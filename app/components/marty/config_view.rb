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

  def my_jsonb_getter
    lambda { |r| v = Marty::Config[r.key]; v && v.to_json || '' }
  end
  def my_jsonb_pretty_getter
    lambda { |r| v = Marty::Config[r.key]
      v && (JSON.pretty_generate(v) rescue v.to_json) || '' }
  end

  def my_jsonb_setter
    lambda { |r, v|
      return r.set_value(nil) if v.blank?
      decoded = ActiveSupport::JSON.decode(v) rescue nil
      r.set_value(decoded)
    }
  end

  def default_form_items
    [
      :key,
      jsonb_field(:value, {
                    getter:  my_jsonb_pretty_getter,
                    setter:  my_jsonb_setter,
                  }),
      textarea_field(:description),
    ]
  end

  attribute :key do |c|
    c.flex = 1
  end

  column :value do |c|
    c.flex = 3
    c.getter  = my_jsonb_getter
    c.setter  = my_jsonb_setter
  end
  attribute :description do |c|
    c.flex = 1
  end

end

ConfigView = Marty::ConfigView
