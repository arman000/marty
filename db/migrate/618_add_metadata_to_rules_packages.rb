class AddMetadataToRulesPackages < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_rules_packages, :build_name, :text, null: false
    add_column :marty_rules_packages, :metadata, :jsonb, null: false, default: {}
  end
end
