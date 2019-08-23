module Marty::Diagnostic; class ScheduledJobs < Base
  self.aggregatable = false

  diagnostic_fn do
    logs = ::Marty::BackgroundJob::Log.
      order(job_class: :asc, status: :desc, id: :desc).
      select('DISTINCT ON(job_class, status) *').
      where.not(status: :failure_ignore).
      first(1000)

    failed_total = ::Marty::BackgroundJob::Log.where(status: :failure).count

    result = logs.each_with_object({}) do |log, hash|
      message = "Status: #{log.status}, last_run: #{log.created_at}"
      message = "#{message}, error: #{log.error}" if log.failure?
      hash[log.job_class] = log.success? ? message : error(message)
    end

    result['Failures total'] = 0
    result['Failures total'] = error(failed_total) if failed_total != 0

    result
  end
end
end
