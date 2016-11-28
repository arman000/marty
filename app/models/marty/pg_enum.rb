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
  def self.extended(base)
    base.class_eval do
      const_set :GET_ALL_SIG, Marty::PgEnum::GET_ALL_SIG
    end
  end

  alias_method :find_by_name, :[]
end
