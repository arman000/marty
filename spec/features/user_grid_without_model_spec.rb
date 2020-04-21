require 'spec_helper'

feature 'under System menu, User Management worflows', js: true do
  def go_to_user_view
    press('Pricing Config.')
    press('User Grid Without Model')
    expect(page).to have_content 'User Grid Without Model'
  end

  # Checkbox Helpers
  def check name, val = true
    page.driver.browser.execute_script <<-JS
      var poc = Ext.ComponentQuery.query("checkbox[fieldLabel='#{name}']")[0];
      poc = poc || Ext.ComponentQuery.query("checkbox[name='#{name}']")[0];
      poc.setValue(#{val});
    JS
  end

  def uncheck name
    check(name, false)
  end

  it 'marty user can add/edit but not delete users' do
    log_in_as('marty')
    wait_for_ajax

    go_to_user_view

    user_view = netzke_find('user_grid_without_model')

    by 'add new user' do
      wait_for_ajax
      press('Add in form')
      within(:gridpanel, 'add_window', match: :first) do
        press 'OK'
        m = find :msg
        expect(m).to have_content "Login can't be blank"
        expect(m).to have_content "Firstname can't be blank"
        expect(m).to have_content "Lastname can't be blank"

        fill_in('Login', with: 'test_login')
        fill_in('Firstname', with: 'test_fname')
        fill_in('Lastname', with: 'test_lname')
        check 'Active'
        press 'OK'
      end
    end

    and_by 'edit the added user' do
      wait_for_ajax
      expect(user_view.row_count).to eq 2
      user_view.select_row(2)
      press('Edit in form')

      within(:gridpanel, 'edit_window', match: :first) do
        fill_in('Login', with: 'new_login')
        fill_in('Firstname', with: 'new_fname')
        fill_in('Lastname', with: 'new_lname')
        press 'OK'
      end
    end

    and_by 'check row got edited' do
      wait_for_ajax
      r2 = user_view.get_row_vals(2)
      expect(user_view.get_row_vals(2)).to netzke_include(
        login: 'new_login',
        firstname: 'new_fname',
        lastname: 'new_lname',
        active: true,
      )
    end

    and_by 'delete user fails' do
      user_view.select_row(2)
      press('Delete')
      press('Yes')
      expect(find(:msg)).to have_content('Users cannot be deleted - set ' \
                                         "'Active' to false to disable the " \
                                         'account')
      user_view.select_row(1)
      press('Delete')
      press('Yes')
      expect(find(:msg)).to have_content('You cannot delete your own account')

      expect(user_view.row_count).to eq 2
    end

    and_by 'edits user inline' do
      expect(user_view.row_count).to eq 2
      user_view.select_row(2)

      row = user_view.all('.x-grid-row').last
      login = row.all('.x-grid-cell')[0]
      fname = row.all('.x-grid-cell')[1]

      login.double_click
      login.fill_in 'login', with: 'marty'

      press('Apply')

      wait_for_ajax

      expect(find(:msg)).to have_content('Login has already been taken')

      login.double_click
      login.fill_in 'login', with: 'new_login2'

      fname.double_click
      fname.fill_in 'firstname', with: 'new_fname2'

      press('Apply')
      wait_for_ajax

      r2 = user_view.get_row_vals(2)

      expect(user_view.get_row_vals(2)).to netzke_include(
        login: 'new_login2',
        firstname: 'new_fname2',
        lastname: 'new_lname',
        active: true,
      )
    end

    and_by 'adds user inline' do
      expect(user_view.row_count).to eq 2
      press('Add')

      row = user_view.all('.x-grid-row').last
      login = row.all('.x-grid-cell')[0]
      fname = row.all('.x-grid-cell')[1]
      lname = row.all('.x-grid-cell')[2]

      login.fill_in 'login', with: 'new_login3'

      fname.double_click
      fname.fill_in 'firstname', with: 'new_fname3'

      lname.double_click
      lname.fill_in 'lastname', with: 'new_lname3'

      press('Apply')
      wait_for_ajax

      expect(Marty::User.count).to eq 3
      expect(user_view.row_count).to eq 3
      expect(user_view.get_row_vals(3)).to netzke_include(
        login: 'new_login3',
        firstname: 'new_fname3',
        lastname: 'new_lname3',
        active: false,
      )
    end
  end
end
