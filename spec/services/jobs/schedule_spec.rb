module Marty
  describe Jobs::Schedule do
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

      non_cron_job = Delayed::Job.create!(handler: 'Non cron job')

      dj = Delayed::Job.last
      dj.handler = dj.handler.gsub('TestJob', 'WrongTestJob')
      dj.save!

      described_class.call

      expect(TestJob.scheduled?(schedule_id: schedule.id)).to be false
      any_old_scheduled_jobs = Delayed::Job.where('handler ILIKE ?', '%WrongTestJob%').any?
      expect(any_old_scheduled_jobs).to be false

      non_cron_job = Delayed::Job.find_by(handler: 'Non cron job')
      expect(non_cron_job).to be_present
    end
  end
end
