class Marty::AwsObject < ActiveRecord::Base

  AWS_CLIENT_CLASSES_MAP = {
    'apigateway' => Marty::Aws::Apigateway,
    'cognito'    => Marty::Aws::Cognito
  }

  #def create args
  #  AWS_CLIENT_CLASSES_MAP[client].new.create_object(args)
  #end
end
