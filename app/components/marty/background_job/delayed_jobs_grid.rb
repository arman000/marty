module Marty
  module BackgroundJob
    class DelayedJobsGrid < Marty::Grid
      ACCESSIBLE_BY = [:admin]

      has_marty_permissions(
        read: ACCESSIBLE_BY,
        create: nil,
        update: nil,
        delete: nil,
        destroy: ACCESSIBLE_BY,
        job_run: ACCESSIBLE_BY,
        edit_window__edit_form__submit: ACCESSIBLE_BY,
        add_window__add_form__submit: ACCESSIBLE_BY
      )

      def configure(c)
        super

        c.title ||= I18n.t(
          'schedule_jobs_dashboard_view_title',
          default: 'Delayed Jobs Dashboard'
        )

        c.model = 'Delayed::Job'
        c.paging = :buffered
        c.editing = :in_form
        c.multi_select = false

        c.attributes = [
          :id,
          :handler,
          :run_at,
          :locked_at,
          :locked_by,
          :created_at,
          :cron,
          :last_error
        ]

        c.store_config.merge!(
          sorters: [
            { property: :locked_at, direction: 'DESC' },
            { property: :run_at, direction: 'DESC' }
          ])

        # c.scope = lambda do |r|
        # r.order('locked_at DESC NULLS LAST')
        # end
      end

      attribute :locked_at do |c|
        c.sorting_scope = lambda do |relation, dir|
          relation.order("locked_at #{dir} NULLS LAST")
        end
      end

      def default_context_menu
        []
      end

      def default_bbar
        []
      end

      attribute :cron do |c|
        c.width = 400
      end
    end
  end
end
