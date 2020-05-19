namespace :marty do
  desc 'remove all loaded scripts from the database'
  task delete_scripts: :environment do
    Marty::Script.delete_scripts
  end

  desc 'load scripts from the LOAD_DIR directory'
  task load_scripts: :environment do
    Mcfly.whodunnit = Marty::User.find_by(
      login: Rails.configuration.marty.system_account
    )

    raise 'must have system user account seeded' unless Mcfly.whodunnit

    load_dir = Rails.application.config.marty.load_dir
    Marty::Script.load_scripts(load_dir)
  end
end
