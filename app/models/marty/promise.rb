class Marty::Promise < Marty::Base
  # default timeout (seconds) to wait for promise values
  DEFAULT_PROMISE_TIMEOUT = Rails.configuration.marty.promise_timeout || 30

  # default timeout (seconds) to wait for jobs to start
  DEFAULT_JOB_TIMEOUT = Rails.configuration.marty.job_timeout || 10

  def result(force = false)
    res = super()
    Marty::Promise.load_result(res, force)
  end

  has_many :children,
           foreign_key: 'parent_id',
           class_name: 'Marty::Promise',
           dependent: :destroy,
           inverse_of: :parent

  validates :title, :promise_type, presence: true

  belongs_to :parent, class_name: 'Marty::Promise'
  belongs_to :user, class_name: 'Marty::User'

  def raw_conn
    self.class.connection.raw_connection
  end

  def pg_notify
    raw_conn.async_exec("NOTIFY promise_#{id}")
  end

  def set_start
    if start_dt || result != {}
      Marty::Util.logger.error("promise already started: #{self}")
      return
    end

    # mark promise as started
    self.start_dt = DateTime.now
    save!
  end

  def set_result(res)
    # log "SETRES #{Process.pid} #{self}"

    reload
    # If exception happened before the promise was started
    # we should still update the record
    if res['error'].present? && !start_dt
      self.start_dt ||= DateTime.now
    # promise must have been started and not yet ended
    elsif !start_dt || end_dt || result != {}
      # log "SETERR #{Process.pid} #{self}"
      Marty::Util.logger.error("unexpected promise state: #{self}")
      return
    end

    raise 'bad result' unless res.is_a?(Hash)

    self.status = res['error'].nil?
    self.result = res

    # update title/format from result hash (somewhat hacky)
    self.title   = res['title'].to_s  if res['title']
    self.cformat = res['format'].to_s if res['format']

    # mark promise as ended
    self.end_dt = DateTime.now
    save!

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
    while true
      # FIXME: we keep using the same timeout.  The timeout should be
      # reduced by total time spent here.
      n = raw_conn.wait_for_notify(timeout)
      return n if !n || n == "promise_#{id}"
    end
  end

  def latest
    # FIXME: Not sure if this is idiomatic.  What's the best way to
    # force AR to reload the promise object?  reset+reload doesn't
    # seems to work.

    # get latest uncached version
    Marty::Promise.uncached { Marty::Promise.find(id) }
  end

  def self.job_by_id(job_id)
    Delayed::Job.uncached { Delayed::Job.find_by(id: job_id) }
  end

  def work_off_job(job)
    # Create a temporary worker to work off the job
    Delayed::Job.where(id: job.id).
      update_all(locked_at: Delayed::Job.db_time_now, locked_by: 'Temp')
    w = Delayed::Worker.new
    w.run(job)
  end

  def wait_for_result(timeout)
    # FIXME: Not sure that comparing result with empty hash if a good idea
    # perhaps it's better to use .present? or .blank?
    return result if result != {}

    begin
      # start listening on promise's notification
      raw_conn.exec("LISTEN promise_#{id}")

      last = latest

      # if job hasn't started yet, wait for it to start
      if !last.start_dt
        job = Marty::Promise.job_by_id(last.job_id)

        # FIXME: this block is needed since a lot of specs rely on
        # delayed job being runned in the same thread as promise
        # Can be deleted later and replaces with simple timeout below
        if !job || job.locked_at
          # job has been locked, so it looks like it started already
          # and we need to wait for it.
          wait_for_my_notify(Marty::Promise::DEFAULT_JOB_TIMEOUT)
        else
          # work off the job instead of waiting for a real worker to
          # pick it up.
          # log "OFF0 #{Process.pid} #{last}"
          begin
            work_off_job(job)
          rescue StandardError => e
            # log "OFFERR #{exc}"
            error = self.class.exception_to_result(
              promise: self,
              exception: e
            )
            last.set_result(error)
          end
          # log "OFF1 #{Process.pid} #{last}"
        end

        # FIXME enable after problem with specs is solved
        # wait_for_my_notify(Marty::Promise::DEFAULT_JOB_TIMEOUT)

        last = latest

        # we waited for it but it never started.  So, mark it with a
        # timeout error.
        if !last.start_dt
          # log "TO11 #{Process.pid} #{last}"
          return { 'error' => self.class.never_started_message(last) }
        end
      end

      # reload promise in case out copy doesn't have a result yet
      last = latest unless last.end_dt

      # at this point, we know the promise has already started
      if !last.end_dt
        wait_for_my_notify(timeout)
        last = latest

        if !last.end_dt
          return { 'error' => self.class.timeout_message(last) }
        end
      end

      last.result
    ensure
      # Stop listening to the promise notifications
      raw_conn.exec("UNLISTEN promise_#{id}")
    end
  end

  delorean_fn :result_and_status, sig: 1 do |promise_id|
    promise = find_by(id: promise_id)
    next { 'error' => 'not found' } if promise.nil?

    {
      'completed' => !promise.status.nil?,
      'status' => promise.status,
      'result' => promise.result
    }
  end

  def delorean?
    promise_type == 'delorean'
  end

  class << self
    def load_result(obj, force = false)
      if force && obj.respond_to?(:__force__)
        obj = obj.__force__
      end

      case obj
      when Array
        obj.map { |x| load_result(x, force) }
      when Hash
        p = obj['__promise__']

        if p && obj.length == 1
          load_result(Marty::PromiseProxy.new(*p), force)
        else
          obj.each_with_object({}) { |(k, v), h| h[k] = load_result(v, force) }
        end
      else
        obj
      end
    end

    def cleanup(all = false)
      where(
        'start_dt < ? AND parent_id IS NULL',
        all ? Time.zone.now : 4.hours.ago
      ).destroy_all
    rescue StandardError => e
        Marty::Util.logger.error("promise GC error: #{e}")
    end

    def exception_to_result(promise:, exception:)
      if promise.delorean?
        return Delorean::Engine.grok_runtime_exception(exception)
       end

      { 'error' => exception.message, 'backtrace' => exception.backtrace }
    end

    def never_started_message(promise)
      "promise #{promise.id} timed out (never started)"
    end

    def timeout_message(promise)
      "promise #{promise.id} timed out (didn't end)"
    end
  end
end
