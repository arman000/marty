require 'spec_helper'

feature 'test netzke + pg_enum compatibility', js: true do

  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    populate_test_users
  end

  after(:all) do
    restore_clean_db(@clean_file)
  end

  it 'shows netzke grid combobox works w pg_enums' do

    lp_grid = netzke_find('loan_program_view')
    @amort_combo = netzke_find('amortization_type__name', 'combobox')
    @mortgage_combo = netzke_find('mortgage_type__name', 'combobox')
    @streamline_combo = netzke_find('streamline_type__name', 'combobox')
    @state_combo = netzke_find('enum_state', 'combobox')

    def setup_enum_form(stateVal)
      @amort_combo.click
      @amort_combo.select_values('Fixed')

      @mortgage_combo.click
      @mortgage_combo.select_values('FHA')

      @streamline_combo.click
      @streamline_combo.select_values('DURP')

      @state_combo.click
      @state_combo.select_values(stateVal)
    end

    log_in_as('dev1')

    by 'navigating to loan program screen' do
      press('Pricing Config.')
      press('Loan Programs')
    end


    and_by 'bring up new window' do
      press('Add')
    end

    and_by 'fill form minus enum value' do
      within(:gridpanel, 'add_window', match: :first) do
        fill_in("Name", with: 'a_l_p')

        @amort_combo.click
        @amort_combo.select_values('Fixed')

        @mortgage_combo.click
        @mortgage_combo.select_values('FHA')

        @streamline_combo.click
        @streamline_combo.select_values('DURP')

        press('OK')
      end

      wait_for_ajax
      expect(lp_grid.row_count).to eq(1)
    end

    and_by 'bring up new window' do
      press('Add')
    end

    and_by 'fill form w enum value & duplicated name (error), then fix' do
      within(:gridpanel, 'add_window', match: :first) do
        fill_in("Name", with: 'a_l_p')
        setup_enum_form("CA")
        press('OK')

        expect(find(:msg)).to have_content 'Name - record must be unique'

        fill_in("Name", with: 'a_l_p_2')
        press('OK')
      end

      wait_for_ajax
      aggregate_failures do
        expect(lp_grid.row_count).to eq(2)
        expect(lp_grid.get_row_vals(2)).to netzke_include({enum_state: 'CA'})
      end
    end

    and_by 'delete a row' do
      lp_grid.select_row(1)
      press('Delete')
      press('Yes')
      wait_for_ajax
      expect(lp_grid.row_count).to eq(1)
    end

    and_by 'bring up new window' do
      press('Add')
    end

    and_by 'fill form w --- for enum value' do
      within(:gridpanel, 'add_window', match: :first) do
        fill_in("Name", with: 'a_l_p')
        setup_enum_form("---")
        press('OK')
      end

      wait_for_ajax
      aggregate_failures do
        expect(lp_grid.row_count).to eq(2)
        expect(lp_grid.get_row_vals(1)).to netzke_include({enum_state: nil})
      end
    end

    and_by 'delete leftover rows' do
      lp_grid.select_row(1)
      press('Delete')
      press('Yes')
      wait_for_ajax
      lp_grid.select_row(1)
      press('Delete')
      press('Yes')
      wait_for_ajax
      expect(lp_grid.row_count).to eq(0)
    end

    and_by "bring up new window" do
      press("Add")
    end

    and_by "fill form with state_enum DC" do
      within(:gridpanel, "add_window", match: :first) do
        fill_in("Name", with: "DC Row")
        setup_enum_form("DC")
        press("OK")
      end
    end

    and_by "bring up new window" do
      press("Add")
    end

    and_by "fill form with state_enum AS" do
      within(:gridpanel, "add_window", match: :first) do
        fill_in("Name", with: "AS Row")
        setup_enum_form("AS")
        press("OK")
      end
    end

    and_by "bring up new window" do
      press("Add")
    end

    and_by "fill form with state_enum WA" do
      within(:gridpanel, "add_window", match: :first) do
        fill_in("Name", with: "WA Row")
        setup_enum_form("WA")
        press("OK")
      end
    end

    and_by "bring up new window" do
      press("Add")
    end

    and_by "fill form with state_enum AZ" do
      within(:gridpanel, "add_window", match: :first) do
        fill_in("Name", with: "AZ Row")
        setup_enum_form("AZ")
        press("OK")
      end
    end

    and_by "filter form by state_enum ASCENDING" do
      press("Enum state")
      expect(lp_grid.get_row_vals(1)).to netzke_include({enum_state: "AS"})
      expect(lp_grid.get_row_vals(2)).to netzke_include({enum_state: "AZ"})
      expect(lp_grid.get_row_vals(3)).to netzke_include({enum_state: "DC"})
      expect(lp_grid.get_row_vals(4)).to netzke_include({enum_state: "WA"})
    end

    and_by "filter form by state_enum DESCENDING" do
      press("Enum state")
      expect(lp_grid.get_row_vals(1)).to netzke_include({enum_state: "WA"})
      expect(lp_grid.get_row_vals(2)).to netzke_include({enum_state: "DC"})
      expect(lp_grid.get_row_vals(3)).to netzke_include({enum_state: "AZ"})
      expect(lp_grid.get_row_vals(4)).to netzke_include({enum_state: "AS"})
    end

  end
end
