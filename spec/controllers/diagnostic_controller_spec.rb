require 'spec_helper'
module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    def git
      begin
        message = `cd #{Rails.root.to_s}; git describe --tags --always;`.strip
      rescue
        message = error("Failed accessing git")
      end
    end

    def version
      {
        "Marty"    => Marty::VERSION,
        "Delorean" => Delorean::VERSION,
        "Mcfly"    => Mcfly::VERSION,
        "Git"      => git,
      }
    end

    def environment
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      {'Environment'             => Rails.env,
       'Rails'                   => Rails.version,
       'Netzke Core'             => Netzke::Core::VERSION,
       'Netzke Basepack'         => Netzke::Basepack::VERSION,
       'Ruby'                    => rbv,
       'RubyGems'                => Gem::VERSION,
       'Database Adapter'        => described_class::Database.db_adapter_name,
       'Database Server'         => described_class::Database.db_server_name,
       'Database Version'        => described_class::Database.db_version,
       'Database Schema Version' => described_class::Database.db_schema}
    end

    def version_display
      <<-ERB
      <h3>Version</h3>
      <div class="wrapper">
        <table>
          <tr>
            <th colspan="2" scope="col">consistent</th>
          </tr>
          <tr>
            <th scope="row">Marty</th>
            <td class="overflow passed"><p>#{Marty::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th scope="row">Delorean</th>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th scope="row">Mcfly</th>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th scope="row">Git</th>
            <td class="overflow passed"><p>#{git}</p>
            </td>
          </tr>
        </table>
      </div>
      ERB
    end

    def version_display_fail val
      <<-ERB
      <h3>Version</h3>
      <h3 class="error">Issues Detected </h3>
      <div class="wrapper">
      <table>
         <tr>
            <th></th>
            <th scope="col">node1</th>
            <th scope="col">node2</th>
          </tr>
          <tr>
            <th scope="row">Marty</th>
            <td class="overflow passed"><p>#{Marty::VERSION}</p></td>
            <td class="overflow error"><p>#{val}</p></td>
          </tr>
          <tr>
            <th scope="row">Delorean</th>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p></td>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p></td>
          </tr>
          <tr>
            <th scope="row">Mcfly</th>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p></td>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p></td>
          </tr>
          <tr>
            <th scope="row">Git</th>
            <td class="overflow passed"><p>#{git}</p></td>
            <td class="overflow passed"><p>#{git}</p></td>
          </tr>
      </table>
      </div>
      ERB
    end

    def minimize(str)
      str.gsub(/\s+/, "")
    end

    describe 'GET #op' do
      it 'returns http success with local scope' do
        get :op, op: 'version', scope: 'local'
        expect(response).to have_http_status(:success)
      end

      it 'returns the current version JSON' do
        get :op, format: :json, op: 'version', scope: 'local'
        expect(assigns('result')).to eq(version)
      end

      it 'returns the correct environment JSON' do
        get :op, format: :json, op: 'environment', scope: 'local'
        expect(assigns('result')).to eq(environment)
      end

      it 'produces an html display of the diagnostic (version)' do
        test = described_class::Version.display({'stub' => version})
        expect(minimize(test)).to eq(minimize(version_display))
      end

      it 'masks consistent nodes for display (version)' do
        data = {'node1' => version, 'node2' => version}
        test = described_class::Version.display(data)
        expect(minimize(test)).to eq(minimize(version_display))
      end

      it 'displays all nodes when there is an inconsistent node (version)' do
        ver       = '0.0.0'
        data      = {'node1' => version, 'node2' => version + {'Marty' => ver}}
        expected  = version_display_fail(ver)
        test      = described_class::Version.display(data)
        expect(minimize(test)).to eq(minimize(expected))
      end
    end

    describe 'diagnostic classes and aggregate functions' do
      it 'has access to DiagnosticController request' do
        get :op, op: 'version', scope: 'local'
        expect(described_class::Base.request).not_to eq(nil)
      end

      it 'can aggregate diagnostics and return appropriate JSON' do
        # simulate open-uri nodal diag request
        uri_stub = {:open => nil, :readlines => [version.to_json]}
        nodes    = ['node1', 'node2', 'node3']
        expected = nodes.each_with_object({}){|n, h| h[n] = version}

        # mock nodes and diag request to node
        allow(described_class::Base.request).to receive(:port).and_return(3000)
        allow(described_class::Base).to receive(:get_nodes).and_return(nodes)
        allow(described_class::Base).to receive_message_chain(uri_stub)

        # perform aggregation using Base class function and Version class
        expect(described_class::Base.get_nodal_diags('version')).to eq(expected)
        expect(described_class::Version.aggregate).to eq(expected)
      end

      # returns true if there are differences in nodes for Base/Version
      it 'determines diff of aggregate diagnostic' do
        inconsistent = {'1' => version, '2' => version + {'Git' => '123'}}
        consistent = inconsistent + {'2' => version}
        aggregate_failures do
          expect(described_class::Base.diff(inconsistent)).to eq(true)
          expect(described_class::Base.diff(consistent)).to eq(false)
          expect(described_class::Version.diff(inconsistent)).to eq(true)
          expect(described_class::Version.diff(consistent)).to eq(false)
        end
      end

      it 'can detects errors in diagnostic' do
        error_free = version
        error_test = version + {'Git' => described_class::Base.
                                           error('Failed accessing git')}
        aggregate_failures do
          expect(described_class::Base.errors(error_free)).to eq(0)
          expect(described_class::Base.errors(error_test)).to eq(1)
          expect(described_class::Version.errors(error_free)).to eq(0)
          expect(described_class::Version.errors(error_test)).to eq(1)
        end
      end
    end
  end
end
