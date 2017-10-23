Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/:action(.:format)" => "rpc", as: :rpc
  get "job/:action" => "job", as: :job
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report
  get  'diagnostic/(:action)', controller: 'diagnostic'
  get  'diag', to: 'diagnostic#test'
end
