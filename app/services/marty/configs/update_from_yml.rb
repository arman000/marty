# frozen_string_literal: true

module Marty
  module Configs
    module UpdateFromYml
      NULL = [nil, 'TODO'].freeze

      module_function

      def resolve_value(value, default_value)
        value == false ? value : value || default_value
      end

      def call
        configs = LoadYml.call

        # update existing configs
        Marty::Config.where(key: configs.keys, description: NULL).each do |c|
          yc = configs[c.key]

          value = if c.value == [false]
                    c.value
                  else
                    (c.value.present? && c.value) || yc.value
                  end

          c.update!(
            { description: yc.description,
              value: value.as_json }.compact
          )
        end

        # create configs that exist in yml and not db
        (configs.keys - Marty::Config.all.pluck(:key)).each do |k|
          c = configs[k]
          next if c.value.empty?

          Marty::Config.create!(
            key: k,
            value: c.value.as_json,
            description: c.description
          )
        end
      end
    end
  end
end
