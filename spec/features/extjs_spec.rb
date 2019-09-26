require 'spec_helper'

feature 'on grid cells', js: true do
  def go_to_user_view
    press('System')
    press('User Management')
    wait_for_ajax
  end

  def go_to_data_grid_view
    find(:xpath, "//a[contains(., 'Applications')]").click
    press('Data Grids')
    wait_for_ajax
  end

  let(:uv) { netzke_find('user_view') }

  before do
    Mcfly.whodunnit = Marty::User.find_by_login('marty')
  end

  it 'grid cells should encode html' do
    log_in_as('marty')
    go_to_user_view

    by 'add user with html in field' do
      wait_for_ajax
      press('New User')

      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Login', with: 'extjs_test_login')
        fill_in('First Name', with: 'test_fname')
        fill_in('Last Name',
                with:
                "<b class='test class' onclick='alert()'>test text</b>"
               )
        press 'Ok'
      end
    end

    and_by 'check html rendering' do
      # negative test
      expect do
        find(:xpath, "//b[contains(@class, 'test class')]")
      end.to raise_error(Capybara::ElementNotFound)

      # positive test
      find('tr', text: 'extjs_test_login').should have_content(
        "<b class='test class' onclick='alert()'>test text</b>"
      )

      # positive test
      find(:xpath, "//td[contains(., 'test text')]").click
      go_to_data_grid_view
      expect(URI.parse(current_url).fragment).to eq 'data_grid_user_view'
    end
  end
end
