class CreateMartyEventOperationEnum < ActiveRecord::Migration
  def change
      execute <<-SQL
         CREATE TYPE enum_event_operations AS ENUM ('UNKNOWN')
      SQL
  end
end
