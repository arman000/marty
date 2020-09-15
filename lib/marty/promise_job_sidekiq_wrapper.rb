# FIXME: remove sidekiq require
require 'sidekiq'
require 'sidekiq/api'
require 'marty/promise_job'

class Marty::PromiseJobSidekiqWrapper
  include Sidekiq::Worker

  # FIXME: move into config.
  sidekiq_options retry: false

  def perform(yaml_job)
    # require 'marty/promise'
    # require 'marty/tag'

    job = if YAML.respond_to?(:load_dj)
            # FIXME: figure out how to use regular load instead of load_dj
            # ATM load doesn't autoload constants
            YAML.load_dj(yaml_job)
          else
            YAML.load(yaml_job) # rubocop:disable Security/YAMLLoad
          end

    # logger.info yaml_job
    # logger.info job
    job.perform
    # logger.info 'after sidekiq'
  end
end
