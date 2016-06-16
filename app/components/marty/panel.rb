# Marty's version of the Netzke Panel component.
class Marty::Panel < Netzke::Core::Panel
  client_class do |c|
    c.update_body_html = l(<<-JS)
        function(html){
          this.body.update(html);
        }
      JS
  end
end

Panel = Marty::Panel
