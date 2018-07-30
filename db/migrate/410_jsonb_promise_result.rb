class JsonbPromiseResult < ActiveRecord::Migration[5.1]
  def change
    table = :marty_promises

    execute "delete from #{table}"

    change_column table, :result, :jsonb, using: 'result::text::jsonb'
  end
end
