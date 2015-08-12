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
    return {error: "Bad attrs"} unless attrs.is_a?(String)

    begin
      attrs = ActiveSupport::JSON.decode(attrs)
    rescue MultiJson::DecodeError
      return {error: "Malformed attrs"}
    end

    return {error: "Malformed attrs"} unless
      attrs.is_a?(Array) && attrs.all? {|x| x.is_a? String}

    return {error: "Bad params"} unless params.is_a?(String)

    begin
      params = ActiveSupport::JSON.decode(params)
    rescue MultiJson::DecodeError
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless params.is_a?(Hash)

    return {error: "Permission denied" } unless
      Marty::ApiAuth.authorized?(sname, api_key)

    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname)
    rescue => e
      return {error: "Can't get engine: #{sname || 'nil'} with tag: " +
              "#{tag || 'nil'}; error: #{e.message}"}
    end

    begin
      engine.evaluate_attrs(node, attrs, params)
    rescue => exc
      Delorean::Engine.grok_runtime_exception(exc)
    end
  end
end
