class Marty::ScriptSet < Delorean::AbstractContainer
  # ScriptSet acts as a cache for Delorean engine compiles

  # maps script_id to Delorean engine
  @@engines, @@dengines = {}, {}

  def self.reset
    @@engines, @@dengines = {}, {}
  end

  attr_reader :tag

  def initialize(tag)
    if tag.is_a? String
      tag = Marty::Tag.find_by_name(tag)
    elsif tag.is_a?(Fixnum)
      tag = Marty::Tag.find_by_id(tag)
    end

    raise "bad tag #{tag}" unless tag.is_a? Marty::Tag
    @tag = tag
    super()
  end

  def parse(script)
    engine = Delorean::Engine.new(script.name)
    engine.parse(script.body, self)
    engine
  end

  def get_engine(script)
    if script.is_a?(Fixnum)
      script = Marty::Script.find_by_id(script)
    elsif script.is_a?(String)
      script = Marty::Script.find_script(script, tag)
    end

    return {error: "No such script"} unless script

    raise "bad script arg: #{script}" unless script.is_a? Marty::Script

    if tag.isdev?
      engine, created_dt = @@dengines[script.id]

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse(script)
      @@dengines[script.id] = [engine, script.created_dt]
    else
      # using created_dt instead of version so that we handle cases
      # where cucumber wipes the database but @@engines is still
      # cached.
      engine, created_dt = @@engines[script.id]

      if created_dt && created_dt == script.created_dt
        add_imports(engine)
        return engine
      end

      engine = parse(script)
      @@engines[script.id] = [engine, script.created_dt]
    end
    engine
  end

  ######################################################################

end
