module Marty
  class ScheduledJob < ActiveRecord::Base
    before_save   :schedule_run_dt
    before_save   :gen_description, :if => :delorean_descriptor_changed?
    before_create :update_user_id
    validate      :validate

    CRON_ATTRS = [
      :second,
      :minute,
      :hour,
      :day_of_the_month,
      :month_of_the_year,
      :day_of_the_week,
      :year
    ]

    def validate_delorean_descriptor
      script, node, attrs = ['script', 'node', 'attrs'].map do
        |m|
        val = delorean_descriptor[m]
        errors[:base] << "#{m} missing from delorean descriptor" unless val
        val
      end
    end

    def gen_description
      script, node = ['script', 'node'].map{|m| delorean_descriptor[m]}

      engine = Marty::ScriptSet.new.get_engine(script)
      res    = engine.evaluate(node, 'scheduled_job_descriptor', {}) rescue nil

      assign_attributes(description: res || "#{script}#{node}")
    end

    def gen_identifier
      (delorean_descriptor.values).join('_').downcase
    end

    def get_cron
      CRON_ATTRS.map{|a| send(a)}.join(' ')
    end

    def self.get_cron_from_time time
      time.strftime('%S %M %H %d %m %w %Y')
    end

    def self.get_cron_hash_from_time time
      CRON_ATTRS.zip(get_cron_from_time(time).split).to_h
    end

    def get_next_run opts={}
      _processed  = opts[:processed]  || processed
      _got_result = opts[:got_result] || got_result

      return nil if max_attempts && (_processed >= max_attempts || _got_result)
      parse_cron
    end

    def parse_cron
      Marty::Delayed::ExtendedCronParser.new(get_cron).next
    end

    def schedule_run_dt
      assign_attributes(scheduled_run_dt: get_next_run)
    end

    def time_till
      scheduled_run_dt.to_time - DateTime.now
    end

    def update_user_id
      user_id = (
        Marty::User.current || Marty::User.find_by_login(
          Marty::Config['SCHEDULER_USER'] || 'marty')
      ).try(:id)

      raise "SCHEDULER_USER is not defined in Marty::Config" unless user_id

      assign_attributes(user_id: user_id)
    end

    def validate
      validate_delorean_descriptor
      begin
        parse_cron
      rescue => e
        errors[:base] << e.message
      end
    end
  end
end
