class Gemini::XyzRuleView < Marty::DeloreanRuleView
  has_marty_permissions create: :admin,
                        read: :admin,
                        update: :admin,
                        delete: :admin
  def self.klass
    Gemini::XyzRule
  end

  def configure(c)
    super
    c.title = 'Xyz Rules'
  end

  def default_form_items
    super
  end

  self.init_fields

  attribute :rule_type do |c|
    c.width = 200
    enum_column(c, Gemini::XyzRuleType)
  end

  # Override width, so it would fit in chrome window in tests
  component :add_window do |c|
    super(c)
    c.width = 1200
    c.height = 740
  end

  component :edit_window do |c|
    super(c)
    c.width = 1200
    c.height = 740
  end

  component :view_window do |c|
    super(c)
    c.width = 1200
    c.height = 740
  end
end
