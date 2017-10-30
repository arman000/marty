class CreateDgPlv8V1Fns < ActiveRecord::Migration
  def change
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
