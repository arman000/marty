require 'delorean_lang'

class Delorean::BaseModule::NodeCall
  def initialize(_e, engine, node, params)
    super

    # If call has a promise_id (i.e. is from a promise) then that's
    # our parent.  Otherwise, we use its parent as our parent.
    params[:_parent_id] = _e[:_promise_id] || _e[:_parent_id]
    params[:_user_id]   = _e[:_user_id]    || Mcfly.whodunnit.try(:id)
  end

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
      Marshal.dump(params)
    rescue => exc
      raise "non-serializable parameters"
    end

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
    promise_meta = Marty::PromiseMetadata.
                   create!(promise_id: promise.id,
                           klass:      params[:__metadata__][:klass],
                           subject_id: params[:__metadata__][:id],
                           enum_promise_operation:
                             params[:__metadata__][:operation]) if
      params[:__metadata__]
    Marty::PromiseProxy.new(promise.id, timeout, attr)
  end
end


class Delorean::Engine
  def background_eval(node, params, attrs, meta = {})
    raise "background_eval bad params" unless params.is_a?(Hash)
    params[:__metadata__] = meta unless meta.empty?
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

  def perform
    # log "PERF #{Process.pid} #{title}"

    promise.set_start

    begin
      # in case the job writes to the the database
      Mcfly.whodunnit = promise.user

      engine = Marty::ScriptSet.new(tag).get_engine(sname)

      engine.evaluate_attrs(node, attrs, params)

      res = attrs.each_with_object({}) { |attr, h|
        h[attr] = engine.evaluate(node, attr, params)
      }

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
