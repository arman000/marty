Rails.application.routes.draw do
  get 'report', to: 'marty/report#index'
end

Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/evaluate(.:format)" => "rpc", as: :rpc
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report
  get  'job/download' => 'job', as: :job
  post 'delayed_job/trigger' => 'delayed_job#trigger', as: :trigger_delayed_job
  get  'diag', to: 'diagnostic/#op'
end
