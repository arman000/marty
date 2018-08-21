class CreateMartyAwsObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_aws_objects do |t|
      t.datetime :created_dt,  null: false
      t.string   :client,      null: false
      t.string   :object_type, null: false
      t.jsonb     :value,      null: false
    end
  end
end
