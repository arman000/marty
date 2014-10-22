require 'netzke-basepack'
require 'netzke/basepack/grid'
require 'marty/permissions'

class Marty::CmGridPanel < ::Netzke::Basepack::Grid
  extend ::Marty::Permissions

  has_marty_permissions read: :any

  def preconfigure_record_window(c)
    super
    # Fix Add in form/Edit in form modal popup width
    # Netzke 0.10.1 defaults width to 80% of screen which is too wide
    # for a form where the fields are stacked top to bottom
    # Netzke 0.8.4 defaulted width to 400px - let's make it a bit wider
    c.width = 475
  end

  js_configure do |c|
    # For some reason the grid update function was removed in Netzke
    # 0.10.1.  So, add it here.
    c.cm_update = <<-JS
    function() {
      this.store.load();
    }
    JS
  end

  def configure(c)
    super

    create = self.class.can_perform_action?(:create)
    read   = self.class.can_perform_action?(:read)
    update = self.class.can_perform_action?(:update)
    delete = self.class.can_perform_action?(:delete)

    c.prohibit_create     = !create
    c.prohibit_read       = !read
    c.prohibit_update     = !update
    c.prohibit_delete     = !delete

    c.enable_edit_inline  = update
    c.enable_edit_in_form = update
  end
end
