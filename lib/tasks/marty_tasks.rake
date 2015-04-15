namespace :marty do
  desc 'Load Engine Seed data.'
  task seed: :environment do
    begin
      Marty::Engine.load_seed
      puts "Database has been seeded with Marty Engine data."
    rescue => error
      puts "Error: ", error
    end
  end

  desc 'remove all loaded scripts from the database'
  task delete_scripts: :environment do
    Marty::Script.delete_scripts
  end

  desc 'load scripts from the LOAD_DIR directory'
  task load_scripts: :environment do
    Mcfly.whodunnit =
      Marty::User.find_by_login(Rails.configuration.marty.system_account)
    raise 'must have system user account seeded' unless Mcfly.whodunnit
    load_dir = ENV['LOAD_DIR']
    raise 'must provide LOAD_DIR= option' unless load_dir
    Marty::Script.load_scripts(load_dir)
  end
end
