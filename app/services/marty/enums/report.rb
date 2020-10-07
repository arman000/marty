module Marty
  module Enums
    module Report
      extend Delorean::Functions

      delorean_fn :call do
        ActiveRecord::Base.connection.execute(<<~SQL).to_a
          SELECT
          t.typname AS enum_name,
          e.enumlabel AS value
          FROM pg_type t
          JOIN pg_enum e ON t.oid = e.enumtypid
          JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        SQL
      end
    end
  end
end
