require 'marty/sql_servers'

module Marty
  module SqlServers
    RSpec.describe SERVERS do
      subject { :SERVERS }
      let(:servers_constant) { SqlServers.const_get(subject) }

      after do
        servers_defined = SqlServers.const_defined?(subject)
        SqlServers.send(:remove_const, subject) if servers_defined
        load 'marty/sql_servers/servers.rb'
      end

      context 'when `sql_servers.yml` is not defined' do
        it 'returns an empty hash' do
          expect(servers_constant).to eq({})
        end

        it 'logs to Rails.logger' do
          servers_constant
          expect(Rails.logger).to receive(:warn).with(
            'Could not load sql_servers.yml configuration file'
          )
        end
      end

      context 'with `sql_servers.yml` is defined' do
        let(:inline_sql_servers_yml) do
          <<~YAML
            ---
            .common: &common
              adapter: "activerecord-sqlserver-adapter"
              encoding: "<%= 'UTF-8' %>"
              reconnect: true

            shared: &shared
              override: "this will be overridden"
              example:
                <<: *common
                host: "<%= 'my_host' %>"
                database: "<%= 1 + 2 %>"
                username: "<%= 2 + 3 %>"
                password: "<%= 3 * 5 %>"

            test:
              override: "I'm overriding"
          YAML
        end

        let(:sample_sql_servers_yml_file) do
          Tempfile.open(['sql_servers', '.yml'], Rails.root.join('config')) do |tmpfile|
            tmpfile.write(inline_sql_servers_yml)
            tmpfile
          end
        end

        it 'can properly load the file with ERB & the right settings' do
          allow(Rails.application).to receive(:config_for).with(:sql_servers).
          and_wrap_original do |m, *_args|
            m.call(Pathname.new(sample_sql_servers_yml_file))
          end

          stub_const(
            "Marty::SqlServers::#{subject}",
            Rails.application.config_for(:sql_servers).with_indifferent_access
          )

          # Need to clear memoized to reload the reference to the redefined
          # constant
          clear_memoized
          expect(servers_constant).to include(
            'override' => "I'm overriding",
            'example' => {
              adapter: 'activerecord-sqlserver-adapter',
              encoding: 'UTF-8',
              reconnect: true,
              host: 'my_host',
              database: '3',
              username: '5',
              password: '15',
            }
          )
        end

        after do
          sample_sql_servers_yml_file.close
          sample_sql_servers_yml_file.unlink
        end
      end
    end
  end
end
