#!/usr/bin/env bash
set -e

source "/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash"
if [ -f /workspace/install/local_setup.bash ]; then
  source /workspace/install/local_setup.bash
fi

exec "$@"
