class Marty::Script < Marty::Base
  has_mcfly

  validates_presence_of :name, :body
  mcfly_validates_uniqueness_of :name
  validates_format_of :name, {
    with: /\A[A-Z][a-zA-Z0-9]*\z/,
    message: I18n.t('script.save_error'),
  }

  belongs_to :user, class_name: "Marty::User"

  gen_mcfly_lookup :lookup, [:name], cache: true

  # find script by name/tag
  def self.find_script(sname, tag=nil)
    tag = Marty::Tag.map_to_tag(tag)
    Marty::Script.lookup(tag.created_dt, sname, {"no_convert"=>true})
  end

  def find_tag
    # find the first tag created after this script.
    Marty::Tag.where("created_dt >= ?", created_dt).order(:created_dt).first
  end

  def self.create_script(name, body)
    script      = new
    script.name = name
    script.body = body
    script.save
    script
  end

  def self.load_a_script(sname, body, dt=nil)
    s = Marty::Script.lookup('infinity', sname, {"no_convert"=>true})

    if !s
      s = Marty::Script.new
      s.body = body
      s.name = sname
      s.created_dt = dt if dt
      s.save!
    elsif s.body != body
      s.body = body
      s.created_dt = dt if dt
      s.save!
    end
  end

  def self.load_script_bodies(bodies, dt=nil)
    bodies.each {
      |sname, body|
      load_a_script(sname, body, dt)
    }

    # Create a new tag if scripts were modified after the last tag
    tag = Marty::Tag.get_latest1
    latest = Marty::Script.order("created_dt DESC").first

    tag_time = (dt || [latest.try(:created_dt), Time.now].compact.max) +
      1.second

    # If no tag_time is provided, the tag created_dt will be the same
    # as the scripts.
    tag = Marty::Tag.do_create(tag_time, "tagged from load scripts") if
      !(tag && latest) || tag.created_dt <= latest.created_dt

    tag
  end

  def self.load_scripts(path=nil, dt=nil)
    files = get_script_filenames(path)

    bodies = read_script_files(files)

    load_script_bodies(bodies, dt)
  end

  def self.read_script_files(files)
    files.collect { |fpath|
      fname = File.basename(fpath)[0..-4].camelize
      [fname, File.read(fpath)]
    }
  end

  def self.get_script_filenames(paths = nil)
    paths = get_script_paths(paths)

    filenames = {}
    paths.each do |path|
      Dir.glob("#{path}/*.dl").each do |filename|
        basename = File.basename(filename)
        filenames[basename] = filename unless filenames.has_key?(basename)
      end
    end

    filenames.values
  end

  def self.get_script_paths(paths)
    if paths
      paths = Array(paths)
    elsif Rails.configuration.marty.delorean_scripts_path
      paths = Rails.configuration.marty.delorean_scripts_path
    else
      paths = [
        "#{Rails.root}/delorean",
        # FIXME: HACKY, wouldn't it be better to use
        # Gem::Specification.find_by_name("marty").gem_dir??
        File.expand_path('../../../../delorean', __FILE__),
      ]
    end
  end

  def self.delete_scripts
    ActiveRecord::Base.connection.
      execute("ALTER TABLE marty_scripts DISABLE TRIGGER USER;")
    Marty::Script.delete_all
    ActiveRecord::Base.connection.
      execute("ALTER TABLE marty_scripts ENABLE TRIGGER USER;")
  end

  delorean_fn :eval_to_hash, sig: 5 do
    |dt, script, node, attrs, params|
    tag = Marty::Tag.find_match(dt) || raise("no tag found for #{dt}")

    engine = Marty::ScriptSet.new(tag).get_engine(script)
    # IMPORTANT: engine evals (e.g. eval_to_hash) modify the
    # params. So, need to clone it.
    engine.eval_to_hash(node, attrs, params.clone)

    # FIXME: should sanitize res to make sure that no nodes are being
    # passed back.  It's likely that nodes which are not from the
    # current tag can caused problems.
  end

  delorean_fn :evaluate, sig: 5 do
    |dt, script, node, attr, params|
    tag = Marty::Tag.find_match(dt) || raise("no tag found for #{dt}")

    engine = Marty::ScriptSet.new(tag).get_engine(script)
    # IMPORTANT: engine evals (e.g. eval_to_hash) modify the
    # params, but it is possible that we may be passing in
    # a frozen hash. To avoid performance impacts, we should first check if
    # params is frozen to decide whether to dup (frozen) or clone (not frozen).
    engine.evaluate(node, attr, params.frozen? ? params.dup : params.clone)
  end

  delorean_fn :pretty_print, sig: 1 do
    |id|
    script = find_by_id id

    next "unknown script #{id}" unless script

    CodeRay.scan(script.body, :ruby).div(line_numbers: :table)
  end
end
