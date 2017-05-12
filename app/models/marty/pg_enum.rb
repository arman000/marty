module Marty::PgEnum

  def [](index)
    index = index.to_s

    raise "no such #{self.name}: '#{index}'" unless
      self::VALUES.include?(index)

    StringEnum.new(index)
  end

  def get_all
    self::VALUES.map { |v| StringEnum.new(v) }
  end

  GET_ALL_SIG = [0, 0]
  LOOKUP_SIG = [1, 1]
  FIND_BY_NAME_SIG = [1, 1]
  def self.extended(base)
    base.class_eval do
      const_set :GET_ALL_SIG, Marty::PgEnum::GET_ALL_SIG
      const_set :LOOKUP_SIG, Marty::PgEnum::LOOKUP_SIG
      const_set :FIND_BY_NAME_SIG, Marty::PgEnum::FIND_BY_NAME_SIG
    end
  end

  def seed
  end

  alias_method :find_by_name, :[]
  alias_method :lookup, :[]
end
