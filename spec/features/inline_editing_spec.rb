require 'spec_helper'

feature 'Inline editing', js: true do
  before do
    populate_test_users
  end

  it 'Adds a new record with default false value in checkbox' do
    log_in_as('marty')
    press('Pricing Config.')
    press('Gemini Simple')
    wait_for_ajax

    grid = netzke_find('simple_view')
    press 'Add'

    user_id = grid.all('.x-grid-cell')[0]
    name = grid.all('.x-grid-cell')[1]

    user_id.double_click
    user_id.fill_in 'user_id', with: 1

    name.double_click
    name.fill_in 'some_name', with: 'test name'

    press 'Apply'
    wait_for_ajax

    model = Gemini::Simple.find_by(some_name: 'test name')
    expect(model.active).to be false
    expect(model.default_true).to be true
  end
end
