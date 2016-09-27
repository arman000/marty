class Marty::PromiseMetadata < Marty::Base

  validates_presence_of :promise_id, :klass, :subject_id, :enum_promise_operation

  belongs_to :promise

  def self.op_is_running?(klass, subject_id, operation)
    all_running.select do |pm|
      pm[:klass] == klass && pm[:subject_id] == subject_id &&
        pm[:enum_promise_operation] == operation
    end.present?
  end

  def self.currently_running(klass, subject_id)
    all_running.select do |pm|
      pm[:klass] == klass && pm[:subject_id] == subject_id
    end.map(&:enum_promise_operation)
  end

  def self.all_running
    @all_running ||= { timestamp: 0, data: [] }
    time_now = Time.now.to_i
    if time_now - @all_running[:timestamp] > 5
      @all_running[:data] =
        Marty::PromiseMetadata.uncached {
        Marty::PromiseMetadata.joins(:promise).
          where('marty_promises.end_dt is null')
      }.to_a
      @all_running[:timestamp] = time_now
    end
    @all_running[:data]
  end
  private_class_method :all_running
end
