ARG BASE_IMAGE=ros:humble-ros-base-jammy
FROM ${BASE_IMAGE}
ARG USER_UID=1000
ARG USER_GID=1000
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ROS_DOMAIN_ID=0 ROS_LOCALHOST_ONLY=1 \
    UNITREE_PROJECT_ROOT=/home/unitree/unitree_robot_development \
    UNITREE_DATA_ROOT=/home/unitree/data
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git ca-certificates curl pkg-config \
    iproute2 iputils-ping procps less nano bash-completion \
    python3-pip python3-venv python3-colcon-common-extensions python3-rosdep \
    python3-yaml python3-numpy python3-opencv python3-pil python3-pytest \
    ffmpeg gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libopencv-dev \
    libeigen3-dev libpcl-dev libssl-dev libyaml-cpp-dev \
    ros-humble-ament-cmake-gtest ros-humble-ament-lint-auto ros-humble-ament-lint-common \
    ros-humble-rmw-cyclonedds-cpp ros-humble-rosidl-generator-dds-idl \
    ros-humble-gps-msgs ros-humble-nmea-msgs ros-humble-pcl-ros \
    ros-humble-pointcloud-to-laserscan ros-humble-navigation2 ros-humble-nav2-bringup \
    ros-humble-nav2-collision-monitor ros-humble-nav2-mppi-controller \
    ros-humble-nav2-rotation-shim-controller ros-humble-nav2-smac-planner \
    ros-humble-robot-localization ros-humble-slam-toolbox ros-humble-twist-mux \
    ros-humble-xacro ros-humble-robot-state-publisher ros-humble-rviz2 \
    ros-humble-foxglove-bridge ros-humble-cv-bridge ros-humble-image-transport \
    && dpkg-query -W -f='${Package}=${Version}\n' > /usr/local/share/unitree-image-packages.txt \
    && rm -rf /var/lib/apt/lists/*
RUN if ! getent group "${USER_GID}" >/dev/null; then groupadd --gid "${USER_GID}" unitree; fi \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash unitree \
    && mkdir -p /home/unitree/unitree_robot_development /home/unitree/data \
    && chown -R "${USER_UID}:${USER_GID}" /home/unitree
COPY docker/env.sh /etc/unitree/env.sh
COPY docker/entrypoint.sh /usr/local/bin/unitree-entrypoint
RUN chmod 0755 /usr/local/bin/unitree-entrypoint \
    && printf '\nsource /etc/unitree/env.sh\n' >> /home/unitree/.bashrc
USER unitree
WORKDIR /home/unitree/unitree_robot_development
ENTRYPOINT ["/usr/local/bin/unitree-entrypoint"]
CMD ["bash"]
