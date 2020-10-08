feature 'Notifications spec', js: true do
  before do
    populate_test_users

    ::Marty::Notifications::Config.create!(
      event_type: event_type,
      recipient: user1,
      delivery_type: :web,
      state: :on,
      text: 'Please contact the customer'
    )

    Marty::Notifications::Create.call(
      event_type: event_type,
      text: 'Test limit is 1000'
    )
  end

  let(:user1) do
    Marty::User.find_by(login: :marty)
  end

  let(:user2) do
    Marty::User.find_by(login: :viewer1)
  end

  let(:event_type) do
    'API reached the limit'
  end

  let(:notification_grid) do
    netzke_find 'grid_view'
  end

  context 'as admin' do
    before do
      log_in_as('marty')
    end

    describe 'Notifications pop-up' do
      it 'shows notifications' do
        notification_link = find 'a[data-qtip="Show notifications"]'
        expect(notification_link.text).to eq '1'

        notification_link.click

        wait_for_ajax

        expect(notification_grid.row_count).to eq 1
        values = notification_grid.get_row_vals 1

        expect(values['notification__event_type']).to eq 'API reached the limit'

        expect(values['text']).to eq(
          'Test limit is 1000, Please contact the customer'
        )

        expect(values['error_text']).to eq ''

        close_btn = find 'div[data-qtip="Close dialog"]'
        close_btn.click

        # Check that no unread notifications left
        notification_link = find 'a[data-qtip="Show notifications"]'
        expect(notification_link.text).to eq ''
      end
    end

    describe 'Configuration grid' do
      before do
        press('System')
        press('Notifications')
        press('User Notification Rules')

        wait_for_ajax
      end

      let(:grid) do
        netzke_find 'notifications_config_view'
      end

      let(:state_select) do
        netzke_find('state', 'combobox')
      end

      let(:event_type_select) do
        netzke_find('event_type', 'combobox')
      end

      let(:recipient_select) do
        netzke_find('recipient__name', 'combobox')
      end

      let(:delivery_type_select) do
        netzke_find('delivery_type', 'combobox')
      end

      it 'allows to view and edit configuration' do
        expect(grid.row_count).to eq 1

        by 'turns the rule off' do
          values = grid.get_row_vals 1
          expect(values['state']).to eq 'on'

          grid.select_row 1
          press 'Edit'

          state_select.select_values 'off'

          press 'OK'

          wait_for_ajax

          values = grid.get_row_vals 1
          expect(values['state']).to eq 'off'
        end

        and_by 'adds new rule' do
          press 'Add'

          event_type_select.select_values 'API reached the limit'

          recipient_select.click
          recipient_select.select_values 'admin1 admin1'

          delivery_type_select.select_values 'web'

          fill_in :text, with: 'example text'

          press 'OK'

          wait_for_ajax

          expect(grid.row_count).to eq 2

          values = grid.get_row_vals 1
          expect(values['state']).to eq 'on'
          expect(values['text']).to eq 'example text'
          expect(values['recipient__name']).to eq 'admin1 admin1'
        end

        and_by "doesn't allow to duplicate the rule with the same delivery_type" do
          press 'Add'

          event_type_select.select_values 'API reached the limit'

          recipient_select.click
          recipient_select.select_values 'admin1 admin1'

          delivery_type_select.select_values 'web'

          fill_in :text, with: 'example text'

          press 'OK'

          expect(page).to have_content 'Delivery type has already been taken'

          press 'Cancel'
        end

        and_by 'deletes rule' do
          row_count = grid.row_count

          grid.select_row 1
          press 'Delete'
          press 'Yes'

          wait_for_ajax

          expect(grid.row_count).to eq(row_count - 1)
        end
      end
    end
  end

  context 'as viewer' do
    before do
      ::Marty::Notifications::Config.create!(
        event_type: event_type,
        recipient: user2,
        delivery_type: :web,
        state: :on,
        text: 'Please notify your manager'
      )

      Marty::Notifications::Create.call(
        event_type: event_type,
        text: 'Test limit is 1000'
      )

      log_in_as('viewer1')
    end

    it 'shows notifications' do
      notification_link = find 'a[data-qtip="Show notifications"]'
      expect(notification_link.text).to eq '1'

      notification_link.click

      wait_for_ajax

      expect(notification_grid.row_count).to eq 1
      values = notification_grid.get_row_vals 1

      expect(values['notification__event_type']).to eq 'API reached the limit'

      expect(values['text']).to eq(
        'Test limit is 1000, Please notify your manager'
      )
    end

    it "doesn't have access to notifications config" do
      visit '#notifications_config_view'
      expect(page).to have_content "You don't have permissions to read data"
    end

    it "doesn't have access to all notification messages" do
      visit '#notifications_deliveries_view'
      expect(page).to have_content "You don't have permissions to read data"
    end
  end
end
