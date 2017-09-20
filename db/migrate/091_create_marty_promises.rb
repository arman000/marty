class CreateMartyPromises < ActiveRecord::Migration[4.2]
  include Marty::Migrations

  def change(*args)
    # Giant hack to monkey patch connection so that we can create an
    # UNLOGGED table in PostgreSQL.
    class << @connection
      alias_method :old_execute, :execute
      define_method(:execute) { |sql, name=nil|
        old_execute(sql.sub('CREATE', 'CREATE UNLOGGED'), name)
      }
    end

    create_table :marty_promises do |t|
      t.string     :title,   null: false, limit: 255
      t.references :user
      t.string     :cformat, limit: 255
      t.references :parent
      t.references :job
      t.boolean    :status
      t.binary     :result
      t.datetime   :start_dt
      t.datetime   :end_dt
    end

    class << @connection
      alias_method :execute, :old_execute
    end

    add_index :marty_promises, :parent_id
    add_fk :promises, :promises, column: 'parent_id'
    add_fk :promises, :users
  end
end
