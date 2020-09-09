# frozen_string_literal: true

module Marty
  module YmlConfig
    module Mock

      module_function

      def call(key, value = nil, description = nil)
        OpenStruct.new(
          key: key,
          value: value.as_json || [],
          description: description
        )
      end
    end
  end
end
