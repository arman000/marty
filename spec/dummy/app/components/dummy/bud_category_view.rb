class Dummy::BudCategoryView < Marty::GridAppendOnly
  has_marty_permissions create: :dev,
                        read: :any,
                        update: :dev,
                        delete: :dev

  def configure(c)
    super

    model = "bud_category".camelize

    c.title = I18n.t("bud_category")
    c.model = "Gemini::" + model
    c.attributes = [:name]

    c.store_config.merge!({sorters:  [{property: :name, direction: 'ASC'}]})
  end

  attribute :name do |c|
    c.width = 200
  end
end
