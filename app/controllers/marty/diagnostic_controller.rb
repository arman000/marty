module Marty
  class DiagnosticController < ActionController::Base

    class Info
      attr_accessor :name, :status, :result
      def initialize(name, description, status = true)
        @name, @status, @description = name, status, description
      end

      def status_text
        case status
        when true
          "Passed"
        when false
          "Failed"
        else
          "Unknown"
        end
      end
    end

    layout false
    before_filter :params_check
    attr_accessor :details

    D_FORMAT  = '%Y-%m-%d'
    T_FORMAT  = '%H:%M:%S'
    DT_FORMAT = D_FORMAT + ' ' + T_FORMAT
    READ_ONLY = ' disabled - database is in read-only mode'
    CLG       = ' disabled - environment is in clg mode'
    SANDBOX   = ' disabled - environment is in sandbox mode'

    OPS = [
      'login',
      'dbgemini',
      'rpc',
      'flux',
      'bloomberg',
      'bloombergterminal',
      'rabbitmq',
      'backgroundjob',
      'servertime',
      'dw',
      'mmsapi',
      'bdmmsapi',
      'fnma',
      'fnma2',
      'fhlmc_pls',
      'fhlmc_trs',
      'errors',
      'errors_external',
      'all',
      'all_external',
      'version',
      'environment',
      'nodes'
    ]

    AGOPS = [
      'gemini_health'
    ]

    def testop
      unless OPS.member? params[:testop]
        render file: 'public/400', formats: [:html], status: 400, layout: false
        return
      end
      @show_detail = true
      @details     = []
      @data        = ''
      @read_only   = Marty::Util.db_in_recovery?

      @result = [self.send(:"#{params[:testop]}_test")]

      respond_to do |format|
        format.html
        format.json {
          render json: [
                   {error_count: error_count},
                   {diag_count: diag_count},
                 ] + @result
        }
      end
    end

    private


    # queries pg_stat_activity to determine pg connections
    def fetch_pg_connections
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

    def resolve_target_nodes db, target
      db_conns = fetch_pg_connections
      gemini_conns = db_conns[ENV[db]].select{|x|
        x['name'].include? target}
      gemini_conns.map{|x| x['address']}.uniq.compact
    end

    def gemini_nodes
      resolve_target_nodes("GEMINI_DB", "Passenger")
    end

    # request diag test information from node
    def get_nodal_diag node, test
      ssl = ENV['HTTPS'] == 'on'
      uri = Addressable::URI.new(host: node, port: ssl ? 443 : request.port)
      uri.query_values = {testop: test}
      uri.scheme = ssl ? 'https' : 'http'
      uri.path = '/diag.json'
      JSON.parse(open(uri,
                      {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).readlines[0])
    end

    def construct_agg_obj resp, opts = {}
      obj = {"details" => resp.select{|x| x["name"] &&
                                      !(x["status"] &&
                                        opts[:filter])}}
      return obj unless opts[:cumm_status]
      obj + {"cumm_status" => resp.all?{|x| x['error_count'].to_i == 0}}
    end

    # performs the desired test accross nodes and returns a hash
    def aggregate_test test, nodes, opts = {}
      nodes.each_with_object({}){
        |n, h| h[n] = construct_agg_obj(get_nodal_diag(n, test), opts)}
    end

    # the main funcion that aggregates tests and determines other information
    def gemini_health_test
      @nodes = gemini_nodes
      @tests = {"all" => all_consistency,
                "version" => target_consistency("version"),
                "environment" => target_consistency("environment")}
    end

    def all_consistency
      test =  aggregate_test("all", @nodes, cumm_status: true)
      test + {"agg_status" => @nodes.all?{|x| test[x]["cumm_status"]},
              "show_nodes" => true}
    end

    # gets aws credentials based on role, which can be used for api req
    def get_aws_credentials
      role = "cf-gemini-dev-2-geminiappSuperUserRole-1UD17HK16BY7I"
      uri = URI.parse("http://169.254.169.254/latest/meta-data/iam/"\
                      "security-credentials/#{role}")
      credentials = JSON.parse(Net::HTTP.get(uri))
    end

    # uses aws-sigv4 gem to sign request for authentication
    # hard-coded tag value for now
    def get_aws_instances
      creds = get_aws_credentials
      service = 'ec2'
      host    = "ec2.us-west-2.amazonaws.com"
      region  = 'us-west-2'
      action  = 'DescribeInstances'
      version = '2016-11-15'
      tag     = 'cf-gemini-dev-2'

      url = URI.parse("https://#{host}/?Action=#{action}&Version=#{version}"\
                      "&Filter.1.Name=tag-value"\
                      "&Filter.1.Value.1=#{tag}")
      signer = Aws::Sigv4::Signer.new(service:           service,
                                      region:            region,
                                      access_key_id:     creds["AccessKeyId"],
                                      secret_access_key: creds["SecretAccessKey"],
                                      session_token:     creds["Token"])
      signature =  signer.presign_url(http_method:'GET', url: url)

      http = Net::HTTP.new(host, 443)
      http.use_ssl = true
      Hash.from_xml(Net::HTTP.get(signature))["DescribeInstancesResponse"]
    end

    def resolve_aws_gemini_ips
      get_aws_instances["reservationSet"]["item"].
        map{|i| i["instancesSet"]["item"]["privateIpAddress"]}
    end

    def target_consistency target
      test = aggregate_test(target, @nodes)
      data = test.map{|x| x[1]}
      status = data.uniq.count == 1
      test + {"agg_status" => status}
    end

    def diag_count
      details.count
    end

    def error_count
      details.count {|d| !d.status}
    end

    def params_check
      params[:testop] = 'errors' unless(params.has_key?(:testop))
      params[:testop] = 'environment' if params[:testop] == 'env'
    end

    def db_server_name
      ActiveRecord::Base.connection_config[:host] || 'undefined'
    end

    def errors_test
      @show_detail = false
      all_test
      @data = "Error count=#{error_count}"
    end

    def all_test
    end

    def errors_external_test
      @show_detail = false
      all_external_test
      @data = "Error count=#{error_count}"
    end

    def version_test
      app_name = Rails.application.class.parent_name
      begin
        gitv, gits = `cd #{Rails.root.to_s}; git describe;`.strip, true
      rescue
        gitv, gits = "Failed accessing git", false
      end

      infos = [Info.new("#{app_name} Git Version" , gits, gitv),
               Info.new('Marty Version', true, Marty::VERSION),
               Info.new('Delorean Version', true, Delorean::VERSION),
               Info.new('Mcfly Version', true, Mcfly::VERSION)]

      Diagnostic.new(name: "version", details: infos)
    end
  end
end
