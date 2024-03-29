class Marty::RpcCall
  # POST to a remote marty
  def self.marty_post(host, port, path, script, node, attrs, params,
                      rpc_opts = {}, ssl = false, http_opts = {})
    http = Net::HTTP.new(host, port)

    # FIXME: in 5.2.0 put ssl in https_opts hash and change interface
    http.use_ssl = ssl
    http.read_timeout = http_opts[:read_timeout] if http_opts[:read_timeout]
    http.open_timeout = http_opts[:open_timeout] if http_opts[:open_timeout]

    request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    request.body = rpc_opts.merge(
      'script' => script,
      'node'   => node,
      'attrs'  => attrs.to_json,
      'params' => params.to_json,
    ).to_json

    begin
      response = http.request(request)
    rescue StandardError => e
      raise "#{e.message} during RPC call to #{host}:#{port}"
    end

    res = JSON.parse(response.body)
    raise res['error'] if res.is_a?(Hash) && res['error'].present?

    res
  end

  def self.marty_download(
    host, port, path, job_id, ssl = false, read_timeout = 60
  )

    params = { job_id: job_id }
    url = path + '?' + URI.encode(URI.encode_www_form(params))

    http = Net::HTTP.new(host, port)
    http.use_ssl = ssl
    http.read_timeout = read_timeout

    request = Net::HTTP::Get.new(url)

    begin
      http.request(request)
    rescue StandardError => e
      raise "#{e.message} during download call to #{host}:#{port}"
    end
  end

  # FIXME: in Marty 5.2.0 put ssl in options hash
  def self.xml_call(host, port, path, body, use_ssl, options = {})
    http = Net::HTTP.new(host, port)
    request = Net::HTTP::Post.new(path)
    http.use_ssl = use_ssl
    http.ciphers = options[:ciphers] if options[:ciphers]
    http.read_timeout = options[:read_timeout] if options[:read_timeout]
    http.open_timeout = options[:open_timeout] if options[:open_timeout]
    request.add_field('Content-Type', 'xml')
    request.add_field('Accept', 'xml')
    request.body = body

    begin
      response = http.request(request)
      raise "got #{response} during XML call" if response.class != Net::HTTPOK
    rescue StandardError => e
      raise "#{e.message} during RPC call to #{host}:#{port}#{path}"
    end

    response.body
  end

  def self.json_call(host, port, path, body, ssl, http_opts = {}, get = false)
    http = Net::HTTP.new(host, port)
    http.use_ssl = ssl
    http.read_timeout = http_opts[:read_timeout] if http_opts[:read_timeout]
    http.open_timeout = http_opts[:open_timeout] if http_opts[:open_timeout]

    request = get ? Net::HTTP::Get.new(path) : request = Net::HTTP::Post.new(path)
    request.add_field('Content-Type', 'application/json')
    request.body = body.to_json

    base_log = {
      host: host,
      port: port,
      path: path,
      input: body,
    }
    begin
      response = http.request(request)
      json = JSON.parse(response.body)
      if json.is_a?(Hash) && json['error'].present?
        Marty::Logger.info('Marty::RpcCall#json_call',
                           base_log.merge(output: json)
                          )
      end
      json
    rescue StandardError => e
      Marty::Logger.error('Marty::RpcCall#json_call',
                          base_log.merge(
                            error: e.message,
                            stack: e.backtrace.select { |s| s.include?('marty') },
                            output: response
                          ).compact
                         )
      raise "#{e.message} during JSON RPC call to #{host}:#{port}#{path}"
    end
  end
end
