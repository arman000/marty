module UserHelpers
  def create_gemini_user
    create_user('gemini')
  end

  def create_user name
    Marty::User.find_or_create_by!(login: name, firstname: name, lastname: 'test', active: true)
  end
end
