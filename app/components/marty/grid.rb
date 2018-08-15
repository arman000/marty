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
    # add menu overflowHandler to toolbars
    c.init_component = l(<<-JS)
    function() {
      this.dockedItems = this.dockedItems || [];
      if (this.paging == 'pagination') {
        this.dockedItems.push({
          xtype: 'pagingtoolbar',
          dock: 'bottom',
          layout: {overflowHandler: 'Menu'},
          listeners: {
            'beforechange': this.disableDirtyPageWarning ? {} : {
              fn: this.netzkeBeforePageChange, scope: this
            }
          },
          store: this.store,
          items: this.bbar && ["-"].concat(this.bbar)
        });
      } else if (this.bbar) {
        this.dockedItems.push({
          xtype: 'toolbar',
          dock: 'bottom',
          layout: {overflowHandler: 'Menu'},
          items: this.bbar
        });
      }

      // block creation of toolbars in parent
      delete this.bbar;
      var paging  = this.paging
      this.paging = false;
      this.callParent();
      this.paging = paging
    }
    JS

    # For some reason the grid update function was removed in Netzke
    # 0.10.1.  So, add it here.
    c.cm_update = l(<<-JS)
    function() {
      this.store.load();
    }
    JS

    # add menu overflowHandler to toolbars
    c.init_component = l(<<-JS)
    function() {
      this.dockedItems = this.dockedItems || [];
      if (this.paging == 'pagination') {
        this.dockedItems.push({
          xtype: 'pagingtoolbar',
          dock: 'bottom',
          layout: {overflowHandler: 'Menu'},
          listeners: {
            'beforechange': this.disableDirtyPageWarning ? {} : {
              fn: this.netzkeBeforePageChange, scope: this
            }
          },
          store: this.store,
          items: this.bbar && ["-"].concat(this.bbar)
        });
      } else if (this.bbar) {
        this.dockedItems.push({
          xtype: 'toolbar',
          dock: 'bottom',
          layout: {overflowHandler: 'Menu'},
          items: this.bbar
        });
      }

      // block creation of toolbars in parent
      delete this.bbar;
      var paging  = this.paging
      this.paging = false;
      this.callParent();
      this.paging = paging
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

    c.clear_filters = l(<<-JS)
    function() {
      this.filters.clearFilters();
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

    c.editing      = :both
    c.store_config = {page_size: 30}
    c.view_config  = {preserve_scroll_on_reload: true}
  end

  def has_search_action?
    false
  end

  # To add :clear_filters to your app's bbar, add the following lines:
  # def default_bbar
  #   [:clear_filters] + super
  # end

  def get_json_sorter(json_col, field)
    lambda do |r, dir|
      r.order("#{json_col} ->> '#{field}' " + dir.to_s)
    end
  end

  action :clear_filters do |a|
    a.tooltip  = "Clear filters"
    a.handler  = :clear_filters
    a.icon_cls = "fa fa-minus glyph"
  end

  # cosmetic changes

  action :add do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-plus glyph"
  end

  action :add_in_form do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-plus-square glyph"
  end

  action :edit do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-edit glyph"
  end

  action :edit_in_form do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-pen-square glyph"
  end

  action :delete do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-trash glyph"
  end

  action :apply do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = "fa fa-check glyph"
  end
end
