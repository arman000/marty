class Marty::Tree < ::Netzke::Tree::Base
  extend ::Marty::Permissions

  has_marty_permissions read: :any

  # parent tree is the tree in which child/linked_components is defined
  # child  components are components dependent on the selected parent row
  # linked components will update whenever the parent is updated
  def initialize(args, kwargs = nil)
    super(args, kwargs)
    client_config[:child_components]  = child_components  || []
    client_config[:linked_components] = linked_components || []
  end

  client_class do |c|
    c.include :tree
  end

  ######################################################################

  def class_can?(op)
    self.class.can_perform_action?(op)
  end

  def configure(c)
    super

    c.permissions = {
      create: class_can?(:create),
      read:   class_can?(:read),
      update: class_can?(:update),
      delete: class_can?(:delete)
    }
  end

  def child_components
    []
  end

  def linked_components
    []
  end

  def configure_form_window(c)
    super

    c.klass = Marty::RecordFormWindow

    # Fix Add in form/Edit in form modal popup width
    # Netzke 0.10.1 defaults width to 80% of screen which is too wide
    # for a form where the fields are stacked top to bottom
    # Netzke 0.8.4 defaulted width to 400px - let's make it a bit wider
    c.width = 475
  end

  component :view_window do |c|
    configure_form_window(c)
    c.excluded = !allowed_to?(:read)
    c.items    = [:view_form]
    c.title    = I18n.t('netzke.grid.base.view_record',
                        model: model.model_name.human)
  end
end
