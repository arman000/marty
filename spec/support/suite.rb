relative = Pathname.new(__FILE__).parent.to_s
['setup',
 'users',
 'components/netzke_combobox',
 'components/netzke_grid',
 'netzke',
 'download_helper',
 'chromedriver',
 'delayed_job_helpers',
 'post_run_logger',
 'helper',
 'performance_helper',
 'structure_compare',
 'custom_matchers',
 'custom_selectors',
].each { |f| require (relative + '/' + f) }

module Marty; module RSpec; module Suite
  include Marty::RSpec::Setup
  include Marty::RSpec::Users
  include Marty::RSpec::Netzke
  include Marty::RSpec::DelayedJobHelpers
  include Marty::RSpec::DownloadHelper
  include Marty::RSpec::PostRunLogger
  include Marty::RSpec::PerformanceHelper
  include Marty::RSpec::StructureCompare
end end end
