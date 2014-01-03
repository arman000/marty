require 'delorean_lang'

class Delorean::BaseModule::NodeCall
  # Monkey-patch '|' method for Delorean NodeCall to create promise
  # jobs and return promise proxy objects.
  def |(args)
    raise "bad arg to %" unless args.is_a?(Array)

    script, version = engine.module_name, engine.version

    nn = node.is_a?(Class) ? node.name.demodulize : node.to_s

    # IDEA: sending a promise as an arg to another job shouldn't cause
    # us to wait for it to be evaluated. i.e. it can be kept lazy!

    # QQQ: what happens when arguments to a delayed job aren't
    # serializable?  This should be an error.

    p 'x'*10, engine.module_name, engine.version, nn, params

    desc 	= params["p_desc"] || "#{engine.module_name}::#{nn}"
    timeout 	= params["p_timeout"] || Marty::Promise::DEFAULT_PROMISE_TIMEOUT
    parent_id	= _e[:_promise_id]
    promise 	= Marty::Promise.create(description: desc, parent_id: parent_id)

    params[:_promise_id] = promise.id
    params[:_parent_id]	 = parent_id if parent_id

    job = Delayed::Job.enqueue Marty::PromiseJob.
      new(promise, desc, script, version, nn, params, args)

    # keep a reference to the job.  This is needed in case we want to
    # work off a promise job that we're waiting for and which hasn't
    # been reserved yet.
    promise.job_id = job.id
    promise.save!

    Marty::PromiseProxy.new(promise, timeout)
  end
end

class Marty::PromiseJob < Struct.new(:promise,
                                     :desc,
                                     :sname,
                                     :version,
                                     :node,
                                     :params,
                                     :attrs,
                                     )
  def log(msg)
    open('/tmp/dj.out', 'a') { |f| f.puts msg }
  end

  def perform
    log "PERF #{Process.pid} #{desc}"

    promise.set_start

    begin
      script = Marty::Script.find_script(sname, version)

      raise "Can't find #{sname} version #{version}" unless script

      engine = Marty::ScriptSet.get_engine(script)

      engine.evaluate_attrs(node, attrs, params)

      res = attrs.each_with_object({}) { |attr, h|
        h[attr] = engine.evaluate(node, attr, params)
      }

      promise.set_result res
      log "DONE #{Process.pid} #{promise.id} #{Time.now.to_f} #{res}"
    rescue => exc
      log "ERR- #{Process.pid} #{promise.id} #{Time.now.to_f} #{exc}"
      promise.set_error exc
      log "ERR+ #{Process.pid} #{promise.id} #{Time.now.to_f} #{exc}"
    end

  end

  def max_attempts
    1
  end
end
