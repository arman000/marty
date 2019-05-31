require 'spec_helper'

feature 'under Applications menu, Reports workflows', js: true do
  before(:all) do
    SOME_DATE = '20130520'
    SOME_TIME = '1200'
    SOME_DT   = "#{SOME_DATE} #{SOME_TIME} PST8PDT"
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    populate_test_users
    populate_sample_reports
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  def go_to_reporting
    press('Applications')
    press('Reports')
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

  def populate_sample_reports
    a_report = <<DELOREAN
PostingField:
    field_label = "Posting"
    xtype       = ":combo"
    name        = "pt_name"
    store       =  Marty::Posting.
                   where("created_dt <> 'infinity'").
                   order("created_dt DESC").limit(10).pluck("name")

RateField:
    field_label = "Note Rate"
    xtype       = ":numberfield"
    name        = "note_rate"

AA:
    title   = "AA"
    pt_name =?
    res1    = [pt_name + i.to_s() for i in [1,2,3,4]]
    res2    = [res1] + [[a, a*2, a*3, a*4] for a in [1,2,3,4]]

    form = [
        PostingField,
        ]

    result = res2
    format = "csv"

BB:
    title = "BB"
    form = [ RateField ]

    # Should not see this as a report since result is misspelled
    resultx = 456
    format = "csv"

DD: BB
    # has valid role, should be displayed in nodename combo
    roles = ["dev"]
    title = "DD [role: dev]"
    background_only = true

    result = 444
DELOREAN

    with_user('dev1') do |_u|
      Marty::Posting.do_create('BASE', SOME_DT, 'a comment')

      Marty::Script.
        load_script_bodies({ 'SomeReport' => a_report, },
                           Date.today)

      Marty::Script.
        load_script_bodies({ 'SomeReport' =>
                             a_report +
                             "CC: BB\n    title=\"CC\"\n    result = 123" },
                           Date.today + 1.minute)
    end
  end

  def select_node node_name
    wait_for_ajax
    # hacky: assumes only 1 combobox without label
    within(:gridpanel, 'report_select', match: :first) do
      # hacky, hardcoding netzkecombobox dropdown arrow name
      arrow = find(:input, 'nodename')['data-componentid'] + '-trigger-picker'
      find(:xpath, ".//div[@id='#{arrow}']").click
      find(:xpath, "//li[text()='#{node_name}']").click
    end
  end

  def generate_rep_url format: 'csv'
    URI.encode("http://#{Capybara.current_session.server.host}"\
               ":#{Capybara.current_session.server.port}"\
               '/report?data='\
               '{"pt_name":"XYZ",'\
               '"selected_script_name":"SomeReport",'\
               '"selected_node":"AA",'\
               "\"selected_testing\":\"true\"}&format=#{format}&reptitle=AA")
  end

  it 'run_script displays proper data' do
    log_in_as('dev1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')
    posting_combo = netzke_find('Posting', 'combobox')
    script_combo = netzke_find('', 'combobox')

    by 'select 2nd tag' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'select SomeReport script & CC node' do
      script_grid.select_row(1)
      select_node('CC (csv)')
    end

    and_by 'fill form' do
     wait_for_ajax

     within(:gridpanel, 'report_form', match: :first) do
       fill_in('Note Rate', with: '3.00')
     end
    end

    and_by 'do Background Report with delayed jobs' do
      Delayed::Worker.delay_jobs = false
      press('Background Report')
      wait_for_ajax
      Delayed::Worker.delay_jobs = true
    end

    and_by 'select AA node' do
      select_node('AA (csv)')
    end

    and_by 'validate posting combobox' do
      wait_for_ajax
      expect(posting_combo.get_values).to include('BASE-20130520-1200')
    end

    and_by 'select 3rd tag' do
      tag_grid.select_row(3)
    end

    and_by 'select SomeReport script' do
      script_grid.select_row(1)
    end

    and_by 'validate script combobox' do
      expect(script_combo.get_values).to include('AA (csv)',
                                                 'DD [role: dev] (csv)',
                                                 '---')
    end

    and_by 'select AA node' do
      select_node('AA (csv)')
    end

    and_by 'validate posting combobox' do
      wait_for_ajax
      expect(posting_combo.get_values).to include('BASE-20130520-1200')
    end
  end

  it 'run_script generates CSV' do
    log_in_as('dev1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')

    by 'select 2nd tag' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'select SomeReport script & AA node' do
      script_grid.select_row(1)
      select_node('AA (csv)')
    end

    and_by 'fill form' do
      wait_for_ajax
      set_field_value('XYZ', '', 'pt_name')
      # hidden field that causes results to be inlined
      set_field_value('true', 'textfield', 'selected_testing')

      press('Generate Report')
    end

    wait_for_element do
      expect(page).to have_content('XYZ1,XYZ2,XYZ3,XYZ4 1,2,3,4 2,4,6,8 ' +
                                   '3,6,9,12 4,8,12,16')
    end
  end

  it 'report screen handles security roles properly - enabled' do
    log_in_as('dev1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')

    by 'select 2nd tag' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'select SomeReport script & AA node' do
      script_grid.select_row(1)
      select_node('DD [role: dev] (csv)')
    end

    and_by 'generate report disabled' do
      fill_in('Note Rate', with: '3.00')
      expect(btn_disabled?('Generate Report')).to be_truthy
      expect(btn_disabled?('Background Report')).to be_falsy
    end
  end

  it 'report screen handles security roles properly - disabled' do
    log_in_as('viewer1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')
    script_combo = netzke_find('', 'combobox')

    by 'select 2nd tag' do
      wait_for_ajax
      tag_grid.select_row(2)
    end

    and_by 'select SomeReport script & AA' do
      script_grid.select_row(1)
    end

    and_by 'no DD [role: dev] (csv)' do
      expect(script_combo.get_values).to include('AA (csv)',
                                                 'CC (csv)',
                                                 '---')
    end
  end

  it 'can generate report through generated url' do
    url = generate_rep_url(format: 'txt') + URI.encode('&disposition=inline')
    visit url
    wait_for_element do
      expect(page).to have_content('XYZ1,XYZ2,XYZ3,XYZ4 1,2,3,4 2,4,6,8 ' +
                                   '3,6,9,12 4,8,12,16')
    end
  end

  it 'can generate an url that can be used to access report' do
    log_in_as('dev1')
    go_to_reporting

    tag_grid = netzke_find('tag_grid')
    script_grid = netzke_find('script_grid')

    and_by 'select SomeReport script & AA node' do
      script_grid.select_row(1)
      select_node('AA (csv)')
    end

    and_by 'fill form and navigate to generated link' do
      wait_for_ajax
      set_field_value('XYZ', '', 'pt_name')
      set_field_value('true', 'textfield', 'selected_testing')
      press('Generate URL')
      wait_for_ajax

      within_window(switch_to_window(windows.last)) do
        url = generate_rep_url
        expect(page).to have_content(url)
      end
    end
  end
end
