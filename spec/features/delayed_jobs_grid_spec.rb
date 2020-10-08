feature 'Delayed Jobs Dashboard', js: true do
  before do
    Delayed::Job.delete_all
    populate_test_users
  end

  context 'as dev' do
    before do
      log_in_as('dev1')
      wait_for_ajax
      press('System')
      press('Background Jobs')
      press('Schedule Jobs Dashboard')
      wait_for_ajax
    end

    it 'access denied' do
      expect(page).to_not have_content 'Schedule Jobs Dashboard'
    end
  end

  context 'as admin' do
    let(:jobs_view) { netzke_find('delayed_jobs_grid') }

    let!(:schedule) do
      ['TestJob', 'Test2Job', 'TestFailingJob'].each do |klass_name|
        Marty::BackgroundJob::Schedule.create(
          job_class: klass_name,
          cron: '0 0 * * *',
          state: 'on',
          arguments: []
        ).tap do |job|
          Marty::BackgroundJob::UpdateSchedule.call(
            id: job.id,
            job_class: job.job_class,
          )
        end
      end
    end

    let(:time1) { 10.hours.ago }

    let(:time2) { 20.hours.ago }

    before do
      @djs = Delayed::Job.all
      @djs.first.update!(locked_at: time1)
      @djs.last.update!(locked_at: time2)

      log_in_as('admin1')
      wait_for_ajax
      press('System')
      press('Background Jobs')
      press('Delayed Jobs Dashboard')

      wait_for_ajax

      expect(page).to have_content 'Delayed Jobs Dashboard'
    end

    it 'shows delayed jobs' do
      expect(jobs_view.row_count).to eq @djs.size
      expect(jobs_view.row_count).to eq 3
      locked_at = jobs_view.get_col_vals('locked_at', 3, 0, false).map do |str|
        next unless str

        Time.zone.parse(str).to_s
      end

      expect(locked_at).to eq(
        [
          time1.to_s,
          time2.to_s,
          nil
        ]
      )
    end
  end
end
