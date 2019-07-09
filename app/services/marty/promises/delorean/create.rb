module Marty
  module Promises
    module Delorean
      module Create
        def self.call(params:, script:, node_name:, attr:, args:, tag:)
          default_timeout = Marty::Promise::DEFAULT_PROMISE_TIMEOUT

          title = params['p_title'] || "#{script}::#{node_name.demodulize}"
          timeout = params['p_timeout'] || default_timeout
          hook = params['p_hook']

          promise = Marty::Promise.create(
            title: title,
            user_id: params[:_user_id],
            parent_id: params[:_parent_id],
            promise_type: 'delorean'
          )

          params[:_promise_id] = promise.id

          begin
            promise_job = Marty::PromiseJob.new(
              promise,
              title,
              script,
              tag,
              node_name,
              params,
              args,
              hook
            )

            job = Delayed::Job.enqueue(promise_job)
          rescue StandardError => e
            # log "CALLERR #{exc}"
            res = ::Delorean::Engine.grok_runtime_exception(e)
            promise.set_start
            promise.set_result(res)
            # log "CALLERRSET #{res}"
            raise
          end

          # keep a reference to the job. This is needed in case we want to
          # work off a promise job that we're waiting for and which hasn't
          # been reserved yet.
          promise.job_id = job.id
          promise.save!

          evh = params['p_event']
          if evh
            event, klass, subject_id, operation = evh.values_at(
              'event',
              'klass',
              'id',
              'operation'
            )

            if event
              event.promise_id = promise.id
              event.save!
            else
              Marty::Event.create!(
                promise_id: promise.id,
                klass: klass,
                subject_id: subject_id,
                enum_event_operation: operation
              )
            end
          end
          Marty::PromiseProxy.new(promise.id, timeout, attr)
        end
      end
    end
  end
end
