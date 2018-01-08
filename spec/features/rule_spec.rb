require 'spec_helper'
require 'marty_rspec'

feature 'rule view', js: true do
  before(:all) do
    marty_whodunnit
    @save_file = "/tmp/save_#{Process.pid}.psql"
    save_clean_db(@save_file)
    Marty::Script.load_scripts
    dt = DateTime.parse('2017-1-1')
    p = File.expand_path('../../fixtures/csv/rule', __FILE__)
    [Marty::DataGrid, Gemini::XyzRule, Gemini::MyRule].each do |klass|
      f = "%s/%s.csv" % [p, klass.to_s.sub(/(Gemini|Marty)::/,'')]
      Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ",")
    end
  end
  after(:all) do
    restore_clean_db(@save_file)
  end
  def go_to_my_rules
    press("Pricing Config.")
    press("My Rules")
    expect(page).to have_content 'My Rules'
  end
  def go_to_xyz_rules
    press("Pricing Config.")
    press("Xyz Rules")
    expect(page).to have_content 'Xyz Rules'
  end
  def col_id(v, col)
    run_js <<-JS
           #{ext_var(v.grid, 'grid')}
           return #{ext_find(ext_arg('gridcolumn', text: col), 'grid')}.id
     JS
  end
  # click_checkbox in marty_rspec not working here for some reason
  def click_checkbox(name)
    q = %Q(checkbox[fieldLabel="#{name}"])
    id = run_js "return  Ext.ComponentQuery.query('#{q}')[0].inputId"
    find_by_id(id).click
  end
  # click_col in marty_rspec is not reliable
  def click_column(rv,name)
    cid = col_id(rv, name)
    c = find('#'+cid)
    c.select_option   #   .click does not work reliably
    c.send_keys(' ')
    # wait_for_ajax and wait_for_ready do not work here,
    # or in the next two methods
    sleep 1.0
  end

  def column_filter(rv,name,value)
    cid = col_id(rv, name)
    c = find('#'+cid)
    c.send_keys([:down, :down, :down, :down, :right, value, :return])
    sleep 1.0
  end
  def column_filter_toggle(rv,name)
    cid = col_id(rv, name)
    c = find('#'+cid)
    c.send_keys([:down, :down, :down, :down, ' ', :escape])
    sleep 1.0
  end
  # idx 0 is the start dt, 1 is the end dt
  def date_fill_in(idx, value)
    dt = all(:xpath, "//input[contains(@name, 'datefield')]")[idx]
    dt.native.clear()
    dt.native.send_keys(value)
  end
  def time_fill_in(idx,value)
    tm = all(:xpath, "//input[contains(@name, 'timefield')]")[idx]
    tm.native.clear()
    tm.native.send_keys(value)
  end
  it "rule workflow" do
    log_in_as('marty')
    page.driver.browser.manage.window.maximize
    go_to_my_rules
    mrv = netzke_find("my_rule_view")
    # test required field
    press('Add')
    wait_for_ajax
    fill_in('name', with: 'abc')
    press('OK')
    expect(page).to have_content("Rule type can't be blank")
    expect(page).to have_content("Start dt can't be blank")
    # create and verify rule
    fill_in('rule_type', with: 'SimpleRule')
    date_fill_in(0, '2013-01-01')
    time_fill_in(0, '11:03:01')
    date_fill_in(1, '2030-01-01')
    time_fill_in(1, '08:03:01')
    press("OK")
    wait_for_ajax
    expect(mrv.row_count()).to eq(7)
    expect(mrv.get_row_vals(1)).to include({"name"=>"abc",
                                            "rule_type"=>"SimpleRule",
                                            "start_dt"=>"2013-01-01T19:03:01.000Z",
                                            "end_dt"=>"2030-01-01T16:03:01.000Z",
                                            "other_flag"=>false,
                                            "g_array"=>"",
                                            "g_single"=>"",
                                            "g_string"=>"",
                                            "g_bool"=>nil,
                                            "g_range"=>"",
                                            "g_integer"=>nil,
                                            "computed_guards"=>"",
                                            "grids"=>"",
                                            "results"=>"",
                                            })
    r = Gemini::MyRule.lookup('infinity','abc')
    expect(r.as_json).to include({"user_id"=>1,
                                  "o_user_id"=>nil,
                                  "name"=>"abc",
                                  "engine"=>"Gemini::MyRuleScriptSet",
                                  "rule_type"=>"SimpleRule",
                                  "simple_guards"=>{"g_has_default"=>
                                                    "string default"},
                                  "computed_guards"=>{},
                                  "grids"=>{},
                                  "results"=>{},
                                  })
    # type validation (string with values list)
    mrv.select_row(1)
    press("Edit")
    fill_in(:g_string, with: "12345")
    press("OK")
    expect(page).to have_content("Bad value '12345' for 'g_string'")
    # type validation (range)
    fill_in(:g_string, with: "Hi Mom")
    click_checkbox("Bool Guard")
    click_checkbox("Other")
    netzke_find('Array Guard', 'combobox').select_values("G1V1,G1V3")
    netzke_find('Single Guard', 'combobox').select_values("G2V2")
    fill_in(:g_integer, with: 123)
    fill_in(:g_range, with: "asfd")
    press("OK")
    expect(page).to have_content("Wrong type for 'g_range'")
    # validate rule
    fill_in(:g_range, with: "(,100]")
    netzke_find('Grid1', 'combobox').select_values("DataGrid1")
    netzke_find('Grid2', 'combobox').select_values("DataGrid2")
    press("OK")
    wait_for_ajax
    exp = {"name"=>"abc",
           "rule_type"=>"SimpleRule",
           "start_dt"=>"2013-01-01T19:03:01.000Z",
           "end_dt"=>"2030-01-01T16:03:01.000Z",
           "other_flag"=>true,
           "g_array"=>"G1V1,G1V3",
           "g_single"=>"G2V2",
           "g_string"=>"Hi Mom",
           "g_bool"=>true,
           "g_range"=>"(,100]",
           "g_integer"=>123,
           "computed_guards"=>"",
           "grids"=>"{\"grid1\":\"DataGrid1\",\"grid2\":\"DataGrid2\"}",
           "results"=>"",
          }
    expect(mrv.get_row_vals(1)).to include(exp)
    # grid edits
    press("Edit")
    netzke_find('Grid2', 'combobox').select_values("---")
    press("OK")
    wait_for_ajax
    expect(mrv.get_row_vals(1)).to include(exp+{"grids"=>
                                                "{\"grid1\":\"DataGrid1\"}"})
    # computed fields
    press("Edit")
    fill_in(:computed_guards, with: 'sadf asdf ljsf')
    press("OK")
    exp = "Computed - Error in field computed_guards: Syntax error on line 1"
    expect(page).to have_content(exp)
    fill_in(:computed_guards, with: 'sadf = 123j s /*fdjOIb')
    press("OK")
    exp = "Computed - Error in field computed_guards: syntax error"
    expect(page).to have_content(exp)
    fill_in(:computed_guards, with: '')
    fill_in(:results, with: %Q(abc = "def"\ndef = 5\nxyz=def+10\nsadf asdf lsf))
    press("OK")
    exp = "Computed - Error in field results: Syntax error on line 4"
    expect(page).to have_content(exp)
    fill_in(:results,
            with: %Q(abc = "def"\ndef = "abc"\nklm = "3"\nabc = "xyz"))
    exp = "Computed - Error in field results: Keyword 'abc' specified more"\
          " than once (line 4)"
    press("OK")
    expect(page).to have_content(exp)
    fill_in(:results,
            with: %Q(abc = "def"\ndef = "abc"\nklm = "3"))
    press("OK")

    press("Dup in form")
    press("OK")
    exp = Regexp.new("Can't have rule with same name and overlapping start"\
                     "/end dates - abc")
    expect(page).to have_content(exp)
    press("Cancel")
    # column sorting, etc
    go_to_xyz_rules
    xrv = netzke_find("xyz_rule_view")
    expect(page).to have_content("Rule type")
    expect(xrv.col_values(:name, 5, 0)).to eq(["ZRule1", "ZRule2",
                                                    "ZRule3", "ZRule4",
                                                    "ZRule5"])
    xrv.select_row(1)
    press("Edit")
    fill_in("Range Guard 1", with: "[100,200)")
    fill_in("Range Guard 2", with: "[30,40)")
    press("OK")
    r = Gemini::XyzRule.get_matches('infinity', {}, {"g_range1"=> 150,
                                                     "g_range2"=> 35})
    expect(r.to_a.count).to eq(1)
    exp = {"user_id"=>1,
           "o_user_id"=>nil,
           "name"=>"ZRule1",
           "engine"=>"Gemini::XyzRuleScriptSet",
           "rule_type"=>"ZRule",
           "start_dt"=>DateTime.parse("2017-1-1 08:01:00"),
           "simple_guards"=>{"g_date"=>"2017-1-1",
                             "g_range1"=>"[100,200)",
                             "g_range2"=>"[30,40)",
                             "g_string"=>"aaa",
                             "g_integer"=>"5",
                             "g_datetime"=>"2017-1-1 12:00:01"},
           "computed_guards"=>{},
           "grids"=>{"grid1"=>"DataGrid1"},
           "results"=>
           {"bvlen"=>"base_value.length",
            "bv"=>"base_value"}}

    expect(r.first.as_json).to include(exp)
    expect(xrv.col_values(:g_string, 5, 0)).to eq(["aaa", "bbb", "ccc",
                                                   "ddd", "eee"])
    click_column(xrv, "G string")
    expect(xrv.col_values(:g_string, 5, 0)).to eq(["eee", "ddd", "ccc",
                                                   "bbb", "aaa"])
    column_filter(xrv, "G string", "eee")
    rc = xrv.row_count
    expect(xrv.col_values(:g_string,rc,0)).to eq(["eee"])
    column_filter_toggle(xrv, "G string")
    rc = xrv.row_count
    expect(xrv.col_values(:g_string,rc,0)).to eq(["eee", "ddd", "ccc",
                                                   "bbb", "aaa"])
    column_filter(xrv, "Grids", "Grid1")
    rc = xrv.row_count
                                         # netzke reports jsonb as string
    expect(xrv.col_values(:grids,rc,0)).to eq([%Q({"grid1":"DataGrid1"}),
                                               %Q({"grid1":"DataGrid1"})])
    column_filter_toggle(xrv, "Grids")
    rc = xrv.row_count
    expect(xrv.col_values(:grids,rc,0)).to eq([%Q({"grid1":"DataGrid3"}),
                                               %Q({"grid1":"DataGrid3"}),
                                               %Q({"grid1":"DataGrid2"}),
                                               %Q({"grid1":"DataGrid1"}),
                                               %Q({"grid1":"DataGrid1"})])
  end
end
