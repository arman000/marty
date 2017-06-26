class Marty::Event < Marty::Base

  class EventValidator < ActiveModel::Validator
    def validate(event)
      event.errors[:base] = "Must have promise_id or start_dt" unless
        event.promise_id || event.start_dt
    end
  end

  validates_presence_of :klass, :subject_id, :enum_event_operation

  belongs_to :promise

  validates_with EventValidator

  after_validation(on: [:create, :update]) do
    self.comment = self.comment.truncate(255) if self.comment
  end

  UPDATE_SQL =<<SQL
  UPDATE marty_events as me
  SET start_dt = p.start_dt,
      end_dt = p.end_dt
  FROM marty_promises p
  WHERE me.promise_id = p.id
    AND (   (    p.start_dt IS NOT NULL
             AND me.start_dt IS NULL
            )
         OR (    p.end_dt IS NOT NULL
             AND me.end_dt IS NULL
            )
        )
SQL
  BASE_QUERY =<<SQL
SELECT id,
            klass,
            subject_id,
            enum_event_operation,
            comment,
            start_dt,
            end_dt,
            expire_secs,
            error
     FROM marty_events
SQL
  def self.running_query(time_now_s)
    "#{BASE_QUERY}
     WHERE start_dt >= '#{time_now_s}'::timestamp - interval '24 hours'
       AND (end_dt IS NULL or end_dt > '#{time_now_s}'::timestamp)
       AND (expire_secs IS NULL
        OR expire_secs > EXTRACT (EPOCH FROM '#{time_now_s}'::timestamp - start_dt))
      ORDER BY start_dt"
  end

  def self.op_is_running?(klass, subject_id, operation)
    all_running.detect do |pm|
      pm["klass"] == klass && pm["subject_id"].to_i == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end
  end

  def self.create_event(klass,
                        subject_id,
                        operation,
                        start_dt,
                        expire_secs,
                        comment=nil)

    # use lookup_event instead of all_running which is throttled
    evs = self.lookup_event(klass, subject_id, operation)
    running = evs.detect do
      |ev|
      next if ev["end_dt"]
      next true unless ev["expire_secs"]
      (Time.zone.now - ev["start_dt"]).truncate < ev["expire_secs"]
    end

    raise "#{operation} is already running for #{klass}/#{subject_id}" if
      running

    self.create!(klass:                klass,
                 subject_id:           subject_id,
                 enum_event_operation: operation,
                 start_dt:             start_dt,
                 expire_secs:          expire_secs,
                 comment:              comment,
                )
  end

  def self.lookup_event(klass, subject_id, operation)
    update_start_and_end
    get_data("#{BASE_QUERY}
              WHERE klass = '#{klass}'
              AND subject_id = #{subject_id}
              AND enum_event_operation = '#{operation}'")

    #For now we return a bare hash
    #Marty::Event.find_by_id(hash["id"])
  end

  def self.finish_event(klass, subject_id, operation, error=false, comment=nil)
    raise "error must be true or false" unless [true, false].include?(error)
    time_now_s = Time.zone.now.strftime('%Y-%m-%d %H:%M:%S.%6N')

    event = get_data(running_query(time_now_s)).detect do |ev|
      ev["klass"] == klass && ev["subject_id"] == subject_id.to_i &&
        ev["enum_event_operation"] == operation
    end
    raise "event #{klass}/#{subject_id}/#{operation} not found" unless
      event

    ev = Marty::Event.find_by_id(event["id"])
    raise "can't explicitly finish a promise event" if ev.promise_id
    ev.end_dt = Time.zone.now
    ev.error = error
    ev.comment = comment if comment
    ev.save!
  end

  def self.last_event(klass, subject_id, operation=nil)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        (operation.nil? || pm["enum_event_operation"] == operation)
    end.last

    return hash if hash

    op_sql = "AND enum_event_operation = '#{operation}'" if operation

    get_data("#{BASE_QUERY}
              WHERE klass = '#{klass}'
              AND subject_id = #{subject_id} #{op_sql}
              AND end_dt IS NOT NULL
              ORDER BY end_dt desc").first
  end

  def self.last_event_multi(klass, subject_ids_arg, operation=nil)
    subject_ids = subject_ids_arg.map(&:to_i)
    events = all_running.select do |pm|
      pm["klass"] == klass && subject_ids.include?(pm["subject_id"]) &&
        (operation.nil? || pm["enum_event_operation"] == operation)
    end.group_by { |ev| ev["subject_id"] }.each_with_object({}) do
      |(id, evs), h|
      h[id] = evs.sort { |a, b| a["start_dt"] <=> b["start_dt"] }.first
    end

    running_ids = events.keys
    check_fin = subject_ids - running_ids

    if check_fin.present?
      op_filt = "AND enum_event_operation = '#{operation}'" if operation
      op_col = ", enum_event_operation" if operation

      fins = get_data("SELECT klass,
                              subject_id,
                              enum_event_operation,
                              comment,
                              start_dt,
                              end_dt,
                              expire_secs,
                              error
                       FROM (SELECT klass,
                                    subject_id,
                                    enum_event_operation,
                                    comment,
                                    start_dt,
                                    end_dt,
                                    expire_secs,
                                    error,
                                    ROW_NUMBER() OVER (PARTITION BY klass,
                                                                    subject_id
                                                                    #{op_col}
                                                       ORDER BY end_dt DESC) rnum
                          FROM marty_events
                          WHERE klass = '#{klass}'
                            AND subject_id IN (#{check_fin.join(',')})
                            #{op_filt}
                            AND end_dt IS NOT NULL) sub
                       WHERE rnum = 1")

      fins.each do |fin|
        events[fin["subject_id"]] = fin
      end
    end
    events
  end

  def self.currently_running(klass, subject_id)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i
    end.map { |e| e["enum_event_operation"] }
  end

  def self.currently_running_multi(klass, subject_id_raw)
    subject_ids = [subject_id_raw].flatten.map(&:to_i)
    all_running.select do |pm|
      pm["klass"] == klass && subject_ids.include?(pm["subject_id"])
    end.each_with_object({}) do |e, h|
      (h[e["subject_id"]] ||= []) <<  e["enum_event_operation"]
    end
  end

  def self.update_comment(hash, comment)
    hid = hash.is_a?(Hash) ? hash['id'] : hash
    e = Marty::Event.find_by_id(hid)
    e.comment = comment
    e.save!
  end

  def self.pretty_op(hash)
    d = hash['enum_event_operation'].downcase.capitalize

    #&& !(hash['comment'] =~ /^ERROR/)
    hash['end_dt'] ? d.sub(/ing/, 'ed') : d
  end

  def self.compact_end_dt(hash)
    hash['end_dt'] ? hash['end_dt'].strftime("%H:%M") : '---'
  end

  def self.update_start_and_end
    ActiveRecord::Base.connection.execute(UPDATE_SQL).cmd_tuples
  end

  def self.get_data(sql)
    ActiveRecord::Base.connection.execute(sql).to_a.map do |h|
      h["id"]          = h["id"].to_i
      h["subject_id"]  = h["subject_id"].to_i
      h["start_dt"]    = Time.zone.parse(h["start_dt"]) if h["start_dt"]
      h["end_dt"]      = Time.zone.parse(h["end_dt"]) if h["end_dt"]
      h["expire_secs"] = h["expire_secs"].to_i if h["expire_secs"]
      h["comment"]     = h["comment"]
      h["error"]       = h["error"]
      h
    end
  end
  private_class_method :get_data

  def self.clear_cache
    @poll_secs = @all_running = @all_finished = nil
  end

  def self.all_running
    @all_running ||= { timestamp: 0, data: [] }
    @poll_secs ||= Marty::Config['MARTY_EVENT_POLL_SECS'] || 0
    time_now = Time.zone.now
    time_now_i = time_now.to_i
    time_now_s = time_now.strftime('%Y-%m-%d %H:%M:%S.%6N')
    upd_count = update_start_and_end
    if upd_count > 0 ||
       time_now_i - @all_running[:timestamp] > @poll_secs
      @all_running[:data] = get_data(running_query(time_now_s))
      @all_running[:timestamp] = time_now_i
    end
    @all_running[:data]
  end
  private_class_method :all_running

  def self.all_finished
    @all_finished ||= {
      data:      {},
      timestamp: Time.zone.parse('00:00:00').to_i,
    }
    @poll_secs ||= Marty::Config['MARTY_EVENT_POLL_SECS'] || 0
    time_now_i = Time.zone.now.to_i
    cutoff = Time.zone.at(@all_finished[:timestamp]).
             strftime('%Y-%m-%d %H:%M:%S.%6N')

    upd_count = update_start_and_end
    if upd_count > 0 ||
       time_now_i - @all_finished[:timestamp] > @poll_secs
      raw = get_data(
        "SELECT * FROM
            (SELECT ROW_NUMBER() OVER (PARTITION BY klass,
                                                    subject_id,
                                                    enum_event_operation
                                       ORDER BY end_dt DESC) rownum, *
             FROM (#{BASE_QUERY}) sub2
             WHERE end_dt IS NOT NULL and end_dt > '#{cutoff}') sub1
         WHERE rownum = 1
         ORDER BY end_dt"
      )
      @all_finished[:timestamp] = time_now_i
      raw.each_with_object(@all_finished[:data]) do |ev, hash|
        if ev["end_dt"] && ev["error"].nil?
          real_ev = Marty::Event.where(id: ev["id"]).first
          promise = Marty::Promise.where(id: real_ev["promise_id"]).first
          maybe_error = promise.result["error"]
          ev["error"] = real_ev.error = !!maybe_error
          real_ev.comment = maybe_error
          real_ev.save!
        end
        subhash = hash[[ev["klass"], ev["subject_id"]]] ||= {}
        subhash[ev["enum_event_operation"]] =
          ev["end_dt"].strftime("%Y-%m-%d %H:%M:%S")
      end
    end
    @all_finished[:data]
  end

  def self.get_finished(klass, id)
    all_finished[[klass, id]]
  end

  def self.cleanup
    begin
      where('start_dt < ?', Time.zone.now - 48.hours).delete_all
    rescue => exc
      Marty::Util.logger.error("event GC error: #{exc}")
    end
  end

end
