class Marty::Grid < ::Netzke::Grid::Base
  extend ::Marty::Permissions

  has_marty_permissions read: :any

  # parent grid is the grid in which child/linked_components is defined
  # child  components are components dependent on the selected parent row
  # linked components will update whenever the parent is updated
  def initialize args, kwargs
    super(args, kwargs)
    client_config[:child_components]  = child_components  || []
    client_config[:linked_components] = linked_components || []
  end

  client_class do |c|
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
      if (paging != 'buffered') { this.paging = false; }
      this.callParent();
      this.paging = paging

      var me = this;

      var children = me.serverConfig.child_components || [];
      me.getSelectionModel().on(
      'selectionchange',
      function(m) {
        var has_sel = m.hasSelection();

        var rid = null;
        if (has_sel) {
          if (m.type == 'spreadsheet') {
            var cell = m.getSelected().startCell;
            rid = cell && cell.record.getId();
          }
          if (!rid) {
            rid = m.getSelection()[0].getId();
          }
        }

        me.serverConfig.selected = rid;

        for (var key in me.actions) {
          // hacky -- assumes our functions start with "do"
          if (key.substring(0, 2) == "do") {
            me.actions[key].setDisabled(!has_sel);
          }
        }

        for (var child of children) {
          var comp = me.netzkeGetComponentFromParent(child);
          if (comp) {
            comp.serverConfig.parent_id = rid;
            if (comp.reload) { comp.reload() }
          }
        }
      });

      var store  = me.getStore();
      var linked = me.serverConfig.linked_components || [];
      for (var event of ['update', 'netzkerefresh']) {
        store.on(event, function() {
        for (var link of linked) {
            var comp = me.netzkeGetComponentFromParent(link);
            if (comp && comp.reload) { comp.reload() }
          }
        }, this);
      }
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

    c.reload = l(<<-JS)
    function(opts={}) {
      this.netzkeReloadStore(opts);
    }
    JS

    c.reload_all = l(<<-JS)
    function() {
      var me = this;
      var children = me.serverConfig.child_components || [];
      this.store.reload();
      for (child of children) {
        var comp = me.netzkeGetComponentFromParent(child);
        if (comp && comp.reload) { comp.reload() }
      }
    }
    JS

    c.clear_filters = l(<<-JS)
    function() {
      this.filters.clearFilters();
    }
    JS

    c.netzkeGetComponentFromParent = l(<<-JS)
    function(component_path) {
      return this.netzkeGetParentComponent().netzkeGetComponent(component_path);
    }
    JS

  end

  ######################################################################

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

  def child_components
    []
  end

  def linked_components
    []
  end

  def configure_form_window(c)
    super

    c.klass = Marty::RecordFormWindow

    # Fix Add in form/Edit in form modal popup width
    # Netzke 0.10.1 defaults width to 80% of screen which is too wide
    # for a form where the fields are stacked top to bottom
    # Netzke 0.8.4 defaulted width to 400px - let's make it a bit wider
    c.width = 475
  end

  component :view_window do |c|
    configure_form_window(c)
    c.excluded = !allowed_to?(:read)
    c.items    = [:view_form]
    c.title    = I18n.t('netzke.grid.base.view_record',
                        model: model.model_name.human)
  end
end
