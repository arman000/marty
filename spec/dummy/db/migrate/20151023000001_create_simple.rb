class CreateSimple < ActiveRecord::Migration[4.2]
  def up
    McflyMigration.new.create_table 'gemini_simples' do |t|
      t.string "some_name"
    end
    McflyMigration.new.add_sql 'gemini_simples', false
  end

  def down
    drop_table 'gemini_simples'
  end
end
