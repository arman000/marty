class Marty::Api::Base
  mattr_accessor :class_list
  @@class_list ||= [name].to_set

  def self.inherited(klass)
    @@class_list << klass.to_s
    super
  end

  def self.respond_to controller
    result = yield
    controller.respond_to do |format|
      format.json { controller.send_data result.to_json }
      format.csv  {
        # SEMI-HACKY: strip outer list if there's only one element.
        result = result[0] if result.is_a?(Array) && result.length==1
        controller.send_data Marty::DataExporter.to_csv(result)
      }
    end
  end

  # api handles
  def self.engine_params_filter
    ['password']
  end

  def self.process_params params
    params
  end

  def self.before_evaluate api_params
  end

  def self.after_evaluate api_params, result
  end

  @@numbers = {}
  @@schemas = {}

  def self.is_authorized? params
    is_secured = Marty::ApiAuth.where(
      script_name: params[:script],
      obsoleted_dt: 'infinity'
    ).exists?

    !is_secured || Marty::ApiAuth.where(
      api_key:       params[:api_key],
      script_name:   params[:script],
      obsoleted_dt: 'infinity'
    ).pluck(:app_name).first
  end

  def self.evaluate params, request, config
    # prevent script evaluation from modifying passed in params
    params = params.deep_dup

    schema_key = [params[:tag], params[:script], params[:node], params[:attr]]
    input_schema = nil
    begin
      # get_schema will either return a hash with the schema,
      # or a string with the error
      input_schema = @@schemas[schema_key] ||=
                     Marty::JsonSchema.get_schema(*schema_key)
    rescue => e
      return {error: e.message}
    end

    # validate input schema
    if config[:input_validated]

      # must fail if schema not found or some other error
      return {"error": input_schema} if input_schema.is_a?(String)

      begin
        res = SchemaValidator::validate_schema(input_schema, params[:params])
      rescue NameError
        return {error: "Unrecognized PgEnum for attribute #{params[:attr]}"}
      rescue => e
        return {error: "#{params[:attr]}: #{e.message}"}
      end

      schema_errors = SchemaValidator::get_errors(res) unless res.empty?
      return {error: "Error(s) validating: #{schema_errors}"} if
        schema_errors
    end

    # if schema was found
    if input_schema.is_a?(Hash)
      # fix numbers types
      numbers = @@numbers[schema_key] ||=
                Marty::JsonSchema.get_numbers(input_schema)

      # modify params in place
      Marty::JsonSchema.fix_numbers(params[:params], numbers)
    elsif !input_schema.include?("Schema not defined")
      # else if some error besides schema not defined, fail
      return {error: input_schema}
    end

    # get script engine
    begin
      engine = Marty::ScriptSet.new(params[:tag]).get_engine(params[:script])
    rescue => e
      error = "Can't get engine: #{params[:script] || 'nil'} with tag: " +
                "#{params[:tag] || 'nil'}; message: #{e.message}"
      Marty::Logger.info error
      return {error: error}
    end

    retval = nil

    # evaluate script
    begin
      if params[:background]
        res = engine.background_eval(params[:node],
                                     params[:params],
                                     params[:attr])

        return retval = {"job_id" => res.__promise__.id}
      end

      res = engine.evaluate(params[:node],
                            params[:attr],
                            params[:params])

      # validate output schema
      if config[:output_validated] && !(res.is_a?(Hash) && res['error'])
        begin
          output_schema_params = params + {attr: params[:attr] + '_'}
          schema = SchemaValidator::get_schema(output_schema_params)
        rescue => e
          return {error: e.message}
        end

        begin
          schema_errors = SchemaValidator::validate_schema(schema, res)
        rescue NameError
          return {error: "Unrecognized PgEnum for attribute #{attr}"}
        rescue => e
          return {error: "#{attr}: #{e.message}"}
        end

        if schema_errors.present?
          errors = schema_errors.map{|e| e[:message]}

          Marty::Logger.error(
            "API #{params[:script]}:#{params[:node]}.#{params[:attr]}",
            {error: errors, data: res}
          )

          msg = "Error(s) validating: #{errors}"
          res = config[:strict_validate] ? {error: msg ,data: res} : res
        end
      end

      # if attr is an array, return result as an array
      return retval = params[:return_array] ? [res] : res

    rescue => e
      msg = Delorean::Engine.grok_runtime_exception(e).symbolize_keys
      Marty::Logger.info "Evaluation error: #{msg}"
      return retval = msg
    ensure
      error = Hash === retval ? retval[:error] : nil
    end
  end

  def self.filter_hash hash, filter_params
    pf = ActionDispatch::Http::ParameterFilter.new(filter_params)
    pf.filter(hash)
  end

  def self.log result, params, request
    ret_arr = params[:return_array]
    input   = filter_hash(params[:params], engine_params_filter)

    Marty::Log.write_log('api',
                         params.values_at(:script, :node, :attr).join(' - '),
                         {script:     params[:script],
                          node:       params[:node],
                          attrs:      ret_arr ? [params[:attr]] : params[:attr],
                          input:      input,
                          output:     (result.is_a?(Hash) &&
                                       result.include?('error')) ? nil : result,
                          start_time: params[:start_time],
                          end_time:   Time.zone.now,
                          error:      (result.is_a?(Hash) &&
                                       result.include?('error')) ? result : nil,
                          remote_ip:  request.remote_ip,
                          auth_name:  params[:auth]
                         })
  end

  class SchemaValidator
    def self.get_schema params
      begin
        Marty::ScriptSet.new(params[:tag]).get_engine(params[:script]+'Schemas').
          evaluate(params[:node], params[:attr], {})
      rescue => e
        msg = e.message == 'No such script' ? 'Schema not defined' :
                'Problem with schema: ' + e.message

        raise "Schema error for #{params[:script]}/#{params[:node]} "\
              "attrs=#{params[:attr]}: #{msg}"
      end
    end

    def self.validate_schema schema, hash
      JSON::Validator.fully_validate(
        schema.merge({"\$schema" => Marty::JsonSchema::RAW_URI}),
        hash,
        validate_schema:   true,
        errors_as_objects: true,
        version:           Marty::JsonSchema::RAW_URI,
      )
    end

    def self.massage_message(msg)
      m = %r|'#/([^']+)' of type ([^ ]+) matched the disallowed schema|.
            match(msg)

      return msg unless m
      "disallowed parameter '#{m[1]}' of type #{m[2]} was received"
    end

    def self._get_errors(errs)
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

    def self.get_errors(errs)
      _get_errors(errs).flatten
    end
  end
end
