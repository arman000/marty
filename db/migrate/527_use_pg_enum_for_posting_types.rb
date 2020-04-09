class UsePgEnumForPostingTypes < ActiveRecord::Migration[5.1]
  include Marty::Migrations

  def up
    disable_triggers 'marty_postings' do
      posting_types = Marty::PostingType.all.to_a
      rename_table :marty_posting_types, :marty_posting_types_old

      new_enum(Marty::PostingType, 'keep_marty_prefix_here')
      add_column :marty_postings, :posting_type, :marty_posting_types

      posting_types.each do |posting_type|
        Marty::Posting.where(posting_type_id: posting_type.id).update_all(posting_type: posting_type.name)
      end

      update_views_up
      remove_column :marty_postings, :posting_type_id

      drop_table :marty_posting_types_old
      change_column_null :marty_postings, :posting_type, false
    end
  end

  def down
    disable_triggers 'marty_postings' do
      posting_types = Marty::Posting.pluck(:posting_type).uniq

      execute <<-SQL
        ALTER TYPE marty_posting_types RENAME TO marty_posting_types_old;
      SQL

      create_table :marty_posting_types do |t|
        t.string :name, null: false, limit: 255
      end

      add_column :marty_postings, :posting_type_id, :integer

      posting_types.each do |posting_type|
        new_record = Marty::PostingType.create!(name: posting_type)
        Marty::Posting.where('posting_type = ?', posting_type).update_all(posting_type_id: new_record.id)
      end

      update_views_down
      remove_column :marty_postings, :posting_type

      execute <<-SQL
        DROP TYPE marty_posting_types_old
      SQL

      change_column_null :marty_postings, :posting_type_id, false
    end
  end

  def update_views_up
    # Add your code here
  end

  def update_views_down
    # Add your code here
  end
end
