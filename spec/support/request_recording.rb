# frozen_string_literal: true

module Marty
  module RSpec
    # This module handles request recording for RSpec suites in Marty-based
    # apps. It uses webmock to disable all incoming net communications,
    # and VCR to control recording incoming and outgoing requests conditionally.
    #
    # Once required. running +.enable_integration!+ and including
    # {Marty::RSpec::RequestRecording} in `RSpec` example groups (using
    # RSpec.config.include), then you should be good to go. All requests using
    # {::Net::HTTP} will be blocked by default and will haev to be generated
    # using +ENV['MARTY_RSPEC_RECORD'] = true+.
    module RequestRecording
      # Call this when setting up your RSpec suite to enable request blocking
      # and stubbing.
      def self.enable_integration!
        require 'uri'
        require 'vcr'
        require 'webdrivers/common'
        require 'webmock/rspec'

        enable_vcr_webmock_hook!
        configure_rspec_with_vcr!
      end

      # Configures VCR globally to hook into webmock and block requests.
      def self.enable_vcr_webmock_hook!
        ::VCR.configure do |config|
          config.cassette_library_dir = "#{::Rails.root}/spec/cassettes"
          config.hook_into :webmock
          config.ignore_localhost = true

          # ignore webdrivers http requests
          driver_hosts = Webdrivers::Common.subclasses.map do |d|
            URI(d.base_url).host
          end
          config.ignore_hosts(*driver_hosts)
        end
      end

      # Configures RSpec to use VCR. Sets it to record cassettes when
      # +ENV['MARTY_RSPEC_RECORD'] = true+ and otherwise gets the necessary
      # data for the cassette.
      def self.configure_rspec_with_vcr!
        ::RSpec.configure do |config|
          config.before do |example|
            mode = ENV['MARTY_RSPEC_RECORD'] == 'true' ? :all : :none
            name = cassette_name(example)
            delete_old_cassette(name) if mode == :all
            ::VCR.insert_cassette(
              cassette_name(example),
              record: mode,
              match_requests_on: [:method, :path]
            )
          end

          config.after do |example|
            ::VCR.eject_cassette(cassette_name(example))
          end
        end
      end

      # Returns name for a cassette based on a given RSpec example.
      #
      # @param example [RSpec::Core::Example] the example object passed in by RSpec.
      #
      # @return [String] The name of the cassette
      def cassette_name(example)
        file_name = File.basename(example.metadata[:file_path], '.rb')
        full_description = example.metadata[:example_group][:full_description]
        description = example.metadata[:description]
        tag = "#{full_description}_#{description}".
          underscore.
          gsub(/\s/, '_').
          gsub(/\(|\)/, '')

        "#{file_name}_#{tag}"
      end

      # Deletes a cassette based on a name.
      #
      # @param name [String] Name of the cassette.
      # @return [Boolean] whether the cassette was deleted or not
      def delete_old_cassette(name)
        root = ::Rails.root
        fn = "#{root}/spec/cassettes/#{name}.yml"

        if File.exist?(fn)
          File.delete(fn)
          true
        else
          false
        end
      end
    end
  end
end
