module CleanDbHelpers
  def current_db
    ActiveRecord::Base.connection_config[:database]
  end

  def save_clean_db(clean_file)
    `pg_dump -O -Fc #{current_db} > #{clean_file}`
  end

  def restore_clean_db(clean_file)
    self.use_transactional_fixtures = false
    `pg_restore -j 2 -O -x -c -d #{current_db} #{clean_file}`
    `rm -f #{clean_file}`
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.reset_shared_connection
    self.use_transactional_fixtures = true
  end

  def simple_restore_tie_out_db(tdir)
    svc = ActiveRecord::Migrator.current_version
    from = "#{tdir}/dump.psql"
    if !db_host || db_host == 'localhost'
      `pg_restore #{restore_args(from)}`
    else
      `#{remote_db_pw} pg_restore #{remote_db_args} #{restore_args(from)} 2>&1`
    end

    svr = ActiveRecord::Migrator.current_version
    if svc != svr
      puts "#{'*' *45}\n" +
           "Test database and dump file are out of sync!\n" +
           "Clean Schema Version: #{svc}\n" +
           "Dump Schema Version:  #{svr}\n" +
           "#{'*' *45}"
      if svc > svr
        raise "Out of sync dump file #{tdir}/dump.psql"
      else
        raise "Out of sync test database"
      end
    end

    ActiveRecord::Base.clear_all_connections!
  end
end
