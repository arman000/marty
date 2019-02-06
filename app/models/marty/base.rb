class Marty::Base < ActiveRecord::Base
  self.table_name_prefix = 'marty_'
  self.abstract_class = true

  def self.mcfly_pt(pt)
    tb = table_name
    where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end

  class << self
    attr_accessor :struct_attrs
  end

  def self.get_struct_attrs
    self.struct_attrs ||=
      attribute_names - Mcfly::COLUMNS.to_a -
      (const_defined?('MCFLY_UNIQUENESS') &&
       const_get('MCFLY_UNIQUENESS') || []).map(&:to_s)
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
        dgh = to_h.stringify_keys.slice(
          'id', 'group_id', 'created_dt', 'metadata', 'data_type')
        Marty::DataGrid.lookup_grid_distinct_entry_h(pt, params, dgh)
      end
    end
    os
  end
end
