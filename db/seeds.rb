# create system account if not there
system_login = Rails.configuration.marty.system_account || 'marty'

unless Marty::User.find_by_login(system_login)
  user           = Marty::User.new
  user.login     = system_login
  user.firstname = system_login
  user.lastname  = system_login
  user.active    = true
  user.save!
end

# FIXME: hacky -- globally changes whodunnit
Mcfly.whodunnit = Marty::User.find_by_login(system_login)

# Give system account all roles
Marty::RoleType.get_all.map do |role|
  ur = Marty::UserRole.new
  ur.user = Mcfly.whodunnit
  ur.role = role
  ur.save
end

# Create default PostingType from configuration
default_p_type =  Rails.configuration.marty.default_posting_type

# Create NOW posting
unless Marty::Posting.find_by_name('NOW')
  sn                 = Marty::Posting.new
  sn.posting_type    = Marty::PostingType[default_p_type]
  sn.comment         = '---'
  sn.created_dt      = 'infinity'
  sn.save!
end

# Create DEV tag
unless Marty::Tag.find_by_name('DEV')
  tag            = Marty::Tag.new
  tag.comment    = '---'
  tag.created_dt = 'infinity'
  tag.save!
end

# Expect the # of DJ workers to be equal to the number of processors on the server
# if you change this, you will have issues with monit
Marty::Config["DELAYED_JOB_WORKERS"] = "#{Etc.nprocessors}"

Marty::Config['DELAYED_JOBS_MAINTENANCE_WINDOW'] = {
  day: '*', range: ['01:00', '04:00']
}

Marty::Config['CLEANER_MAINTENANCE_WINDOW'] = {
  day: 'saturday', range: ['01:00', '02:00']
}

Marty::Configs::UpdateFromYml.call

Marty::Diagnostic.diagnostics.each do |name|
  Marty::Diagnostic::Configuration.find_or_create_by!(
    name: name
  )
end
