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
    Marty::Script.load_scripts(load_dir)
  end

  desc 'Print out all models and their fields'
  task print_schema: :environment do
    Rails.application.eager_load!
    ActiveRecord::Base.descendants.sort_by(&:name).each do |model|
      puts model.name
      model.attribute_names.each do |attribute|
        puts "  #{attribute}"
      end
      puts
    end
  end

  task :generate_migrations_plv8 do
    Marty::Migrations.generate_sql_migrations('db/migrate', 'db/plv8', 'js')
  end

end
