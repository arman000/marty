class Gemini::MyRuleView < Marty::BaseRuleView
  has_marty_permissions create: :admin,
                        read: :admin,
                        update: :admin,
                        delete: :admin

  def configure(c)
    super
    c.title = 'My Rules'
  end

  def self.klass
    Gemini::MyRule
  end

  attribute :other_flag do |c|
    c.getter = lambda { |r| r.attrs[name]||false}
    c.type = :boolean
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
        vbox(*[:name] +
             form_items_attrs +
             form_items_guards +
             form_items_grids,
             border: false,
             width: "40%",
        ),
        vbox(width: '2%', border: false),
        vbox(*form_items_simple_results,
             width: '55%', border: false),
        height: '56%',
        border: false,
      ),
      hbox(
        vbox(*form_items_computed_guards +
             form_items_computed_results,
             width: '99%',
             border: false
        ),
        height: '35%',
        border: false
      )
    ]
  end

  self.init_fields

end
