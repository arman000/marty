class Marty::Diagnostic::Reporter < Marty::Diagnostic::Request
  class_attribute :reports, :diagnostics

  self.reports = {}
  self.diagnostics = []

  def self.run request
    self.request = request

    ops = op.split(/,\s*/).uniq - [unresolve_diagnostic(self)]
    reps = ops.select{|o| reports.keys.include?(o)}

    self.diagnostics = ((ops - reps) + reps.map{|r| reports[r]}.flatten).uniq.
                         map{|d| resolve_diagnostic(d)}

    self.scope == 'local' ? generate : aggregate
  end

  private
  def self.resolve_diagnostic diag_name
    return diag_name.constantize unless diag_name.slice(name.deconstantize).nil?
    (name.deconstantize + '::' + diag_name.camelize).constantize
  end

  def self.unresolve_diagnostic klass
    klass.name.demodulize.underscore
  end

  def self.generate
    diagnostics.each_with_object({}){
      |d, h|
      begin
        h[d.name.demodulize] = d.generate
      rescue => e
        h.deep_merge!(Marty::Diagnostic::Fatal.message(e.message, type: d.name))
      end
    }
  end

  def self.aggregate
    data = consistency([generate, get_remote_diagnostics].reduce(:deep_merge))
    {'data' => data, 'errors' => errors(data)}
  end

  def self.consistency data
    data.each_with_object({}){
      |(klass, result), h|
      h[klass] = resolve_diagnostic(klass).apply_consistency(result)
    }
  end

  def self.errors data
    data.each_with_object({}){
      |(klass, result), new_data|
      new_data[klass] = result.each_with_object({}){
        |(node, diagnostic), new_result|
        new_result[node] = diagnostic.each_with_object({}){
          |(test, info), new_diagnostic|
          new_diagnostic[test] = info unless
            info['status'] && (scope == 'local' || info['consistent'])
        }
        new_result.delete(node) if new_result[node].empty?
      }
      new_data.delete(klass) if new_data[klass].empty?
    }
  end

  def self.displays result
    result.map{|d, r| resolve_diagnostic(d).display(r)}.sum
  end

  def self.get_remote_diagnostics
    ops = diagnostics.map{|d| unresolve_diagnostic(d) if d.aggregatable}.compact
    return {} if ops.empty?

    nodes = Marty::Diagnostic::Node.get_nodes - [Marty::Diagnostic::Node.my_ip]
    remote = nodes.sort.map do |n|
      Thread.new do
        uri = Addressable::URI.new(host: n, port: request.port)
        uri.scheme = ssl? ? 'https' : 'http'
        uri.path = '/marty/diag.json'
        uri.query_values = {
          scope: 'local',
          op: ops.join(','),
        }
        req = Net::HTTP.new(uri.host, uri.port)
        req.use_ssl = ssl?
        req.read_timeout = req.open_timeout = ENV['DIAG_TIMEOUT'] || 10
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE

        begin
          response = req.start {|http| http.get(uri.to_s)}
          next JSON.parse(response.body) if response.code == "200"

          Marty::Diagnostic::Fatal.message(response.body,
                                           type: response.message,
                                           node: uri.host)
        rescue => e
          Marty::Diagnostic::Fatal.message(e.message,
                                           type: e.class,
                                           node: uri.host)
        end
      end
    end

    remote.empty? ? {} : remote.map(&:join).map(&:value).reduce(:deep_merge)
  end
end
