$LOAD_PATH.push File.expand_path('lib', __dir__) # rubocop:disable Style/SpecialGlobalVars

require 'marty/version'

files = Dir[
  'app/**/*',
  'config/**/*',
  'db/**/*',
  'delorean/**/*',
  'lib/**/*',
  'spec/support/**/*',
  'CHANGELOG.md',
  'Gemfile',
  'marty.gemspec',
  'MIT-LICENSE',
  'package.json',
  'Rakefile',
  'README.md',
]

Gem::Specification.new do |s|
  s.name        = 'marty'
  s.version     = Marty::VERSION
  s.authors     = [
    'Arman Bostani',
    'Brian VanLoo',
    'Chad Edie',
    'Eric Litwin',
    'Iliana Toneva',
    'Jock Cooper',
    'Masaki Matsuo',
    'Hayden McFarland',
    'Omri Gabay',
    'Eugene Zvyagintsev',
    'Gabriel Lluch',
    'Agrim Pathak',
    'Frank Garcia'
  ]
  s.email       = ['arman.bostani@pnmac.com', 'capitalmarketsit@pnmac.com']
  s.homepage    = 'https://github.com/arman000/marty'
  s.summary     = 'A framework for working with versioned data'
  s.description =
    'Marty is a framework for viewing and reporting on versioned data.'
  s.files       = files
  s.licenses    = ['MIT']
  s.required_ruby_version = '>= 2.4.2'

  # used for signing aws ec2 requests
  s.add_dependency 'aws-sigv4', '~> 1.2.2'
  # Only pinning this because there's no other way around it for Axlsx.
  # DO NOT unpin this.
  s.add_dependency 'axlsx', '3.0.0pre'
  s.add_dependency 'coderay', '~> 1.1.3'
  s.add_dependency 'daemons', '~> 1.3.1'
  s.add_dependency 'delayed_cron_job', '~> 0.7.4'
  s.add_dependency 'delayed_job', '~> 4.1.9'
  s.add_dependency 'delayed_job_active_record', '~> 4.1.5'
  s.add_dependency 'delorean_lang', '>= 2.6.0'
  s.add_dependency 'json-schema', '~> 2.8.1'
  s.add_dependency 'mcfly', '~> 1.0.0'
  # s.add_dependency 'mini_racer' # FIXME: add mini_racer as dependency once we fix the lambda layer size issue
  s.add_dependency 'net-ldap', '~> 0.17.0'
  s.add_dependency 'netzke', '~> 6.5.0.0'
  s.add_dependency 'pg', '~> 1.2.2'
  s.add_dependency 'rails', '>= 5.0.0', '< 6.1'
  s.add_dependency 'redis', '~> 4.2.5'

  # Constrained to rubyzip 1 because axlsx hasn't been updated and
  # is not maintained
  s.add_dependency 'rubyzip', '>= 1.2.1'
  s.add_dependency 'simplecov' # FIXME: Move to cm_shared when it's ready
  s.add_dependency 'state_machines', '~> 0.5.0'
  s.add_dependency 'state_machines-activerecord', '~> 0.6.0'
  s.add_dependency 'zip-zip', '~> 0.3'

  # Development-only Dependencies
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'puma'
end
