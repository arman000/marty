class DropMartyApiLogs < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :marty_api_logs
  end

  def self.down
    announce("No-op on DropMartyApiLogs.down")
  end
end
