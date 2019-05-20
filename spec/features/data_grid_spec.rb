require 'spec_helper'
require 'marty_rspec'

feature 'data grid view', js: true do
  before(:all) do
    marty_whodunnit
    @save_file = "/tmp/save_#{Process.pid}.psql"
    save_clean_db(@save_file)
    Marty::Script.load_scripts
    dt = DateTime.parse('2017-1-1')
    p = File.expand_path('../../fixtures/csv/rule', __FILE__)
    klass = Marty::DataGrid
    f = '%s/%s.csv' % [p, klass.to_s.sub(/(Gemini|Marty)::/, '')]
    Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ',')
  end
  after(:all) do
    restore_clean_db(@save_file)
  end
  def go_to_my_data_grids
    press('Applications')
    press('Data Grids')
    expect(page).to have_content 'Data Grids'
  end

  it 'rule workflow' do
    log_in_as('marty')
    go_to_my_data_grids
    mrv = netzke_find('data_grid_view')
    mrv.select_row(4)
    wait_for_ajax
    press("Edit Grid")
    wait_for_ajax
    grid = page.all(:xpath,
                    ".//div[contains(@class, 'x-grid-item-container')]").
             detect{ |e| e.text.include?('flavor / param') }

    gridx = grid.native.rect.x
    height = grid.native.size.height
    perr = (height / 3).to_i
    cols=page.all(:xpath, ".//div[contains(@role, 'columnheader') and "\
                          "contains(@class, 'x-column-header')]").select do
      |c|
      (0..10).map(&:to_s).include?(c.text)
    end.map { |c| n=c.native; [n.text.to_i, [n.rect.x, n.rect.width]] }
    colh = Hash[cols]

    context_click2 = lambda do |col, row, menuidx, click=false|
      colx = colh[col][0]
      colw = colh[col][1]
      xpos = (colx + colw/2).to_i - gridx
      ypos = (perr*row + perr/2).to_i
      mxpos = xpos + 20
      mypos = ypos + (perr*menuidx+ perr/2).to_i
      puts "#{xpos}/#{ypos}"
      page.driver.browser.action.
        move_to(grid.native, xpos, ypos).context_click.perform
      page.driver.browser.action.move_to(grid.native, mxpos, mypos).click.
        release.perform if click
    end
    menu_get = lambda do
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
    cell_edit = lambda do |col, row, text|
      colx = colh[col][0]
      colw = colh[col][1]
      xpos = (colx + colw/2).to_i - gridx
      ypos = (perr*row + perr/2).to_i
      puts "#{xpos}/#{ypos}"
      page.driver.browser.action.
        move_to(grid.native, xpos, ypos).double_click.
        send_keys([:control ,'a'], :delete, text, :enter).perform
    end
    grid_get = lambda do
      run_js <<-JS
         var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
         var store = grid.getStore().data.items;
         var ret = [];

         for (var i = 0; i < store.length; ++i) {
             var row = {};

             for (const [key, value] of Object.entries(store[i].data)) {
                 row[key] = value;
             }
             ret.push(row);
         }
         return ret;
      JS
    end
    binding.pry
  end
end
