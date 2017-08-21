module CleanDbHelpers
  def current_db
    ActiveRecord::Base.connection_config[:database]
  end

  def save_clean_db(clean_file)
    `pg_dump -O -Fc #{current_db} > #{clean_file}`
  end

  def restore_clean_db(clean_file, remove_file = true)
    self.use_transactional_tests = false
    `pg_restore -j 2 -O -x -c -d #{current_db} #{clean_file}`
    `rm -f #{clean_file}` if remove_file
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.reset_shared_connection
    self.use_transactional_tests = true
  end
end
