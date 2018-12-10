class Marty::RpcController < ActionController::Base
  def evaluate
    begin
      # set default result and params in case of unexpected errors
      # to ensure logging capabilities
      result          = nil
      api_params      = {}
      start_time      = nil
      auth            = nil

      # massage request params
      massaged_params = massage_params(params)

      # resolve api config in order to determine api class and settings
      api_config = Marty::ApiConfig.lookup(*massaged_params.values_at(
                                             :script,
                                             :node,
                                             :attr)
                                          ) || {}

      # default to base class if no config is present
      api = api_config.present? ? api_config[:api_class].constantize :
              Marty::Api::Base

      return result = massaged_params if massaged_params.include?(:error)

      api_params = api.process_params(massaged_params)
      auth       = api.is_authorized?(massaged_params)
      return result = {error: "Permission denied"} unless auth

      start_time = Time.zone.now
      api.before_evaluate(api_params)
      result = api.evaluate(api_params, request, api_config)
      api.after_evaluate(api_params, result)
    rescue => e
      # log unexpected failures in rpc controller and respond with
      # generic server error
      Marty::Logger.log('rpc_controller', 'failure', e.message)
      result = {error: 'internal server error'}
    ensure
      # if logging is enabled, always log the result even on error
      if api_config && api_config[:logged] && api
        api.log(result,
                api_params + {start_time: start_time, auth: auth},
                request)
      end

      api.respond_to(self) do
        result || {'error' => 'internal server error'}
      end
    end
  end

  private
  def process_active_params params
    # must permit params before conversion to_h
    # convert hash to json and parse to get expected hash (not indifferent)
    params.permit!
    JSON.parse(params.to_h.to_json)
  end

  def massage_params request_params
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

    return {error: "Malformed attrs"} unless
      attr.is_a?(String) || (attr.is_a?(Array) && attr.count == 1)

    # if attr is a single attr array, remember to return as an array
    if attr.is_a? Array
      attr    = attr[0]
      ret_arr = true
    end

    return {error: "Malformed attrs"} unless attr =~ /\A[a-z][a-zA-Z0-9_]*\z/

    begin
      case params
      when String
        params = ActiveSupport::JSON.decode(params)
      when nil
        params = {}
      when ActionController::Parameters
        params = process_active_params(params)
      else
        return {error: "Bad params"}
      end
    rescue JSON::ParserError => e
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless params.is_a?(Hash)

    # permit request params and convert to hash
    process_active_params(request_params.except(:rpc)).symbolize_keys + {
      attr:         attr,
      params:       params,
      return_array: ret_arr
    }
  end
end
