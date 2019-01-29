class Marty::Tag < Marty::Base
  has_mcfly append_only: true

  mcfly_validates_uniqueness_of :name
  validates_presence_of :name, :comment

  belongs_to :user, class_name: "Marty::User"

  def self.get_struct_attrs
    self.struct_attrs ||= super + ["id", "created_dt"]
  end

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
    # FIXME: this is really hacky. This function should not take so
    # many different types of arguments.
    case tag_id
    when Integer, /\A[0-9]+\z/
      tag = find_by_id(tag_id)
    when String
      tag = find_by_name(tag_id)
      # if tag name wasn't found, look for a matching
      # posting, then find the tag whose created_dt <= posting dt.
      if !tag
        cdt = Marty::Posting.where(name: tag_id).pluck('created_dt').first

        tag = find_match(Mcfly.normalize_infinity(cdt)) if cdt
      end
    when nil
      tag = get_latest1
    else
      tag = tag_id
    end
    raise "bad tag identifier #{tag_id.inspect}" unless tag.is_a?(Marty::Tag)
    tag
  end

  cached_delorean_fn :lookup, sig: 1 do |name|
    t = self.find_by_name(name).select(get_struct_attrs)
    t && t.attributes
  end

  def self.get_latest1
    order("created_dt DESC").find_by("created_dt <> 'infinity'")
  end

  def self.find_match(dt)
    order("created_dt DESC").find_by("created_dt <= ?", dt)
  end

  # Performance hack for script sets -- FIXME: making find_mtach
  # cached breaks Gemini tests.  Need to look into it.
  def self.cached_find_match(dt)
    @@CACHE_FIND_BY_DT ||= {}
    @@CACHE_FIND_BY_DT[dt] ||= find_match(dt)
  end
end
