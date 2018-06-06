Rails.application.routes.draw do
  get 'report', to: 'marty/report#index'
end

Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/evaluate(.:format)" => "rpc", as: :rpc
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report
  get  'job/download' => 'job', as: :job
  get  'diag',        to: 'diagnostic/#op'

  # api controller routes
  get  'api',                         to: 'api/#index'
  post 'api',                         to: 'api/#index'
  post 'api/sign_in',                 to: 'api/#sign_in'
  post 'api/sign_up',                 to: 'api/#sign_up'
  post 'api/confirm_sign_up',         to: 'api/#confirm_sign_up'
  post 'api/forgot_password',         to: 'api/#forgot_password'
  post 'api/confirm_forgot_password', to: 'api/#confirm_forgot_password'
  post 'api/oauth2/token',            to: 'api/#token'
end
