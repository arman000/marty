relative = Pathname.new(__FILE__).parent.to_s
file_names = [
  'chromedriver',
  'components/netzke_combobox',
  'components/netzke_grid',
  'custom_matchers',
  'custom_selectors',
  'delayed_job_helpers',
  'download_helper',
  'helper',
  'json_helper',
  'netzke',
  'performance_helper',
  'post_run_logger',
  'setup',
  'structure_compare',
  'users',
]

file_names.sort.each { |f| require (relative + '/' + f) }

module Marty
  module RSpec
    module Suite
      include Marty::RSpec::Setup
      include Marty::RSpec::Users
      include Marty::RSpec::Netzke
      include Marty::RSpec::DelayedJobHelpers
      include Marty::RSpec::DownloadHelper
      include Marty::RSpec::JsonHelper
      include Marty::RSpec::PostRunLogger
      include Marty::RSpec::PerformanceHelper
      include Marty::RSpec::StructureCompare
    end
  end
end
