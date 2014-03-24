$:.push File.expand_path("../lib", __FILE__)

require "marty/version"

Gem::Specification.new do |s|
  s.name        = "marty"
  s.version     = Marty::VERSION
  s.authors     = ["Arman Bostani", "Eric Litwin", "Iliana Toneva"]
  s.email       = ["arman.bostani@pnmac.com"]
  s.homepage    = "https://github.com/arman000/marty"
  s.summary     = "A framework for working with versioned data"
  s.description = s.summary

  s.files = Dir["{app,config,db,lib}/**/*"] + Dir["lib/tasks/*.rake"] +
    ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.13"

  s.add_development_dependency "pg"

  # s.add_development_dependency "cucumber-rails"
  s.add_development_dependency "pickle"
  s.add_development_dependency "rspec-rails", '>= 2.0.1'
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara", '~> 1.0'
  s.add_development_dependency "selenium-webdriver"
  s.add_development_dependency 'timecop'

  s.add_dependency 'netzke-core', '0.8.4'
  s.add_dependency 'netzke-basepack', '0.8.4'

  # needed for Netzke
  s.add_dependency 'will_paginate', '~>3.0.3'

  s.add_dependency 'foreigner', '~>1.4.2'

  s.add_dependency 'axlsx'

  s.add_dependency 'delorean_lang'
  s.add_dependency 'mcfly'

  s.add_dependency 'coderay'
  s.add_dependency 'net-ldap'
  s.add_dependency 'paper_trail', '~>2.7.2'
  s.add_dependency 'rubyzip', '1.1.0'
end
