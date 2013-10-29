class Marty::McflyGridPanel < Marty::CmGridPanel
  def configure(c)
    super

    warped = Marty::Util.warped?

    c.enable_extended_search	= false
    c.enable_edit_in_form	&&= !warped
    c.prohibit_update		||= warped
    c.prohibit_delete		||= warped
    c.prohibit_create		||= warped
    #c.prohibit_read		||= !self.class.has_any_perm?

    # default sort all Mcfly grids with id
    c.data_store.sorters ||= {property: :id, direction: 'ASC'}
  end

  def get_data(*args)
    ts = Marty::Util.get_posting_time

    # normalize infinity
    ts = 'infinity' if Mcfly::Model::INFINITIES.member? ts

    # FIXME: may need to pass the scope in using the params hash in
    # args.  Not sure how the following will interact with sorting.
    tb = data_class.table_name
    data_class.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                     ts, ts).scoping do
      super
    end
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

      # NOTE - Monkey patching of this method eliminates the need to do this
      # The following is to bypass a Netzke bug in 0.8.4.
      # They're mistakenly setting :scopes (plural) in
      # default_fields_for_forms().  This is fixed as of 0.9.x.
      #c[:editor] ||= {}
      #c[:editor][:scope] = c[:scope]
    end
  end

private
  def self.mcfly_scope(sort_column)
    lambda { |r|
      t = Marty::Util.get_posting_time
      ts = (t == Float::INFINITY) ? 'infinity' : t
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
