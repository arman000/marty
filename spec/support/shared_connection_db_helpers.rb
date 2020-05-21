module Marty; module RSpec; module SharedConnectionDbHelpers
  def current_db
    ActiveRecord::Base.connection_config[:database]
  end

  def save_clean_db(clean_file)
    if db_host == 'localhost'
      `pg_dump -O -p #{db_port} -Fc #{current_db} > #{clean_file}`
    else
      `#{remote_db_pw} pg_dump -O -Fc #{remote_db_args} #{current_db} > #{clean_file}`
    end
  end

  def restore_clean_db(clean_file, remove_file = true)
    self.use_transactional_tests = false

    if db_host == 'localhost'
      `pg_restore -p #{db_port} -j 2 -O -x -c -d #{current_db} #{clean_file}`
    else
      `#{remote_db_pw} pg_restore #{remote_db_args} #{restore_args(current_db, clean_file)}`
    end

    `rm -f #{clean_file}` if remove_file
    ActionCable.server.pubsub.shutdown
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.reset_shared_connection
    self.use_transactional_tests = true
  end

  private

  def current_db
    ActiveRecord::Base.connection_config[:database]
  end

  def db_host
    ActiveRecord::Base.connection_config[:host] || 'localhost'
  end

  def db_port
    return 5432 if ActiveRecord::Base.connection_config[:port].blank?

    ActiveRecord::Base.connection_config[:port]
  end

  def db_user
    ActiveRecord::Base.connection_config[:username]
  end

  def db_password
    ActiveRecord::Base.connection_config[:password]
  end

  def restore_args db, from
    "-j 2 -O -x -c -d #{db} #{from}"
  end

  def remote_db_args
    "-h #{db_host} -p #{db_port} -U #{db_user} -w"
  end

  def remote_db_pw
    "PGPASSWORD='#{db_password}'"
  end
end end end
