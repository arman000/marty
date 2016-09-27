class CreateMartyPromiseMetadata < ActiveRecord::Migration
  def change(*args)
    # Giant hack to monkey patch connection so that we can create an
    # UNLOGGED table in PostgreSQL.
    class << @connection
      alias_method :old_execute, :execute
      define_method(:execute) { |sql, name=nil|
        old_execute(sql.sub('CREATE', 'CREATE UNLOGGED'), name)
      }
    end
    create_table :marty_promise_metadata do |t|
      t.integer  :promise_id, null: false
      t.string   :klass, null: false, limit: 255
      t.integer  :subject_id, null: false
      t.pg_enum  :enum_promise_operation, null: false
    end
    class << @connection
      alias_method :execute, :old_execute
    end
    add_index :marty_promise_metadata, [:klass, :subject_id,
                                        :enum_promise_operation],
              name: 'idx_klass_id_op'
  end
end
