require 'spec_helper'

module Marty
  describe BackgroundJob::UpdateSchedule do
    before(:each) do
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = true
      Sidekiq::Cron::Job.destroy_all!

      @schedule = Marty::BackgroundJob::Schedule.create!(
        job_class: 'TestJob',
        cron: '0 0 * * *',
        state: 'on'
      )
      Marty::Jobs::Schedule.call
    end

    after do
      Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = false
    end

    context '.call' do
      let(:new_cron) { '1 0 * * *' }

      it 'updates a Sidekiq::Cron::Job cron when cron is updated to on' do
        @schedule.update(cron: new_cron)
        described_class.call(
          id: @schedule.id,
          job_class: @schedule.job_class
        )
        expect(@schedule.reload.sidekiq_job.cron).to eq(new_cron)
      end

      it 'does not update Sidekiq::Cron::Job cron when cron is updated to off' do
        @schedule.update(cron: new_cron, state: 'off')

        described_class.call(
          id: @schedule.id,
          job_class: @schedule.job_class
        )

        expect(@schedule.reload.sidekiq_job).to be_nil
      end
    end
  end
end
