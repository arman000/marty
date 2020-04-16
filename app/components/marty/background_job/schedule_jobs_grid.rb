module Marty
  module BackgroundJob
    class ScheduleJobsGrid < Marty::Grid
      ACCESSIBLE_BY = [:admin]

      has_marty_permissions(
        read: ACCESSIBLE_BY,
        create: ACCESSIBLE_BY,
        update: ACCESSIBLE_BY,
        delete: ACCESSIBLE_BY,
        destroy: ACCESSIBLE_BY,
        job_run: ACCESSIBLE_BY,
        edit_window__edit_form__submit: ACCESSIBLE_BY,
        add_window__add_form__submit: ACCESSIBLE_BY
      )

      def configure(c)
        super

        c.title ||= I18n.t(
          'schedule_jobs_dashboard_view_title',
          default: 'Schedule Jobs Dashboard'
        )

        c.model = 'Marty::BackgroundJob::Schedule'
        c.paging = :buffered
        c.editing = :in_form
        c.multi_select = false

        c.attributes = [
          :job_class,
          :arguments,
          :cron,
          :state
        ]
      end

      def default_context_menu
        []
      end

      def default_bbar
        super + [:do_job_run]
      end

      def configure_form_window(c)
        super

        c.form_config.submit_handler = lambda { |params|
          return unless super(params)

          Marty::BackgroundJob::UpdateSchedule.call(
            id: record.id,
            job_class: record.job_class
          )

          true
        }
      end

      attribute :job_class do |c|
        c.width = 400
      end

      attribute :arguments do |c|
        c.width = 400

        c.getter = lambda do |record|
          record.arguments.to_json
        end

        c.setter = lambda do |record, value|
          # FIXME: hacky way to parse JSON with single quotes
          record.arguments = JSON.parse(value.tr("'", '"'))
        end
      end

      attribute :cron do |c|
        c.width = 400
      end

      attribute :state do |c|
        c.width = 150
        editor_config = {
          trigger_action: :all,
          xtype: :combo,
          store: Marty::BackgroundJob::Schedule::ALL_STATES,
          forceSelection: true,
        }

        c.column_config = { editor: editor_config }
        c.field_config  = editor_config
      end

      action :do_job_run do |a|
        a.text     = 'Run'
        a.tooltip  = 'Run'
        a.icon_cls = 'fa fa-play glyph'
        a.disabled = true
        a.handler = :netzke_call_endpoint
        a.require_confirmation = true
        a.confirmation_title = 'Run Job'
        a.in_progress_message = 'Performing job...'
        a.endpoint_name = :job_run
      end

      endpoint :multiedit_window__multiedit_form__submit do |_params|
        client.netzke_notify 'Multiediting is disabled for cron schedules'
      end

      endpoint :destroy do |params|
        res = params.each_with_object({}) do |id, hash|
          record = model.find_by(id: id)
          job_class = record&.job_class
          result = super([id])

          # Do nothing If it wasn't destroyed
          next hash.merge(result) unless result[id.to_i] == 'ok'

          Marty::BackgroundJob::UpdateSchedule.call(
            id: id,
            job_class: job_class,
          )

          hash.merge(result)
        end

        res
      end

      endpoint :job_run do |_ids|
        begin
          s = Marty::BackgroundJob::Schedule.find(client_config['selected'])
          klass = s.job_class
          klass.constantize.new.perform(*s.arguments)
        rescue StandardError => e
          next client.netzke_notify(e.message)
        end
        client.netzke_notify("#{klass.demodulize} ran successfully.")
      end
    end
  end
end
