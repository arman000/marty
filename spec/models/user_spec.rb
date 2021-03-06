module Marty
  describe User do
    before(:each) do
      Rails.configuration.marty.system_account =
        system_user.login
    end

    let (:tuser) do
      create_user('other_user')
    end

    describe 'validations' do
      it 'should require login, firstname and lastname' do
        user = User.new
        expect(user).to_not be_valid
        expect(user.errors[:login].any?).to be true
        expect(user.errors[:firstname].any?).to be true
        expect(user.errors[:lastname].any?).to be true
      end

      it 'should require unique login' do
        expect(Mcfly.whodunnit).to_not be_nil
        user = system_user.dup
        expect(user).to_not be_valid
        expect(user.errors[:login].to_s).to include('already been taken')
        user.login = 'marty2'
        expect(user).to be_valid
      end

      it 'should not allow Gemini account to be de-activated' do
        user = system_user
        user.active = false
        expect(user).to_not be_valid
        expect(user.errors[:base].to_s).
          to include('application system account cannot be deactivated')
      end

      it 'should not allow accounts to be deleted' do
        user = system_user
        user.destroy
        expect(user.destroyed?).to be false
      end

      it 'should not allow user managers to edit the Gemini account' do
        Mcfly.whodunnit = tuser
        user = system_user
        allow_any_instance_of(Marty::User).to receive(:user_manager_only).
          and_return(true)
        user.firstname = 'Testing'
        expect(user).to_not be_valid
        expect(user.errors[:base].to_s).
          to include('cannot edit the application system account')
      end

      it 'should not allow user managers to edit their own account' do
        Mcfly.whodunnit = tuser
        allow_any_instance_of(Marty::User).to receive(:user_manager_only).
          and_return(true)
        tuser.firstname = 'Testing'
        expect(tuser).to_not be_valid
        expect(tuser.errors[:base].to_s).
          to include('cannot edit or add additional roles')
      end
    end
  end
end
