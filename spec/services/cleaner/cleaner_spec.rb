module Marty::Cleaner
  describe CleanAll do
    let(:config_key) { described_class::CONFIG_KEY }

    before(:each) do
      Marty::Config[config_key] = {
        'day' => 'saturday',
        'range' => ['11:00', '13:00']
      }
    end

    after(:each) do
      Timecop.return
    end
  end

  describe CleanAll do
    it 'takes parameters from the config key' do
      allow(Marty::MaintenanceWindow).to receive(:call).and_return(
        {
          'day' => 'saturday',
        'range' => ['11:00', '13:00'],
        'log_days' => 123,
        'mcfly_days' => 231,
        'timestamp_days' => 321
        })
      expect(Logs).to receive(:call).with(123)
      described_class.call
    end

    it 'takes parameters from the config key' do
      allow(Marty::MaintenanceWindow).to receive(:call).and_return(
        {
          'day' => 'saturday',
        'range' => ['11:00', '13:00'],
        'log_days' => 'Doc',
        'mcfly_days' => 'Im from the future'
        })
      expect { described_class.call }.to raise_error(/must be an integer/)
    end
  end

  describe Logs do
    before(:all) do
      Timecop.travel(Time.zone.now + 11.days)
    end

    after(:all) do
      Timecop.return
    end

    it 'removes logs before but not after' do
      Marty::Logger.info('Please keep me')
      Timecop.travel(Time.zone.now - 3.days)
      Marty::Logger.info('Please delete me')
      Timecop.travel(Time.zone.now + 3.days)
      expect { described_class.call(2) }.to change { Marty::Log.count }.by(-1)
    end
  end

  describe McflyModels do
    def create_api_auth
      api_auth = Marty::ApiAuth.new
      api_auth.app_name = Time.zone.today.to_s
      api_auth.api_key = Time.zone.today.to_s
      api_auth.script_name = Time.zone.today.to_s
      api_auth.user_id = Mcfly.whodunnit.id
      api_auth.o_user_id = Mcfly.whodunnit.id
      api_auth.created_dt = Time.zone.now
      api_auth.obsoleted_dt = Time.zone.now
      api_auth.group_id = 999
      api_auth.save(validate: false)
    end

    it 'removes models of various kinds based on obsoleted date' do
      described_class::CLASSES_TO_CLEAN = [
        ::Marty::ApiAuth
      ]
      Mcfly.whodunnit = Marty::User.find_by(login: 'marty')

      Timecop.travel(Time.zone.now - 5.days)
      create_api_auth

      Timecop.return
      create_api_auth

      expect { described_class.call(2) }.
      to change { Marty::ApiAuth.count }.by(-1)
    end
  end

  describe TimestampModels do
    def create_user
      Marty::User.create!(
        created_at: Time.zone.now,
        updated_at: Time.zone.now,
        login: Time.zone.today.to_s,
        firstname: Time.zone.today.to_s,
        lastname: Time.zone.today.to_s,
        active: false
      )
    end
    it 'removes models based on their last updated_dt' do
      described_class::CLASSES_TO_CLEAN = [
        ::Marty::User
      ]

      Timecop.travel(Time.zone.now - 10.days)
      create_user

      Timecop.return
      create_user

      expect { described_class.call(2) }.
      to change { Marty::User.count }.by(-1)
    end
  end
end
