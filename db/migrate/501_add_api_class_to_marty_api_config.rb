class AddApiClassToMartyApiConfig < ActiveRecord::Migration[5.1]
  def change
    table = :marty_api_configs
    add_column table, :api_class, :string, default: 'Marty::Api::Base'
  end
end
