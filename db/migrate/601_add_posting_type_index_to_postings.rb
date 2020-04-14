class AddPostingTypeIndexToPostings < ActiveRecord::Migration[5.1]
  include Marty::Migrations

  def change
    add_index :marty_postings, :posting_type
  end
end
