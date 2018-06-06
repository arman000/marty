class Marty::Aws::Object < ActiveRecord::Base
  self.table_name = "marty_aws_objects"

  belongs_to :marty_user, :class_name => 'Marty::User'

  AWS_CLIENT_CLASSES_MAP = {
    'apigateway' => Marty::Aws::Apigateway,
    'cognito'    => Marty::Aws::Cognito
  }

  def method_missing method, *args, &block
    m = method.to_s
    return value[m] if value.include?(m)
    super
  end
end
