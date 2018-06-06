class CreateMartyAwsApiKey < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_aws_api_keys do |t|
      t.timestamps
      t.string :aid,               null: false
      t.string :api_id,            null: false
      t.string :api_usage_plan_id, null: false
      t.string :name,              null: false
      t.string :value,             null: false
      t.string :username,          null: true
      t.string :email,             null: true
    end
  end
end
