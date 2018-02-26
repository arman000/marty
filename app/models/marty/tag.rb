class Marty::Tag < Marty::Base
  has_mcfly append_only: true

  mcfly_validates_uniqueness_of :name
  validates_presence_of :name, :comment

  belongs_to :user, class_name: "Marty::User"

  def self.get_struct_attrs
    super + ["created_dt"]
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
    nc = {"no_convert"=>true}
    case tag_id
    when Integer, /\A[0-9]+\z/
      tag = find_by_id(tag_id)
    when String
      tag = find_by_name(tag_id)
      # if tag name wasn't found, look for a matching
      # posting, then find the tag whose created_dt <= posting dt.
      if !tag
        posting = Marty::Posting.lookup(tag_id, nc)
        tag = find_match(Mcfly.normalize_infinity(posting.created_dt), nc) if
          posting
      end
    when nil
      tag = get_latest1(nc)
    else
      tag = tag_id
    end
    binding.pry unless tag.nil? || tag.is_a?(Marty::Tag)
    raise "bad tag identifier #{tag_id.inspect}" unless tag.is_a?(Marty::Tag)
    tag
  end

  cached_delorean_fn :lookup, sig: [1, 2] do
    |name, opts={}|
    make_openstruct(self.find_by_name(name), opts)
  end

  # Performance hack to cache AR object
  cached_delorean_fn :lookup_id, sig: [1, 2] do
    |id, opts={}|
    make_openstruct(find_by_id(id), opts)
  end

  delorean_fn :lookup_dt, sig: 1 do
    |name|
    lookup(name).try(:created_dt)
  end

  delorean_fn :get_latest1, sig: 1 do
    |opts={}|
    make_openstruct(where("created_dt <> 'infinity'").
                     order("created_dt DESC").first, opts)
  end

  delorean_fn :find_match, sig: [1, 2] do
    |dt, opts={}|
    id = select(:id).where("created_dt <= ?", dt).order("created_dt DESC").first.id

    # performance hack to use cached version
    id && lookup_id(id, opts)
  end

  # Performance hack for script sets -- FIXME: making find_mtach
  # cached breaks Gemini tests.  Need to look into it.
  cached_delorean_fn :cached_find_match, sig: [1, 2] do
    |dt, opts={}|

    find_match(dt, opts)
  end
end
