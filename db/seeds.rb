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

# FIXME: this is a hack.  It's needed due to the fact that 'NOW'
# posting requires a PostingType.
Marty::PostingType.create name: 'BASE'

# Create NOW posting
unless Marty::Posting.find_by_name('NOW')
  sn                 = Marty::Posting.new
  # FIXME: this is Gemini-specific
  sn.posting_type_id = Marty::PostingType['BASE'].id
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
