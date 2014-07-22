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
      Marty::Enum === obj ? obj[attr] : old_get_attr(obj, attr, _e)
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

class ActiveRecord::Relation
  # multi-column pluck based on AR pluck code
  def pluckn(*columns)
    return pluck(columns[0]) if columns.length == 1

    relation = clone
    relation.select_values = columns
    klass.connection.select_all(relation.arel).map! do |attributes|
      attributes.map { |k,v|
        klass.type_cast_attribute(k, klass.initialize_attributes(attributes))
      }
    end
  end
end

######################################################################

# The following is a hack to get around postgres_ext's broken handling
# of PostgreSQL ranges.  Essentially, postgres_ext doesn't allow
# numranges to exlude the range start e.g. anything like: "(1.1,2.2]".
# This hack turns off the casting of PostgreSQL ranges to ruby
# ranges. i.e. we keep them as strings.  Note that this hack would be
# quite different for Rails 4.0.

raise "The PG range hack needs to be fixed" if Rails.version[0] != "3"

require 'postgres_ext'

RANGE_TYPES =
  Set[:numrange,:int4range,:int8range,:daterange,:tsrange,:tstzrange]

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLColumn
      RANGE_TYPES =
        Set[:numrange,:int4range,:int8range,:daterange,:tsrange,:tstzrange]

      def type_cast_with_rr(value)
        return value if RANGE_TYPES.member?(type)

        type_cast_without_rr(value)
      end

      alias_method_chain :type_cast, :rr


      def type_cast_code_with_rr(var_name)
        return var_name if RANGE_TYPES.member?(type)

        type_cast_code_without_rr(var_name)
      end
      alias_method_chain :type_cast_code, :rr

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
