class Marty::DataConversion
  EXCEL_START_DATE = Date.parse('1/1/1900')-2

  FLOAT_PAT = /^-?\d+(\.\d+)?$/

  PATS = {
    integer: /^-?\d+(\.0+)?$/,
    float:   FLOAT_PAT,
    decimal: FLOAT_PAT,
  }

  # database types that can be converted to on import
  DATABASE_TYPES = Set[
    :boolean,
    :string,
    :text,
    :integer,
    :float,
    :decimal,
    :date,
    :datetime,
    :numrange,
    :int4range,
    :int8range,
    :float_array,
    :json,
    :jsonb,
    :enum,
  ]

  def self.convert(v, type)
    # Converts external data v (e.g. from a CSV, cut/paste) to
    # ActiveRecord database data type.

    pat = PATS[type]

    raise "bad #{type} #{v.inspect}" if
      v.is_a?(String) && pat && !(v =~ pat)

    case type
    when :boolean
      case v.to_s.downcase
      when "true",  "1", "y", "t" then true
      when "false", "0", "n", "f" then false
      else raise "unknown boolean: #{v.inspect}"
      end
    when :string, :text, :enum
      v
    when :enum_array, :string_array, :integer_array
      "'{#{v}}'"
    when :integer
      v.to_i
    when :float
      v.to_f
    when :decimal
      v.to_d
    when :date
      # Dates are kept as float in Google spreadsheets.  Need to
      # convert them to dates.
      begin
        v =~ FLOAT_PAT ? EXCEL_START_DATE + v.to_f :
          Mcfly.is_infinity(v) ? 'infinity' : v.to_date
      rescue => exc
        raise "date conversion failed for #{v.inspect}}"
      end
    when :datetime
      begin
        Mcfly.is_infinity(v) ? 'infinity' : v.to_datetime
      rescue => exc
        raise "datetime conversion failed for #{v.inspect}}"
      end
    when :numrange, :int4range, :int8range
      v.to_s
    when :float_array, :json, :jsonb
      # v might be base64 or might be a readable string
      JSON.parse Marty::DataExporter.decode_json(v) rescue JSON.parse(v)
    else
      raise "unknown type #{type} for #{v.inspect}}"
    end
  end

  ######################################################################

  def self.assoc_keys(klass)
    return Mcfly.mcfly_uniqueness(klass) if Mcfly.has_mcfly?(klass)
    # FIXME: very hacky -- picks 1st non-id attr as the association
    # key for regular (non-mcfly) AR models which don't have
    # MARTY_IMPORT_UNIQUENESS.
    klass.const_get(:MARTY_IMPORT_UNIQUENESS) rescue [
    klass.column_names.reject{|x| x=="id"}.first.to_sym]
  end

  @@associations = {}

  def self.associations(klass)
    # build a profile for ActiveRecord klass associations which
    # enables find/import of its database records

    @@associations[klass] ||= klass.reflect_on_all_associations.
      each_with_object({}) do
      |assoc, h|

      h[assoc.name.to_s] = {
        assoc_keys:  assoc_keys(assoc.klass),
        assoc_class: assoc.klass,
        foreign_key: assoc.foreign_key,
      }
    end
  end

  def self.assoc_cols(klass)
    # array of klass association columns (e.g. ["xxx_id", ...])
    associations(klass).values.map { |a| a[:foreign_key] }
  end

  ######################################################################

  @@col_types = {}

  def self.col_types(klass)
    # build profile for ActiveRecord non-assoc columns -- used to
    # find/import of klass database records.

    @@col_types[klass] ||= klass.columns.each_with_object({}) do
      |col, h|

      assoc ||= associations(klass)
      acols ||= assoc_cols(klass)

      cn = col.name

      # ignore mcfly cols
      next if Mcfly::COLUMNS.member?(cn)

      if acols.member?(cn)
        h[cn] = assoc.values.detect { |a| a[:foreign_key] == cn }
      else
        # for JSON fields in Rails 3.x type is nil, so use sql_type
        type = col.type || col.sql_type
        type = "#{type}_array" if col.array
        h[cn] = type.to_sym
      end
    end
  end

  def self.columns(klass)
    # list of non-mcfly columns
    col_types(klass).keys
  end

  ######################################################################

  def self.find_row(klass, options, dt)
    key_attrs = assoc_keys(klass)

    raise "no key_attrs for #{klass}" unless key_attrs

    find_options = options.select { |k,v| key_attrs.member? k.to_sym }

    raise "no keys for #{klass} -- #{options}" if find_options.empty?

    # unscope klass since we're sometimes sent lazy column classes
    q = klass.unscoped.where(find_options)
    q = q.where("obsoleted_dt >= ? AND created_dt < ?", dt, dt) if
       dt && Mcfly.has_mcfly?(klass)

    # q.count is almost always 0 or 1 => hopefully it's not too slow on PG.
    raise "too many results for: #{klass} -- #{options}" if q.count > 1

    q.first
  end

  ######################################################################

  def self.convert_row(klass, row, dt)
    # Given row information from imports (usually csv row or hash),
    # return a hash with fields converted into proper ruby types.

    ctypes = col_types(klass)
    assoc  = associations(klass)

    raise "bad row (extra columns?) -- #{row}" if row.has_key?(nil)

    key_groups = row.keys.group_by {|x| x.to_s.split('__').first}

    # FIXME: map all empty string values to nil --- this means that
    # user can't import empty strings -- Perhaps, mapping "" -> nil
    # should be optional?
    row = row.each_with_object({}) {
      |(k,v), h|
      h[k.to_s] = v == '' ? nil : v
    }
    key_groups.each_with_object({}) do
      |(ga, g), h|

      # find the association's details
      ai = assoc[ga]

      unless ai
        raise "unexpected grouping for non assoc #{g}" unless g.length == 1

        type = ctypes[ga]

        raise "unknown column #{ga} in #{klass}" unless type

        v = row[ga]

        if v.nil?
          h[ga] = nil
        elsif Hash === type
          # got an id for an association -- FIXME: perhaps this should
          # not be allowed at all?
          raise "#{type[:assoc_class].name} with id #{v} not found" unless
            type[:assoc_class].find_by_id(v)

          h[ga] = v
        else
          # not an association, so we need to convert
          h[ga] = convert(v, type)
        end
        next
      end

      srch_class = ai[:assoc_class]
      fk = "#{ga}_id"

      if g.length == 1
        # optimization for case where we have a 1-key association
        v = row[g.first]

        # If group has only one attr and the attr is nil or AR obj, then
        # we don't need to search.
        if v.nil? || v.is_a?(ActiveRecord::Base)
          h[fk] = v && v.id
          next
        end

        # If it's an Enum, use the faster cached looked mechanism
        if Marty::Enum === srch_class
          h[fk] = srch_class[ v ].id
          next
        end
      end

      # group size > 1 or not an Enum, so it must be an association
      raise "expected an association for #{ga}" unless ai

      # build a new row map for this association, we need to convert
      # it and search for it.
      arow = g.each_with_object({}) do
        |k, h|

        # Some old exports don't provide full assoc__attr column names
        # (e.g. 'xxx_name').  Instead the columns are just named by
        # assoc (e.g. 'xxx').
        gname, ka = k.split('__', 2)

        ka ||= ai[:assoc_keys][0].to_s
        h[ka] = row[k]
      end

      c_arow = convert_row(srch_class, arow, dt)
      o_arow = find_row(srch_class, c_arow, dt)

      raise "obj not found: #{ai[:assoc_class]}, #{c_arow}, #{dt}" unless o_arow

      h[fk] = o_arow.id
    end

  end

  ######################################################################

  def self.create_or_update(klass, row, dt)
    # Given a row data (usually from import) try to find the
    # associated DB row from the klass keys.  If found the row is
    # updated using the dt datetime.  Otherwise, a new row is created
    # with the provided row data.

    c_row = convert_row(klass, row.to_hash, dt)
    obj = find_row(klass, c_row, dt)

    obj ||= klass.new

    c_row.each do
      |k, v|
      # For each attr, check to see if it's begin changed before
      # setting it.  The AR obj.changed? doesn't work properly
      # with array, JSON or lazy attrs.
      obj.send("#{k}=", v) if obj.send(k) != v
    end

    # FIXME: obj.changed? doesn't work properly for timestamp
    # fields in Rails 3.2. It evaluates to true even when datetime
    # is not changed.  Caused by lack of awareness of timezones.
    tag = obj.new_record? ? :create : (obj.changed? ? :update : :same)

    raise "old created_dt >= current #{obj} #{obj.created_dt} #{dt}" if
      (tag == :update) && dt && !Mcfly.is_infinity(dt) && (obj.created_dt > dt)

    obj.created_dt = dt unless tag == :same || Mcfly.is_infinity(dt) || !dt
    obj.save!

    [tag, obj.id]
  end
end
