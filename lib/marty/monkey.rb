# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Very hacky to overwrite delorean's whitelist.  But, there's no
# better way now.

Delorean::RUBY_WHITELIST.
  merge!({
           sum: 	[Array],
           zip:         [Array, [Array, Array, Array]],
         })

######################################################################
# FIXME: not sure why the following is needed.  Otherwise, the monkey
# patch doesn't work.
ActiveSupport::JSON.encode([Date.today])

class Date
  # Very Hacky: The date JSON encoding format doesn't include TZ info.
  # Therefore, the ExtJS client interprets it using GMT time.  This
  # causes dates to be displayed as previous day on Pacific TZ
  # clients.  So, we just tack on 12:00 time to force the client to
  # use the correct date (at least in the US).
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
