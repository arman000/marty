class Marty::McflyGridPanel < Marty::Grid
  def configure(c)
    super

    warped = Marty::Util.warped?

    c.enable_extended_search = false
    c.enable_edit_in_form    &&= !warped
    c.prohibit_update        ||= warped
    c.prohibit_delete        ||= warped
    c.prohibit_create        ||= warped
    #c.prohibit_read         ||= !self.class.has_any_perm?

    # default sort all Mcfly grids with id
    c.data_store.sorters ||= {property: :id, direction: 'ASC'}
  end

  def get_records(params)
   ts = Mcfly.normalize_infinity(Marty::Util.get_posting_time)
   tb = data_class.table_name

    data_class.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                     ts, ts).scoping do
      super
    end
  end

  ######################################################################

  def augment_column_config(c)
    super

    # Set mcfly_scope if the attribute is a mcfly association
    if !c[:scope] && data_adapter.association_attr?(c)
      assoc_name, assoc_method = c[:name].split('__')
      begin
        aklass = data_class.reflect_on_association(assoc_name.to_sym).klass
      rescue
        raise "trouble finding #{assoc_name} assoc class on #{data_class}"
      end

      c[:scope] = Mcfly.has_mcfly?(aklass) ?
      self.class.mcfly_scope(assoc_method || 'id') :
        self.class.sorted_scope(assoc_method || 'id')
    end
  end

private
  def self.mcfly_scope(sort_column)
    lambda { |r|
      ts = Mcfly.normalize_infinity(Marty::Util.get_posting_time)
      r.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts).
      order(sort_column.to_sym)
    }
  end

  def self.sorted_scope(sort_column)
    lambda { |r|
      r.order(sort_column.to_sym)
    }
  end
end
