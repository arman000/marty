class Marty::ApiAuth < Marty::Base
  has_mcfly

  KEY_SIZE = 19

  validates :app_name, :api_key, :script_name, presence: true

  class ApiAuthValidator < ActiveModel::Validator
    def validate(api)
      api.errors.add(:base, "API Key length must be #{KEY_SIZE * 2}") if
        api.api_key && api.api_key.length != KEY_SIZE * 2

      api.errors.add(:base, 'Script Name must reference a valid script') unless
        Marty::Script.find_script(api.script_name, nil)
    end
  end

  validates_with ApiAuthValidator

  mcfly_validates_uniqueness_of :api_key, scope: [:script_name]
  validates :app_name, uniqueness: { scope: [:script_name,
                                             :obsoleted_dt] }

  before_validation do
    self.api_key = Marty::ApiAuth.generate_key if
      api_key.blank?
  end

  def self.generate_key
    SecureRandom.hex(KEY_SIZE)
  end
end
