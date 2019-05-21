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
      begin
        Marty::DataGrid.create_from_import(n, File.read(path), dt)
      rescue => e
        binding.pry
      end
    end
  end
  after(:all) do
    restore_clean_db(@save_file)
  end
  def go_to_my_data_grids
    press('Applications')
    press('Data Grids')
    expect(page).to have_content 'Data Grids'
  end

  def grid_setup
    @grid = page.all(:xpath,
                    ".//div[contains(@class, 'x-grid-item-container')]").
             detect{ |e| e.text.include?('flavor / param') }

    @gridx = @grid.native.rect.x
    height = @grid.native.size.height
    @perr = (height / 3).to_i
    cols=page.all(:xpath, ".//div[contains(@role, 'columnheader') and "\
                          "contains(@class, 'x-column-header')]").select do
      |c|
      (0..10).map(&:to_s).include?(c.text)
    end.map { |c| n=c.native; [n.text.to_i, [n.rect.x, n.rect.width]] }
    @colh = Hash[cols]
  end
  def context_click(col, row, menuidx, click=false)
    colx = @colh[col][0]
    colw = @colh[col][1]
    xpos = (colx + colw/2).to_i - @gridx
    ypos = (@perr*row + @perr/2).to_i
    mxpos = xpos + 20
    mypos = ypos + (@perr*menuidx+ @perr/2).to_i
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).context_click.perform
    page.driver.browser.action.move_to(@grid.native, mxpos, mypos).click.
      release.perform if click
  end
  def get_menu
      m=page.all(:xpath, ".//div[contains(@class, 'x-menu-item-default')]").to_a
      n=page.all(:xpath, ".//div[contains(@class, 'x-menu-item-disabled')]").to_a
      labels = ['Insert Row Above', 'Insert Row Below',
                'Insert Column Left', 'Insert Column Right',
                'Delete Row', 'Delete Column']
      en = m.select { |m| labels.include?(m.text) }.
             map { |m| [m.text, :enabled]}
      dis = n.select { |m| labels.include?(m.text) }.
             map { |m| [m.text, :disabled]}
      Hash[en+dis]
  end
  def cell_edit(col, row, text)
    colx = @colh[col][0]
    colw = @colh[col][1]
    xpos = (colx + colw/2).to_i - @gridx
    ypos = (@perr*row + @perr/2).to_i
    page.driver.browser.action.
      move_to(@grid.native, xpos, ypos).double_click.
      send_keys([:control ,'a'], :delete, text, :enter).perform
  end
  def get_grid(values=true)
    get = values ? "row.push(value);" :
            "row.push(grid.getView().getCell(i,j+1).style.backgroundColor);"
    ret = run_js <<-JS

         var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
/*
         var grids = Ext.ComponentQuery.query('grid');
         var grid = grids.find(function(v) {
                return v.name=='data_grid_edit_grid'
                });
         grids.forEach(function(grid) {
             console.log(grid.name);
         });
*/
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
    #
  end
  def check_grid(grid_name)
    get_latest = lambda do
      Marty::DataGrid.mcfly_pt('infinity').find_by(name: grid_name)
    end
    grid = get_latest.call()
    hdim = grid.metadata.select { |md| md['dir'] == 'h' }
    vdim = grid.metadata.select { |md| md['dir'] == 'v' }
    data = grid.data
    ui_data = get_grid
    row_cnt = ui_data.length
    col_cnt = ui_data[0].length
    # colors check
    ui_colors = get_grid(false)

    vdim_size = vdim.count == 0 ? 1 : vdim.count
    hdim_size = hdim.count == 0 ? 1 : hdim.count
    label_area = {ulx: 0, uly: 0, lrx: vdim_size, lry: hdim_size}
    vdim_area =  {ulx: 0, uly: hdim_size, lrx: vdim_size, lry: row_cnt}
    hdim_area =  {ulx: vdim_size, uly: 0, lrx: col_cnt, lry: hdim_size}
    data_area =  {ulx: vdim_size, uly: hdim_size, lrx: col_cnt,
                           lry: row_cnt}
    iterate_area = lambda do |rect, a_of_a, &block|
      ulx, uly, lrx, lry = rect.values
      sub = []
      a_of_a[uly...lry].each_with_index do |row, row_idx|
        subrow = []
        row[ulx...lrx].each_with_index do |cell, col_idx|
          subrow << cell
          block.call(cell, row_idx, col_idx) if block
        end
        sub << subrow
      end
      sub
    end
    # vertical dims
    if vdim.count > 0
      vert_color_sets = vdim_size.times.map { Set.new }
      iterate_area.call(vdim_area, ui_colors) do |cell, row_idx, col_idx|
        vert_color_sets[col_idx] << cell
      end
      vert_color_sets.each do |theset|
        expect(theset.length).to eq(1)
        expect(theset.to_a[0]).to match(/^rgb/)
      end
      all_set = vert_color_sets.map(&:to_a).reduce(&:+).to_set
      expect(all_set.length).to eq(vert_color_sets.length)

      vdim_data = iterate_area.call(vdim_area, ui_data)
      keys = vdim.map { |d| Marty::DataGrid.export_keys(d) }

      piv = keys.each_with_object([]) do |key_array, piv_array|
        key_array.each_with_index do |v, idx|
          (piv_array[idx] ||= []) << v
        end
      end
      expect(piv.map(&:flatten)).to eq(vdim_data)
    end
    # horizontal dims
    if hdim.count > 0
      horiz_color_sets = hdim_size.times.map { Set.new }
      iterate_area.call(hdim_area, ui_colors) do |cell, row_idx, col_idx|
        horiz_color_sets[row_idx] << cell
      end
      horiz_color_sets.each do |theset|
        expect(theset.length).to eq(1)
        expect(theset.to_a[0]).to match(/^rgb/)
      end
      all_set = horiz_color_sets.map(&:to_a).reduce(&:+).to_set
      expect(all_set.length).to eq(horiz_color_sets.length)

      hdim_data = iterate_area.call(hdim_area, ui_data)
    end

    # data and label section
    [data_area, label_area].each do |area|
      colors = Set.new
      iterate_area.call(area, ui_colors) do |cell, row_idx, col_idx|
        colors << cell
      end
      expect(colors.length).to eq(1)
      expect(colors.to_a[0]).to eq('')
      data_data = iterate_area.call(data_area, ui_data)
      label_data = iterate_area.call(label_area, ui_data)
    end

  end

  it 'dg editor' do
    log_in_as('marty')
    go_to_my_data_grids
    dgv = netzke_find('data_grid_view')
    grids = dgv.get_col_vals('name', 5)
    grids.each do |grid|

      pos = grids.index(grid) + 1
      dgv.select_row(pos)
      press('Edit Grid')
      check_grid(grid)
      press('Cancel')
      wait_for_ajax
    end
  end
end
