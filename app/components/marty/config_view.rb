class Marty::ConfigView < Marty::Grid
  has_marty_permissions \
  create: :admin,
  read: :admin,
  update: :admin,
  delete: :admin

  include Marty::Extras::Layout

  def configure(c)
    super

    c.title   = I18n.t('config', default: "Config")
    c.model   = "Marty::Config"
    c.attributes = [:key, :value, :description]
    c.store_config.merge!({sorters: [{property: :key, direction: 'ASC'}]})
    c.editing = :both
  end

  # need a getter / setter to call the []= and [] methods now
  # since value is no longer stored as is
  def my_jsonb_getter
    lambda { |r| Marty::Config[r.key].to_json }
  end

  def my_jsonb_setter
    lambda { |r, v|
      decoded = ActiveSupport::JSON.decode(v) rescue nil
      r.set_value(decoded)
    }
  end

  def default_form_items
    [
      :key,
      {
        name:        :value,
        width:       "100%",
        height:      150,
        xtype:       :textareafield,
        auto_scroll: true,
        spellcheck:  false,
        allow_blank: false,
        field_style: {
          font_family: 'courier new',
          font_size:   '12px'
        },
        getter:  my_jsonb_getter,
        setter:  my_jsonb_setter,
      },
      textarea_field(:description),
    ]
  end

  attribute :key do |c|
    c.flex = 1
  end

  attribute :value do |c|
    c.flex = 3
    c.getter  = my_jsonb_getter
    c.setter  = my_jsonb_setter
  end
  attribute :description do |c|
    c.flex = 1
  end

end

ConfigView = Marty::ConfigView
