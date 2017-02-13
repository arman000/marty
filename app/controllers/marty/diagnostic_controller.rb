module Marty
  class DiagnosticController < ActionController::Base
    layout 'marty/diagnostic'

    def index
      if action_methods.include?(params[:testop].to_s)
        send(params[:testop])
      elsif params[:testop] == 'env'
        send('environment')
      else
        render file: 'public/404', status: 404, layout: false
      end
    end

    def version
      diag_response git_details +
        [Diagnostic.new('Marty Version', true, VERSION)]
    end

    def environment
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"

      details = [
        Diagnostic.new('Environment', true, Rails.env),
        Diagnostic.new('Rails Version', true, Rails.version),
        Diagnostic.new('Netzke Core Version', true, Netzke::Core::VERSION),
        Diagnostic.new('Netzke Basepack Version', true,
                       Netzke::Basepack::VERSION),
        Diagnostic.new('Ruby Version', true, rbv),
        Diagnostic.new('RubyGems Version', true, Gem::VERSION),
        Diagnostic.new('Database Adapter', true,
                       ActiveRecord::Base.connection.adapter_name)
      ]
      begin
        status = true
        result = ActiveRecord::Base.connection.execute('SELECT VERSION();')
        message = result[0]['version'] if result
      rescue => e
        status = false
        message = e.message
      end
      details << Diagnostic.new('Database Version', status, message)

      begin
        status, message = true, ActiveRecord::Migrator.current_version
      rescue => e
        status = false
        message = e.message
      end
      details << Diagnostic.new('Database Schema Version', status, message)
      diag_response details
    end

  private
    def diag_response details
      if @aggregate_diags
        @aggregated_details += details
      else
        @details = details
        respond_to do |format|
          format.html { render 'diagnostic' }
          format.json { render json: [{ error_count: error_count(details),
                                       diag_count: details.count }] + details }
        end
      end
    end

    def aggregate_diags
      begin
        @aggregate_diags = true
        @aggregated_details = []
        yield
      ensure
        @aggregate_diags = false
        diag_response @aggregated_details
      end
    end

    def error_count details
      details.count { |detail| !detail.status }
    end

    def git_details app_name = Rails.application.class.parent.to_s
      [
        Diagnostic.new("#{app_name} Git Version", true,
               `git describe 2>&1`.strip),
        Diagnostic.new("#{app_name} Git Details", true,
               `git show --pretty=format:"sha: %h, %D" --no-patch 2>&1`.strip)
      ]
    end

    class Diagnostic < Struct.new(:name, :status, :description)
      def status_css
        status ? 'passed' : 'failed'
      end

      def status_text
        status ? 'Passed' : 'Failed'
      end
    end
  end
end
