require 'marty/main_auth_app'

class ComponentsController < Marty::ApplicationController
  def home
    render inline: "<%= netzke :'main_auth_app' %>", layout: true
  end
end
