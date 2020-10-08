module Marty
  describe Notifications::Create do
    before do
      populate_test_users
    end

    let(:user1) do
      Marty::User.find_by(login: :admin1)
    end

    let(:user2) do
      Marty::User.find_by(login: :admin2)
    end

    let(:event_type) do
      'API reached the limit'
    end

    let!(:config) do
      ::Marty::Notifications::Config.create!(
        event_type: event_type,
        recipient: user1,
        delivery_type: :web,
        state: :on,
        text: 'Please contact the customer'
      )
    end

    let!(:config2) do
      ::Marty::Notifications::Config.create!(
        event_type: event_type,
        recipient: user2,
        delivery_type: :web,
        state: :on,
      )
    end

    def create_notification
      hash = described_class.call(
        event_type: event_type,
        text: 'Test limit is 1000'
      )

      Marty::Notifications::Notification.find(hash[:id])
    end

    it 'creates deliveries' do
      notification = create_notification

      expect(notification.deliveries.size).to eq 2

      delivery1 = user1.notification_deliveries.find_by(
        notification: notification
      )

      expect(delivery1.state).to eq 'sent'
      expect(delivery1.text).to eq 'Please contact the customer'

      delivery2 = user2.notification_deliveries.find_by(
        notification: notification
      )
      expect(delivery2.state).to eq 'sent'
      expect(delivery2.text).to eq ''
    end

    it "doesn't create delivery when config is off" do
      config2.update!(state: :off)

      notification = create_notification

      expect(notification.deliveries.size).to eq 1

      delivery2 = user2.notification_deliveries.find_by(
        notification: notification
      )

      expect(delivery2).to_not be_present
    end
  end
end
