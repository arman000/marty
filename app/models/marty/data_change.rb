require 'delorean_lang'

class Marty::DataChange
  include Delorean::Model

  def self.class_info(klass)
    @class_info ||= {}

    return @class_info[klass] if @class_info[klass]

    associations = klass.reflect_on_all_associations.map(&:name)

    @class_info[klass] = {
      cols:
      klass.columns.map(&:name) - Marty::DataImporter::MCFLY_COLUMNS.to_a,
      assoc:
      associations.each_with_object({}) { |a, h|
        h["#{a}_id"] = Marty::DataImporter::RowProcessor.assoc_info(klass, a)
      },
    }
  end

  # Some arbitrary limit so we don't allow enormous queries
  MAX_COUNT = 64000

  delorean_fn :changes, sig: 3 do
    |t0, t1, class_name|

    klass = class_name.constantize

    # The following test fails when t0/t1 are infinity.  ActiveSupport
    # doesn't know about infinity.

    # return unless t0 < t1

    t0 = 'infinity' if t0 == Float::INFINITY
    t1 = 'infinity' if t1 == Float::INFINITY

    info = class_info(klass)

    change_q = '(obsoleted_dt >= ? AND obsoleted_dt < ?)' +
      ' OR (created_dt >= ? AND created_dt < ?)'

    raise "Change count exceeds limit #{MAX_COUNT}" if
      klass.where(change_q, t0, t1, t0, t1).count > MAX_COUNT

    changes = klass.where(change_q, t0, t1, t0, t1).
      order("group_id, created_dt").group_by(&:group_id)

    changes.inject({}) { |h, (group_id, ol)|
      h[group_id] = ol.each_with_index.map { |o, i|
        profile = {
          "obj" => o,
        }

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

        profile["attrs"] = info[:cols].map { |c|
          {
            "value" 	=> export_attr(o, c, info),
            "changed" 	=> prev && (o.send(c.to_sym) != prev.send(c.to_sym)),
          }
        }

        profile
      }
      h
    }
  end

  delorean_fn :class_list, sig: 0 do
    Rails.configuration.marty.class_list.sort.uniq || []
  end

  def self.export_attr(obj, c, info)
    v = obj.send(c.to_sym)
    assoc_info = info[:assoc][c] unless v.nil?
    assoc_info ? assoc_info[:assoc_class].find(v).
      send(assoc_info[:assoc_key].to_sym) : v
  end

  delorean_fn :class_headers, sig: 1 do
    |class_name|

    klass = class_name.constantize
    info = class_info(klass)
    info[:cols].map { |c|
      # strip _id if it's an assoc
      c = c[0..-4] if info[:assoc][c]
      I18n.t(c, scope: 'attributes')
    }
  end

  delorean_fn :user_name, sig: 1 do
    |user_id|

    Marty::User.find_by_id(user_id).try(:name)
  end

  delorean_fn :sanitize_classes, sig: 1 do
    |classes|
    classes = classes.split(/,\s*/) if classes.is_a? String

    Set[* classes] & Set[* class_list]
  end

end
