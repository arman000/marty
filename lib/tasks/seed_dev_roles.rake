namespace :marty do
  desc 'Give dev users the user_manager role in dev'
  task seed_dev_roles: :environment do
    return unless Rails.env.development?

    # Grant developers access to manage roles
    devs = Marty::UserRole.where(role: 'dev').pluck(:user_id)
    umgrs = Marty::UserRole.where(role: 'user_manager').pluck(:user_id)

    (devs - umgrs).each do |user_id|
      Marty::UserRole.create!(user_id: user_id, role: 'user_manager')
    end
  end
end
