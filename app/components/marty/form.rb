class Marty::Form < Netzke::Form::Base
  extend ::Marty::Permissions

  client_class do |c|
    c.include :form
  end
end
