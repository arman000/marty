class CreateMartyPromiseOperationEnum < ActiveRecord::Migration
  def change
      execute <<-SQL
         CREATE TYPE enum_promise_operations AS ENUM ('UNKNOWN')
      SQL
  end
end
