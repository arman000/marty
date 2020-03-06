module Marty
  class DeloreanBackgroundJob < ::Marty::CronJob
    def perform(script, node, attribute)
      engine = Marty::ScriptSet.new.get_engine(script)
      engine.evaluate(node, attribute, {})
    end
  end
end
