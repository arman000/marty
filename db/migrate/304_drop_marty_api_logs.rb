class DropMartyApiLogs < ActiveRecord::Migration
  def self.up
    drop_table :marty_api_logs
  end

  def self.down
    announce("No-op on DropMartyApiLogs.down")
  end
end
