class Marty::RpcController < ActionController::Base
  def evaluate
    start_time = Time.zone.now
    reshash = do_eval(params["script"],
                  params["tag"],
                  params["node"],
                  params["attrs"] || "[]",
                  params["params"] || "{}",
                  params["api_key"] || nil,
                  params["background"],
                  )
    end_time = Time.zone.now

    error = reshash[:error]
    logattrs = reshash.delete(:log)
    auth = reshash.delete(:auth)
    params_h = reshash.delete(:params)
    ip = request.remote_ip
    res = reshash[:result] || reshash

    Marty::ApiLog.create!(script: params["script"],
                          node:   params["node"],
                          attrs:  params["attrs"],
                          input:  params_h,
                          output: !error && res || nil,
                          start_time: start_time,
                          end_time: end_time,
                          error: error,
                          remote_ip: ip,
                          auth_name: auth) if logattrs.present?
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

  #move to (probably) agrim's schema code in lib
  def get_schemas(tag, sname, node, attrs)
    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname+'Schemas')
      result = engine.evaluate_attrs(node, attrs, {})
      attrs.zip(result)
    rescue => e
      use_message = e.message == 'No such script' ?
                      'Schema not defined' : 'Problem with schema'
      raise "Schema error for #{sname}/#{node} "\
            "attrs=#{attrs.join(',')}: #{use_message}"
    end
  end

  def do_eval(sname, tag, node, attrs, params, api_key, background)
    err = "Marty::RpcController#do_eval,"

    attrs_err = nil
    lookup_attrs = nil
    begin
      unless attrs.is_a?(String)
        logger.info "#{err} Bad attrs (must be a string): <#{attrs.inspect}>"
        raise "Bad attrs"
      end

      attrs_atom = false
      if attrs.match(/\A\s*[a-z][a-zA-Z0-9_]*\s*\z/)
        attrs = [attrs]
        attrs_atom = true
      else
        begin
          attrs = ActiveSupport::JSON.decode(attrs)
        rescue JSON::ParserError => e
          logger.info "#{err} Malformed attrs (json): #{attrs.inspect}, #{e.message}"
          raise "Malformed attrs"
        end
      end

      unless attrs.is_a?(Array) && attrs.all? {|x| x.is_a? String}
        logger.info "#{err} Malformed attrs (not string array): <#{attrs.inspect}>"
        raise "Malformed attrs"
      end
      lookup_attrs = attrs
    rescue => e
      attrs_err = e.message
    ensure
      configs = Marty::ApiConfig.multi_lookup(sname, node, lookup_attrs)
      need_validate = []
      need_log = []
      configs.each do |attr, log, validate, id|
        need_validate << attr if validate
        need_log << id if log
      end

      return_hash = { log: need_log }
    end

    return return_hash + { error: attrs_err } if attrs_err

    unless params.is_a?(String)
      logger.info "#{err} Bad params (must be a string): <#{params.inspect}>"
      return return_hash + {error: "Bad params"}
    end

    begin
      params = ActiveSupport::JSON.decode(params)
    rescue JSON::ParserError => e
      logger.info "#{err} Malformed params (json): <#{params.inspect}>, #{e.message}"
      return return_hash + {error: "Malformed params"}
    end

    unless params.is_a?(Hash)
      logger.info "#{err} Malformed params (not hash): <#{params.inspect}>"
      return return_hash + {error: "Malformed params"}
    end
    return_hash += { params: params.clone }
    auth = Marty::ApiAuth.authorized?(sname, api_key)
    return_hash += { auth: auth } if auth.is_a?(String)
    unless auth
      logger.info "#{err} permission denied"
      return return_hash + {error: "Permission denied" }
    end

    validation_error = nil
    if need_validate.present?
      begin
        schemas = get_schemas(tag, sname, node, need_validate)
      rescue => e
        return return_hash + {error: e.message}
      end
      schemas.each do |attr, schema|
        # JSON::Validator.fully_validate(schema, params)
        # set validation_error if any schemas had error.. should be string
      end
    end

    return return_hash + {error: "Error(s) validating: #{validation_error}"} if
                          validation_error

    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname)
    rescue => e
      err_msg = "Can't get engine: #{sname || 'nil'} with tag: " +
              "#{tag || 'nil'}; message: #{e.message}"
      logger.info "#{err} #{err_msg}"
      return return_hash + {error: err_msg}
    end

    begin
      if background
        result = engine.background_eval(node, params, attrs)
        return_hash + { "job_id" => result.__promise__.id,
        }
      else
        res = engine.evaluate_attrs(node, attrs, params)
        return_hash + { result: (attrs_atom ? res.first : res) }
      end
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc)
      logger.info "#{err} Evaluation error: #{err_msg}"
      err_msg
    end
  end
end
