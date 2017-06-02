require 'json-schema'

module Marty

  private
  class PgEnumAttribute < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, processor, validator, options={})
      enum = curr_schema.schema["pg_enum"].constantize
      if !enum::VALUES.include?(data)
         msg = "#{self.class.name} error: '#{data}' not contained in #{enum}."
         validation_error( processor,
                           msg,
                           frag,
                           curr_schema,
                           self,
                           options[:record_errors])
      end
    end
  end

  class DateTimeFormatAttribute < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, processor, validator, options={})
      begin
        DateTime.parse(data).in_time_zone(Rails.configuration.time_zone)
      rescue
        msg = "#{self.class.name} error: Can't parse '#{data}' into a DateTime."
        validation_error( processor,
                          msg,
                          frag,
                          curr_schema,
                          self,
                          options[:record_errors])
      end
    end
  end

  class JsonSchema < JSON::Schema::Draft4
    def initialize
      super
      @attributes["pg_enum"] = PgEnumAttribute
      @attributes["datetime_format"] = DateTimeFormatAttribute
      @uri = JSON::Util::URI.parse("http://json-schema.org/marty-draft/schema#")
    end

    JSON::Validator.register_validator(self.new)
  end

end
