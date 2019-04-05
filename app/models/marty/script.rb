require 'pathname'

class Marty::Script < Marty::Base
  has_mcfly

  validates_presence_of :name, :body
  mcfly_validates_uniqueness_of :name
  validates_format_of :name,
                      with: /\A[A-Z][a-zA-Z0-9]*(__[A-Z][a-zA-Z0-9]*)*\z/,
                      message: I18n.t('script.save_error')

  belongs_to :user, class_name: 'Marty::User'

  gen_mcfly_lookup :lookup, [:name], cache: true

  # find script by name/tag (not cached)

  def find_tag
    # find the first tag created after this script.
    Marty::Tag.where('created_dt >= ?', created_dt).order(:created_dt).first
  end

  delorean_fn :eval_to_hash, sig: 5 do |dt, script, node, attrs, params|
    tag = Marty::Tag.find_match(dt) if dt.present?
    raise("no tag for #{dt}") if tag.nil? && dt.present?

    engine = Marty::ScriptSet.new(tag).get_engine(script)
    # IMPORTANT: engine evals (e.g. eval_to_hash) modify the
    # params. So, need to clone it.
    engine.eval_to_hash(node, attrs, params.clone)

    # FIXME: should sanitize res to make sure that no nodes are being
    # passed back.  It's likely that nodes which are not from the
    # current tag can caused problems.
  end

  # evaluate script's node attribute (attr) with the given params.  dt
  # is used to determine which script tag to use.  The latest tag is
  # used if dt is nil.
  delorean_fn :evaluate, sig: 5 do |dt, script, node, attr, params|
    tag = Marty::Tag.find_match(dt) if dt.present?
    raise("no tag for #{dt}") if tag.nil? && dt.present?

    # nil tag, uses the latest one
    engine = Marty::ScriptSet.new(tag).get_engine(script)

    # IMPORTANT: engine evals (e.g. eval_to_hash) modify the
    # params, but it is possible that we may be passing in
    # a frozen hash. To avoid performance impacts, we should first check if
    # params is frozen to decide whether to dup (frozen) or clone (not frozen).
    engine.evaluate(node, attr, params.frozen? ? params.dup : params.clone)
  end

  delorean_fn :pretty_print, sig: 1 do |id|
    script = find_by_id id

    next "unknown script #{id}" unless script

    CodeRay.scan(script.body, :ruby).div(line_numbers: :table)
  end

  class << self
    def find_script(sname, tag = nil)
      tag = Marty::Tag.map_to_tag(tag)
      Marty::Script.mcfly_pt(tag.created_dt).find_by(name: sname)
    end

    def create_script(name, body)
      script      = new
      script.name = name
      script.body = body
      script.save
      script
    end

    def load_a_script(sname, body, dt = nil)
      s = Marty::Script.find_by(obsoleted_dt: 'infinity', name: sname)

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

    def load_script_bodies(bodies, dt = nil)
      bodies.each do |sname, body|
        load_a_script(sname, body, dt)
      end

      # Create a new tag if scripts were modified after the last tag
      tag = Marty::Tag.get_latest1
      latest = Marty::Script.order('created_dt DESC').first

      tag_time = (dt || [latest.try(:created_dt), Time.now].compact.max) +
        1.second

      # If no tag_time is provided, the tag created_dt will be the same
      # as the scripts.
      tag = Marty::Tag.do_create(tag_time, 'tagged from load scripts') if
        !(tag && latest) || tag.created_dt <= latest.created_dt

      tag
    end

    def load_scripts(path = nil, dt = nil)
      files = get_script_file_paths(path)

      bodies = read_script_files(files)

      load_script_bodies(bodies, dt)
    end

    def read_script_files(files)
      files.map do |fname, fpath|
        script_name = fname.camelize.gsub('::', '__')
        [script_name, File.read(fpath)]
      end
    end

    def get_script_filenames(paths = nil)
      get_script_file_paths(paths).values
    end

    def get_script_file_paths(paths = nil)
      paths = get_script_paths(paths)

      paths.each_with_object({}) do |path, filenames|
        Dir.glob("#{path}/**/*.dl").each do |filename|
          base_pathname = Pathname.new(path)
          pathname = Pathname.new(filename).relative_path_from(base_pathname)
          relative_file_name = pathname.sub_ext('').to_s

          next if filenames.key?(relative_file_name)

          filenames[relative_file_name] = filename
        end
      end
    end

    def get_script_paths(paths)
      paths_from_config = Rails.configuration.marty.delorean_scripts_path

      return Array(paths) if paths
      return paths_from_config if paths_from_config.present?

      [
        "#{Rails.root}/delorean",
        # FIXME: HACKY, wouldn't it be better to use
        # Gem::Specification.find_by_name("marty").gem_dir??
        File.expand_path('../../../../delorean', __FILE__),
      ]
    end

    def delete_scripts
      ActiveRecord::Base.connection.
        execute('ALTER TABLE marty_scripts DISABLE TRIGGER USER;')
      Marty::Script.delete_all
      ActiveRecord::Base.connection.
        execute('ALTER TABLE marty_scripts ENABLE TRIGGER USER;')
    end
  end
end
