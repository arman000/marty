require 'netzke-core'

Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/:action(.:format)" => "rpc"
  get "job/:action" => "job"
end
