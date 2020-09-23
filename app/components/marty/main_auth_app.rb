require_relative 'api_auth_view'
require_relative 'api_config_view'
require_relative 'api_log_view'
require_relative 'background_job/delayed_jobs_grid'
require_relative 'background_job/schedule_jobs_dashboard'
require_relative 'background_job/schedule_jobs_logs'
require_relative 'config_view'
require_relative 'data_grid_view'
require_relative 'data_grid_user_view'
require_relative 'import_type_view'
require_relative 'notifications/config_view'
require_relative 'notifications/deliveries_view'
require_relative 'postings/new_window'
require_relative 'postings/window'
require_relative 'promise_view'
require_relative 'reporting'
require_relative 'scripting'
require_relative 'users/user_view'

class Marty::MainAuthApp < Marty::AuthApp
  extend ::Marty::Permissions
  include Marty::Extras::Misc

  client_class do |c|
    c.include :main_auth_app
  end

  # set of posting types user is allowed to post with
  def self.has_posting_perm?
    Marty::Postings::NewForm.has_any_perm?
  end

  def self.has_scripting_perm?
    has_perm?(:admin)
  end

  def posting_menu
    {
      text:  warped ? Marty::Util.get_posting.name.to_s : I18n.t('postings'),
      name:  'posting',
      tooltip: 'Postings',
      icon_cls: 'fa fa-clock glyph',
      style: (warped ? 'background-color: lightGrey;' : ''),
      menu:  [
        :new_posting,
        :select_posting,
        :select_now,
      ],
    }
  end

  def log_menu
    [
      {
        text: 'Log Maintenance',
        icon_cls: 'fa fa-wrench glyph',
        disabled: !(self.class.has_perm?(:admin) || self.class.has_perm?(:dev)),
        menu: [
          :log_view,
          :log_cleanup,
        ]
      }
    ]
  end

  def api_menu
    [
      {
        text: 'API Management',
        icon_cls: 'fa fa-fighter-jet glyph',
        disabled: !self.class.has_perm?(:admin),
        menu: [
          :api_auth_view,
          :api_config_view,
          :api_log_view,
        ]
      }
    ]
  end

  def misc_menu
    [
      {
        text: 'Miscellaneous Views',
        icon_cls: 'fa fa-window-restore glyph',
        disabled: !self.class.has_perm?(:admin),
        menu: [
          :show_env,
        ],
      },
    ]
  end

  def system_menu
    {
      text:  I18n.t('system'),
      icon_cls: 'fa fa-wrench glyph',
      style: '',
      menu:  [
        :import_type_view,
        :user_view,
        :config_view,
        :reload_scripts,
        :load_seed,
      ] +
      background_jobs_menu  +
      notifications_menu    +
      log_menu              +
      api_menu              +
      misc_menu
    }
  end

  def applications_menu
    {
      text: I18n.t('applications'),
        icon_cls: 'fa fa-window-restore glyph',
      menu: [
        :data_grid_view,
        :data_grid_user_view,
        :reporting,
        :scripting,
        :promise_view,
      ],
    }
  end

  def background_jobs_menu
    [
      {
        text: 'Background Jobs',
        icon_cls: 'fa fa-user-clock glyph',
        disabled: !self.class.has_perm?(:admin),
        menu: [
          :bg_status,
          :bg_stop,
          :bg_restart,
          :delayed_jobs_grid,
          :schedule_jobs_dashboard,
          :schedule_jobs_logs,
        ]
      },
    ]
  end

  def notifications_menu
    disabled = !(self.class.has_perm?(:admin) ||
                 self.class.has_perm?(:user_manager))
    [
      {
        text: 'Notifications',
        icon_cls: 'fa fa-bell glyph',
        disabled: disabled,
        menu: [
          :notifications_config_view,
          :notifications_deliveries_view,
        ]
      },
    ]
  end

  def warped
    Marty::Util.warped?
  end

  def app_moniker
    warped ? 0x231B.chr('utf-8') : 0x03FB.chr('utf-8')
  end

  def app_title
    title = "#{app_moniker} #{::Marty::RailsApp.application_name_with_env}"
    title += ' [TIME WARPED]' if warped
    title
  end

  def ident_menu
    "<span style='color:#157fcc;
        background-color:#{warped ? '#FBDF4F' : ''};
        font-size:120%;
        font-weight:bold;'>#{app_title}</span>"
  end

  def data_menus
    []
  end

  def menu
    return super unless self.class.has_any_perm?

    [ident_menu, sep] +
      (self.class.has_perm?(:admin) || self.class.has_perm?(:dev) ||
       self.class.has_perm?(:user_manager) ? [system_menu, sep] : []) +
      data_menus +
      [
        applications_menu, sep,
        posting_menu, sep,
      ] + super
  end

  ######################################################################

  action :import_type_view do |a|
    a.text      = I18n.t('import_type')
    a.handler   = :netzke_load_component_by_action
    a.disabled  = !self.class.has_perm?(:admin)
    a.icon_cls = 'fa fa-file-import glyph'
  end

  action :scripting do |a|
    a.text      = I18n.t('scripting')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-code glyph'
    a.disabled  = !self.class.has_any_perm?
  end

  action :reporting do |a|
    a.text      = I18n.t('reports')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-file-alt glyph'
    a.disabled  = !self.class.has_any_perm?
  end

  action :promise_view do |a|
    a.text      = I18n.t('jobs.promise_view')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-search glyph'
    a.disabled  = !self.class.has_any_perm?
  end

  action :user_view do |a|
    a.text      = I18n.t('user_view')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-users glyph'
    a.disabled  = !self.class.has_perm?(:admin) &&
      !self.class.has_perm?(:user_manager)
  end

  action :config_view do |a|
    a.text      = I18n.t('config_view')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled  = !self.class.has_perm?(:admin) &&
      !self.class.has_perm?(:user_manager)
  end

  action :api_auth_view do |a|
    a.text      = 'API Auth Management'
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-key glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :api_config_view do |a|
    a.text     = 'API Config Management'
    a.tooltip  = 'Manage API behavior and settings'
    a.handler  = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-sliders-h glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :api_log_view do |a|
    a.text     = 'API Log View'
    a.tooltip  = 'View API logs'
    a.handler  = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-pencil-alt glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :data_grid_view do |a|
    a.text      = I18n.t('data_grid_view')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-table glyph'
    a.disabled = !self.class.has_any_perm?
  end

  action :data_grid_user_view do |a|
    a.text      = I18n.t('data_grid_user_view')
    a.handler   = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-table glyph'
    a.disabled = !self.class.has_any_perm?
  end

  action :reload_scripts do |a|
    a.text     = 'Reload Scripts'
    a.tooltip  = 'Reload and tag Delorean scripts'
    a.icon_cls = 'fa fa-sync-alt glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :load_seed do |a|
    a.text     = 'Load Seeds'
    a.tooltip  = 'Load Seeds'
    a.icon_cls = 'fa fa-retweet glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :bg_status do |a|
    a.text     = 'Show Delayed Jobs Status'
    a.tooltip  = 'Run delayed_job status script'
    a.icon_cls = 'fa fa-desktop glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :bg_stop do |a|
    a.text     = 'Stop Delayed Jobs'
    a.tooltip  = 'Run delayed_job stop script'
    a.icon_cls = 'fa fa-skull glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :bg_restart do |a|
    a.text     = 'Restart Delayed Jobs'
    a.tooltip  = 'Run delayed_job restart script using DELAYED_JOB_WORKERS'
    a.icon_cls = 'fa fa-power-off glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  action :delayed_jobs_grid do |a|
    a.text     = 'Delayed Jobs Dashboard'
    a.tooltip  = 'Show running delayed jobs'
    a.icon_cls = 'fa fa-clock glyph'
    a.disabled = !self.class.has_perm?(:admin)
    a.handler = :netzke_load_component_by_action
  end

  action :schedule_jobs_dashboard do |a|
    a.text     = 'Schedule Jobs Dashboard'
    a.tooltip  = 'Edit Delayed Jobs Cron schedules'
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled = !self.class.has_perm?(:admin)
    a.handler = :netzke_load_component_by_action
  end

  action :schedule_jobs_dashboard do |a|
    a.text     = 'Schedule Jobs Dashboard'
    a.tooltip  = 'Edit Delayed Jobs Cron schedules'
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled = !self.class.has_perm?(:admin)
    a.handler = :netzke_load_component_by_action
  end

  action :schedule_jobs_logs do |a|
    a.text     = 'Scheduled Jobs Logs'
    a.tooltip  = 'Show Scheduled Jobs logs'
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled = !self.class.has_perm?(:admin)
    a.handler = :netzke_load_component_by_action
  end

  action :log_view do |a|
    a.text     = 'View Log'
    a.tooltip  = 'View Log'
    a.handler  = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled = !(self.class.has_perm?(:admin) || self.class.has_perm?(:dev))
  end

  action :log_cleanup do |a|
    a.text     = 'Cleanup Log Table'
    a.tooltip  = 'Delete old log records'
    a.icon_cls = 'fa fa-cog glyph'
    a.disabled = !self.class.has_perm?(:admin)
  end

  # action 'Notifications::ConfigView' do |a|
  action :notifications_config_view do |a|
    a.text     = 'User Notification Rules'
    a.tooltip  = 'Configure notification rules for users'
    a.handler  = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-sliders-h glyph'
    a.disabled = !(self.class.has_perm?(:admin) ||
                   self.class.has_perm?(:user_manager))
  end

  action :notifications_deliveries_view do |a|
    a.text     = 'Notificaiton messages'
    a.tooltip  = 'Show all notification messages'
    a.handler  = :netzke_load_component_by_action
    a.icon_cls = 'fa fa-list glyph'
    a.disabled = !(self.class.has_perm?(:admin) ||
                   self.class.has_perm?(:dev))
  end

  action :show_env do |a|
    a.text     = 'Show Env Variables'
    a.tooltip  = 'Run `env` on host'
    a.icon_cls = 'fa fa-terminal glphy'
    a.disabled = !self.class.has_perm?(:admin)
  end

  ######################################################################
  # Background Jobs/Delayed Jobs

  def bg_command(subcmd)
    params = "-n #{Marty::Config['DELAYED_JOB_WORKERS']} --sleep-delay 5"
    e, root, p = Rails.env, Rails.root, Marty::Config['RUBY_PATH']
    dj_path = Marty::Config['DELAYED_JOB_PATH'] || 'bin/delayed_job'
    cmd = "export RAILS_ENV=#{e};"
    # FIXME: Environment looks to be setup incorrectly - this is a hack
    cmd += "export PATH=#{p}:$PATH;" if p
    # we use sudo -i to ensure that the root resources files (vars) are loaded
    # 2>&1 redirects STDERR to STDOUT since backticks only captures STDOUT
    cmd += "sudo -i #{root}/#{dj_path} #{subcmd} #{params} 2>&1"
    cmd
  end

  endpoint :bg_status do |_|
    cmd = bg_command('status')
    res = `#{cmd}`
    client.show_detail res.html_safe.gsub("\n", '<br/>'),
                       "Delayed Job Status: #{Marty::Diagnostic::Node.my_ip}"
  end

  endpoint :bg_stop do |_|
    cmd = bg_command('stop')
    res = `#{cmd}`
    res = 'delayed_job: no instances running. Nothing to stop.' if res.empty?
    client.show_detail res.html_safe.gsub("\n", '<br/>'),
                       "Delayed Job Stop: #{Marty::Diagnostic::Node.my_ip}"
  end

  endpoint :bg_restart do |_|
    cmd = bg_command('restart')
    res = `#{cmd}`
    client.show_detail res.html_safe.gsub("\n", '<br/>'),
                       "Delayed Job Restart: #{Marty::Diagnostic::Node.my_ip}"
  end

  endpoint :log_cleanup do |params|
    begin
      Marty::Log.cleanup(params)
    rescue StandardError => e
      res = e.message
      client.show_detail res.html_safe.gsub("\n", '<br/>'), 'Log Cleanup'
    end
  end

  endpoint :show_env do |_|
    html = `env`.
           split(/\n/).
           sort.
           map do |e|
             # mask passwords and expose first 4 digits of SECRET_KEY
             e.
             gsub(/PASSWORD=.*/, 'PASSWORD=********').
             gsub(/SECRET_KEY_BASE=(.{4}).*/, 'SECRET_KEY_BASE=\1****')
           end.
           join('<br/>').
           html_safe

    client.show_detail html, 'Server Environment'
  end

  ######################################################################
  # Postings

  action :new_posting do |a|
    a.text      = I18n.t('new_posting')
    a.tooltip   = I18n.t('new_posting')
    a.icon_cls = 'fa fa-plus glyph'
    a.disabled  = Marty::Util.warped? || !self.class.has_posting_perm?
  end

  action :select_posting do |a|
    a.text      = I18n.t('select_posting')
    a.tooltip   = I18n.t('select_posting')
    a.icon_cls = 'fa fa-history glyph'
  end

  endpoint :select_posting do |params|
    sid = params && params[0]
    Marty::Util.set_posting_id(sid)
    posting = sid && Marty::Posting.find(sid)

    client.netzke_notify "Selected '#{posting ? posting.name : 'NOW'}'"
    client.netzke_on_reload 1
  end

  action :select_now do |a|
    a.text = I18n.t('go_to_now')
    a.icon_cls = 'fa fa-globe glyph'
    a.disabled = Marty::Util.get_posting_time == Float::INFINITY
  end

  ######################################################################
  component :api_auth_view do |c|
    c.disabled = Marty::Util.warped?
  end

  component :api_log_view

  component :api_config_view

  component :delayed_jobs_grid do |c|
    c.klass = ::Marty::BackgroundJob::DelayedJobsGrid
  end

  component :config_view

  component :data_grid_view

  component :data_grid_user_view

  component :import_type_view

  component :log_view do |c|
    c.klass = Marty::LogView
  end

  component :new_posting_window do |c|
    c.disabled = Marty::Util.warped? || !self.class.has_posting_perm?
    c.klass = ::Marty::Postings::NewWindow
  end

  component :notifications_config_view do |c|
    c.klass = ::Marty::Notifications::ConfigView
  end

  component :notifications_deliveries_view do |c|
    c.klass = ::Marty::Notifications::DeliveriesView
  end

  component :posting_window do |c|
    c.klass = ::Marty::Postings::Window
  end

  component :promise_view do |c|
    c.klass = Marty::PromiseView
  end

  component :reporting

  component :schedule_jobs_dashboard do |c|
    c.klass = ::Marty::BackgroundJob::ScheduleJobsDashboard
  end

  component :schedule_jobs_logs do |c|
    c.klass = ::Marty::BackgroundJob::ScheduleJobsLogs
  end

  component :scripting do |c|
    c.allow_edit = self.class.has_scripting_perm?
  end

  component :user_view do |c|
    c.klass = ::Marty::Users::UserView
  end

  endpoint :reload_scripts do |_params|
    Marty::Script.load_scripts
    client.netzke_notify 'Scripts have been reloaded'
  end

  endpoint :load_seed do |_params|
    Rails.application.load_seed
    client.netzke_notify 'Seeds have been loaded'
  end
end

MainAuthApp = Marty::MainAuthApp
