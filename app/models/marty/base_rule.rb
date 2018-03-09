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
    types << :boolean if [true, false, 'True', 'False'].include?(v)
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
      "- Error in rule '#{name}' field 'computed_guards': #{cg_err.capitalize}" if cg_err
    res_err = results.delete("~~ERROR~~")
    errors[:computed] <<
      "- Error in rule '#{name}' field 'results': #{res_err.capitalize}" if res_err
  end

  validates_presence_of :name
  validate :validate

  before_validation(on: [:create, :update]) do
    self.simple_guards     ||= {}
    self.computed_guards   ||= {}
    self.grids             ||= {}
    self.results           ||= {}
  end

  before_create do
    self.class.guard_info.each do |k,v|
      next if !v.include?(:default) || self.simple_guards.include?(k)
      self.simple_guards[k] = v[:default]
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

    q = select("DISTINCT ON (name) *").where(attrs)

    params.each do |k, vraw|
      h = guard_info
      use_k = (h[k] && k) ||
              (h[k+"_array"] && k+"_array") ||
              (h[k+"_range"] && k+"_range")
      next unless use_k
      multi, type = h[use_k].values_at(:multi, :type)
      filts = [vraw].flatten.map do |v|
        qstr = get_subq('simple_guards', use_k, multi, type, v)
      end.join(" OR ")
      isn = "simple_guards->'#{use_k}' IS NULL OR"

      q = q.where("(#{isn} #{filts})")
    end
    #print q.to_sql
    q.order(:name)
  end

end
