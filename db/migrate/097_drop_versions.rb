class DropVersions < ActiveRecord::Migration
  def self.up
    drop_table :versions
  end

  def self.down
    announce("No-op on DropVersions.down")
  end
end
