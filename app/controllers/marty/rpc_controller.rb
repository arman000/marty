class Marty::RpcController < ActionController::Base
  def evaluate
    massaged_params = massage_params(params)
    api_config = Marty::ApiConfig.lookup(*massaged_params.values_at(
                                           :script,
                                           :node,
                                           :attr)
                                        ) || {}

    api = api_config.present? ? api_config[:api_class].constantize :
            Marty::Api::Base

    api.respond_to(self) do
      api_params = api.process_params(massaged_params)
      api.before_evaluate(api_params)
      next api_params if api_params.include?(:error)

      auth = api.is_authorized?(api_params)
      next {error: "Permission denied"} unless auth

      start_time = Time.zone.now

      result = api.evaluate(api_params.deep_dup, request, api_config.deep_dup)
      api.after_evaluate(api_params.deep_dup, result)

      log_params = {start_time: start_time, auth: auth}
      api.log(result, api_params + log_params, request) if
        api_config[:logged]

      result
    end
  end

  private

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
      when ActionController::Parameters
        params.permit!
        params = JSON.parse(params.to_h.to_json)
      when nil
        params = {}
      else
        return {error: "Bad params"}
      end
    rescue JSON::ParserError => e
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless params.is_a?(Hash)

    {
      script:       sname,
      tag:          tag,
      node:         node,
      attr:         attr,
      params:       params,
      api_key:      api_key,
      background:   background,
      return_array: ret_arr
    }
  end
end
