class Marty::ReportExecution < Marty::Base
  belongs_to :user, class_name: 'Marty::User'

  before_save :set_current_user

  # used to set values on promise hook
  def run(opts)
    update!(
      completed_at: Time.zone.now,
      error: !opts.dig(:result)&.key?('result')
    )
  end

  def set_current_user
    self.user = Marty::User.current ||
                Marty::User.find_by(
                  login: Rails.application.config.marty.system_account
                )
  end

  def self.cleanup(days_to_keep)
    raise "Must give numeric value. (Got '#{days_to_keep}')" unless
      (Float(days_to_keep) rescue false)

    where('created_at <= ?', Time.zone.now - days_to_keep.to_i.days).delete_all
  end
end
