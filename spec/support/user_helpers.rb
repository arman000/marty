module UserHelpers
  def create_gemini_user
    create_user('gemini')
  end

  def create_user name
    Marty::User.create!(login: name, firstname: name, lastname: 'test', active: true)
  end
end
