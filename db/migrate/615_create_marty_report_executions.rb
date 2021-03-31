class CreateMartyReportExecutions < ActiveRecord::Migration[5.1]
  def change
    create_table :marty_report_executions do |t|
      t.text :report, null: false
      t.references :user, null: false
      t.timestamp :completed_at
      t.boolean :error, default: false
      t.timestamps
    end
  end
end
