module Marty
  class Railtie < Rails::Railtie
    config.marty = ActiveSupport::OrderedOptions.new
    config.marty.default_posting_type = 'BASE'
    config.marty.extjs_theme = 'classic'
    config.marty.promise_job_enqueue_hooks = []
    config.marty.redis_url = nil
    config.marty.enable_action_cable = true
    config.marty.data_grid_plpg_lookups = false
  end
end
