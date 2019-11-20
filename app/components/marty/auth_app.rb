# Basic Marty single-page application with authentication.
#
# == Extending Marty::AuthApp
# DOCFIX
require 'marty/notifications/window'

class Marty::AuthApp < Marty::SimpleApp
  client_class do |c|
    c.include :auth_app
  end

  # Set the Logout button if current_user is set
  def menu
    [].tap do |menu|
      user = Mcfly.whodunnit
      if !user.nil?
        menu <<
          '->' <<
          notification_menu_item <<
          current_user_menu_item(user)
      else
        menu << '->' << :sign_in
      end
    end
  end

  def notification_menu_item
    :notifications_window
  end

  def current_user_menu_item(user)
    {
      text: user.name,
      tooltip: 'Current user',
      menu: user_menu,
      name: 'sign_out',
    }
  end

  def user_menu
    [:sign_out, :toggle_dark_mode]
  end

  def unread_notifications_count
    user = Mcfly.whodunnit

    return 0 unless user.present?

    user.unread_web_notifications_count
  end

  action :notifications_window do |c|
    c.icon_cls = 'fa fa-bell gylph '
    c.tooltip = 'Show notifications'

    c.text = nil

    notifications_count = unread_notifications_count

    next if notifications_count.zero?

    c.text = "<span class='notification-counter'>#{notifications_count}</span>"
  end

  action :sign_in do |c|
    c.icon_cls = 'fa fa-sign-in-alt gylph'
  end

  action :sign_out do |c|
    c.icon_cls = 'fa fa-sign-out-alt gylph'
    c.text     = "Sign out #{Mcfly.whodunnit.name}" if Mcfly.whodunnit
  end

  action :toggle_dark_mode do |a|
    a.text = 'Toggle Dark Mode'
    a.icon_cls = 'fa fa-adjust glyph'
  end

  endpoint :sign_in do |params|
    user = Marty::User.try_to_login(params[:login], params[:password])
    user ? Netzke::Base.controller.set_user(user) :
      client.netzke_notify('Wrong credentials')

    !!user
  end

  endpoint :sign_out do
    Netzke::Base.controller.logout_user
    true
  end

  endpoint :toggle_dark_mode do
    Netzke::Base.controller.toggle_dark_mode
  end

  endpoint :mark_web_notifications_delivered do
    user = Mcfly.whodunnit
    deliveries = user.notification_deliveries.where(
      delivery_type: :web,
      state: [:sent]
    )

    deliveries.each(&:set_delivered!)
  end

  component :notifications_window do |c|
    c.klass = ::Marty::Notifications::Window
  end
end
