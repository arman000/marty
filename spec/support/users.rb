module Marty; module RSpec; module Users
  def populate_test_users
    (1..2).each do |i|
      Rails.configuration.marty.roles.each do |role_name|
        username = "#{role_name}#{i}"
        next if Marty::User.find_by_login(username)

        user = Marty::User.new
        user.firstname = user.login = username
        user.lastname = username
        user.active = true
        user.save

        role = Marty::Role.find_by_name(role_name.to_s)

        rails "Oops unknown role: #{role_name}. Was db seeded?" unless role

        user_role = Marty::UserRole.new
        user_role.user = user
        user_role.role = role
        user_role.save!
      end
    end

    # also create an anon user
    user = Marty::User.new
    user.login = user.firstname = user.lastname = 'anon'
    user.active = true
    user.save
  end

  def system_user
    Marty::User.find_by_login('marty') # (system_login)
  end

  def create_user(name)
    Marty::User.find_or_create_by!(login: name,
                                   firstname: name,
                                   lastname: 'test',
                                   active: true)
  end
end end end
