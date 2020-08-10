###################
# This configuration (or one similar to it) is only necessary if you plan to
# use monit as a keep-alive monitor for your delayed job background processes.
###################

## CONFIG # These are filled in with the common values for our stacks
RAILS_ROOT_PATH= #!!FILL ME OUT!!#
RUN_AS_USER=www-data
MONIT_BIN_PATH=/etc/init.d/monit
MONIT_CONFIG_PATH=/etc/monit/conf.d/delayed_job
# There is a background job that should restart the DJ workers in Marty
# gracefully. However, in the the event that all the DJ workers on a server get
# hung, this background will be unable to run on the server. Monit will use
# this MAX_ALIVE_TIME to kill and restart the workers forcefully in that event.
MAX_ALIVE_TIME="48 hours"

## SCRIPT # This will create your monit config and launch monit/DJ workers
DJ_BIN_PATH=$RAILS_ROOT_PATH/bin/delayed_job
PIDFOLDER=$RAILS_ROOT_PATH/tmp/pids

# Stop monit so that if delayed jobs are running with old code we can kill them
# as this script should only get run during deployments
$MONIT_BIN_PATH stop

# Kill the old delayed job workers by looking for delayed_job processes
# we can't kill by process name because they run as `ruby`
for pid in `ps aux | grep delayed_job | grep -v "grep" | awk '{print $2}'`; do
   kill -9 $pid
done

# Empty /etc/monit/conf.d/delayed_job file
> $MONIT_CONFIG_PATH

# Marty expects the number of delayed jobs to be equal to # of CPUs
DELAYED_JOBS_PER_SERVER="$(grep -c ^processor /proc/cpuinfo)"

# Make sure our pid directory is there
mkdir -p $PIDFOLDER

# We run DJs as root, therefore we should grant access to our run-as user to call our DJ bin.
# We only want to run this if we haven't already added these permissions
# note: If you want more than 9 workers/server -- change ? to ??, ???, etc.
if (("$(grep -c $DJ_BIN_PATH '/etc/sudoers')"==0)); then
   echo "$RUN_AS_USER ALL=(root) NOPASSWD: /bin/bash -c $DJ_BIN_PATH status -n ? --sleep-delay 5" >> /etc/sudoers
   echo "$RUN_AS_USER ALL=(root) NOPASSWD: /bin/bash -c $DJ_BIN_PATH restart -n ? --sleep-delay 5" >> /etc/sudoers
   echo "$RUN_AS_USER ALL=(root) NOPASSWD: /bin/bash -c $DJ_BIN_PATH stop -n ? --sleep-delay 5" >> /etc/sudoers
fi

# Create the monit config
DJ_INDEX=`expr $DELAYED_JOBS_PER_SERVER - 1`
for i in `seq 0 1 $DJ_INDEX`; do

   # Write a monit entry
   cat >> $MONIT_CONFIG_PATH <<EOF

check process delayed_job.$i
   with pidfile $PIDFOLDER/delayed_job.$i.pid
   start program = "/bin/su -c '$DJ_BIN_PATH --pid-dir=$PIDFOLDER -i $i start' - root"
   stop program = "/bin/su -c '$DJ_BIN_PATH --pid-dir=$PIDFOLDER -i $i stop' - root"
   if uptime > $MAX_ALIVE_TIME then restart

EOF
done

# Restart monit, which will find your pids missing and start DJs
$MONIT_BIN_PATH restart
