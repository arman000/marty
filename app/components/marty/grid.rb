class Marty::Grid < ::Netzke::Grid::Base

  extend ::Marty::Permissions

  has_marty_permissions read: :any

  def configure_form_window(c)
    super

    c.klass = Marty::RecordFormWindow

    # Fix Add in form/Edit in form modal popup width
    # Netzke 0.10.1 defaults width to 80% of screen which is too wide
    # for a form where the fields are stacked top to bottom
    # Netzke 0.8.4 defaulted width to 400px - let's make it a bit wider
    c.width = 475
  end

  client_class do |c|
    # For some reason the grid update function was removed in Netzke
    # 0.10.1.  So, add it here.
    c.cm_update = l(<<-JS)
    function() {
      this.store.load();
    }
    JS

    c.do_view_in_form = l(<<-JS)
    function(record){
      this.netzkeLoadComponent("view_window", {
        serverConfig: {record_id: record.id},
        callback: function(w){
          w.show();
          w.on('close', function(){
            if (w.closeRes === "ok") {
              this.netzkeReloadStore();
            }
          }, this);
        }});
    }
    JS
  end

  component :view_window do |c|
    configure_form_window(c)
    c.excluded = !allowed_to?(:read)
    c.items    = [:view_form]
    c.title    = I18n.t('netzke.grid.base.view_record',
                        model: model.model_name.human)
  end

  def class_can?(op)
    self.class.can_perform_action?(op)
  end

  def configure(c)
    super

    c.permissions = {
      create: class_can?(:create),
      read:   class_can?(:read),
      update: class_can?(:update),
      delete: class_can?(:delete)
    }

    c.paging       = :buffered
    c.editing      = :in_form
    c.store_config = {page_size: 30}
  end

  def has_search_action?
    false
  end

  def get_json_sorter(json_col, field)
    lambda do |r, dir|
      r.order("#{json_col} ->> '#{field}' " + dir.to_s)
    end
  end
end
