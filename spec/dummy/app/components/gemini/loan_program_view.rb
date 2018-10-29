class Gemini::LoanProgramView < Marty::GridAppendOnly
  include Marty::Extras::Layout

  has_marty_permissions create: :dev,
                        read:   :any,
                        update: :dev,
                        delete: :dev

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

  attribute :enum_state do |c|
    enum_column(c, Gemini::EnumState)
  end
end
