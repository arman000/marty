module DbSeedHelpers
  def self.create_now_posting
    unless Marty::Posting.find_by_name('NOW')
      sn                 = Marty::Posting.new
      sn.posting_type_id = Marty::PostingType["BASE"].id
      sn.comment         = '---'
      sn.created_dt      = 'infinity'
      sn.save!
    end
  end

  def create_dev_tag
    unless Marty::Tag.find_by_name('DEV')
      tag            = Marty::Tag.new
      tag.comment    = '---'
      tag.created_dt = 'infinity'
      tag.save!
    end
  end
end
