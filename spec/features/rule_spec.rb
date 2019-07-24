require 'spec_helper'

feature 'rule view', js: true do
  before(:all) do
    marty_whodunnit
    @save_file = "/tmp/save_#{Process.pid}.psql"
    save_clean_db(@save_file)
    Marty::Script.load_scripts
    dt = DateTime.parse('2017-1-1')
    p = File.expand_path('../../fixtures/csv/rule', __FILE__)

    [Marty::DataGrid, Gemini::XyzRule, Gemini::MyRule].each do |klass|
      f = '%s/%s.csv' % [p, klass.to_s.sub(/(Gemini|Marty)::/, '')]
      Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ',')
    end
  end

  after(:all) do
    restore_clean_db(@save_file)
  end

  def go_to_my_rules
    press('Pricing Config.')
    press('My Rules')
    expect(page).to have_content 'My Rules'
  end

  def go_to_xyz_rules
    press('Pricing Config.')
    press('Xyz Rules')
    expect(page).to have_content 'Xyz Rules'
  end

  def col_id(v, col)
    run_js <<-JS
           #{ext_var(v.grid, 'grid')}
           return #{ext_find(ext_arg('gridcolumn', text: col), 'grid')}.id
     JS
  end

  def click_checkbox(name)
    q = %Q(checkbox[fieldLabel="#{name}"])
    page.execute_script <<-JS
    var checkbox = Ext.ComponentQuery.query('#{q}')[0];
    checkbox.setValue(!checkbox.value);
    JS
  end

  def click_column(rv, name)
    cid = col_id(rv, name)
    c = find('#' + cid)
    c.select_option   #   .click does not work reliably
    c.send_keys(' ')
    # wait_for_ajax and wait_for_ready do not work here,
    # or in the next two methods
    sleep 1.0
  end

  def column_filter(rv, name, value)
    begin
      cid = col_id(rv, name)
      c = find('#' + cid)
    rescue Capybara::ElementNotFound
      # Scroll to the element
      page.execute_script <<-JS
        var element = document.getElementById('#{cid}')
        element.scrollIntoView(true);
      JS
      c = find('#' + cid)
    end
    c.send_keys([:down, :down, :down, :down, :right, value, :return])
    sleep 1.0
  end

  def column_filter_toggle(rv, name)
    cid = col_id(rv, name)
    c = find('#' + cid)
    c.send_keys([:down, :down, :down, :down, ' ', :escape])
    sleep 1.0
  end

  # idx 0 is the start dt, 1 is the end dt
  def date_fill_in(idx, value)
    dt = all(:xpath, "//input[contains(@name, 'datefield')]")[idx]
    dt.native.clear()
    dt.native.send_keys(value)
  end

  def time_fill_in(idx, value)
    tm = all(:xpath, "//input[contains(@name, 'timefield')]")[idx]
    tm.native.clear()
    tm.native.send_keys(value)
  end

  it 'rule workflow' do
    log_in_as('marty')
    go_to_my_rules
    mrv = netzke_find('my_rule_view')
    # test required field
    press('Add')
    wait_for_ajax
    fill_in('name', with: 'abc')
    press('OK')
    wait_for_ajax
    expect(page).to have_content("Rule type can't be blank")
    expect(page).to have_content("Start dt can't be blank")
    # create and verify rule
    fill_in('rule_type', with: 'SimpleRule')
    date_fill_in(0, '2013-01-01')
    time_fill_in(0, '11:03:01')
    date_fill_in(1, '2030-01-01')
    time_fill_in(1, '08:03:01')
    press('OK')
    wait_for_ajax
    expect(mrv.row_count()).to eq(12)
    expect(mrv.get_row_vals(1)).to include('name' => 'abc',
                                            'rule_type' => 'SimpleRule',
                                            'start_dt' => '2013-01-01T11:03:01',
                                            'end_dt' => '2030-01-01T08:03:01',
                                            'other_flag' => false,
                                            'g_array' => '',
                                            'g_single' => '',
                                            'g_string' => '',
                                            'g_bool' => nil,
                                            'g_nullbool' => '',
                                            'g_bool_def' => nil,
                                            'g_nbool_def' => 'False',
                                            'g_range' => nil,
                                            'g_integer' => nil,
                                            'g_has_default' => 'string default',
                                            'computed_guards' => '',
                                            'grids' => '',
                                            'results' => '',
                                          )

    r = Gemini::MyRule.find_by(obsoleted_dt: 'infinity', name: 'abc')
    expect(r.attributes).to include('user_id' => 1,
                                     'o_user_id' => nil,
                                     'name' => 'abc',
                                     'engine' => 'Gemini::MyRuleScriptSet',
                                     'rule_type' => 'SimpleRule',
                                     'simple_guards' => { 'g_bool' => false,
                                                       'g_bool_def' => false,
                                                       'g_nbool_def' => false,
                                                       'g_has_default' =>
                                                       'string default' },
                                     'computed_guards' => {},
                                     'grids' => {},
                                     'results' => {},
                                   )
    # type validation (string with values list)
    mrv.select_row(1)
    press('Edit')
    # type validation (range)
    netzke_find('String list Guard', 'combobox').select_values('Hi Mom')
    click_checkbox('Bool Guard')
    click_checkbox('Other')
    netzke_find('NullBool Guard', 'combobox').select_values('False')
    netzke_find('Array Guard', 'combobox').select_values('G1V1,G1V3')
    netzke_find('Single Guard', 'combobox').select_values('G2V2')
    fill_in(:g_integer, with: 123)
    fill_in(:g_range, with: 'asfd')
    press('OK')
    wait_for_ajax
    expect(page).to have_content("Wrong type for 'g_range'")
    # validate rule
    fill_in(:g_range, with: '<=100')
    netzke_find('Grid1', 'combobox').select_values('DataGrid1')
    netzke_find('Grid2', 'combobox').select_values('DataGrid2')
    fill_in('Defaulted String', with: '12345')
    press('OK')
    wait_for_ajax
    exp = { 'name' => 'abc',
           'rule_type' => 'SimpleRule',
           'start_dt' => '2013-01-01T11:03:01',
           'end_dt' => '2030-01-01T08:03:01',
           'other_flag' => true,
           'g_array' => 'G1V1,G1V3',
           'g_single' => 'G2V2',
           'g_string' => 'Hi Mom',
           'g_bool' => true,
           'g_nullbool' => 'False',
           'g_range' => '<=100',
           'g_integer' => 123,
           'g_has_default' => '12345',
           'computed_guards' => '',
           'grids' => '{"grid1":"DataGrid1","grid2":"DataGrid2"}',
           'results' => '',
          }
    r = Gemini::MyRule.lookup('infinity', 'abc')
    expect(r['simple_guards']['g_nullbool']).to eq(false)
    expect(mrv.get_row_vals(1)).to include(exp)
    # grid edits
    press('Edit')
    netzke_find('Grid2', 'combobox').select_values('---')
    press('OK')
    wait_for_ajax
    expect(mrv.get_row_vals(1)).to include(exp + { 'grids' =>
                                                '{"grid1":"DataGrid1"}' })
    press('Edit')
    netzke_find('NullBool Guard', 'combobox').select_values('---')
    press('OK')
    wait_for_ajax
    expect(mrv.get_row_vals(1)).to include(exp + { 'g_nullbool' => '',
                                                'grids' =>
                                                '{"grid1":"DataGrid1"}' })
    r = Gemini::MyRule.lookup('infinity', 'abc')
    expect(r['simple_guards']).not_to include('g_nullbool')
    # computed fields
    press('Edit')

    # bad form - BaseRuleView#simple_to_hash will raise
    fill_in(:computed_guards, with: 'sadf asdf ljsf')
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'computed_guards': "\
          'Syntax error on line 1'
    expect(page).to have_content(exp)
    sleep 2  # sleep needed for message to clear, otherwise failing tests could
    # pass due to prior messages

    # lhs is not identifier - BaseRuleView#simple_to_has will raise
    fill_in(:computed_guards, with: '0sadf = 123j')
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'computed_guards': "\
          'Syntax error on line 1'
    expect(page).to have_content(exp)
    sleep 2

    # bad rhs - delorean compile will raise
    fill_in(:computed_guards, with: "x = true\ny = false\nvar = 123j\nz = true")
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'computed_guards' "\
          '(attribute var): Syntax error'
    expect(page).to have_content(exp)
    sleep 2

    fill_in(:computed_guards, with: %Q(var1 = "good"\nvar2 = 123\nvar3 = 123j))
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'computed_guards' "\
          '(attribute var3): Syntax error'
    expect(page).to have_content(exp)
    sleep 2

    fill_in(:computed_guards, with: '')
    fill_in(:results, with: %Q(var3 = 123j\nvar1 = "good"\nvar2 = 123))
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'results' (attribute var3): "\
          'Syntax error'
    expect(page).to have_content(exp)
    sleep 2

    fill_in(:results, with: %Q(abc = "def"\ndef = 5\nxyz = def+10\nsadf asdf lsf))
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'results' (attribute xyz): "\
          'Syntax error'
    expect(page).to have_content(exp)
    sleep 2

    fill_in(:results,
            with: %Q(abc = "def"\ndef = "abc"\nklm = "3"\nabc = "xyz"))

    exp = "Computed - Error in rule 'abc' field 'results': Keyword 'abc' "\
          'specified more than once (line 4)'
    press('OK')
    wait_for_ajax
    expect(page).to have_content(exp)
    sleep 2

    klm = "    3 +    \n\n# hi mom\n     4 +\n    if true then 5 else 0\n\n"
    bogus = <<-EOL

# comment line

EOL

    multi_line = <<-EOL
abc = "def"
def = "abc"
klm = #{klm}
EOL

    fill_in(:results, with: bogus + multi_line)
    press('OK')
    wait_for_ajax
    exp = "Computed - Error in rule 'abc' field 'results': "\
          'Syntax error on line 1'
    expect(page).to have_content(exp)

    fill_in(:results, with: multi_line)
    press('OK')
    wait_for_ajax

    # re-edit twice to make sure identation and comments are preserved
    press('Edit')
    wait_for_ajax
    expect(find_field(:results).value).to eq(multi_line)
    press('OK')
    wait_for_ajax

    press('Edit')
    wait_for_ajax
    expect(find_field(:results).value).to eq(multi_line)
    press('OK')
    wait_for_ajax

    # when stored in rule, all lines of a multi line value s/b stripped
    r = Gemini::MyRule.where(name: 'abc', obsoleted_dt: 'infinity').first
    expect(r.results['klm']).to eq(klm)

    # make sure change of key/value order is recognized as a change
    press('Edit')
    wait_for_ajax
    val = find_field(:results).value.lines
    val[-1] += "\n"
    newval = (val[1..-1] + val[0..0]).join
    fill_in(:results, with: newval)
    press('OK')
    wait_for_ajax
    press('Edit')
    wait_for_ajax
    val = find_field(:results).value
    expect(val).to eq(newval)
    press('OK')
    wait_for_ajax

    exp = <<-EOL
simple_result = "c value"
computed_value = if paramb
    then param1 / (grid1_grid_result||1)
     else (grid2_grid_result||1) / param1
EOL

    names = mrv.get_col_vals(:name, 12, 0)
    idx = names.index { |n| n == 'Rule3' } + 1
    mrv.select_row(idx)
    press('Edit')
    expect(find_field(:results).value).to eq(exp)
    press('OK')
    wait_for_ajax

    press('Dup in form')
    netzke_find('Single Guard', 'combobox').select_values('G2V3')
    press('OK')
    wait_for_ajax
    expect(page).to have_content(/record must be unique/)

    press('Cancel')
    # column sorting, etc
    go_to_xyz_rules
    xrv = netzke_find('xyz_rule_view')
    expect(page).to have_content('Rule type')
    expect(xrv.get_col_vals(:name, 5, 0)).to eq(['ZRule1', 'ZRule2',
                                                 'ZRule3', 'ZRule4',
                                                 'ZRule5'])
    xrv.select_row(1)

    expect(page).to_not have_content('NOT (G2V1)')

    press('Edit')

    fill_in('Guard two', with: 'G2V1')
    click_checkbox('Not')

    fill_in('Range Guard 1', with: '[100,200)', fill_options: { clear: :backspace })
    fill_in('Range Guard 2', with: '[30,40)', fill_options: { clear: :backspace })
    press('OK')

    wait_for_ajax

    r = Gemini::XyzRule.get_matches(
      'infinity',
      {},
      'g_range1' => 150,
      'g_range2' => 35,
      'guard_two' => 'G2V2'
    )

    expect(r.to_a.count).to eq(1)
    exp = {
      'user_id' => 1,
      'o_user_id' => nil,
      'name' => 'ZRule1',
      'engine' => 'Gemini::XyzRuleScriptSet',
      'rule_type' => 'ZRule',
      'start_dt' => DateTime.parse('2017-1-1 08:01:00'),
      'simple_guards' => {
        'g_bool' => false,
        'g_date' => '2017-1-1',
        'guard_two' => 'G2V1',
        'g_range1' => '[100,200)',
        'g_range2' => '[30,40)',
        'g_string' => 'aaa',
        'g_integer' => '5',
        'g_datetime' => '2017-1-1 12:00:01'
      },
      'simple_guards_options' => {
        'g_bool' => { 'not' => false },
        'g_date' => { 'not' => false },
        'g_datetime' => { 'not' => false },
        'g_integer' => { 'not' => false },
        'g_range1' => { 'not' => false },
        'g_range2' => { 'not' => false },
        'g_string' => { 'not' => false },
        'guard_two' => { 'not' => true }
      },
      'computed_guards' => {},
      'grids' => { 'grid1' => 'DataGrid1' },
      'results' => {
        'bvlen' => 'base_value.length',
        'bv' => 'base_value'
      }
    }

    expect(r.first.as_json).to include(exp)

    expect(page).to have_content('NOT (G2V1)')

    expect(xrv.get_col_vals(:g_string, 8, 0)).to eq(['aaa', 'bbb', 'ccc', 'ddd',
                                                     'eee', 'eee', 'eee', 'eee'])
    click_column(xrv, 'String list Guard')
    expect(xrv.get_col_vals(:g_string, 8, 0)).to eq(['eee', 'eee', 'eee', 'eee',
                                                     'ddd', 'ccc', 'bbb', 'aaa'])
    column_filter(xrv, 'String list Guard', 'eee')
    rc = xrv.row_count
    expect(xrv.get_col_vals(:g_string, rc, 0)).to eq(['eee', 'eee', 'eee', 'eee'])
    column_filter_toggle(xrv, 'String list Guard')
    rc = xrv.row_count
    expect(xrv.get_col_vals(:g_string, rc, 0)).to eq(['eee', 'eee', 'eee', 'eee',
                                                      'ddd', 'ccc', 'bbb', 'aaa'])
    column_filter(xrv, 'Grids', 'Grid1')
    rc = xrv.row_count
    # netzke reports jsonb as string
    expect(xrv.get_col_vals(:grids, rc, 0)).to eq([%Q({"grid1":"DataGrid1"}),
                                                   %Q({"grid1":"DataGrid1"})])
    column_filter_toggle(xrv, 'Grids')
    rc = xrv.row_count
    expect(xrv.get_col_vals(:grids, rc, 0)).to eq([%Q({"grid1":"DataGrid3"}),
                                                   %Q({"grid1":"DataGrid3"}),
                                                   %Q({"grid1":"DataGrid3"}),
                                                   %Q({"grid1":"DataGrid3"}),
                                                   %Q({"grid1":"DataGrid3"}),
                                                   %Q({"grid1":"DataGrid2"}),
                                                   %Q({"grid1":"DataGrid1"}),
                                                   %Q({"grid1":"DataGrid1"})])

    press('Applications')
    press('Data Grids Admin')
    dgv = netzke_find('data_grid_view')
    cvs = dgv.get_col_vals(:name, 4, 0)
    ind1 = cvs.index('DataGrid1') + 1
    ind4 = cvs.index('DataGrid4') + 1
    dgv.select_row(ind1)
    press('Edit')
    fill_in('Name', with: 'DataGrid1 new')
    press('OK')
    wait_for_ajax
    dgv.select_row(ind4)
    press('Edit')
    fill_in('Name', with: 'DataGrid4 new')
    press('OK')
    wait_for_ajax

    go_to_xyz_rules
    wait_for_ajax

    names = xrv.get_col_vals(:name, 5, 0)
    gvs = xrv.get_col_vals(:grids, 5, 0)
    g1h = { 'grid1' => 'DataGrid1 new' }
    expect(JSON.parse(gvs[names.index('ZRule1')])).to eq(g1h)
    expect(JSON.parse(gvs[names.index('ZRule2')])).to eq(g1h)

    go_to_my_rules
    wait_for_ajax

    names = mrv.get_col_vals(:name, 12, 0)
    gvs = mrv.get_col_vals(:grids, 12, 0)
    rvs = mrv.get_col_vals(:results, 12, 0)
    expect(JSON.parse(gvs[names.index('abc')])).to eq(g1h)
    expect(JSON.parse(gvs[names.index('Rule2b')])).to eq(g1h +
                                                         { 'grid2' => 'DataGrid2' })
    expect(JSON.parse(rvs[names.index('Rule5')])['other_grid']).to eq(
      '"DataGrid4 new"')
  end
end
