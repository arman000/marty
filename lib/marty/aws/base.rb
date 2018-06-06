class Marty::Aws::Base
  # aws reserved host used to get instance meta-data
  META_DATA_HOST = '169.254.169.254'

  SERVICES = ['apigateway', 'ec2'].to_set.freeze

  attr_reader :id,
              :doc,
              :role,
              :creds,
              :version,
              :host,

  def self.get url
    uri = URI.parse(url)
    req = Net::HTTP.new(uri.host, uri.port)
    req.read_timeout = req.open_timeout = ENV['AWS_REQUEST_TIMEOUT'] || 0.25
    req.start {|http| http.get(uri.to_s) }.body
  end

  def self.is_aws?
    response = get("http://#{META_DATA_HOST}") rescue nil
    response.present?
  end

  def initialize
    @id            = get_instance_id
    @doc           = get_document
    @role          = get_role
    @creds         = get_credentials
    @version       = '2016-11-15'
  end

  def query_meta_data query
    self.class.get("http://#{META_DATA_HOST}/latest/meta-data/#{query}/")
  end

  def query_dynamic query
    self.class.get("http://#{META_DATA_HOST}/latest/dynamic/#{query}/")
  end

  private
  def get_instance_id
    query_meta_data('instance-id').to_s
  end

  def get_role
    query_meta_data('iam/security-credentials').to_s
  end

  def symbolize h
    h.each_with_object({}){|(k,v), h| h[k.underscore.to_sym] = v}
  end

  def get_credentials
    res = JSON.parse(query_meta_data("iam/security-credentials/#{@role}"))
    symbolize(res)
  end

  def get_document
    res = JSON.parse(query_dynamic('instance-identity/document'))
    symbolize(res)
  end

  def request service, info, params = {}
    raise "#{service} is not a supported AWS service" unless
      SERVICES.member?(service)

    action   = info[:action]
    endpoint = info[:endpoint]
    method   = info[:method] || :get

    default = action ? {'Action' => action, 'Version' => @version} : {}

    host = "#{service}.#{@doc['region']}.amazonaws.com"

    url = "https://#{@host}/"
    url += endpoint if endpoint
    url += '?' + (default + params).map{|a, v| "#{a}=#{v}"}.join('&') unless
      params.empty?

    sig = Aws::Sigv4::Signer.new(service:           @service,
                                 region:            @doc[:region],
                                 access_key_id:     @creds[:access_key_id],
                                 secret_access_key: @creds[:secret_access_key],
                                 session_token:     @creds[:token])
    signed_url = sig.presign_url(http_method:'GET', url: url)

    http = Net::HTTP.new(@host, 443)
    http.use_ssl = true
    Net::HTTP.send(method, signed_url)
  end

  def ensure_resp path, obj
    if path == []
      obj.is_a?(Array) ? obj : [obj]
    elsif obj.is_a?(Hash)
      key = path.shift
      raise "Unexpected AWS Response: #{key} missing" unless
        (obj.is_a?(Hash) && obj[key])

      ensure_resp(path, obj[key])
    else
      obj.map{|s| ensure_resp(path.clone, s)}.flatten(1)
    end
  end
end
