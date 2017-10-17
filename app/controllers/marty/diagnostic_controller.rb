        require 'erb'
module Marty
  ENV["DUMMY_DB"] = 'marty_dev'
  class DiagnosticController < ActionController::Base
    D_FORMAT  = '%Y-%m-%d'
    T_FORMAT  = '%H:%M:%S'
    DT_FORMAT = D_FORMAT + ' ' + T_FORMAT
    READ_ONLY = ' disabled - database is in read-only mode'
    CLG       = ' disabled - environment is in clg mode'
    SANDBOX   = ' disabled - environment is in sandbox mode'

    layout false
    before_filter :params_check
    def test
      @show_detail = true
      @details     = []
      @data        = ''
      @read_only   = Marty::Util.db_in_recovery?
      begin
        @result = send(:"#{params[:op]}")
      rescue NoMethodError
        render file: 'public/404', formats: [:html], status: 400, layout: false
      else
        respond_to do |format|
          format.html
          format.json {render json: @result}
        end
      end
    end

    public
    ############################################################################
    #
    # Helpers for Diagnostic Controllers
    #
    ############################################################################
    def params_check
      params[:op] = 'errors' unless(params.has_key?(:op))
    end

    def diag_count
      @result.respond_to?(:tests) ? @result.tests.count : 1
    end

    def error_count
      @result.respond_to?(:tests) ? @result.tests.count(false) :
        (@result.status ? 1 : 0)
    end

    def db_server_name
      ActiveRecord::Base.connection_config[:host] || 'undefined'
    end

    def create_report name, tests
      Report.new(name, tests, self)
    end

    ############################################################################
    #
    # Diagnostics, Nodal Diagnostics, and Reports
    #
    ############################################################################

    # Reports
    # Report objects perform tests and group them together for display.
    def report
      tests = ['version', 'environment']
      Report.new('Report', tests, self)
    end

    def nodal_report
      tests = ['nodal_environment', 'nodal_version']
      create_report('Nodal Report', tests)
    end

    # Nodal Diagnostics
    # Nodal diagnostics will call the specified test (diag) on all nodes.
    def nodal_version
      NodalDiag.new('version', consistency: false)
    end

    def nodal_environment
      NodalDiag.new('environment', consistency: true)
    end

    # Diagnostics
    # Diagnostics are local to the node.
    def version
      begin
        gitv, gits = `cd #{Rails.root.to_s}; git describe;`.strip, true
      rescue
        gitv, gits = "Failed accessing git", false
      end
      details = [Info.new("Git"      , gitv, gits),
                 Info.new('Marty'    , Marty::VERSION),
                 Info.new('Delorean' , Delorean::VERSION),
                 Info.new('Mcfly'    , Mcfly::VERSION)]
      Diag.new('version', details)
    end

    def environment
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      details = [Info.new('Environment'     , Rails.env),
                 Info.new('Rails'           , Rails.version),
                 Info.new('Netzke Core'     , Netzke::Core::VERSION),
                 Info.new('Netzke Basepack' , Netzke::Basepack::VERSION),
                 Info.new('Ruby'            , rbv),
                 Info.new('RubyGems'        , Gem::VERSION),
                 Info.new('Database Adapter', ActiveRecord::Base.
                                                connection.adapter_name),
                 Info.new('Database Server' , db_server_name)]
      Diag.new('environment', details)
    end

    ############################################################################
    #
    # Info, Diag, NodalDiag, and Report Classes
    #
    ############################################################################

    # Info object packs information together for easier display.
    class Info
      attr_accessor :name, :status, :details
      def initialize(name, details, status = true)
        @name, @status, @details = name, status, details
      end

      def status_css
        status ? "passed" : "failed"
      end
    end

    # Diag object packs Info objects together for easier display.
    class Diag
      attr_accessor :name, :infos, :status
      def initialize(name, infos, opts ={})
        @name, @infos, @status = name, infos, infos.all?{|x| x.status}
      end

      def display label=nil
        display = <<-ERB
                <table>
                  <th><%= label.nil? ? @name : label %></th>
                  <th></th>
                  <% @infos.each do |i| %>
                    <tr class="<%= i.status_css %>">
                      <td><%= i.name %></td>
                      <td class="overflow"><%= i.details %></td>
                    </tr>
                  <% end %>
                </table>
                ERB
        ERB.new(display.html_safe).result(binding)
      end
    end

    # NodalDiag performs tests on all nodes that are discoverable.
    class NodalDiag
      attr_accessor :name, :diags, :nodes, :consistent, :consistency, :status
      def initialize(test, opts={})
        @test, @nodes = test.downcase.capitalize, get_nodes
        @diags = get_nodal_diags(test.downcase).sum
        @status = @nodes.all?{|n| @diags[n].status}
        @consistent = @nodes.map{|n| @diags[n].infos}.uniq.length == 1
        @consistency = opts[:consistency]
      end

      def get_nodal_diags test
        @nodes.map do |n|
          ssl = ENV['HTTPS'] == 'on'
          uri = Addressable::URI.new(host: n, port: ssl ? 443 : 80)
          uri.query_values = {op: test}
          uri.scheme = ssl ? 'https' : 'http'
          uri.path = '/marty/diagnostic/test.json'
          opts = {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
          {n => reconstruct_diag(JSON.parse(open(uri, opts).readlines[0]))}
        end
      end

      def get_pg_connections
        info = ActiveRecord::Base.connection.execute("SELECT datname,"\
                                                     "application_name,"\
                                                     "state,"\
                                                     "pid,"\
                                                     "client_addr "\
                                                     "FROM pg_stat_activity")
        info.each_with_object({}) do |x, h|
          h[x["datname"]] ||= []
          h[x["datname"]] << {"name"   => x["application_name"],
                              "address"=> x["client_addr"],
                              "state"  => x["state"],
                              "pid"    => x["pid"]}
        end
      end

      def reconstruct_diag diag
        Diag.new(diag["name"], diag["infos"].map{|x|
                   Info.new(x['name'], x['details'], x['status'])})
      end

      def resolve_target_nodes target
        db = ActiveRecord::Base.connection_config[:database]
        db_conns = get_pg_connections
        target_conns = db_conns[db].select{|x|
          x['name'].include? target}
        target_conns.map{|x| x['address']}.uniq.compact
      end

      def get_nodes
        nodes = resolve_target_nodes("Passenger")
        !nodes.empty? ? nodes : ['127.0.0.1']
      end

      def display
        display = <<-ERB
                  <div class="wrapper">
                     <h3><%= @test %></h3>
                    <% @nodes.each do |n| %>
                    <%= @diags[n].display n %>
                    <% break if @consistent && @consistency %>
                    <% end %>
                  </div>
                  ERB
        ERB.new(display.html_safe).result(binding)
      end
    end

    class Report
      attr_accessor :name, :tests, :status
      def initialize(name, tests, controller, opts ={})
        @name, @tests = name, tests.map{|t| controller.send(t.to_sym)}
      end

      def display
        display = <<-ERB
                  <h3><%= @name %></h3>
                  <div class="wrapper">
                    <% @tests.each do |t| %>
                      <%= t.display %>
                    <% end %>
                  </div>
                  ERB
        ERB.new(display.html_safe).result(binding)
      end
    end
  end
end
