class AddPromiseTypeEnum < ActiveRecord::Migration[4.2]
  def up
    values = Marty::EnumPromiseType::VALUES
    str_values = values.map {|v| ActiveRecord::Base.connection.quote v}.join ','
    execute <<-SQL
       CREATE TYPE marty_promise_types AS ENUM (#{str_values})
    SQL
  end

  def down
    execute <<-SQL
       DROP TYPE marty_promise_types
    SQL
  end
end
