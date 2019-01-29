class Marty::ApiConfigView < Marty::Grid
  has_marty_permissions create: :admin,
                        read: :any,
                        update: :admin,
                        delete: :admin

  def configure(c)
    super
    c.model = Marty::ApiConfig
    c.title = 'API Config'
    c.attributes = [
      :script,
      :node,
      :attr,
      :api_class,
      :logged,
      :input_validated,
      :output_validated,
      :strict_validate,
      :created_at,
      :updated_at,
    ]
    c.paging = :pagination
    c.editing = :in_form
    c.store_config.merge!(
      sorters: [{ property: :script, direction: :ASC },
                { property: :node,      direction: :ASC },
                { property: :attr,      direction: :ASC },
                { property: :api_class, direction: :ASC },])
    @model = c.model
  end

  attribute :api_class do |c|
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          Marty::Api::Base.class_list,
      forceSelection: true,
    }
    c.merge!(
      column_config: { editor: editor_config },
      field_config:  editor_config,
      type:          :string,
    )
    c.width = 200
    c.label = "API Class"
  end

  attribute :script do |c|
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          Marty::Script.where(obsoleted_dt: 'infinity')
        .order(:name).pluck(:name),
      forceSelection: true,
    }
    c.merge!(
      column_config: { editor: editor_config },
      field_config:  editor_config,
      type:          :string,
    )
    c.width = 150
  end

  [:node, :attr].each do |a|
    attribute a do |c|
      c.width = 150
      c.setter = lambda { |r, v| r.send("#{a}=", v.blank? ? nil : v) }
    end
  end

  [:logged, :input_validated, :output_validated, :strict_validate].each do |a|
    attribute a do |c|
      c.width = 110
    end
  end

  [:created_at, :updated_at].each do |a|
    attribute a do |c|
      c.read_only = true
    end
  end

  def default_form_items
    [
      :script,
      :node,
      :attr,
      :api_class,
      :logged,
      :input_validated,
      :output_validated,
      :strict_validate,
    ]
  end
end
ApiConfigView = Marty::ApiConfigView
