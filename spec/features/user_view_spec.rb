require 'spec_helper'

feature 'under Sytem menu, User Management worflows', js: true do

  before(:all) do
    custom_selectors
  end

  def go_to_user_view
    press('System')
    press('User Management')
    expect(page).to have_content 'marty'
  end

  def go_to_user_view_backdoor
    sys_btn = first(:btn, 'System')
    if sys_btn
      sys_btn.click
      expect(page).not_to have_content 'User Management'
    end

    ensure_on("/#userView")
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
    go_to_user_view

    user_view = netzke_find('user_view')

    by 'add new user' do
      wait_for_ajax
      zoom_out
      press('New User')
      within(:gridpanel, 'add_window', match: :first) do
        press 'OK'
        m = find :msg
        expect(m).to have_content "Login can't be blank"
        expect(m).to have_content "Firstname can't be blank"
        expect(m).to have_content "Lastname can't be blank"

        fill_in('Login', with: 'test_login')
        fill_in('First Name', with: 'test_fname')
        fill_in('Last Name', with: 'test_lname')
        check 'Active'
        click_combobox 'Roles'
        select_combobox('Admin, Developer, User Manager, Viewer', 'Roles')
        press 'OK'
      end
    end

    and_by 'edit the added user' do
      wait_for_ajax
      expect(user_view.row_count).to eq 2
      user_view.select_row(2)
      press('Edit')

      within(:gridpanel, 'edit_window', match: :first) do
        fill_in('Login', with: 'new_login')
        fill_in('First Name', with: 'new_fname')
        fill_in('Last Name', with: 'new_lname')
        click_combobox 'Roles'
        select_combobox('User Manager, Viewer', 'Roles')
        press 'OK'
      end
    end

    and_by 'check row got edited' do
      wait_for_ajax
      user_view.validate_row_values(2,
                                    :login => 'new_login',
                                    :firstname => 'new_fname',
                                    :lastname => 'new_lname',
                                    :active => true,
                                    :roles => 'User Manager,Viewer')
    end

    and_by 'delete user fails' do
      user_view.select_row(2)
      press("Delete")
      press("Yes")
      expect(find(:msg)).to have_content("Users cannot be deleted - set " +
                                         "'Active' to false to disable the " +
                                         "account")
      user_view.select_row(1)
      press("Delete")
      press("Yes")
      expect(find(:msg)).to have_content("You cannot delete your own account")

      expect(user_view.row_count).to eq 2
    end
  end

  describe 'check user permissions & what buttons appear' do

    before(:all) do
      populate_test_users
    end

    it 'user manager has access' do
      log_in_as('user_manager1')
      go_to_user_view
      user_view = netzke_find('user_view')
      by 'check buttons' do
        find(:btn, 'New User', match: :first)
        zoom_out
        user_view.select_row(1)
        expect(btn_disabled?('New User')).to be_falsy
        expect(btn_disabled?('Edit')).to be_falsy
        expect(btn_disabled?('Delete')).to be_falsy
      end
    end

    it 'admin has access' do
      log_in_as('admin1')
      go_to_user_view
      user_view = netzke_find('user_view')
      by 'check buttons' do
        find(:btn, 'New User', match: :first)
        user_view.select_row(1)
        expect(btn_disabled?('New User')).to be_falsy
        expect(btn_disabled?('Edit')).to be_falsy
        expect(btn_disabled?('Delete')).to be_falsy
      end
    end

    it 'viewer denied access' do
      log_in_as('viewer1')
      go_to_user_view_backdoor

      user_view = netzke_find('user_view')
      by 'check buttons' do
        user_view.select_row(1)
        expect(page).not_to have_content('New User')
        expect(page).not_to have_content('Edit')
        expect(page).not_to have_content('Delete')
      end
    end

    it 'developer denied access' do
      log_in_as('dev1')
      go_to_user_view_backdoor

      user_view = netzke_find('user_view')
      by 'check buttons' do
        user_view.select_row(1)
        expect(page).not_to have_content('New User')
        expect(page).not_to have_content('Edit')
        expect(page).not_to have_content('Delete')
      end
    end
  end
end
