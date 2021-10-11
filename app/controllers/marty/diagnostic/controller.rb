module Marty
  module Diagnostic
    class Controller < ActionController::Base
      layout 'marty/diagnostic'

      class << self
        def inherited(klass)
          namespace = klass.name.deconstantize.split('::')[0] rescue ''
          Reporter.namespaces.unshift(namespace)
          super
        end
      end

      def op
        @reporter = Reporter.new(request.params, request.ssl?)
        @reporter.run
        @reporter.result
      rescue NameError
        render :help,
               formats: [:html],
               status: :bad_request
      else
        respond_to do |format|
          format.html { @result = html }
          format.json { render json: process_result_for_api }
        end
      end

      def process_result_for_api
        response = @reporter.result
        response.delete('data') unless @reporter.return_data?
        response.delete('errors') unless @reporter.errors?
        response
      end

      def html
        @reporter.display
      end
    end
  end
end
