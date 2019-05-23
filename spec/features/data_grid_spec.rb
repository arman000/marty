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

  # setup the info for the ext grid.  unfortunately I can't figure out
  # how to ask Ext for the row count in the grid, so passing it in
  def grid_setup(rows)
    @grid = page.all(:xpath,
                     ".//div[contains(@class, 'x-grid-item-container')]").
              reject { |e| e.text.include?('2016-12-31') }.first
    @gridx = @grid.native.rect.x
    @gridy = @grid.native.rect.y
    height = @grid.native.size.height
    @perr = (height / rows).to_i
    cols0 = page.all(:xpath, ".//div[contains(@role, 'columnheader') and "\
                          "contains(@class, 'x-column-header')]").select do |c|
      (0..100).map(&:to_s).include?(c.text)
    end
    cols = cols0.map do |c|
      n = c.native
      [n.text.to_i, [n.rect.x, n.rect.width]]
    end
    @colh = Hash[cols]
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
  end

  def get_grid(values: true)
    get = values ? 'row.push(value);' :
            'row.push(grid.getView().getCell(i,j+1).style.backgroundColor);'
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
                    #{get}
                 j++;
             }
             ret.push(row);
         }
         return ret;
    JS
    ret
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

  def check_grid(grid_name)
    grid = Marty::DataGrid.mcfly_pt('infinity').find_by(name: grid_name)
    hdim = grid.metadata.select { |md| md['dir'] == 'h' }
    vdim = grid.metadata.select { |md| md['dir'] == 'v' }
    data = grid.data
    ui_data = get_grid
    row_cnt = ui_data.length
    col_cnt = ui_data[0].length
    ui_colors = get_grid(values: false)

    vdim_size = vdim.count == 0 ? 1 : vdim.count
    hdim_size = hdim.count == 0 ? 1 : hdim.count
    label_area = { ulx: 0, uly: 0, lrx: vdim_size, lry: hdim_size }
    vdim_area =  { ulx: 0, uly: hdim_size, lrx: vdim_size, lry: row_cnt }
    hdim_area =  { ulx: vdim_size, uly: 0, lrx: col_cnt, lry: hdim_size }
    data_area =  { ulx: vdim_size, uly: hdim_size, lrx: col_cnt,
                           lry: row_cnt }
    # check the dim areas
    check_dim(vdim, vdim_size, vdim_area, ui_colors, ui_data)
    check_dim(hdim, hdim_size, hdim_area, ui_colors, ui_data, by_col: false)

    # data and label section color check
    [data_area, label_area].each do |area|
      colors = Set.new
      iterate_area(area, ui_colors) do |cell, row_idx, col_idx|
        colors << cell
      end
      expect(colors.length).to eq(1)
      expect(colors.to_a[0]).to eq('')
    end

    # check that data section matches actual grid data
    data_data = iterate_area(data_area, ui_data)
    expect(struct_compare(data_data, grid.data)).to be_falsey

    # check that the label section looks right
    label_data = iterate_area(label_area, ui_data)
    label_exp = Array.new(hdim_size) { Array.new(vdim_size) }
    hdim_labels = hdim.map { |d| d['attr'] }
    vdim_labels = vdim.map { |d| d['attr'] }
    hdim_labels.each_with_index do |label, idx|
      label_exp[idx][-1] = label
    end
    vdim_labels.each_with_index do |label, idx|
      cur = label_exp.last[idx]
      label_exp.last[idx] = cur.is_a?(String) ? label + ' / ' + cur : label
    end
    expect(struct_compare(label_data, label_exp)).to be_falsey

    # check context menu for each area to make sure that inserts/deletes
    # are allowed only in the correct parts of the grid
    grid_setup(hdim_size + grid.data.length)
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
    data_menu = if hdim.count == 0
                  col_disabled
                elsif vdim.count == 0
                  row_disabled
                else
                  all_enabled
                end
    areas = [[data_area, data_menu],
             [label_area, all_disabled],
             [vdim_area, vdim.count > 0 ? col_disabled : all_disabled],
             [hdim_area, hdim.count > 0 ? row_disabled : all_disabled]]
    areas.each do |area, menu_exp|
      (area[:ulx]...area[:lrx]).each do |x|
        (area[:uly]...area[:lry]).each do |y|
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
    grids.each do |grid|
      pos = grids.index(grid) + 1
      dgv.select_row(pos)
      press('Edit Grid')
      wait_for_ajax
      check_grid(grid)
      press('Cancel')
      wait_for_ajax
    end if false

    # now test some editing, saving, and cancel logic
    get_latest = lambda do
      Marty::DataGrid.mcfly_pt('infinity').find_by(name: 'DataGrid5')
    end
    pos = grids.index('DataGrid5') + 1
    dgv.select_row(pos)
    press('Edit Grid')
    wait_for_ajax
    # test saving and validation etc
    grid_setup(12) # 12 rows of data
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
    grid_setup(12)
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
    grid_setup(12) # 12 rows of data
    context_click(1, 9, 1, click: true)
    grid_setup(13) # 12 rows of data
    ['AR', 'Abc', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].each_with_index do |v, idx|
      cell_edit(idx, 10, v)
    end
    context_click(5, 12, 0, click: true)
    grid_setup(14) # 12 rows of data
    ['TN', 'Xyz', 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1].each_with_index do |v, idx|
      cell_edit(idx, 12, v)
    end
    context_click(5, 5, 2, click: true)
    grid_setup(14) # 12 rows of data
    (['FHA', nil, '<1'] + [100] * 11).each_with_index do |v, idx|
      cell_edit(5, idx, v) if v
    end
    context_click(13, 1, 3, click: true)
    grid_setup(14) # 12 rows of data
    (['VA', nil, '>5'] + [100] * 11).each_with_index do |v, idx|
      cell_edit(14, idx, v)
    end
    grid_setup(14) # 12 rows of data
    context_click(2, 4, 4, click: true)
    grid_setup(13) # 12 rows of data
    context_click(2, 1, 5, click: true)
    wait_for_ajax
    press('Save')
    wait_for_ajax
    grid = get_latest.call
    exp_data = JSON.parse(File.read('spec/fixtures/misc/grid_final_data.json'))
    expect(grid.data).to eq(exp_data)
    exp_meta = JSON.parse(File.read('spec/fixtures/misc/grid_final_meta.json'))
    grid_meta = grid.metadata.map do |md|
      [md['dir'], md['attr'], md['keys']]
    end.sort
    expect(grid_meta).to eq(exp_meta)
  end
end
