require 'spec_helper'

module Marty
  describe Jobs::Schedule do
    before do
      Sidekiq::Cron::Job.destroy_all!
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = true
    end

    after do
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = false
    end

    let!(:schedule) do
      Marty::BackgroundJob::Schedule.create!(
        job_class: 'TestJob',
        arguments: [],
        cron: '0 0 * * *',
        state: 'on'
      )
    end

    it 'schedules jobs' do
      expect(TestJob.scheduled?(schedule_id: schedule.id)).to be false
      described_class.call
      expect(TestJob.scheduled?(schedule_id: schedule.id)).to be true
    end

    it 'deletes previously scheduled jobs' do
      described_class.call
      expect(TestJob.scheduled?(schedule_id: schedule.id)).to be true
      schedule.destroy!

      described_class.call

      expect(TestJob.scheduled?(schedule_id: schedule.id)).to be false

      any_old_scheduled_jobs = Sidekiq::Cron::Job.all.any? do |job|
        job.name.split(' ').first == schedule.id.to_s
      end

      expect(any_old_scheduled_jobs).to be false
    end
  end
end
