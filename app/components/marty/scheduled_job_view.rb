require 'cronex'

class Marty::ScheduledJobView < Marty::Grid
  include Marty::Extras::Layout
  extend Marty::Extras::Columns

  has_marty_permissions read:   :admin,
                        delete: :admin

  client_styles do |config|
    config.require :scheduled_job_view
  end

  endpoint :halt_job do |params|
    record_id = params[:record_id]

    sj = Marty::ScheduledJob.where(id: record_id).first
    return client.netzke_notify("No scheduled job.") unless sj

    return client.netzke_notify("Cannot halt an unscheduled job.") unless
      sj.scheduled_run_dt

    return client.netzke_notify("Please wait for scheduled job to finish.") if
      sj.promise_id

    sj.update(halt: !sj.halt)
  end

  endpoint :ping do
    Marty::ScheduledJob.create!(
      max_attempts: 1,
      second: '*',
      minute: '*',
      delorean_descriptor: {
        'script' => 'Scheduler',
        'node'   => 'Ping',
        'attrs'  => 'perform',
      }
    )
  end

  client_class do |config|
    config.netzke_halt_job = l(<<-JS)
    function() {
      var sel = this.getSelectionModel().getSelection()[0];
      var record_id = sel && sel.getId();
      this.server.haltJob({record_id: record_id});
      this.getStore().reload();
    }
    JS

    config.netzke_ping = l(<<-JS)
    function() {
      this.server.ping();
      this.getStore().reload();
    }
    JS

    config.default_get_row_class = l(<<-JS)
    function(record, index, rowParams, ds) {
       var status = record.get('status')[0];
       var halt   = record.get('halt');
       if (halt) return "gray-row";
       if (status == 'E' || status == 'F') return "red-row";
       if (status == 'C') return "green-row";
       if (status == 'P') return "pink-row";
       return "orange-row";
    }
    JS

    config.init_component = l(<<-JS)
    function() {
       this.callParent();
       this.getView().getRowClass = this.defaultGetRowClass
       var store = this.getStore();

       // auto refresh page every 5 seconds
       var runner = new Ext.util.TaskRunner();
       var task = runner.start({
           run: function() {
                  store.reload();
                },
           interval: 5000
           });
    }
    JS
  end

  def configure(c)
    super
    c.model        = "Marty::ScheduledJob"
    c.editing      = :in_form
    c.view_config  = {loadMask: false}
    c.paging       = :pagination
    c.store_config.merge!(sorters:
                            [{property: :scheduled_run_dt, direction: 'ASC'}])

  end

  component :view_window do |c|
    super(c)
    c.width = 750
    c.height = 630
  end

  action :halt_job do |a|
    a.text = "Halt/Resume"
    a.tooltip = "Halt/Resume Scheduled Job"
    a.icon = :timeline_marker
    a.handler = :netzke_halt_job
    a.disabled = false
  end

  action :ping do |a|
    a.text = "Ping"
    a.tooltip = "Create Ping/Pong job"
    a.icon = :bullet_white
    a.handler = :netzke_ping
  end

  def default_bbar
    [:halt_job, :delete, :ping]
  end

  def default_form_items
    [:description,
     {name: 'Scheduled',
      getter: lambda {
        |r|
        Cronex::ExpressionDescriptor.new(r.get_cron).description
      },
      xtype: :textfield},
     :max_attempts,
     :processed,
     :last_completed_dt,
     :scheduled_run_dt,
     :created_at,
     :updated_at,
     :status,
     {name: 'User',
      getter: lambda {
        |r|
        user_id = r.send('user_id')
        Marty::User.find_by_id(user_id).login rescue user_id
      }
     },
     :promise_id,
     jsonb_field(:delorean_descriptor),
     jsonb_field(:params)
    ]
  end

  [:delorean_descriptor, :params].each do |a|
    json_column a, hidden: true
  end

  attribute :description do |c|
    c.width = 250
  end

  [:user_id, :got_result].each do |a|
    attribute a do |c|
      c.hidden = true
    end
  end

  attribute :halt do |c|
    c.text = "Halted"
  end

  attribute :updated_at do |c|
    c.flex = 1
  end

  Marty::ScheduledJob::CRON_ATTRS.each do |a|
    attribute a do |c|
      c.text = a.to_s.split('_').map do
        |s|
        char = s[0] == 't' ? '' : (s[0] == 'o' ? s[0] : s[0].capitalize)
      end.compact.join
      c.width = 80
    end
  end
end

ScheduledJobView = Marty::ScheduledJobView
