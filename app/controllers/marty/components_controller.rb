class Marty::ComponentsController < Marty::ApplicationController
  # This is useful for individual component testing.  Note that the
  # appropriate route needs to be defined.
  # <base_url>/components/<ComponentCamelCaseName>

  helper Rails.application.routes.url_helpers

  def index
    component = params[:component]

    return redirect_to root_path unless component

    format, req_disposition, title =
      params[:format], params[:disposition], params[:reptitle]

    if format && Marty::ContentHandler::GEN_FORMATS.member?(format)
      klass = component.constantize

      raise "bad component" unless klass < Netzke::Base

      inst = klass.new
      return unless inst.respond_to?(:export_content)

      title ||= component

      res, type, disposition, filename =
        inst.export_content(format, title, params)

      return send_data(res,
                       type:        type,
                       filename:    filename,
                       disposition: req_disposition || disposition,
                       )
    end

    cname = component.gsub("::", "_").underscore
    render layout: true,
    inline: "<%= netzke :#{cname}, class_name: '#{component}', height: 650 %>"
  end
end
