class Marty::Scripting < Netzke::Base

  def configure(c)
    super

    c.items =
      [
       :script_form,
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

       var tag_grid      = me.netzkeGetComponent('tag_grid').getView();
       var script_grid   = me.netzkeGetComponent('script_grid').getView();
       var script_form   = me.netzkeGetComponent('script_form');
       //var script_tester = me.netzkeGetComponent('script_tester');

       tag_grid.getSelectionModel().on('selectionchange',
          function(self, records) {

          if(records[0] == null)
             return;

          var tag_id = records[0].get('id');
          me.selectTag({tag_id: tag_id});
          script_grid.getStore().load();
          var script_name = null;
          script_form.netzkeLoad({script_name: script_name});
          //script_tester.selectScript(script_name);
          }, me);

       script_grid.getSelectionModel().on('selectionchange',
          function(self, records) {

          if(script_grid.getStore().isLoading() == true)
             return;

          if(records[0] == null)
             return;

          var script_name = records[0].get('name');
          me.selectScript({script_name: script_name});
          script_form.netzkeLoad({script_name: script_name});
          //script_tester.selectScript(script_name);
          }, me);
    }
    JS

    c.script_refresh = <<-JS
    function(script_name) {
       if (!script_name) {
          this.selectScript({});
          this.netzkeReload();
       }
       else {
          this.selectScript({script_name: script_name});
          this.netzkeGetComponent('tag_grid').getStore().load();
          this.netzkeGetComponent('script_grid').getStore().load();
          this.netzkeGetComponent('script_form').netzkeLoad(
             {script_name: script_name});
          //this.netzkeGetComponent('script_tester').selectScript(script_name);
       }
    }
    JS
  end

  endpoint :select_tag do |params, this|
    root_sess[:selected_tag_id]      = params[:tag_id]
    root_sess[:selected_script_name] = nil
  end

  endpoint :select_script do |params, this|
    root_sess[:selected_script_name] = params[:script_name]
  end

  component :tag_grid do |c|
    c.klass            = Marty::TagGrid
    c.width            = 400
    c.height           = 300
    c.load_inline_data = false
    c.title            = I18n.t("script.selection_history")
  end

  component :script_grid do |c|
    c.width            = 400
    c.klass            = Marty::ScriptGrid
    c.title            = I18n.t("script.selection_list")
    c.flex             = 1
  end

  component :script_form do |c|
    c.klass            = Marty::ScriptForm
    c.title            = I18n.t("script.detail")
    c.flex             = 1
    c.split            = true
    c.region           = :west
  end

  component :script_tester do |c|
    c.klass            = Marty::ScriptTester
    c.title            = I18n.t("script.tester")
    c.flex             = 1
  end

end

Scripting = Marty::Scripting
