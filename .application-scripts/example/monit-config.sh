#!/bin/bash
chown -R www-data:www-data /var/crape/log
chown -R www-data:www-data /var/crape/tmp/cache/

###################
# This configuration (or one similar to it) is only necessary if you plan to
# use monit as a keep-alive monitor for your delayed job background processes.
###################

##############################################################################
## CONFIG # These are filled in with the common values for our stacks
RAILS_ROOT_PATH=/var/crape
MONIT_BIN_PATH=/etc/init.d/monit
MONIT_CONFIG_PATH=/etc/monit/conf.d/delayed_job
# There is a background job that should restart the DJ workers on a server
# gracefully. However, in the the event that all the DJ workers on a server get
# hung, this background will be unable to run on the server. Monit will use
# this MAX_ALIVE_TIME to kill and restart the workers forcefully in that event.
MAX_ALIVE_TIME="48 hours"

##############################################################################
## SCRIPT # This will create your monit config and launch monit/DJ workers

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

# Make sure the pid directory is present
mkdir -p $RAILS_ROOT_PATH/tmp/pids

# Delayed jobs pid files start at 0 so we create an index
DJ_INDEX=`expr $DELAYED_JOBS_PER_SERVER - 1`

# Create the monit config
for i in `seq 0 1 $DJ_INDEX`; do
   cat >> $MONIT_CONFIG_PATH <<EOF

check process delayed_job.$i with PIDFILE $RAILS_ROOT_PATH/tmp/pids/delayed_job.$i.pid
   start program = "/bin/su -c '$RAILS_ROOT_PATH/bin/delayed_job --pid-dir=$RAILS_ROOT_PATH/tmp/pids -i $i start' - root"
   stop program = "/bin/su -c '$RAILS_ROOT_PATH/bin/delayed_job --pid-dir=$RAILS_ROOT_PATH/tmp/pids -i $i stop' - root"
   if uptime > $MAX_ALIVE_TIME then restart

EOF
done

# Monit will restart the delayed jobs with the desired pidfiles
$MONIT_BIN_PATH restart

