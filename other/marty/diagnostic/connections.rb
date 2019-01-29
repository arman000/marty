module Marty::Diagnostic; class Connections < Base
  self.aggregatable = false
  diagnostic_fn do
    conns = Node.get_postgres_connections[Database.db_name].
              sort_by{|h| [h['application_name'],
                           h['pid'],
                           h['client_addr'],
                           h['state']]
    }

    counts = Hash.new(0)
    conns.each_with_object({}) do |c, h|
      c['client_addr'] = 'localhost' unless c['client_addr']
      name = c['application_name']
      counts[name] += 1
      key = "#{name} #{'*' * (counts[name]-1)}"
      h[key] = c.except('application_name').map{|k,v| "<li>#{k}: #{v}</li>"}.join
    end
  end
end
end
