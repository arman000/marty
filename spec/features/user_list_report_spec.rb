require 'csv'

feature 'User List report', js: true do
  before(:each) do
    populate_test_users
    Marty::Script.load_scripts(nil)
  end

  def go_to_reporting
    press('Applications')
    press('Reports')
  end

  def with_user(uname)
    u = Marty::User.find_by(login: uname)
    begin
      old_u, Mcfly.whodunnit = Mcfly.whodunnit, u
      yield(u)
    ensure
      Mcfly.whodunnit = old_u
    end
  end

  def select_node(node_name)
    wait_for_ajax
    # hacky: assumes only 1 combobox without label
    within(:gridpanel, 'report_select', match: :first) do
      # hacky, hardcoding netzkecombobox dropdown arrow name
      arrow = find(:input, 'nodename')['data-componentid'] + '-trigger-picker'
      find(:xpath, ".//div[@id='#{arrow}']").click
      find(:xpath, "//li[text()='#{node_name}']").click
    end
  end

  it 'run_script displays proper data' do
    log_in_as('admin1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')
    posting_combo = netzke_find('Posting', 'combobox')
    script_combo = netzke_find('', 'combobox')

    by 'select tag' do
      wait_for_ajax
      tag_grid.select_row(1)
    end

    and_by 'select TableReport script & UserList node' do
      find('table', text: 'TableReport').click
      select_node('User List (csv)')
    end

    and_by 'generate report' do
      wait_for_ajax
      press('Generate Report')
      wait_for_ajax
      expect(page).to have_content('Generate: User List')
    end

    path = Rails.root.join('spec/tmp/downloads/User List.csv')
    csv_content = ::CSV.parse File.read(path)

    expect(csv_content.size > 1).to be true
    expect(csv_content.first).to eq ['login', 'firstname', 'lastname', 'active', 'roles']

    expected_row = [
      'marty', 'marty', 'marty', 'true',
      'admin, data_grid_editor, dev, user_manager, viewer'
    ]
    marty_row = csv_content.find { |row| row[0] == 'marty' }
    expect(marty_row).to eq expected_row
  end
end
