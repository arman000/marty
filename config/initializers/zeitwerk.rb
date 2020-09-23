# config/initializers/zeitwerk.rb

return unless Rails.respond_to?(:autoloaders) && Rails.autoloaders.main

# FIXME: Zeitwerk is very convention heavy and anything that doesn't
# conform will result in an exception.

# we can sometimes resolve convention issues with inflectors
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'netzke-basepack' => 'NetzkeBasepack',
    'simplecov_helper' => 'SimpleCovHelper',
  )
end

# ignore monkey/version as these break convention.
marty = Gem::Specification.find_by_name('marty')
ignore = [
  "#{marty.gem_dir}/lib/marty/monkey.rb",
  "#{marty.gem_dir}/lib/marty/version.rb"
]

Rails.autoloaders.main.ignore(*ignore)
