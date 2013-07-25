require 'delorean_lang'

module Marty
  class ScriptContainer < Delorean::AbstractContainer
    def get_engine(name, version)
      script = Marty::Script.find_script(name, version)

      raise "Can't find #{name} version #{version} for import." unless script

      Marty::ScriptSet.get_engine(script, self)
    end
  end
end
