require Pathname.new(__FILE__).parent.to_s + '/post_run_logger'

module Marty; module RSpec; module PerformanceHelper
  include Marty::RSpec::PostRunLogger

  def calculate_baseline iterations
    Benchmark.measure do
      ActiveRecord::Base.uncached { (0...iterations).each { yield } }
    end
  end

  def compare_baseline baseline, timings, opts = {}
    result_time = timings.map(&:total).sum
    factor      = result_time / baseline.total

    lb = opts.delete(:lower_bound) || 1.5
    ub = opts.delete(:upper_bound) || 5.0

    post_run_log '  ' + '-' * 45,
                 '   baseline: %.2f, result: %.2f, factor: %.2f' %
                 [baseline.total, result_time, factor],
                 '  ' + '-' * 45

    expect(result_time).to be_between(baseline.total * lb, baseline.total * ub)
  end
end end end
