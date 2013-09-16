class Marty::Scripting < Netzke::Base

  def configure(c)
    super

    c.items = [
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
                                   :script_list,
                                   :script_log,
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
      this.callParent();

      var script_list = this.netzkeGetComponent('script_list').getView();
      script_list.on('itemclick', function(script_list, record) {
	var id = record.get('id');
        this.selectScript({script_id: id});
        this.netzkeGetComponent('script_log').getStore().load();
        this.netzkeGetComponent('script_details').netzkeLoad({id: id});
        this.netzkeGetComponent('script_tester').selectScript(id);
      }, this);

      var script_log = this.netzkeGetComponent('script_log').getView();
      script_log.on('itemclick', function(script_log, record) {
	var id = record.get('id');
        this.selectLog({log_id: id});
        this.netzkeGetComponent('script_details').netzkeLoad({id: id});
        this.netzkeGetComponent('script_tester').selectScript(id);
        }, this);

      // display tooltip for checkin log message
      script_log.on('render', function(view) {
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
                          view.getRecord(tip.triggerElement).get('log_message')
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
	  this.selectScript({});
	  this.netzkeReload()
	}
        else {
	  this.selectScript({script_id: script_id});
          this.netzkeGetComponent('script_list').getStore().load();
          this.netzkeGetComponent('script_log').getStore().load();
          this.netzkeGetComponent('script_details').netzkeLoad({id: script_id});
          this.netzkeGetComponent('script_tester').selectScript(script_id);
	}
      }
      JS
  end

  endpoint :select_script do |params, this|
    # store selected script id in the session for this component's instance
    script = Marty::Script.find_by_id(params[:script_id])

    component_session[:selected_group_id] = script && script.group_id
    component_session[:selected_script_id] = params[:script_id]
  end

  endpoint :select_log do |params, this|
    # store selected script id in the session for this component's instance
    component_session[:selected_script_id] = params[:log_id]
  end

  component :script_list do |c|
    c.width 		= 400
    c.klass 		= Marty::ScriptGrid
    c.title 		= I18n.t("script.selection_list")
    c.flex 		= 1
    c.allow_edit	= config[:allow_edit]
  end

  component :script_log do |c|
    c.klass 		= Marty::ScriptLogGrid
    c.width 		= 400
    c.load_inline_data 	= false
    c.group_id 	 	= component_session[:selected_group_id]
    c.script_id 	= component_session[:selected_script_id]
    c.title 		= I18n.t("script.selection_history")
    c.flex 		= 1
  end

  component :script_details do |c|
    c.klass 		= Marty::ScriptDetail
    c.script_id 	= component_session[:selected_script_id]
    c.title 		= I18n.t("script.details")
    c.flex 		= 1
    c.split 		= true
    c.region 		= :west
    c.allow_edit	= config[:allow_edit]
  end

  component :script_tester do |c|
    c.klass 		= Marty::ScriptTester
    c.script_id 	= component_session[:selected_script_id]
    c.title 		= I18n.t("script.tester")
    c.flex 		= 1
  end

end

Scripting = Marty::Scripting
