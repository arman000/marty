class Dummy::AuthApp < Marty::MainAuthApp
  def data_menus
    basic =
      [
        {
          text: 'foo',
          menu: [
            :bud_category_view
          ]
        },
      ]
  end

  action :bud_category_view do |a|
    a.text    = 'Bud Category View'
    a.handler = :netzke_load_component_by_action
  end

  component :bud_category_view do |c|
    c.klass = Dummy::BudCategoryView
    c.text = 'Bud Category View'
  end
end

AuthApp = Dummy::AuthApp
