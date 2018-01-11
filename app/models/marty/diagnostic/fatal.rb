class Marty::Diagnostic::Fatal < Marty::Diagnostic::Base
  def self.display_alert_message
    '<h3 class="error">Something went wrong.</br>'\
    'Consistency is checked between remaining nodes if applicable.</h3>'
  end

  def self.message msg, opts = {}
    node = opts[:node] || Marty::Diagnostic::Node.my_ip
    type = opts[:type] || 'RuntimeError'
    {name.demodulize => {node => {type => error(msg)}}}
  end
end
