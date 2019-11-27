class CreateMartyEventOperationEnum < ActiveRecord::Migration[4.2]
  def change
      values = Marty::EnumEventOperation.values
      str_values = values.map {|v| ActiveRecord::Base.connection.quote v}.join ','
      execute <<-SQL
         CREATE TYPE enum_event_operations AS ENUM (#{str_values})
      SQL
  end
end
