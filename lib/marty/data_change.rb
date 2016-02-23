class Marty::DataChange
  include Delorean::Model

  # Some arbitrary limit so we don't allow enormous queries
  MAX_COUNT = 64000

  # will break if DataExporter::export_attrs recurses more than 1 level
  # and a level 2+ child table has a compound mcfly_uniqueness key
  delorean_fn :changes, sig: [3, 4] do
    |t0, t1, class_name, ids = []|

    klass = class_name.constantize

    t0 = Mcfly.normalize_infinity t0
    t1 = Mcfly.normalize_infinity t1

    cols_model = Marty::DataConversion.columns(klass)
    cols_header = Marty::DataExporter.export_headers(class_name.constantize,
                                                     nil, [])
    changes = get_changed_data(t0, t1, klass, ids)

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

        exp_attrs = Marty::DataExporter.export_attrs(klass, o).flatten(1)

        # assumes cols order is same as that returned by export_attrs

        profile["attrs"] = cols_model.each_with_index.with_object([]) do
          |(col, i), a|
          header_current = cols_header[i]
          valcount = (header_current.is_a? Array) ? header_current.count : 1
          changed = prev && (o.send(col.to_sym) != prev.send(col.to_sym))
          valcount.times do
            a.push({
              "value"     => exp_attrs.shift,
              "changed"   => changed
            })
          end
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

    changes = get_changed_data(t0, t1, klass, [])

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
    Marty::DataExporter.export_headers(class_name.constantize, nil, []).flatten.
      map { |f| I18n.t(f, scope: 'attributes', default: f) }
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

  delorean_fn :do_export, sig: [2, 4] do
    |pt, klass, sort_field=nil, exclude_attrs=[]|

    # allow classes on class_list or any Enum to be exported
    raise "'#{klass}' not on class_list" unless
      class_list.member?(klass) || klass.constantize.is_a?(Marty::Enum)

    Marty::DataExporter.
      do_export(pt, klass.constantize, sort_field, exclude_attrs)
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

  def self.get_changed_data(t0, t1, klass, ids)
    # The following test fails when t0/t1 are infinity.  ActiveSupport
    # doesn't know about infinity.
    # return unless t0 < t1

    change_q = '(obsoleted_dt >= ? AND obsoleted_dt < ?)' +
               ' OR (created_dt >= ? AND created_dt < ?)'

    countq = klass.unscoped.where(change_q, t0, t1, t0, t1)
    dataq = klass.where(change_q, t0, t1, t0, t1)
    if ids && ids.length > 0
      countq = countq.where(group_id: ids)
      dataq = dataq.where(group_id: ids)
    end

    raise "Change count exceeds limit #{MAX_COUNT}" if countq.count > MAX_COUNT

    dataq.order("group_id, created_dt").group_by(&:group_id)
  end

  ######################################################################

  # Given a class and an array of records (hashes), figure out the
  # differences in the current records for the class and the records.
  # Produces a result hash with the following format:
  #
  # {"only_source" => [...],
  #  "only_input"  => [...],
  #  "different"   => [...],
  #  "same"        => [...]}
  #
  # The "only_input" are hashes found in input which were not found in
  # source.  "same" are input hashes which were found in source and
  # have identical information for fields provided.  "only_source" is
  # an array of source objects for which no equivalent was found in
  # the input data.  "different" denotes the set of objects which were
  # found in both input and source but differed on some attribute
  # values.  "different" is an array of hashes.  Array element look
  # like:
  #
  # {"source" => {k1=>v1, k2=>v2, ...},
  #  "input"  => {k1=>v1, k2=>v2, ...}}

  delorean_fn :diff, sig: [2, 3] do
    |klass, input_data, ts='infinity'|

    ts = Mcfly.normalize_infinity(ts)
    keys = Marty::DataConversion.assoc_keys(klass).map(&:to_s).to_set

    only_source, only_input, different, same = [], [], [], []
    found_sources = Set[]

    input_data.each do
      |input|

      input_keys = input.keys

      raise "non-String keys in input data" unless
        input_keys.all? { |x| String === x }

      begin
        # convert record -- if there's an exception, it's likely that
        # an association lookup failed => don't have some association
        # in source.  FIXME: it could be that we get an conversion
        # error through not finding a non-key association.  Ideally,
        # if we can find the key in source, we should report this as
        # "different".
        conv =
          Marty::DataConversion.convert_row(klass, input, ts)
      rescue => exc
        only_input << input
        next
      end

      key_hash = conv.reject { |k, v| !keys.member?(k) }

      source = Marty::DataConversion.find_row(klass, key_hash, ts)

      if !source
        # lookup of keys failed => don't have this in source
        only_input << input
        next
      end

      found_sources << source

      non_key_hash = conv.reject { |k, v| keys.member?(k) }

      # is source same as converted input?
      if non_key_hash.all? { |k, v| v == source.send(k) }
        same << input
        next
      end

      source_export = Marty::DataExporter.export_obj(source) % input_keys

      different << [
        {"_origin_" => "source"} + source_export,
        {"_origin_" => "input"} + input,
      ]
    end

    # now find any live source object which have not been visited
    query = klass

    query = query.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts) if
      Mcfly.has_mcfly?(klass)

    query = query.where.not(id: found_sources.map(&:id))

    {
      "different"   => different,
      "same"        => same,
      "only_input"  => only_input,
      "only_source" => Marty::DataExporter.
                      do_export_query_result(klass, query),
    }
  end

  ######################################################################

  # Given a Mcfly class_name, find all of the obsoleted Mcfly objects
  # which are referenced by live (non-obsoleted) class instances.
  delorean_fn :dead_refs, sig: 2 do
    |ts, class_name|

    klass = class_name.constantize

    return unless Mcfly.has_mcfly?(klass)

    ts = Mcfly.normalize_infinity(ts)
    col_types = Marty::DataConversion.col_types(klass)

    mcfly_cols = col_types.map { |attr, h|
      Hash === h && Mcfly.has_mcfly?(h[:assoc_class]) && h || nil
    }.compact

    mcfly_cols.each_with_object({}) {
      |h, res|

      fk = h[:foreign_key]
      rtable = h[:assoc_class].table_name
      ktable = klass.table_name

      # find references to the latest version in rtable (i.e. id =
      # group_id). The latest referenced version should not be
      # obsoleted before the row which refers to it.  FIXME: this is
      # not exhaustive.  There are other possibities for dead
      # references. e.g. referenced id != group_id.
      arr =
        klass.
        joins("INNER JOIN #{rtable} ON #{ktable}.#{fk} = #{rtable}.group_id").
        where("#{ktable}.obsoleted_dt >= ?", ts).
        where("#{ktable}.created_dt < ?", ts).
        where("#{rtable}.obsoleted_dt < #{ktable}.obsoleted_dt").
        where("#{rtable}.group_id = #{rtable}.id").
        all

      arr = arr.map {|obj| Marty::DataExporter.export_attrs(klass, obj, [fk])}

      res[fk] = arr unless arr.empty?
    }
  end
end
