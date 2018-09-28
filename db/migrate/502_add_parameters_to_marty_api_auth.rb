class AddParametersToMartyApiAuth < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_api_auths, :parameters, :jsonb, default: {}
  end
end
