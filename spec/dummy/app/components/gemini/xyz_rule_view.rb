class Gemini::XyzRuleView < Marty::BaseRuleView
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

end
