require 'spec_helper'

feature 'Posting workflows', js: true do

  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    populate_test_users

    custom_selectors

    monkey_patch_new_posting_form
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  def monkey_patch_new_posting_form
    # presently, Gemini displays similar monkeypatching behavior.
    # consider coming up with a proper fix...
    Marty::NewPostingForm.has_marty_permissions(BASE: :admin)
  end

  it 'create posting and select it' do
    log_in_as('admin1')

    posting_grid = netzke_find('posting_grid')

    by 'bring up new posting form' do
      wait_for_ajax
      press('Postings')
      press('New Posting')
    end

    and_by 'make posting TEST-A' do
      click_combobox('Posting Type')
      select_combobox('BASE', 'Posting Type')
      fill_in('Comment', with: 'TEST-A')
      press('Create')
    end

    and_by 'bring up select posting form' do
      wait_for_ajax
      press('Postings')
      press('Select Posting')
    end

    and_by 'select new posting' do
      within(:gridpanel, 'posting_window', match: :first) do
        expect(posting_grid.row_count).to eq 2
        posting_grid.select_row(2)
        press('Select')
      end
    end

    and_by 'can see that we are time warped' do
      expect(page).to have_content "TIME WARPED"
    end
  end

  it 'cannot create posting as dev' do
    log_in_as('dev1')

    by 'bring up new posting form' do
      wait_for_ajax
      press('Postings')
      press('New Posting')
    end

    and_by 'no posting available for adding' do
      click_combobox('Posting Type')
      expect(combobox_values('Posting Type')).not_to include 'BASE'
    end
  end
end
