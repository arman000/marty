class Marty::Scripting < Netzke::Base

  def configure(c)
    super

    c.items =
      [
       :script_details,
       {
         xtype: "tabpanel",
         active_tab: 0,
         region: :center,
         split: true,
         items: [
                 {
                   title: I18n.t("script.selection"),
                   layout: {
                     type: :vbox,
                     align: :stretch,
                   },
                   items: [
                           :tag_grid,
                           :script_grid,
                          ],
                 },
                 :script_tester,
                ],
       },
      ]
  end

  js_configure do |c|

    c.header = false
    c.layout = :border

    c.init_component = <<-JS
    function() {
       var me = this;
       me.callParent();

       var tag_grid    = me.netzkeGetComponent('tag_grid').getView();
       var script_grid = me.netzkeGetComponent('script_grid').getView();

       tag_grid.on('itemclick', function(tag_grid, record) {
          var id = record.get('id');
          me.selectTag({tag_id: id});
          var script_store = me.netzkeGetComponent('script_grid').getStore();
          script_store.load();
          script_store.on('load', function(self, params) {
             script_grid.getSelectionModel().select(0);
             var sel = script_grid.getSelectionModel().getSelection()[0];
             var id = sel && sel.data.id;
             me.selectScript({script_id: id});
             me.netzkeGetComponent('script_details').netzkeLoad({id: id});
             me.netzkeGetComponent('script_tester').selectScript(id);
             }, me);
          }, me);

       script_grid.on('itemclick', function(script_grid, record) {
          var id = record.get('id');
          me.selectScript({script_id: id});
          me.netzkeGetComponent('script_details').netzkeLoad({id: id});
          me.netzkeGetComponent('script_tester').selectScript(id);
          }, this);

       // display tooltip for checkin log message
       tag_grid.on('render', function(view) {
          view.tip = Ext.create('Ext.tip.ToolTip', {
             target: view.el,
             delegate: view.itemSelector,
             trackMouse: true,
             minWidth: 300,
             maxWidth: 500,
             dismissDelay: 0,
             showDelay: 200,
             renderTo: Ext.getBody(),
             listeners: {
                beforeshow: function updateTipBody(tip) {
                   tip.update(
                      view.getRecord(tip.triggerElement).get('comment')
                   );
                }
             }
          });
       });
    }
    JS

    c.script_refresh = <<-JS
    function(script_id) {
       if (script_id == -1) {
          // FIXME: will this work now ??? i.e. unsetting script
          this.selectScript({});
          this.netzkeReload();
       }
       else {
          this.selectScript({script_id: script_id});
          this.netzkeGetComponent('tag_grid').getStore().load();
          this.netzkeGetComponent('script_grid').getStore().load();
          this.netzkeGetComponent('script_details').netzkeLoad({id: script_id});
          this.netzkeGetComponent('script_tester').selectScript(script_id);
       }
    }
    JS
  end

  endpoint :select_script do |params, this|
    session[:selected_script_id] = params[:script_id]
  end

  endpoint :select_tag do |params, this|
    session[:selected_tag_id] = params[:tag_id]

    # when we select a new tag, invalidate the script selection
    # FIXME: is this right????
    session[:selected_script_id] = nil
  end

  component :tag_grid do |c|
    c.klass            = Marty::TagGrid
    c.width            = 400
    c.load_inline_data = false
    c.title            = I18n.t("script.selection_history")
    c.flex             = 1
  end

  component :script_grid do |c|
    c.width            = 400
    c.klass            = Marty::ScriptGrid
    c.title            = I18n.t("script.selection_list")
    c.flex             = 1
    c.allow_edit       = config[:allow_edit]
  end

  component :script_details do |c|
    c.klass            = Marty::ScriptDetail
    c.title            = I18n.t("script.details")
    c.flex             = 1
    c.split            = true
    c.region           = :west
    c.allow_edit       = config[:allow_edit]
  end

  component :script_tester do |c|
    c.klass            = Marty::ScriptTester
    c.title            = I18n.t("script.tester")
    c.flex             = 1
  end

end

Scripting = Marty::Scripting
