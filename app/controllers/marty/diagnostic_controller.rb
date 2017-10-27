require 'erb'
module Marty
  class DiagnosticController < ActionController::Base
    layout false
    def op
      @show_detail = true
      @data        = ''
      @read_only   = Marty::Util.db_in_recovery?
      begin
        # inject request into Base class of all diagnostics
        Base.request = request
        params[:scope] = 'nodal' unless params[:scope]
        diag = self.class.get_sub_class(params[:op])
        @result = params[:scope] == 'local' ? diag.generate : diag.aggregate
      rescue NameError
        render file: 'public/404', formats: [:html], status: 404, layout: false
      else
        respond_to do |format|
          format.html {@result = diag.display(@result, params[:scope])}
          format.json {render json: @result}
        end
      end
    end

    def self.get_sub_class klass
      (name + '::' + klass.downcase.camelize).constantize
    end

    private
    ############################################################################
    #
    # Diagnostics
    #
    ############################################################################
    class Base
      attr_accessor :request
      @@request = nil

      D_FORMAT  = '%Y-%m-%d'
      T_FORMAT  = '%H:%M:%S'
      DT_FORMAT = D_FORMAT + ' ' + T_FORMAT
      READ_ONLY = ' disabled - database is in read-only mode'
      CLG       = ' disabled - environment is in clg mode'
      SANDBOX   = ' disabled - environment is in sandbox mode'

      def self.request= req
       @@request = req
      end

      def self.aggregate op_name=name.demodulize
        get_nodal_diags(op_name)
      end

      def self.get_nodal_diags op_name, scope='local'
         self.get_nodes.map do |n|
          ssl = ENV['HTTPS'] == 'on'
          uri = Addressable::URI.new(host: n, port: ssl ? 443 : @@request.port)
          uri.query_values = {op: op_name.underscore,
                              scope: scope}
          uri.scheme = ssl ? 'https' : 'http'
          uri.path = '/marty/diag.json'
          opts = {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
          {n => (JSON.parse(open(uri, opts).readlines[0]))}
         end.sum
      end

      def self.diff data
        data.keys.map{|n| data[n]}.uniq.length != 1
      end

      def self.package status, message
        {name.demodulize.capitalize => [status, message]}
      end

      def self.display data, type='nodal'
        data = {'local' => data} if type == 'local'
        display = <<-ERB
                <% inconsistent = diff(data) %>
                <h3><%=name.demodulize%></h3>
                <%='<h3 class="error">&#x26a0; Issues Detected</h3>' if
                   inconsistent%>
                <div class="wrapper">
                <% data.each do |node, result| %>
                    <table>
                    <% issues = ('error' if inconsistent) %>
                    <th class=<%=issues%>><%=inconsistent ? node :
                                             '<small>consistent</small>'%></th>
                    <th class=<%=issues%>></th>
                    <% result.each do |name, value| %>
                      <tr class="<%=value.first ? "passed" : "failed"%>">
                        <td><%=name%></td>
                        <td class="overflow"><%=value.last%></td>
                      </tr>
                    <% end %>
                    </table>
                  <% break unless inconsistent %>
                <% end %>
                </div>
                ERB
        ERB.new(display.html_safe).result(binding)
      end

      def self.get_pg_connections
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

      def self.resolve_target_nodes target
        db = ActiveRecord::Base.connection_config[:database]
        db_conns = get_pg_connections
        target_conns = db_conns[db].select{|x|
          x['name'].include? target}
        target_conns.map{|x| x['address']}.uniq.compact
      end

      def self.get_nodes
        nodes = resolve_target_nodes("Passenger")
        !nodes.empty? ? nodes : ['127.0.0.1']
      end
    end

    ############################################################################
    #
    # Diagnostic Definitions
    # Default: pulls from all nodes; force local with '&scope=local'
    #
    ############################################################################
    class Version < Base
      def self.generate
        begin
          message, status = `cd #{Rails.root.to_s}; git describe;`.strip, true
        rescue
          message, status = "Failed accessing git", false
        end
        {
          'Git'      => [status, message],
          'Marty'    => [true, Marty::VERSION],
          'Delorean' => [true, Delorean::VERSION],
          'Mcfly'    => [true, Mcfly::VERSION]
        }
      end
    end

    class Database < Base
      def self.db_server_name
        ActiveRecord::Base.connection_config[:host] || 'undefined'
      end

      def self.db_adapter_name
        ActiveRecord::Base.connection.adapter_name
      end

      def self.db_time
        ActiveRecord::Base.connection.execute('SELECT NOW();')
      end

      def self.db_version_info
        begin
        message = ActiveRecord::Base.connection.
                    execute('SELECT VERSION();')[0]['version']
        rescue => e
          return [false, e.message]
        end
        [true, message]
      end

      def self.db_schema_info
        begin
          message = AciveRecord::Migrator.current_version
        rescue => e
          return [false, e.message]
        end
        [true, message]
      end
    end

    class Environment < Database
      def self.generate
        rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
        infos = {'Environment'             => [true, Rails.env],
                 'Rails'                   => [true, Rails.version],
                 'Netzke Core'             => [true, Netzke::Core::VERSION],
                 'Netzke Basepack'         => [true, Netzke::Basepack::VERSION],
                 'Ruby'                    => [true, rbv],
                 'RubyGems'                => [true, Gem::VERSION],
                 'Database Adapter'        => [true, db_adapter_name],
                 'Database Server'         => [true, db_server_name],
                 'Database Version'        => db_version_info,
                 'Database Schema Version' => db_schema_info}
        begin
          status, message = true, ActiveRecord::Migrator.current_version
        rescue => e
          status = false
          message = e.message
        end
        infos['Database Schema Version'] = [status, message]
        infos
      end
    end

    class Nodes < Base
      def self.generate
        a_nodes  = AwsInstanceInfo.is_aws? ? AwsInstanceInfo.new.nodes : []
        a_status = !a_nodes.empty?
        {"Postgres Connections" => [true, get_nodes.sort.join(', ')],
         "Amazon Instances"     => [a_status,
                                    a_status ? a_nodes.sort.join(', ') :
                                      'Could not retrieve metadata.']}
      end
    end

    ############################################################################
    #
    # Reports
    #
    ############################################################################
    class Report < Base
      class << self
        attr_accessor :diags
      end

      def diags
        self.class.diags
      end

      self.diags = ['nodes', 'version', 'environment']

      def self.get_diag_klass diag
        (name.chomp(name.demodulize) + diag.capitalize).constantize
      end

      def self.generate
        diags.each_with_object({}){|d, h| h[d] = get_diag_klass(d).generate}
      end

      def self.aggregate
        diags.each_with_object({}){|d, h| h[d] = get_diag_klass(d).aggregate}
      end

      def self.display data, type
        report = '<h3>' +
                 name.demodulize +
                 " #{'(' + type + ')' if type == 'local'}" +
                 '</h3>'
        displays = diags.map{|d| get_diag_klass(d).display(data[d], type)}
        ([report] + displays).sum
      end
    end

    ############################################################################
    #
    # AWS Helper Class
    #
    ############################################################################
    class AwsInstanceInfo
      attr_accessor :id, :doc, :role, :creds, :version, :host, :tag, :nodes

      # aws reserved host used to get instance meta-data
      META_DATA_HOST = '169.254.169.254'

      def self.is_aws?
        uri = URI.parse("http://#{META_DATA_HOST}")
        !(Net::HTTP.get(uri) rescue nil).nil?
      end

      def initialize
        @id      = get_instance_id
        @doc     = get_document
        @role    = get_role
        @creds   = get_credentials
        @host    = "ec2.#{@doc['region']}.amazonaws.com"
        @version = '2016-11-15'
        @tag     = get_tag
        @nodes   = get_private_ips
      end

      private
      def query_meta_data query
        uri = URI.parse("http://#{META_DATA_HOST}/latest/meta-data/#{query}/")
        Net::HTTP.get(uri)
      end

      def query_dynamic query
        uri = URI.parse("http://#{META_DATA_HOST}/latest/dynamic/#{query}/")
        Net::HTTP.get(uri)
      end

      def get_instance_id
        query_meta_data('instance-id').to_s
      end

      def get_role
        query_meta_data('iam/security-credentials').to_s
      end

      def get_credentials
        JSON.parse(query_meta_data("iam/security-credentials/#{@role}"))
      end

      def get_document
        JSON.parse(query_dynamic('instance-identity/document'))
      end

      def ec2_req action, params = {}
        url = "https://#{@host}/?Action=#{action}&Version=#{@version}"
        params.each{|a, v| url += "&#{a}=#{v}"}

        sig = Aws::Sigv4::Signer.new(service:           'ec2',
                                     region:            @doc['region'],
                                     access_key_id:     @creds['AccessKeyId'],
                                     secret_access_key: @creds['SecretAccessKey'],
                                     session_token:     @creds['Token'])
        signed_url = sig.presign_url(http_method:'GET', url: url)

        http = Net::HTTP.new(@host, 443)
        http.use_ssl = true
        Hash.from_xml(Net::HTTP.get(signed_url))["#{action}Response"]
      end

      def get_tag
        params = {'Filter.1.Name'    => 'resource-id',
                  'Filter.1.Value.1' => get_instance_id,
                  'Filter.2.Name'    => 'key',
                  'Filter.2.Value.1' => 'Name'}
        ec2_req('DescribeTags', params)['tagSet']['item']['value']
      end

      def get_instances
        params = {'Filter.1.Name'    => 'tag-value',
                  'Filter.1.Value.1' => @tag}
        ec2_req('DescribeInstances', params)
      end

      def get_private_ips
        get_instances['reservationSet']['item'].
          map{|i| i['instancesSet']['item']['privateIpAddress']}
      end
    end
  end
end
