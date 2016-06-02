Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/:action(.:format)" => "rpc", as: :rpc
  get "job/:action" => "job", as: :job
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report
  get  'diag/(:action)', controller: 'diagnostic'
  get  'diagnostic/(:action)', controller: 'diagnostic'
end
