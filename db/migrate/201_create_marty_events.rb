class CreateMartyEvents < ActiveRecord::Migration[4.2]
  def change(*args)
    # Giant hack to monkey patch connection so that we can create an
    # UNLOGGED table in PostgreSQL.
    class << @connection
      alias_method :old_execute, :execute
      define_method(:execute) { |sql, name=nil|
        old_execute(sql.sub('CREATE', 'CREATE UNLOGGED'), name)
      }
    end
    create_table :marty_events do |t|
      t.integer  :promise_id, null: true
      t.string   :klass, null: false, limit: 255
      t.integer  :subject_id, null: false
      t.pg_enum  :enum_event_operation, null: false
      t.datetime :start_dt, null: true
      t.datetime :end_dt, null: true
      t.integer  :expire_secs, null: true
      t.string   :comment, null: true
    end
    class << @connection
      alias_method :execute, :old_execute
    end
    add_index :marty_events, [:klass, :subject_id,
                             :enum_event_operation],
              name: 'idx_klass_id_op'
    add_index :marty_events, [:klass, :subject_id],
              name: 'idx_klass_id'
  end
end
