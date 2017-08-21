class CreateVersions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :versions do |t|
      t.string   :item_type, null: false, limit: 255
      t.integer  :item_id,   null: false
      t.string   :event,     null: false, limit: 255
      t.string   :whodunnit, limit: 255
      t.text     :object
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]
  end

  def self.down
    remove_index :versions, [:item_type, :item_id]
    drop_table :versions
  end
end
