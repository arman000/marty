class Marty::RpcController < ActionController::Base
  respond_to :json, :csv

  def evaluate
    res = do_eval(params["script"],
                  params["version"],
                  params["node"],
                  params["attrs"] || "[]",
                  params["params"] || "{}",
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

  def do_eval(sname, version, node, attrs, params)
    return {error: "Bad attrs"} if !attrs.is_a?(String)

    begin
      attrs = ActiveSupport::JSON.decode(attrs)
    rescue MultiJson::DecodeError
      return {error: "Malformed attrs"}
    end

    return {error: "Malformed attrs"} unless
      attrs.is_a?(Array) && attrs.all? {|x| x.is_a? String}

    return {error: "Bad params"} if !params.is_a?(String)

    begin
      params = ActiveSupport::JSON.decode(params)
    rescue MultiJson::DecodeError
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless
      params.is_a?(Hash)

    script = Marty::Script.find_script(sname, version)

    return {error: "Can't find #{sname} version #{version}"} unless script

    engine = Marty::ScriptSet.get_engine(script)

    begin
      engine.evaluate_attrs(node, attrs, params)
    rescue => exc
      Delorean::Engine.grok_runtime_exception(exc)
    end
  end

end
