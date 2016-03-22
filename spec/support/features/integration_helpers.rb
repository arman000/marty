module IntegrationHelpers

  # provides Rspec-y way to group/document longer feature tests
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
    RSpec.configuration.reporter.by_started(message)
  end

  def by_end
    RSpec.configuration.reporter.by_ended()
  end

  # test setup helpers
  def populate_test_users
    Rails.configuration.marty.auth_source = 'local'
    Rails.configuration.marty.local_password = 'marty'

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

  def log_in(username, password="marty")
    wait_for_ready(10)

    if first("a[data-qtip='Current user']")
      return if first("a[contains(text(), '#{username}')]")
      log_out
    end

    find(:xpath, "//span", text: 'Sign in', match: :first, wait: 5).click
    fill_in("login", :with => username)
    fill_in("password", :with => password)
    press("OK")
    wait_for_ajax
    find('a', text: username, match: :first, wait: 5)
  end

  def log_in_as(username, password="marty")
    ensure_on("/")
    log_in(username, password)
    ensure_on("/")
  end

  def log_out
    press("Current user")
    press("Sign out")
  end

  def log_out_as(name)
    press(name)
    press("Sign out")
    #find('span', text: "Sign in", match: :first, wait: 5)
    #ensure_on("/")
  end

  def press component, c_type='button'
    begin
      cmp = first("a[data-qtip='#{component}']")
      cmp ||= first(:xpath, ".//a", text: "#{component}")
      cmp ||= find(:btn, component, match: :first)
      cmp.click
    rescue
      find_by_id(ext_cmp_id(component, c_type)).click
    end
  end

  def popup message = ''
    by_start('popup: ' + message)
    wait_for_ready
    yield
    close_window
    by_end
  end

  def close_window
    find(:xpath, '//img[contains(@class, "x-tool-close")]').click
  end

  def wait_until
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep(0.1) until value = yield
      value
    end
  end

  def wait_for_ready wait_time = nil
    if wait_time
      find(:status, 'Ready', wait: wait_time)
    else
      find(:status, 'Ready')
    end
  end

  def wait_for_ajax
    begin
      all(:status, 'Busy...', minimum: 1)
    rescue Capybara::ExpectationNotMet => e
      Rails.logger.warn(e)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
    end
    wait_for_ready(10)
    wait_until { !ajax_loading? }
    wait_for_ready
  end

  def ajax_loading?
    page.execute_script <<-JS
      return Netzke.ajaxIsLoading() || Ext.Ajax.isLoading();
    JS
  end

  def zoom_out component
    el = find_by_id(id_of(component))
    el.native.send_keys([:control, '0'])
    el.native.send_keys([:control, '-'])
    el.native.send_keys([:control, '-'])
    el.native.send_keys([:control, '-'])
  end

  def wait_for_element(seconds_to_wait = 2.0, sleeptime = 0.1)
    res = nil
    iterations = (seconds_to_wait / sleeptime).to_i
    while !res && iterations > 0
      begin
        res = yield
      rescue
        sleep sleeptime
        iterations -= 1
      end
    end
    res
  end

  def show_submenu text
    page.execute_script <<-JS
       Ext.ComponentQuery.query('menuitem[text="#{text}"] menu')[0].show()
    JS
  end

  # component helpers
  def ext_cmp_id title, c_type='button'
    id = page.execute_script("Ext.ComponentQuery.query(
      \"#{c_type}{isVisible(true)}[text='#{title}']\")[0].id")
    "##{id}"
  end

  def set_field_value value, field_type
    page.execute_script <<-JS
      var field = Ext.ComponentQuery.query("#{field_type}")[0];
      field.setValue("#{value}")
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
    page.execute_script <<-JS
      var area = Ext.ComponentQuery.query('textarea[name="#{textarea}"]')[0];
      area.setValue("#{text}");
    JS
  end

  def btn_disabled? text, grid
    res = page.execute_script(<<-JS)
      var grid = #{grid};
      var btn = Ext.ComponentQuery.query('[text="#{text}"]', grid)[0];
      return !btn || btn.disabled;
    JS
  end

  # Netzke component lookups, arguments for helper methods below
  # (i.e. component) require JS scripts instead of objects
  def gridpanel arg
    # use these to generate component args for below
    if /^\d+$/.match(arg)
      <<-JS
        Ext.ComponentQuery.query('gridpanel')[#{arg}]
      JS
    else
      <<-JS
        Ext.ComponentQuery.query('gridpanel[name="#{arg}"]')[0]
      JS
    end
  end

  def treepanel arg
    # unused
    # use these to generate component args for below
    if /^\d+$/.match(arg)
      <<-JS
        Ext.ComponentQuery.query('treepanel')[#{arg}]
      JS
    else
      <<-JS
        Ext.ComponentQuery.query('treepanel[name="#{arg}"]')[0]
      JS
    end
  end

  # Netzke helper methods
  # Grid helpers
  def id_of component
    page.execute_script <<-JS
      var c = #{component};
      return c.view.id
    JS
  end

  def row_count grid
    result =  page.execute_script <<-JS
      var grid = #{grid};
      return grid.getStore().getCount();
    JS
    result.to_i
  end

  def row_total grid
    result =  page.execute_script <<-JS
      var grid = #{grid};
      return grid.getStore().getTotalCount();
    JS
    result.to_i
  end

  def row_modified_count grid
    result =  page.execute_script <<-JS
      var grid = #{grid};
      return grid.getStore().getUpdatedRecords().length;
    JS
    result.to_i
  end

  def data_desc row, grid
    desc = page.execute_script <<-JS
      var grid = #{grid};
      var r = grid.getStore().getAt(#{row.to_i-1});
      return r.data.desc
    JS

    desc.gsub(/<.*?>/, '')
  end

  def click_col col, grid
    el_id = page.execute_script <<-JS
      var grid = #{grid};
      return Ext.ComponentQuery.query('gridcolumn[text="#{col}"]', grid)[0].id;
    JS

    find_by_id(el_id).click
  end

  def col_values(col, grid, cnt, init=0)
    #does not validate the # of rows
    # FOR NETZKE 1.0, use this line... for columns
    # r.get('association_values')['#{col}'] :
    items = wait_for_element do
      result = page.execute_script <<-JS
        var grid = #{grid},
          column = Ext.ComponentQuery.query('gridcolumn[name=\"#{col}\"]', grid)[0],
          obj = [];
        for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
          var r = grid.getStore().getAt(i);
          var value = column.assoc ? r.get('meta').associationValues['#{col}'] :
                                     r.get('#{col}');

          if(value instanceof Date){
            obj.push(value.toISOString().substring(0,value.toISOString().indexOf('T')));
          } else {
            obj.push(value);
          }
        };
        return obj;
      JS
      result if result.count == cnt
    end
    items
  end

  def validate_col_values(col, val, grid, cnt, init=0)
    # FOR NETZKE 1.0, use this line... for columns
    # r.get('association_values')['#{col}'] :
    obj = page.execute_script <<-JS
      var grid = #{grid},
        column = Ext.ComponentQuery.query('gridcolumn[name=\"#{col}\"]', grid)[0];
      for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
        var r = grid.getStore().getAt(i);
        var value = column.assoc ? r.get('meta').associationValues['#{col}'] :
                                   r.get('#{col}');
        if (value != #{val}) { return false };
      };
      return true;
    JS
  end

  def cell_value(row, col, component)
    # FOR NETZKE 1.0, use this line... for columns
    # r.get('association_values')['#{col}'] :
    page.execute_script <<-JS
      var grid = #{component},
        column = Ext.ComponentQuery.query('gridcolumn[name=\"#{col}\"]', grid)[0],
        r      = grid.getStore().getAt(#{row.to_i-1});
      return column.assoc ? r.get('meta').associationValues['#{col}'] :
                            r.get('#{col}');
    JS
  end

  def select_row(row, component, click_after=true)
    elid = wait_for_element do
      page.execute_script <<-JS
      var grid = #{component};
      grid.getSelectionModel().select(#{row.to_i-1});
      var node = grid.getView().getNode(#{row.to_i-1});
      return node.id;
    JS
    end
    find("##{elid}").click if click_after
    wait_for_ajax
    return elid
  end

  def select_rows(row0, row1, component)
    elids = wait_for_element do
      page.execute_script <<-JS
      var grid = #{component};
      var result = [];
      for (var i = #{row0.to_i - 1}; i < #{row1.to_i}; i++) {
        grid.getSelectionModel().select(i, i != #{row0.to_i - 1});
        result.push(grid.getView().getNode(i).id);
      };
      return result;
    JS
    end
    elids
  end

  def set_row_vals row, grid, fields
    js_set_fields = fields.each_pair.map do |k,v|
      "r.set('#{k}', '#{v}');"
    end.join

    page.execute_script <<-JS
      var grid = #{grid};
      var r = grid.getStore().getAt(#{row.to_i-1});
      #{js_set_fields}
    JS
  end

  def validate_row_values row, grid, fields
    # FOR NETZKE 1.0, use this line... for columns
    # r.get('association_values')['#{col}'] :
    js_get_fields = fields.each_key.map do |k|
      "var column = Ext.ComponentQuery.query('gridcolumn[name=\"#{k}\"]', grid)[0];\n"+
        "var value = column.assoc ? r.get('meta').associationValues['#{k}'] : " +
        "r.get('#{k}');\n" +
        "if(value instanceof Date){\n"+
        "   obj['#{k}'] = value.toISOString().substring(0, \n"+
        "value.toISOString().indexOf('T'));\n"+
        "} else {\n"+
        "   obj['#{k}'] = value;\n"+
        "}\n"
    end.join

    obj = page.execute_script <<-JS
      var grid = #{grid};
      var r = grid.getStore().getAt(#{row.to_i-1});
      var obj = {};
      #{js_get_fields}
      return obj;
    JS

    expect(obj).to eq fields.stringify_keys
  end

  def sorted_by? col, grid, direction = 'asc'
    # FOR NETZKE 1.0, use this line... for columns
    # r.get('association_values')['#{col}'] :
    page.execute_script <<-JS
      var grid = #{grid},
        column = Ext.ComponentQuery.query('gridcolumn[name=\"#{col}\"]', grid)[0],
        colValues = [];

      grid.getStore().each(function(r){
        var val = column.assoc ? r.get('meta').associationValues['#{col}'] :
                                 r.get('#{col}');
        if (val) colValues.#{direction == 'asc' ? 'push' : 'unshift'}(val);
      });

      return colValues.toString() === Ext.Array.sort(colValues).toString();
    JS
  end

  # Grid Combobox Helpers
  def select_grid_combobox(selection, row, field, grid)
    result = false
    while !result
      result = page.execute_script <<-JS
         var grid = #{grid},
           combo  = Ext.ComponentQuery.query('netzkeremotecombo[name="#{field}"]')[0],
           editor = grid.getPlugin('celleditor'), now;

         editor.startEditByPosition({ row:#{row.to_i-1},
           column:grid.headerCt.items.findIndex('name', '#{field}') });

//         if (combo.getStore().loading == true) { return false; }

         combo.onTriggerClick();
         rec = combo.findRecordByDisplay('#{selection}');
         if (rec == false) { return false; }
         combo.setValue(rec);
         combo.onTriggerClick();
         editor.completeEdit();
         return true
       JS
    end
  end

  def grid_combobox_values(row, field, grid)
    start_edit_grid_combobox(row, field, grid)
    # hacky: delay for combobox to render, assumes that the combobox is not empty
    result = wait_for_element do
      page.execute_script <<-JS
        var grid = #{grid},
          combo  = Ext.ComponentQuery.query('netzkeremotecombo[name="#{field}"]')[0],
          r      = [],
          editor = grid.getPlugin('celleditor'),
          store  = combo.getStore();

        // force a retry if the store is still loading
        if (store.loading == true) { throw "store not loaded yet"; }

        for(var i = 0; i < combo.getStore().getCount(); i++) {
          r.push(combo.getStore().getAt(i).get('text'));
        };
        editor.completeEdit();
        return r;
      JS
    end
    result
  end

  def get_grid_combobox_val(index, row, field, grid)
    start_edit_grid_combobox(row, field, grid)

    result = wait_for_element do
      page.execute_script <<-JS
        var grid = #{grid},
          combo  = Ext.ComponentQuery.query('netzkeremotecombo[name="#{field}"]')[0],
          editor = grid.getPlugin('celleditor'),
          val    = combo.getStore().getAt(#{index}).get('text');
        editor.completeEdit();
        return val;
      JS
    end
    result
  end

  def start_edit_grid_combobox(row, field, grid)
    page.execute_script <<-JS
      var grid = #{grid},
        combo  = Ext.ComponentQuery.query('netzkeremotecombo[name="#{field}"]')[0],
        editor = grid.getPlugin('celleditor');

      editor.startEditByPosition({ row:#{row.to_i-1}, column:grid.headerCt.items.findIndex('name', '#{field}') });
      now = new Date().getTime();
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
    page.execute_script <<-JS
      var grid = #{grid},
          editor = grid.getPlugin('celleditor');

      editor.startEditByPosition({ row:#{row.to_i-1},
        column:grid.headerCt.items.findIndex('name', '#{field}') });
      return editor.activeEditor.field.inputId;
    JS
  end

  def end_edit(row, field, grid)
    page.execute_script <<-JS
      var grid = #{grid},
          editor = grid.getPlugin('celleditor');
      editor.completeEdit();
    JS
  end

  # Combobox Helpers
  def select_combobox(values, combo_label)
    page.execute_script <<-JS
      var values = #{values.split(/,\s*/)};
      var combo = Ext.ComponentQuery.query("combobox[fieldLabel='#{combo_label}']")[0];
      combo = combo || Ext.ComponentQuery.query("combobox[name='#{combo_label}']")[0];
      var arr = new Array();
      for(var i=0; i < values.length; i++) {
        arr[i] = combo.findRecordByDisplay(values[i]);
      }
      combo.select(arr);
      if (combo.isExpanded) { combo.onTriggerClick(); }
    JS
  end

  def combobox_values(combo_label)
    page.execute_script <<-JS
      var combo = Ext.ComponentQuery.query("combobox[fieldLabel='#{combo_label}']")[0];
      combo = combo || Ext.ComponentQuery.query("combobox[name='#{combo_label}']")[0];
      values = [];
      combo.getStore().each(
        function(r) { values.push(r.data.text || r.data.field1); });
      return values;
    JS
  end

  def click_combobox combo_label
    page.execute_script <<-JS
      var combo = Ext.ComponentQuery.query("combobox[fieldLabel='#{combo_label}']")[0];
      combo = combo || Ext.ComponentQuery.query("combobox[name='#{combo_label}']")[0];
      combo.onTriggerClick();
    JS
    wait_until { !ajax_loading? }
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

# monkey patching rspec for use with instafail & by method
module RSpec::Core
  class Reporter
    if defined?(NOTIFICATIONS)
      NOTIFICATIONS.push("by_started", "by_finished")
    end

    def by_started(message)
      notify :by_started, message
    end

    def by_ended(message = '')
      notify :by_ended, message
    end
  end

  unless defined?(Reporter::NOTIFICATIONS)
    class Formatters::DocumentationFormatter
      def by_started(message)
      end
      def by_ended(message = '')
      end
    end
  end
end
