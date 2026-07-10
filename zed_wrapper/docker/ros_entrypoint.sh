#!/usr/bin/env bash
set -e

source "/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash"
if [ -f /opt/grip/install/local_setup.bash ]; then
  source /opt/grip/install/local_setup.bash
fi

exec "$@"
