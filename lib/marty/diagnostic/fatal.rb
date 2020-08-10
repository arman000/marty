module Marty::Diagnostic; class Fatal < Base
  def self.message(msg, opts = {})
    node = opts[:node] || Node.my_ip
    type = opts[:type] || 'RuntimeError'
    { name.demodulize => { node => { type => error(msg) } } }
  end
end
end
