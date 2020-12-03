# Most of the code is tested in cron_job_spec.rb
describe 'Delorean Background Jobs' do
  let(:klass) { Marty::DeloreanBackgroundJob }

  before do
    Marty::Script.load_scripts(nil)
  end

  let!(:schedule) do
    Marty::BackgroundJob::Schedule.create!(
      job_class: klass.name,
      cron: '* * * * *',
      state: 'on',
      arguments: ['Jobs', 'TestJob1', 'perform']
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

  describe 'logs' do
    it 'logs success' do
      expect { run_job }.to change { Marty::BackgroundJob::Log.count }.by 1
      log = Marty::BackgroundJob::Log.find_by(job_class: klass.name)
      expect(log.error).to_not be_present
      expect(log.arguments).to eq ['Jobs', 'TestJob1', 'perform']
      expect(log.success?).to be true
      expect(klass.scheduled?(schedule_id: schedule.id)).to be true

      dj = schedule.reload.delayed_job
      expect(dj.schedule_id).to eq schedule.id
    end
  end
end
