module Marty
  describe ApiAuth do
    before(:each) do
      Marty::Script.load_script_bodies({
                                         'Script1' => "A:\n    a = 1\n",
                           'NewScript1' => "B:\n    b = 0\n",
                                       }, Time.zone.today)
    end

    def create_params(script, key)
      { script: script, api_key: key }
    end

    describe 'validations' do
      it 'requires app name, api key and script name' do
        api = ApiAuth.new
        expect(api).to_not be_valid
        expect(api.errors[:app_name].any?).to be_truthy
        expect(api.errors[:api_key].any?).to be false # auto-set if nil
        expect(api.errors[:script_name].any?).to be_truthy
      end

      it 'requires unique app name/script name' do
        ApiAuth.create!(app_name: 'TestApp', script_name: 'Script1')
        new_api = ApiAuth.new(app_name: 'TestApp', script_name: 'Script1')

        expect(new_api).to_not be_valid
        expect(new_api.errors[:app_name].to_s).to include('already been taken')
        new_api.script_name = 'NewScript1'
        expect(new_api).to be_valid
      end

      it 'requires unique api key/script name' do
        api = ApiAuth.create!(app_name: 'TestApp', script_name: 'Script1')
        new_api = api.dup
        expect(new_api).to_not be_valid
        expect(new_api.errors[:api_key].to_s).to include('must be unique')
        new_api.script_name = 'NewScript1'
        expect(new_api).to be_valid
      end

      it 'requires a valid associated script name' do
        api = ApiAuth.new(app_name: 'TestApp', script_name: 'Script zero')
        expect(api).to_not be_valid
        expect(api.errors[:base].to_s).to include('reference a valid script')
      end

      it 'allows a tagged script version to be associated when a DEV ' \
         'version of that script also exists' do
        script = Marty::Script.find_by(obsoleted_dt: 'infinity', name: 'Script1')
        script.update(body: "A:\n    a = 3\n")

        api = ApiAuth.new(app_name: 'NewApp', script_name: script.name)
        expect(api).to be_valid
      end

      it 'does not allow a DEV script to be associated if there is no ' \
         'tagged version of that script' do
          # Creates a script in the future - no tag exists
          script = Marty::Script.create!({
                                           name: 'TestScript',
            body: '-- Test3',
            created_dt: Time.zone.now + 1.hour
                                         })

          api = ApiAuth.new(app_name: 'NewApp', script_name: script.name)

          expect(api).to_not be_valid
          expect(api.errors[:base].to_s).to include('reference a valid script')
      end
    end

    describe 'key management' do
      let(:api) { ApiAuth.new(app_name: 'TestApp', script_name: 'Script1') }

      it 'requires a 38 character key' do
        api.api_key = '123456789'
        expect(api).to_not be_valid
        expect(api.errors[:base].to_s).to include('length must be 38')
      end

      it 'creates the api key if necessary when the record is created' do
        expect(api.api_key).to be_nil
        api.save!
        expect(api.api_key).to_not be_nil
      end

      it 'allows api key to be updated for an existing record' do
        api.save!
        old_key = api.api_key
        new_key = ApiAuth.generate_key
        api.api_key = new_key
        expect(api.api_key).to_not eq(old_key)
        expect(api).to be_valid
        api.save!
        # Verifies that validation and saving does not create new key
        expect(api.api_key).to eq(new_key)
      end

      it 'generates new api key if old one is cleared' do
        api.save!
        old_key = api.api_key
        api.api_key = ''
        api.app_name += 'x'
        api.save!
        expect(api.api_key).to_not eq(old_key)
      end

      it 'generates new api key if old one is cleared (2)' do
        old_key = api.api_key
        api.api_key = nil
        api.app_name += 'x'
        api.save!
        expect(api.api_key).to_not eq(old_key)
      end
    end

    describe 'authorization' do
      it 'should pass when script is not secured' do
        # Script is not secured by any entries
        params = create_params('SomeScript', 'SomeKey')
        expect(Marty::Api::Base.is_authorized?(params)).to be_truthy
      end

      it 'should pass when script is secured and key is valid' do
        api = ApiAuth.new(app_name: 'NewApp', script_name: 'Script1')
        params = create_params(api.script_name, api.api_key)

        expect(Marty::Api::Base.is_authorized?(params)).to be_truthy
      end

      it 'should pass when script is secured and key is valid 2' do
        api = ApiAuth.create!(app_name: 'NewApp', script_name: 'NewScript1')
        params = create_params(api.script_name, api.api_key)

        expect(Marty::Api::Base.is_authorized?(params)).to be_truthy
      end

      context "when there's an existing app" do
        before { ApiAuth.create!(app_name: 'NewApp', script_name: 'Script1') }

        it 'should match on exact script name' do
          api = ApiAuth.create!(app_name: 'NewApp', script_name: 'NewScript1')
          params = create_params('Script1', api.api_key)

          expect(Marty::Api::Base.is_authorized?(params)).to be_falsey
        end

        it 'fails when script is secured and key is invalid' do
          params = create_params('Script1', 'SomeKey')

          expect(Marty::Api::Base.is_authorized?(params)).to be_falsey
        end

        it 'fails when script is secured and key is invalid (2)' do
          api = ApiAuth.create!(app_name: 'my app', script_name: 'NewScript1')

          params = create_params('NewScript1', 'Somekey')
          expect(Marty::Api::Base.is_authorized?(params)).to be_falsey
        end

        it 'fails when script is secured and key is not specified' do
          params = create_params('Script1', nil)

          expect(Marty::Api::Base.is_authorized?(params)).to be_falsey

          params = create_params('Script1', '')

          expect(Marty::Api::Base.is_authorized?(params)).to be_falsey
        end
      end
    end
  end

  describe 'without auth' do
    skip 'must return false with nil values' do
      expect(Marty::ApiAuth.count).to eq(0)
      expect(Marty::Api::Base.is_authorized?({ script: nil, api_key: nil })).to eq(false)
    end

    skip 'must return false if empty string values' do
      expect(Marty::Api::Base.is_authorized?({ script: '', api_key: '' })).to eq(false)
    end
  end
end
