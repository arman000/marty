# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Very hacky to overwrite delorean's whitelist.  But, there's no
# better way now.

Delorean::RUBY_WHITELIST.
  merge!({
         })

######################################################################

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
# FIXME: not sure why the following is needed.  Otherwise, the monkey
# patch doesn't work.
ActiveSupport::JSON.encode([Date.today])

class Date
  # Very Hacky: The date JSON encoding format doesn't include TZ info.
  # Therefore, the ExtJS client interprets it as GMT.  This causes
  # dates to be displayed as previous day on Pacific TZ clients.  So,
  # we just tack on 12:00 time to force the client to use the correct
  # date (at least in the US).
  def as_json(options = nil)
    strftime("%Y-%m-%dT12:00:00-00:00")
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

def pg_range_to_human(r)
  m = /\A(?<open>\[|\()(?<start>.*?),(?<end>.*?)(?<close>\]|\))\z/.match(r)

  raise "bad pg range #{r}" unless m

  if m[:start] == ""
    res = ""
  else
    op = m[:open] == "(" ? ">" : ">="
    res = "#{op}#{m[:start]}"
  end

  if m[:end] != ""
    op = m[:close] == ")" ? "<" : "<="
    res += "#{op}#{m[:end]}"
  end

  res
end

def human_to_pg_range(r)
  m = /\A
    ((?<op0>\>|\>=)(?<start>[^\<\>\=]*?))?
    ((?<op1>\<|\<=)(?<end>[^\<\>\=]*?))?
    \z/x.match(r)

  raise "bad range '#{r}'" unless m

  if m[:op0]
    open = m[:op0] == ">" ? "(" : "["
    start = "#{open}#{m[:start]}"
  else
    start = "["
  end

  if m[:op1]
    close = m[:op1] == "<" ? ")" : "]"
    ends = "#{m[:end]}#{close}"
  else
    ends = "]"
  end

  "#{start},#{ends}"
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
