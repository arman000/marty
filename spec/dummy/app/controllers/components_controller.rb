class ComponentsController < Marty::ApplicationController
  def home
    render inline: "<%= netzke :'cm_auth_app', klass: Gemini::CmAuthApp %>", layout: true
  end
end