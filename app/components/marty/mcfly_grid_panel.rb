class Marty::McflyGridPanel < Marty::CmGridPanel
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

    # Set Mcfly scoping
    c.scope = lambda { |r|
      ts = Mcfly.normalize_infinity(Marty::Util.get_posting_time)
      tb = data_class.table_name
      r.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", ts, ts)
    }
  end

  ######################################################################

  def augment_column_config(c)
    super

    name = c[:name]

    # Set mcfly_scope if the attribute is a mcfly association
    if !c[:scope] && data_adapter.association_attr?(name)
      assoc_name, assoc_method = name.split('__')
      begin
        aklass = data_class.reflect_on_association(assoc_name.to_sym).klass
      rescue
        raise "trouble finding #{assoc_name} assoc class on #{data_class}"
      end

      # FIXME: MCFLY_UNIQUENESS is the easiest way I can think of
      # figuring out if a class is Mcfly.
      if (aklass.const_get(:MCFLY_UNIQUENESS) rescue nil)
        c[:scope] = self.class.mcfly_scope(assoc_method || 'id')
      else
        c[:scope] = self.class.sorted_scope(assoc_method || 'id')
      end
    end
  end

# HACKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
  # # The basepack grid doesn't catch general exceptions.  We can get
  # # this if there's some sort of failure with saving to the DB.
  # # e.g. range violation.
  # def process_data_with_error_handling(data, operation)
  #   begin
  #     process_data_without_error_handling(data, operation)
  #   rescue => exc
  #     success = false
  #     flash :error => "Error: #{exc}"
  #   end
  # end

  # alias_method_chain :process_data, :error_handling

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
