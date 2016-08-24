module Marty::PgEnum
  def [](index)
    index = index.to_s

    raise "no such #{self.name}: '#{index}'" unless
      self::VALUES.include?(index)

    index
  end
end
