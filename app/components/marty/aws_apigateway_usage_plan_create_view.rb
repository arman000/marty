class Marty::AwsApigatewayUsagePlanCreateView < Marty::Form
  include Marty::Extras::Layout

  action :apply do |a|
    a.text     = 'Create'
    a.icon_cls = 'fa fa-upload glyph'
  end

  client_class do |c|
    c.init_component = l(<<-JS)
    function() {
      var me = this;
      me.callParent();

      var window      = this.netzkeGetParentComponent();
      var parent_view = window.netzkeGetParentComponent();

      this.serverConfig.api_rec_id   = parent_view.serverConfig.parent_id
      this.serverConfig.stage_rec_id = parent_view.serverConfig.selected

      console.log(this.serverConfig);
    }
    JS

    c.close_window = l(<<-JS)
    function() {
      this.up('window').close();
    }
    JS

    c.reload_parent = l (<<-JS)
    function() {
      var window      = this.netzkeGetParentComponent();
      var parent_view = window.netzkeGetParentComponent();
      parent_view.reload();
    }
    JS
  end

  ######################################################################

  endpoint :submit do |params|
    begin
    form_data  = ActiveSupport::JSON.decode(params[:data])

    # remove -inputEl from form data
    form_data  = form_data.each_with_object({}) do |(k,v), h|
      h[k.chomp('-inputEl')] = v
    end

    ['name',
     'description',
     'burst_limit',
     'rate_limit',
     'limit',
     'offset',
     'period'
    ].each do |k|
      return client.netzke_notify "Usage Plan #{k.titleize} is required" unless
        form_data[k] != ''
    end

    throttle = {
      burst_limit: form_data['burst_limit'],
      rate_limit:  form_data['rate_limit']
    }

    quota = {
      limit:  form_data['limit'],
      offset: form_data['offset'],
      period: form_data['period'],
    }

    api_id     = Marty::AwsObject.find(client_config['api_rec_id']).
                   value['aid']

    stage_name = Marty::AwsObject.find(client_config['stage_rec_id']).
                   value['stage_name']

    Marty::Aws::Apigateway.new.create_usage_plan(form_data['name'],
                                                 form_data['description'],
                                                 api_id,
                                                 [stage_name],
                                                 throttle,
                                                 quota)
    client.reload_parent
    rescue => e
      client.netzke_notify e.message
    end
    client.close_window
  end

  def configure(c)
    super
    c.title = nil
    c.height = 50
    c.items =
      [
        fieldset("Usage Plan",
                 {
                   id:'name',
                   xtype:'textfield',
                   fieldLabel:'Name',
                 },
                 {
                   id:'description',
                   xtype:'textfield',
                   fieldLabel:'Description',
                 },
                 hide_label: true,
                ),
        fieldset("Throttle",
                 {
                   id:'burst_limit',
                   xtype:'numberfield',
                   fieldLabel:'Burst Limit',
                   minValue: 0,
                   value: 0,
                 },
                 {
                   id:'rate_limit',
                   xtype:'numberfield',
                   fieldLabel:'Rate Limit',
                   minValue: 0,
                   value: 0,
                 },
                 hide_label: true,
                ),
        fieldset("Quota",
                 {
                   id:'limit',
                   xtype:'numberfield',
                   fieldLabel:'Limit',
                   minValue: 0,
                   value: 0,

                 },
                 {
                   id:'offset',
                   xtype:'numberfield',
                   fieldLabel:'Offset',
                   minValue: 0,
                   value: 0,
                 },

                 {
                   id:'period',
                   xtype:'combobox',
                   fieldLabel:'Period',
                   store: ['DAY', 'WEEK', 'MONTH'],
                   value: 'DAY',
                 },
                 hide_label: true,
                ),
      ]
  end
end
