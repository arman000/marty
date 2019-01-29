class Marty::Aws::Request < Marty::Aws::Base
  # this class is used to make aws api requests for specific services
  # currently only used for diagnostics

  def request info, params = {}
    action   = info[:action]
    endpoint = info[:endpoint]
    method   = info[:method] || :get

    default = action ? {'Action' => action, 'Version' => @version} : {}

    host = "#{@service}.#{@doc[:region]}.amazonaws.com"

    url = "https://#{host}/"
    url += endpoint if endpoint
    url += '?' + (default + params).map {|a, v| "#{a}=#{v}"}.join('&') unless
      params.empty?

    sig = Aws::Sigv4::Signer.new(service:           @service,
                                 region:            @doc[:region],
                                 access_key_id:     @creds[:access_key_id],
                                 secret_access_key: @creds[:secret_access_key],
                                 session_token:     @creds[:token])
    signed_url = sig.presign_url(http_method:'GET', url: url)

    http = Net::HTTP.new(host, 443)
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
      obj.map {|s| ensure_resp(path.clone, s)}.flatten(1)
    end
  end
end
