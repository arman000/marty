# Basic Marty single-page application with authentication.
#
# == Extending Marty::AuthApp
# DOCFIX
class Marty::AuthApp < Marty::SimpleApp
  client_class do |c|
    c.include :auth_app
  end

  # Set the Logout button if current_user is set
  def menu
    [].tap do |menu|
      user = Mcfly.whodunnit
      if !user.nil?
        menu << "->" << {
          text: user.name,
          tooltip: 'Current user',
          menu: user_menu,
          name: "sign_out",
        }
      else
        menu << "->" << :sign_in
      end
    end
  end

  def user_menu
    [:sign_out]
  end

  action :sign_in do |c|
    c.icon = :door_in
  end

  action :sign_out do |c|
    c.icon = :door_out
    c.text = "Sign out #{Mcfly.whodunnit.name}" if Mcfly.whodunnit
  end

  endpoint :sign_in do |params|
    user = Marty::User.try_to_login(params[:login], params[:password])
    if user
      Netzke::Base.controller.set_user(user)
      client.netzke_set_result(true)
      true
    else
      client.netzke_set_result(false)
      client.netzke_notify("Wrong credentials")
      false
    end
  end

  endpoint :sign_out do
    Netzke::Base.controller.logout_user
    client.netzke_set_result(true)
  end
end
