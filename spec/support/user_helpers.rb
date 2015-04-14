module UserHelpers
  def self.system_user
    Marty::User.find_by_login('marty') # (system_login)
  end

  def self.create_user(name)
    Marty::User.find_or_create_by!(login: name,
                                   firstname: name,
                                   lastname: 'test',
                                   active: true)
  end
end
