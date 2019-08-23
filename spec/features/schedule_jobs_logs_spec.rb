require 'spec_helper'

feature 'Schedule Jobs Logs', js: true do
  before do
    populate_test_users
  end

  context 'as dev' do
    before do
      log_in_as('dev1')
      wait_for_ajax
      press('System')
      press('Background Jobs')
      press("Schedule Job's Logs")
      wait_for_ajax
    end

    it 'access denied' do
      expect(page).to_not have_content "Schedule Job's Logs"
    end
  end

  context 'as admin' do
    let(:grid_view) { netzke_find('schedule_jobs_logs') }

    let!(:create_logs) do
      Marty::BackgroundJob::Log.create!(
        job_class: 'TestJob2',
        status: :success,
        created_at: 3.minutes.ago
      )

      Marty::BackgroundJob::Log.create!(
        job_class: 'TestJob2',
        status: :failure,
        error: { message: 'Test error message', backtrace: '' },
        created_at: 2.minutes.ago
      )

      Marty::BackgroundJob::Log.create!(
        job_class: 'Another Test Job',
        status: :success,
        created_at: 1.minute.ago
      )
    end

    before do
      log_in_as('admin1')
      wait_for_ajax
      press('System')
      press('Background Jobs')
      press("Schedule Job's Logs")

      wait_for_ajax

      expect(page).to have_content "Scheduled Job's Logs"
    end

    it 'shows logs' do
      class_names = grid_view.get_col_vals('job_class', 3, 0)

      expect(class_names.uniq).to eq ['Another Test Job', 'TestJob2']

      statuses = grid_view.get_col_vals('status', 3, 0)
      expect(statuses).to eq ['success', 'failure', 'success']
    end

    it 'deletes log' do
      find('.x-grid-item', text: 'Another Test Job').click
      press 'Delete'
      press 'Yes'

      wait_for_ajax

      class_names = grid_view.get_col_vals('job_class', 2, 0)
      expect(class_names.uniq).to eq ['TestJob2']
    end

    it 'deletes all logs' do
      press 'Delete all'
      press 'Yes'

      wait_for_ajax

      expect(grid_view.row_count).to eq 0
      expect(Marty::BackgroundJob::Log.count).to eq 0
    end

    it 'marks as ignored in diags' do
      expect(Marty::BackgroundJob::Log.failure_ignore.count).to eq 0
      find('.x-grid-item', text: 'Test error').click
      press 'Ignore in diag'
      press 'Yes'

      wait_for_ajax

      statuses = grid_view.get_col_vals('status', 3, 0)
      expect(statuses).to eq ['success', 'failure_ignore', 'success']
      expect(Marty::BackgroundJob::Log.failure_ignore.count).to eq 1
    end
  end
end
