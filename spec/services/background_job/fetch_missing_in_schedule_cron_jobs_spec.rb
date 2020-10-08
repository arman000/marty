module Marty
  describe BackgroundJob::FetchMissingInScheduleCronJobs do
    before do
      schedule = Marty::BackgroundJob::Schedule.create!(
        job_class: 'TestJob',
        cron: '0 0 * * *',
        state: 'on'
      )

      Marty::Jobs::Schedule.call

      dj = schedule.delayed_job

      schedule.delayed_job.dup.tap do |new_dj|
        new_dj.handler = new_dj.handler.gsub('TestJob', 'Test2Job')
        new_dj.schedule_id = nil
        new_dj.cron = nil
        new_dj.save!
      end

      schedule.delayed_job.dup.tap do |new_dj|
        new_dj.handler = new_dj.handler.gsub('TestJob', 'MissingJob')
        new_dj.schedule_id = nil
        new_dj.save!
      end
    end

    it 'fetchs only jobs that have cron and are not present in the dashboard' do
      result = described_class.call
      expect(result.size).to eq 1
      expect(result.first.handler).to include('MissingJob')
    end
  end
end
