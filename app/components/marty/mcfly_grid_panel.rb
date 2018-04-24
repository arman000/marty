class Marty::McflyGridPanel < Marty::Grid
  def configure(c)
    super

    warped = Marty::Util.warped?

    c.editing  = !warped && c.editing || :none

    [:update, :delete, :create].each do |perm|
      c.permissions[perm] = false if warped
    end
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

  client_class do |c|
    c.init_component = l(<<-JS)
      function() {
         this.callParent();

         // dup is a non standard button, so we have to explicitly manage
         // its clickability
         this.getSelectionModel().on('selectionchange', function(selModel) {
            this.actions.dupInForm &&
                this.actions.dupInForm.setDisabled(!selModel.hasSelection() ||
                                                   !this.permissions.create);
         }, this);
      }
   JS
  end

  client_class do |c|
    c.include :dup_in_form
  end

  action :dup_in_form do |a|
    a.hidden   = !config[:permissions][:create]
    a.icon     = :page_copy
    a.disabled = true
  end

  # edit-in-form submit with dup support
  endpoint :edit_window__edit_form__submit do |params|

    if params["dup"]
      # FIXME: copied from basepack grid endpoint
      # :add_window__add_form__netzke_submit

      params[:data] = ActiveSupport::JSON.
                      decode(params[:data]).merge(id: nil).to_json

      client.merge!(component_instance(:add_window).
                   component_instance(:add_form).
                   invoke_endpoint(:submit, [params]))

      on_data_changed if client.netzke_set_form_values.present?
      client.delete(:netzke_set_form_values)
    else
      # FIXME: copied from basepack grid endpoint
      # :edit_window__edit_form__netzke_submit
      client.merge!(component_instance(:edit_window).
                     component_instance(:edit_form).
                     invoke_endpoint(:submit, [params]))
      on_data_changed if client.netzke_set_form_values.present?
      client.delete(:netzke_set_form_values)
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
