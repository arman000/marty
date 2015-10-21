class Marty::RpcController < ActionController::Base
  respond_to :json, :csv

  def evaluate
    res = do_eval(params["script"],
                  params["tag"],
                  params["node"],
                  params["attrs"] || "[]",
                  params["params"] || "{}",
                  params["api_key"] || nil,
                  )

    respond_to do |format|
      format.json { send_data res.to_json }
      format.csv  {
        # SEMI-HACKY: strip outer list if there's only one element.
        res = res[0] if res.is_a?(Array) && res.length==1
        send_data Marty::DataExporter.to_csv(res)
      }
    end

  end

  private

  def do_eval(sname, tag, node, attrs, params, api_key)
    unless attrs.is_a?(String)
      logger.info "Marty::RpcController#do_eval, Bad attrs (must be a string): <#{attrs.inspect}>"
      return {error: "Bad attrs"}
    end

    begin
      attrs = ActiveSupport::JSON.decode(attrs)
    rescue JSON::ParserError => e
      logger.info "Marty::RpcController#do_eval, Malformed attrs (json parse error): #{attrs.inspect}, #{e.message}"
      return {error: "Malformed attrs"}
    end

    unless attrs.is_a?(Array) && attrs.all? {|x| x.is_a? String}
      logger.info "Marty::RpcController#do_eval, Malformed attrs (must be array of strings): <#{attrs.inspect}>"
      return {error: "Malformed attrs"}
    end

    unless params.is_a?(String)
      logger.info "Marty::RpcController#do_eval, Bad params (must be a string): <#{params.inspect}>"
      return {error: "Bad params"}
    end

    begin
      params = ActiveSupport::JSON.decode(params)
    rescue JSON::ParserError => e
      logger.info "Marty::RpcController#do_eval, Malformed params (json parse error): <#{params.inspect}>, #{e.message}"
      return {error: "Malformed params"}
    end

    unless params.is_a?(Hash)
      logger.info "Marty::RpcController#do_eval, Malformed params (must be a hash): <#{params.inspect}>"
      return {error: "Malformed params"}
    end

    unless Marty::ApiAuth.authorized?(sname, api_key)
      logger.info "Marty::RpcController#do_eval, permission denied"
      return {error: "Permission denied" }
    end

    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname)
    rescue => e
      err_msg = "Can't get engine: #{sname || 'nil'} with tag: " +
              "#{tag || 'nil'}; message: #{e.message}"
      logger.info "Marty::RpcController#do_eval, #{err_msg}"
      return {error: err_msg}
    end

    begin
      engine.evaluate_attrs(node, attrs, params)
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc)
      logger.info "Marty::RpcController#do_eval, Evaluation error: #{err_msg}"
      err_msg
    end
  end
end
