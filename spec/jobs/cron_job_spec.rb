require 'spec_helper'

describe 'Cron jobs' do
  let(:klass) { TestFailingJob }

  let!(:schedule) do
    Marty::BackgroundJob::Schedule.create!(
      job_class: klass.name,
      cron: '* * * * *',
      state: 'on',
      arguments: []
    ).tap do |job|
      Marty::BackgroundJob::UpdateSchedule.call(
        id: job.id,
        job_class: job.job_class,
      )

      dj = job.delayed_job
      dj.update!(run_at: 1.minute.ago)
    end
  end

  def run_job
    expect(schedule.delayed_job).to be_present
    expect(Delayed::Job.count).to eq 1
    worker = Delayed::Worker.new
    worker.work_off
  end

  describe 'when delayed_job record is deleted during the execution' do
    describe 'after failure' do
      context 'schedule is on' do
        before do
          run_job
        end

        it 'job is recreated' do
          expect(klass.scheduled?(schedule_id: schedule.id)).to be true
          expect(schedule.delayed_job).to be_present
        end
      end

      context 'schedule is off' do
        before do
          schedule.update!(state: :off)
          run_job
        end

        it 'job is not recreated' do
          expect(klass.scheduled?(schedule_id: schedule.id)).to be false
          expect(schedule.reload.delayed_job).to_not be_present
        end
      end
    end

    describe 'after success' do
      before do
        allow(klass).to receive(:trigger_failure).and_return(nil)
        run_job
      end

      it 'job is not recreated' do
        expect(klass.scheduled?(schedule_id: schedule.id)).to be false
        expect(schedule.reload.delayed_job).to_not be_present
      end
    end
  end

  describe 'logs' do
    before do
      allow(klass).to receive(:trigger_destroy).and_return(nil)
    end

    it 'logs failure' do
      expect { run_job }.to change { Marty::BackgroundJob::Log.count }.by 1
      log = Marty::BackgroundJob::Log.find_by(job_class: klass.name)
      expect(log.error).to be_present
      expect(log.failure?).to be true
      expect(klass.scheduled?(schedule_id: schedule.id)).to be true
    end

    it 'logs success' do
      allow(klass).to receive(:trigger_failure).and_return(nil)

      expect { run_job }.to change { Marty::BackgroundJob::Log.count }.by 1
      log = Marty::BackgroundJob::Log.find_by(job_class: klass.name)
      expect(log.error).to_not be_present
      expect(log.success?).to be true
      expect(klass.scheduled?(schedule_id: schedule.id)).to be true

      dj = schedule.reload.delayed_job
      expect(dj.schedule_id).to eq schedule.id
    end
  end
end
