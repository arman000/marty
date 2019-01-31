class Marty::Scripting < Netzke::Base
  def configure(c)
    super

    c.items =
      [
        :script_form,
        {
          xtype: "tabpanel",
          active_tab: 0,
          region: :center,
          split: true,
          items: [
            {
              title: I18n.t("script.selection"),
              layout: {
                type: :vbox,
                align: :stretch,
              },
              items: [
                :tag_grid,
                :script_grid,
              ],
            },
            :script_tester,
          ],
        },
      ]
  end

  client_class do |c|
    c.header = false
    c.layout = :border
    c.include :scripting
  end

  endpoint :select_tag do |params|
    root_sess[:selected_tag_id]      = params[:tag_id]
    root_sess[:selected_script_name] = nil
  end

  endpoint :select_script do |params|
    root_sess[:selected_script_name] = params[:script_name]
  end

  component :tag_grid do |c|
    c.klass            = Marty::TagGrid
    c.width            = 400
    c.height           = 300
    c.load_inline_data = false
    c.title            = I18n.t("script.selection_history")
  end

  component :script_grid do |c|
    c.width            = 400
    c.klass            = Marty::ScriptGrid
    c.title            = I18n.t("script.selection_list")
    c.flex             = 1
  end

  component :script_form do |c|
    c.klass            = Marty::ScriptForm
    c.title            = I18n.t("script.detail")
    c.flex             = 1
    c.split            = true
    c.region           = :west
  end

  component :script_tester do |c|
    c.klass            = Marty::ScriptTester
    c.title            = I18n.t("script.tester")
    c.flex             = 1
  end
end

Scripting = Marty::Scripting
