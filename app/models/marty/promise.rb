class Marty::Promise < Marty::Base
  class MarshalResult
    def dump(v)
      Marshal.dump(v)
    end

    def load(v)
      # FIXME: Rails4 bytea interface seems to remove the trailing
      # \x00 char.
      v += "\x00" if v

      # Marshal.load can't handle nil
      v.nil? ? {} : Marshal.load(v)
    end
  end

  # default timeout (seconds) to wait for promise values
  DEFAULT_PROMISE_TIMEOUT = Rails.configuration.marty.promise_timeout || 30

  # default timeout (seconds) to wait for jobs to start
  DEFAULT_JOB_TIMEOUT = Rails.configuration.marty.job_timeout || 10

  lazy_load :result

  serialize :result, MarshalResult.new

  validates_presence_of :title

  has_many :children,
  foreign_key: 'parent_id',
  class_name: "Marty::Promise",
  dependent: :destroy

  belongs_to :parent, class_name: "Marty::Promise"
  belongs_to :user, class_name: "Marty::User"

  def self.cleanup(all=false)
    begin
      where('start_dt < ? AND parent_id IS NULL',
            DateTime.now - (all ? 0.hours : 2.hours)).destroy_all
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
    # log "SETRES #{Process.pid} #{res} #{self}"

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

  def work_off_job(job)
    # Create a temporary worker to work off the job
    Delayed::Job.where(id: job.id).
      update_all(locked_at: Delayed::Job.db_time_now, locked_by: "Temp")
    w = Delayed::Worker.new
    w.run(job)
  end

  def wait_for_result(timeout)
    return self.result if self.result != {}

    begin
      # start listening on promise's notification
      raw_conn.exec("LISTEN promise_#{id}")

      last = latest

      # if job hasn't started yet, wait for it to start
      if !last.start_dt
        # log "AAAA #{Process.pid} #{last}"

        job = Delayed::Job.find_by_id(last.job_id)
        job.reload if job # paranoid

        if !job && job.locked_at
          # job has been locked, so it looks like it started already
          # and we need to wait for it.
          wait_for_my_notify(Marty::Promise::DEFAULT_JOB_TIMEOUT)
        else
          # work off the job instead of waiting for a real worker to
          # pick it up.
          # log "OFF0 #{Process.pid} #{last}"
          begin
            work_off_job(job)
          rescue => exc
            # log "OFFERR #{exc}"
            res = Delorean::Engine.grok_runtime_exception(exc)
            last.set_result(res)
          end
          # log "OFF1 #{Process.pid} #{last}"
        end

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
        # log "UUUU #{Process.pid} #{id} #{Time.now.to_f}"
        last = latest

        # log "XXXX #{Process.pid} #{Time.now.to_f} #{last}"

        if !last.end_dt
          # log "TO22 #{Process.pid} #{last}"
          return {"error" => "promise #{last.id} timed out (didn't end)"}
        end
      end

      # log "RRRR #{Process.pid} #{last} #{Time.now.to_f}"

      last.result
    ensure
      # Stop listening to the promise notifications
      raw_conn.exec("UNLISTEN promise_#{id}")
    end

  end
end
