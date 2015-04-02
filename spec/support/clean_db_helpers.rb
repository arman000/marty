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
    self.use_transactional_fixtures = true
  end
end
