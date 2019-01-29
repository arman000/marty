module Marty; module RSpec; module Setup
  def marty_whodunnit
    Mcfly.whodunnit = Marty::User.find_by_login('marty')
  end

  def load_scripts(path, dt)
    Marty::Script.load_scripts(path, dt)
    Marty::ScriptSet.clear_cache
  end

  def posting(type, dt, comment)
    Marty::Posting.clear_lookup_cache!
    Marty::Posting.do_create(type, dt, comment)
  end

  def dg_from_import(*args)
    Marty::DataGrid.create_from_import(*args)
  end

  def do_import_summary(*args)
    Marty::DataImporter.do_import_summary(*args)
  end

  def disable_triggers(table_name, &block)
    begin
      ActiveRecord::Base.connection
        .execute("ALTER TABLE #{table_name} DISABLE TRIGGER USER;")

      block.call
    ensure
      ActiveRecord::Base.connection
        .execute("ALTER TABLE #{table_name} ENABLE TRIGGER USER;")
    end
  end
end end end
