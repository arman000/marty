require 'aws-sdk-apigateway'
class Marty::Aws::Apigateway
  attr_accessor :client, :id

  def initialize
    aws_base = Marty::Aws::Base.new
    @client = Aws::APIGateway::Client.new(
      region:            aws_base.doc[:region],
      access_key_id:     aws_base.creds[:access_key_id],
      secret_access_key: aws_base.creds[:secret_access_key],
      session_token:     aws_base.creds[:token]
    )
  end

  def create_api_key name, description, value
    client.create_api_key(
      name: name,
      description: description,
      enabled: true,
      generate_distinct_id: false,
      value: value,
    )
  end

  def delete_api_key api_key
    client.delete_api_key(api_key: api_key)
  end

  def update_api_key api_key, enable
    client.update_api_key(
      api_key: api_key,
      patch_operations: [
        op: 'replace',
        path: '/enabled',
        value: enable,
      ],
    )
  end

  def enable_api_key api_key
    update_api_key(api_key, true)
  end

  def disable_api_key api_key
    update_api_key(api_key, false)
  end

  def get_api_key api_key
    client.get_api_key(
      api_key: api_key,
      include_value: true,
    )
  end

  def get_rest_api api_id
    client.get_rest_api(rest_api_id: api_id)
  end

  def get_rest_apis
    client.get_rest_apis(
      limit: 500
    )
  end

  def get_apis_by_name name
    get_rest_apis.items.select{|i| i.name.include?(name)}
  end

  def get_authorizers id=nil
    return [] unless id

    client.get_authorizers(
      rest_api_id: id,
      limit: 500,
    ).items.map do |a|
      provider = a.provider_arns.first
      temp     = provider.try(:split, "/")
      a.id     = temp[-1] if temp
      a
    end
  end

  def get_apis
    get_rest_apis.items
  end

  def get_api_keys
    client.get_api_keys(
      limit: 500,
      include_values: true
    ).items
  end

  def get_stages id=nil
    return [] unless id

    client.get_stages(
      rest_api_id: id
    ).item
  end

  def get_usage_plans id=nil
    return [] unless id

    client.get_usage_plans(limit: 500).items.select do |p|
      p.api_stages.any?{|s| s.api_id == id}
    end
  end

  def get_usage_plan_keys id=nil
    return [] unless id

    usage_plan_key_ids = client.get_usage_plan_keys(
      usage_plan_id: id,
      limit: 500,
    ).items.map{|upk| upk.id}.to_set

    get_api_keys.select{|k| usage_plan_key_ids.member?(k.id)}
  end

  def create_usage_plan_key uid, kid
    resp = client.create_usage_plan_key(
      usage_plan_id: uid,
      key_id:        kid,
      key_type:      "API_KEY",
    )
    resp
  end

  def delete_usage_plan_key uid, kid
    client.delete_usage_plan_key(
      usage_plan_id: uid,
      key_id:        kid,
    )
  end

  def delete_usage_plan usage_plan_id
    client.delete_usage_plan(usage_plan_id: usage_plan_id)
  end
end
