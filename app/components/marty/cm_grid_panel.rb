require 'netzke-basepack'
require 'marty/permissions'

class Marty::CmGridPanel < Netzke::Basepack::Grid
  extend Marty::Permissions
  include Marty::Extras::Csv

  js_configure do |c|
    # FIXME: Replacing Grid's fieldTypeForAttrType function since we
    # need to map float.  This is still busted in 0.8.4.  Remove this
    # when bug is fixed.
    c.field_type_for_attr_type = <<-JS
    function(attrType){
    var map = {
      integer   : 'int',
      decimal   : 'float',
      datetime  : 'date',
      date      : 'date',
      string    : 'string',
      text      : 'string',
      'boolean' : 'boolean',
      'float'   : 'float',  // added by PennyMac
    };

    return map[attrType] || 'string';
    }
    JS
  end
end
