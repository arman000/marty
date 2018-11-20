class Marty::Form < Netzke::Form::Base
  extend ::Marty::Permissions

  client_class do |c|
    c.find_component = l(<<-JS)
    function(name) {
      return Ext.ComponentQuery.query(`[name=${name}]`)[0];
    }
    JS
  end
end
