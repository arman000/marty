module DbSeedHelpers
  def create_now_posting
    unless Marty::Posting.find_by_name('NOW')
      sn                 = Marty::Posting.new
      sn.posting_type_id = Marty::PostingType["BASE"].id
      sn.comment         = '---'
      sn.created_dt      = 'infinity'
      sn.save!
    end
  end
end
