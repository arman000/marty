module UserHelpers
  def self.create_gemini_user
    create_user('gemini')
  end

  def self.create_user name
    Marty::User.find_or_create_by!(login: name, firstname: name, lastname: 'test', active: true)
  end
end
