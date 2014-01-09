require 'netzke-core'

Marty::Engine.routes.draw do
  match "rpc/:action(.:format)" => "rpc"
  get "job/:action" => "job"
end
