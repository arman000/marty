require 'marty/permissions'

# Netzke Form with Marty permissions
class Marty::Form < Netzke::Basepack::Form
  extend ::Marty::Permissions
end
