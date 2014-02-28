class Marty::ScriptSet < Delorean::AbstractContainer
  # ScriptSet acts as a cache for Delorean engine compiles

  # maps script_id to Delorean engine
  @@engines, @@dengines = {}, {}

  def self.reset
    @@engines, @@dengines = {}, {}
  end

  attr_reader :tag

  def initialize(tag=nil)
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

    script = Marty::Script.find_script(sname, tag)

    raise "No such script" unless script

    if tag.isdev?
      engine, created_dt = @@dengines[sname]

      # FIXME: need to invalidate engine and its imports if any of its
      # imports changed.  Right now, just checking script itself.

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse_check(sname, script.body)
      @@dengines[sname] = [engine, script.created_dt]
    else
      # using created_dt so that we handle cases where cucumber wipes
      # the database but @@engines is still cached. --- FIXME: Needed?
      engine, created_dt = @@engines[[tag.id, sname]]

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse_check(sname, script.body)
      @@engines[[tag.id, sname]] = [engine, script.created_dt]
    end
    engine
  end
end
