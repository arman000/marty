class Marty::Aws::ApiKey < ActiveRecord::Base
  self.table_name = "marty_aws_api_keys"

  belongs_to :api_auth

  before_save do
    next
    client       = Marty::Aws::Apigateway.new
    identifier   = Marty::Config['AWS_API_IDENTIFIER'] || 'marty_api'
    default_name = "#{identifier}_#{value[0..3]}"
    begin
      if !name
        name = default_name
        write_attribute(:name, name)
      end
      name  = default_name unless name
      key   = client.create_api_key(name, 'marty_api_key', api_key)
      upkey = client.create_usage_plan_key(api_usage_plan_id, key.id)

      write_attribute(:aid, key.id)

    rescue => e
      client.delete_usage_plan_key(api_usage_plan_id, key.id) if upkey
      client.delete_api_key(key.id)                           if key
    end
  end

  before_destroy do
    begin
      delete_key
    rescue => e
      throw :abort unless e.message.include?('Invalid API Key')
    end
  end

  def delete_key
    client = Marty::Aws::Apigateway.new
    resp   = client.delete_usage_plan_key(api_usage_plan_id, aid)
    client.delete_api_key(aid) if resp
  end

  def move_key usage_plan_id
    begin
      client = Marty::Aws::Apigateway.new
      resp   = client.delete_usage_plan_key(api_usage_plan_id, aid)
      client.create_usage_plan_key(usage_plan_id, aid) if resp
    rescue
      # on fail recreate usage plan key
      client.create_usage_plan_key(api_usage_plan_id, aid) if client
      return
    end

    self.api_usage_plan_id = usage_plan_id
    self.save!
  end

  def api_key
    api_auth.try(:api_key)
  end
end
