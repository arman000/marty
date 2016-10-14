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

  BASE_QUERY = "SELECT ev.id,
                   ev.klass,
                   ev.subject_id,
                   ev.enum_event_operation,
                   ev.comment,
                   coalesce(pr.start_dt, ev.start_dt) start_dt,
                   coalesce(pr.end_dt, ev.end_dt) end_dt,
                   expire_secs
                FROM marty_events ev
                LEFT JOIN marty_promises pr ON ev.promise_id = pr.id "

  def self.op_is_running?(klass, subject_id, operation)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"].to_i == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end.present?
  end

  def self.lookup_event(klass, subject_id, operation)
    get_data(BASE_QUERY +
             " WHERE klass = '#{klass}'
                AND subject_id = #{subject_id}
                and enum_event_operation = '#{operation}'")

    #For now we return a bare hash
    #Marty::Event.find_by_id(hash["id"])
  end

  def self.finish_event(klass, subject_id, operation, comment=nil)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end.first
    e = Marty::Event.find_by_id(hash["id"])
    raise "can't explicitly finish a promise event" if e.promise_id
    e.end_dt = Time.zone.now
    e.comment = comment if comment
    e.save!
  end

  def self.last_event(klass, subject_id, operation=nil)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        (operation.nil? || pm["enum_event_operation"] == operation)
    end.sort { |a, b| b["start_dt"]  <=> a["start_dt"] }.first
    return hash if hash
    get_data("SELECT * FROM (" + BASE_QUERY + ") sub
              WHERE klass = '#{klass}'
                AND subject_id = #{subject_id} " +
             (operation ? "and enum_event_operation = '#{operation}' " : "") +
             "ORDER BY start_dt desc").first
  end

  def self.currently_running(klass, subject_id)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i
    end.map { |e| e["enum_event_operation"] }
  end

  def self.update_comment(hash, comment)
    hid = hash.is_a?(Hash) ? hash['id'] : hash
    e = Marty::Event.find_by_id(hid)
    e.comment = comment
    e.save!
  end

  def self.pretty_op(hash)
    d = hash['enum_event_operation'].downcase.capitalize
    if hash['end_dt'] #&& !(hash['comment'] =~ /^ERROR/)
      return d.sub(/ing/, 'ed')
    end
    d
  end

  def self.compact_end_dt(hash)
    hash['end_dt'] ? hash['end_dt'].strftime("%H:%M") : '---'
  end

  def self.get_data(sql)
    ActiveRecord::Base.connection.execute(sql).to_a.map do |h|
      h["id"] = h["id"].to_i
      h["subject_id"] = h["subject_id"].to_i
      h["start_dt"] = Time.zone.parse(h["start_dt"]) if h["start_dt"]
      h["end_dt"] = Time.zone.parse(h["end_dt"]) if h["end_dt"]
      h["expire_secs"] = h["expire_secs"].to_i if h["expire_secs"]
      h["comment"] = h["comment"]
      h
    end
  end
  private_class_method :get_data
  def self.clear_cache
    @all_running = nil
  end
  def self.all_running
    @all_running ||= { timestamp: 0, data: [] }
    @poll_secs ||= Marty::Config['MARTY_EVENT_POLL_SECS'] || 5
    time_now = Time.zone.now
    time_now_i = time_now.to_i
    time_now_s = time_now.strftime('%Y-%m-%d %H:%M:%S.%6N')
    if time_now_i - @all_running[:timestamp] > @poll_secs
      @all_running[:data] = get_data(
        "SELECT * FROM
               (#{BASE_QUERY}
                WHERE coalesce(pr.start_dt, ev.start_dt, '1900-1-1') >=
                         '#{time_now_s}'::timestamp - interval '24 hours') sub
             WHERE (end_dt IS NULL or end_dt > '#{time_now_s}'::timestamp)
               AND (expire_secs IS NULL
                 OR expire_secs > EXTRACT (EPOCH FROM '#{time_now_s}'::timestamp - start_dt))"
      )
      @all_running[:timestamp] = time_now_i
    end
    @all_running[:data]
  end
  private_class_method :all_running
end
