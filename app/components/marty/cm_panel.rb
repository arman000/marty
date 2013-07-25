class Marty::CmPanel < Netzke::Core::Panel
  js_configure do |c|
    c.update_body_html = <<-JS
        function(html){
          this.body.update(html);
        }
      JS
  end
end

CmPanel = Marty::CmPanel

