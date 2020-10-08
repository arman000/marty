require 'benchmark/ips'

describe 'Caching Performance' do
  def check_cache(adapter:)
    ::Delorean::Cache.adapter = adapter
    ::Delorean::Cache.adapter.clear_all!

    expect(Math).to receive(:gamma).once.and_call_original
    2.times { Gemini::Helper.cached_factorial(10) }

    ::Delorean::Cache.adapter.clear_all!
  end

  let(:mcfly_adapter) do
    ::Marty::CacheAdapters::McflyRubyCache.new(size_per_class: 1000)
  end

  let(:redis_adapter) do
    ::Marty::CacheAdapters::Redis.new
  end

  let(:memory_and_redis_adapter) do
    ::Marty::CacheAdapters::MemoryAndRedis.new(
      size_per_class: 1000
    )
  end

  it 'cache works as expected' do
    check_cache(adapter: mcfly_adapter)
    check_cache(adapter: redis_adapter)
    check_cache(adapter: memory_and_redis_adapter)
  end

  it 'performs fast enough' do
    bm = Benchmark.ips do |x|
      x.config(
        suite: CacheSuite.new(
          adapters: [
            mcfly_adapter,
            redis_adapter,
            memory_and_redis_adapter
          ]
        )
      )

      x.report('redis_adapter') do
        ::Delorean::Cache.adapter = redis_adapter
        10.times { |n| Gemini::Helper.cached_factorial(n) }
      end

      x.report('memory_and_redis_adapter') do
        ::Delorean::Cache.adapter = memory_and_redis_adapter
        10.times { |n| Gemini::Helper.cached_factorial(n) }
      end

      x.report('mcfly_adapter') do
        ::Delorean::Cache.adapter = mcfly_adapter
        10.times { |n| Gemini::Helper.cached_factorial(n) }
      end

      x.compare!
    end

    h = bm.entries.each_with_object({}) do |e, hh|
      hh[e.label] = e.stats.central_tendency
    end

    memory_and_redis_vs_memory_factor = h['mcfly_adapter'] / h['memory_and_redis_adapter']
    redis_vs_memory_and_redis_factor = h['memory_and_redis_adapter'] / h['redis_adapter']

    expect(memory_and_redis_vs_memory_factor).to be < 3
    expect(redis_vs_memory_and_redis_factor).to be > 10
  end
end

class CacheSuite
  def initialize(adapters:)
    @adapters = adapters
  end

  def warming(*)
    clear_cache
  end

  def running(*)
    clear_cache
  end

  def warmup_stats(*); end

  def add_report(*); end

  private

  def clear_cache
    @adapters.map(&:clear_all!)
  end
end
