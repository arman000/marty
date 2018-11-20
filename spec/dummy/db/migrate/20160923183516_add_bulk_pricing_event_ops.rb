class AddBulkPricingEventOps < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  def change
    execute "ALTER TYPE enum_event_operations ADD VALUE 'PRICING';"
    execute "ALTER TYPE enum_event_operations ADD VALUE 'CRA';"
    execute "ALTER TYPE enum_event_operations ADD VALUE 'AVM';"
  end
end
