class Marty::BaseRule < Marty::Base
  self.table_name = 'marty_rules'
  has_mcfly

  def self.attr_info
    {}
  end
  def self.guard_info
    {}
  end

  def chkrange(v)
    v.match(/\A(\[|\()([0-9\.-]*),([0-9\.-]*)(\]|\))\z/)
  end
  def gettypes(v)
    types = []
    types << :string if v.is_a?(String)
    types += [:int, :integer] if Integer(v) rescue nil
    types << :float if Float(v) rescue nil
    types << :date if Date.parse(v) rescue nil
    types << :datetime if DateTime.parse(v) rescue nil
    types << :range if chkrange(v) rescue nil
    types << :boolean if [true, false].include?(v)
    types
  end
  def check(name, h, errtype)
    multi, type, enum, values, req = h.values_at(:multi, :type, :enum, :values,
                                                 :required)
    ns = "'#{name}'"
    expmulti = multi ? 'multi' : 'single'
    v = errtype == :attributes ? attrs[name] : simple_guards[name]
    type ||= :string
    return errors[errtype] << "- Required field #{ns} is missing" if
      v.blank? && req
    return if v.blank?
    gotmulti = v.is_a?(Array) ? 'multi' : 'single'
    return errors[errtype] << "- Wrong arity for #{ns} (expected #{expmulti} "\
                              "got #{gotmulti})" if expmulti != gotmulti
    vs = [v].flatten
    vs.each do |vv|
      return errors[errtype] << "- Wrong type for #{ns}" unless
        gettypes(vv).member?(type)
    end
    return unless enum || values
    vals = enum && enum::VALUES || values
    bad = (vs - vals)
    p = bad.count > 1 ? 's' : ''
    return errors[errtype] <<
           %Q(- Bad value#{p} '#{bad.join("', '")}' for #{ns}) if bad.present?
  end
  def validate
    self.class.attr_info.each { |name, h| check(name, h, :attributes) }
    self.class.guard_info.each { |name, h| check(name, h, :guards) }
    if computed_guards.present? || computed_results.present?
      begin
        eclass = attrs["engine"].try(:constantize) || Marty::RuleScriptSet
        engine = eclass.new('infinity').get_engine(self)
      rescue => e
        f = get_parse_error_field(e)
        return errors[:computed] = "- Error in field #{f}: #{e} "
      end
    end
    grids.each do |vn, gn|
      return errors[:grids] << "- Bad grid name '#{gn}' for '#{vn}'" unless
        gn.blank? || Marty::DataGrid.lookup('infinity', gn)
    end
    # errors in computed jsons are detected earlier by creating an engine
    err = simple_results.delete("~~ERROR~~")
    errors[:simple_results] = " - " + err.capitalize if err
  end

  def get_parse_error_field(exc)
    e = attrs['engine']
    kl = e && e.constantize || Marty::RuleScriptSet
    line = exc.line ? exc.line - kl.body_lines : 0
    errs = {}
    errs[:computed_guards] = computed_guards.keys.count

    # 1 code line per each grid
    # plus 2 per each unique grid
    # plus 2 code lines for pt and params__
    gridlines = grids.present? ? 2 + grids.values.to_set.count * 2 +
                                 grids.keys.count : 0
    errs[:grids] = gridlines
    errs[:computed_results] = computed_results.keys.count
    line_count = 0
    errs.each do |k,v|
      line_count += v
      return k if line <= line_count
    end
    errs.keys.last
  end


  validates_presence_of :name
  mcfly_validates_uniqueness_of :name
  validate :validate

  before_validation(on: [:create, :update]) do
    self.attrs             ||= {}
    self.simple_guards     ||= {}
    self.computed_guards   ||= {}
    self.grids             ||= {}
    self.simple_results    ||= {}
    self.computed_results  ||= {}
  end

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  cached_mcfly_lookup :lookup_id, sig: 2 do
    |pt, group_id|
    find_by_group_id group_id
  end

  class DupKeyError < StandardError
    def initialize(key, lineno)
      @key    = key
      @lineno = lineno
    end
    def message
      "keyword '#{@key}' specified more than once (line #{@lineno})"
    end
  end

  def self.simple_to_hashstr(s, unquoted)
    pairs = []
    keys = Set.new
    s.lines.each.with_index(1) do |line, idx|
      next if /\A\s*\z/.match(line)
      line.chomp!
      begin
        m = /\A\s*([a-z0-9][a-z0-9_]*)\s*=\s*(.*)\s*\z/.match(line)
        k, v = m[1], m[2]
        v = unquoted ? [v].to_json[1..-2] : v
        raise DupKeyError.new(k, idx) if keys.include?(k)
        raise unless /\A['"].*['"]\z/.match(v)
        keys << k
      rescue DupKeyError => e
        raise
      rescue => e
        raise "syntax error on line #{idx}"
      end
      pairs << [k, v]
    end

    kvs = pairs.map { |k, v| %Q("#{k}":#{v}) }.join(",")
    "{#{kvs}}"
  end

  def self.hash_to_simple(h, unquoted)
    return unless h && h.present?
    fmt = '%-' +  h.keys.map(&:length).max.to_s + 's = %s'
    h.map do |k, v|
      vstr = unquoted ? v : [v].to_json[1..-2]
      fmt % [k, vstr]
    end.join("\n") || ''
  end

  def compute(params)
    eclass = attrs["engine"].try(:constantize) || Marty::RuleScriptSet
    engine = eclass.new(params["pt"]).get_engine(self) if
      computed_guards.present? || computed_results.present?

    if computed_guards.present?
      cg_keys = computed_guards.keys
      begin
        res = engine.evaluate(eclass.node_name,
                              cg_keys,
                              params.clone)
      rescue => e
        raise e, "Error (guard) in rule '#{id}:#{name}': #{e}", e.backtrace
      end
      return Hash[cg_keys.zip(res).select{|k,v| !v}] unless res.all?
    end

    if computed_results.present?
      #fixme except tmp vars
      compute_keys = computed_results.keys + grids.keys
      begin
        eval_result = engine.evaluate(
          eclass.node_name,
          compute_keys,
          params + {
            "params__" => params
          })
      rescue => e
        raise e, "Error (result) in rule '#{id}:#{name}': #{e}", e.backtrace
      end
      Hash[compute_keys.zip(eval_result)]
    end
  end

  def self.get_subq(field, subfield, multi, type, vraw)
    arrow = multi || ![:range, :string, :date, :datetime].include?(type) ?
              "->" : "->>"
    op = multi || type == :range ? "@>" : "="
    value0 = [:string, :date, :datetime].include?(type) ?
               ActiveRecord::Base.connection.quote(vraw) :
               type == :range ? vraw.to_f :
                 "'#{vraw}'::jsonb"
    value = multi ? %Q('["%s"]') % value0[1..-2] : value0
    fieldcast = type == :range ? "::numrange" : ''
    "(#{field}#{arrow}'#{subfield}')#{fieldcast} #{op} #{value}"
  end

  def self.get_matches_(pt, attrs, params)
    q = select("DISTINCT ON (name) *")

    m = lambda { |isnull, dbfield, h, k, vraw|
      next unless h[k]
      multi, type = h[k].values_at(:multi, :type)
      filts = [vraw].flatten.map do |v|
        qstr = get_subq(dbfield, k, multi, type, v)
      end.join(" OR ")
      isn = isnull ? "#{dbfield}->'#{k}' IS NULL OR" : ''
      q = q.where("(#{isn} #{filts})")
    }
    attrs.each { |k, v| m.call(false, 'attrs', attr_info, k, v) }
    params.each { |k, v| m.call(true, 'simple_guards', guard_info, k, v) }
  #  puts q.to_sql
    q.order(:name)
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end
end
