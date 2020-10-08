module Marty
  describe BackgroundJob::UpdateSchedule do
    before(:each) do
      @schedule = Marty::BackgroundJob::Schedule.create!(
        job_class: 'TestJob',
        cron: '0 0 * * *',
        state: 'on'
      )
      Marty::Jobs::Schedule.call
    end
    context '.call' do
      let(:new_cron) { '1 0 * * *' }
      it 'updates a Delayed::Job cron when cron is updated to on' do
        @schedule.update(cron: new_cron)
        described_class.call(
          id: @schedule.id,
          job_class: @schedule.job_class
        )
        expect(@schedule.reload.delayed_job.cron).to eq(new_cron)
      end

      it 'does not update Delayed::Job cron when cron is updated to off' do
        @schedule.update(cron: new_cron, state: 'off')
        described_class.call(
          id: @schedule.id,
          job_class: @schedule.job_class
        )
        expect(@schedule.reload.delayed_job).to be_nil
      end
    end
  end
end
