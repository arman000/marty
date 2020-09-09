# frozen_string_literal: true

module Marty
  module YmlConfig
    module Update
      NULL = [nil, 'TODO'].freeze

      module_function

      def resolve_value(value, default_value)
        value == false ? value : value || default_value
      end

      def call
        configs = Load.call.map do |k, v|
          Mock.call(k, v['default_value'], v['description'])
        end.index_by(&:key)

        # update existing configs
        Marty::Config.where(key: configs.keys, description: NULL).each do |c|
          yc = configs[c.key]
          c.update!(
            {
              description: yc.description,
              value: c.value == false ? c.value : c.value || yc.value
            }.compact
          )
        end

        # create configs that exist in yml and not db
        (configs.keys - Marty::Config.all.pluck(:key)).each do |k|
          c = configs[k]
          next if c.value.empty?

          Marty::Config.create!(
            key: k,
            value: c.value,
            description: c.description
          )
        end
      end
    end
  end
end
