require Pathname.new(__FILE__).parent.to_s + '/shared_connection_db_helpers'

module Marty; module RSpec; module SharedConnection
  @@classes_to_exclude_from_shared = ['Marty::Log']
  mattr_accessor :classes_to_exclude_from_shared

  EXCL_LAMBDA = lambda { classes_to_exclude_from_shared }.freeze

  class ActiveRecord::Base
    mattr_accessor :shared_connection
    class << self
      alias_method :orig_connection, :connection
    end
    def self.clear_connection
      @@shared_connection = nil
    end

    clear_connection

    def self.connection
      EXCL_LAMBDA.call.include?(model_name) ? orig_connection :
        @@shared_connection ||
        ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
    end

    def self.reset_shared_connection
      @@shared_connection = ConnectionPool::Wrapper
                              .new(:size => 1) { retrieve_connection }
    end
  end
end end end
