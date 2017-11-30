# DO NOT change order of require, since there are some dependencies

# DO NOT include anything here that will be properly autoloaded by
# Rails - This would be any file that define a properly namespaced
# module/class as Marty::<filename> and that don't run code outside of
# that module/class

# Also note that anything required here will need to require in any
# classes that they might be overriding methods in

require 'marty/engine'
require 'marty/railtie'
require 'marty/mcfly_model'
require 'marty/monkey'
require 'marty/promise_job'
require 'marty/lazy_column_loader'
require 'marty/json_schema'

# This does not get loaded in via bundler unless it is included in the
# application's Gemfile. Requiring it here removes the need to add it
# to the Gemfile
require 'net-ldap'
