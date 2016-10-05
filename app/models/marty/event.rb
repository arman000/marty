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

  def self.currently_running(klass, subject_id)
    all_running.select do |pm|
      pm["klass"] == klass && pm["subject_id"].to_i == subject_id.to_i
    end.map { |e| e["enum_event_operation"] }
  end

  def self.all_running
    @all_running ||= { timestamp: 0, data: [] }
    time_now = Time.now.to_i
    if time_now - @all_running[:timestamp] > 5
      @all_running[:data] =
        ActiveRecord::Base.connection.execute(
            "SELECT * FROM
               (SELECT ev.klass,
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
      ).to_a
      @all_running[:timestamp] = time_now
    end
    @all_running[:data]
  end
  private_class_method :all_running
end
