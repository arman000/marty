module Marty
  describe ApplicationController do
    before(:each) do
      subject.logout_user
      expect(Marty::User.current).to be_nil
    end

    describe 'authentication' do
      it 'should allow a registered user to log in' do
        allow(Rails.configuration.marty).to receive(:auth_source).
          and_return('local')

        user = Marty::User.try_to_login('marty', 'marty')
        subject.set_user(user)
        expect(Marty::User.current).to_not be_nil

        subject.logout_user
        expect(Marty::User.current).to be_nil
      end

      it 'should allow a registered user to log in when the database ' +
        'is in recovery mode' do
        allow(Marty::Util).to receive(:db_in_recovery?).and_return(true)
        allow(Rails.configuration.marty).to receive(:auth_source).
          and_return('local')

        user = Marty::User.try_to_login('marty', 'marty')
        subject.set_user(user)
        expect(Marty::User.current).to_not be_nil

        subject.logout_user
        expect(Marty::User.current).to be_nil
      end

      it 'should prevent a non-registered user from logging in' do
        user = Marty::User.try_to_login('unknown_marty', 'invalid_password')
        expect(user).to be_nil
        expect(Marty::User.current).to be_nil
      end

      it 'should prevent a non-registered user from logging in when the ' +
        'database is in recovery mode' do
        allow(Marty::Util).to receive(:db_in_recovery?).and_return(true)
        user = Marty::User.try_to_login('unknown_marty', 'invalid_password')
        expect(user).to be_nil
        expect(Marty::User.current).to be_nil
      end
    end
  end
end
