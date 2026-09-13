#!/usr/bin/env bash
set -eo pipefail
source /etc/unitree/env.sh
set -u
printf 'ROS_DISTRO=%s\nRMW_IMPLEMENTATION=%s\nROS_LOCALHOST_ONLY=%s\nROS_DOMAIN_ID=%s\n' "$ROS_DISTRO" "$RMW_IMPLEMENTATION" "$ROS_LOCALHOST_ONLY" "$ROS_DOMAIN_ID"
printf 'Architecture: '; uname -m
for tool in cmake g++ colcon python3 ffmpeg gst-inspect-1.0; do command -v "$tool"; done
python3 -c 'import rclpy, cv2, yaml, numpy; print("Python ROS/camera dependencies: OK")'
for package in rmw_cyclonedds_cpp nav2_bringup nav2_collision_monitor nav2_mppi_controller slam_toolbox foxglove_bridge; do
  ros2 pkg prefix "$package"
done
for repo in u_robot_move u_robot_audio u_robot_duck_dataset; do
  [[ -d "$UNITREE_PROJECT_ROOT/$repo" ]] || { echo "Missing workspace: $repo" >&2; exit 1; }
done
sdk="$UNITREE_PROJECT_ROOT/sdk"
[[ -f "$sdk/unitree_sdk2/include/unitree/robot/a2/audio/audio_client.hpp" ]]
[[ -f "$sdk/unitree_sdk2/lib/$(uname -m)/libunitree_sdk2.a" ]]
[[ -f "$sdk/unitree_ros2/cyclonedds_ws/src/unitree/unitree_api/package.xml" ]]
description="$sdk/unitree_ros/robots/a2_description"
[[ -f "$sdk/unitree_ros/LICENSE" ]]
[[ -f "$description/urdf/a2.urdf" ]]
[[ -d "$description/meshes" ]]
python3 - "$description/urdf/a2.urdf" <<'PY_CHECK'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
urdf = Path(sys.argv[1])
meshes = [node.attrib["filename"] for node in ET.parse(urdf).iter("mesh")]
assert meshes, "A2 URDF has no mesh references"
for mesh in meshes:
    path = (urdf.parent / mesh).resolve()
    assert path.is_file(), f"Missing A2 mesh: {path}"
print(f"A2 URDF mesh references: {len(meshes)} resolved")
PY_CHECK
echo 'Environment checks passed; no ROS graph discovery or hardware commands performed.'
