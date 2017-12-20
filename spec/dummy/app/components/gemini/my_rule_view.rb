class Gemini::MyRuleView < Marty::DeloreanRuleView
  has_marty_permissions create: :admin,
                        read: :admin,
                        update: :admin,
                        delete: :admin

  def self.base_fields
    super + [:other_flag]
  end
  def configure(c)
    super
    c.title = 'My Rules'
  end

  def self.klass
    Gemini::MyRule
  end

  attribute :other_flag do |c|
    c.width = 75
  end

  def form_items_grids
    [
      self.class.grid_column(:grid1),
      self.class.grid_column(:grid2),
    ]
  end
  def default_form_items
    [
      hbox(
        vbox(*form_items_attrs +
             form_items_guards +
             form_items_grids,
             border: false,
             width: "40%",
        ),
        vbox(width: '2%', border: false),
        vbox(
             width: '55%', border: false),
        height: '56%',
        border: false,
      ),
      hbox(
        vbox(*form_items_computed_guards +
             form_items_results,
             width: '99%',
             border: false
        ),
        height: '35%',
        border: false
      )
    ]
  end

  self.init_fields

  attribute :rule_type do |c|
    c.width = 200
    enum_column(c, Gemini::MyRuleType)
  end

end
