class WarnToProperlyConfigureMonit < ActiveRecord::Migration[5.1]
  def up
    wmsg = <<~WMSG
      \n\n
      WARNING!!!!!!!!

      MONIT MAY NOT BE CONFIGURED PROPERLY

      To ensure that monit is properly monitoring your background jobs, please:
      1. Confirm the script that configures monit (typically in .application-scripts/)
         is setup to check for the pidfiles in <RAILS_ROOT>/tmp/pids. An example
         monit config script is provided is marty/.application-scripts/examples.
      2. Set your Marty::Config["DELAYED_JOB_WORKERS"] to match the number of
         delayed job workers that you put in your monit script. By default, the
         example script will expect 1 DJ worker per CPU. If you choose a
         different configuration be sure to update both the script and your
         Marty::Config to keep the two in sync.

      WARNING!!!!!!!!
      WMSG
    announce(wmsg)

    Marty::Config["DELAYED_JOB_WORKERS"] = "#{Etc.nprocessors}"
    # Uncomment this to remove the old DELAYED_JOB_PARAMS config
    # Marty::Config.where(key: 'DELAYED_JOB_PARAMS').destroy_all
  end

  def down
    Marty::Config.where(key: 'DELAYED_JOB_WORKERS').destroy_all
  end
end
