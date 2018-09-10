class AddAwsAssociationToMartyApiAuth < ActiveRecord::Migration[4.2]
  def change
    #add_column :marty_aws_api_keys, :api_auth_id, :integer, null: false
    add_column :marty_api_auths, :aws_api_key_id, :integer, null: true
    #remove_column :marty_aws_api_keys, :value
  end
end
