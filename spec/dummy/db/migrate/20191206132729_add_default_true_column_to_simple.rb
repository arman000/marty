class AddDefaultTrueColumnToSimple < ActiveRecord::Migration[5.2]
  def up
    add_column :gemini_simples, :default_true, :boolean, null: false, default: true
  end

  def down
    remove_column :gemini_simples, :default_true
  end
end
