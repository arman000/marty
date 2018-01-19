require 'spec_helper'

# used for testing controller inheritance
module Test
  module Diagnostic; end
end

module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    def my_ip
      Diagnostic::Node.my_ip
    end

    def git
      `cd #{Rails.root.to_s}; git describe --tags --always;`.
        strip rescue "Failed accessing git"
    end

    describe 'GET #op' do
      it 'returns http success' do
        get :op, format: :json, op: 'version'
        expect(response).to have_http_status(:success)
      end

      it 'a request injects the request object into Diagnostic classes' do
        get :op, format: :json, op: 'version'
        expect(Diagnostic::Reporter.request).not_to eq(nil)
      end

      it 'returns the current version JSON' do
        get :op, format: :json, op: 'version', data: 'true'

        # generate version data and declare all values consistent
        versions = Diagnostic::Version.generate.each_with_object({}){
          |(n, v),h|
          h[n] = v.each{|t, r| r['consistent'] = true}
        }

        expected = {
          'data' => {
            'Version' => versions
          }
        }

        expect(assigns('result')).to eq(expected)
      end

      it 'returns the expected cummulative diagnostic' do
        expected = {
          "data" => {
            "Version" => {
              my_ip => {
                "Marty" => {
                  "description" => Marty::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Delorean" => {
                  "description" => Delorean::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Mcfly" => {
                  "description" => Mcfly::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Git" => {
                  "description" => git,
                  "status"      => true,
                  "consistent"  => true
                },
                "Rails" => {
                  "description" => Rails.version,
                  "status"      => true,
                  "consistent"  => true
                },
                "Netzke Core" => {
                  "description" => Netzke::Core::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Netzke Basepack" => {
                  "description" => Netzke::Basepack::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Ruby" => {
                  "description" => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} "\
                                   "(#{RUBY_PLATFORM})",
                  "status"      => true,
                  "consistent"  => true
                },
                "RubyGems" => {
                  "description" => Gem::VERSION,
                  "status"      => true,
                  "consistent"  => true
                },
                "Database Schema Version" => {
                  "description" => Diagnostic::Database.db_schema,
                  "status"      => true,
                  "consistent"  => true
                },
                "Environment" => {
                  "description" => Rails.env,
                  "status"      => true,
                  "consistent"  => true
                }
              }
            },
            "EnvironmentVariables" => {
              my_ip => {
              }
            },
            "Nodes" => {
              my_ip => {
                "Nodes"=> {
                  "description" => my_ip,
                  "status"      => true,
                  "consistent"  => true
                }
              }
            }
          }
        }

        get :op,
            format: :json,
            op: 'version, environment_variables, nodes',
            data: 'true'

        expect(JSON.parse(response.body)).to eq(expected)
      end
    end

    describe 'Inheritance behavior' do
      it 'appends namespace to reporter and resolves in order of inheritance' do
        class Test::SomeController < DiagnosticController; end
        expect(Diagnostic::Reporter.namespaces).to include('Test')

        class Test::Diagnostic::Version; end
        expect(Diagnostic::Reporter.resolve_diagnostic('Version').name).
          to include('Test')

        Diagnostic::Reporter.namespaces.shift
      end
    end
  end
end
