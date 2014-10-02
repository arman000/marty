class AddUserRolesToImportTypes < ActiveRecord::Migration
  include Marty::Migrations

  def change
    change_table :marty_import_types do |t|
      t.references :role
    end

    add_fk :import_types, :roles
  end
end
