class Marty::Posting < Marty::Base
  mcfly append_only: true

  mcfly_validates_uniqueness_of :name
  validates :name, :posting_type, :comment, presence: true

  belongs_to :user, class_name: 'Marty::User'

  def self.make_name(posting_type, dt)
    return 'NOW' if Mcfly.is_infinity(dt)

    return unless posting_type

    # If no dt is provided (which is the usual non-testing case), we
    # use Time.now.strftime to name the posting.  This has the effect
    # of using the host's timezone. i.e. since we're in PST8PDT, names
    # will be based off of the Pacific TZ.
    dt ||= Time.zone.now
    "#{posting_type}-#{dt.strftime('%Y%m%d-%H%M')}"
  end

  before_validation :set_posting_name

  def set_posting_name
    self.name = self.class.make_name(posting_type, created_dt)
    true
  end

  def self.do_create(posting_type, dt, comment)
    raise "unknown posting type #{name}" unless posting_type

    o              = new
    o.posting_type = posting_type
    o.comment      = comment
    o.created_dt   = dt
    o.save!
    o
  end

  def self.get_struct_attrs
    self.struct_attrs ||= super + ['created_dt', 'name']
  end

  # Not using mcfly_lookup since we don't want these time-warp markers
  # time-warped. FIXME: perhaps this should use mcfly_lookup since we
  # may allow deletion of postings.  i.e. a new one with same name
  # might be created.  Or, use regular validates_uniqueness_of instead
  # of mcfly_validates_uniqueness_of.
  delorean_fn :lookup, cache: true do |name|
    p = select(get_struct_attrs).find_by(name: name)
    make_openstruct(p)
  end

  delorean_fn :lookup_dt, sig: 1 do |name|
    find_by(name: name).try(:created_dt)
  end

  delorean_fn :first_match, sig: [1, 2] do |dt, posting_type = nil|
    raise 'bad posting type' if
      posting_type && !posting_type[posting_type]

    q = where('created_dt <= ?', dt)
    q = q.where(posting_type: posting_type) if posting_type
    q.order('created_dt DESC').first&.attributes
  end

  delorean_fn :get_latest_by_type, sig: [1, 2] do |limit, posting_types = []|
    raise 'missing posting types list' unless posting_types
    raise 'bad posting types list' unless posting_types.is_a?(Array)

    q = where("created_dt <> 'infinity'").
       where(posting_type: posting_types).
       select(get_struct_attrs).
       order('created_dt DESC').limit(limit || 1)

    q.map(&:attributes)
  end
end
