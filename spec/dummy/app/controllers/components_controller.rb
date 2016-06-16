require 'marty/main_auth_app'
require 'dummy/auth_app'

class ComponentsController < Marty::ApplicationController
  def home
    render inline: "<%= netzke :'auth_app' %>", layout: true
  end

  def marty
    render inline: "<%= netzke :'main_auth_app' %>", layout: true
  end
end
