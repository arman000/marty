class CreateDgPlpgsqlV1Fns < ActiveRecord::Migration[4.2]
  def up
    marty_path = Gem.loaded_specs["marty"].full_gem_path
    Dir.glob("#{marty_path}/db/sql/*_v1.sql") do |f|
      connection.execute(File.read(f))
    end

    connection.execute('DROP FUNCTION IF EXISTS errinfo(err jsonb);')
  end

  def down
    connection.execute <<-SQL
      -- required to utilize plv8 extension
      CREATE EXTENSION IF NOT EXISTS plv8;
    SQL

    marty_path = Gem.loaded_specs["marty"].full_gem_path
    Dir.glob("#{marty_path}/db/js/*_v1.js") do |f|
      connection.execute(Marty::Migrations.get_plv8_migration(f))
    end
  end
end
