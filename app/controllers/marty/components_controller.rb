class Marty::ComponentsController < Marty::ApplicationController
  # This is useful for individual component testing.  Note that the
  # appropriate route needs to be defined.
  # <base_url>/components/<ComponentCamelCaseName>
  def index
    component = params[:component]

    return redirect_to root_path unless component

    format = params[:format]

    if format && Marty::ContentHandler::GEN_FORMATS.member?(format)
      klass = component.constantize

      raise "bad component" unless klass < Netzke::Base

      inst = klass.new
      return unless inst.respond_to?(:export_content)

      title = inst.respond_to?(:filename) ? inst.filename : component

      res, type, disposition, filename =
        inst.export_content(format, title, params)

      return send_data(res,
                       type: 		type,
                       filename: 	filename,
                       disposition: 	disposition,
                       )
    end

    cname = component.gsub("::", "_").underscore
    render layout: true,
    inline: "<%= netzke :#{cname}, class_name: '#{component}', height: 650 %>"
  end
end
