module Marty
  module Promises
    module Ruby
      module Create
        def self.call(module_name:, method_name:, method_args:, params: {})
          default_timeout = Marty::Promise::DEFAULT_PROMISE_TIMEOUT

          promise_params = params.with_indifferent_access

          title = promise_params['p_title'] || "#{module_name}.#{method_name}"
          timeout = promise_params['p_timeout'] || default_timeout
          hook = promise_params['p_hook']

          promise = Marty::Promise.create(
            title: title,
            user_id: promise_params[:_user_id],
            parent_id: promise_params[:_parent_id],
            promise_type: 'ruby'
          )

          begin
            promise_job = Marty::PromiseRubyJob.new(
              promise,
              title,
              module_name,
              method_name,
              method_args,
              hook
            )

            job = Delayed::Job.enqueue(promise_job)
          rescue StandardError => exc
            res = { 'error' => exc.message }
            promise.set_start
            promise.set_result(res)
            raise
          end

          Marty::PromiseProxy.new(promise.id, timeout, 'result')
        end
      end
    end
  end
end
