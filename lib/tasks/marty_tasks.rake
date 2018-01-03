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

  # currently this is for delorean style rules only.  if other types were ever
  # added (eg some sort of SQL rule like apollo has), that would probably be
  # a new rake task
  desc 'generate rule table migration'
  task :generate_rule_table_migration, [:table] => :environment do |t, args|
    (puts "Usage: rake marty:generate_rule_table_migration[<table name>]"
     next) unless args[:table]
    table = args[:table]
    filename = Rails.root.join("db/migrate",Time.zone.now.strftime(
                                 "%Y%m%d%H%M%S_create_#{table}.rb"))
    puts "creating #{filename}"
    File.open(filename, "w") do |f|
      f.puts <<~EOF
        class Create#{table.camelize} < McflyMigration
          include Marty::Migrations
          def change()
            create_table :#{table} do |t|
              t.string :name, null: false
              # set type enum
              t.column :rule_type, :enum_name, null: false
              t.datetime :start_dt, null: false
              t.datetime :end_dt, null: true
              t.string :engine, null: true  # add engine default if used
              # add any additional attrs here
              t.jsonb :simple_guards,    null: false, default: {}
              t.json  :computed_guards,  null: false, default: {}
              t.jsonb :grids,            null: false, default: {}
              t.json  :results,          null: false, default: {}
              t.jsonb :fixed_results,    null: false, default: {}
            end
            execute("CREATE OR REPLACE FUNCTION to_numrange(val text) "\\
                    "RETURNS numrange AS "\\
                    "$BODY$ select numrange(val); $BODY$ "\\
                    "LANGUAGE SQL IMMUTABLE;")
           end
        end
      EOF
    end
    puts "please edit the migration file to customize the rule"
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
end
