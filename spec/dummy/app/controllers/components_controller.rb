class ComponentsController < Marty::ApplicationController
  def home
    render inline: "<%= netzke :'auth_app', klass: Dummy::AuthApp %>", layout: true
  end

  def marty
    render inline: "<%= netzke :'main_auth_app', klass: Marty::MainAuthApp %>", layout: true
  end
end
