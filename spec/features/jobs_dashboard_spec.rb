require 'spec_helper'

describe 'Jobs Dashboard', type: :feature, js: true, capybara: true do
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

    visit marty_components_path('Marty::AuthApp')
    find(ext_button_id('Sign in')).click
    fill_in 'Login', with: 'marty'
    fill_in 'Password', with: 'marty'
    find(:xpath, '//a[contains(., "OK")]').click
    expect(page).to have_content('marty marty')

    visit marty_components_path('Marty::PromiseView')
    page_title = I18n.t("jobs.promise_view")
    expect(page).to have_content(page_title)
    expect(tree_row_count(page_title)).to eq(2)

    fill_in "live_search_text", with: 'marty'
    sleep 1
    expect(tree_row_count(page_title)).to eq(1)
  end

  def ext_button_id title
    id = page.evaluate_script("Ext.ComponentQuery.query(\"button{isVisible(true)}[text='#{title}']\")[0].id")
    "##{id}"
  end

  def tree_row_count name
    page.evaluate_script("Ext.ComponentQuery.query('treepanel[title=\"#{name}\"]')[0].getStore().getCount()")
  end
end
