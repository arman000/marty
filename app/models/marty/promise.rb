class Marty::Promise < Marty::Base

  # default timeout (seconds) to wait for promise values
  DEFAULT_PROMISE_TIMEOUT = Rails.configuration.marty.promise_timeout || 30

  # default timeout (seconds) to wait for jobs to start
  DEFAULT_JOB_TIMEOUT = Rails.configuration.marty.job_timeout || 10

  def result(force=false)
    res = super()
    Marty::Promise.load_result(res, force)
  end

  def self.load_result(obj, force=false)
    if force && obj.respond_to?(:__force__)
      obj = obj.__force__
    end

    case obj
    when Array
      obj.map {|x| load_result(x, force)}
    when Hash
      p = obj['__promise__']

      if p && obj.length==1
        load_result(Marty::PromiseProxy.new(*p), force)
      else
        obj.each_with_object({}) { |(k, v), h| h[k] = load_result(v, force) }
      end
    else
      obj
    end
  end

  has_many :children,
           foreign_key: 'parent_id',
           class_name: "Marty::Promise",
           dependent: :destroy

  validates_presence_of :title

  belongs_to :parent, class_name: "Marty::Promise"
  belongs_to :user, class_name: "Marty::User"

  def self.cleanup(all=false)
    begin
      where('start_dt < ? AND parent_id IS NULL',
            DateTime.now - (all ? 0.hours : 4.hours)).destroy_all
    rescue => exc
      Marty::Util.logger.error("promise GC error: #{exc}")
    end
  end

  def raw_conn
    self.class.connection.raw_connection
  end

  def pg_notify
    raw_conn.async_exec("NOTIFY promise_#{id}")
  end

  def set_start
    if self.start_dt || self.result != {}
      Marty::Util.logger.error("promise already started: #{self}")
      return
    end

    # mark promise as started
    self.start_dt = DateTime.now
    self.save!
  end

  def set_result(res)
    # log "SETRES #{Process.pid} #{self}"

    # promise must have been started and not yet ended
    if !self.start_dt || self.end_dt || self.result != {}
      # log "SETERR #{Process.pid} #{self}"
      Marty::Util.logger.error("unexpected promise state: #{self}")
      return
    end

    raise "bad result" unless res.is_a?(Hash)

    self.status = res["error"].nil?
    self.result = res

    # update title/format from result hash (somewhat hacky)
    self.title   = res["title"].to_s  if res["title"]
    self.cformat = res["format"].to_s if res["format"]

    # mark promise as ended
    self.end_dt = DateTime.now
    self.save!

    # log "NOTIFY #{Process.pid}"
    pg_notify
  end

  def to_s
    inspect
  end

  # def log(msg)
  #   open('/tmp/dj.out', 'a') { |f| f.puts msg }
  # end

  def wait_for_my_notify(timeout)
    while true do
      # FIXME: we keep using the same timeout.  The timeout should be
      # reduced by total time spent here.
      n = raw_conn.wait_for_notify(timeout)
      return n if !n || n=="promise_#{id}"
    end
  end

  def latest
    # FIXME: Not sure if this is idiomatic.  What's the best way to
    # force AR to reload the promise object?  reset+reload doesn't
    # seems to work.

    # get latest uncached version
    Marty::Promise.uncached {Marty::Promise.find(id)}
  end

  def self.job_by_id(job_id)
    Delayed::Job.uncached {Delayed::Job.find_by_id(job_id)}
  end

  def work_off_job(job)
    # Create a temporary worker to work off the job
    Delayed::Job.where(id: job.id).
      update_all(locked_at: Delayed::Job.db_time_now, locked_by: "Temp")
    w = Delayed::Worker.new
    w.run(job)
  end

  def wait_for_result(timeout)
    # FIXME: Not sure that comparing result with empty hash if a good idea
    # perhaps it's better to use .present? or .blank?
    return self.result if self.result != {}

    begin
      # start listening on promise's notification
      raw_conn.exec("LISTEN promise_#{id}")

      last = latest

      # if job hasn't started yet, wait for it to start
      if !last.start_dt
        job = Marty::Promise.job_by_id(last.job_id)

        wait_for_my_notify(Marty::Promise::DEFAULT_JOB_TIMEOUT)

        last = latest

        # we waited for it but it never started.  So, mark it with a
        # timeout error.
        if !last.start_dt
          # log "TO11 #{Process.pid} #{last}"
          return {"error" => "promise #{last.id} timed out (never started)"}
        end
      end

      # reload promise in case out copy doesn't have a result yet
      last = latest unless last.end_dt

      # at this point, we know the promise has already started
      if !last.end_dt
        wait_for_my_notify(timeout)
        last = latest

        if !last.end_dt
          return {"error" => "promise #{last.id} timed out (didn't end)"}
        end
      end

      last.result
    ensure
      # Stop listening to the promise notifications
      raw_conn.exec("UNLISTEN promise_#{id}")
    end
  end
end
