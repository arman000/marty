RSpec.describe Marty::Diagnostic::Controller, type: :controller do
  before(:each) { @routes = Marty::Engine.routes }

  delegate :my_ip, to: 'Marty::Diagnostic::Node'
  delegate :db_schema, to: 'Marty::Diagnostic::Database'
  delegate :db_version, to: 'Marty::Diagnostic::Database'

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

    it 'returns the current version JSON' do
      get :op, params: { format: :json, op: 'version', data: 'true' }

      # generate version data and declare all values consistent
      versions = Marty::Diagnostic::Version.
        generate.
        each_with_object({}) do |(n, v), h|
        h[n] = v.each { |_t, r| r['consistent'] = true }
      end

      expected = {
        'data' => {
          'Version' => versions
        }
      }

      expect(JSON.parse(response.body)).to eq(expected)
    end

    describe 'configurability' do
      before(:each) do
        report = Marty::Diagnostic::Report.create!(name: 'health')
        Marty::Diagnostic::Configuration.
          where(name: Marty::Diagnostic.diagnostics).
          update(report: report)

        Marty::Diagnostic::Configuration.
          where(name: 'Marty::Diagnostic::DelayedJobVersion').
          update(enabled: false)
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
                consistent('Rails', Rails.version),
                consistent('Netzke Core', Netzke::Core::VERSION),
                consistent('Netzke Basepack', Netzke::Basepack::VERSION),
                consistent(
                  'Ruby',
                  "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
                ),
                consistent('RubyGems', ::Gem::VERSION),
                consistent('Database Schema Version', db_schema),
                consistent('Postgres', db_version),
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

        diag_response = JSON.parse(response.body)
        expect(diag_response).to eq(expected)
      end

      it 'allows reports to define various diagnostics' do
        get :op, params: {
          format: :json,
          op: 'health',
          data: 'true'
        }

        diag_response = JSON.parse(response.body)
        expect(diag_response['data'].keys.sort).to eq(
          [
            'Connections',
            'DelayedJobWorkers',
            'EnvironmentVariables',
            'Nodes',
            'ObjectSizes',
            'ScheduledJobs',
            'ServerTimeAndTz',
            'Version'
          ]
        )
      end

      it 'allows reports to define various diagnostics if enabled' do
        Marty::Diagnostic::Configuration.
        find_by(name: 'Marty::Diagnostic::Nodes').
        update!(enabled: false)

        get :op, params: {
          format: :json,
          op: 'health',
          data: 'true'
        }

        diag_response = JSON.parse(response.body)
        expect(diag_response['data'].keys.sort).to eq(
          [
            'Connections',
            'DelayedJobWorkers',
            'EnvironmentVariables',
            'ObjectSizes',
            'ScheduledJobs',
            'ServerTimeAndTz',
            'Version'
          ]
        )
      end

      it 'forces failure if diagnotsic exceeds configured timeout' do
        Marty::Diagnostic::Configuration.
        find_by(name: 'Marty::Diagnostic::Nodes').
        update!(timeout: 1)

        allow(Marty::Diagnostic::Nodes).to receive(:generate).and_wrap_original do
          sleep(10)
        end

        get :op, params: {
          format: :json,
          op: 'nodes',
          data: 'true'
        }

        diag_response = JSON.parse(response.body)
        errors = diag_response.dig('errors', 'Fatal', my_ip.to_s)
        expect(errors.dig('Nodes', 'description')).to eq('execution expired')
      end
    end
  end
end
