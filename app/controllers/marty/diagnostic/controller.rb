module Marty::Diagnostic; class Controller < ActionController::Base
  layout 'marty/diagnostic'

  def self.inherited(klass)
    namespace = klass.name.deconstantize.split('::')[0] rescue ''
    Reporter.namespaces.unshift(namespace)
    super
  end

  def op
      @result = Reporter.run(request)
  rescue NameError
    render :help,
           formats: [:html],
           status: :bad_request
  else
      respond_to do |format|
        format.html { @result = display_parameters }
        format.json { render json: process_result_for_api }
      end
  end

  def process_result_for_api
    @result.delete('data') unless request.params['data'] == 'true'
    @result.delete('errors') if @result['errors'] && @result['errors'].empty?
    @result
  end

  def display_parameters
    local  = params[:scope] == 'local'
    data   = local ? @result : @result['data']
    errors = local ? Reporter.errors(data) : @result['errors']
    {
      'display' => Reporter.displays(data),
      'errors' => errors
    }
  end

  def self.add_report(name, diagnostics)
    Reporter.reports[name] = diagnostics
  end
end
end
