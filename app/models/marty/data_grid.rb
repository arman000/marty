class Marty::DataGrid < Marty::Base
  # If data_type is nil, assume float
  DEFAULT_DATA_TYPE = 'float'

  INDEX_MAP = {
    'numrange'  => Marty::GridIndexNumrange,
    'int4range' => Marty::GridIndexInt4range,
    'integer'   => Marty::GridIndexInteger,
    'string'    => Marty::GridIndexString,
    'boolean'   => Marty::GridIndexBoolean,
  }.freeze

  ARRSEP = '|'.freeze
  NOT_STRING_START = 'NOT ('.freeze
  NOT_STRING_END = ')'.freeze
  NULL_STRING = 'NULL'.freeze

  class DataGridValidator < ActiveModel::Validator
    def validate(dg)
      dg.errors.add(:base, "'#{dg.data_type}' not a defined type or class") unless
        Marty::DataGrid.convert_data_type(dg.data_type)

      dg.errors.add(:base, 'data must be array of arrays') unless
        dg.data.is_a?(Array) && dg.data.all? { |a| a.is_a? Array }

      dg.errors.add(:base, 'metadata must be an array of hashes') unless
        dg.metadata.is_a?(Array) && dg.metadata.all? { |a| a.is_a? Hash }

      dg.errors.add(:base, 'metadata must contain only h/v dirs') unless
        dg.metadata.all? { |h| ['h', 'v'].member? h['dir'] }

      dg.errors.add(:base, 'metadata item attrs must be unique') unless
        dg.metadata.map { |h| h['attr'] }.uniq.length == dg.metadata.length

      dg.metadata.each do |inf|
        attr, type, keys, rs_keep =
          inf['attr'], inf['type'], inf['keys'], inf['rs_keep']

        if rs_keep.present?
          m = /\A *(<|<=|>|>=)? *([a-z][a-z_0-9]+) *\z/.match(rs_keep)
          unless m
            dg.errors.add(:base, "invalid grid modifier expression: #{rs_keep}")
            next
          end
        end

        dg.errors.add(:base, 'metadata elements must have attr/type/keys') unless
          attr && type && keys

        # enforce Delorean attr syntax (a bit Draconian)
        dg.errors.add(:base, "bad attribute '#{attr}'") unless
          /^[a-z][A-Za-z0-9_]*$/.match?(attr)

        dg.errors.add(:base, "unknown metadata type #{type}") unless
          Marty::DataGrid.type_to_index(type)

        dg.errors.add(:base, 'bad metadata keys') unless
          keys.is_a?(Array) && !keys.empty?
      end

      # Check key uniqueness of vertical/horizontal key
      # combinations. FIXME: ideally, we should also check for
      # array/range key subsumption.  Those will result in runtime
      # errors anyway when multiple hits are produced.
      v_keys = dg.dir_infos('v').map { |inf| inf['keys'] }
      h_keys = dg.dir_infos('h').map { |inf| inf['keys'] }

      v_zip_keys = v_keys.empty? ? [] : v_keys[0].zip(*v_keys[1..-1])
      h_zip_keys = h_keys.empty? ? [] : h_keys[0].zip(*h_keys[1..-1])

      dg.errors.add(:base, 'duplicate horiz. key combination') unless
        h_zip_keys.uniq.length == h_zip_keys.length

      dg.errors.add(:base, 'duplicate vertical key combination') unless
        v_zip_keys.uniq.length == v_zip_keys.length

      con_chk = []
      begin
        con_chk = Marty::DataGrid::Constraint.parse(dg.data_type, dg.constraint)
      rescue StandardError => e
        dg.errors.add(:base, "Error in constraint: #{e.message}")
      end
      data_check = Marty::DataGrid::Constraint.check_data(dg.data_type,
                                                          dg.data, con_chk)
      return if data_check.blank?

      data_check.each do |(err, x, y)|
        dg.errors.add(:base, "cell #{x}, #{y} fails constraint check") if
          err == :constraint
        dg.errors.add(:base, "cell #{x}, #{y} incorrect type") if
          err == :type
      end
    end
  end

  has_mcfly

  validates :name, :data, :metadata, presence: true

  mcfly_validates_uniqueness_of :name
  validates_with DataGridValidator
  validates_with Marty::NameValidator, field: :name

  gen_mcfly_lookup :lookup, [:name], cache: true, to_hash: true
  gen_mcfly_lookup :get_all, [], mode: nil, to_hash: true

  # FIXME: if the caller requests data as part of fields, there could
  # be memory concerns with caching since some data_grids have massive data
  delorean_fn :lookup_h, cache: true, sig: [2, 3] do |pt, name, fields = nil|
    fields ||= %w(id group_id created_dt metadata data_type name strict_null_mode)
    dga = mcfly_pt(pt).where(name: name).pluck(*fields).first
    dga && Hash[fields.zip(dga)]
  end

  delorean_fn :exists, cache: true, sig: 2 do |pt, name|
    Marty::DataGrid.mcfly_pt(pt).where(name: name).exists?
  end

  def self.get_struct_attrs
    self.struct_attrs ||= super + ['id', 'group_id', 'created_dt', 'name']
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
    if changed?
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
    save!
  end

  def self.type_to_index(type)
    # map given header type to an index class -- uses string index
    # for ruby classes.
    return INDEX_MAP[type] if INDEX_MAP[type]

    INDEX_MAP['string'] if (type.constantize rescue nil)
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

  PLV_DT_FMT = '%Y-%m-%d %H:%M:%S.%N6'

  def self.ruby_lookup_indices(h_passed, dgh)
    dgh['metadata'].each_with_object({ 'v' => [], 'h' => [] }) do |m, h|
      attr = m['attr']

      inc = h_passed[attr]

      val = (defined? inc.name) ? inc.name : inc

      dir = m['dir']

      m_type = m['type']
      nots = m.fetch('nots', [])
      wildcards = m.fetch('wildcards', [])

      unless dgh['strict_null_mode']
        next unless h_passed.key?(attr)

        # FIXME: Treating passed nil in the same way
        # as missing broke our lookups. Maybe we should get back to it later.
        # Before missing attribute would match anything,
        # while explicitly passed nil would only match wildcard keys
        # We want to be consistent and treat nil attribute as missing one,
        # unless it's a stict_null_mode, where nil would be explicitly mapped
        # to NULL keys
        # next if val.nil?
      end

      converted_val = if val.nil?
                        nil
                      elsif m_type == 'string'
                        val.to_s
                      elsif m_type == 'integer'
                        val.to_i
                      elsif m_type == 'numrange'
                        val.to_f
                      elsif m_type == 'int4range'
                        val.to_i
                      elsif m_type == 'boolean'
                        ActiveModel::Type::Boolean.new.cast(val)
                      else
                        val
                      end

      arr = m['keys'].each_with_index.map do |key_val, index|
        wildcard = wildcards.fetch(index, true) # By default empty value is a wildcard

        next index if key_val.nil? && wildcard

        not_condition = nots[index]

        check_res = if ['int4range', 'numrange'].include?(m_type)
                      raise 'Data Grid lookup failed' if val.nil?

                      checks = Marty::Util.pg_range_to_ruby(key_val)
                      checks.all? do |check|
                        converted_val.send(check[0], check[1])
                      end
                    elsif key_val.nil?
                      val.nil?
                    elsif m_type == 'boolean'
                      key_val == converted_val
                    else
                      key_val.include?(converted_val)
                    end

        if check_res && !not_condition
          next index
        elsif !check_res && not_condition
          next index
        end

        nil
      end.compact

      h[dir] << arr
    end
  end

  def self.ruby_lookup_grid_distinct(h_passed, dgh, ret_grid_data = false,
                                     distinct = true)

    grid = Marty::DataGrid.find(dgh['id'])
    indices = ruby_lookup_indices(h_passed, dgh)

    # We use the 0 as default, if there are no indices in that dir
    # Otherwise we find an intersection between all indices
    v_indices = if indices['v'].empty?
                  [0]
                else
                  indices['v'].reduce(:&)
                end

    h_indices = if indices['h'].empty?
                  [0]
                else
                  indices['h'].reduce(:&)
                end

    if distinct
      raise 'matches > 1' if v_indices.size > 1
      raise 'matches > 1' if h_indices.size > 1
    end

    v_index_min = v_indices.min
    h_index_min = h_indices.min

    if v_index_min.nil? || h_index_min.nil?
      nil_res = {
        'data' => nil,
        'name' => grid.name,
        'result' => nil,
        'metadata' => nil
      }

      return nil_res if grid.lenient && !ret_grid_data

      raise 'Data Grid lookup failed'
    end

    res2 = grid.data.dig(v_index_min, h_index_min)

    if ret_grid_data
      {
        'data' => grid.data,
         'name' => grid.name,
         'result' => res2,
         'metadata' => grid.metadata
      }
    else
      {
        'data' => nil,
        'name' => grid.name,
        'result' => res2,
        'metadata' => nil
      }
    end
  rescue StandardError => e
    ri = {
      'id' => grid.id,
      'group_id' => grid.group_id,
      'created_dt' => grid.created_dt
    }

    dg = grid.attributes.reject do |k, _|
      next true if !ret_grid_data && k == 'data'

      k == 'permissions'
    end

    raise "DG #{name}: Error in Ruby call: #{e.message} \n"\
      "params: #{h_passed}\n"\
      "results: #{[h_indices, v_indices]}\n"\
      "dg: #{grid.attributes}\n"\
      "ri: #{ri}"
  end

  def self.plpg_lookup_grid_distinct(h_passed, dgh, ret_grid_data = false,
                                     distinct = true)
    cd = dgh['created_dt']
    @@dtcache ||= {}
    @@dtcache[cd] ||= cd.strftime(PLV_DT_FMT)
    row_info = {
      'id'         => dgh['id'],
      'group_id'   => dgh['group_id'],
      'created_dt' => @@dtcache[cd]
    }

    h = dgh['metadata'].each_with_object({}) do |m, h|
      attr = m['attr']
      inc = h_passed.fetch(attr, :__nf__)
      next if inc == :__nf__

      val = (defined? inc.name) ? inc.name : inc
      h[attr] = val.is_a?(String) ?
                  ActiveRecord::Base.connection.quote(val)[1..-2] : val
    end

    fn     = 'lookup_grid_distinct'
    hjson  = "'#{h.to_json}'::JSONB"
    rijson = "'#{row_info.to_json}'::JSONB"
    params = "#{hjson}, #{rijson}, #{ret_grid_data}, #{distinct}"
    sql    = "SELECT #{fn}(#{params})"
    raw    = ActiveRecord::Base.connection.execute(sql)[0][fn]
    res    = JSON.parse(raw)

    if res['error']
      msg = res['error']
      parms, sqls, ress, dg = res['error_extra'].values_at(
        'params', 'sql', 'results', 'dg')

      raise "DG #{name}: Error in PLPG call: #{msg}\n"\
            "params: #{parms}\n"\
            "sqls: #{sqls}\n"\
            "results: #{ress}\n"\
            "dg: #{dg}\n"\
            "ri: #{row_info}" if res['error']
    end

    res
  end

  # this function is cached through lookup_grid_h_priv
  delorean_fn :lookup_grid_h, sig: 4 do |pt, dgn, h, distinct|
    dgh = lookup_h(pt, dgn)
    raise "#{dgn} grid not found" unless dgh
    raise "non-hash arg #{h}" unless Hash === h

    if dgh['data_type'] != 'Marty::DataGrid'
      # Narrow hash to needed attrs -- makes the cache work a lot
      # better in case the hash includes items not in grid
      # attrs. Can't do this for multi-grids since they pass down
      # their params.
      attrs = dgh['metadata'].map { |a| a['attr'] }
      h = h.slice(*attrs)
    end

    lookup_grid_h_priv(pt, dgh, h, distinct)
  end

  # private method used to cache lookup_grid_distinct_entry_h result
  delorean_fn :lookup_grid_h_priv,
              to_hash: false, private: true, cache: true, sig: 4 do |pt, dgh, h, distinct|
    lookup_grid_distinct_entry_h(
      pt, h, dgh, nil, true, false, distinct)['result']
  end

  # FIXME: using delorean_fn just for the caching -- this is
  # not expected to be called from Delorean.
  delorean_fn :find_class_instance, cache: true, sig: 3 do |pt, klass, v|
    if ::Marty::EnumHelper.pg_enum?(klass: klass)
      klass.find_by_name(v)
    else
      # FIXME: very hacky -- hard-coded name
      Marty::DataConversion.find_row(klass, { 'name' => v }, pt)
    end
  end

  def self.lookup_grid_distinct_entry_h(
    pt, h, dgh, visited = nil, follow = true,
    return_grid_data = false, distinct = true
  )

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

    vhash = if Rails.application.config.marty.data_grid_plpg_lookups &&
               Rails.env.test? # Keep plpg lookups for performance tests
              plpg_lookup_grid_distinct(h, dgh, return_grid_data, distinct)
            else
              ruby_lookup_grid_distinct(h, dgh, return_grid_data, distinct)
            end

    return vhash if vhash['result'].nil? || !dgh['data_type']

    c_data_type = Marty::DataGrid.convert_data_type(dgh['data_type'])

    return vhash if String === c_data_type

    res = vhash['result']

    v = if ::Marty::EnumHelper.pg_enum?(klass: res)
          c_data_type.find_by_name(res)
        elsif Marty::DataGrid == c_data_type
          follow ?
            Marty::DataGrid.lookup_h(pt, res) :
            Marty::DataGrid.lookup(pt, res)
        else
          Marty::DataConversion.find_row(c_data_type, { 'name' => res }, pt)
        end

    return vhash.merge('result' => v) unless
      Marty::DataGrid == c_data_type && follow

    visited ||= []

    visited << dgh['group_id']

    raise "#{self.class} recursion loop detected -- #{visited}" if
      visited.member?(v['group_id'])

    lookup_grid_distinct_entry_h(
      pt, h, v, visited, follow, return_grid_data, distinct)
  end

  def dir_infos(dir)
    metadata.select { |inf| inf['dir'] == dir }
  end

  def self.export_keys(inf)
    # should unify this with Marty::DataConversion.convert

    type = inf['type']
    nots = inf.fetch('nots', [])
    wildcards = inf.fetch('wildcards', [])
    klass = type.constantize unless INDEX_MAP[type]

    keys = inf['keys'].each_with_index.map do |v, index|
      wildcard = wildcards.fetch(index, true)

      next 'NULL' if v.nil? && !wildcard

      case type
      when 'numrange', 'int4range'
        Marty::Util.pg_range_to_human(v)
      when 'boolean'
        v.to_s
      when 'string', 'integer'
        v.map do |val|
          next 'NULL' if val.nil? && !wildcard

          val.to_s
        end.join(ARRSEP) if v
      else
        # assume it's an AR class
        v.each do |k|
          begin
            # check to see if class instance actually exists
            Marty::DataGrid.
              find_class_instance('infinity', klass, k) || raise(NoMethodError)
          rescue NoMethodError
            raise "instance #{k} of #{type} not found"
          end
        end if v
        v.join(ARRSEP) if v
      end
    end

    keys.each_with_index.map do |v, index|
      next v unless nots[index]

      add_not(v)
    end
  end

  # FIXME: this is only here to appease Netzke add_in_form
  def export=(text)
  end

  def export_array
    # add data type metadata row if not default
    lenstr = 'lenient' if lenient
    strict_null_mode_str = 'strict_null_mode' if strict_null_mode

    typestr = data_type unless [nil, DEFAULT_DATA_TYPE].member?(data_type)
    len_type = [lenstr, strict_null_mode_str, typestr].compact.join(' ')

    meta_rows = if len_type.present? || constraint.present?
                  [[len_type, constraint].compact]
                else
                  []
                end

    meta_rows += metadata.map do |inf|
      [inf['attr'], inf['type'], inf['dir'], inf['rs_keep'] || '']
    end

    v_infos, h_infos = dir_infos('v'), dir_infos('h')

    h_key_rows = h_infos.map do |inf|
      [nil] * v_infos.count + self.class.export_keys(inf)
    end

    transposed_v_keys = v_infos.empty? ? [[]] :
      v_infos.map { |inf| self.class.export_keys(inf) }.transpose

    data_rows = transposed_v_keys.each_with_index.map do |keys, i|
      keys + (data[i] || [])
    end

    [meta_rows, h_key_rows, data_rows]
  end

  def export
     # return null string when called from Netzke on add_in_form
     return '' if metadata.nil? && data.nil?

     meta_rows, h_key_rows, data_rows = export_array

     Marty::DataExporter.
       to_csv(meta_rows + [[]] + h_key_rows + data_rows,
              'col_sep' => "\t",
             ).
       gsub(/\"\"/, '') # remove "" to beautify output
  end

  delorean_fn :export, sig: 1 do |os|
    dg = find(os.id)
    dg.export
  end

  def self.null_value?(value, strict_null_mode)
    return false unless value == NULL_STRING
    return true if strict_null_mode

    raise 'NULL is not supported in grids without strict_null_mode'
  end

  def self.parse_fvalue(pt, passed_val, type, klass, strict_null_mode = false)
    return unless passed_val

    v = remove_not(passed_val)

    return nil if null_value?(v, strict_null_mode)

    case type
    when 'numrange', 'int4range'
      Marty::Util.human_to_pg_range(v)
    when 'integer'
      v.split(ARRSEP).map do |val|
        next nil if null_value?(val, strict_null_mode)

        Integer(val) rescue raise "invalid integer: #{val}"
      end.uniq.sort_by(&:to_i)
    when 'float'
      v.split(ARRSEP).map do |val|
        next nil if null_value?(val, strict_null_mode)

        Float(val) rescue raise "invalid float: #{val}"
      end.uniq.sort
    when 'string'
      res = v.split(ARRSEP).uniq.sort.map do |val|
        next nil if null_value?(val, strict_null_mode)

        val
      end

      raise 'leading/trailing spaces in elements not allowed' if res.any? do |x|
        x != x&.strip
      end

      raise '0-length string not allowed' if res.any? do |x|
        x&.empty?
      end

      res
    when 'boolean'
      return nil if null_value?(v, strict_null_mode)

      case v.downcase
      when 'true', 't'
        true
      when 'false', 'f'
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
          Marty::DataGrid.
            find_class_instance(pt, klass, k) || raise(NoMethodError)
        rescue NoMethodError
          raise "instance #{k} of #{type} not found"
        end
      end
      res
    end
  end

  def self.maybe_get_klass(type)
      type.constantize unless INDEX_MAP[type] || type == 'float'
  rescue NameError
      raise "unknown header type/klass: #{type}"
  end

  def self.parse_keys(pt, keys, type, strict_null_mode)
    klass = maybe_get_klass(type)

    keys.map do |v|
      parse_fvalue(pt, v, type, klass, strict_null_mode)
    end
  end

  def self.parse_nots(keys)
    keys.map do |v|
      next false unless v

      v.starts_with?(NOT_STRING_START) && v.ends_with?(NOT_STRING_END)
    end
  end

  def self.parse_wildcards(keys)
    keys.map(&:nil?)
  end

  # parse grid external representation into metadata/data
  def self.parse(pt, grid_text, options)
    options[:headers] ||= false
    options[:col_sep] ||= "\t"

    pt ||= 'infinity'

    rows = CSV.new(grid_text, options).to_a
    blank_index = rows.find_index { |x| x.all?(&:nil?) }

    raise 'must have a blank row separating metadata' unless
      blank_index

    raise "can't import grid with trailing blank column" if
      rows.map { |r| r.last.nil? }.all?

    raise "last row can't be blank" if rows[-1].all?(&:nil?)

    data_type, lenient, strict_null_mode = nil, false, false

    # check if there's a data_type definition
    dt, constraint, *x = rows[0]
    if dt && x.all?(&:nil?)
      dts = dt.split

      lenient = dts.delete('lenient').present?
      strict_null_mode = dts.delete('strict_null_mode').present?
      data_type = dts.first
      raise "bad data type '#{dt}'" if dts.size > 1
    end

    constraint = nil if x.first.in?(['v', 'h'])

    start_md = constraint || data_type || lenient || strict_null_mode ? 1 : 0

    rows_for_metadata = rows[start_md...blank_index]
    metadata = rows_for_metadata.map do |attr, type, dir, rs_keep, key|
      raise 'metadata elements must include attr/type/dir' unless
        attr && type && dir
      raise "bad dir #{dir}" unless ['h', 'v'].member? dir
      raise "unknown metadata type #{type}" unless
        Marty::DataGrid.type_to_index(type)

      keys = key && parse_keys(pt, [key], type, strict_null_mode)
      nots = key && parse_nots([key])
      wildcards = key && parse_wildcards([key])

      res = {
        'attr' => attr,
        'type' => type,
        'dir'  => dir,
        'keys' => keys,
        'nots' => nots,
        'wildcards' => wildcards,
      }
      res['rs_keep'] = rs_keep if rs_keep
      res
    end

    v_infos = metadata.select { |inf| inf['dir'] == 'v' }
    h_infos = metadata.select { |inf| inf['dir'] == 'h' }

    # keys+data start right after blank_index
    data_index = blank_index + 1

    # process horizontal key rows
    h_infos.each_with_index do |inf, i|
      row = rows[data_index + i]

      raise "horiz. key row #{data_index + i} must include nil starting cells" if
        row[0, v_infos.count].any?

      inf['keys'] = parse_keys(pt, row[v_infos.count, row.count], inf['type'], strict_null_mode)
      inf['nots'] = parse_nots(row[v_infos.count, row.count])
      inf['wildcards'] = parse_wildcards(row[v_infos.count, row.count])
    end

    raise 'horiz. info keys length mismatch!' unless
      h_infos.map { |inf| inf['keys'].length }.uniq.count <= 1

    data_rows = rows[data_index + h_infos.count, rows.count]

    # process vertical key columns
    v_key_cols = data_rows.map { |r| r[0, v_infos.count] }.transpose

    v_infos.each_with_index do |inf, i|
      inf['keys'] = parse_keys(pt, v_key_cols[i], inf['type'], strict_null_mode)
      inf['nots'] = parse_nots(v_key_cols[i])
      inf['wildcards'] = parse_wildcards(v_key_cols[i])
    end

    raise 'vert. info keys length mismatch!' unless
      v_infos.map { |inf| inf['keys'].length }.uniq.count <= 1

    c_data_type = Marty::DataGrid.convert_data_type(data_type)

    raise "bad data type #{data_type}" unless c_data_type

    # based on data type, decide to check using convert or instance
    # lookup.  FIXME: DRY.

    if String === c_data_type
      tsym = c_data_type.to_sym

      data = data_rows.map do |r|
        r[v_infos.count, r.count].map do |v|
          next v unless v

          Marty::DataConversion.convert(v, tsym)
        end
      end
    else
      data = data_rows.map do |r|
        r[v_infos.count, r.count].map do |v|
          next v unless v

          next v if Marty::DataGrid.
                         find_class_instance(pt, c_data_type, v)

          raise "can't find key '#{v}' for class #{data_type}"
        end
      end
    end

    {
      metadata: metadata,
      data: data,
      data_type: data_type,
      lenient: lenient,
      strict_null_mode: strict_null_mode,
      constraint: constraint,
    }
  end

  def self.create_from_import(name, import_text, created_dt = nil)
    parsed_result = parse(created_dt, import_text, {})

    metadata = parsed_result[:metadata]
    data = parsed_result[:data]
    data_type = parsed_result[:data_type]
    lenient = parsed_result[:lenient]
    constraint = parsed_result[:constraint]
    strict_null_mode = parsed_result[:strict_null_mode]

    dg                  = new
    dg.name             = name
    dg.data             = data
    dg.data_type        = data_type
    dg.lenient          = lenient
    dg.strict_null_mode = strict_null_mode
    dg.metadata         = metadata
    dg.created_dt       = created_dt if created_dt
    dg.constraint       = constraint
    dg.save!
    dg
  end

  def update_from_import(name, import_text, created_dt = nil)
    parsed_result = self.class.parse(created_dt, import_text, {})

    new_metadata = parsed_result[:metadata]
    data = parsed_result[:data]
    data_type = parsed_result[:data_type]
    lenient = parsed_result[:lenient]
    constraint = parsed_result[:constraint]
    strict_null_mode = parsed_result[:strict_null_mode]

    self.name             = name
    self.data             = data
    self.data_type        = data_type
    self.lenient          = !!lenient
    self.strict_null_mode = strict_null_mode
    # Otherwise changed will depend on order in hashes
    self.metadata         = new_metadata unless metadata == new_metadata
    self.constraint       = constraint
    self.created_dt       = created_dt if created_dt
    save!
  end

  # FIXME: should be private
  def build_index
    # create indices for the metadata
    metadata.each do |inf|
      attr = inf['attr']
      type = inf['type']
      keys = inf['keys']
      nots = inf.fetch('nots', [])

      # find index class
      idx_class = Marty::DataGrid.type_to_index(type)

      keys.each_with_index do |k, index|
        gi              = idx_class.new
        gi.attr         = attr
        gi.key          = k
        gi.created_dt   = created_dt
        gi.data_grid_id = group_id
        gi.index        = index
        gi.not          = nots[index] || false
        gi.save!
      end
    end
  end

  private

  def self.parse_range(key)
    match = key.match(/\A(\[|\()([0-9\.-]*),([0-9\.-]*)(\]|\))\z/)
    raise "unrecognized pattern #{key}" unless match

    lboundary, lhs, rhs, rboundary = match[1..4]
    # convert range values to float for comparison
    lhv = lhs.blank? ? nil : lhs.to_f
    rhv = rhs.blank? ? nil : rhs.to_f

    [lboundary == '(' ? :> : :>=, lhv, rhv, rboundary == ')' ? :< : :<=]
  end

  def self.remove_not(string)
    return string unless string.starts_with?(NOT_STRING_START)
    return string unless string.ends_with?(NOT_STRING_END)

    remove_from_left = NOT_STRING_START.size
    remove_from_right = NOT_STRING_END.size
    string.slice(remove_from_left...-remove_from_right)
  end

  def self.add_not(string)
    "#{NOT_STRING_START}#{string}#{NOT_STRING_END}"
  end
end
