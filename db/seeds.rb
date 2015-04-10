# Create all Marty roles from configuration
(Rails.configuration.marty.roles || []).each do |role|
  Marty::Role.create(name: role.to_s)
end

# Create NOW posting
unless Marty::Posting.find_by_name('NOW')
  sn                 = Marty::Posting.new
  sn.posting_type_id = Marty::PostingType["BASE"].id
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
