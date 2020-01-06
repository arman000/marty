require 'delorean_lang'

class Marty::PromiseJob < Struct.new(:promise,
                                     :title,
                                     :sname,
                                     :tag,
                                     :node,
                                     :params,
                                     :attrs,
                                     :hook,
                                     :max_run_time
                                    )
  # def log(msg)
  #   open('/tmp/dj.out', 'a') { |f| f.puts msg }
  # end
  #
  def enqueue(job)
    config = Rails.configuration.marty
    hooks = config.promise_job_enqueue_hooks

    return if hooks.blank?

    hooks.each do |hook|
      hook.call(job)
    end
  end

  def perform
    # log "PERF #{Process.pid} #{title}"

    promise.set_start

    begin
      # in case the job writes to the the database
      Mcfly.whodunnit = promise.user

      engine = Marty::ScriptSet.new(tag).get_engine(sname)

      attrs_eval = engine.evaluate(node, attrs, params)
      res = attrs.zip(attrs_eval).each_with_object({}) do |(attr, val), h|
        h[attr] = val
      end

      # log "DONE #{Process.pid} #{promise.id} #{Time.now.to_f} #{res}"
    rescue ::Delayed::WorkerTimeout => e
      timeout_error = StandardError.new(
        ::Marty::Promise.timeout_message(promise)
      )
      timeout_error.set_backtrace(e.backtrace)

      res = Delorean::Engine.grok_runtime_exception(timeout_error)
    rescue StandardError => e
      res = Delorean::Engine.grok_runtime_exception(e)
      # log "ERR- #{Process.pid} #{promise.id} #{Time.now.to_f} #{e}"
    end

    promise.set_result(res)
    process_hook(res)
  end

  def process_hook(res)
      return unless hook

      hook.run(params: params, result: res)
  rescue StandardError => e
      Marty::Util.logger.error "promise hook failed: #{e}"
  end

  def max_attempts
    1
  end
end
