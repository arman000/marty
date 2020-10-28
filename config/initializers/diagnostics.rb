marty_path = Gem.loaded_specs['marty'].full_gem_path
Dir["#{marty_path}/lib/marty/diagnostic/**/*.rb"].sort.each { |f| require f }

app_name = Marty::RailsApp.application_name.downcase
app_diag_path = Rails.application.config.marty.diagnostic_directory ||
                Rails.root.join("lib/#{app_name}/diagnostic")

Dir["#{app_diag_path}/**/*.rb"].sort.each { |f| require f }
