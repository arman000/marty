module SpecSetup
  def load_scripts(path, dt)
    Marty::Script.load_scripts(path, dt)
    Marty::ScriptSet.clear_cache
#    Gemini::RuleScriptSet.clear_cache
  end

  def posting(type, dt, comment)
    Marty::Posting.clear_lookup_cache!
    Marty::Posting.do_create(type, dt, comment)
  end

  def dg_from_import(*args)
    Marty::DataGrid.create_from_import(*args)
  end

  def marty_whodunnit
    Mcfly.whodunnit = Marty::User.find_by_login('marty')
  end

  def do_import_summary(*args)
    Marty::DataImporter.do_import_summary(*args)
  end
end
