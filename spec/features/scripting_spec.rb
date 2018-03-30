require 'spec_helper'

feature 'under Applications menu, Scripting workflows', js: true do

  before(:all) do
    self.use_transactional_tests = false

    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
  end

  before(:each) do
    populate_test_users
    populate_test_scripts
  end

  after(:each) do
    restore_clean_db(@clean_file, false)
  end

  after(:all) do
    restore_clean_db(@clean_file)
    self.use_transactional_tests = true
  end

  def go_to_scripting
    press('Applications')
    press('Scripting')
  end

  def with_user(uname, &block)
    u = Marty::User.find_by_login(uname)
    begin
      old_u, Mcfly.whodunnit = Mcfly.whodunnit, u
      block.call(u)
    ensure
      Mcfly.whodunnit = old_u
    end
  end

  def populate_test_scripts
    lastid = nil

    with_user("dev2") {

      Marty::Script.
        load_script_bodies({
                             "A1" => "#1\n",
                             "A2" => "#2\n",
                             "A3" => "#3\n",
                             "A4" => "#4\n",
                             "A5" => "#5\n",
                           }, Date.today)

      # create 3 additional tags and modify A5 in the process
      (1..3).each { |i|
        body = Marty::Script.find_script("A5").body

        Marty::Script.
          load_script_bodies({
                               "A5" => body + "##{i}\n"
                             }, Date.today + i.minute)
      }
    }
  end

  it 'adding scripts and tags & ensure proper validations' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select DEV tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'add script' do
      press('New Script')
      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Name', with: 'Xyz')
        press('OK')
      end
    end

    and_by 'select the new script' do
      wait_for_ajax
      within(:gridpanel, 'script_grid', match: :first) do
        expect(script_grid.get_row_vals(6)).to netzke_include({:name=>"Xyz", :tag=>"DEV"})
        script_grid.select_row(6)
      end
    end

    and_by 'fill script body' do
      wait_for_ajax
      within(:gridpanel, 'script_form', match: :first) do
        set_field_value('###', '', 'body')
        press('Save')
      end
    end

    and_by 'new script body shows up' do
      expect(page).to have_content '###'
    end

    and_by 'add new tag' do
      press('New Tag')
      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Comment', with: 'This is my log')
        press('OK')
      end
    end

    and_by 'new tag shows up' do
      wait_for_ajax
      within(:gridpanel, 'tag_grid', match: :first) do
        expect(tag_grid.row_count).to eq 6
      end
    end

    and_by 'tag row 2 has 6 scripts' do
      tag_grid.select_row(2)
      wait_for_ajax
      expect(script_grid.row_count).to eq 6
    end

    and_by 'tag row 3 has 5 scripts' do
      tag_grid.select_row(3)
      wait_for_ajax
      expect(script_grid.row_count).to eq 5
    end
  end

  it 'add a script with invalid names, no scripts get added' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select DEV tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'add script with duplicate name' do
      press('New Script')
      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Name', with: 'A1')
        press('OK')
        expect(find(:msg)).to have_content 'Name - record must be unique'
      end
    end

    and_by 'add script with number name' do
      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Name', with: '123')
        press('OK')
        expect(find(:msg)).to have_content 'Name must be capitalized'
        press('Cancel')
      end
    end

    and_by 'no script got added' do
      wait_for_ajax
      expect(script_grid.row_count).to eq 5
    end
  end

  it 'has proper access controls (viewer/anon users)' do
    log_in_as('anon')
    # no nav buttons available, but check direct access
    ensure_on('/#scripting')

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'nothing should work & log out' do
      wait_for_ajax
      expect(script_grid.row_count).to eq 0
      expect(tag_grid.row_count).to eq 0
      expect(btn_disabled?('New Script')).to be_truthy
      expect(btn_disabled?('New Tag')).to be_truthy
      log_out
    end

    and_by 'log in as viewer1' do
      log_in_as('viewer1')
      go_to_scripting
    end

    and_by 'viewable but cannot add scripts or tags' do
      wait_for_ajax
      expect(script_grid.row_count).to eq 5
      tag_grid.select_row(1)
      wait_for_ajax
      expect(btn_disabled?('New Script')).to be_truthy
      expect(btn_disabled?('New Tag')).to be_truthy
      tag_grid.select_row(4)
      wait_for_ajax
      expect(script_grid.row_count).to eq 5
      expect(btn_disabled?('Save')).to be_truthy
    end
  end

  it 'selects different scripts & shows correct details' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')


    by 'select tag row 2' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'select script row 5' do
      wait_for_ajax
      script_grid.select_row(5)
    end

    and_by 'form displays correct body' do
      wait_for_ajax
      expect(page).to have_content "#5\n#1\n#2\n#3\n"
    end

    and_by 'select different tag' do
      tag_grid.select_row(4)
    end

    and_by 'select script row 5' do
      wait_for_ajax
      script_grid.select_row(5)
    end

    and_by 'form displays updated body' do
      wait_for_ajax
      expect(page).to have_content "#5\n#1\n"
    end
  end

  it 'saving an edited script' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select DEV tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'select script row 5' do
      wait_for_ajax
      script_grid.select_row(5)
    end

    and_by 'edit script form body' do
      wait_for_ajax
      within(:gridpanel, 'script_form', match: :first) do
        set_field_value('#123\n#456\n', '', 'body')
        press('Save')
      end
    end

    and_by 'new script does not exist in old tag' do
      wait_for_ajax
      tag_grid.select_row(2)
      # FIX?  selection change required to refresh script form
      script_grid.select_row(1)
      script_grid.select_row(5)
      wait_for_ajax
      expect(page).not_to have_content "#123\n#456\n"
      script_grid.select_row(1)
    end

    and_by 'make new tag' do
      press('New Tag')
      within(:gridpanel, 'add_window', match: :first) do
        fill_in('Comment', with: 'ABCD')
        press('OK')
      end
    end

    and_by 'new tag contains new script' do
      wait_for_ajax
      tag_grid.select_row(2)
      wait_for_ajax
      script_grid.select_row(5)
      expect(page).to have_content "#123\n#456\n"
      expect(tag_grid.get_row_vals(2)).to netzke_include({:comment=>"ABCD"})
    end
  end

  it 'checking in without changes does not modify history' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select DEV tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'select script row 1' do
      wait_for_ajax
      script_grid.select_row(1)
    end

    and_by 'save without changes' do
      press('Save')
      expect(find(:msg)).to have_content 'no save needed'
    end
  end

  it 'deletes a script' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select DEV tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'delete script' do
      script_grid.select_row(1)
      press('Delete Script')
      find(:xpath, "//div[text()='Confirmation']", wait: 5)
      press('Yes')
    end

    and_by 'script is gone' do
      wait_for_ready
      expect(script_grid.row_count).to eq 4
    end
  end

  it 'prevents non-dev from deleting' do
    log_in_as('viewer1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    and_by 'delete script' do
      script_grid.select_row(1)
      press('Delete Script')
      find(:xpath, "//div[text()='Confirmation']", wait: 5)
      press('Yes')
    end

    and_by 'script is gone' do
      expect(find(:msg)).to have_content 'Permission Denied'
    end
  end

  it 'only allows delete on DEV tag' do
    log_in_as('dev1')
    go_to_scripting

    script_grid = netzke_find('script_grid')
    tag_grid = netzke_find('tag_grid')

    by 'select not DEV tag' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'delete script' do
      wait_for_ajax
      script_grid.select_row(1)
      press('Delete Script')
      find(:xpath, "//div[text()='Confirmation']", wait: 5)
      press('Yes')
    end

    and_by 'delete did not work' do
       expect(find(:msg)).to have_content 'Can only delete in DEV tag'
    end
  end
end
