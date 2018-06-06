module Marty::Diagnostic; class ExternalApiEndpoints < Base
  diagnostic_fn aggregatable: false do
    begin
      var = 'EXTERNAL_API_ENDPOINTS'
      endpoints = Marty::Config[var] || []
      next error("'#{var}' is not an array of endpoints") unless
        endpoints.is_a?(Array)

      method = 'token'
      msg    = "Stage: #{Rails.env.titleize}\nMethod: #{method.titleize}\n"

      # we check that the APIs are deployed properly by
      # checking the token endpoint
      results = endpoints.map do |e|
        Thread.new do
          uri = URI.parse([e, Rails.env, method].join('/'))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri, {})
          request.body = {}.to_json
          http.request(request).body
        end
      end.map{|t| t.join && t.value}

      # forbidden actually lets us know our api is set up as expected
      # FIXME: add better methodology
      endpoints.each_with_object({}).with_index do |(e, h), i|
        h[e] = results[i].include?('Forbidden') ?
                 msg : error("#{msg}\nAPI Call Failed\n#{results[i]}")
      end
    rescue => e
      error("#{msg} #{e.message}")
    end
  end
end
end
