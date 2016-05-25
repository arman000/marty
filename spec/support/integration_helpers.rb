module Marty::IntegrationHelpers
  # test setup helpers
  def populate_test_users
    (1..2).each { |i|
      Rails.configuration.marty.roles.each { |role_name|
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
      }
    }

    # also create an anon user
    user = Marty::User.new
    user.login = user.firstname = user.lastname = "anon"
    user.active = true
    user.save
  end

  def log_in_as(username)
    Rails.configuration.marty.auth_source = 'local'

    ensure_on("/")
    log_in(username, Rails.configuration.marty.local_password)
    ensure_on("/")
  end
end
