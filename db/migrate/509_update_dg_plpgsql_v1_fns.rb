class UpdateDgPlpgsqlV1Fns < ActiveRecord::Migration[4.2]
  def up
    marty_path = Gem.loaded_specs["marty"].full_gem_path
    Dir.glob("#{marty_path}/db/sql/*_v1.sql") do |f|
      connection.execute(File.read(f))
    end
  end

  def down
    # Load functions once again
    up
  end
end
