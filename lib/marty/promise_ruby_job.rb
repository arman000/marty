class Marty::PromiseRubyJob < Struct.new(:promise,
                                         :title,
                                         :module_name,
                                         :method_name,
                                         :method_args,
                                         :hook,
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

      mod = module_name.constantize
      res = { 'result' => mod.send(method_name, *method_args) }
    rescue StandardError => e
      res = ::Marty::Promise.exception_to_result(promise: promise, exception: e)
    end

    promise.set_result(res)
    process_hook(res)
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
