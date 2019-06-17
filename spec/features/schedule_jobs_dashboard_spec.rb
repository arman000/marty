require 'spec_helper'

feature 'Schedule Jobs Dashboard', js: true do
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
    let(:schedule_view) { netzke_find('schedule_jobs_dashboard') }

    let!(:schedule) do
      Marty::BackgroundJob::Schedule.create(
        job_class: 'TestJob2',
        cron: '0 0 * * *',
        state: 'on'
      ).tap do |job|
        Marty::BackgroundJob::UpdateSchedule.call(
          id: job.id,
          job_class: job.job_class
        )
      end
    end

    before do
      expect(TestJob2.scheduled?).to be true

      log_in_as('admin1')
      wait_for_ajax
      press('System')
      press('Background Jobs')
      press('Schedule Jobs Dashboard')

      wait_for_ajax

      expect(page).to have_content 'Schedule Jobs Dashboard'
    end

    it 'creates new schedule' do
      expect(TestJob.scheduled?).to be false

      press('Add')

      fill_in('Job class', with: 'TestJob')
      fill_in('cron', with: '1 1 * * *')
      fill_in('state', with: 'on')

      press 'OK'
      wait_for_ajax

      find('.x-tool-refresh').click
      crons = schedule_view.get_col_vals('cron', 2, 0)

      expect(crons).to include('1 1 * * *')
      expect(crons).to include('0 0 * * *')

      expect(TestJob.scheduled?).to be true
      expect(TestJob.delayed_job.cron).to eq '1 1 * * *'

      expect(TestJob2.scheduled?).to be true
      expect(TestJob2.delayed_job.cron).to eq '0 0 * * *'
    end

    it 'deletes schedule' do
      find('.x-grid-item', text: 'TestJob2').click
      press 'Delete'
      press 'Yes'

      wait_for_ajax

      expect(TestJob2.scheduled?).to be false
    end

    it 'turns the schedule off' do
      find('.x-grid-item', text: 'TestJob2').click
      press 'Edit'
      fill_in('state', with: 'off')

      press 'OK'
      wait_for_ajax
      expect(TestJob2.scheduled?).to be false
    end

    it 'shows validation errors' do
      press('Add')

      fill_in('Job class', with: 'TestJob2')
      fill_in('state', with: 'on')
      fill_in('cron', with: '1')

      press 'OK'
      wait_for_ajax
      expect(page).to have_content('Job class has already been taken')
      expect(page).to have_content('Cron is invalid')
    end
  end
end
