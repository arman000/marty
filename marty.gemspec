$:.push File.expand_path("../lib", __FILE__)

require "marty/version"

Gem::Specification.new do |s|
  s.name        = "marty"
  s.version     = Marty::VERSION
  s.authors     = [
                   "Arman Bostani",
                   "Eric Litwin",
                   "Iliana Toneva",
                   "Brian VanLoo",
                   "Chad Edie",
                  ]
  s.email       = ["arman.bostani@pnmac.com"]
  s.homepage    = "https://github.com/arman000/marty"
  s.summary     = "A framework for working with versioned data"
  s.description = s.summary
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + Dir["lib/tasks/*.rake"] +
    ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "pg"

  s.add_dependency 'netzke-core', '0.11.0'
  s.add_dependency 'netzke-basepack', '0.11.0'

  s.add_dependency 'axlsx', '2.1.0pre'

  s.add_dependency 'delorean_lang'
  s.add_dependency 'mcfly'

  s.add_dependency 'coderay'
  s.add_dependency 'net-ldap'
  s.add_dependency 'rubyzip'
end
