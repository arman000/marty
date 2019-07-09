module Marty; module RSpec; module Netzke
  MAX_WAIT_TIME = 5.0

  def by message, _level = 0
    wait_for_ready(10)
    pending(message) unless block_given?
    yield
  end

  alias and_by by

  ############################################################################
  # navigation helpers
  ############################################################################

  def ensure_on(path)
    visit(path) unless current_path == path
  end

  def log_in(username, password)
    wait_for_ready(25)

    begin
      if first("a[data-qtip='Current user']")
        log_out
        wait_for_ajax
      end
    rescue StandardError
      # ignore error
    end

    find(:xpath, '//span', text: 'Sign in', match: :first, wait: 5).click
    fill_in('login', with: username)
    fill_in('password', with: password)
    press('OK')
    wait_for_ajax
  end

  def log_in_as(username)
    Rails.configuration.marty.auth_source = 'local'

    ensure_on('/')
    log_in(username, Rails.configuration.marty.local_password)
    ensure_on('/')
  end

  def log_out
    press('Current user')
    press('Sign out')
  end

  def press button_name, index_of = 0
    wait_for_element do
      begin
        cmp = first("a[data-qtip='#{button_name}']") rescue nil
        cmp ||= all(:xpath, './/a', text: button_name.to_s).
                  detect { |c| c.text == button_name.to_s } rescue nil
        cmp ||= find(:btn, button_name, match: :first)
        cmp.click
        true
      rescue StandardError
        find_by_id(ext_button_id(button_name, index_of), visible: :all).click
        true
      end
    end
  end

  def popup _message = ''
    wait_for_ready
    yield if block_given?
    close_window
  end

  def close_window
    find(:xpath, '//div[contains(@class, "x-tool-close")]', wait: 5).click
  end

  ############################################################################
  # stability functions
  ############################################################################

  def wait_for_ready wait_time = nil
    if wait_time
      find(:status, 'Ready', wait: wait_time)
    else
      find(:status, 'Ready')
    end
  end

  def wait_for_ajax wait_time = 10
    wait_for_ready(wait_time)
    wait_for_element { !ajax_loading? }
    wait_for_ready
  end

  def ajax_loading?
    page.execute_script <<-JS
      return Netzke.ajaxIsLoading() || Ext.Ajax.isLoading();
    JS
  end

  def wait_for_element(seconds_to_wait = 2.0, sleeptime = 0.1)
    res = nil
    start_time = current_time = Time.now
    while !res && current_time - start_time < seconds_to_wait
      begin
        res = yield
      rescue StandardError
      ensure
        sleep sleeptime
        current_time = Time.now
      end
    end
    res
  end

  ############################################################################
  # note that netzke_find doesn't actually find the component (as in Capybara)
  # instead, it prepares the javascript to be run on the component object
  ############################################################################

  def netzke_find(name, c_type = 'gridpanel')
    case c_type
    when 'combobox'
      Marty::RSpec::Components::NetzkeCombobox.new(name)
    else
      Marty::RSpec::Components::NetzkeGrid.new(name, c_type)
    end
  end

  def run_js js_str, seconds_to_wait = MAX_WAIT_TIME, sleeptime = 0.1
    result = wait_for_element(seconds_to_wait, sleeptime) do
      page.document.synchronize { @res = page.execute_script(js_str) }
      @res
    end
    result
  end

  ############################################################################
  # component helpers
  ############################################################################

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

  def set_field_value value, field_type = 'textfield', name = ''
    args1 = name.empty? ? '' : "[fieldLabel='#{name}']"
    args2 = name.empty? ? '' : "[name='#{name}']"
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

  ############################################################################
  # helpers
  ############################################################################

  def id_of component
    res = run_js <<-JS
      var c = #{component};
      return c.view.id;
    JS
    res
  end

  def btn_disabled? text
    res = wait_for_element do
      find_by_id(ext_button_id(text))
    end
    !res[:class].match(/disabled/).nil?
  end

  def click_checkbox(name)
    q = %Q(checkbox[fieldLabel="#{name}"])
    item_id = run_js "return  Ext.ComponentQuery.query('#{q}')[0].getItemId();"
    find_by_id(item_id).click
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

  def press_key_in(key, el_id)
    kd = key.downcase
    use_key = ['enter', 'return'].include?(kd) ? kd.to_sym : key
    el = find_by_id(el_id.to_s)
    el.native.send_keys(use_key)
  end

  def simple_escape! text
    text.gsub!(/(\r\n|\n)/, '\\n')
    text.gsub!(/\t/, '\\t')
  end

  def simple_escape text
    text.gsub(/(\r\n|\n)/, '\\n').
      gsub(/\t/, '\\t').
      gsub(/"/, '\"')
  end

  def type_in(type_s, el_id, enter: false)
    el = find_by_id(el_id.to_s)
    type_s.each_char do |key|
      el.native.send_keys(key)
    end
    el.send_keys(:enter) if enter
  end

  private

  ############################################################################
  # ExtJS/Netzke helper javascripts:
  #   Netzke component lookups, arguments for helper methods
  #   (i.e. component) require JS scripts instead of objects
  ############################################################################

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

  def ext_var(ext_find_str, var_name = 'ext_c')
    <<-JS
      var #{var_name} = #{ext_find_str};
    JS
  end

  def ext_netzkecombo field
    <<-JS
      #{ext_find(ext_arg('netzkeremotecombo', name: field))}
    JS
  end

  def ext_combo combo_label, c_name = 'combo'
    <<-JS
      #{ext_var(ext_find(ext_arg('combobox', fieldLabel: combo_label)), c_name)}
      #{c_name} = #{c_name} ||
                  #{ext_find(ext_arg('combobox', name: combo_label))};
    JS
  end

  def ext_celleditor(grid_name = 'grid')
    <<-JS
      #{grid_name}.getPlugin('celleditor')
    JS
  end

  def ext_row(row, grid_name = 'grid')
    <<-JS
      #{grid_name}.getStore().getAt(#{row})
    JS
  end

  def ext_col(col, grid_name = 'grid')
    <<-JS
      #{ext_find(ext_arg('gridcolumn', name: "\"#{col}\""), grid_name)}
    JS
  end

  def ext_cell_val(row, col, grid, var_str = 'value')
    <<-JS
      #{ext_var(grid, 'grid')}
      #{ext_var(ext_col(col, 'grid'), 'col')}
      #{ext_var(ext_row(row, 'grid'), 'row')}
      var #{var_str} = col.assoc ?
        row.get('association_values')['#{col}'] :
        row.get('#{col}');
    JS
  end
end end end
