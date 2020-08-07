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
      2. Set your Marty::Config["DELAYED_JOB_PARAMS"] to match the number of
         delayed job workers that you put in your monit script. By default, the
         example script will expect 1 DJ worker per CPU. If you choose a
         different configuration be sure to update Marty accordingly

      WARNING!!!!!!!!
      WMSG
    announce(wmsg)

    # Uncomment this to set your DJ Params to be equal to the # of processors
    # as is expected by the example script mentioned above
    # Marty::Config["DELAYED_JOB_PARAMS"] = "-n #{Etc.nprocessors} --sleep-delay 5"
  end

  def down
    announce("no-op")
  end
end
