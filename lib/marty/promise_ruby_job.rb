class Marty::PromiseRubyJob < Struct.new(:promise,
                                         :title,
                                         :module_name,
                                         :method_name,
                                         :method_args,
                                         :hook,
                                         :max_run_time
                                        )

  def enqueue(job)
    config = Rails.configuration.marty
    hooks = config.promise_job_enqueue_hooks

    return if hooks.blank?

    hooks.each do |hook|
      hook.call(job)
    end
  end

  def perform
    promise.set_start

    begin
      Mcfly.whodunnit = promise.user

      ENV['__promise_id'] = promise.id.to_s
      mod = module_name.constantize
      res = { 'result' => mod.send(method_name, *method_args) }
    rescue ::Delayed::WorkerTimeout => e
      timeout_error = StandardError.new(
        ::Marty::Promise.timeout_message(promise)
      )
      timeout_error.set_backtrace(e.backtrace)

      res = Delorean::Engine.grok_runtime_exception(timeout_error)
    rescue StandardError => e
      res = ::Marty::Promise.exception_to_result(promise: promise, exception: e)
    end

    promise.set_result(res)
    process_hook(res)
    ENV.delete('__promise_id')
  end

  def process_hook(res)
    return unless hook

    hook.run(params: method_args, result: res)
  rescue StandardError => e
    Marty::Util.logger.error "promise hook failed: #{e}"
  end

  def max_attempts
    1
  end
end
