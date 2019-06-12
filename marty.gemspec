$:.push File.expand_path('../lib', __FILE__)

require 'marty/version'
require 'digest/md5'
require 'base64'
require 'zlib'
require 'csv'
require 'pathname'

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
  ]
  s.email       = ['arman.bostani@pnmac.com']
  s.homepage    = 'https://github.com/arman000/marty'
  s.summary     = 'A framework for working with versioned data'
  s.description =
    'Marty is a framework for viewing and reporting on versioned data.'
  s.files       = `git ls-files`.split($\)
  s.licenses    = ['MIT']

  s.add_dependency 'pg', '~> 0.21'

  s.add_dependency 'netzke', '6.5.0.0'

  s.add_dependency 'axlsx', '3.0.0pre'

  s.add_dependency 'delorean_lang', '~> 0.6'
  s.add_dependency 'mcfly', '~> 0.0.20'

  s.add_dependency 'coderay'
  s.add_dependency 'json-schema'
  s.add_dependency 'net-ldap', '~> 0.16.1'
  s.add_dependency 'rubyzip'
  s.add_dependency 'sqlite3'

  # used for signing aws ec2 requests
  s.add_dependency 'aws-sigv4', '~> 1.0', '>= 1.0.2'

  s.add_dependency 'daemons', '~> 1.3.1'
  s.add_dependency 'delayed_cron_job'
  s.add_dependency 'delayed_job_active_record'
end
