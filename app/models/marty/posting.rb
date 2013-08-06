class Marty::Posting < Marty::Base
  has_mcfly append_only: true

  attr_accessible :created_dt, :name, :posting_type_id, :is_test, :comment
  mcfly_validates_uniqueness_of :name
  validates_presence_of :name, :posting_type_id, :comment

  belongs_to :user, class_name: "Marty::User"
  belongs_to :posting_type

  def self.make_name(posting_type, dt, is_test)
    return 'NOW' if dt == Float::INFINITY || dt == 'infinity'

    return unless posting_type

    # If no dt is provided (which is the usual non-testing case), we
    # use Time.now.strftime to name the posting.  This has the effect
    # of using the host's timezone. i.e. since we're in PST8PDT, names
    # will be based off of the Pacific TZ.
    dt ||= Time.now
    "#{'TEST-' if is_test}#{posting_type.name}-#{dt.strftime('%Y%m%d-%H%M')}"
  end

  before_validation :set_posting_name
  def set_posting_name
    posting_type = Marty::PostingType.find_by_id(self.posting_type_id)
    self.is_test ||= false

    self.name =
      self.class.make_name(posting_type, self.created_dt, self.is_test)
    true
  end

  def self.do_create(type_name, is_test, dt, comment)
    posting_type = Marty::PostingType.find_by_name(type_name)

    raise "unknown posting type #{name}" unless posting_type

    o 			= new
    o.posting_type 	= posting_type
    o.is_test 		= !!is_test
    o.comment		= comment
    o.created_dt 	= dt
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

  delorean_fn :get_latest, sig: [1, 2] do
    |limit, is_test=nil|
    q = is_test.nil? ? self : self.where("is_test = ?", !!is_test)
    q.where("created_dt <> 'infinity'").order("created_dt DESC").limit(limit)
  end

  delorean_fn :is_base, sig: 1 do
    |posting|
    posting.posting_type == Marty::PostingType.BASE
  end

  # Get the base for the posting argument.  If the posting has
  # posting_type base, then the argument itself is the result.
  # Otherwise, we search for the last non-TEST BASE posting which is
  # older.
  delorean_fn :get_base, sig: 1 do
    |posting|
    next posting if is_base(posting)

    t = posting.created_dt
    t = 'infinity' if t == Float::INFINITY

    where("created_dt <= ? AND posting_type_id = ? AND is_test = 'f'",
          t, Marty::PostingType.BASE.id).order("created_dt DESC").first
  end

  delorean_fn :is_today, sig: 1 do
    |posting|
    posting.created_dt.to_date == Date.today
  end
end
