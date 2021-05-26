# frozen_string_literal: true

class Marty::RpcController < ActionController::Base
  INTERNAL_SERVER_ERROR   = { error: 'internal server error' }
  PERMISSION_DENIED_ERROR = { error: 'Permission denied' }

  def evaluate
    massaged_params = massage_params(params)

    # resolve api config in order to determine api class and settings
    api_config = get_api_config(massaged_params) || {}

    # default to base class if no config is present
    api = api_config[:api_class].try(:constantize) || Marty::Api::Base

    api.respond_to(self) do
      begin
        next massaged_params if massaged_params.include?(:error)

        api_params = api.process_params(massaged_params)
        auth       = api.is_authorized?(api_params)

        next PERMISSION_DENIED_ERROR unless auth

        # allow api classes to return hashes with error key for custom responses
        next auth if auth.is_a?(Hash) && auth[:error]

        start_time = Time.zone.now
        api.before_evaluate(api_params)

        result = api.evaluate(api_params, request, api_config)
        api.after_evaluate(api_params, result)

        if api_config[:logged]
          log_params = api_params + { start_time: start_time, auth: auth }
          api.log(result, log_params, request)
        end

        # Do not expose backtrace in case of error
        next result.except('backtrace', :backtrace) if result.is_a?(Hash)

        result
      rescue StandardError => e
        Marty::Logger.log('rpc_controller', 'failure', e.message)
        INTERNAL_SERVER_ERROR
      end
    end
  end

  private

  def get_api_config(params)
    config_attrs = params.values_at(:script, :node, :attr)
    Marty::ApiConfig.lookup(*config_attrs)
  end

  def process_active_params(params)
    # must permit params before conversion to_h
    # convert hash to json and parse to get expected hash (not indifferent)
    params.permit!
    JSON.parse(params.to_h.to_json)
  end

  def massage_params(request_params)
    sname,
    tag,
    node,
    attr,
    params,
    api_key,
    background = request_params.values_at(:script,
                                          :tag,
                                          :node,
                                          :attrs,
                                          :params,
                                          :api_key,
                                          :background)

    # FIXME: small patch to allow for single attr array
    attr = ActiveSupport::JSON.decode(attr) rescue attr

    return { error: 'Malformed attrs' } unless
      attr.is_a?(String) || (attr.is_a?(Array) && attr.count == 1)

    # if attr is a single attr array, remember to return as an array
    if attr.is_a? Array
      attr    = attr[0]
      ret_arr = true
    end

    return { error: 'Malformed attrs' } unless /\A[a-z][a-zA-Z0-9_]*\z/.match?(
      attr.to_s
    )

    begin
      case params
      when String
        params = ActiveSupport::JSON.decode(params)
      when nil
        params = {}
      when ActionController::Parameters
        params = process_active_params(params)
      else
        return { error: 'Bad params' }
      end
    rescue JSON::ParserError => e
      return { error: 'Malformed params' }
    end

    return { error: 'Malformed params' } unless params.is_a?(Hash)

    # permit request params and convert to hash
    process_active_params(request_params.except(:rpc)).symbolize_keys + {
      attr:         attr,
      params:       params,
      return_array: ret_arr
    }
  end
end
