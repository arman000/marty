class Marty::RpcCall
  # POST to a remote marty
  def self.marty_post(host, port, path, script, node, attrs, params, options = {},
                      ssl = false)
    http = Net::HTTP.new(host, port)
    http.use_ssl = ssl
    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    request.body = (options + {
                      "script" => script,
                      "node"   => node,
                      "attrs"  => attrs.to_json,
                      "params" => params.to_json,
                    }).to_json
    begin
      response = http.request(request)
    rescue => e
      raise "#{e.message} during RPC call to #{host}:#{port}"
    end

    res = JSON.parse(response.body)
    raise res["error"] if res.is_a?(Hash) && !res["error"].blank?

    res
  end

  def self.marty_download(host, port, path, job_id, ssl = false)
    params = { job_id: job_id }
    url = path + '?' + URI.encode(URI.encode_www_form(params))

    http = Net::HTTP.new(host, port)
    http.use_ssl = ssl
    request = Net::HTTP::Get.new(url)

    begin
      http.request(request)
    rescue => e
      raise "#{e.message} during download call to #{host}:#{port}"
    end
  end

  def self.xml_call(host, port, path, body, use_ssl)
    http = Net::HTTP.new(host, port)
    request = Net::HTTP::Post.new(path)
    http.use_ssl = use_ssl
    request.add_field('Content-Type', 'xml')
    request.add_field('Accept', 'xml')
    request.body = body

    begin
      response = http.request(request)
      raise "got #{response} during XML call" if response.class != Net::HTTPOK
    rescue => e
      raise "#{e.message} during RPC call to #{host}:#{port}#{path}"
    end

    response.body
  end
end
