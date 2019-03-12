class Marty::ComponentsController < Marty::ApplicationController
  # This is useful for individual component testing.  Note that the
  # appropriate route needs to be defined.
  # <base_url>/components/<ComponentCamelCaseName>

  def index
    component = params[:component]

    return redirect_to root_path unless component

    cname = component.gsub('::', '_').underscore
    render layout: true,
    inline: "<%= netzke :#{cname}, class_name: '#{component}', height: 650 %>"
  end
end
