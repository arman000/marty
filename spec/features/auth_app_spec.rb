feature 'Posting workflows', js: true do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    populate_test_users

    monkey_patch_new_posting_form
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  def monkey_patch_new_posting_form
    # presently, Gemini displays similar monkeypatching behavior.
    # consider coming up with a proper fix...
    Marty::Postings::NewForm.has_marty_permissions(BASE: :admin)
  end

  it 'create posting and select it' do
    log_in_as('admin1')

    posting_grid = netzke_find('posting_grid')
    posting_type_combo = netzke_find('Posting Type', 'combobox')

    by 'bring up new posting form' do
      wait_for_ajax
      press('Postings')
      press('New Posting')
    end

    and_by 'make posting TEST-A' do
      posting_type_combo.click
      posting_type_combo.select_values('BASE')
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
        wait_for_ajax
        expect(posting_grid.row_count).to eq 2
        posting_grid.select_row(2)
        press('Select')
      end
    end

    and_by 'can see that we are time warped' do
      expect(page).to have_content 'TIME WARPED'
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
      posting_type_combo = netzke_find('Posting Type', 'combobox')
      posting_type_combo.click
      expect(posting_type_combo.get_values).not_to include 'BASE'
    end
  end
end
