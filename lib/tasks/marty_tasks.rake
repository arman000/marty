namespace :marty do
  desc 'Load Engine Seed data.'
  task seed: :environment do
    begin
      Marty::Engine.load_seed
      puts 'Database has been seeded with Marty Engine data.'
    rescue StandardError => e
      puts 'Error: ', e
    end
  end

  # currently this is for delorean style rules only.  if other types were ever
  # added (eg some sort of SQL rule like apollo has), that would probably be
  # a new rake task
  desc 'generate rule table migration'
  task :generate_rule_table_migration, [:table] => :environment do |_t, args|
    unless args[:table]
      (puts 'Usage: rake marty:generate_rule_table_migration[<table name>]'
       next)
    end
    table = args[:table]
    filename = Rails.root.join('db/migrate', Time.zone.now.strftime(
                                               "%Y%m%d%H%M%S_create_#{table}.rb"))
    puts "creating #{filename}"
    File.open(filename, 'w') do |f|
      f.puts <<~RUBY
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
              # only needed for delorean type rules
              t.jsonb :fixed_results,    null: false, default: {}
            end
            execute("CREATE OR REPLACE FUNCTION to_numrange(val text) "\\
                    "RETURNS numrange AS "\\
                    "$BODY$ select numrange(val); $BODY$ "\\
                    "LANGUAGE SQL IMMUTABLE;")
          end
        end
      RUBY
    end
    puts 'please edit the migration file to customize the rule'
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

  desc 'Merge the results of various SimpleCov coverage reports'
  task merge_coverage_reports: :environment do
    require 'marty/simplecov_helper'
    require_relative '../marty/simplecov_helper.rb'
    Marty::SimpleCovHelper.configure_profile
    puts 'Merging code coverage reports...'
    Marty::SimpleCovHelper.merge_all_results!
  end
end
