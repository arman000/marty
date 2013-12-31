class Marty::ScriptSet
  # maps script_id to Delorean engine
  @@engines, @@dengines = {}, {}

  def self.reset
    @@engines, @@dengines = {}, {}
  end

  def self.parse(sname, body, version=nil, sset=nil)
    sset ||= Marty::ScriptContainer.new

    engine = Delorean::Engine.new(sname, version)
    engine.parse(body, sset)
    engine
  end

  def self.get_engine(script, sset=nil)
    script = Marty::Script.find(script) if
      script.is_a?(Fixnum)

    return {error: "No such script"} unless script

    if script.isdev?
      ds = script.group_dscript
      engine, updated_at = @@dengines[ds.id]

      if updated_at && updated_at == ds.updated_at
        sset.add_imports(engine) if sset
        return engine
      end

      engine = parse(script.name, ds.body, script.version, sset)
      @@dengines[ds.id] = [engine, ds.updated_at]
    else
      # using created_dt instead of version so that we handle cases
      # where cucumber wipes the database but @@engines is still
      # cached.
      engine, created_dt = @@engines[script.id]

      if created_dt && created_dt == script.created_dt
        sset.add_imports(engine) if sset
        return engine
      end

      engine = parse(script.name, script.body, script.version, sset)
      @@engines[script.id] = [engine, script.created_dt]
    end
    engine
  end

end
