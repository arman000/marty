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
      result = engine.evaluate(node, attrs, {})
      attrs.zip(result)
    rescue => e
      use_message = e.message == 'No such script' ?
                    'Schema not defined' : 'Problem with schema: ' + e.message
      raise "Schema error for #{sname}/#{node} "\
            "attrs=#{attrs.join(',')}: #{use_message}"
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

    need_input_validate, need_output_validate, strict_validate, need_log =
                                                                [], [], [], []
    Marty::ApiConfig.multi_lookup(sname, node, attrs).each do
      |attr, log, input_validate, output_validate, strict, id|
      need_input_validate << attr if input_validate
      need_output_validate << attr + "_" if output_validate
      strict_validate << attr if strict
      need_log << id if log
    end

    opt = { :validate_schema    => true,
                :errors_as_objects  => true,
                :version            => Marty::JsonSchema::RAW_URI }
    to_append = {"\$schema" => Marty::JsonSchema::RAW_URI}

    validation_error = {}
    err_count = 0
    if need_input_validate.present?
      begin
        schemas = get_schemas(tag, sname, node, need_input_validate)
      rescue => e
        return {error: e.message}
      end
      schemas.each do |attr, sch|
        begin
          er = JSON::Validator.fully_validate(sch.merge(to_append), params, opt)
        rescue NameError
          return {error: "Unrecognized PgEnum for attribute #{attr}"}
        rescue => ex
          return {error: "#{attr}: #{ex.message}"}
        end

        validation_error[attr] = get_errors(er) if er.size > 0
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
      res = engine.evaluate(node, attrs, params)

      validation_error = {}
      err_count = 0
      if need_output_validate.present?
        begin
          schemas = get_schemas(tag, sname, node, need_output_validate)
        rescue => e
          return {error: e.message}
        end
        pairs = attrs.zip(res)
        pairs.zip(schemas).each do |(attr, res), (_, sch)|
          begin
            er = JSON::Validator.fully_validate(sch.merge(to_append), res, opt)
          rescue NameError
            return {error: "Unrecognized PgEnum for attribute #{attr}"}
          rescue => ex
            return {error: "#{attr}: #{ex.message}"}
          end
          validation_error[attr] = er.map{ |e| e[:message] } if er.size > 0
          err_count += er.size
        end
        if err_count > 0
          res = pairs.map do |attr, res|
            is_strict = strict_validate.include?(attr)
            the_error = validation_error[attr]

            Marty::Logger.error("API #{sname}:#{node}.#{attr}",
                                {error:  the_error,
                                 data: res}) if the_error
            is_strict && the_error ?
              {error: "Error(s) validating: #{the_error}",
               data: res} : res
          end
        end
      end

      return retval = (attrs_atom ? res.first : res)
    rescue => exc
      err_msg = Delorean::Engine.grok_runtime_exception(exc).symbolize_keys
      logger.info "Evaluation error: #{err_msg}"
      return retval = err_msg
    ensure
      error = Hash === retval ? retval[:error] : nil

      # FIXME: how do we know this isn't going to fail??
      end_time = Time.zone.now
      Marty::Log.create!(message_type: 'api',
                         message: "#{sname} - #{node}",
                         timestamp: end_time,
                         details:{script:     sname,
                                  node:       node,
                                  attrs:      (attrs_atom ? attrs.first : attrs),
                                  input:      orig_params,
                                  output:     error ? nil : retval,
                                  start_time: start_time,
                                  end_time:   end_time,
                                  error:      error,
                                  remote_ip:  request.remote_ip,
                                  auth_name:  auth
                                 }
                        ) if need_log.present?
    end
  end
end
