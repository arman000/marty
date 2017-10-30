require 'spec_helper'
module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    def version
      {"Git"      => "",
       "Marty"    => Marty::VERSION,
       "Delorean" => Delorean::VERSION,
       "Mcfly"    => Mcfly::VERSION}
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
    end

    describe 'diagnostic Base class' do
      it 'has access to DiagnosticController request' do
        get :op, op: 'version', scope: 'local'
        expect(described_class::Base.request).not_to eq(nil)
      end

      #it 'returns aggregate version JSON' do
      #  allow(Net::HTTP).to receive(:get_response).and_return ['127.0.0.1']
      #  described_class::Base.request.port = 3000
      #  described_class::Base.get_nodal_diags('version')
      #end

      # returns true if inconsistent or false if consistent
      it 'determines diff of aggregate diagnostic' do
        inconsistent = {'1' => version, '2' => version + {'Git' => '123'}}
        consistent = inconsistent + {'2' => version}
        aggregate_failures do
          expect(described_class::Base.diff(inconsistent)).to eq(true)
          expect(described_class::Base.diff(consistent)).to eq(false)
        end
      end

      it 'detects errors in diagnostic' do
        error_free = version
        error_test = version + {'Git' => described_class::Base.
                                           error('Failed accessing git')}
        aggregate_failures do
          expect(described_class::Base.errors(error_free)).to eq(0)
          expect(described_class::Base.errors(error_test)).to eq(1)
        end
      end
    end
  end
end
