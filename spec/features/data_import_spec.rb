require 'spec_helper'

feature 'on Data Import', js: true do

  before(:all) do
    Dummy::Application.load_seed
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    dt = Time.zone.now

    Marty::Script.load_scripts(nil, dt)

    populate_import_type
    populate_bud_category_fannie_bup
    populate_test_users

    custom_selectors
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  def go_to_reporting
    press('Applications')
    press('Reports')
  end

  def populate_import_type
    Marty::ImportType.create(name: 'BC',
                             db_model_name: 'Gemini::BudCategory',
                             role_id: 1
                            )
    Marty::ImportType.create(name: 'FB',
                             db_model_name: 'Gemini::FannieBup',
                             role_id: 1
                            )
  end

  def populate_bud_category_fannie_bup
    bc = Gemini::BudCategory.create(name: 'Conv Fixed 30')
    Gemini::BudCategory.create(name: 'Govt Fixed 30')
    Gemini::FannieBup.create(bud_category: bc,
                             note_rate: 2.250,
                             buy_up: 1.123,
                             buy_down: 2.345,
                             settlement_mm: 12,
                             settlement_yy: 2012,
                            )
  end

  let(:tg) { gridpanel('tag_grid') }
  let(:sg) { gridpanel('script_grid') }
  let(:rf) { gridpanel('report_form') }

  it 'data import report adds 2 new fannie bups' do
    log_in_as('marty')
    go_to_reporting

    by 'select BASE tag' do
      select_row(2, tg)
    end

    and_by 'select DataReport script & Data Import node' do
      select_row(2, sg)
    end

    and_by 'select Data Import node' do
      wait_for_ajax

      #hacky: assumes only 1 combobox without label
      within(:gridpanel, 'report_select', match: :first) do
        # hacky, hardcoding netzkecombobox dropdown arrow name
        arrow = find(:input, 'nodename')['componentid'] + '-trigger-picker'
        find(:xpath, ".//div[@id='#{arrow}']").click
        find(:xpath, "//li[text()='Data Import Job (csv)']").click
      end
    end

    and_by 'fill form' do
      wait_for_ajax

      within(:gridpanel, 'report_form', match: :first) do
        select_combobox('FB', 'Import Type')
        paste("bud_category_id\tnote_rate\tsettlement_mm\tsettlement_yy\tbuy_up\tbuy_down\n1\t9.500\t9\t2014\t0\t0\n1\t9.750\t9\t2014\t0\t0\n",
              'data_import_field')
      end
    end

    and_by 'do Background Report with delayed jobs' do
      Delayed::Worker.delay_jobs = false
      press('Background Report')
      wait_for_element { find(:status, 'Busy...') }
      wait_for_ajax
      Delayed::Worker.delay_jobs = true
    end

    and_by 'go to jobs dashboard' do
      press('Applications')
      press('Jobs Dashboard')
    end

    and_by 'background job has shown up' do
      wait_for_ajax
      within(:gridpanel, 'promise_view', match: :first) do
        expect(row_count(treepanel('promise_view'))).to eq 1
      end
    end

    and_by '2 Fannie bups got added' do
      # no reliable way to check if delayed job completed in time
      wait_for_element(10.0) { Gemini::FannieBup.count > 1 }
      expect(Gemini::FannieBup.count).to eq 3
    end
  end

  it 'insufficient permission to add Bud Category' do
    log_in_as('dev1')
    go_to_reporting

    by 'select BASE tag' do
      select_row(2, tg)
    end

    and_by 'select DataReport script & Data Import node' do
      select_row(2, sg)
    end

    and_by 'select Data Import node' do
      wait_for_ajax

      #hacky: assumes only 1 combobox without label
      within(:gridpanel, 'report_select', match: :first) do
        # hacky, hardcoding netzkecombobox dropdown arrow name
        arrow = find(:input, 'nodename')['componentid'] + '-trigger-picker'
        find(:xpath, ".//div[@id='#{arrow}']").click
        find(:xpath, "//li[text()='Data Import Job (csv)']").click
      end
    end

    and_by 'fill form' do
      wait_for_ajax

      within(:gridpanel, 'report_form', match: :first) do
        select_combobox('BC', 'Import Type')
        paste("name\nConv Fixed 40\n", 'data_import_field')
      end
    end

    and_by 'do Background Report with delayed jobs' do
      Delayed::Worker.delay_jobs = false
      press('Background Report')
      wait_for_ajax
      Delayed::Worker.delay_jobs = true
    end

    and_by 'no Bud Category added' do
      # hacky, this only assumes that the script failed, not that it failed
      # due to insufficient permissions
      expect(Gemini::BudCategory.count).to eq 2
    end
  end
end
