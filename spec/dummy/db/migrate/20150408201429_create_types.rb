class CreateTypes < ActiveRecord::Migration[4.2]
  def up
    create_table 'gemini_amortization_types' do |t|
      t.string "name", null: false
    end

    create_table 'gemini_mortgage_types' do |t|
      t.string "name", null: false
    end

    create_table 'gemini_streamline_types' do |t|
      t.string "name", null: false
    end
  end

  def down
    drop_table 'gemini_amortization_types'
    drop_table 'gemini_mortgage_types'
    drop_table 'gemini_streamline_types'
  end
end
