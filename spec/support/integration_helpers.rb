module Marty::IntegrationHelpers

  MAX_WAIT_TIME = 5.0

  # without rspec-by gem, essentially works as documentation & wait
  def by message, level=0
    wait_for_ready(10)
    pending(message) unless block_given?
    begin
      by_start(message)
      yield
    ensure
      by_end
    end
  end

  alias and_by by

  def by_start message
    if RSpec.configuration.reporter.respond_to? :by_started
      RSpec.configuration.reporter.by_started(message)
    end
  end

  def by_end
    if RSpec.configuration.reporter.respond_to? :by_ended
      RSpec.configuration.reporter.by_ended()
    end
  end

  # test setup helpers
  def populate_test_users
    (1..2).each { |i|
      Rails.configuration.marty.roles.each { |role_name|
        username = "#{role_name}#{i}"
        next if Marty::User.find_by_login(username)

        user = Marty::User.new
        user.firstname = user.login = username
        user.lastname = username
        user.active = true
        user.save

        role = Marty::Role.find_by_name(role_name.to_s)

        rails "Oops unknown role: #{role_name}. Was db seeded?" unless role

        user_role = Marty::UserRole.new
        user_role.user = user
        user_role.role = role
        user_role.save!
      }
    }

    # also create an anon user
    user = Marty::User.new
    user.login = user.firstname = user.lastname = "anon"
    user.active = true
    user.save
  end

  # navigation helpers
  def ensure_on(path)
    visit(path) unless current_path == path
  end

  def log_in(username, password)
    wait_for_ready(10)

    if first("a[data-qtip='Current user']")
      log_out
      wait_for_ajax
    end

    find(:xpath, "//span", text: 'Sign in', match: :first, wait: 5).click
    find(:xpath, "//span", text: 'Password', match: :first, wait: 5)
    fill_in("login", :with => username)
    fill_in("password", :with => password)
    press("OK")
    wait_for_ajax
  end

  def log_in_as(username)
    Rails.configuration.marty.auth_source = 'local'

    ensure_on("/")
    log_in(username, Rails.configuration.marty.local_password)
    ensure_on("/")
  end

  def log_out
    press("Current user")
    press("Sign out")
  end

  def press button_name, index_of = 0
    wait_for_element do
      begin
        cmp = first("a[data-qtip='#{button_name}']")
        cmp ||= first(:xpath, ".//a", text: "#{button_name}")
        cmp ||= find(:btn, button_name, match: :first)
        cmp.click
        true
      rescue
        find_by_id(ext_button_id(button_name, index_of), visible: :all).click
        true
      end
    end
  end

  def popup message = ''
    by_start('popup: ' + message)
    wait_for_ready
    yield if block_given?
    close_window
    by_end
  end

  def close_window
    find(:xpath, '//img[contains(@class, "x-tool-close")]', wait: 5).click
  end

  def wait_for_ready wait_time = nil
    if wait_time
      find(:status, 'Ready', wait: wait_time)
    else
      find(:status, 'Ready')
    end
  end

  def wait_for_ajax
    wait_for_ready(10)
    wait_for_element { !ajax_loading? }
    wait_for_ready
  end

  def ajax_loading?
    page.execute_script <<-JS
      return Netzke.ajaxIsLoading() || Ext.Ajax.isLoading();
    JS
  end

  def zoom_out component
    wait_for_element do
      el_id = id_of(component)
      el = find_by_id(el_id)
      el.native.send_keys([:control, '0'])
      el.native.send_keys([:control, '-'])
      el.native.send_keys([:control, '-'])
      el.native.send_keys([:control, '-'])
    end
  end

  def wait_for_element(seconds_to_wait = 2.0, sleeptime = 0.1)
    res = nil
    start_time = current_time = Time.now
    while !res && current_time - start_time < seconds_to_wait
      begin
        res = yield
      rescue
      ensure
        sleep sleeptime
        current_time = Time.now
      end
    end
    res
  end

  def run_js js_str, seconds_to_wait = MAX_WAIT_TIME, sleeptime = 0.1
    result = wait_for_element(seconds_to_wait, sleeptime) do
      res = nil
      page.document.synchronize { res = page.execute_script(js_str) }
      res.nil? ? true : res
    end
    result
  end

  # Component helpers
  def show_submenu text
    run_js <<-JS
      Ext.ComponentQuery.query('menuitem[text="#{text}"] menu')[0].show()
    JS
  end

  def ext_button_id title, scope = nil, index_of = 0
    c_str = ext_arg('button{isVisible(true)}', text: "\"#{title}\"")
    run_js <<-JS
      return #{ext_find(c_str, scope, index_of)}.id;
    JS
  end

  def set_field_value value, field_type='textfield', name=''
    args1 = name.empty? ? "" : "[fieldLabel='#{name}']"
    args2 = name.empty? ? "" : "[name='#{name}']"
    run_js <<-JS
      var field = Ext.ComponentQuery.query("#{field_type}#{args1}")[0];
      field = field || Ext.ComponentQuery.query("#{field_type}#{args2}")[0];
      field.setValue("#{value}");
      return true;
    JS
  end

  def get_total_pages
    # will get deprecated by Netzke 1.0
    result = find(:xpath, ".//div[contains(@id, 'tbtext-')]",
                  text: /^of (\d+)$/, match: :first).text
    result.split(' ')[1].to_i
  end

  def simple_escape! text
    text.gsub!(/(\r\n|\n)/, "\\n")
    text.gsub!(/\t/, "\\t")
  end

  def paste text, textarea
    # bit hacky: textarea doesn't like receiving tabs and newlines via fill_in
    simple_escape!(text)

    find(:xpath, ".//textarea[@name='#{textarea}']")
    run_js <<-JS
      #{ext_var(ext_find(ext_arg('textarea', name: textarea)), 'area')}
      area.setValue("#{text}");
    JS
  end

  def btn_disabled? text, grid
    res = wait_for_element do
      find_by_id(ext_button_id(text))
    end
    !res[:class].match(/disabled/).nil?
  end

  # Netzke component lookups, arguments for helper methods below
  # (i.e. component) require JS scripts instead of objects
  def ext_arg(component, c_args = {})
    res = component
    c_args.each do |k, v|
      res += "[#{k.to_s}=#{v.to_s}]"
    end
    res
  end

  def ext_find(ext_arg_str, scope = nil, index = 0)
    scope_str = scope.nil? ? '' : ", #{scope}"
    <<-JS
      Ext.ComponentQuery.query('#{ext_arg_str}'#{scope_str})[#{index}]
    JS
  end

  def ext_var(ext_find_str, var_name='ext_c')
    <<-JS
      var #{var_name} = #{ext_find_str};
    JS
  end

  def ext_netzkecombo field
    <<-JS
      #{ext_find(ext_arg('netzkeremotecombo', name: field))}
    JS
  end

  def ext_combo combo_label, c_name='combo'
    <<-JS
      #{ext_var(ext_find(ext_arg('combobox', fieldLabel: combo_label)), c_name)}
      #{c_name} = #{c_name} ||
                  #{ext_find(ext_arg('combobox', name: combo_label))};
    JS
  end

  def ext_celleditor(grid_name='grid')
    <<-JS
      #{grid_name}.getPlugin('celleditor')
    JS
  end

  def ext_row(row, grid_name='grid')
    <<-JS
      #{grid_name}.getStore().getAt(#{row})
    JS
  end

  def ext_col(col, grid_name='grid')
    <<-JS
      #{ext_find(ext_arg('gridcolumn', name: "\"#{col}\""), grid_name)}
    JS
  end

  def ext_cell_val(row, col, grid, var_str = 'value')
    # FOR NETZKE 1.0, use this line for columns
    # r.get('association_values')['#{col}'] :
    <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_col(col, 'grid'), 'col')}
      #{ext_var(ext_row(row, 'grid'), 'row')}
      var #{var_str} = col.assoc ?
        row.get('meta').associationValues['#{col}'] :
        row.get('#{col}');
    JS
  end

  ####
  def gridpanel arg
    # use these to generate component args for below
    if /^\d+$/.match(arg)
      ext_find('gridpanel', nil, arg)
    else
      ext_find(ext_arg('gridpanel', name: arg))
    end
  end

  def treepanel arg
   if /^\d+$/.match(arg)
      ext_find('treepanel', nil, arg)
    else
      ext_find(ext_arg('treepanel', name: arg))
    end
  end

  # Netzke helper methods
  # Grid helpers
  def id_of component
    res = run_js <<-JS
      var c = #{component};
      return c.view.id;
    JS
    res
  end

  def row_count grid
    res = run_js <<-JS
      return #{grid}.getStore().getCount();
    JS
    res.to_i
  end

  def row_total grid
    res = run_js <<-JS
      return #{grid}.getStore().getTotalCount();
    JS
    res.to_i
  end

  def row_modified_count grid
    res = run_js <<-JS
      return #{grid}.getStore().getUpdatedRecords().length;
    JS
    res.to_i
  end

  def data_desc row, grid
    res = run_js <<-JS
      var r = #{grid}.getStore().getAt(#{row.to_i-1});
      return r.data.desc
    JS
    res.gsub(/<.*?>/, '')
  end

  def click_col col, grid
    run_js <<-JS
      #{ext_find(ext_arg('gridcolumn', text: col), grid)}.click();
    JS
  end

  def col_values(col, grid, cnt, init=0)
    #does not validate the # of rows
    run_js <<-JS
      var result = [];
      for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
        #{ext_cell_val('i', col, grid)}
        if(value instanceof Date){
          result.push(value.toISOString().substring(0,value.toISOString().indexOf('T')));
        } else {
          result.push(value);
        };
      };
      return result;
    JS
  end

  def validate_col_values(col, val, grid, cnt, init=0)
    run_js <<-JS
      for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
        #{ext_cell_val('i', col, grid)}
        if (value != #{val}) { return false };
      };
      return true;
    JS
  end

  def cell_value(row, col, grid)
    run_js <<-JS
      #{ext_cell_val(row.to_i - 1, col, grid)}
      return value;
    JS
  end

  def select_row(row, grid, click_after=true)
    resid = run_js(<<-JS, 10.0)
      #{ext_var(grid, 'grid')}
      grid.getSelectionModel().select(#{row.to_i-1});
      return grid.getView().getNode(#{row.to_i-1}).id;
    JS
    find_by_id(resid).click if click_after
    wait_for_ajax
    return resid
  end

  def set_row_vals row, grid, fields
    js_set_fields = fields.each_pair.map do |k,v|
      "r.set('#{k}', '#{v}');"
    end.join

    run_js <<-JS
      #{ext_var(ext_row(row.to_i - 1, grid), 'r')}
      #{js_set_fields}
    JS
  end

  def validate_row_values row, grid, fields
    js_get_fields = fields.each_key.map do |k|
      <<-JS
        var col = Ext.ComponentQuery.query('gridcolumn[name=\"#{k}\"]', grid)[0];
        var value = col.assoc ? r.get('meta').associationValues['#{k}'] :
                                r.get('#{k}');
        if (value instanceof Date) {
          obj['#{k}'] = value.toISOString().substring(0,
            value.toISOString().indexOf('T'));
        } else {
          obj['#{k}'] = value;
        };
      JS
    end.join

    res = run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_row(row.to_i - 1, 'grid'), 'r')}
      var obj = {};
      #{js_get_fields}
      return obj;
    JS
    wait_for_element { expect(res).to eq fields.stringify_keys }
  end

  def sorted_by? col, grid, direction = 'asc'
    run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_col(col, 'grid'), 'col')}
      var colValues = [];

      grid.getStore().each(function(r){
        var val = col.assoc ? r.get('meta').associationValues['#{col}'] :
                              r.get('#{col}');
        if (val) colValues.#{direction == 'asc' ? 'push' : 'unshift'}(val);
      });

      return colValues.toString() === Ext.Array.sort(colValues).toString();
    JS
  end

  # Grid Combobox Helpers
  def select_grid_combobox(selection, row, field, grid)
    run_js <<-JS
      #{start_edit_grid_combobox(row, field, grid)}

      rec = combo.findRecordByDisplay('#{selection}');
      if (rec == false) { return false; }
      combo.setValue(rec);
      combo.onTriggerClick();
      editor.completeEdit();
      return true
    JS
  end

  def grid_combobox_values(row, field, grid)
    run_js <<-JS
      #{start_edit_grid_combobox(row, field, grid)}
    JS

    # hacky: delay for combobox to render, assumes that the combobox is not empty
    run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_netzkecombo(field), 'combo')}
      var r = [];
      #{ext_var(ext_celleditor, 'editor')}
      var store = combo.getStore();

      // force a retry if the store is still loading
      if (store.loading == true) { throw "store not loaded yet"; }

      for(var i = 0; i < store.getCount(); i++) {
        r.push(store.getAt(i).get('text'));
      };

      editor.completeEdit();
      return r;
    JS
  end

  def get_grid_combobox_val(index, row, field, grid)
    run_js <<-JS
      #{start_edit_grid_combobox(row, field, grid)}
    JS

    run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_netzkecombo(field), 'combo')}
      #{ext_var(ext_celleditor, 'editor')}
      var val = combo.getStore().getAt(#{index}).get('text');
      editor.completeEdit();
      return val;
    JS
  end

  def start_edit_grid_combobox(row, field, grid)
    <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_netzkecombo(field), 'combo')}
      #{ext_var(ext_celleditor, 'editor')}

      editor.startEditByPosition({ row:#{row.to_i-1},
        column:grid.headerCt.items.findIndex('name', '#{field}') });

      var now = new Date().getTime();
      while(new Date().getTime() < now + 500) { }

      combo.onTriggerClick();
    JS
  end

  # Field edit/Key in Helpers
  def type_in(type_s, el_id)
    el = find_by_id("#{el_id}")
    el.native.clear()
    type_s.each_char do |key|
      el.native.send_keys(key)
    end
    el.send_keys(:enter)
  end

  def press_key_in(key, el_id)
    kd = key.downcase
    use_key = ['enter', 'return'].include?(kd) ? kd.to_sym : key
    el = find_by_id("#{el_id}")
    el.native.send_keys(use_key)
  end

  def id_of_edit_field(row, field, grid)
    res = run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_celleditor, 'editor')}

      editor.startEditByPosition({ row:#{row.to_i-1},
        column:grid.headerCt.items.findIndex('name', '#{field}') });
      return editor.activeEditor.field.inputId;
    JS
    res
  end

  def end_edit(row, field, grid)
    run_js <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_celleditor, 'editor')}
      editor.completeEdit();
      return true;
    JS
  end

  # Combobox Helpers
  def select_combobox(values, combo_label)
    run_js <<-JS
      var values = #{values.split(/,\s*/)};
      #{ext_combo(combo_label)}

      var arr = new Array();
      for(var i=0; i < values.length; i++) {
        arr[i] = combo.findRecordByDisplay(values[i]);
      }
      combo.select(arr);
      if (combo.isExpanded) { combo.onTriggerClick(); }
    JS
  end

  def combobox_values(combo_label)
    run_js <<-JS
      #{ext_combo(combo_label)}
      var values = [];
      combo.getStore().each(
        function(r) { values.push(r.data.text || r.data.field1); });
      return values;
    JS
  end

  def click_combobox combo_label
    run_js <<-JS
      #{ext_combo(combo_label)}
      combo.onTriggerClick();
    JS
    wait_for_element { !ajax_loading? }
  end

  # Capybara finders
  def custom_selectors
    Capybara.add_selector(:gridpanel) do
      xpath { |name| ".//div[contains(@id, '#{name}')] | " +
              ".//div[contains(@id, '#{name.camelize(:lower)}')]" }
    end
    Capybara.add_selector(:msg) do
      xpath { "//div[@id='msg-div']" }
    end
    Capybara.add_selector(:body) do
      xpath { ".//div[@data-ref='body']" }
    end
    Capybara.add_selector(:input) do
      xpath { |name| "//input[@name='#{name}']" }
    end
    Capybara.add_selector(:status) do
      xpath { |name| "//div[contains(@id, 'statusbar')]//div[text()='#{name}']" }
    end
    Capybara.add_selector(:btn) do
      xpath { |name| ".//span[text()='#{name}']" }
    end
    Capybara.add_selector(:refresh) do
      xpath { "//img[contains(@class, 'x-tool-refresh')]" }
    end
    Capybara.add_selector(:gridcolumn) do
      xpath { |name| ".//span[contains(@class, 'x-column-header')]" +
              "//span[text()='#{name}']" }
    end
  end
end
