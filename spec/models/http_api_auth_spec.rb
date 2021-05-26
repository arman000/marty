module Marty
  describe HttpApiAuth do
    describe 'validations' do
      it 'requires app name, api key' do
        api = HttpApiAuth.new
        api.valid?
        expect(api).to_not be_valid
        expect(api.errors[:app_name]).to eq(["can't be blank"])
        expect(api.errors[:token]).to eq([]) # auto-set if nil
      end
    end

    describe 'authorizations' do
      it 'defaults to an empty array' do
        api = HttpApiAuth.new
        expect(api.authorizations).to eq([])
      end

      it 'accepts a list of hashes' do
        auth = Marty::HttpApiAuth.new(authorizations: [{ path: '/test/app', method: 'GET' }])
        auth.valid?

        expect(auth.errors[:authorizations]).to be_empty
      end

      it 'allows a wildcard character' do
        auth = Marty::HttpApiAuth.new(authorizations: '*')
        auth.valid?

        expect(auth.errors[:authorizations]).to be_empty
      end

      it 'allows an empty value' do
        auth = Marty::HttpApiAuth.new(authorizations: '')
        auth.valid?

        expect(auth.errors[:authorizations]).to be_empty
      end

      it 'allows a nil value' do
        auth = Marty::HttpApiAuth.new(authorizations: nil)
        auth.valid?

        expect(auth.errors[:authorizations]).to be_empty
      end

      it 'with bad schema' do
        auth = Marty::HttpApiAuth.new(authorizations: ['bad-schema'])
        auth.valid?

        expect(auth.errors[:base]).to eq(['invalid schema'])
      end

      it 'with bad schema 2' do
        auth = Marty::HttpApiAuth.new(authorizations: [{}])
        auth.valid?

        expect(auth.errors[:base]).to eq(['invalid schema'])
      end
    end

    describe 'key management' do
      it 'creates the api key if necessary when the record is created' do
        api = HttpApiAuth.new(app_name: 'test')
        expect(api.token).to be_nil
        api.save!
        expect(api.token).to be_present
      end

      it 'allows api key to be updated for an existing record' do
        api = HttpApiAuth.create!(app_name: 'test')
        old_key = api.token
        api.token = SecureRandom.hex(19)
        new_key = api.token
        expect(api.token).to_not eq(old_key)
        expect(api).to be_valid
        api.save!
        # Verifies that validation and saving does not create new key
        expect(api.token).to eq(new_key)
      end

      it 'generates new api key if old one is cleared' do
        api = HttpApiAuth.create!(app_name: 'test')
        old_key = api.token
        api.token = ''
        api.app_name = 'new name'
        api.save!
        expect(api.token).to_not eq(old_key)
      end

      it 'generates new api key if old one is cleared (2)' do
        api = HttpApiAuth.create!(app_name: 'test')
        old_key = api.token
        api.token = nil
        api.app_name = 'new name'
        api.save!
        expect(api.token).to_not eq(old_key)
      end
    end
  end
end
