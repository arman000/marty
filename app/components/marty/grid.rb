class Marty::Grid < ::Netzke::Grid::Base
  extend ::Marty::Permissions

  has_marty_permissions read: :any

  # parent grid is the grid in which child/linked_components is defined
  # child  components are components dependent on the selected parent row
  # linked components will update whenever the parent is updated
  def initialize args, kwargs = nil
    super(args, kwargs)
    client_config[:child_components]  = child_components  || []
    client_config[:linked_components] = linked_components || []
  end

  client_class do |c|
    c.include :grid
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

    c.editing      = :both
    c.store_config = { page_size: 30 }
    c.view_config  = { preserve_scroll_on_reload: true }

    # disable buffered renderer plugin to avoid white space on reload
    c.buffered_renderer = false
  end

  def has_search_action?
    false
  end

  action :clear_filters do |a|
    a.text    = 'X'
    a.tooltip = 'Clear filters'
    a.handler = :clear_filters
  end

  def get_json_sorter(json_col, field)
    lambda do |r, dir|
      r.order(Arel.sql("#{json_col} ->> '#{field}' " + dir.to_s))
    end
  end

  action :clear_filters do |a|
    a.text     = 'X'
    a.tooltip  = 'Clear filters'
    a.handler  = :clear_filters
  end

  # cosmetic changes

  action :add do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-plus glyph'
  end

  action :add_in_form do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-plus-square glyph'
  end

  action :edit do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-edit glyph'
  end

  action :edit_in_form do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-pen-square glyph'
  end

  action :delete do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-trash glyph'
  end

  action :apply do |a|
    super(a)
    a.icon     = nil
    a.icon_cls = 'fa fa-check glyph'
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

    c.form_config.submit_handler = nil
  end

  component :view_window do |c|
    configure_form_window(c)
    c.excluded = !allowed_to?(:read)
    c.items    = [:view_form]
    c.title    = I18n.t('netzke.grid.base.view_record',
                        model: model.model_name.human)
  end
end
