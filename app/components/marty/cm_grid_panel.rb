require 'netzke-basepack'
require 'marty/permissions'

class Marty::CmGridPanel < Netzke::Basepack::Grid
  extend ::Marty::Permissions

  has_marty_permissions read: :any

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
