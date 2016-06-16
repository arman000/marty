class Marty::McflyGridPanel < Marty::Grid
  def configure(c)
    super

    warped = Marty::Util.warped?

    c.editing  = !warped && c.editing || :none

    [:update, :delete, :create].each do |perm|
      c.permissions[perm] = false if warped
    end

    # default sort all Mcfly grids with id
    c.store_config.merge!({sorters: [{property: :id, direction: 'ASC'}]})
  end

  def get_records(params)
   ts = Mcfly.normalize_infinity(Marty::Util.get_posting_time)
   tb = model.table_name

   model.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                     ts, ts).scoping do
      super
    end
  end

  ######################################################################

  def augment_attribute_config(c)
    super

    # Set mcfly_scope if the attribute is a mcfly association
    if !c[:scope] && model_adapter.association_attr?(c)
      assoc_name, assoc_method = c[:name].split('__')
      begin
        aklass = model.reflect_on_association(assoc_name.to_sym).klass
      rescue
        raise "trouble finding #{assoc_name} assoc class on #{model}"
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
