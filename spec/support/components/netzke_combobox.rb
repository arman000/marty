require 'capybara/dsl'
require 'rspec/matchers'
require Pathname.new(__FILE__).parent.parent.to_s + '/netzke'

module Marty; module RSpec; module Components
  class NetzkeCombobox
    include Netzke
    include Capybara::DSL
    # include RSpec::Matchers

    attr_reader :name, :combobox

    def initialize(name)
      @name = name
      if /^\d+$/.match(name)
        @combobox = ext_find('combobox', nil, name)
      else
        @combobox = ext_combo(name)
      end
    end

    def select_values(values)
      run_js <<-JS
        var values = #{values.split(/,\s*/)};
        #{combobox}
        var arr = new Array();
        for(var i=0; i < values.length; i++) {
          arr[i] = combo.findRecordByDisplay(values[i]);
        }
        combo.select(arr);
        if (combo.isExpanded) {
          combo.onTriggerClick();
        };
        return true;
        JS
    end

    def get_values
      run_js <<-JS
        var values = [];
        #{combobox}
        combo.getStore().each(
          function(r) { values.push(r.data.text || r.data.field1); });
        return values;
      JS
    end

    def click
      run_js <<-JS
        #{combobox}
        combo.onTriggerClick();
        return true;
        JS
      wait_for_element { !ajax_loading? }
    end
  end
end end end
