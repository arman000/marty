class AddApiConfigsValidateResult < ActiveRecord::Migration
  def change
    rename_column :marty_api_configs, :validated, :input_validated
    add_column :marty_api_configs, :output_validated, :boolean, null: false,
               default: false
    add_column :marty_api_configs, :strict_validate, :boolean, null: false,
               default: false
  end
end
