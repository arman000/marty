# Create all Marty roles from configuration
Rails.configuration.marty.roles.each do |role|
  Marty::Role.create(name: role.to_s)
end
