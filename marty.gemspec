$:.push File.expand_path("../lib", __FILE__)

require "marty/version"
require "digest/md5"
require "base64"
require "zlib"
require "csv"

Gem::Specification.new do |s|
  s.name        = "marty"
  s.version     = Marty::VERSION
  s.authors     = [
    "Arman Bostani",
    "Brian VanLoo",
    "Chad Edie",
    "Eric Litwin",
    "Iliana Toneva",
    "Jock Cooper",
    "Masaki Matsuo",
  ]
  s.email       = ["arman.bostani@pnmac.com"]
  s.homepage    = "https://github.com/arman000/marty"
  s.summary     = "A framework for working with versioned data"
  s.description =
    "Marty is a framework for viewing and reporting on versioned data."
  s.files       = `git ls-files`.split($\)
  s.licenses    = ['MIT']

  s.add_dependency "pg", "~> 0.17"

  s.add_dependency 'netzke-core', '~> 1.0.0'
  s.add_dependency 'netzke-basepack', '~> 1.0.0'
  s.add_development_dependency 'netzke-testing', '~> 1.0.0'

  s.add_dependency 'axlsx', '2.1.0pre'

  s.add_dependency 'delorean_lang', '~> 0.3.24'
  s.add_dependency 'mcfly', '0.0.19'

  s.add_dependency 'coderay'
  s.add_dependency 'net-ldap', '~> 0.12.0'
  s.add_dependency 'rubyzip'
  s.add_dependency 'sqlite3'
  s.add_dependency 'json-schema'
end
