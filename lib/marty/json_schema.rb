require 'json-schema'

module Marty
  private

  class PgEnumAttribute < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, pro, _validator, opt = {})
      values = nil
      path = '#/' + frag.join('/')
      begin
        cs = curr_schema.schema['pg_enum']
        enum = cs.constantize
        values = enum::VALUES
      rescue StandardError => e
        msg = "The property '#{path}': '#{cs}' is not a pg_enum class"
        validation_error(pro, msg, frag, curr_schema, self, opt[:record_errors])
      end
      if values && !values.include?(data)
        msg = "The property '#{path}' value '#{data}' not contained in #{enum}"
        validation_error(pro, msg, frag, curr_schema, self, opt[:record_errors])
      end
    end
  end

  class JsonSchema < JSON::Schema::Draft4
    RAW_URI = 'http://json-schema.org/marty-draft/schema#'

    def initialize
      super
      @attributes['pg_enum'] = PgEnumAttribute
      @formats['date-time']  = JSON::Schema::DateTimeFormat
      @formats['date']       = JSON::Schema::DateFormat
      @uri                   = JSON::Util::URI.parse(RAW_URI)
      @names                 = ['marty-draft', RAW_URI]
    end

    JSON::Validator.register_validator(new)

    def self.get_numbers(schema)
      numbers = []

      # traverse the schema, if we find a type: number, add to numbers []
      trav = lambda { |tree, key, path = []|
        return tree.each do |k, v|
          trav.call(v, k, path + [k])
        end if tree.is_a?(Hash)
        numbers << path[0..-2] if key == 'type' && tree == 'number'
      }
      trav.call(schema, nil, [])

      # convert the array stuff [ie. "items", "properties"] to :array
      numbers.map do |num|
        num.delete('properties')
        num.map { |n| n == 'items' ? :array : n }
      end
    end

    def self.fix_numbers(json, numbers)
      # follow path to drill into json
      drill = lambda { |tree, path|
        return unless tree

        key = path.first
        val = val = tree.send(:[], key) unless key == :array
        if key == :array
          # if we are at an array of numbers, fix them
          if path.length == 1
            tree.each_with_index do |v, i|
              tree[i] = v.to_f if v.is_a?(Numeric)
            end
          else
            # this is an array of object so continue to drill down
            tree.each { |sub| drill.call(sub, path[1..-1]) }
          end
        elsif path.length == 1
          # fix a non array field
          tree.send(:[]=, key, val.to_f) if val.is_a?(Numeric)
        else
          # continue drilling
          drill.call(val, path[1..-1])
        end
      }
      numbers.each { |number| drill.call(json, number) }
    end

    def self.get_schema(tag, sname, node, attr)
        Marty::ScriptSet.new(tag).get_engine(sname + 'Schemas').
          evaluate(node, attr, {})
    rescue StandardError => e
        id = "#{sname}/#{node} attrs=#{attr}"

        # the schema DL might not exist at all, or might not define the attr
        # being requested
        sch_not_found = ['No such script', "undefined method `#{attr}__D'",
                         "node #{node} is undefined"]
        msg = sch_not_found.detect { |msg| e.message.starts_with?(msg) } ?
                'Schema not defined' : "Problem with schema: #{e.message}"
        "Schema error for #{id}: #{msg}"
    end
  end
end
