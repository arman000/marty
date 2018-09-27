class Marty::Aws::Apigateway::UsagePlanCreateView < Marty::Form
  include Marty::Extras::Layout

  action :apply do |a|
    a.text     = 'Upload'
    a.tooltip  = 'Upload'
    a.icon_cls = 'fa fa-upload glyph'
  end

  client_class do |c|
    c.init_component = l(<<-JS)
    function() {
      var me = this;
      me.callParent();

      var comp = me.findComponent('aws_apigateway_api_view');
      this.serverConfig.selected = comp.serverConfig.selected;
    }
    JS

    c.close_window = l(<<-JS)
    function() {
      this.up('window').close();
    }
    JS

    c.reload = l (<<-JS)
    function() {
      this.findComponent('aws_apigateway_api_usage_plan_view').reload();
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

    api_id = Marty::Aws::Object.find(client_config['selected']).aid

    app_id = Marty::Config['AWS_APP_IDENTIFIER'] || 'marty'
    usage_plan_name = "#{app_id}-#{form_data['name'].downcase.gsub(/\s/,'-')}"

    Marty::Aws::Apigateway.new.create_usage_plan(usage_plan_name,
                                                 form_data['description'],
                                                 api_id,
                                                 throttle,
                                                 quota)
    client.reload
    rescue => e
      client.netzke_notify e.message
    end
    client.close_window
  end

  def configure(c)
    super
    c.title   = nil
    c.items   =
      [
        fieldset('Usage Plan',
                 {
                   id:         'name',
                   xtype:      'textfield',
                   fieldLabel: 'Name',
                 },
                 {
                   id:         'description',
                   xtype:      'textfield',
                   fieldLabel: 'Description',
                 },
                 hide_label: true,
                ),
        fieldset('Throttle',
                 {
                   id:         'burst_limit',
                   xtype:      'numberfield',
                   fieldLabel: tooltip(
                     'Burst Limit',
                     'The maximum API request rate limit over a period'
                   ),
                   minValue: 0,
                   value:    0,
                 },
                 {
                   id:         'rate_limit',
                   xtype:      'numberfield',
                   fieldLabel: tooltip(
                     'Rate Limit',
                     'The API request steady-state rate limit'
                   ),
                   minValue: 0,
                   value:    0,
                 },
                 hide_label: true,
                ),
        fieldset('Quota',
                 {
                   id:         'limit',
                   xtype:      'numberfield',
                   fieldLabel: tooltip(
                     'Limit',
                     'The maximum number of requests'
                   ),
                   minValue: 0,
                   value:    0,
                 },
                 {
                   id:         'offset',
                   xtype:      'numberfield',
                   fieldLabel: tooltip(
                     'Offset',
                     'Number of requests to subtract from the limit'
                   ),
                   minValue: 0,
                   value:    0,
                 },
                 {
                   id:         'period',
                   xtype:      'combobox',
                   fieldLabel: tooltip(
                     'Period',
                     'The time period for which the limit applies'
                   ),
                   store: ['DAY', 'WEEK', 'MONTH'],
                   value: 'DAY',
                 },
                 hide_label: true,
                ),
      ]
  end
end
