# This migration comes from marty (originally 95)
require 'marty/migrations'

class CreateMartyTags < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    create_table :marty_tags do |t|
      t.string :name, null: false
      t.string :comment, null: false
    end

    add_mcfly_index :marty_tags, :name
  end

  def migrate(direction)
    super

    return unless direction == :up

    # hack to handle fresh migration where db hasn't been seeded
    Mcfly.whodunnit = {id: 1}

    unless Marty::Tag.find_by_name('DEV')
      tag            = Marty::Tag.new
      tag.comment    = '---'
      tag.created_dt = 'infinity'
      tag.save!
    end
  end
end
