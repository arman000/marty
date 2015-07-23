require 'spec_helper'

describe 'Jobs Dashboard - Netzke::Testing', type: :feature, js: true do
  it 'filters out usernames other than the one specified in the search box' do
    other_user = Marty::User.create(login: 'other',
                                    firstname: 'other',
                                    lastname: 'other',
                                    active: true)
    Marty::Promise.create title: "Test Job 1",
      user: Marty::User.find_by(login: 'marty'),
      cformat: 'csv',
      start_dt: Time.now
    Marty::Promise.create title: "Test Job 2",
      user: other_user,
      cformat: 'csv',
      start_dt: Time.now

    Rails.configuration.marty.auth_spec_mode = true
    run_mocha_spec 'login', component: 'Marty::AuthApp'

    run_mocha_spec 'job_dashboard_live_search',
      component: 'Marty::PromiseViewTwo'
  end
end
