class AddUserRefToAwsObjects < ActiveRecord::Migration[4.2]
  def change
    add_reference :marty_aws_objects, :marty_user, index: true
  end
end
