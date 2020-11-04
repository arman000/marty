module Marty
  module RpcCall
    # POST to a remote marty
    def marty_post(host, port, path, script, node, attrs, params, rpc_opts = {}, ssl = false, http_opts = {})
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

    def marty_download(
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
    def xml_call(host, port, path, body, use_ssl, options = {})
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
  end
end
