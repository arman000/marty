class AddActivityFlagToSimple < ActiveRecord::Migration[5.2]
  def up
    add_column :gemini_simples, :active, :boolean, null: false, default: false
    change_column_default :gemini_simples, :active, nil
  end

  def down
    remove_column :gemini_simples, :active
  end
end
