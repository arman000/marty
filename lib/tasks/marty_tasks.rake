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
end
