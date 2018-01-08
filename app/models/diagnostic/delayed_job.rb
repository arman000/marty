# DelayedJob is a unique diagnostic that creates a series of delayed jobs
# in the hopes that enough nodes will touch these jobs to determine
# if delayed job workers are running the latest application version
#
# `DELAYED_VER` environment variable should be set in the
# delayed jobs initializer.
#
class Diagnostic::DelayedJob < Diagnostic::Base
  self.aggregatable = false

  def self.generate
    raise 'DelayedJob cannot be called with local scope.' if scope == 'local'

    raise 'DELAYED_VER environment variable has not been initialized.' if
      ENV['DELAYED_VER'].nil?

    total_workers = delayed_worker_count

    raise 'No delayed jobs are running.' if total_workers.zero?

    # we will only iterate by half of the total delayed workers to avoid
    # excess use of delayed job time
    total_workers = (total_workers/2).zero? ? 1 : total_workers/2

    d_engine = Marty::ScriptSet.new.get_engine("Diagnostics")
    res = d_engine.
            evaluate('VersionDelay', 'result', {'count' => total_workers-1})

    # merge results, remove duplicates, and construct "aggregate" object
    res.each_with_object({}){
      |r, hash|
      hash[r[0]] ||= []
      hash[r[0]] << r[1]
    }.map {
      |node, result|

      versions = result.uniq
      status = versions.count == 1 && versions[0] == ENV['DELAYED_VER']

      {node => {'Version' => create_info(versions.join("\n"), status)}}
    }.reduce(:deep_merge)
  end

  def self.delayed_worker_count
    Diagnostic::Node.get_postgres_connections[Diagnostic::Database.db_name].
      count{|conn| conn['application_name'].include?('delayed_job')}
  end
end