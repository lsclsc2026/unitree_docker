#!/usr/bin/env bash
# Source ROS scripts without nounset; generated setup scripts may read unset vars.
_unitree_restore_nounset=0
case $- in *u*) _unitree_restore_nounset=1; set +u ;; esac
source /opt/ros/humble/setup.bash
export UNITREE_PROJECT_ROOT="${UNITREE_PROJECT_ROOT:-/home/unitree/unitree_robot_development}"
export UNITREE_DATA_ROOT="${UNITREE_DATA_ROOT:-/home/unitree/data}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-1}"
# SDK native DDS libraries belong to native backends; never add them globally.
for _unitree_repo in u_robot_move u_robot_audio; do
  _unitree_setup="$UNITREE_PROJECT_ROOT/$_unitree_repo/install/local_setup.bash"
  if [[ -f "$_unitree_setup" ]]; then source "$_unitree_setup"; fi
done
if [[ -n ${UNITREE_NETWORK_INTERFACE:-} && -z ${CYCLONEDDS_URI:-} ]]; then
  if [[ ! $UNITREE_NETWORK_INTERFACE =~ ^[a-zA-Z0-9_.:-]+$ ]]; then
    printf '无效 UNITREE_NETWORK_INTERFACE\n' >&2
    return 2
  fi
  export CYCLONEDDS_URI="<CycloneDDS><Domain><General><Interfaces><NetworkInterface name=\"${UNITREE_NETWORK_INTERFACE}\"/></Interfaces></General></Domain></CycloneDDS>"
fi
unset _unitree_repo _unitree_setup
if [[ $_unitree_restore_nounset == 1 ]]; then set -u; fi
unset _unitree_restore_nounset
