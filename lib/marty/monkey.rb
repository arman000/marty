# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Very hacky to overwrite delorean's whitelist.  But, there's no
# better way now.

Delorean::RUBY_WHITELIST.
  merge!({
         })

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

# define addition on hashes -- useful in Delorean code.
class Hash
  def +(x)
    self.merge(x)
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

