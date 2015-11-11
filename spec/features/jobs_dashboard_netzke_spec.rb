require 'spec_helper'

describe 'Jobs Dashboard - Netzke::Testing', type: :feature, js: true,
          capybara: true,  netzke_testing: true do
  it 'filters out usernames other than the one specified in the search box' do
    other_user = Marty::User.create(login: 'other',
                                    firstname: 'other',
                                    lastname: 'other',
                                    active: true)
    Marty::Promise.create title: "Test Job 1",
      user: Marty::User.find_by(login: 'marty'),
      cformat: 'csv',
      start_dt: Time.zone.now.to_time
    Marty::Promise.create title: "Test Job 2",
      user: other_user,
      cformat: 'csv',
      start_dt: Time.zone.now.to_time

    run_mocha_spec 'login', component: 'marty__auth_app'

    run_mocha_spec 'job_dashboard_live_search',
      component: 'Marty::PromiseView'
  end
end
