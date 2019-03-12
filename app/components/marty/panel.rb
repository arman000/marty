# Marty's version of the Netzke Panel component.
class Marty::Panel < Netzke::Core::Panel
  client_class do |c|
    c.include :panel
  end
end

Panel = Marty::Panel
