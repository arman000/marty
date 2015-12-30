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
    c.columns = [:key, :value, :description]

    c.enable_extended_search = false
    c.data_store.sorters     = {property: :key, direction: 'ASC'}
  end

  # need a getter / setter to call the []= and [] methods now
  # since value is no longer stored as is
  def my_jsonb_getter
    lambda { |r| Marty::Config[r.key].to_json }
  end

  def my_jsonb_setter
    lambda { |r, v|
      Marty::Config[r.key] = ActiveSupport::JSON.decode(v) }
  end

  def default_fields_for_forms
    [
      :key,
      {
        name:        :value,
        width:       "100%",
        height:      150,
        xtype:       :textareafield,
        auto_scroll: true,
        spellcheck:  false,
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

  column :key do |c|
    c.flex = 1
  end

  column :value do |c|
    c.flex = 3
    c.getter  = my_jsonb_getter
    c.setter  = my_jsonb_setter
  end
  column :description do |c|
    c.flex = 1
    c.width = 200
  end

end

ConfigView = Marty::ConfigView
