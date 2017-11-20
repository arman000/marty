include ActionView::Helpers::TextHelper
require 'erb'

module Marty
  class DiagnosticController < ActionController::Base
    layout false
    def op
      begin
        # inject request into Base class of all diagnostics
        Base.request   = request
        params[:scope] = 'nodal' unless params[:scope]
        diag = self.class.get_sub_class(params[:op])
        @result = params[:scope] == 'local' ? diag.generate : diag.aggregate
      rescue NameError
        render file: 'public/400', formats: [:html], status: 400, layout: false
      else
        respond_to do |format|
          format.html {@result = diag.display(@result, params[:scope])}
          format.json {render json: @result}
        end
      end
    end

    def self.get_sub_class klass
      const_get(klass.downcase.camelize)
    end

    private
    ############################################################################
    #
    # Diagnostics
    #
    ############################################################################
    class Base
      @@request     = nil
      @@read_only   = Marty::Util.db_in_recovery?

      def self.request= req
       @@request = req
      end

      def self.request
        @@request
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
          {n => JSON.parse(open(uri, opts).readlines[0])}
         end.sum
      end

      def self.find_failures data
        data.each_with_object({}){
          |(k,v), h| h[k] = v.include?('Failure') ? 'F' : 'P'}
      end

      def self.errors data
        data.keys.count{|n| is_failure?(data[n])}
      end

      def self.diff data
        data.keys.map{|n| data[n]}.uniq.length != 1
      end

      def self.package message
        {name.demodulize => message}
      end

      def self.is_failure? message
        message.to_s.include?('Failure')
      end

      def self.error message
        "Failure: #{message}"
      end

      def self.display data, type='nodal'
        data = {'local' => data} if type == 'local'
        display = <<-ERB
                <% inconsistent = diff(data) %>
                <h3><%=name.demodulize%></h3>
                <%='<h3 class="error">Issues Detected</h3>' if
                   inconsistent%>
                <div class="wrapper">
                <% data.each do |node, result| %>
                    <table>
                    <% issues = ('error' if inconsistent) %>
                    <th colspan="2" class="<%=issues%>">
                      <small>
                        <%=inconsistent ? node :
                           (type == 'local' ? 'local' : 'consistent') %>
                      </small>
                    </th>
                    <% result.each do |name, value| %>
                      <tr class="<%=is_failure?(value) ? 'failed' :
                                    'passed' %>">
                        <td><%=name%></td>
                        <td class="overflow"><%=simple_format(value.to_s)%></td>
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
        nodes.empty? ? ['127.0.0.1'] : nodes
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
          message = `cd #{Rails.root.to_s}; git describe --tags --always;`.strip
        rescue
          message = error("Failed accessing git")
        end
        {
          'Marty'    => Marty::VERSION,
          'Delorean' => Delorean::VERSION,
          'Mcfly'    => Mcfly::VERSION,
          'Git'      => message,
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

      def self.db_version
        begin
          message = ActiveRecord::Base.connection.
                      execute('SELECT VERSION();')[0]['version']
        rescue => e
          return error(message)
        end
        message
      end

      def self.db_schema
        begin
          current = ActiveRecord::Migrator.current_version
          needs_migration = ActiveRecord::Migrator.needs_migration?
        rescue => e
          return error(e.message)
        end
        needs_migration ? error("Migration is needed.\n"\
                                "Current Version: #{current}") : current
      end
    end

    class Environment < Database
      def self.generate
        rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
        infos = {'Environment'             => Rails.env,
                 'Rails'                   => Rails.version,
                 'Netzke Core'             => Netzke::Core::VERSION,
                 'Netzke Basepack'         => Netzke::Basepack::VERSION,
                 'Ruby'                    => rbv,
                 'RubyGems'                => Gem::VERSION,
                 'Database Adapter'        => db_adapter_name,
                 'Database Server'         => db_server_name,
                 'Database Version'        => db_version,
                 'Database Schema Version' => db_schema}
      end
    end

    class Nodes < Base
      def self.generate
        begin
          a_nodes  = AwsInstanceInfo.new.nodes.sort if AwsInstanceInfo.is_aws?
        rescue => e
          a_nodes = [e.message]
        end
        pg_nodes = get_nodes.sort
        message  = a_nodes.nil? || pg_nodes == a_nodes ? pg_nodes.join("\n") :
                     error("There is a discrepancy between nodes connected to "\
                           "Postgres and those discovered through AWS EC2.\n"\
                           "Postgres: \n#{pg_nodes.join("\n")}\n"\
                           "AWS: \n#{a_nodes.join("\n")}")
        {"PG/AWS" => message}
      end
    end

    class Env < Base
      def self.filter_env filter=''
        env = ENV.clone

        # obfuscate SECRET_KEY_BASE for comparison
        env['SECRET_KEY_BASE'] = env['SECRET_KEY_BASE'][0,4] if
          env['SECRET_KEY_BASE']

        # remove SCRIPT_URI, SCRIPT_URL as calling node differs
        ['SCRIPT_URI', 'SCRIPT_URL'].each{|k| env.delete(k)}

        to_block = ['PASSWORD', 'DEBUG']
        env.sort.each_with_object({}){|(k,v),h|
          h[k] = v if to_block.all?{|b| !k.include?(b)} && k.include?(filter)}
      end

      def self.generate
        filter_env
      end

      def self.aggregate
        envs = get_nodal_diags(name.demodulize)
        diff(envs) ? envs : package({})
      end
    end

    class DelayedJob < Base
      def self.delayed_job_count
        db = ActiveRecord::Base.connection_config[:database]
        get_pg_connections[db].count{|c| c['pid'] if
          c['name'].include?('delayed_job')}
      end

      def self.pretty hash
        hash.keys.map{|k| k + " => " + hash[k].to_s}.join("\n")
      end

      def self.verify_history delayed_versions
        @@history ||= delayed_versions
        @@history == delayed_versions
      end

      def self.validate data
        data.each_with_object({}) do
          |(k,v), h|
          h[k] = v.count > 1 ? error("\n" + v.join("\n")) :
                   v[0] != ENV['DELAYED_VER'] ? error(v[0]) : v[0]
        end
      end

      def self.generate
        count = delayed_job_count
        return {'Status' => ['No delayed jobs are running.']} if count.zero?

        # we will only iterate by half of the total delayed workers to avoid
        # excess use of delayed job time
        count = (count/2).zero? ? 1 : count/2

        d_engine = Marty::ScriptSet.new.get_engine("Diagnostics")
        res = d_engine.evaluate('VersionDelay', 'result', {'count' => count-1})

        # merge results and remove duplicates
        res.each_with_object({}){
          |r, h|
          h[r[0]] ||= []
          h[r[0]] << r[1]
        }.each_with_object({}){|(k,v), h| h[k] = v.uniq}
      end

      def self.aggregate
        d_vers = validate(generate)

        unless verify_history(d_vers)
          a = @@history.to_a
          b = d_vers.to_a
          @@history = d_vers
          d_vers += {"WARN" => error(["Result different from "\
                                      "#{Marty::Helper.my_ip}'s history.",
                                      "#{pretty(Hash[a - b])}"].join("\n"))}
        end
        package(d_vers)
      end

      def self.diff data
        data = data[name.demodulize] if data[name.demodulize]
        data.keys.map{|k| data[k]}.flatten.uniq.count != 1 ||
          data[data.keys[0]] != ENV['DELAYED_VER']
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
        controller = name.split(name.demodulize)[0].constantize
        controller.const_get(diag.capitalize)
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
        get_instances['reservationSet']['item'].map{
          |i|
          item = i['instancesSet']['item']
          item.is_a?(Array) ? item.map{|i| i['privateIpAddress']} :
            item['privateIpAddress']
        }.flatten
      end
    end
  end
end
