return unless Rails.env.development?

# Grant developers access to manage roles
devs = Marty::UserRole.where(role: 'dev').pluck(:user_id)
umgrs = Marty::UserRole.where(role: 'user_manager').pluck(:user_id)

(devs - umgrs).each do |user_id|
  # if we can't add the role, still want the app to start
  Marty::UserRole.create(user_id: user_id, role: 'user_manager')
end
