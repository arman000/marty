# DelayedJob is a unique diagnostic that creates a series of delayed jobs
# in the hopes that enough nodes will touch these jobs to determine
# if delayed job workers are running the latest application version
#
# `DELAYED_VER` environment variable should be set in the
# delayed jobs initializer.
#
module Marty
  module Diagnostic
    class DelayedJobVersion < Marty::Diagnostic::Base
      self.aggregatable = false

      class << self
        def description
          <<~TEXT
            Creates a number of background jobs that will be worked off by background
            workers in order to report back their corresponding code versions.
          TEXT
        end

        def create_promise
          Marty::Promises::Ruby::Create.call(
            module_name: name,
            method_name: 'delay',
            method_args: [2.6],
            params: { 'p_title' => name }
          )
        end

        def delay(time)
          Marty::Helper.sleep(time)
          Marty::Helper.git
        end

        def disabled_info
          {
            Marty::Diagnostic::Node.my_ip => {
              'Version' => create_info('Disabled')
            }
          }
        end

        def generate
          return disabled_info if Marty::Config['DIAG_DELAYED_JOB_VERSION_DISABLED'] == true

          raise 'DelayedJob cannot be called with local scope.' if
            scope == 'local'

          raise 'DELAYED_VER environment variable has not been initialized.' if
            Rails.application.config.marty.delayed_ver.nil?

          total_workers = Marty::Diagnostic::Node.
            get_target_connections('delayed').count

          raise 'No delayed jobs are running.' if total_workers.zero?

          # we will only iterate by half of the total delayed workers to avoid
          # excess use of delayed job time
          promise_count = (total_workers / 2).zero? ? 1 : total_workers / 2

          raise 'Previous diagnostic is still processing.' if
            Marty::Promise.where(title: name).where('end_dt is NULL').exists?

          (0...promise_count).map { create_promise }.each_with_object({}) do |r, hash|
            hash[r[0]] ||= []
            hash[r[0]] << r[1]
          end.map do |node, result|
            versions = result.uniq
            status = versions.count == 1 && versions[0] == Rails.application.config.marty.delayed_ver

            { node => { 'Version' => create_info(versions.join("\n"), status) } }
          end.reduce(:deep_merge)
        end
      end
    end
  end
end
