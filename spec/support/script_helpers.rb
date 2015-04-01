module ScriptHelpers
  def load_a_script(sname, body, dt=nil)
    s = Marty::Script.lookup('infinity', sname)

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

  def load_script_bodies(bodies, dt=nil)
    bodies.each {
      |sname, body|
      load_a_script(sname, body, dt)
    }

    # Create a new tag if scripts were modified after the last tag
    tag = Marty::Tag.get_latest1
    latest = Marty::Script.order("created_dt DESC").first

    tag_time = (dt || [latest.created_dt, Time.now].max) + 1.second

    # If no tag_time is provided, the tag created_dt will be the same
    # as the scripts.
    tag = Marty::Tag.do_create(tag_time, "tagged from load scripts") if
      !tag or tag.created_dt <= latest.created_dt

    tag
  end
end
