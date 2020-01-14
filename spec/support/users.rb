module Marty; module RSpec; module Users
  def populate_test_users
    (1..2).each do |i|
      Rails.configuration.marty.roles.each do |role_name|
        username = "#{role_name}#{i}"
        next if Marty::User.find_by(login: username)

        user = Marty::User.new
        user.firstname = user.login = username
        user.lastname = username
        user.active = true
        user.save

        Marty::UserRole.create(user_id: user.id, role: role_name)
      end
    end

    # also create an anon user
    user = Marty::User.new
    user.login = user.firstname = user.lastname = 'anon'
    user.active = true
    user.save
  end

  def system_user
    Marty::User.find_by(login: 'marty') # (system_login)
  end

  def create_user(name)
    Marty::User.find_or_create_by!(login: name,
                                   firstname: name,
                                   lastname: 'test',
                                   active: true)
  end
end end end
