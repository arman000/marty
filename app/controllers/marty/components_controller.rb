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
      fn = "generate_#{format}".to_sym
      return unless inst.respond_to?(fn)

      type, disposition = Marty::ContentHandler::GEN_FORMATS[format]
      filename = inst.respond_to?(:filename) ?
        "#{inst.filename}.#{format}" : "#{component}.#{format}"

      return send_data(inst.send(fn, params),
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
