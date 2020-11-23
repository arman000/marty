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
ignore = [
  Marty::Gem.dir.join('lib/marty/monkey.rb'),
  Marty::Gem.dir.join('lib/marty/version.rb'),
]

Rails.autoloaders.main.ignore(*ignore)
