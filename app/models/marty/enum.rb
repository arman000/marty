module Marty::Enum
  def [](index)
    @LOOKUP_CACHE ||= {}

    index = index.to_s

    res = @LOOKUP_CACHE[index] ||= find_by_name(index)

    raise "no such #{name}: '#{index}'" unless res

    res
  end

  def clear_lookup_cache!
    @LOOKUP_CACHE.clear if @LOOKUP_CACHE
  end
end
