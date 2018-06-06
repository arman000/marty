class Marty::ApiAuth < Marty::Base
  has_mcfly

  KEY_SIZE = 19

  validates_presence_of :app_name, :api_key, :script_name

  class ApiAuthValidator < ActiveModel::Validator
    def validate(api)
      api.errors.add(:base, "API Key length must be #{KEY_SIZE*2}") if
        api.api_key && api.api_key.length != KEY_SIZE*2

      api.errors.add(:base, "Script Name must reference a valid script") unless
        Marty::Script.find_script(api.script_name, nil)
    end
  end

  validates_with ApiAuthValidator

  mcfly_validates_uniqueness_of :api_key, scope: [:script_name]
  validates_uniqueness_of :app_name, scope: [:script_name,
                                             :obsoleted_dt]


  before_validation do
    self.api_key = Marty::ApiAuth.generate_key if
      self.api_key.nil? || self.api_key.length == 0
  end

  before_destroy do
    next unless aws = parameters['aws_api_key']
    begin
      client = Marty::Aws::Apigateway.new
      resp   = client.delete_usage_plan_key(aws['api_usage_plan_id'],
                                            aws['aid'])
      client.delete_api_key(aws['aid']) if resp
    rescue => e
      Marty::Logger.log('api_test', 'error', e.message)
      throw :abort unless e.message.include?('Invalid API Key')
    end
  end

  def self.generate_key
    SecureRandom.hex(KEY_SIZE)
  end

  def create_aws_api_key api_id, api_usage_plan_id
    client = Marty::Aws::Apigateway.new
    app_id = Marty::Config['AWS_APP_IDENTIFIER'] || 'marty'
    name   = "#{app_id}-#{api_id}-#{api_key[0..3]}"

    key = nil
    begin
      key = client.create_api_key(name, 'marty_api_key', api_key)
    rescue => e
      #Marty::Logger.log('api_test', 'error', e.message)
    end

    upkey = nil
    begin
    upkey = key &&
            client.create_usage_plan_key(api_usage_plan_id, key.id)
    rescue => e
      #Marty::Logger.log('api_test', 'error', e.message)
      # remove api key we created
      client.delete_api_key(key.id)
    end

    raise "Unable to create AWS API Key" unless key && upkey

    parameters['aws_api_key'] = {
      'aid'               => key.id,
      'api_usage_plan_id' => api_usage_plan_id,
      'api_id'            => api_id,
    }

    save!
  end

  def move_aws_key usage_plan_id
    return unless aws = parameters['aws_api_key']
    return if aws['api_usage_plan_id'] == usage_plan_id

    begin
      client = Marty::Aws::Apigateway.new
      resp   = client.delete_usage_plan_key(aws['api_usage_plan_id'],
                                            aws['aid'])
    rescue => e
      # on fail recreate usage plan key
      Marty::Logger.log('api', 'api_test', aws)
      client.create_usage_plan_key(aws['api_usage_plan_id'], aws['aid']) if
        client
      return
    else
      client.create_usage_plan_key(usage_plan_id, aws['aid']) if resp
    end

    parameters['aws_api_key'] += {'api_usage_plan_id' => usage_plan_id}
    save!
  end
end
