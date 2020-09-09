# frozen_string_literal: true

module Marty
  module Configs
    module UpdateFromYml
      NULL = [nil, 'TODO'].freeze

      module_function

      def call
        configs = LoadYml.call

        # update existing config description with yml value
        Marty::Config.where(key: configs.keys, description: NULL).each do |c|
          desc = configs[c.key].description
          c.update!(description: desc) if desc
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
