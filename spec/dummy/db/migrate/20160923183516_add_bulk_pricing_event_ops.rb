class AddBulkPricingEventOps < ActiveRecord::Migration[4.2]
  def change
    execute("COMMIT;")
    execute "ALTER TYPE enum_event_operations ADD VALUE 'PRICING';"
    execute "ALTER TYPE enum_event_operations ADD VALUE 'CRA';"
    execute "ALTER TYPE enum_event_operations ADD VALUE 'AVM';"
    execute("BEGIN;")
  end
end
