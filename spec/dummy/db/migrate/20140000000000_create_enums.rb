class CreateEnums < ActiveRecord::Migration
  def change
    values = Gemini::EnumState::VALUES
      str_values =
        values.map {|v| ActiveRecord::Base.connection.quote v}.join ','

      ActiveRecord::Base.schema_migrations_table_name

      # FIXME: very crude
      name = 'enum_states'

      execute <<-SQL
         CREATE TYPE #{name} AS ENUM (#{str_values});
      SQL
  end
end
