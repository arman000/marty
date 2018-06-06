class Marty::AwsApigatewayApiStageView < Marty::AwsGrid
  aws_model('apigateway', 'stage')

  ATTRIBUTES = {
    created_date:      {type: :datetime, label: 'Created Date'},
    deployment_id:     {type: :string},
    description:       {type: :string},
    stage_name:        {type: :string, label: 'Name'},
    last_updated_date: {type: :datetime, label: 'Last Updated Date'}
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  def configure(c)
    super
    c.title      = "AWS API Stages"
    c.attributes = ATTRIBUTES.keys
  end
end

AwsApigatewayApiStageView = Marty::AwsApigatewayApiStageView
