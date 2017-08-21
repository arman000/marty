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
  def get_schema(tag, sname, node, attr)
    begin
      Marty::ScriptSet.new(tag).get_engine(sname+'Schemas').
        evaluate(node, attr, {})
    rescue => e
      use_message = e.message == 'No such script' ?
                      'Schema not defined' : 'Problem with schema: ' + e.message
      raise "Schema error for #{sname}/#{node} attrs=#{attr}: #{use_message}"
    end
  end

  def massage_message(msg)
    m = %r|'#/([^']+)' of type ([^ ]+) matched the disallowed schema|.match(msg)
    return msg unless m
    "disallowed parameter '#{m[1]}' of type #{m[2]} was received"
  end

  def _get_errors(errs)
    if errs.is_a?(Array)
      errs.map { |err| _get_errors(err) }
    elsif errs.is_a?(Hash)
      if !errs.include?(:failed_attribute)
        errs.map { |k, v| _get_errors(v) }
      else
        fa, fragment, message, errors = errs.values_at(:failed_attribute,
                                                       :fragment,
                                                       :message, :errors)
        ((['AllOf','AnyOf','Not'].include?(fa) && fragment =='#/') ?
           [] : [massage_message(message)]) + _get_errors(errors || {})
      end
    end
  end

  def get_errors(errs)
    _get_errors(errs).flatten
  end

  def do_eval(sname, tag, node, attr, params, api_key, background)
    # FIXME: small patch to allow for single attr array
    attr = ActiveSupport::JSON.decode(attr) rescue attr

    return {error: "Malformed attrs"} unless
      attr.is_a?(String) || (attr.is_a?(Array) && attr.count == 1)

    # if attr is a single attr array, remember to return as an array
    if attr.is_a? Array
      attr = attr[0]
      ret_arr = true
    end

    start_time = Time.zone.now
    return {error: "Malformed attrs"} unless attr =~ /\A[a-z][a-zA-Z0-9_]*\z/
    return {error: "Bad params"} unless params.is_a?(String)

    begin
      params = ActiveSupport::JSON.decode(params)
      orig_params = params.duplicable? ? params.clone : params
    rescue JSON::ParserError => e
      return {error: "Malformed params"}
    end

    return {error: "Malformed params"} unless params.is_a?(Hash)
    need_log,
    need_input_validate,
    need_output_validate,
    need_strict_validate = Marty::ApiConfig.lookup(sname, node, attr)
    opt                  = {validate_schema:   true,
                            errors_as_objects: true,
                            version:           Marty::JsonSchema::RAW_URI }
    to_append            = {"\$schema" => Marty::JsonSchema::RAW_URI}
    validation_error     = nil

    if need_input_validate
      begin
        schema = get_schema(tag, sname, node, attr)
      rescue => e
        return {error: e.message}
      end
      begin
        er = JSON::Validator.
               fully_validate(schema.merge(to_append), params, opt)
      rescue NameError
        return {error: "Unrecognized PgEnum for attribute #{attr}"}
      rescue => ex
        return {error: "#{attr}: #{ex.message}"}
      end
      validation_error = get_errors(er) if er.size > 0
    end
    return {error: "Error(s) validating: #{validation_error}"} if
      validation_error

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
        result = engine.background_eval(node, params, attr)
        return retval = {"job_id" => result.__promise__.id}
      end

      res = engine.evaluate(node, attr, params)

      if need_output_validate && !(res.is_a?(Hash) && res['error'])
        begin
          schema = get_schema(tag, sname, node, attr + '_')
        rescue => e
          return {error: e.message}
        end

        begin
          er = JSON::Validator.fully_validate(schema.merge(to_append), res, opt)
        rescue NameError
          return {error: "Unrecognized PgEnum for attribute #{attr}"}
        rescue => ex
          return {error: "#{attr}: #{ex.message}"}
        end

        if er.size > 0
          errors = er.map{|e| e[:message]}
          Marty::Logger.error("API #{sname}:#{node}.#{attr}",
                              {error: errors, data: res})
          res = need_strict_validate ? {error: "Error(s) validating: #{errors}",
                                        data: res} : res
        end
      end
      return retval = ret_arr ? [res] : res
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc).symbolize_keys
      logger.info "Evaluation error: #{err_msg}"
      return retval = err_msg
    ensure
      error = Hash === retval ? retval[:error] : nil
      Marty::Log.write_log('api',
                           "#{sname} - #{node}",
                           {script:     sname,
                            node:       node,
                            attrs:       (ret_arr ? [attr] : attr),
                            input:      orig_params,
                            output:     error ? nil : retval,
                            start_time: start_time,
                            end_time:   Time.zone.now,
                            error:      error,
                            remote_ip:  request.remote_ip,
                            auth_name:  auth
                           }) if need_log.present?
    end
  end
end
