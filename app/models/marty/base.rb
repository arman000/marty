class Marty::Base < ActiveRecord::Base
  self.table_name_prefix = "marty_"
  self.abstract_class = true

  def self.mcfly_pt(pt)
    tb = self.table_name
    self.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end
  MCFLY_PT_SIG = [1, 1]

  # FIXME: hacky signatures for AR queries
  COUNT_SIG    = [0, 0]
  DISTINCT_SIG = [0, 100]
  FIRST_SIG    = [0, 1]
  GROUP_SIG    = [1, 100]
  JOINS_SIG    = [1, 100]
  LAST_SIG     = [0, 1]
  LIMIT_SIG    = [1, 1]
  NOT_SIG      = [1, 100]
  ORDER_SIG    = [1, 100]
  PLUCK_SIG    = [1, 100]
  SELECT_SIG   = [1, 100]
  WHERE_SIG    = [0, 100]

  class << self
    attr_accessor :struct_attrs
  end

  def self.get_struct_attrs
    self.struct_attrs ||=
      self.attribute_names - Mcfly::COLUMNS.to_a -
      (self.const_defined?('MCFLY_UNIQUENESS') &&
       self.const_get('MCFLY_UNIQUENESS') || []).map(&:to_s)
  end

  def self.get_final_attrs
    final_attrs = get_struct_attrs
    return final_attrs if final_attrs.present?

    # otherwise raise with error line
    raise "Marty::Base: no attributes for #{self}"

    # for more detailed debugging use this code instead
    # st = caller.detect{|s|s.starts_with?('DELOREAN__')}
    # re = /DELOREAN__([A-Z][a-zA-Z0-9]*)[:]([0-9]+)[:]in `([a-z_0-9]+)__D'/
    # m = re.match(st)
    # if !m
    #   st = "No attributes #{st} #{self}"
    #   puts st unless File.readlines(Rails.root.join('tmp','dlchk')).
    #                   map(&:chop).detect{|l|l==st}
    # else
    #   loc = "#{m[1]}::#{self}::#{m[2]}"
    #   str = "*** No attributes %-40s %-20s   %s" % [loc, m[3], attr]
    #   puts str unless File.readlines(Rails.root.join('tmp','dlchk')).
    #                    map(&:chop).detect{|l|l==str}
    # end
  end

  def self.make_hash(inst)
    fa = get_final_attrs
    inst.attributes.slice(*fa)
  end

  def self.make_openstruct(inst)
    return nil unless inst
    fa = get_final_attrs
    os = OpenStruct.new(inst.attributes.slice(*fa))
    if self == Marty::DataGrid
      def os.lookup_grid_distinct_entry(pt, params)
        dgh = self.to_h.stringify_keys.slice(
          "id", "group_id", "created_dt", "metadata", "data_type")
        Marty::DataGrid.lookup_grid_distinct_entry_h(pt, params, dgh)
      end
    end
    os
  end
end
