class CreateMartyDiagnosticConfigurations < ActiveRecord::Migration[6.0]
  def change
    table_name = :marty_diagnostic_configurations
    create_table table_name do |t|
      t.string :name, null: false
      t.integer :timeout, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :report_id, null: true

      t.timestamps
    end

    add_index table_name, :name, unique: true
    add_foreign_key table_name, :marty_diagnostic_reports, column: :report_id, on_delete: :nullify
  end
end
