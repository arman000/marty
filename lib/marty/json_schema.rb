require 'json-schema'

module Marty

  private
  class PgEnumAttribute < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, pro, validator, opt={})
      enum = nil
      begin
        enum = curr_schema.schema["pg_enum"].constantize
      rescue
        msg = "#{self.class.name} error: '#{data}' is not a pg_enum class"
        validation_error(pro, msg, frag, curr_schema, self, opt[:record_errors])
      end
      if !enum::VALUES.include?(data)
        msg = "#{self.class.name} error: '#{data}' not contained in #{enum}"
        validation_error(pro, msg, frag, curr_schema, self, opt[:record_errors])
      end
    end
  end

  class DateTimeFormat < JSON::Schema::FormatAttribute
    def self.validate(cur_sch, data, frag, pro, validator, opt={})
      begin
        DateTime.parse(data).in_time_zone(Rails.configuration.time_zone)
      rescue
        msg = "#{self.class.name} error: Can't parse '#{data}' into a DateTime"
        validation_error(pro, msg, frag, cur_sch, self, opt[:record_errors])
      end
    end
  end

  class JsonSchema < JSON::Schema::Draft4
    RAW_URI = "http://json-schema.org/marty-draft/schema#"

    def initialize
      super
      @attributes["pg_enum"] = PgEnumAttribute
      @formats["date-time"]  = DateTimeFormat
      @formats["date"]       = JSON::Schema::DateFormat
      @uri                   = JSON::Util::URI.parse(RAW_URI)
      @names                 = ["marty-draft", RAW_URI]
    end

    JSON::Validator.register_validator(self.new)
  end

end
