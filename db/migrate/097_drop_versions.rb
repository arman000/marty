class DropVersions < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :versions
  end

  def self.down
    announce("No-op on DropVersions.down")
  end
end
