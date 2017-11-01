class IncreaseApiLogErrorSize < ActiveRecord::Migration
  def change
    execute("alter table marty_api_logs alter column error type text")
  end
end
