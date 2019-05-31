require 'spec_helper'
require 'marty_rspec'

feature 'data grid view', js: true do
  before(:all) do
    marty_whodunnit
    @save_file = "/tmp/save_#{Process.pid}.psql"
    save_clean_db(@save_file)
    Marty::Script.load_scripts
    dt = DateTime.parse('2017-1-1')
    p = File.expand_path('../../fixtures/misc', __FILE__)
    Dir.glob(p + '/data_grid_*.txt').each do |path|
      n = File.basename(path, '.txt').camelize
      Marty::DataGrid.create_from_import(n, File.read(path), dt)
    end
  end

  after(:all) do
    restore_clean_db(@save_file)
  end

  def go_to_data_grids
    press('Applications')
    press('Data Grids')
    expect(page).to have_content 'Data Grids'
  end

  # setup the info for the ext grid
  def grid_setup
    widths, rows = get_grid_info
    @grid = page.all(:xpath,
                     ".//div[contains(@class, 'x-grid-item-container')]").
              reject { |e| e.text.include?('2016-12-31') }.first
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
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).double_click.
      send_keys([:control, 'a'], :delete, text, :enter).perform
    # for some reason sometimes this fails
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).double_click.
      send_keys([:control, 'a'], :delete, text, :enter).perform
  end

  def get_grid(to_get: :values)
    get_expr = case to_get
               when :values
                 'row.push(value);'
               when :colors
                 'row.push(grid.getView().getCell(i,j).style.backgroundColor);'
               end
    ret = run_js <<-JS
         var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
         var store = grid.getStore().data.items;
         var ret = [];
         for (var i = 0; i < store.length; ++i) {
             var row = [];
             var j = 0;
             for (const [key, value] of Object.entries(store[i].data)) {
                 if (key != 'id')
                    #{get_expr}
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
    hdim_area =  { ulx: vdim_size, uly: 0, lrx: col_cnt, lry: hdim_size }
    data_area =  { ulx: vdim_size, uly: hdim_size, lrx: col_cnt,
                           lry: row_cnt }
    # check the dim areas
    check_dim(vdim, vdim_size, vdim_area, ui_colors, ui_data) if vdim_size > 0
    check_dim(hdim, hdim_size, hdim_area, ui_colors, ui_data, by_col: false) if
      hdim_size > 0

    # data section color check
    colors = Set.new
    iterate_area(data_area, ui_colors) do |cell, row_idx, col_idx|
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
    all_enabled = Hash[all_disabled.map { |k, v| [k, :enabled] }]

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

  it 'dg editor' do
    log_in_as('marty')
    go_to_data_grids
    dgv = netzke_find('data_grid_view')
    grids = dgv.get_col_vals('name', 5)
    [['edit_all', true],
     ['edit_data', false],
     ['view', false]].each do |perm, all_cells|
      grids.each do |grid|
        Marty::Config['grid_edit_edit_perm'] = perm
        Marty::Config['grid_edit_save_perm'] = perm
        pos = grids.index(grid) + 1
        dgv.select_row(pos)
        press('Edit Grid')
        wait_for_ajax
        check_grid(grid, perm, all_cells)
        expect(page).not_to have_content('Save') if perm == 'view'
        press('Cancel')
        wait_for_ajax
      end
    end
    Marty::Config['grid_edit_edit_perm'] = 'edit_all'
    Marty::Config['grid_edit_save_perm'] = 'edit_all'

    # now test some editing, saving, and cancel logic
    get_latest = lambda do
      Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid5')
    end
    pos = grids.index('DataGrid5') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup
    cell_edit(2, 3, 'abc')
    press('Save')
    expect(page).to have_content('error: bad float "abc"')
    press('OK')
    cell_edit(2, 3, '123.456')
    press('Save')
    wait_for_ajax
    grid = get_latest.call
    expect(grid.data[0][0]).to eq(123.456)
    press('Edit Grid')
    wait_for_ajax
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
    grid = get_latest.call
    exp_data = JSON.parse(File.read('spec/fixtures/misc/grid_final_data.json'))
    expect(grid.data).to eq(exp_data)
    exp_meta = JSON.parse(File.read('spec/fixtures/misc/grid_final_meta.json'))
    grid_meta = grid.metadata.map do |md|
      [md['dir'], md['attr'], md['keys']]
    end.sort
    expect(grid_meta).to eq(exp_meta)

    Marty::Config['grid_edit_save_perm'] = 'view'
    count = 1
    begin
      press('Edit Grid')
      wait_for_ajax
      grid_setup
      cell_edit(2, 3, '123.456')
    rescue StandardError => e
      if count > 0
        sleep 1
        retry
      end
      count -= 1
    end
    press('Save')
    errexp = 'error: save_grid: entered with view permissions'
    expect(page).to have_content(errexp)
    press('OK')
    wait_for_ajax
    context_click(2, 4, 4, click: true)
    Marty::Config['grid_edit_save_perm'] = 'edit_data'
    press('Save')
    errexp = 'error: save_grid: grid modification not allowed'
    expect(page).to have_content(errexp)
    exp_log = JSON.parse(File.read('spec/fixtures/misc/grid_log_errs.json'))
    expect(Marty::Log.all.select(:message, :details).attributes).to eq(exp_log)
  end
end
