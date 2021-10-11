module Marty
  module Diagnostic
    class Fatal < Base
      class << self
        def message(msg, opts = {})
          node = opts[:node] || Node.my_ip
          type = opts[:type] || 'RuntimeError'
          { name.demodulize => { node => { type => error(msg) } } }
        end
      end
    end
  end
end
