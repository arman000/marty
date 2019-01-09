require 'delorean_lang'

class Delorean::BaseModule::NodeCall
  def initialize(_e, engine, node, params)
    super

    # If call has a promise_id (i.e. is from a promise) then that's
    # our parent.  Otherwise, we use its parent as our parent.
    params[:_parent_id] = _e[:_promise_id] || _e[:_parent_id]
    params[:_user_id]   = _e[:_user_id]    || Mcfly.whodunnit.try(:id)
  end

  # def log(msg)
  #   open('/tmp/dj.out', 'a') { |f| f.puts msg }
  # end

  # Monkey-patch '|' method for Delorean NodeCall to create promise
  # jobs and return promise proxy objects.
  def |(args)

    if args.is_a?(String)
      attr = args
      args = [attr]
    else
      raise "bad arg to %" unless args.is_a?(Array)
      attr = nil
    end
    script, tag = engine.module_name, engine.sset.tag
    nn = node.is_a?(Class) ? node.name : node.to_s
    begin
      # make sure params is serialzable before starting a Job
      JSON.dump(params)
    rescue => exc
      raise "non-serializable parameters: #{params} #{exc}"
    end

    # log "||||| #{args.inspect} #{params.inspect}"

    title   = params["p_title"]   || "#{script}::#{nn.demodulize}"
    timeout = params["p_timeout"] || Marty::Promise::DEFAULT_PROMISE_TIMEOUT
    hook    = params["p_hook"]
    promise = Marty::Promise.
      create(title:     title,
             user_id:   params[:_user_id],
             parent_id: params[:_parent_id],
             )
    params[:_promise_id] = promise.id
    begin
      job = Delayed::Job.enqueue Marty::PromiseJob.
        new(promise, title, script, tag, nn, params, args, hook)
    rescue => exc
      # log "CALLERR #{exc}"
      res = Delorean::Engine.grok_runtime_exception(exc)
      promise.set_start
      promise.set_result(res)
      # log "CALLERRSET #{res}"
      raise
    end

    # keep a reference to the job.  This is needed in case we want to
    # work off a promise job that we're waiting for and which hasn't
    # been reserved yet.
    promise.job_id = job.id
    promise.save!

    evh = params["p_event"]
    if evh
      event, klass, subject_id, operation = evh.values_at("event", "klass",
                                                          "id", "operation")
      if event
        event.promise_id = promise.id
        event.save!
      else
        event = Marty::Event.
                create!(promise_id: promise.id,
                        klass:      klass,
                        subject_id: subject_id,
                        enum_event_operation: operation)
      end
    end
    Marty::PromiseProxy.new(promise.id, timeout, attr)
  end
end


class Delorean::Engine
  def background_eval(node, params, attrs, event = {})
    raise "background_eval bad params" unless params.is_a?(Hash)
    params["p_event"] = event.each_with_object({}) do |(k, v), h|
      h[k.to_s] = v
    end unless event.empty?
    nc = Delorean::BaseModule::NodeCall.new({}, self, node, params)
    # start the background promise
    nc | attrs
  end
end

class Marty::PromiseJob < Struct.new(:promise,
                                     :title,
                                     :sname,
                                     :tag,
                                     :node,
                                     :params,
                                     :attrs,
                                     :hook,
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
    rescue => exc
      res = Delorean::Engine.grok_runtime_exception(exc)
      # log "ERR- #{Process.pid} #{promise.id} #{Time.now.to_f} #{exc}"
    end
    promise.set_result(res)

    begin
      hook.run(res) if hook
    rescue => exc
      Marty::Util.logger.error "promise hook failed: #{exc}"
    end
  end

  def max_attempts
    1
  end
end
