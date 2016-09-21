class Marty::RpcCall
  def self.marty_post(host, port, path, script, node, attrs, params)
    http = Net::HTTP.new(host, port)
    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    request.body = {
      "script" => script,
      "node"   => node,
      "attrs"  => attrs.to_json,
      "params" => params.to_json,
    }.to_json
    begin
      resraw = http.request(request)
    rescue => e
      raise "#{e.message} during RPC call to #{host}:#{port}"
    end
    res = JSON.parse(resraw.body)
    raise res["error"] if res.is_a?(Hash) && !res["error"].blank?
    res
  end

  def self.xml_call(host, port, path, body, use_ssl)
    http = Net::HTTP.new(host, port)
    request = Net::HTTP::Post.new(path)
    http.use_ssl = use_ssl
    request.add_field('Content-Type', 'xml')
    request.add_field('Accept', 'xml')
    request.body = body
    begin
      resraw = http.request(request)
      if resraw.class != Net::HTTPOK
        raise "got #{resraw} during XML call"
      end
    rescue => e
      raise "#{e.message} during RPC call to #{host}:#{port}#{path}"
    end
    resraw.body
  end
end
