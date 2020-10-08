feature 'logger view', js: true, capybara: true do
  before(:all) do
    self.use_transactional_tests = false
    Marty::Log.delete_all

    info_s = { info: 'message' }
    error_s = [1, 2, 3, { error: 'message' }]
    fatal_s = ['string', 123, { fatal: 'message', another_key: 'value' }]
    Marty::Logger.info('info message', nil)
    Marty::Logger.error('error message', error_s)
    Marty::Logger.fatal('fatal message', fatal_s)

    Marty::Log.create!(message_type: 'debug',
                       message: 'hi mom',
                       details: ['one', 'two', 3, 4.0],
                       timestamp: Time.zone.now - 5.days)

    Marty::Log.create!(message_type: 'warn',
                       message: 'all your base',
                       details: [5],
                       timestamp: Time.zone.now - 10.days)

    @ts = Marty::Log.select(:timestamp).order(timestamp: :desc).map do |(ts)|
      Time.zone.at(ts[:timestamp]).strftime('%Y-%m-%d %H:%M:%S')
    end

    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    populate_test_users
  end

  after(:all) do
    restore_clean_db(@clean_file)
    Marty::Log.delete_all
    self.use_transactional_tests = true
  end

  let(:logview) { netzke_find('log_view') }
  it 'updates views correctly' do
    log_in_as('marty')
    press('System')
    show_submenu('Log Maintenance')
    press('View Log')
    wait_for_ajax

    exp_types = ['fatal', 'error', 'info', 'debug', 'warn']
    exp_messages = ['fatal message', 'error message',
                    'info message', 'hi mom', 'all your base']
    exp_details = ['["string", 123, {"fatal"=>"message", '\
                     '"another_key"=>"value"}]',
                   '[1, 2, 3, {"error"=>"message"}]',
                   '',
                   '["one", "two", 3, 4.0]',
                   '[5]']
    [[nil, 5], [7, 4], [3, 3], [0, 0]].each do |days, exp_count|
       if days
         press('System')
         show_submenu('Log Maintenance')
         press('Cleanup Log Table')
         wait_for_ajax
         find(:xpath, "//input[contains(@id, 'textfield')]", wait: 5).set(days)
         press('OK')
         wait_for_ready
         find('.x-tool-refresh').click
         wait_for_ready
       end
       wait_for_ajax
       cnt = logview.row_count()
       expect(cnt).to eq(exp_count)
       types = logview.get_col_vals('message_type', cnt, 0)
       messages = logview.get_col_vals('message', cnt, 0)
       details = logview.get_col_vals('details', cnt, 0).
                   map { |d| CGI.unescapeHTML(d) }
       ts = logview.get_col_vals('timestamp_custom', cnt, 0)
       expect(ts).to eq(@ts.slice(0, exp_count))
       expect(types).to eq(exp_types.slice(0, exp_count))
       expect(messages).to eq(exp_messages.slice(0, exp_count))
       expect(details).to eq(exp_details.slice(0, exp_count))
    end
  end
end
