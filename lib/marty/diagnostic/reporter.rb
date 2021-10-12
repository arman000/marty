module Marty
  module Diagnostic
    class Reporter
      mattr_accessor :namespaces, default: ['Marty']
      mattr_accessor :diagnostic_map, default: {}

      attr_accessor :result, :op, :scope, :diagnostics

      class << self
        def consistency(data)
          data.each_with_object({}) do |(klass, result), h|
            h[klass] = resolve_diagnostic(klass).apply_consistency(result)
          end
        end

        def errors(data, scope = nil)
          data.each_with_object({}) do |(klass, result), new_data|
            new_data[klass] = result.each_with_object({}) do |(node, diagnostic), new_result|
              new_result[node] = diagnostic.each_with_object({}) do |(test, info), new_diagnostic|
                new_diagnostic[test] = info unless
                  info['status'] && (scope == 'local' || info['consistent'])
              end
              new_result.delete(node) if new_result[node].empty?
            end
            new_data.delete(klass) if new_data[klass].empty?
          end
        end

        def remote_diagnostics(diagnostics, ssl = false)
          ops = diagnostics.map { |d| unresolve_diagnostic(d) if d.aggregatable }.compact
          return {} if ops.empty?

          nodes = Node.get_nodes - [Node.my_ip]
          remote = nodes.sort.map do |n|
            Thread.new do
              uri = Addressable::URI.new(host: n, port: ssl ? 443 : 80)
              uri.scheme = ssl ? 'https' : 'http'
              uri.path = '/marty/diag.json'
              uri.query_values = {
                scope: 'local',
                op: ops.join(','),
              }
              req = Net::HTTP.new(uri.host, uri.port)
              req.use_ssl = ssl
              req.read_timeout = req.open_timeout = Rails.application.config.marty.diagnostic_remote_timeout
              req.verify_mode = OpenSSL::SSL::VERIFY_NONE

              begin
                response = req.start { |http| http.get(uri.to_s) }
                next JSON.parse(response.body) if response.code == '200'

                Fatal.message(response.body, type: response.message, node: uri.host)
              rescue StandardError => e
                Fatal.message(e.message, type: e.class, node: uri.host)
              end
            end
          end

          remote.empty? ? {} : remote.map(&:join).map(&:value).reduce(:deep_merge)
        end

        def render_diagnostics(data)
          data.map { |d, r| resolve_diagnostic(d).render(r) }.reduce(&:+)
        end

        def report_diagnostics(reports)
          Marty::Diagnostic::Report.includes(:configurations).
            where(name: reports).where(
              marty_diagnostic_configurations: { enabled: true }
            ).each_with_object({}) { |r, h| h[r.name] = r.configurations }
        end

        def resolve_diagnostic(diag_name)
          diag_name = diag_name.camelize
          return diagnostic_map[diag_name] if diagnostic_map[diag_name]

          klass = nil
          namespaces.each do |n|
            klass = (n + '::Diagnostic::' + diag_name).constantize rescue nil
            break if klass
          end
          raise NameError, "#{diag_name} could not be resolved by #{name}" if
            klass.nil?

          diagnostic_map[diag_name] = klass
        end

        def unresolve_diagnostic(klass)
          diagnostic_map[klass] || klass.name.demodulize.underscore
        end
      end

      def initialize(params = {}, ssl = false)
        @ssl = ssl
        @op = params['op']
        @scope = params['scope']
        @data_flag = params['data'] == 'true'
        @diagnostics = []
        @result = nil
      end

      def run
        ops = @op&.split(/,\s*/)&.uniq || []
        report_diags = self.class.report_diagnostics(ops)
        diag_ops = ops - report_diags.keys
        diag_names = diag_ops.map { |name| self.class.resolve_diagnostic(name).name }
        @diagnostics = (
          report_diags.values.flatten +
          Configuration.where(name: diag_names, enabled: true)
        ).uniq

        @result = @scope == 'local' ? generate : aggregate
      end

      def display
        local  = @scope == 'local'
        data   = local ? @result : @result['data']
        {
          'html' => self.class.render_diagnostics(data),
          'errors' => local ? self.class.errors(data, @scope) : @result['errors']
        }
      end

      def return_data?
        @data_flag == true
      end

      def errors?
        @result['errors']&.present?
      end

      private

      def aggregate
        data = self.class.consistency(
          [
            generate,
            self.class.remote_diagnostics(@diagnostics, @ssl)
          ].reduce(:deep_merge)
        )
        { 'data' => data, 'errors' => self.class.errors(data) }
      end

      def generate
        diagnostics.each_with_object({}) do |config, response|
          begin
            key = config.diagnostic.name.demodulize
            response[key] = transaction_with_timeout(config.timeout) { config.generate }
          rescue StandardError => e
            response.deep_merge!(Fatal.message(e.message, type: key))
          end
        end
      end

      # limits ruby code and query execution time
      def transaction_with_timeout(timeout)
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute(
            "SET LOCAL statement_timeout = '#{timeout}s'"
          )
          Timeout.timeout(timeout) do
            yield if block_given?
          end
        end
      end
    end
  end
end
