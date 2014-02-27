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

  def parse(script)
    parse_check script.name, script.body
  end

  def parse_check(sname, body)
    engine = Delorean::Engine.new(sname, self)
    engine.parse(body)
    engine
  end

  def get_engine(script)
    if script.is_a?(Fixnum)
      script = Marty::Script.find_by_id(script)

      if script
        # sanity check -- make sure script belongs to the tag
        sane = Marty::Script.find_script(script.name, tag)
        raise "script/tag mismatch #{script.id} #{tag.name}" unless
          sane && sane.id == script.id
      end
    elsif script.is_a?(String)
      script = Marty::Script.find_script(script, tag)
    end

    raise "No such script" unless script
    raise "bad script arg: #{script}" unless script.is_a? Marty::Script

    if tag.isdev?
      engine, created_dt = @@dengines[script.id]

      # FIXME: need to invalidate engine and its imports if any of its
      # imports changed.  Right now, just checking script itself.

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse(script)
      @@dengines[script.id] = [engine, script.created_dt]
    else
      # using created_dt so that we handle cases where cucumber wipes
      # the database but @@engines is still cached. --- FIXME: Needed?
      engine, created_dt = @@engines[[tag.id, script.id]]

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse(script)
      @@engines[[tag.id, script.id]] = [engine, script.created_dt]
    end
    engine
  end
end
