class Marty::Aws::ApigatewayKeyView < Marty::Aws::Grid
  aws_model('apigateway', 'api_key')

  ATTRIBUTES = {
    aid:               {type: :string},
    name:              {type: :boolean},
    value:             {type: :string},
    customer_id:       {type: :string},
    description:       {type: :string},
    created_date:      {type: :datetime, label: 'Created Date'},
    last_updated_date: {type: :datetime, label: 'Last Updated Date'},
    stage_keys:        {type: :string},
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  def configure(c)
    super
    c.title      = "AWS API Keys"
    c.attributes = ATTRIBUTES.keys
  end
end

AwsApigatewayKeyView = Marty::Aws::ApigatewayKeyView
