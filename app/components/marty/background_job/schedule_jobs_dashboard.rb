require 'marty/background_job/schedule_jobs_grid'

module Marty
  module BackgroundJob
    class ScheduleJobsDashboard < Marty::Form
      include Marty::Extras::Layout

      def configure(c)
        super
        c.items = [
          :schedule_jobs_grid,
          :schedule_jobs_warnings
        ]
      end

      def prepare_warnings
        djs = ::Marty::BackgroundJob::FetchMissingInScheduleCronJobs.call

        messages = djs.map do |dj|
          handler_str = dj.handler[/job_class.*\n/]
          job_class = handler_str.gsub('job_class:', '').strip

          "#{job_class} with cron #{dj.cron} and schedule_id #{dj.schedule_id}" \
            'is present in delayed_jobs table, but is missing in the Dashboard.'
        end

        messages.join('<br>')
      end

      client_class do |c|
        c.header   = false
        c.defaults = { body_style: 'padding:0px' }
      end

      component :schedule_jobs_grid do |c|
        c.klass = Marty::BackgroundJob::ScheduleJobsGrid
        c.region = :north
        c.min_height = 500
      end

      component :schedule_jobs_warnings do |c|
        c.klass = Marty::Panel
        c.title = I18n.t('jobs.schedule_dashboard.warnings')
        c.html = prepare_warnings
        c.min_height = 200
      end

      def default_bbar
        []
      end
    end
  end
end
