class Gemini::LoanProgramView < Marty::GridAppendOnly
  include Marty::Extras::Layout

  has_marty_permissions create: :dev,
                        read:   :any,
                        update: :dev,
                        delete: :dev,
                        test_access: :admin

  def configure(c)
    super

    c.title = "Loan Programs"
    c.model = "Gemini::LoanProgram"
    c.attributes = [
      :name,
      :amortization_type__name,
      :mortgage_type__name,
      :streamline_type__name,
      :enum_state,
    ]

    c.store_config.merge!({sorters:  [{property: :name, direction: 'ASC'}]})
  end

  client_class do |c|
    c.netzke_on_test_access = l(<<-JS)
        function() {
           this.server.testAccess({})
        }
    JS
  end

  def default_bbar
     super + [:test_access]
  end

  action :test_access do |a|
    a.text    = a.tooltip = 'Test Access'
  end

  attribute :enum_state do |c|
    enum_column(c, Gemini::EnumState)
  end

  endpoint :test_access do |c|
    client.netzke_notify 'You have admin access'
  end
end
