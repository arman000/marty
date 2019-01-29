class Marty::ScriptSet < Delorean::AbstractContainer
  # ScriptSet acts as a process-wide cache for Delorean
  # engines. FIXME: rewrite as Singleton.

  attr_reader :tag

  def self.clear_cache
    @@engines, @@dengines, @@dengines_dt = {}, {}, nil
  end

  clear_cache

  def initialize(tag = nil)
    @tag = Marty::Tag.map_to_tag(tag)
    super()
  end

  def parse_check(sname, body)
    engine = Delorean::Engine.new(sname, self)
    engine.parse(body)
    engine
  end

  def get_engine(sname)
    raise "bad sname #{sname}" unless sname.is_a?(String)

    if tag.isdev?
      # FIXME: there are race conditions here if a script changes in
      # the middle of a DEV import sequence. But, DEV imports are
      # hacky/rare anyway.  So, don't bother for now.

      max_dt = Marty::Script
        .order("created_dt DESC").limit(1).pluck(:created_dt).first

      @@dengines_dt ||= max_dt

      # reset dengine cache if a script has changed
      @@dengines = {} if max_dt > @@dengines_dt

      engine = @@dengines[sname]

      return engine if engine

      script = Marty::Script.find_script(sname, tag) || raise("No such script")

      @@dengines[sname] = parse_check(sname, script.body)
    else
      engine = @@engines[[tag.id, sname]]

      return engine if engine

      script = Marty::Script.find_script(sname, tag) || raise("No such script")

      @@engines[[tag.id, sname]] = parse_check(sname, script.body)
    end
  end
end
