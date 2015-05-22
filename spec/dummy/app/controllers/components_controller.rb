class ComponentsController < Marty::ApplicationController
  def home
    render inline: "<%= netzke :'Marty::AuthApp' %>", layout: true
  end
end
