require 'spec_helper'

# used for testing controller inheritance
module Test
  module Diagnostic; end
end

module Marty::Diagnostic
  RSpec.describe Controller, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }

    def my_ip
      Node.my_ip
    end

    def git
      tag = `cd #{Rails.root}; git describe --tags --always --abbrev=7;`.strip
      git_datetime = `cd #{Rails.root}; git log -1 --format=%cd;`.strip

      "#{tag} (#{git_datetime})"
    rescue StandardError
      'Failed accessing git'
    end

    def consistent(key, description)
      {
        key => {
          'description' => description,
          'status' => true,
          'consistent' => true
        }
      }
    end

    describe 'GET #op' do
      it 'returns http success' do
        get :op, params: { format: :json, op: 'version' }
        expect(response).to have_http_status(:success)
      end

      it 'a request injects the request object into Diagnostic classes' do
        get :op, params: { format: :json, op: 'version' }
        expect(Reporter.request).not_to eq(nil)
      end

      it 'returns the current version JSON' do
        get :op, params: { format: :json, op: 'version', data: 'true' }

        # generate version data and declare all values consistent
        versions = Version.generate.each_with_object({}) do |(n, v), h|
          h[n] = v.each { |_t, r| r['consistent'] = true }
        end

        expected = {
          'data' => {
            'Version' => versions
          }
        }

        expect(assigns('result')).to eq(expected)
      end

      it 'returns the expected cummulative diagnostic' do
        expected = {
          'data' => {
            'Version' => {
              my_ip =>
              [
                consistent('Marty', Marty::VERSION),
                consistent('Delorean', Delorean::VERSION),
                consistent('Mcfly', Mcfly::VERSION),
                consistent('CM Shared', CmShared::VERSION),
                consistent('Rails', Rails.version),
                consistent('Netzke Core', Netzke::Core::VERSION),
                consistent('Netzke Basepack', Netzke::Basepack::VERSION),
                consistent(
                  'Ruby',
                  "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
                ),
                consistent('RubyGems', Gem::VERSION),
                consistent('Database Schema Version', Database.db_schema),
                consistent('Postgres', Database.db_version),
                consistent(
                  'Shared GitLab CI',
                  Marty::Diagnostic::Version.check_gitlab_ci.to_s
                ),
                consistent('Environment', Rails.env),
                consistent('Root Git', git),
              ].reduce({}, :merge)
            },
            'EnvironmentVariables' => {
              my_ip => {}
            },
            'Nodes' => {
              my_ip => consistent('Nodes', my_ip)
            }
          }
        }

        get :op, params: {
              format: :json,
              op: 'version, environment_variables, nodes',
              data: 'true'
            }

        diag_version_response = JSON.parse(response.body)
        expect(JSON.parse(response.body)).to eq(expected)
      end
    end

    describe 'Inheritance behavior' do
      it 'appends namespace to reporter and resolves in order of inheritance' do
        class Test::SomeController < Controller; end
        expect(Reporter.namespaces).to include('Test')

        class Test::Diagnostic::Version; end
        expect(Reporter.resolve_diagnostic('Version').name).
          to eq('Test::Diagnostic::Version')

        Reporter.namespaces.shift
      end
    end
  end
end
