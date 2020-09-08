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
        yml_configs = Load.call
        yml_keys = yml_configs.keys.map(&:upcase)

        # update existing configs
        Marty::Config.where(key: yml_keys, description: NULL).each do |c|
          yc = yml_configs[c.key.downcase]
          c.update!(
            {
              description: yc.description,
              value: c.value == false ? c.value : c.value || yc.value
            }.compact
          )
        end

        # create configs that exist in yml and not db
        (yml_keys - Marty::Config.all.pluck(:key)).each do |k|
          config = yml_configs[k.downcase]
          next if config.value.empty?

          Marty::Config.create!(
            key: k,
            value: config.value,
            description: config.description
          )
        end
      end
    end
  end
end
