class AddPostingTypes < ActiveRecord::Migration[5.2]
  include Marty::Migrations

  disable_ddl_transaction!

  def up
    Marty::PostingType::VALUES += [
      'OTHER',
      'SNAPSHOT'
    ]

    update_enum(Marty::PostingType, 'do_not_override_prefix')
  end
end
