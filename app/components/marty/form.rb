class Marty::Form < Netzke::Form::Base
  extend ::Marty::Permissions

  client_class do |c|
    c.include :form
    c.include "#{Marty.root}/app/components/marty/js/addons.js"
  end
end
