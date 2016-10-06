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

  def self.op_is_running?(klass, subject_id, operation)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"].to_i == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end.present?
  end

  def self.lookup_event(klass, subject_id, operation)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end.first
    Marty::Event.find_by_id(hash["id"])
  end

  def self.finish_event(klass, subject_id, operation)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        pm["enum_event_operation"] == operation
    end.first
    e = Marty::Event.find_by_id(hash["id"])
    raise "can't explicitly finish a promise event" if e.promise_id
    e.end_dt = Time.zone.now
    e.save!
  end

  def self.last_event(klass, subject_id, operation=nil)
    hash = all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i &&
        (operation.nil? || pm["enum_event_operation"] == operation)
    end.sort { |a, b| b["start_dt"]  <=> a["start_dt"] }.first
    Marty::Event.find_by_id(hash["id"]) if hash
  end

  def self.currently_running(klass, subject_id)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"] == subject_id.to_i
    end.map { |e| e["enum_event_operation"] }
  end

  def self.all_running
    @all_running ||= { timestamp: 0, data: [] }
    @poll_secs ||= Marty::Config['MARTY_EVENT_POLL_SECS'] || 5
    time_now = Time.now.to_i
    if time_now - @all_running[:timestamp] > @poll_secs
      @all_running[:data] =
        ActiveRecord::Base.connection.execute(
            "SELECT * FROM
               (SELECT ev.id,
                   ev.klass,
                   ev.subject_id,
                   ev.enum_event_operation,
                   coalesce(pr.start_dt, ev.start_dt) start_dt,
                   coalesce(pr.end_dt, ev.end_dt) end_dt,
                   expire_secs
                FROM marty_events ev
                LEFT JOIN marty_promises pr ON ev.promise_id = pr.id
                WHERE coalesce(pr.start_dt, ev.start_dt) >
                         NOW() - interval '24 hours') sub
             WHERE end_dt IS NULL
               AND (expire_secs IS NULL
                 OR expire_secs > EXTRACT (EPOCH FROM NOW() - start_dt));"
      ).to_a.map do |h|
        h["id"] = h["id"].to_i
        h["subject_id"] = h["subject_id"].to_i
        h["start_dt"] = Time.zone.parse(h["start_dt"])
        h["end_dt"] = Time.zone.parse(h["end_dt"]) if h["end_dt"]
        h["expire_secs"] = h["expire_secs"].to_i if h["expire_secs"]
        h
      end
      @all_running[:timestamp] = time_now
    end
    @all_running[:data]
  end
  private_class_method :all_running
end
