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

  # FIXME: move to (probably) agrim's schema code in lib
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
    return {error: "Malformed attrs"} unless attrs.is_a?(String)

    attrs_atom = !attrs.start_with?('[')
    start_time = Time.zone.now

    if attrs_atom
      attrs = [attrs]
    else
      begin
        attrs = ActiveSupport::JSON.decode(attrs)
      rescue JSON::ParserError => e
        return {error: "Malformed attrs"}
      end
    end

    return {error: "Malformed attrs"} unless
      attrs.is_a?(Array) && attrs.all? {|x| x =~ /\A[a-z][a-zA-Z0-9_]*\z/}

    return {error: "Bad params"} unless params.is_a?(String)

    begin
      params = ActiveSupport::JSON.decode(params)
      orig_params = params.clone
    rescue JSON::ParserError => e
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless params.is_a?(Hash)

    need_validate, need_log = [], []
    Marty::ApiConfig.multi_lookup(sname, node, attrs).each do
      |attr, log, validate, id|
      need_validate << attr if validate
      need_log << id if log
    end

    validation_error = {}
    err_count = 0
    if need_validate.present?
      begin
        schemas = get_schemas(tag, sname, node, need_validate)
      rescue => e
        return {error: e.message}
      end
      opt = { :validate_schema    => true,
              :errors_as_objects  => true,
              :version            => Marty::JsonSchema::RAW_URI }
      to_append = {"\$schema" => Marty::JsonSchema::RAW_URI}
      schemas.each do |attr, sch|
        begin
          er = JSON::Validator.fully_validate(sch.merge(to_append), params, opt)
        rescue NameError
          return {error: "Unrecognized PgEnum for attribute #{attr}"}
        rescue => ex
          return {error: ex.message}
        end
        validation_error[attr] = er.map{ |e| e[:message] } if er.size > 0
        err_count += er.size
      end
    end
    return {error: "Error(s) validating: #{validation_error}"} if err_count > 0

    auth = Marty::ApiAuth.authorized?(sname, api_key)
    return {error: "Permission denied" } unless auth

    begin
      engine = Marty::ScriptSet.new(tag).get_engine(sname)
    rescue => e
      err_msg = "Can't get engine: #{sname || 'nil'} with tag: " +
                "#{tag || 'nil'}; message: #{e.message}"
      logger.info err_msg
      return {error: err_msg}
    end

    retval = nil

    begin
      if background
        result = engine.background_eval(node, params, attrs)
        return retval = {"job_id" => result.__promise__.id}
      end

      res = engine.evaluate_attrs(node, attrs, params)
      return retval = (attrs_atom ? res.first : res)
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc).symbolize_keys
      logger.info "Evaluation error: #{err_msg}"
      return retval = err_msg
    ensure
      error = Hash === retval ? retval[:error] : nil

      # FIXME: how do we know this isn't going to fail??
      Marty::ApiLog.create!(script:     sname,
                            node:       node,
                            attrs:      (attrs_atom ? attrs.first : attrs),
                            input:      orig_params,
                            output:     error ? nil : retval,
                            start_time: start_time,
                            end_time:   Time.zone.now,
                            error:      error,
                            remote_ip:  request.remote_ip,
                            auth_name:  auth,
                           ) if need_log.present?
    end
  end
end
