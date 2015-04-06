# Marty's version of the Netzke Panel component.
class Marty::Panel < Netzke::Core::Panel
  js_configure do |c|
    c.update_body_html = <<-JS
        function(html){
          this.body.update(html);
        }
      JS
  end
end

Panel = Marty::Panel
