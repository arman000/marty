require 'delorean_lang'

class Delorean::BaseModule::NodeCall
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

    # FIXME: if node is a string like "A::B", then the version
    # selected will be from the caller[?]

    script, version = engine.module_name, engine.version
    nn = node.is_a?(Class) ? node.name : node.to_s

    begin
      # make sure params is serialzable before starting a Job
      Marshal.dump(params)
    rescue => exc
      raise "non-serializable parameters"
    end

    title	= params["p_title"]   || "#{script}::#{nn.demodulize}"
    timeout 	= params["p_timeout"] || Marty::Promise::DEFAULT_PROMISE_TIMEOUT
    hook	= params["p_hook"]
    parent_id	= _e[:_promise_id]
    user_id	= _e[:_user_id] || Mcfly.whodunnit.try(:id)
    promise 	= Marty::Promise.create(title: title,
                                        user_id: user_id,
                                        parent_id: parent_id,
                                        )

    params[:_promise_id] = promise.id
    params[:_parent_id]	 = parent_id	if parent_id
    params[:_user_id]	 = user_id	if user_id

    begin
      job = Delayed::Job.enqueue Marty::PromiseJob.
        new(promise, title, script, version, nn, params, args, hook)
    rescue => exc
      open('/tmp/dj.out', 'a') { |f| f.puts "CALLERR #{exc}" }
      res = Delorean::Engine.grok_runtime_exception(exc)
      promise.set_start
      promise.set_result(res)
      open('/tmp/dj.out', 'a') { |f| f.puts "CALLERRSET #{res}" }
      raise
    end

    # keep a reference to the job.  This is needed in case we want to
    # work off a promise job that we're waiting for and which hasn't
    # been reserved yet.
    promise.job_id = job.id
    promise.save!

    Marty::PromiseProxy.new(promise.id, timeout, attr)
  end
end

class Delorean::Engine
  def background_eval(node, params, attrs)
    nc = Delorean::BaseModule::NodeCall.new({}, self, node, params)
    # start the background promise
    nc | attrs
  end
end

class Marty::PromiseJob < Struct.new(:promise,
                                     :title,
                                     :sname,
                                     :version,
                                     :node,
                                     :params,
                                     :attrs,
                                     :hook,
                                     )
  def log(msg)
    open('/tmp/dj.out', 'a') { |f| f.puts msg }
  end

  def perform
    log "PERF #{Process.pid} #{title}"

    promise.set_start

    begin
      script = Marty::Script.find_script(sname, version)

      raise "Can't find #{sname} version #{version}" unless script

      engine = Marty::ScriptSet.get_engine(script)

      engine.evaluate_attrs(node, attrs, params)

      res = attrs.each_with_object({}) { |attr, h|
        h[attr] = engine.evaluate(node, attr, params)
      }

      log "DONE #{Process.pid} #{promise.id} #{Time.now.to_f} #{res}"
    rescue => exc
      res = Delorean::Engine.grok_runtime_exception(exc)
      log "ERR- #{Process.pid} #{promise.id} #{Time.now.to_f} #{exc}"
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
