# frozen_string_literal: true

require_relative 'request_recording/callbacks'

module Marty
  module RSpec
    # This module handles request recording for RSpec suites in Marty-based
    # apps. It uses webmock to disable all incoming net communications,
    # and VCR to control recording incoming and outgoing requests conditionally.
    #
    # By default, requiring this file enables all necessary RSpec and VCR
    # integration, so it works out of the box.
    #
    # All requests using {::Net::HTTP} will be blocked by default and will have
    # to be generated using +ENV[{RECORD_ENV_FLAG_NAME}] = true+.
    module RequestRecording
      CASSETTE_HOME = Rails.root.join('spec/cassettes')

      # The pre-configured environment variable name to enable for recording
      RECORD_ENV_FLAG_NAME = 'MARTY_RSPEC_RECORD'

      # Call this when setting up your RSpec suite to enable request blocking
      # and stubbing.
      def self.enable_integration!
        require 'uri'
        require 'vcr'
        require 'webdrivers/common'
        require 'webmock/rspec'

        # Disable any Net::HTTP requests
        # Doesn't block connections not using Net::HTTP (like database)
        WebMock.disable_net_connect! unless recording?

        enable_vcr_webmock_hook!
        configure_rspec_with_vcr!
      end

      # @return [Boolean] whether or not recording is globally enabled.
      def self.recording?
        ENV[RECORD_ENV_FLAG_NAME] == 'true'
      end

      # Configures VCR globally to hook into webmock and block requests.
      def self.enable_vcr_webmock_hook!
        ::VCR.configure do |config|
          config.cassette_library_dir = CASSETTE_HOME
          config.hook_into :webmock
          config.ignore_localhost = true
          config.default_cassette_options = {
            record: recording? ? :all : :none,
            match_requests_on: [:method, :path]
          }

          # ignore webdrivers http requests
          driver_hosts = ::Webdrivers::Common.subclasses.map do |d|
            URI(d.base_url).host
          end
          config.ignore_hosts(*driver_hosts)
        end
      end
      private_class_method :enable_vcr_webmock_hook!

      # Configures RSpec to use VCR. Sets it to record cassettes when
      # +.recording?+ is true and otherwise gets the necessary
      # data for the cassette.
      # It also defines the `recording` setting for RSpec, which can be
      # used globally across all tests.
      def self.configure_rspec_with_vcr!
        ::RSpec.configure do |config|
          config.add_setting :recording, default: recording?
          config.include Marty::RSpec::RequestRecording
          config.around(:example, &Callbacks.insert_cassette)
        end
      end
      private_class_method :configure_rspec_with_vcr!

      # Returns name for a cassette based on a given RSpec example.
      #
      # @param example [RSpec::Core::Example] the example object passed in by RSpec.
      # @return [String] The name of the cassette
      def self.cassette_name(example)
        # return the cassette_name specified on the example metadata
        # example:
        # it "some test", vcr: { cassette_name: 'my_cassette' } do
        #   expect(...)
        # end
        cassette_name = example.metadata.dig(:vcr, :cassette_name)
        return cassette_name if cassette_name.present?

        file_name = File.basename(example.metadata[:file_path], '.rb')
        full_description = example.metadata[:example_group][:full_description]
        description = example.metadata[:description]
        tag = "#{full_description}_#{description}".
          underscore.
          gsub(/\s/, '_').
          gsub(/\(|\)/, '')

        "#{file_name}_#{tag}"
      end

      # Deletes a cassette based on a name. Required because VCR complains
      # that a cassette already exists when trying to overwrite, even in
      # +record: :none+ mode.
      #
      # @param name [String] Name of the cassette.
      # @return [Boolean] whether the cassette was deleted or not
      def delete_old_cassette!(name)
        @vcr_library_dir ||= Pathname.new(::VCR.configuration.cassette_library_dir)
        cassette_path = @vcr_library_dir.join("#{name}.yml")

        if File.exist?(cassette_path)
          File.delete(cassette_path)
          true
        else
          false
        end
      end
    end
  end
end

Marty::RSpec::RequestRecording.enable_integration!
