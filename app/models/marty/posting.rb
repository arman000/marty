class Marty::Posting < Marty::Base
  has_mcfly append_only: true

  mcfly_validates_uniqueness_of :name
  validates_presence_of :name, :posting_type_id, :comment

  belongs_to :user, class_name: "Marty::User"
  belongs_to :posting_type

  def self.make_name(posting_type, dt)
    return 'NOW' if Mcfly.is_infinity(dt)

    return unless posting_type

    # If no dt is provided (which is the usual non-testing case), we
    # use Time.now.strftime to name the posting.  This has the effect
    # of using the host's timezone. i.e. since we're in PST8PDT, names
    # will be based off of the Pacific TZ.
    dt ||= Time.now
    "#{posting_type.name}-#{dt.strftime('%Y%m%d-%H%M')}"
  end

  before_validation :set_posting_name
  def set_posting_name
    posting_type = Marty::PostingType.find_by_id(self.posting_type_id)
    self.name = self.class.make_name(posting_type, self.created_dt)
    true
  end

  def self.do_create(type_name, dt, comment)
    posting_type = Marty::PostingType.find_by_name(type_name)

    raise "unknown posting type #{name}" unless posting_type

    o              = new
    o.posting_type = posting_type
    o.comment      = comment
    o.created_dt   = dt
    o.save!
    o
  end

  # Not using mcfly_lookup since we don't want these time-warp markers
  # time-warped. FIXME: perhaps this should use mcfly_lookup since we
  # may allow deletion of postings.  i.e. a new one with same name
  # might be created.  Or, use regular validates_uniqueness_of instead
  # of mcfly_validates_uniqueness_of.
  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end

  delorean_fn :lookup_dt, sig: 1 do
    |name|
    lookup(name).try(:created_dt)
  end

  delorean_fn :first_match, sig: [1, 2] do
    |dt, posting_type=nil|
    raise "bad posting type" if
      posting_type && !posting_type.is_a?(Marty::PostingType)

    q = where("created_dt <= ?", dt)
    q = q.where(posting_type_id: posting_type.id) if posting_type
    q.order("created_dt DESC").first
  end

  delorean_fn :get_latest, sig: [1, 2] do
    |limit, is_test=nil|
    # IMPORTANT: is_test arg is ignored (KEEP for backward compat.)

    where("created_dt <> 'infinity'").
      order("created_dt DESC").limit(limit).to_a
  end

  delorean_fn :get_latest_by_type, sig: [2, 2] do
    |limit, posting_types=[]|
    raise "missing posting types list" unless posting_types
    raise "bad posting types list" unless posting_types.is_a?(Array)

    joins(:posting_type).where("created_dt <> 'infinity'").
      where(marty_posting_types: { name: posting_types } ).
      order("created_dt DESC").limit(limit || 1).to_a
  end

  delorean_fn :get_last, sig: [0, 1] do
    |posting_type=nil|

    raise "bad posting type" if
      posting_type && !posting_type.is_a?(Marty::PostingType)

    q = where("created_dt <> 'infinity'")
    q = q.where(posting_type_id: posting_type.id) if posting_type
    q.order("created_dt DESC").first
  end

  delorean_fn :is_today, sig: 1 do
    |posting|
    posting.created_dt.to_date == Date.today
  end
end
