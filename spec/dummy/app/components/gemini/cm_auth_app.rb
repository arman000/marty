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
        ],
      }
    ]
  end

  action :loan_program_view do |a|
    a.text    = a.tooltip = 'Loan Programs'
    a.handler = :netzke_load_component_by_action
  end

  component :loan_program_view do |c|
    c.klass = Gemini::LoanProgramView
  end
end
