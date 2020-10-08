feature 'data grid view', js: true, speed: :super_slow do
  before(:all) do
    self.use_transactional_tests = true
  end

  before(:each) do
    marty_whodunnit
    Marty::Script.load_scripts
    dt = DateTime.parse('2017-1-1')
    p = File.expand_path('../../fixtures/misc', __FILE__)
    Dir.glob(p + '/data_grid_*.txt').sort.each do |path|
      next if path.include?('data_grid_7')

      n = File.basename(path, '.txt').camelize
      Marty::DataGrid.create_from_import(n, File.read(path), dt)
    end
    path = p + '/data_grid_7.txt'
    Marty::DataGrid.create_from_import('DataGrid7', File.read(path),
                                       dt + 1.second)
    u = Marty::User.create!(login: 'grid_user',
                            firstname: 'grid',
                            lastname: 'user',
                            active: true)
    Marty::UserRole.create!(user_id: u.id, role: 'data_grid_editor')
    @no_perm = { 'view' => [],
                 'edit_data' => [],
                 'edit_all' => [] }
  end

  def go_to_data_grids(admin: true)
    log_in_as(admin ? 'marty' : 'grid_user')
    press('Applications')
    dest = 'Data Grids' + (admin ? ' Admin' : '')
    press(dest)
    expect(page).to have_content dest
  end

  # setup the info for the ext grid
  def grid_setup
    widths, rows = get_grid_info
    @grid = page.all(:xpath,
                     ".//div[contains(@class, 'x-grid-item-container')]").
              reject { |e| e.text.include?('DataGrid1') }.first
    @gridx = @grid.native.rect.x
    @gridy = @grid.native.rect.y
    height = @grid.native.size.height
    @perr = (height / rows).to_i
    col_preh = widths.each_with_index.map do |c, i|
      [i, [c[:x] + @gridx, c[:width]]]
    end
    @colh = Hash[col_preh]
  end

  def context_click(col, row, menuidx, click: false)
    colx = @colh[col][0]
    colw = @colh[col][1]
    xpos = (colx + colw / 2).to_i - @gridx
    ypos = (@perr * row + @perr / 2).to_i
    mxpos = xpos + 20
    mypos = ypos + (@perr * menuidx + @perr / 2).to_i
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).context_click.perform

    if click
      page.driver.browser.action.move_to(@grid.native, mxpos, mypos).click.
        release.perform
    else
      ret = get_menu
      page.driver.browser.action.move_to(@grid.native, 0, 0).click.perform
      ret
    end
  end

  def get_menu
    m_en = page.all(:xpath,
                    ".//div[contains(@class, 'x-menu-item-default')]").to_a
    m_dis = page.all(:xpath,
                     ".//div[contains(@class, 'x-menu-item-disabled')]").to_a
    labels = ['Insert Row Above', 'Insert Row Below',
              'Insert Column Left', 'Insert Column Right',
              'Delete Row', 'Delete Column']
    en = m_en.select { |m| labels.include?(m.text) }.
           map { |m| [m.text, :enabled] }
    dis = m_dis.select { |m| labels.include?(m.text) }.
            map { |m| [m.text, :disabled] }
    Hash[en + dis]
  end

  def cell_edit(col, row, text)
    colx = @colh[col][0]
    colw = @colh[col][1]
    xpos = (colx + colw / 2).to_i - @gridx
    ypos = (@perr * row + @perr / 2).to_i
    page.driver.browser.action.move_to(@grid.native, xpos, ypos).double_click.
        send_keys("\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08").perform
    sleep 0.1
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).double_click.
      send_keys(text.to_s).perform
  end

  def get_grid(to_get: :values)
    get_expr = case to_get
               when :values
                 'value'
               when :colors
                 'cell.style.backgroundColor'
               when :qtips
                 "('data-qtip' in cell.attributes) && "\
                 "cell.attributes['data-qtip'].value"
               end
    db = 'debugger;' if to_get == :qtips
    ret = run_js <<-JS
         var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
         var store = grid.getStore().data.items;
         var view = grid.getView();
         var ret = [];
         for (var i = 0; i < store.length; ++i) {
             var row = [];
             var j = 0;
             for (const [key, value] of Object.entries(store[i].data)) {
                 if (key != 'id') {
                    var cell = view.getCell(i, j);
                    row.push(#{get_expr});
                 }
                 j++;
             }
             ret.push(row);
         }
         return ret;
    JS
    ret
  end

  def get_grid_info
    cwraw, rc = run_js <<-JS
         var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
         var cols = grid.getColumnManager().getColumns();
         var ret = [];
         for (col of cols)
            ret.push(col.lastBox);
         return [ret, grid.getStore().data.items.length];
    JS
    cw = cwraw.map do |cwr|
      h = {}
      h[:x] = cwr['x']
      h[:width] = cwr['width']
      h
    end
    [cw, rc]
  end

  def iterate_area(rect, a_of_a)
    ulx, uly, lrx, lry = rect.values
    sub = []
    a_of_a[uly...lry].each_with_index do |row, row_idx|
      subrow = []
      row[ulx...lrx].each_with_index do |cell, col_idx|
        subrow << cell
        yield(cell, row_idx, col_idx) if block_given?
      end
      sub << subrow
    end
    sub
  end

  def check_dim(dim, dim_size, dim_area, ui_colors, ui_data, by_col: true)
    return unless dim.count > 0

    color_sets = Array.new(dim_size) { Set.new }

    iterate_area(dim_area, ui_colors) do |cell, row_idx, col_idx|
      idx = by_col ? col_idx : row_idx
      color_sets[idx] << cell
    end

    color_sets.each do |the_set|
      expect(the_set.length).to eq(1)
      expect(the_set.to_a[0]).to match(/^rgb/)
    end

    all_set = color_sets.map(&:to_a).reduce(&:+).to_set
    expect(all_set.length).to eq(color_sets.length)

    dim_data = iterate_area(dim_area, ui_data)
    keys = dim.map { |d| Marty::DataGrid.export_keys(d) }
    piv = by_col ?
            keys.each_with_object([]) do |key_array, piv_array|
              key_array.each_with_index do |v, idx|
                (piv_array[idx] ||= []) << v
              end
            end : keys
    expect(piv.map(&:flatten)).to eq(dim_data)
  end

  def check_grid(grid_name, perm, all_cells)
    grid = Marty::DataGrid.mcfly_pt('infinity').find_by(name: grid_name)
    hdim = grid.metadata.select { |md| md['dir'] == 'h' }
    vdim = grid.metadata.select { |md| md['dir'] == 'v' }
    data = grid.data
    ui_data = get_grid
    row_cnt = ui_data.length
    col_cnt = ui_data[0].length
    ui_colors = get_grid(to_get: :colors)

    vdim_size = vdim.count
    hdim_size = hdim.count
    vdim_area =  { ulx: 0, uly: hdim_size, lrx: vdim_size, lry: row_cnt }
    hdim_area =  { ulx: vdim_size, uly: 0, lrx: col_cnt - 1, lry: hdim_size }
    data_area =  {
      ulx: vdim_size,
      uly: hdim_size,
      lrx: col_cnt - 1, # minus comment column
      lry: row_cnt
    }

    # check the dim areas
    check_dim(vdim, vdim_size, vdim_area, ui_colors, ui_data) if vdim_size > 0
    check_dim(hdim, hdim_size, hdim_area, ui_colors, ui_data, by_col: false) if
      hdim_size > 0

    # data section color check
    colors = Set.new
    iterate_area(data_area, ui_colors) do |cell, _row_idx, _col_idx|
      colors << cell
    end
    expect(colors.length).to eq(1)
    expect(colors.to_a[0]).to eq('')

    # check that data section matches actual grid data
    data_data = iterate_area(data_area, ui_data)
    expect(struct_compare(data_data, grid.data)).to be_falsey

    grid_setup
    all_disabled = {
      'Insert Row Above'    => :disabled,
      'Insert Row Below'    => :disabled,
      'Insert Column Left'  => :disabled,
      'Insert Column Right' => :disabled,
      'Delete Row'          => :disabled,
      'Delete Column'       => :disabled
    }
    col_disabled = all_disabled + {
      'Insert Row Above'    => :enabled,
      'Insert Row Below'    => :enabled,
      'Delete Row'          => :enabled
    }
    row_disabled = all_disabled + {
      'Insert Column Left'  => :enabled,
      'Insert Column Right' => :enabled,
      'Delete Column'       => :enabled
    }
    all_enabled = Hash[all_disabled.map { |k, _v| [k, :enabled] }]

    # in the data area, what is allowed depends on whether there
    # are only vdims, hdims, or both
    data_menu = if ['view', 'edit_data'].include?(perm)
                then all_disabled
                elsif hdim.count == 0
                  col_disabled
                elsif vdim.count == 0
                  row_disabled
                else
                  all_enabled
                end

    areas = [[data_area, data_menu],
             [vdim_area, perm == 'edit_all' && vdim.count > 0 ? col_disabled :
                           all_disabled],
             [hdim_area, perm == 'edit_all' && hdim.count > 0 ? row_disabled :
                           all_disabled]]

    areas.each do |area, menu_exp|
      xrangefull = (area[:ulx]...area[:lrx]).to_a
      yrangefull = (area[:uly]...area[:lry]).to_a

      # grid has only v or h dims
      next if xrangefull.empty? || yrangefull.empty?

      xrange = all_cells ? xrangefull : [xrangefull[0], xrangefull[-1]].uniq
      yrange = all_cells ? yrangefull : [yrangefull[0], yrangefull[-1]].uniq

      xrange.each do |x|
        yrange.each do |y|
          m = context_click(x, y, 0)
          expect(m).to eq(menu_exp)
        end
      end
    end
  end

  def validate_grid(gn)
    grid = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid' + gn)
    fix = 'spec/fixtures/misc'
    exp_data = JSON.parse(File.read("#{fix}/grid#{gn}_final_data.json"))
    expect(grid.data).to eq(exp_data)
    exp_meta = JSON.parse(File.read("#{fix}/grid#{gn}_final_meta.json"))
    grid_meta = grid.metadata.map do |md|
      [md['dir'], md['attr'], md['keys']]
    end.sort
    expect(grid_meta).to eq(exp_meta)

    return unless File.exist?("#{fix}/grid#{gn}_final_comments.json")

    exp_comments = JSON.parse(File.read("#{fix}/grid#{gn}_final_comments.json"))
    expect(grid.comments).to eq(exp_comments)
  end

  it 'dg perms' do
    log_in_as('marty')
    go_to_data_grids
    dgv = netzke_find('data_grid_view')
    grids = dgv.get_col_vals('name', 6)
    set_one = lambda do |grid, perms|
      pos = grids.index(grid) + 1
      dgv.select_row(pos)
      press('Edit')
      wait_for_ajax
      view_combo = netzke_find('Can View', 'combobox')
      edit_data_combo = netzke_find('Can Edit Data', 'combobox')
      edit_all_combo = netzke_find('Can Edit All', 'combobox')
      view_combo.select_values(perms['view'].join(', '))
      edit_data_combo.select_values(perms['edit_data'].join(', '))
      edit_all_combo.select_values(perms['edit_all'].join(', '))
      press('OK')
      wait_for_ajax
    end
    dg1p = { 'view' => ['Data Grid Editor'],
             'edit_data' => ['Data Grid Editor'],
             'edit_all' => ['Admin'] }
    dg2p = { 'view' => ['Data Grid Editor', 'User Manager'],
             'edit_data' => ['Data Grid Editor', 'User Manager'],
            'edit_all' => ['Data Grid Editor', 'Admin'] }
    set_one.call('DataGrid1', dg1p)
    set_one.call('DataGrid2', dg2p)
    dg1 = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid1')
    dg2 = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid2')
    fixexp = lambda do |orig_h|
      orig_h.each_with_object({}) do |(k, v), h|
        h[k] = v.map do |vals|
          vals.split(' ').map(&:downcase).join('_')
        end.sort
      end
    end
    exp1 = fixexp.call(dg1p)
    exp2 = fixexp.call(dg2p)
    fixgot = ->(orig_h) { Hash[orig_h.map { |k, v| [k, v.sort] }] }
    got1 = fixgot.call(dg1.permissions)
    got2 = fixgot.call(dg2.permissions)
    cmp1 = struct_compare(got1, exp1)
    cmp2 = struct_compare(got2, exp2)
    expect(cmp1).to be_falsey
    expect(cmp2).to be_falsey

    set_one.call('DataGrid1', @no_perm)
    set_one.call('DataGrid2', @no_perm)
    dg1 = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid1')
    dg2 = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid2')
    expect(dg1.permissions).to eq(@no_perm)
    expect(dg2.permissions).to eq(@no_perm)
  end

  it 'show grid' do
    log_in_as('marty')
    go_to_data_grids
    dgv = netzke_find('data_grid_view')
    grids = dgv.get_col_vals('name', 5)
    pos = grids.index('DataGrid1') + 1
    dgv.select_row(pos)
    press('Show Grid')
    expect(page).to have_content('Antwerp')
  end

  def set_perm(perm)
    p = @no_perm + (perm ? { perm => ['data_grid_editor'] } : {})
    Marty::DataGrid.mcfly_pt('infinity').each do |dg|
      dg.permissions = p
      dg.save!
    end
  end

  it 'dg context menus' do
    log_in_as('grid_user')
    go_to_data_grids(admin: false)
    context_test_all = ENV['DG_FEATURE_FULL'] == 'true'
    [[nil, nil],
     ['edit_all', context_test_all],
     ['edit_data', false],
     ['view', false]].each do |perm, all_cells|
      set_perm(perm)

      press('Refresh')
      # 'press('Refresh')' sometimes doesn't work locally, in that case
      # uncomment the following line:
      page.find('.x-tool-refresh').click

      dgv = netzke_find('data_grid_user_view')
      grids = dgv.get_col_vals('name', 5)

      if perm.nil?
        expect(grids).to be_nil
        next
      end

      grids.each do |grid|
        pos = grids.index(grid) + 1

        begin
          dgv.select_row(pos)
        rescue StandardError => e
          sleep 1
          dgv.select_row(pos)
        end

        press('Edit Grid')
        wait_for_ajax
        check_grid(grid, perm, all_cells)
        expect(page).not_to have_content('Save') if perm == 'view'
        press('Cancel')
        wait_for_ajax
      end
    end
  end

  it 'dg editor' do
    set_perm('edit_all')
    log_in_as('grid_user')
    go_to_data_grids(admin: false)
    dgv = netzke_find('data_grid_user_view')
    grids = dgv.get_col_vals('name', 9)

    # now test some editing, saving, and cancel logic
    get_latest = lambda do
      Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid5')
    end
    grid = get_latest.call
    grid.constraint = '>=0<200'
    grid.save!

    # check boolean validation
    pos = grids.index('DataGrid6') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(3, 0, 'bad')
    press('Save')
    expect(page).to have_content('error: some entries failed constraint or '\
                                 'data type check')
    press('OK')
    wait_for_ajax
    press('Cancel')
    press('Yes')
    wait_for_ajax
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup
    cell_edit(3, 0, 'true')
    cell_edit(3, 2, 'true')
    press('Save')
    wait_for_ajax
    dg_data = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid6').
                data.flatten
    expect(dg_data).to eq([true, false, true, false])

    # class validation
    pos = grids.index('DataGrid7') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(1, 0, 'bad')
    press('Save')
    expect(page).to have_content('error: some entries failed constraint or '\
                                 'data type check')
    press('OK')
    wait_for_ajax
    press('Cancel')
    press('Yes')
    wait_for_ajax
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup
    cell_edit(1, 0, 'DataGrid8')
    press('Save')
    wait_for_ajax
    dg_data = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid7').
                data.flatten
    expect(dg_data).to eq(['DataGrid8', 'DataGrid3', 'DataGrid4', 'DataGrid5'])

    # int validation
    pos = grids.index('DataGrid8') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(2, 0, 'bad')
    press('Save')
    expect(page).to have_content('error: some entries failed constraint or '\
                                 'data type check')
    press('OK')
    wait_for_ajax
    press('Cancel')
    press('Yes')
    wait_for_ajax
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup
    cell_edit(2, 0, 123)
    press('Save')
    wait_for_ajax
    dg_data = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid8').
                data.flatten
    expect(dg_data).to eq([123, 360, 120, 180, 240, 360])

    # string grid
    pos = grids.index('DataGrid9') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(2, 0, 'bad')
    press('Save')
    wait_for_ajax
    dg_data = Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid9').
                data.flatten
    expect(dg_data).to eq(['bad', '360', '120', '180', '240', '360'])

    pos = grids.index('DataGrid5') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup
    cell_edit(2, 3, 'abc')
    cell_edit(3, 3, '250')
    press('Save')
    expect(page).to have_content('error: some entries failed constraint or '\
                                 'data type check')
    press('OK')
    colors = get_grid(to_get: :colors)
    qtips = get_grid(to_get: :qtips)
    expect(colors[3][2]).to eq('rgb(255, 177, 129)')
    expect(colors[3][3]).to eq('rgb(255, 129, 129)')
    expect(qtips[3][2]).to eq('failed type check')
    expect(qtips[3][3]).to eq('failed constraint check')
    expect(qtips[0][0]).to eq(false)
    expect(qtips[0][2]).to eq('mortgage_type')
    expect(qtips[1][2]).to eq('PLST')
    expect(qtips[3][0]).to eq('property_state')
    expect(qtips[3][1]).to eq('property_county_name')

    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(2, 3, '')
    cell_edit(3, 3, '')
    press('Save')
    wait_for_ajax
    colors = get_grid(to_get: :colors)
    expect(colors).to be_nil

    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(4, 3, '')
    press('Save')
    wait_for_ajax
    colors = get_grid(to_get: :colors)

    # colors should be nil because grid closed(saved) successfully
    expect(colors).to be_nil

    press('Edit Grid')
    wait_for_ajax
    grid_setup
    colors = get_grid(to_get: :colors)
    qtips = get_grid(to_get: :qtips)

    # make sure data area of colors and qtips are all blank/false
    expect(colors[3..-1].flat_map { |r| r[2..-1] }.to_set).
      to eq(Set.new(['']))
    expect(qtips[3..-1].flat_map { |r| r[2..-2] }.to_set).
      to eq(Set.new([false]))

    # Comments qtip
    expect(qtips[3..-1].map { |r| r[-1] }.to_set).
      to eq(Set.new(['Comments']))

    press('Cancel')

    press('Edit Grid')
    wait_for_ajax
    grid_setup
    cell_edit(2, 3, '123.456')
    cell_edit(3, 3, '1.1')
    cell_edit(4, 3, '2.2')
    cell_edit(2, 2, 'yo')
    press('Save')
    expect(page).to have_content('error: bad range yo')
    press('OK')
    cell_edit(2, 2, '>=1')

    cell_edit(2, 0, 'xyz')
    press('Save')
    expect(page).to have_content('error: instance xyz of Gemini::MortgageType'\
                                 ' not found')
    press('OK')
    cell_edit(2, 0, 'Conventional')

    cell_edit(0, 3, 'xyz')
    press('Save')
    expect(page).to have_content("error: no such Gemini::EnumState: 'xyz'")
    press('OK')
    cell_edit(0, 3, 'AK')

    press('Save')
    wait_for_ajax
    grid = get_latest.call
    expect(grid.data[0][0]).to eq(123.456)
    press('Edit Grid')
    wait_for_ajax

    colors = get_grid(to_get: :colors)
    qtips = get_grid(to_get: :qtips)
    expect(colors[3][2]).to eq('')
    expect(colors[3][3]).to eq('')
    expect(qtips[3][2]).to eq(false)
    expect(qtips[3][2]).to eq(false)

    # each time we change the grid, grid_setup needs to ask
    # JS for the updated grid info
    grid_setup
    cell_edit(2, 3, '0.0')
    press('Cancel')
    exp = 'You are closing a window that has unsaved changes'
    expect(page).to have_content(exp)
    press('No')
    find(:xpath, ".//div[contains(@class,'x-tool-close')]").click
    exp = 'You are closing a window that has unsaved changes'
    expect(page).to have_content(exp)
    press('No')
    press('Cancel')
    exp = 'You are closing a window that has unsaved changes'
    expect(page).to have_content(exp)
    press('Yes')
    grid = get_latest.call
    expect(grid.data[0][0]).to eq(123.456)

    press('Edit Grid')
    wait_for_ajax
    grid_setup
    context_click(1, 9, 1, click: true)
    grid_setup
    ['AR', 'Abc', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].each_with_index do |v, idx|
      cell_edit(idx, 10, v)
    end
    context_click(5, 12, 0, click: true)
    grid_setup
    ['TN', 'Xyz', 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1].each_with_index do |v, idx|
      cell_edit(idx, 12, v)
    end
    context_click(5, 5, 2, click: true)
    grid_setup
    (['FHA', nil, '<1'] + [100] * 11).each_with_index do |v, idx|
      cell_edit(5, idx, v) if v
    end
    context_click(13, 1, 3, click: true)
    grid_setup
    (['VA', nil, '>5'] + [100] * 11).each_with_index do |v, idx|
      cell_edit(14, idx, v)
    end
    grid_setup
    context_click(2, 4, 4, click: true)
    grid_setup
    context_click(2, 1, 5, click: true)
    wait_for_ajax
    press('Save')
    wait_for_ajax
    sleep 1
    validate_grid('5')

    pos = grids.index('DataGrid2') + 1
    dgv.select_row(pos)
    begin
      press('Edit Grid')
      press('Edit Grid')
    rescue StandardError => e
    end
    wait_for_ajax
    grid_setup
    context_click(2, 3, 2, click: true)
    grid_setup
    ['99', 'StrNew', 'StrNew2', 'Strnew3', 'StrNew4', 'StrNew5',
     '>10000000<11000000', '12345'].each_with_index do |v, idx|
      cell_edit(2, idx, v)
    end
    press('Save')
    sleep 1
    validate_grid('2')

    pos = grids.index('DataGrid1') + 1
    dgv.select_row(pos)
    begin
      press('Edit Grid')
      press('Edit Grid')
    rescue StandardError => e
    end
    wait_for_ajax
    grid_setup
    cell_edit(7, 2, '11111')
    context_click(3, 4, 1, click: true)

    ['5|4', 'Abc', 'Def', 'QQQ', 'ZZZ', 'AAA', '>5000011<6000000', 765].
      each_with_index do |v, idx|
      cell_edit(idx, 5, v)
    end

    7.times do |idx|
      cell_edit(8, idx, "Comment ##{idx}")
    end

    press('Save')
    sleep 1
    validate_grid('1')
  end
end
