class Marty::DataGrid < Marty::Base
  # If data_type is nil, assume float
  DEFAULT_DATA_TYPE = "float"

  INDEX_MAP = {
    "numrange"  => Marty::GridIndexNumrange,
    "int4range" => Marty::GridIndexInt4range,
    "integer"   => Marty::GridIndexInteger,
    "string"    => Marty::GridIndexString,
    "boolean"   => Marty::GridIndexBoolean,
  }

  ARRSEP = '|'

  class DataGridValidator < ActiveModel::Validator
    def validate(dg)
      dg.errors.add(:base, "'#{dg.data_type}' not a defined type or class") unless
        Marty::DataGrid.convert_data_type(dg.data_type)

      dg.errors.add(:base, "data must be array of arrays") unless
        dg.data.is_a?(Array) && dg.data.all? { |a| a.is_a? Array }

      dg.errors.add(:base, "metadata must be an array of hashes") unless
        dg.metadata.is_a?(Array) && dg.metadata.all? { |a| a.is_a? Hash }

      dg.errors.add(:base, "metadata must contain only h/v dirs") unless
        dg.metadata.all? { |h| ["h", "v"].member? h["dir"] }

      dg.errors.add(:base, "metadata item attrs must be unique") unless
        dg.metadata.map { |h| h["attr"] }.uniq.length == dg.metadata.length

      dg.metadata.each do |inf|
        attr, type, keys, rs_keep =
          inf["attr"], inf["type"], inf["keys"], inf["rs_keep"]

        unless rs_keep.nil? || rs_keep.empty?
          m = /\A *(<|<=|>|>=)? *([a-z][a-z_0-9]+) *\z/.match(rs_keep)
          unless m
            dg.errors.add(:base, "invalid grid modifier expression: #{rs_keep}")
            next
          end
        end

        dg.errors.add(:base, "metadata elements must have attr/type/keys") unless
          attr && type && keys

        # enforce Delorean attr syntax (a bit Draconian)
        dg.errors.add(:base, "bad attribute '#{attr}'") unless
          attr =~ /^[a-z][A-Za-z0-9_]*$/

        dg.errors.add(:base, "unknown metadata type #{type}") unless
          Marty::DataGrid.type_to_index(type)

        dg.errors.add(:base, "bad metadata keys") unless
          keys.is_a?(Array) && keys.length > 0
      end

      # Check key uniqueness of vertical/horizontal key
      # combinations. FIXME: ideally, we should also check for
      # array/range key subsumption.  Those will result in runtime
      # errors anyway when multiple hits are produced.
      v_keys = dg.dir_infos("v").map { |inf| inf["keys"] }
      h_keys = dg.dir_infos("h").map { |inf| inf["keys"] }

      v_zip_keys = v_keys.empty? ? [] : v_keys[0].zip(*v_keys[1..-1])
      h_zip_keys = h_keys.empty? ? [] : h_keys[0].zip(*h_keys[1..-1])

      dg.errors.add(:base, "duplicate horiz. key combination") unless
        h_zip_keys.uniq.length == h_zip_keys.length

      dg.errors.add(:base, "duplicate vertical key combination") unless
        v_zip_keys.uniq.length == v_zip_keys.length
    end
  end

  has_mcfly

  validates_presence_of :name, :data, :metadata

  mcfly_validates_uniqueness_of :name
  validates_with DataGridValidator
  validates_with Marty::NameValidator, field: :name

  gen_mcfly_lookup :lookup, [:name], cache: true
  gen_mcfly_lookup :get_all, [], mode: nil

  # FIXME: if the caller requests data as part of fields, there could
  # be memory concerns with caching since some data_grids have massive data
  cached_delorean_fn :lookup_h, sig: [2, 3] do |pt, name, fields = nil|
    fields ||= %w(id group_id created_dt metadata data_type name)
    dga = mcfly_pt(pt).where(name: name).pluck(*fields).first
    dga && Hash[fields.zip(dga)]
  end

  # deprecated - remove 2018-Oct
  cached_mcfly_lookup :lookup_id, sig: 2 do |pt, group_id|
    find_by_group_id group_id
  end

  cached_delorean_fn :exists, sig: 2 do |pt, name|
    Marty::DataGrid.mcfly_pt(pt).where(name: name).exists?
  end

  def self.get_struct_attrs
    self.struct_attrs ||= super + ["id", "group_id", "created_dt", "name"]
  end

  def to_s
    name
  end

  def freeze
    # FIXME: mcfly lookups freeze their results in order to protect
    # the cache.  That doesn't interact correctly with lazy_load which
    # modifies the attr hash at runtime.
    self
  end

  def self.register_rule_handler(handler)
    (@@rule_handlers ||= []) << handler
  end

  def update_rules(old, new)
    @@rule_handlers.each { |rh| rh.call(old, new) }
  end

  # FIXME: not sure what's the right way to perform the save in a
  # transaction -- i.e. together with build_index.  before_save would
  # be OK, but then save inside it would cause an infinite loop.
  def save!
    if self.changed?
      transaction do
        nc, nw, n = [name_changed?, name_was, name]
        res = super
        update_rules(nw, n) if nc && nw.present?
        reload
        build_index
        res
      end
    end
  end

  # FIXME: hacky -- save is just save!
  def save
    self.save!
  end

  def self.type_to_index(type)
    # map given header type to an index class -- uses string index
    # for ruby classes.
    return INDEX_MAP[type] if INDEX_MAP[type]

    INDEX_MAP["string"] if (type.constantize rescue nil)
  end

  def self.convert_data_type(data_type)
    # given data_type, convert it to class and or known data type --
    # returns nil if data_type is invalid

    return DEFAULT_DATA_TYPE if data_type.nil?
    return data_type if
      Marty::DataConversion::DATABASE_TYPES.member?(data_type.to_sym)

    data_type.constantize rescue nil
  end

  def self.clear_dtcache
    @@dtcache = {}
  end

  PLV_DT_FMT = "%Y-%m-%d %H:%M:%S.%N6"

  def self.plv_lookup_grid_distinct(h_passed, dgh, ret_grid_data = false,
                                    distinct = true)
    cd = dgh["created_dt"]
    @@dtcache ||= {}
    @@dtcache[cd] ||= cd.strftime(PLV_DT_FMT)
    row_info = {
      "id"         => dgh["id"],
      "group_id"   => dgh["group_id"],
      "created_dt" => @@dtcache[cd]
    }

    h = dgh["metadata"].each_with_object({}) do |m, h|
      attr = m["attr"]
      inc = h_passed.fetch(attr, :__nf__)
      next if inc == :__nf__

      val = (defined? inc.name) ? inc.name : inc
      h[attr] = val.is_a?(String) ?
                  ActiveRecord::Base.connection.quote(val)[1..-2] : val
    end

    fn     = "lookup_grid_distinct"
    hjson  = "'#{h.to_json}'::JSONB"
    rijson = "'#{row_info.to_json}'::JSONB"
    params = "#{hjson}, #{rijson}, #{ret_grid_data}, #{distinct}"
    sql    = "SELECT #{fn}(#{params})"
    raw    = ActiveRecord::Base.connection.execute(sql)[0][fn]
    res    = JSON.parse(raw)

    if res["error"]
      msg = res["error"]
      parms, sqls, ress, dg = res["error_extra"].values_at(
        "params", "sql", "results", "dg")

      raise "DG #{name}: Error in PLV8 call: #{msg}\n"\
            "params: #{parms}\n"\
            "sqls: #{sqls}\n"\
            "results: #{ress}\n"\
            "dg: #{dg}\n"\
            "ri: #{row_info}" if res["error"]
    end

    if ret_grid_data
      dg = find(dgh["id"])
      md, mmd = modify_grid(h_passed, dg.metadata, dg.data)
      res["data"] = md
      res["metadata"] = mmd
    end
    res
  end

  # deprecated - remove 2018-Oct
  cached_delorean_fn :lookup_grid, sig: 4 do |pt, dg, h, distinct|
    dg_is_grid = Marty::DataGrid === dg
    dg_is_os = dg.is_a?(OpenStruct)
    raise "bad DataGrid #{dg}" unless dg_is_grid || dg_is_os
    raise "non-hash arg #{h}" unless Hash === h

    dgh = dg_is_os ? dg.to_h.stringify_keys :
            dg.attributes.slice('id', 'group_id', 'created_dt', 'metadata')
    res = plv_lookup_grid_distinct(h, dgh, false, distinct)
    res["result"]
  end

  cached_delorean_fn :lookup_grid_h, sig: 4 do |pt, dgn, h, distinct|
    dgh = lookup_h(pt, dgn)
    raise "#{dgn} grid not found" unless dgh
    raise "non-hash arg #{h}" unless Hash === h

    res = lookup_grid_distinct_entry_h(pt, h, dgh, nil, true, false, distinct)
    res["result"]
  end

  # FIXME: using cached_delorean_fn just for the caching -- this is
  # not expected to be called from Delorean.
  cached_delorean_fn :find_class_instance, sig: 3 do |pt, klass, v|
    if Marty::PgEnum === klass
      klass.find_by_name(v)
    else
      # FIXME: very hacky -- hard-coded name
      Marty::DataConversion.find_row(klass, { "name" => v }, pt)
    end
  end

  def self.lookup_grid_distinct_entry_h(pt, h, dgh, visited = nil, follow = true,
                                        return_grid_data = false, distinct = true)

    # Perform grid lookup, if result is another data_grid, and follow is true,
    # then perform lookup on the resulting grid.  Allows grids to be nested
    # as multi-grids.  If return_grid_data is true, also return the grid
    # data and metadata
    # return is a hash for the grid results:
    #
    #   "result"   => <result of running the grid>
    #   "name"     => <grid name>
    #   "data"     => <grid's data array>
    #   "metadata" => <grid's metadata (array of hashes)>
    vhash = plv_lookup_grid_distinct(h, dgh, return_grid_data, distinct)

    return vhash if vhash["result"].nil? || !dgh['data_type']

    c_data_type = Marty::DataGrid.convert_data_type(dgh['data_type'])

    return vhash if String === c_data_type

    res = vhash["result"]

    v = case
             when Marty::PgEnum === res
               c_data_type.find_by_name(res)
             when Marty::DataGrid == c_data_type
               follow ?
                 Marty::DataGrid.lookup_h(pt, res) :
                 Marty::DataGrid.lookup(pt, res)
             else
               Marty::DataConversion.find_row(c_data_type, { "name" => res }, pt)
         end

    return vhash.merge({ "result" => v }) unless (Marty::DataGrid == c_data_type &&
                                              follow)

    visited ||= []

    visited << dgh['group_id']

    raise "#{self.class} recursion loop detected -- #{visited}" if
      visited.member?(v['group_id'])

    lookup_grid_distinct_entry_h(pt, h, v, visited, follow, return_grid_data,
                                 distinct)
  end

  def dir_infos(dir)
    metadata.select { |inf| inf["dir"] == dir }
  end

  def self.export_keys(inf)
    # should unify this with Marty::DataConversion.convert

    type = inf["type"]
    klass = type.constantize unless INDEX_MAP[type]

    inf["keys"].map do |v|
      case type
      when "numrange", "int4range"
        Marty::Util.pg_range_to_human(v)
      when "boolean"
        v.to_s
      when "string", "integer"
        v.map(&:to_s).join(ARRSEP) if v
      else
        # assume it's an AR class
        v.each do |k|
          begin
            # check to see if class instance actually exists
            Marty::DataGrid
              .find_class_instance('infinity', klass, k) || raise(NoMethodError)
          rescue NoMethodError
            raise "instance #{k} of #{type} not found"
          end
        end if v
        v.join(ARRSEP) if v
      end
    end
  end

  # FIXME: this is only here to appease Netzke add_in_form
  def export=(text)
  end

  def export_array
    # add data type metadata row if not default
    dt_row = lenient ? ["lenient"] : []
    dt_row << data_type unless [nil, DEFAULT_DATA_TYPE].member?(data_type)

    meta_rows = dt_row.empty? ? [] : [[dt_row.join(' ')]]

    meta_rows += metadata.map do |inf|
      [inf["attr"], inf["type"], inf["dir"], inf["rs_keep"] || ""]
    end

    v_infos, h_infos = dir_infos("v"), dir_infos("h")

    h_key_rows = h_infos.map do |inf|
      [nil] * v_infos.count + self.class.export_keys(inf)
    end

    transposed_v_keys = v_infos.empty? ? [[]] :
      v_infos.map { |inf| self.class.export_keys(inf) }.transpose

    data_rows = transposed_v_keys.each_with_index.map do |keys, i|
      keys + (self.data[i] || [])
    end

    [meta_rows, h_key_rows, data_rows]
  end

  def export
     # return null string when called from Netzke on add_in_form
     return "" if metadata.nil? && data.nil?

    meta_rows, h_key_rows, data_rows = export_array

    Marty::DataExporter
      .to_csv(meta_rows + [[]] + h_key_rows + data_rows,
              "col_sep" => "\t",
             )
      .gsub(/\"\"/, '') # remove "" to beautify output
  end

  delorean_fn :export, sig: 1 do |os|
    dg = find(os.id)
    dg.export
  end

  def self.parse_fvalue(pt, v, type, klass)
    return unless v

    case type
    when "numrange", "int4range"
      Marty::Util.human_to_pg_range(v)
    when "integer"
      v.split(ARRSEP).map do |val|
        Integer(val) rescue raise "invalid integer: #{val}"
      end.uniq.sort
    when "float"
      v.split(ARRSEP).map do |val|
        Float(val) rescue raise "invalid float: #{val}"
      end.uniq.sort
    when "string"
      res = v.split(ARRSEP).uniq.sort
      raise "leading/trailing spaces in elements not allowed" if
        res.any? { |x| x != x.strip }
      raise "0-length string not allowed" if res.any?(&:empty?)

      res
    when "boolean"
      case v.downcase
      when "true", "t"
        true
      when "false", "f"
        false
      else
        raise "bad boolean #{v}"
      end
    else
      # AR class
      # FIXME: won't work if the obj identifier (name) has ARRSEP
      res = v.split(ARRSEP).uniq
      res.each do |k|
        begin
          # check to see if class instance actually exists
          Marty::DataGrid
            .find_class_instance(pt, klass, k) || raise(NoMethodError)
        rescue NoMethodError
          raise "instance #{k} of #{type} not found"
        end
      end
      res
    end
  end

  def self.maybe_get_klass(type)
    begin
      type.constantize unless INDEX_MAP[type] || type == "float"
    rescue NameError
      raise "unknown header type/klass: #{type}"
    end
  end

  def self.parse_keys(pt, keys, type)
    klass = maybe_get_klass(type)
    keys.map do |v|
      parse_fvalue(pt, v, type, klass)
    end
  end

  # parse grid external representation into metadata/data
  def self.parse(pt, grid_text, options)
    options[:headers] ||= false
    options[:col_sep] ||= "\t"

    pt ||= 'infinity'

    rows = CSV.new(grid_text, options).to_a
    blank_index = rows.find_index { |x| x.all?(&:nil?) }

    raise "must have a blank row separating metadata" unless
      blank_index

    raise "can't import grid with trailing blank column" if
      rows.map { |r| r.last.nil? }.all?

    raise "last row can't be blank" if rows[-1].all?(&:nil?)

    data_type, lenient = nil, false

    # check if there's a data_type definition
    dt, *x = rows[0]
    if dt && x.all?(&:nil?)
      dts = dt.split
      raise "bad data type '#{dt}'" if dts.count > 2

      lenient = dts.delete "lenient"
      data_type = dts.first
    end

    metadata = rows[(data_type || lenient ? 1 : 0)...blank_index].map do |attr, type, dir, rs_keep, key|
      raise "metadata elements must include attr/type/dir" unless
        attr && type && dir
      raise "bad dir #{dir}" unless ["h", "v"].member? dir
      raise "unknown metadata type #{type}" unless
        Marty::DataGrid.type_to_index(type)

      res = {
        "attr" => attr,
        "type" => type,
        "dir"  => dir,
        "keys" => key && parse_keys(pt, [key], type),
      }
      res["rs_keep"] = rs_keep if rs_keep
      res
    end

    v_infos = metadata.select { |inf| inf["dir"] == "v" }
    h_infos = metadata.select { |inf| inf["dir"] == "h" }

    # keys+data start right after blank_index
    data_index = blank_index + 1

    # process horizontal key rows
    h_infos.each_with_index do |inf, i|
      row = rows[data_index + i]

      raise "horiz. key row #{data_index + i} must include nil starting cells" if
        row[0, v_infos.count].any?

      inf["keys"] = parse_keys(pt, row[v_infos.count, row.count], inf["type"])
    end

    raise "horiz. info keys length mismatch!" unless
      h_infos.map { |inf| inf["keys"].length }.uniq.count <= 1

    data_rows = rows[data_index + h_infos.count, rows.count]

    # process vertical key columns
    v_key_cols = data_rows.map { |r| r[0, v_infos.count] }.transpose

    v_infos.each_with_index do |inf, i|
      inf["keys"] = parse_keys(pt, v_key_cols[i], inf["type"])
    end

    raise "vert. info keys length mismatch!" unless
      v_infos.map { |inf| inf["keys"].length }.uniq.count <= 1

    c_data_type = Marty::DataGrid.convert_data_type(data_type)

    raise "bad data type #{data_type}" unless c_data_type

    # based on data type, decide to check using convert or instance
    # lookup.  FIXME: DRY.
    if String === c_data_type
      tsym = c_data_type.to_sym

      data = data_rows.map do |r|
        r[v_infos.count, r.count].map do |v|
          Marty::DataConversion.convert(v, tsym) if v
        end
      end
    else
      data = data_rows.map do |r|
        r[v_infos.count, r.count].map do |v|
          next v if !v || Marty::DataGrid
                         .find_class_instance(pt, c_data_type, v)

          raise "can't find key '#{v}' for class #{data_type}"
        end
      end
    end

    [metadata, data, data_type, lenient]
  end

  def self.create_from_import(name, import_text, created_dt = nil)
    metadata, data, data_type, lenient = parse(created_dt, import_text, {})
    dg            = self.new
    dg.name       = name
    dg.data       = data
    dg.data_type  = data_type
    dg.lenient    = !!lenient
    dg.metadata   = metadata
    dg.created_dt = created_dt if created_dt
    dg.save!
    dg
  end

  def update_from_import(name, import_text, created_dt = nil)
    metadata, data, data_type, lenient =
                               self.class.parse(created_dt, import_text, {})

    self.name       = name
    self.data       = data
    self.data_type  = data_type
    self.lenient    = !!lenient
    self.metadata   = metadata unless self.metadata == metadata # Otherwise changed will depend on order in hashes
    self.created_dt = created_dt if created_dt
    save!
  end

  # FIXME: should be private
  def build_index
    # create indices for the metadata
    metadata.each do |inf|
      attr, type, keys = inf["attr"], inf["type"], inf["keys"]

      # find index class
      idx_class = Marty::DataGrid.type_to_index(type)

      keys.each_with_index do |k, index|
        gi              = idx_class.new
        gi.attr         = attr
        gi.key          = k
        gi.created_dt   = created_dt
        gi.data_grid_id = group_id
        gi.index        = index
        gi.save!
      end
    end
  end

  def self.modify_grid(params, metadata, data)
    removes = ["h", "v"].each_with_object({}) { |dir, hash| hash[dir] = Set.new }

    metadata_copy, data_copy = metadata.deep_dup, data.deep_dup

    metadata_copy.each do |meta|
      dir, keys, type, rs_keep = meta.values_at(
        "dir", "keys", "type", "rs_keep")
      next unless rs_keep

      if type == "numrange" || type == "int4range"
        modop, modvalparm = parse_bounds(rs_keep)
        modval = params[modvalparm]
        if modval
          prune_a, rewrite_a = compute_numeric_mods(keys, modop, modval)
          removes[dir].merge(prune_a)
          rewrite_a.each { |(ind, value)| keys[ind] = value }
        end
      else
        modval = params[rs_keep]
        if modval
          prune_a, rewrite_a = compute_set_mods(keys, modval)
          removes[dir].merge(prune_a)
          rewrite_a.each { |(ind, value)| keys[ind] = value }
        end
      end
    end

    removes.reject! { |dir, set| set.empty? }

    removes.each do |dir, set|
      metadata_copy.select { |m| m["dir"] == dir }.each do |meta|
        meta["keys"] = remove_indices(meta["keys"], removes[dir])
      end
    end

    data_copy = remove_indices(data_copy, removes["v"]) if removes["v"]

    data_copy.each_index do |index|
      data_copy[index] = remove_indices(data_copy[index], removes["h"])
    end if removes["h"]

    [data_copy, metadata_copy]
  end

  private

  def self.remove_indices(orig_array, inds)
    orig_array.each_with_object([]).with_index do |(item, new_array), index|
      new_array.push(item) unless inds.include?(index)
    end
  end

  def self.opposite_sign(op)  # toggle sign and inclusivity
    {
      :<  => :>=,
      :<= => :>,
      :>  => :<=,
      :>= => :<,
    }[op]
  end

  def self.compute_numeric_mods(keys, op, val)
    @keyhash ||= {}
    prune_a, rewrite_a = [], []

    # features allow multiple values, but for constraint on a grid range
    # only a scalar is meaningful.  so if there are multiple values we
    # take the first value to use
    value = val.is_a?(Array) ? val[0] : val
    keys.each_with_index do |key, index|
      lhop, orig_lhv, orig_rhv, rhop = @keyhash[key] ||= parse_range(key)

      lhv, rhv = orig_lhv || -Float::INFINITY, orig_rhv || Float::INFINITY

      case op
      when :>=, :>
        next if value > rhv

        if value == rhv
          if rhop == :<= && op == :>=
            rewrite_a.push(
              [index, rewrite_range(lhop, orig_lhv, orig_rhv, :<)])
          end
        elsif value > lhv
          rewrite_a.push(
            [index, rewrite_range(lhop, orig_lhv, value, opposite_sign(op))])
        elsif value == lhv && lhop == :>= && op == :>
          rewrite_a.push([index, rewrite_range(:>=, value, value, :<=)])
        elsif value <= lhv
          prune_a.push(index)
        end
      when :<=, :<
        next if value < lhv

        if value == lhv
          if lhop == :>= && op == :<=
            rewrite_a.push(
              [index, rewrite_range(:>, orig_lhv, orig_rhv, rhop)])
          end
        elsif value < rhv
          rewrite_a.push(
            [index, rewrite_range(opposite_sign(op), value, orig_rhv, rhop)])
        elsif value == rhv && rhop == :<= && op == :<
          rewrite_a.push([index, rewrite_range(:>=, value, value, :<=)])
        elsif value >= rhv
          prune_a.push(index)
        end
      end
    end
    [prune_a, rewrite_a]
  end

  # value is a list of what to keep
  def self.compute_set_mods(keys, val)
    prune_a, rewrite_a, value = [], [], Array(val)

    keys.each_with_index do |key, index|
      # rewrite any nil (wildcard) keys in the dimension
      # to be our 'to-keep' val(s)
      if key.nil?
        rewrite_a.push([index, value])
        next
      end

      remove = key - value
      if remove == key
        prune_a.push(index)
        next
      end

      rewrite_a.push([index, key - remove]) if remove != []
    end
    [prune_a, rewrite_a]
  end

  def self.parse_range(key)
    match = key.match(/\A(\[|\()([0-9\.-]*),([0-9\.-]*)(\]|\))\z/)
    raise "unrecognized pattern #{key}" unless match

    lboundary, lhs, rhs, rboundary = match[1..4]
    # convert range values to float for comparison
    lhv = lhs.blank? ? nil : lhs.to_f
    rhv = rhs.blank? ? nil : rhs.to_f

    [lboundary == '(' ? :> : :>=, lhv, rhv, rboundary == ')' ? :< : :<=]
  end

  def self.rewrite_range(lb, lhv, rhv, rb)
    lboundary = lb == :> ? '(' : '['

    # even though numranges are float type, we don't want to output ".0"
    # for integer values.  So for values like that we convert to int
    # first before conversion to string
    lvalue = (lhv.to_i == lhv ? lhv.to_i : lhv).to_s
    rvalue = (rhv.to_i == rhv ? rhv.to_i : rhv).to_s
    rboundary = rb == :< ? ')' : ']'
    lboundary + lvalue + ',' + rvalue + rboundary
  end

  def self.parse_bounds(key)
    match = key.match(/\A *(<|>|<=|>=)? *([a-z_]+) *\z/)
    raise "unrecognized pattern #{key}" unless match

    opstr, ident = match[1..2]

    # data grid value is expressed as what to keep
    # we convert to the opposite (what to prune)
    [opposite_sign(opstr.to_sym), ident]
  end
end
