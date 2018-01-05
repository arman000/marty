class Marty::BaseRule < Marty::Base
  self.abstract_class = true
  has_mcfly

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
  def check(name, h)
    multi, type, enum, values, req = h.values_at(:multi, :type, :enum, :values,
                                                 :required)
    ns = "'#{name}'"
    expmulti = multi ? 'multi' : 'single'
    errtype = :guards
    v = simple_guards[name]
    type ||= :string
    return errors[errtype] << "- Required field #{ns} is missing" if
      v.blank? && req
    return if v.blank?
    gotmulti = v.is_a?(Array) ? 'multi' : 'single'
    return errors[errtype] << "- Wrong arity for #{ns} (expected #{expmulti} "\
                              "got #{gotmulti})" if expmulti != gotmulti
    vs = [v].flatten.to_set
    vs.each do |vv|
      return errors[errtype] << "- Wrong type for #{ns}" unless
        gettypes(vv).member?(type)
    end
    return unless enum || values
    vals = enum && enum::VALUES || values.to_set
    bad = (vs - vals)
    p = bad.count > 1 ? 's' : ''
    return errors[errtype] <<
           %Q(- Bad value#{p} '#{bad.to_a.join("', '")}' for #{ns}) if bad.present?
  end
  def validate
    self.class.guard_info.each { |name, h| check(name, h) }
    grids.each do |vn, gn|
      return errors[:grids] << "- Bad grid name '#{gn}' for '#{vn}'" unless
        gn.blank? || Marty::DataGrid.lookup('infinity', gn)
    end
    cg_err = computed_guards.delete("~~ERROR~~")
    errors[:computed] <<
      "- Error in field computed_guards: #{cg_err.capitalize}" if cg_err
    res_err = results.delete("~~ERROR~~")
    errors[:computed] <<
      "- Error in field results: #{res_err.capitalize}" if res_err

    same_name_diff_guards = self.class.
        where(obsoleted_dt: 'infinity', name: self.name).
        # id is nil on new rules
        where.not(id: self.id).
        where("simple_guards != '#{self.simple_guards.to_json}'")

    errors[:base] =
      "Can't have rule with same name and different type/guards" +
      " - #{self.name}" if same_name_diff_guards.exists?

  end

  validates_presence_of :name
  validate :validate

  before_validation(on: [:create, :update]) do
    self.simple_guards     ||= {}
    self.computed_guards   ||= {}
    self.grids             ||= {}
    self.results           ||= {}
    # identify result values that are fixed, stash them (removing quotes)
    fixed = self.results.each_with_object({}) do |(k, v), h|
      jp = JSON.parse("[#{v}]") rescue nil
      next unless jp
      h[k] = jp[0]
    end
    self.fixed_results = fixed
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

  def self.simple_to_hashstr(s)
    pairs = []
    keys = Set.new
    s.lines.each.with_index(1) do |line, idx|
      next if /\A\s*\z/.match(line)
      line.chomp!
      begin
        m = /\A\s*([a-z0-9][a-z0-9_]*)\s*=\s*(.*)\s*\z/.match(line)
        k, v = m[1], m[2]
        v = [v].to_json[1..-2]
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

  def self.hash_to_simple(h)
    return unless h && h.present?
    fmt = '%-' +  h.keys.map(&:length).max.to_s + 's = %s'
    h.map do |k, vstr|
      fmt % [k, vstr]
    end.join("\n") || ''
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

    q = select("DISTINCT ON (name) *").where(attrs)

    params.each do |k, vraw|
      h = guard_info
      next unless h[k]
      multi, type = h[k].values_at(:multi, :type)
      filts = [vraw].flatten.map do |v|
        qstr = get_subq('simple_guards', k, multi, type, v)
      end.join(" OR ")
      isn = "simple_guards->'#{k}' IS NULL OR"

      q = q.where("(#{isn} #{filts})")
    end
    #print q.to_sql
    q.order(:name)
  end

end
