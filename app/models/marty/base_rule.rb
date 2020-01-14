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

    vals = enum&.values || values.to_set
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

    cg_err = computed_guards.delete('~~ERROR~~')
    errors[:computed] <<
      "- Error in rule '#{name}' field 'computed_guards': #{cg_err.capitalize}" if cg_err

    res_err = results.delete('~~ERROR~~')
    errors[:computed] <<
      "- Error in rule '#{name}' field 'results': #{res_err.capitalize}" if res_err
  end

  validates :name, presence: true
  validate :validate
  validate :validate_simple_guard_options

  before_validation(on: [:create, :update]) do
    self.simple_guards         ||= {}
    self.simple_guards_options ||= {}
    self.computed_guards       ||= {}
    self.grids                 ||= {}
    self.results               ||= {}
  end

  before_create do
    self.class.guard_info.each do |k, v|
      next if !v.include?(:default) || self.simple_guards.include?(k)

      self.simple_guards[k] = v[:default]
    end
  end

  private

  def validate_simple_guard_options
    simple_guards_options.each do |guard_name, value|
      field_path = "'simple_guard_options' -> '#{guard_name}' -> 'not'"

      guard_info = self.class.guard_info[guard_name.to_s]

      if guard_info.blank?
        errors[:simple_guards_options] <<
          "- Error in rule '#{name}' #{field_path}."\
          "Guard '#{guard_name}' doesn't exist."

        next
      end

      not_is_allowed = guard_info.fetch(:allow_not, true)

      not_field = value['not'] || value[:not]
      next if not_field.nil?

      if not_field.is_a?(TrueClass)
        next if not_is_allowed

        errors[:simple_guards_options] <<
          "- Error in rule '#{name}' #{field_path}. True value is not allowed"
        next
      end

      next if not_field.is_a?(FalseClass)

      errors[:simple_guards_options] <<
        "- Error in rule '#{name}' #{field_path} field must be a boolean"
    end
  end

  class << self
    def get_subq(field, subfield, multi, type, vraw)
      arrow = multi || ![:range, :string, :date, :datetime].include?(type) ?
                '->' : '->>'
      op = multi || type == :range ? '@>' : '='
      value0 = [:string, :date, :datetime].include?(type) ?
                 ActiveRecord::Base.connection.quote(vraw) :
                 type == :range ? vraw.to_f :
                   "'#{vraw}'::jsonb"
      value = multi ? %Q('["%s"]') % value0[1..-2] : value0
      fieldcast = type == :range ? '::numrange' : ''
      "(#{field}#{arrow}'#{subfield}')#{fieldcast} #{op} #{value}"
    end

    def get_matches_(_pt, attrs, params)
      q = select('DISTINCT ON (name) *').where(attrs)

      h = guard_info

      params.each do |k, vraw|
        use_k = (h[k] && k) ||
                (h[k + '_array'] && k + '_array') ||
                (h[k + '_range'] && k + '_range')

        next unless use_k

        param_guard_info = h[use_k]

        multi = param_guard_info[:multi]
        type = param_guard_info[:type]
        with_not = param_guard_info.fetch(:allow_not, true)

        filts = [vraw].flatten.map do |v|
          qstr = get_subq('simple_guards', use_k, multi, type, v)
        end.join(' OR ')

        condition = if with_not
                      "CASE
                       WHEN (simple_guards_options->'#{use_k}'->>'not')::boolean
                       THEN simple_guards->'#{use_k}' IS NULL OR NOT #{filts}
                       ELSE simple_guards->'#{use_k}' IS NULL OR #{filts}
                       END
                      "
                    else
                      "simple_guards->'#{use_k}' IS NULL OR #{filts}"
                    end

        q = q.where(condition)
      end
      # print q.to_sql
      q.order(:name)
    end
  end
end
