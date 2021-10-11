class CreateMartyDiagnosticReports < ActiveRecord::Migration[6.0]
  def change
    create_table :marty_diagnostic_reports do |t|
      t.string :name, null: false
    end
  end
end
