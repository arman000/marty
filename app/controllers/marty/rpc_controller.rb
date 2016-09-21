class Marty::RpcController < ActionController::Base
  def evaluate
    res = do_eval(params["script"],
                  params["tag"],
                  params["node"],
                  params["attrs"] || "[]",
                  params["params"] || "{}",
                  params["api_key"] || nil,
                  params["background"],
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

  def do_eval(sname, tag, node, attrs, params, api_key, background)
    err = "Marty::RpcController#do_eval,"

    unless attrs.is_a?(String)
      logger.info "#{err} Bad attrs (must be a string): <#{attrs.inspect}>"
      return {error: "Bad attrs"}
    end

    begin
      attrs = ActiveSupport::JSON.decode(attrs)
    rescue JSON::ParserError => e
      logger.info "#{err} Malformed attrs (json): #{attrs.inspect}, #{e.message}"
      return {error: "Malformed attrs"}
    end

    unless attrs.is_a?(Array) && attrs.all? {|x| x.is_a? String}
      logger.info "#{err} Malformed attrs (not string array): <#{attrs.inspect}>"
      return {error: "Malformed attrs"}
    end

    unless params.is_a?(String)
      logger.info "#{err} Bad params (must be a string): <#{params.inspect}>"
      return {error: "Bad params"}
    end

    begin
      params = ActiveSupport::JSON.decode(params)
    rescue JSON::ParserError => e
      logger.info "#{err} Malformed params (json): <#{params.inspect}>, #{e.message}"
      return {error: "Malformed params"}
    end

    unless params.is_a?(Hash)
      logger.info "#{err} Malformed params (not hash): <#{params.inspect}>"
      return {error: "Malformed params"}
    end

    unless Marty::ApiAuth.authorized?(sname, api_key)
      logger.info "#{err} permission denied"
      return {error: "Permission denied" }
    end

    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname)
    rescue => e
      err_msg = "Can't get engine: #{sname || 'nil'} with tag: " +
              "#{tag || 'nil'}; message: #{e.message}"
      logger.info "#{err} #{err_msg}"
      return {error: err_msg}
    end

    begin
      if background
        result = engine.background_eval(node, params, attrs)
        {"job_id" => result.__promise__.id}
      else
        engine.evaluate_attrs(node, attrs, params)
      end
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc)
      logger.info "#{err} Evaluation error: #{err_msg}"
      err_msg
    end
  end
end
