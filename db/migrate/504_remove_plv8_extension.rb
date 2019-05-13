class RemovePlv8Extension < ActiveRecord::Migration[5.1]
  def up
    connection.execute <<-SQL
    DROP EXTENSION IF EXISTS plv8;
    SQL
  end

  def down
    connection.execute <<-SQL
    CREATE EXTENSION IF NOT EXISTS plv8;
    SQL
  end
end
