module Marty
  module Diagnostic
    class Base
      extend Packer
      include ActionView::Helpers::TextHelper

      EXCLUDE_ON_INHERITANCE = [
        'Marty::Diagnostic::Collection',
        'Marty::Diagnostic::Fatal'
      ].freeze

      # all diagnostics have `aggregatable` set to true.
      # aggregatable indicates to the reporting mechanism that a diagnostic
      # should be aggregated  as these types of diagnostics are
      # aggregated differently (or not at all).
      class_attribute :aggregatable, :status_only

      @@read_only = Marty::Util.db_in_recovery?
      @@template  = ActionController::Base.new.lookup_context.
                      find_template('marty/diagnostic/diag').
                      identifier

      class << self
        # register diagnostic on inheritance
        #
        # FIXME: Collection and Fatal are similar to Base, but should not
        # directly inherit from Base as the classes will be picked up on
        # registration. We need to decompose Base into separate module/classes.
        def inherited(klass)
          Marty::Diagnostic.diagnostics.add(klass.name) unless EXCLUDE_ON_INHERITANCE.member?(klass.name)

          super
        end

        def diagnostic_fn(opts = {})
          opts.each do |k, v|
            send("#{k}=", v)
          end
          class << self
            define_method :generate do
              pack do
                yield
              end
            end
          end
        end

        def fatal?
          name.include?('Fatal')
        end

        def process_status_only(infos)
          return infos unless status_only

          infos.map { |info| info.map { |test, result| [test, result['status']] }.to_h }
        end

        def get_difference(data)
          values = process_status_only(data.values)
          Marty::DataExporter.hash_array_merge(values, true).map do |test, values|
            test if values.uniq.count > 1
          end.compact
        end

        def apply_consistency(data)
          diff = get_difference(data)
          data.each_with_object({}) do |(node, diagnostic), new_data|
            new_data[node] = diagnostic.each_with_object({}) do |(test, info), new_diagnostic|
              new_diagnostic[test] = info + { 'consistent' => !diff.include?(test) }
            end
          end
        end

        def consistent?(data)
          process_status_only(data.values).uniq.count == 1
        end

        def render(data)
          consistent = consistent?(data)
          success    = consistent && !fatal?
          ERB.new(File.open(@@template).read).result(binding)
        end

        def render_info_css(info)
          return 'inconsistent' if info.nil? || (info['status'] &&
                                                info['consistent'] == false)
          return 'error' unless info['status']

          'passed'
        end

        def render_info_description(info)
          new.simple_format(info ? info['description'] : 'N/A')
        end
      end

      diagnostic_fn aggregatable: true, status_only: false do
        raise "generate has not been defined for #{name}"
      end
    end
  end
end
