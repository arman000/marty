module Marty
  module EnumHelper
    def self.pg_enum?(klass:)
      return true if klass.is_a? Marty::PgEnum
      return true if Marty::PgEnum === klass
      return klass._pg_enum? if klass.respond_to?(:_pg_enum?)

      false
    end
  end
end
