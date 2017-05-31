require 'spec_helper'

module Marty
  describe ApiAuth do
    before(:each) do
      Marty::Script.load_script_bodies({
                           "Script1" => "A:\n    a = 1\n",
                           "NewScript1" => "B:\n    b = 0\n",
                         }, Date.today)

      @api = ApiAuth.new
      @api.app_name = 'TestApp'
      @api.script_name = 'Script1'
      @api.save!
      @api.reload
    end

    describe "validations" do
      it "should require app name, api key and script name" do
        api = ApiAuth.new
        expect(api).to_not be_valid
        expect(api.errors[:app_name].any?).to be_truthy
        expect(api.errors[:api_key].any?).to be false # auto-set if nil
        expect(api.errors[:script_name].any?).to be_truthy
      end

      it "should require unique app name/script name" do
        api = @api.dup
        expect(api).to_not be_valid
        expect(api.errors[:app_name].to_s).to include('already been taken')
        api.script_name = 'NewScript1'
        expect(api).to be_valid
      end

      it "should require unique api key/script name" do
        api = @api.dup
        expect(api).to_not be_valid
        expect(api.errors[:api_key].to_s).to include('must be unique')
        api.script_name = 'NewScript1'
        expect(api).to be_valid
      end

      it "should require a valid associated script name" do
        api = ApiAuth.new
        api.app_name = 'NewApp'
        api.script_name = @api.script_name + 'Bad'
        expect(api).to_not be_valid
        expect(api.errors[:base].to_s).to include('reference a valid script')
      end

      it "should allow a tagged script version to be associated when a DEV " +
        "version of that script also exists" do
        s = Marty::Script.lookup('infinity', 'Script1')
        s.body = "A:\n    a = 3\n"
        s.save!

        api = ApiAuth.new
        api.app_name = 'NewApp'
        api.script_name = s.name
        expect(api).to be_valid
      end

      it "should not allow a DEV script to be associated if there is no " +
        "tagged version of that script" do
        s = Marty::Script.new
        s.name = 'TestScript'
        s.body = '-- Test3'
        # Creates a script in the future - no tag exists
        s.created_dt = Time.now + 1.minute
        s.save!

        api = ApiAuth.new
        api.app_name = 'NewApp'
        api.script_name = s.name
        expect(api).to_not be_valid
        expect(api.errors[:base].to_s).to include('reference a valid script')
      end
    end

    describe "key management" do
      it "should require a 38 character key" do
        expect(@api.api_key.length).to eq(38)

        @api.api_key = "123456789"
        expect(@api).to_not be_valid
        expect(@api.errors[:base].to_s).to include('length must be 38')
      end

      it "should create the api key if necessary when the record is created" do
        a = ApiAuth.new
        a.app_name = 'MyApp'
        a.script_name = 'NewScript1'
        expect(a.api_key).to be_nil
        a.save!
        expect(a.api_key).to_not be_nil
      end

      it "should allow api key to be updated for an existing record" do
        old = @api.api_key
        @api.api_key = ApiAuth.generate_key
        new = @api.api_key
        expect(@api.api_key).to_not eq(old)
        expect(@api).to be_valid
        @api.save!
        # Verifies that validation and saving does not create new key
        expect(@api.api_key).to eq(new)
      end

      it "should generate new api key if old one is cleared" do
        old = @api.api_key
        @api.api_key = ''
        @api.app_name += 'x'
        @api.save!
        expect(@api.api_key).to_not eq(old)
      end

      it "should generate new api key if old one is cleared (2)" do
        old = @api.api_key
        @api.api_key = nil
        @api.app_name += 'x'
        @api.save!
        expect(@api.api_key).to_not eq(old)
      end
    end

    describe "authorization" do
      it "should pass when script is not secured" do
        # Script is not secured by any entries
        expect(ApiAuth.authorized?('SomeScript','SomeKey')).to be_truthy
      end

      it "should pass when script is secured and key is valid" do
        expect(@api.script_name).to include('Script1')
        expect(ApiAuth.authorized?(@api.script_name,@api.api_key)).to be_truthy
      end

      it "should pass when script is secured and key is valid 2" do
        a = ApiAuth.new
        a.app_name = @api.app_name + 'x'
        a.script_name = 'NewScript1'
        a.save!
        expect(ApiAuth.authorized?('NewScript1',a.api_key)).to be_truthy
      end

      it "should match on exact script name" do
        a = ApiAuth.new
        a.app_name = @api.app_name + 'x'
        a.script_name = 'NewScript1'
        a.save!
        expect(ApiAuth.authorized?('Script1',a.api_key)).to be_falsey
      end

      it "should fail when script is secured and key is invalid" do
        expect(ApiAuth.authorized?('Script1','SomeKey')).to be_falsey
      end

      it "should fail when script is secured and key is invalid (2)" do
        a = ApiAuth.new
        a.app_name = @api.app_name + 'x'
        a.script_name = 'NewScript1'
        a.save!
        expect(ApiAuth.authorized?('NewScript1',@api.api_key)).to be_falsey
      end

      it "should fail when script is secured and key is not specified" do
        expect(ApiAuth.authorized?('Script1',nil)).to be_falsey
        expect(ApiAuth.authorized?('Script1','')).to be_falsey
      end

      it "should pass when api_auth is deleted and no other auths exist" do
        expect(ApiAuth.authorized?(@api.script_name,@api.api_key)).to be_truthy
        @api.delete
        expect(ApiAuth.authorized?(@api.script_name,@api.api_key)).to be_truthy
      end

      it "should fail when api_auth is deleted and another auth exists" do
        api = @api.dup
        api.app_name += 'x'
        api.api_key = nil
        api.save!
        expect(ApiAuth.authorized?(@api.script_name,@api.api_key)).to be_truthy
        @api.delete
        expect(ApiAuth.authorized?(@api.script_name,@api.api_key)).to be_falsey
      end
    end
  end
end
