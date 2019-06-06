require 'capybara/dsl'
require 'rspec/matchers'
require Pathname.new(__FILE__).parent.parent.to_s + '/netzke'

module Marty; module RSpec; module Components
  class NetzkeGrid
    include Netzke
    include Capybara::DSL
    # include RSpec::Matchers

    attr_reader :name, :grid

    def initialize(name, c_type)
      # for now, also allows treepanel
      @name = name
      if /^\d+$/.match(name)
        @grid = ext_find(c_type, nil, name)
      else
        @grid = ext_find(ext_arg(c_type, name: name))
      end
    end

    def id
      res = run_js <<-JS
          var c = #{grid};
          return c.view.id;
        JS
      res
    end

    def row_count
      res = run_js <<-JS
          return #{grid}.getStore().getTotalCount();
        JS
      res.to_i
    end

    def page_size
      res = run_js <<-JS
          return #{grid}.getStore().pageSize();
        JS
      res.to_i
    end

    alias :row_total :row_count

    def row_modified_count
      res = run_js <<-JS
          return #{grid}.getStore().getUpdatedRecords().length;
        JS
      res.to_i
    end

    def data_desc row
      res = run_js <<-JS
          var r = #{grid}.getStore().getAt(#{row.to_i - 1});
          return r.data.desc
        JS
      res.gsub(/<.*?>/, '')
    end

    def click_col col
      el = run_js <<-JS
          #{ext_var(grid, 'grid')}
          return #{ext_find(ext_arg('gridcolumn', text: col), 'grid')}.id
        JS

      find('#' + el).click
    end

    # filter_col and filter_col_toggle expect sortable column
    #   might need to allow to specify the number of :down to send.
    #   for now, four :downs to get to the filter, :right opens it
    #    then enter value and press return
    def filter_col(col, value)
      el = run_js <<-JS
          #{ext_var(grid, 'grid')}
          return #{ext_find(ext_arg('gridcolumn', text: col), 'grid')}.id
        JS

      c = find('#' + el)
      c.send_keys([:down, :down, :down, :down, :right, value, :return])
      sleep 1.0
      c.click
    end

    def filter_col_toggle(col)
      el = run_js <<-JS
          #{ext_var(grid, 'grid')}
          return #{ext_find(ext_arg('gridcolumn', text: col), 'grid')}.id
        JS

      c = find('#' + el)
      c.send_keys([:down, :down, :down, :down, ' ', :escape])
      sleep 1.0
    end

    def get_col_vals(col, cnt = row_count, init = 0, date_only = true)
      # NOTE: does not validate the # of rows
      run_js <<-JS
          var result = [];
          for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
            #{ext_cell_val('i', col, grid)}
            if(value instanceof Date) {
                if (#{date_only}){
                  result.push(value.toISOString().split('T')[0]);
                }
                else
                {
                  result.push(value.toISOString());
                }
            }
            else {
              result.push(value);
            };
          };
          return result;
        JS
    end

    def validate_col_vals(col, val, cnt, init = 0)
      run_js <<-JS
          for (var i = #{init}; i < #{init.to_i + cnt.to_i}; i++) {
            #{ext_cell_val('i', col, grid)}
            if (value != #{val}) { return false };
          };
          return true;
        JS
    end

    def cell_value(row, col)
      run_js <<-JS
          #{ext_cell_val(row.to_i - 1, col, grid)}
          return value;
        JS
    end

    def select_row(row, click_after = true)
      resid = run_js(<<-JS, 10.0)
          #{ext_var(grid, 'grid')}
          grid.getSelectionModel().select(#{row.to_i - 1});
          return grid.getView().getNode(#{row.to_i - 1}).id;
        JS
      el = find_by_id(resid)
      el.click if click_after
      wait_for_ajax
      el
    end

    def select_row_range(st, en)
      resid = run_js(<<-JS, 10.0)
          #{ext_var(grid, 'grid')}
          grid.getSelectionModel().selectRange(#{st - 1}, #{en - 1});
        JS
      wait_for_ajax
    end

    def set_row_vals row, fields
      js_set_fields = fields.each_pair.map do |k, v|
        "r.set('#{k}', '#{v}');"
      end.join

      run_js <<-JS
          #{ext_var(ext_row(row.to_i - 1, grid), 'r')}
          #{js_set_fields}
        JS
    end

    def get_row_vals row, fields = nil
      res = run_js <<-JS
          #{ext_var(grid, 'grid')}
          return Ext.encode(#{ext_row(row.to_i - 1, 'grid')}.data);
        JS
      temp = JSON.parse(res)
      parsed = temp.merge(temp.delete('association_values') || {})
      fields ? fields.each_with_object({}).each { |k, h| h[k] = parsed[k] } :
        parsed
    end

    def sorted_by? col, direction = 'asc'
      run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_col(col, 'grid'), 'col')}
          var colValues = [];

          grid.getStore().each(function(r){
            var val = col.assoc ? r.get('association_values')['#{col}'] :
                                  r.get('#{col}');
            if (val) colValues.#{direction == 'asc' ? 'push' : 'unshift'}(val);
          });

          return colValues.toString() === Ext.Array.sort(colValues).toString();
        JS
    end

    def grid_combobox_values(row, field)
      run_js <<-JS
          #{start_edit_combobox(row, field)}
        JS

      # hacky: delay for combobox to render, assumes combobox is not empty
      run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_netzkecombo(field), 'combo')}
          var r = [];
          #{ext_var(ext_celleditor, 'editor')}
          var store = combo.getStore();

          // force a retry if the store is still loading
          if (store.loading == true) {
            now = new Date().getTime();
            while(new Date().getTime() < now + 100) { }
            return false;
          }

          for(var i = 0; i < store.getCount(); i++) {
            r.push(store.getAt(i).get('text'));
          };

          editor.completeEdit();
          return r;
        JS
    end

    def get_combobox_val(index, row, field)
      run_js <<-JS
          #{start_edit_combobox(row, field)}
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

    def start_edit_grid_combobox(row, field)
      <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_netzkecombo(field), 'combo')}
          #{ext_var(ext_celleditor, 'editor')}

          editor.startEditByPosition({ row:#{row.to_i - 1},
            column:grid.headerCt.items.findIndex('name', '#{field}') });

          var now = new Date().getTime();
          while(new Date().getTime() < now + 500) { }

          combo.onTriggerClick();
        JS
    end

    def id_of_edit_field(row, field)
      res = run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_celleditor, 'editor')}

          editor.startEditByPosition({ row:#{row.to_i - 1},
            column:grid.headerCt.items.findIndex('name', '#{field}') });
          return editor.activeEditor.field.inputId;
        JS
      res
    end

    def end_edit(_row, _field)
      run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_celleditor, 'editor')}
          editor.completeEdit();
          return true;
        JS
    end

    def id_of_checkbox(row, field)
      res = run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_celleditor, 'editor')}

          editor.startEditByPosition({ row:#{row.to_i - 1},
            column:grid.headerCt.items.findIndex('name', '#{field}') });
          return editor.activeEditor.field.getItemId();
        JS
      res
    end

    ############################################################################
    # grid combobox helpers
    ############################################################################

    def select_combobox(selection, row, field)
      run_js <<-JS
          #{start_edit_combobox(row, field)}

          rec = combo.findRecordByDisplay('#{selection}');
          if (rec == false) { return false; }
          combo.setValue(rec);
          combo.onTriggerClick();
          editor.completeEdit();
          return true
        JS
    end

    def select_combobox_enum(selection, row, field)
      run_js <<-JS
          #{start_edit_combobox_enum(row, field)}

          rec = combo.findRecordByDisplay('#{selection}');
          if (rec == false) { return false; }
          combo.setValue(rec);
          editor.completeEdit();
          return true
        JS
    end

    def combobox_values(row, field)
      run_js <<-JS
          #{start_edit_combobox(row, field)}
        JS

      # hacky: delay for combobox to render, assumes that the combobox is not empty
      run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_netzkecombo(field), 'combo')}
          var r = [];
          #{ext_var(ext_celleditor, 'editor')}
          var store = combo.getStore();

          // force a retry if the store is still loading
          if (store.loading == true) {
              now = new Date().getTime();
              while(new Date().getTime() < now + 100) { }
              return false;
          }

          for(var i = 0; i < store.getCount(); i++) {
            r.push(store.getAt(i).get('text'));
          };

          editor.completeEdit();
          return r;
        JS
    end

    def get_combobox_val(index, row, field)
      run_js <<-JS
          #{start_edit_combobox(row, field)}
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_netzkecombo(field), 'combo')}
          #{ext_var(ext_celleditor, 'editor')}
          var val = combo.getStore().getAt(#{index}).get('text');
          editor.completeEdit();
          return val;
        JS
    end

    def start_edit_combobox(row, field)
      <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_netzkecombo(field), 'combo')}
          #{ext_var(ext_celleditor, 'editor')}

          editor.startEditByPosition({ row:#{row.to_i - 1},
            column:grid.headerCt.items.findIndex('name', '#{field}') });

          var now = new Date().getTime();
          while(new Date().getTime() < now + 500) { }

          combo.onTriggerClick();
        JS
    end

    def start_edit_combobox_enum(row, field)
      <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_combo(field, 'combo')}
          #{ext_var(ext_celleditor, 'editor')}

          editor.startEditByPosition({ row:#{row.to_i - 1},
            column:grid.headerCt.items.findIndex('name', '#{field}') });
        JS
    end

    def end_edit(_row, _field)
      run_js <<-JS
          #{ext_var(grid, 'grid')}
          #{ext_var(ext_celleditor, 'editor')}
          editor.completeEdit();
          return true;
        JS
    end
  end
end end end
