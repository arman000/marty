Marty::PromiseRubySidekiqJob = Struct.new(:promise,
                                          :title,
                                          :module_name,
                                          :method_name,
                                          :method_args,
                                          :hook,
                                          :max_run_time
                                         ) do
  def enqueue(job)
    config = Rails.configuration.marty
    hooks = config.promise_job_enqueue_hooks

    return if hooks.blank?

    hooks.each do |hook|
      hook.call(job)
    end
  end

  def perform
    res = nil # Needed, since timeout block has it's own scope
    promise.set_start

    begin
      Timeout.timeout(max_run_time&.to_i, Marty::WorkerTimeout) do
        Mcfly.whodunnit = promise.user
        Marty::ThreadSafeGlobals.promise_id = promise.id.to_s
        mod = module_name.constantize
        res = { 'result' => mod.send(method_name, *method_args) }
      end
    rescue ::Marty::WorkerTimeout => e
      msg = ::Marty::Promise.timeout_message(promise)
      timeout_error = StandardError.new(
        "#{msg} (Triggered by #{e.class})"
      )
      timeout_error.set_backtrace(e.backtrace)

      res = Delorean::Engine.grok_runtime_exception(timeout_error)
    rescue StandardError => e
      res = ::Marty::Promise.exception_to_result(promise: promise, exception: e)
    end

    locked_by = "host:#{Socket.gethostname} pid:#{Process.pid}" rescue "pid:#{Process.pid}"
    promise.set_result(res, locked_by)
    process_hook(res)
    Marty::ThreadSafeGlobals.promise_id = nil
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
