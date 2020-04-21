class Gemini::CmAuthApp < Marty::MainAuthApp

  CATEGORY_COMPONENTS = [
    :loan_program_view,
  ]

  def data_menus
    basic = [
      {
        text: 'Pricing Config.',
        icon: icon_hack(:database_key),
        menu: [
          :loan_program_view,
          :my_rule_view,
          :xyz_rule_view,
          :simple_view,
          :user_grid_without_model,
        ],
      }
    ]
  end

  action :loan_program_view do |a|
    a.text    = a.tooltip = 'Loan Programs'
    a.handler = :netzke_load_component_by_action
  end

  action :my_rule_view do |a|
    a.text    = a.tooltip = 'My Rules'
    a.handler = :netzke_load_component_by_action
  end

  action :xyz_rule_view do |a|
    a.text    = a.tooltip = 'Xyz Rules'
    a.handler = :netzke_load_component_by_action
  end

  action :simple_view do |a|
    a.text    = a.tooltip = 'Gemini Simple'
    a.handler = :netzke_load_component_by_action
  end

  action :user_grid_without_model do |a|
    a.text    = a.tooltip = 'User Grid Without Model'
    a.handler = :netzke_load_component_by_action
  end

  component :loan_program_view do |c|
    c.klass = Gemini::LoanProgramView
  end

  component :my_rule_view do |c|
    c.klass = Gemini::MyRuleView
  end

  component :xyz_rule_view do |c|
    c.klass = Gemini::XyzRuleView
  end

  component :simple_view do |c|
    c.klass = Gemini::SimpleView
  end

  component :user_grid_without_model do |c|
    c.klass = Gemini::UserGridWithoutModel
  end
end
