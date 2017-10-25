class CreateDgPlv8V1Fns < ActiveRecord::Migration
  def change
    connection.execute <<-SQL
      -- required to utilize plv8 extension
      CREATE EXTENSION IF NOT EXISTS plv8;
    SQL
    marty_path = Gem.loaded_specs["marty"].full_gem_path
    Dir.glob("#{marty_path}/db/plv8/*_v1.plv8") do |f|
      lines=File.read(f)
      connection.execute(lines)
    end
  end
end
