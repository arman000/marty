class Marty::Tag < Marty::Base
  has_mcfly append_only: true

  attr_accessible :created_dt, :name, :comment
  mcfly_validates_uniqueness_of :name
  validates_presence_of :name, :comment

  belongs_to :user, class_name: "Marty::User"

  def self.make_name(dt)
    return 'DEV' if Mcfly.is_infinity(dt)

    # If no dt is provided (which is the usual non-testing case), we
    # use Time.now.strftime to name the posting.  This has the effect
    # of using the host's timezone. i.e. since we're in PST8PDT, names
    # will be based off of the Pacific TZ.
    dt ||= Time.now
    dt.strftime('%Y%m%d-%H%M')
  end

  before_validation :set_tag_name
  def set_tag_name
    self.name = self.class.make_name(self.created_dt)
    true
  end

  def self.do_create(dt, comment)
    o            = new
    o.comment    = comment
    o.created_dt = dt
    o.save!
    o
  end

  def isdev?
    Mcfly.is_infinity(created_dt)
  end

  def self.map_to_tag(tag_id)
    case tag_id
    when String
      tag = find_by_name(tag_id)
      # if tag name wasn't found, look for a matching
      # posting, then find the tag whose created_dt <= posting dt.
      if !tag
        posting = Marty::Posting.lookup(tag_id)
        tag = find_match(Mcfly.normalize_infinity(posting.created_dt)) if
          posting
      end
    when Fixnum
      tag = find_by_id(tag_id)
    when nil
      tag = get_latest1
    else
      tag = tag_id
    end

    raise "bad tag identifier #{tag_id}" unless tag.is_a? Marty::Tag
    tag
  end

  cached_delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end

  delorean_fn :lookup_dt, sig: 1 do
    |name|
    lookup(name).try(:created_dt)
  end

  delorean_fn :get_latest1, sig: 0 do
    where("created_dt <> 'infinity'").order("created_dt DESC").first
  end

  delorean_fn :find_match, sig: 1 do
    |dt|
    where("created_dt <= ?", dt).order("created_dt DESC").first
  end
end
