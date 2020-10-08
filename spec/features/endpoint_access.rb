feature 'Endpoint access', js: true do
  before do
    populate_test_users
  end

  context 'as admin' do
    before do
      log_in_as('admin1')
      wait_for_ajax
    end

    it 'can access test_access endpoint' do
      press('Pricing Config.')
      press('Loan Programs')
      press('Test Access')
      wait_for_ajax
      expect(page).to have_content 'You have admin access'
    end
  end

  context 'as dev' do
    before do
      log_in_as('dev1')
      wait_for_ajax
    end

    it 'can not access test_access endpoint' do
      press('Pricing Config.')
      press('Loan Programs')
      press('Test Access')
      wait_for_ajax
      expect(page).to have_content 'Permission Denied'
    end
  end
end
