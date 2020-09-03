require 'spec_helper'

module Marty
  describe BackgroundJob::FetchMissingInScheduleCronJobs do
    before do
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = true

      schedule = Marty::BackgroundJob::Schedule.create!(
        job_class: 'TestJob',
        cron: '0 0 * * *',
        state: 'on'
      )

      Marty::Jobs::Schedule.call

      job = ::Sidekiq::Cron::Job.create(
        name: '10 - class: MissingJob, cron: 0 0 * * *',
        cron: '0 0 * * *',
        class: 'MissingJob'
      )
    end

    after do
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = false
    end

    it 'fetchs only jobs that have cron and are not present in the dashboard' do
      result = described_class.call
      expect(result.size).to eq 1
      expect(result.first.klass).to include('MissingJob')
    end
  end
end
