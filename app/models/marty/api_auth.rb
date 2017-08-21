class Marty::ApiAuth < Marty::Base
  has_mcfly

  KEY_SIZE = 19

  def self.generate_key
    SecureRandom.hex(KEY_SIZE)
  end

  class ApiAuthValidator < ActiveModel::Validator
    def validate(api)
      api.errors.add(
        :base,
        "API Key length must be #{KEY_SIZE*2}") if
        api.api_key && api.api_key.length != KEY_SIZE*2

        api.errors.add(
          :base,
          "Script Name must reference a valid script") if
        Marty::Script.find_script(api.script_name, nil).nil?
    end
  end

  before_validation do
    self.api_key = Marty::ApiAuth.generate_key if
      self.api_key.nil? || self.api_key.length == 0
  end

  validates_presence_of :app_name, :api_key, :script_name

  validates_with ApiAuthValidator

  mcfly_validates_uniqueness_of :api_key, scope: [:script_name]
  validates_uniqueness_of :app_name, scope: [:script_name,
                                             :obsoleted_dt]

  def self.authorized?(script_name, api_key)
    is_secured = where(script_name: script_name,
                       obsoleted_dt: 'infinity').exists?
    !is_secured || where(api_key: api_key,
                         script_name: script_name,
                         obsoleted_dt: 'infinity').pluck(:app_name).first
  end

end
