require 'spec_helper'

feature 'on Reporting', js: true do
  before(:all) do
    SOME_DATE = "20130520"
    SOME_TIME = "1200"
    SOME_DT   = "#{SOME_DATE} #{SOME_TIME} PST8PDT"
    Dummy::Application.load_seed
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    populate_test_users
    populate_sample_reports
    
    custom_selectors
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
    a_report  = <<DELOREAN
PostingField:
    field_label = "Posting"
    xtype       = ":combo"
    name        = "pt_name"
    store       = [lp.name for lp in Marty::Posting.get_latest(10)]

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
    
    with_user("dev1") { |u|
      Marty::Posting.do_create('BASE', SOME_DT, 'a comment')

      Marty::Script.
        load_script_bodies({ "SomeReport" => a_report, },
                           Date.today)

      Marty::Script.
        load_script_bodies({ "SomeReport" =>
                             a_report +
                             "CC: BB\n    title=\"CC\"\n    result = 123" },
                           Date.today + 1.minute)
    }
  end

  let(:tg) { gridpanel('tag_grid') }
  let(:sg) { gridpanel('script_grid') }
  let(:rf) { gridpanel('report_form') }

  def select_node node_name
    wait_for_ajax
    #hacky: assumes only 1 combobox without label
    within(:gridpanel, 'report_select', match: :first) do
      # hacky, hardcoding netzkecombobox dropdown arrow name
      arrow = find(:input, 'nodename')['componentid'] + '-trigger-picker'
      find(:xpath, ".//div[@id='#{arrow}']").click
      find(:xpath, "//li[text()='#{node_name}']").click
    end
  end

  it 'run_script displays proper data' do
    log_in_as('dev1')
    go_to_reporting

    by 'select 2nd tag' do
      wait_for_ajax
      zoom_out(tg)
      select_row(2, tg)
    end

    and_by 'select SomeReport script & CC node' do
      select_row(1, sg)
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
      expect(combobox_values('Posting')).to include('BASE-20130520-1200')
    end

    and_by 'select 3rd tag' do
      select_row(3, tg)
    end

    and_by 'select SomeReport script' do
      select_row(1, sg)
    end

    and_by 'validate script combobox' do
      expect(combobox_values('')).to include('AA (csv)',
                                             'DD [role: dev] (csv)',
                                             '---')
    end

    and_by 'select AA node' do
      select_node('AA (csv)')
    end

    and_by 'validate posting comobox' do
      wait_for_ajax
      expect(combobox_values('Posting')).to include('BASE-20130520-1200')
    end
  end

  it 'run_script generates CSV' do
    log_in_as('dev1')
    go_to_reporting

    by 'select 2nd tag' do
      wait_for_ajax
      zoom_out(tg)
      select_row(2, tg)
    end

    and_by 'select SomeReport script & AA node' do
      select_row(1, sg)
      select_node('AA (csv)')
    end
    
    and_by 'fill form' do
      wait_for_ajax
      set_field_value('XYZ', '', 'pt_name')
      # hidden field that causes results to be inlined
      set_field_value('true', 'textfield', 'selected_testing')
      press("Generate Report")
    end
    
    wait_for_element do
      expect(page).to have_content('XYZ1,XYZ2,XYZ3,XYZ4 1,2,3,4 2,4,6,8 ' +
                                   '3,6,9,12 4,8,12,16')
    end
  end

  it 'report screen handles security roles properly - enabled' do
    log_in_as('dev1')
    go_to_reporting

    by 'select 2nd tag' do
      wait_for_ajax
      zoom_out(tg)
      select_row(2, tg)
    end

    and_by 'select SomeReport script & AA node' do
      select_row(1, sg)
      select_node('DD [role: dev] (csv)')
    end

    and_by 'generate report disabled' do
      fill_in('Note Rate', with: '3.00')
      expect(btn_disabled?('Generate Report', rf)).to be_truthy
      expect(btn_disabled?('Background Report', rf)).to be_falsy
    end
  end

  it 'report screen handles security roles properly - disabled' do
    log_in_as('viewer1')
    go_to_reporting

    by 'select 2nd tag' do
      wait_for_ajax
      zoom_out(tg)
      select_row(2, tg)
    end

    and_by 'select SomeReport script & AA' do
      select_row(1, sg)
    end

    and_by 'no DD [role: dev] (csv)' do
      expect(combobox_values('')).to include('AA (csv)',
                                             'CC (csv)',
                                             '---')
    end
  end
end
