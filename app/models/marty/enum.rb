module Marty::Enum
  def [](index)
    @LOOKUP_CACHE ||= {}

    index = index.to_s

    res = @LOOKUP_CACHE[index] ||= find_by_name(index)

    return res if res

    raise "no such #{self.name}: '#{index}'"
  end

  def to_s
    # FIXME: hacky since not all enums have name
    self.name
  end

  def clear_lookup_cache!
    @LOOKUP_CACHE.clear if @LOOKUP_CACHE
  end
end
