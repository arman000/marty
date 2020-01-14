class Marty::DelayedJobController < ApplicationController
  # FIXME: We probably don't need this endpoint anymore.
  # It's not used by lambda
  def trigger
    work_off_job if delayed_job.present?
    render json: { status: :ok }, status: :ok
  end

  private

  def delayed_job
    return if params['id'].blank?

    @delayed_job ||= ::Delayed::Job.find_by(id: params['id'])
  end

  def work_off_job
    return if delayed_job.locked_at.present?

    ::Delayed::Job.find_by(id: delayed_job.id)&.update!(
      locked_at: ::Delayed::Job.db_time_now, locked_by: 'Lambda'
    )

    w = ::Delayed::Worker.new
    w.run(delayed_job)
  end
end
