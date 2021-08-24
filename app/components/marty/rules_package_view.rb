class Marty::RulesPackageView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: [:admin, :dev]

  def configure(c)
    super

    c.title ||= I18n.t('rules_packages', default: 'Rules Packages')
    c.model      = 'Marty::Rules::Package'
    c.paging     = :pagination
    c.editing    = :none
    c.attributes = [
      :name,
      :build_name,
      :starts_at,
      :metadata,
      :created_at,
      :updated_at,
    ]

    c.store_config.merge!(sorters:
                            [
                              { property: :name },
                              { property: :starts_at, direction: 'DESC' },
                            ]
                         )
  end

  def default_context_menu
    []
  end

  attribute :metadata do |c|
    c.width = 300
    c.getter = ->(r) { r.metadata.to_json }
  end
end

RulesPackageView = Marty::RulesPackageView
