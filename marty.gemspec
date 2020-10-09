$:.push File.expand_path('../lib', __FILE__)

require 'marty/version'
require 'digest/md5'
require 'base64'
require 'zlib'
require 'csv'
require 'pathname'

git_tracked_files = `git ls-files`.split($\)
gem_ignored_files = `git ls-files -i -X .gemignore`.split($\)
files = git_tracked_files - gem_ignored_files

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
  s.add_dependency 'actioncable'
  s.add_dependency 'aws-sigv4'
  # Only pinning this because there's no other way around it for Axlsx.
  # DO NOT unpin this.
  s.add_dependency 'axlsx', '3.0.0pre'
  s.add_dependency 'coderay'
  s.add_dependency 'daemons'
  s.add_dependency 'delayed_cron_job'
  s.add_dependency 'delayed_job_active_record'
  s.add_dependency 'delorean_lang', '>= 2.6.0'
  s.add_dependency 'json-schema'
  s.add_dependency 'mcfly'
  # s.add_dependency 'mini_racer' # FIXME: add mini_racer as dependency once we fix the lambda layer size issue
  s.add_dependency 'net-ldap'
  s.add_dependency 'netzke'
  s.add_dependency 'pg'
  s.add_dependency 'rails'
  s.add_dependency 'redis'
  s.add_dependency 'rubyzip'
  s.add_dependency 'simplecov' # FIXME: Move to cm_shared when it's ready
  s.add_dependency 'state_machines'
  s.add_dependency 'state_machines-activerecord'
  s.add_dependency 'tiny_tds'
  s.add_dependency 'zip-zip'

  # Development-only Dependencies
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'puma'
end
