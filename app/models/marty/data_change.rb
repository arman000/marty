require 'delorean_lang'

class Marty::DataChange
  include Delorean::Model

  # Some arbitrary limit so we don't allow enormous queries
  MAX_COUNT = 64000

  delorean_fn :changes, sig: 3 do
    |t0, t1, class_name|

    klass = class_name.constantize

    t0 = Mcfly.normalize_infinity t0
    t1 = Mcfly.normalize_infinity t1

    cols = Marty::DataConversion.columns(klass)
    changes = get_changed_data(t0, t1, klass)

    changes.each_with_object({}) do |(group_id, ol), h|
      h[group_id] = ol.each_with_index.map do |o, i|
        profile = {"obj" => o}

        # Create a profile hash for each object in the group.
        # "status" tells us if the object is old/new/mod.  If
        # status=="mod" then "changes" will provide the list of
        # columns which changed.  If the object was deleted during
        # t0-t1 then we set the deleted flag in the profile.
        profile["deleted"] = (group_id == o.id &&
                              o.obsoleted_dt != Float::INFINITY &&
                              (t1 == 'infinity' || o.obsoleted_dt < t1)
                              )
        if i == 0
          profile["status"] = o.created_dt < t0 ? "old" : "new"
          prev = nil
        else
          profile["status"], prev = "mod", prev = ol[i-1]
        end

        exp_attrs = Marty::DataExporter.export_attrs(klass, o)

        # assumes cols order is same as that returned by export_attrs
        profile["attrs"] = cols.each_with_index.map do
          |c, i|

          {
            # FIXME: using .first on export_attr -- this will not work
            # if the attr is an association which will requires
            # multiple keys to identify (e.g. Rule: name & version)
            "value"     => exp_attrs[i].first,
            "changed"   => prev && (o.send(c.to_sym) != prev.send(c.to_sym)),
          }
        end

        profile
      end
    end
  end

  delorean_fn :change_summary, sig: 3 do
    |t0, t1, class_name|

    klass = class_name.constantize

    t0 = Mcfly.normalize_infinity t0
    t1 = Mcfly.normalize_infinity t1

    changes = get_changed_data(t0, t1, klass)

    created = updated = deleted = 0

    changes.each { |group_id, ol|
      ol.each_with_index.map { |o, i|
        deleted +=1 if (group_id == o.id &&
                        o.obsoleted_dt != Float::INFINITY &&
                        (t1 == 'infinity' || o.obsoleted_dt < t1)
                        )
        if i == 0
          created +=1 unless o.created_dt < t0
        else
          updated += 1
        end
      }
    }

    {'created' => created, 'updated' => updated, 'deleted' => deleted}
  end

  delorean_fn :class_list, sig: 0 do
    Rails.configuration.marty.class_list.sort.uniq || []
  end

  delorean_fn :class_headers, sig: 1 do
    |class_name|

    klass = class_name.constantize
    assoc = Marty::DataConversion.associations klass
    Marty::DataConversion.columns(klass).map { |c|
      # strip _id if it's an assoc
      c = c[0..-4] if assoc[c]
      I18n.t(c, scope: 'attributes', default: c)
    }
  end

  delorean_fn :user_name, sig: 1 do
    |user_id|

    Marty::User.find_by_id(user_id).try(:name)
  end

  delorean_fn :sanitize_classes, sig: 1 do
    |classes|
    classes = classes.split(/,\s*/) if classes.is_a? String

    classes.to_set & class_list.to_set
  end

  delorean_fn :do_export, sig: [2, 3] do
    |pt, klass, sort_field=nil|

    # allow classes on class_list or any Enum to be exported
    raise "'#{klass}' not on class_list" unless
      class_list.member?(klass) || klass.constantize.is_a?(Marty::Enum)

    Marty::DataExporter.do_export(pt, klass.constantize, sort_field)
  end

  delorean_fn :export_changes, sig: 3 do
    |t0, t1, class_name|

    klass = class_name.constantize

    t0 = Mcfly.normalize_infinity t0
    t1 = Mcfly.normalize_infinity t1

    change_q = '(obsoleted_dt >= ? AND obsoleted_dt < ?)' +
      ' OR (created_dt >= ? AND created_dt < ?)'

    # find all changes from t0 to t1 -- orders by id to get the lower
    # ones since those are the original version in Mcfly.  Using
    # unscoped to get around lazy loaded column scopes.
    changes = klass.unscoped.select("DISTINCT ON (group_id) *").
      where(change_q, t0, t1, t0, t1).
      order("group_id, id").
      to_a

    # update/adds, deletes
    chg, del = [], []

    changes.each do |o|
      if Mcfly.is_infinity(o.obsoleted_dt)
        chg << o
      else
        # if a version of row existed before t0 => add it to del list
        del << o if klass.
          where("group_id = ? AND created_dt < ?", o.group_id, t0).exists?
      end
    end

    [chg, del].map {|l|
      l.empty? ? nil : Marty::DataExporter.do_export_query_result(klass, l)
    }
  end

  def self.get_changed_data(t0, t1, klass)
    # The following test fails when t0/t1 are infinity.  ActiveSupport
    # doesn't know about infinity.
    # return unless t0 < t1

    change_q = '(obsoleted_dt >= ? AND obsoleted_dt < ?)' +
      ' OR (created_dt >= ? AND created_dt < ?)'

    raise "Change count exceeds limit #{MAX_COUNT}" if
      klass.unscoped.where(change_q, t0, t1, t0, t1).count > MAX_COUNT

    klass.where(change_q, t0, t1, t0, t1).
      order("group_id, created_dt").group_by(&:group_id)
  end
end
