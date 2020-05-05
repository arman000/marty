# frozen_string_literal: true

module Marty
  module McflyHelper
    module DisableTriggers
      class << self
        def call(*tables)
          conn = ActiveRecord::Base.connection
          tables.each do |table_name|
            conn.execute("ALTER TABLE #{table_name} DISABLE TRIGGER USER;")
          end

          yield
        ensure
          tables.each do |table_name|
            conn.execute("ALTER TABLE #{table_name} ENABLE TRIGGER USER;")
          end
        end
      end
    end
  end
end
