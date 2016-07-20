# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Be able to access Enums from Delorean
class Delorean::BaseModule::BaseClass
  class << self
    alias_method :old_get_attr, :_get_attr

    def _get_attr(obj, attr, _e)
      if Marty::Enum === obj && !obj.respond_to?(attr)
        obj[attr]
      else
        old_get_attr(obj, attr, _e)
      end
    end
  end
end

######################################################################

class Hash
  # define addition on hashes -- useful in Delorean code.
  def +(x)
    self.merge(x)
  end

  # define hash slice (similar to node slice in Delorean)
  def %(x)
    x.each_with_object({}) { |k, h|
      h[k] = self[k]
    }
  end
end

######################################################################

require 'netzke-basepack'

class Netzke::Base
  # get root component session
  def root_sess(component=nil)
    component ||= self
    component.parent ? root_sess(component.parent) : component.component_session
  end
end

######################################################################

# The following is a hack to get around ActiveRecord's broken handling
# of PostgreSQL ranges.  Essentially, AR doesn't allow numranges to
# exclude the range start e.g. anything like: "(1.1,2.2]".  This hack
# turns off the casting of PostgreSQL ranges to ruby ranges. i.e. we
# keep them as strings.

require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID
        class Range
          def cast_value(value)
            super
          end

          def type_cast_for_database(value)
            super
          end
        end
      end
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Array

          # In the 4.2.1 version of this code, under Mutable, the code
          # checks for raw_old_value != type_cast_for_database(new_value)
          #
          # Since this is comparing db (string) version, we end up
          # comparing "{1}"!="{1.0}" for float arrays. The following
          # is a hack to check the new_value which is the ruby array.
          # This could be problematic in other ways.  But, works for
          # our purposes.  FIXME: In Rails 5.0 all this code has been
          # changed and this should no longer be an issue.


          def changed_in_place?(raw_old_value, new_value)
            new_value != type_cast_from_database(raw_old_value)
          end

        end
      end
    end
  end
end

######################################################################

# Rails 4 doesn't handle 'infinity' datetime properly due to
# in_time_zone conversion. Ergo this hack.

class String
  alias_method :old_in_time_zone, :in_time_zone

  def in_time_zone(zone = ::Time.zone)
    self == 'infinity' ? self : old_in_time_zone(zone)
  end
end

######################################################################

# Axlsx::sanitize modifies strings in worksheet definition -- this
# doesn't work with Delorean's frozen strings.
require 'axlsx'
module Axlsx
  def self.sanitize(str)
    str.delete(CONTROL_CHARS)
  end
end

######################################################################

require 'netzke/basepack/data_adapters/active_record_adapter'
module Netzke::Basepack::DataAdapters
  class ActiveRecordAdapter < AbstractAdapter
    # FIXME: another giant hack to handle lazy_load columns.
    # Modified original count_records to call count on first passed column.name
    # when lazy-loaded.  Otherwise, we run into issues with
    # counting records in the default_scope placed by the lazy_load
    # module.
    def count_records(params, columns=[])

      relation = @relation || get_relation(params)
      columns.each do |c|
        assoc, method = c[:name].split('__')
        relation = relation.includes(assoc.to_sym).references(assoc.to_sym) if method
      end

      @model.const_defined?(:LAZY_LOADED) ? relation.count(columns.first.name) :
        relation.count
    end

  end
end
