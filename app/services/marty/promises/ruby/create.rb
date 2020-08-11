module Marty
  module Promises
    module Ruby
      module Create
        def self.call(module_name:, method_name:, method_args:, params: {})
          if Marty::Config['USE_SIDEKIQ_WITH_PROMISES'].to_s == 'true'
            return call_with_sidekiq(
              module_name: module_name,
              method_name: method_name,
              method_args: method_args,
              params: params,
            )
          end

          default_timeout = Marty::Promise::DEFAULT_PROMISE_TIMEOUT

          promise_params = params.with_indifferent_access

          title = promise_params['p_title'] || "#{module_name}.#{method_name}"
          timeout = promise_params['p_timeout'] || default_timeout
          hook = promise_params['p_hook']

          default_priority = 0
          pid = promise_params[:_parent_id]
          if pid
            ppr = Marty::Promise.find_by(id: pid)
            # make sure parent isn't cancelled
            return if ppr&.result&.[]('error') == 'Cancelled'

            default_priority = ppr.priority if ppr
          end
          priority = promise_params['p_priority'] || default_priority

          promise = Marty::Promise.create(
            title: title,
            user_id: promise_params[:_user_id],
            parent_id: promise_params[:_parent_id],
            priority: priority,
            promise_type: 'ruby',
            timeout: timeout
          )

          begin
            promise_job = Marty::PromiseRubyJob.new(
              promise,
              title,
              module_name,
              method_name,
              method_args,
              hook,
              promise_params['p_timeout']
            )

            job = Delayed::Job.enqueue(
              promise_job,
              priority: priority,
              queue: promise_params['p_queue'] ||
                Delayed::Worker.default_queue_name)
          rescue StandardError => e
            res = { 'error' => e.message }
            promise.set_start
            promise.set_result(res)
            raise
          end

          # keep a reference to the job. This is needed in case we want to
          # work off a promise job that we're waiting for and which hasn't
          # been reserved yet.
          promise.job_id = job.id
          promise.save!

          Marty::PromiseProxy.new(promise.id, timeout, 'result')
        end

        def self.call_with_sidekiq(module_name:, method_name:, method_args:, params: {})
          default_timeout = Marty::Promise::DEFAULT_PROMISE_TIMEOUT

          promise_params = params.with_indifferent_access

          title = promise_params['p_title'] || "#{module_name}.#{method_name}"
          timeout = promise_params['p_timeout'] || default_timeout
          hook = promise_params['p_hook']

          default_priority = 0
          pid = promise_params[:_parent_id]
          if pid
            ppr = Marty::Promise.find_by(id: pid)
            # make sure parent isn't cancelled
            return if ppr&.result&.[]('error') == 'Cancelled'

            default_priority = ppr.priority if ppr
          end
          priority = promise_params['p_priority'] || default_priority

          promise = Marty::Promise.create(
            title: title,
            user_id: promise_params[:_user_id],
            parent_id: promise_params[:_parent_id],
            priority: priority,
            promise_type: 'ruby',
            timeout: timeout
          )

          begin
            promise_job = Marty::PromiseRubySidekiqJob.new(
              promise,
              title,
              module_name,
              method_name,
              method_args,
              hook,
              promise_params['p_timeout']
            )

            sidekiq_queue = if priority >= 1
                              'low'
                            else
                              'default'
                            end

            sidekiq_id = Marty::PromiseJobSidekiqWrapper.set(
              queue: sidekiq_queue
            ).perform_async(
              promise_job.to_yaml
            )
          rescue StandardError => e
            res = { 'error' => e.message }
            promise.set_start
            promise.set_result(res)
            raise
          end

          # keep a reference to the job. This is needed in case we want to
          # work off a promise job that we're waiting for and which hasn't
          # been reserved yet.
          promise.job_id = sidekiq_id
          promise.save!

          Marty::PromiseProxy.new(promise.id, timeout, 'result')
        end
      end
    end
  end
end
