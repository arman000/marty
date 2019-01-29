module Marty::PgEnum
  def [](i0, i1 = nil)
    # if i1 is provided, then i0 is a pt and we ignore it.
    index = (i1 || i0).to_s

    raise "no such #{name}: '#{index}'" unless
      self::VALUES.include?(index)

    index
  end

  def get_all(pt = nil)
    self::VALUES.map(&:to_s)
  end

  def self.extended(base)
    base.class_eval do
      const_set :GET_ALL_SIG,      [0, 1]
      const_set :LOOKUP_SIG,       [1, 2]
      const_set :FIND_BY_NAME_SIG, [1, 2]
    end
  end

  def seed
  end

  alias_method :find_by_name, :[]
  alias_method :lookup, :[]
end
