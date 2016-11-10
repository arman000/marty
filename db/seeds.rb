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

# Create all Marty roles from configuration
(Rails.configuration.marty.roles || []).each do |role|
  Marty::Role.create(name: role.to_s)
end

# Give system account all roles
Marty::Role.all.map { |role|
  ur = Marty::UserRole.new
  ur.user = Mcfly.whodunnit
  ur.role = role
  ur.save
}

# Create default PostingType from configuration
default_p_type =  Rails.configuration.marty.default_posting_type

Marty::PostingType.create(name: default_p_type)

# Create NOW posting
unless Marty::Posting.find_by_name('NOW')
  sn                 = Marty::Posting.new
  sn.posting_type_id = Marty::PostingType[default_p_type].id
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

# one time set up for delayed_job/promises, override only needed
# if DELAYED_JOB_PATH is not bin/delayed_job
Marty::Config["DELAYED_JOB_PARAMS"] = "-n 4"
# Marty::Config["DELAYED_JOB_PATH"]   = "script/delayed_job"
