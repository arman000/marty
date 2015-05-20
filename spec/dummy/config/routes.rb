require 'netzke-core'

Rails.application.routes.draw do
  mount Marty::Engine => "/marty"

  get 'marty/components/:component' => 'marty/components#index',
    as: "marty/components"

  root 'components#home'

  netzke
end
