# Standalone GPU image for zed_wrapper (ZED SDK + CUDA).
# Build from the grip repo root:
#   docker compose --profile build build ros-zenoh-base   # once
#   docker compose build zed-wrapper

ARG CUDA_MAJOR=12
ARG CUDA_MINOR=8
ARG CUDA_PATCH=0
FROM nvcr.io/nvidia/cuda:${CUDA_MAJOR}.${CUDA_MINOR}.${CUDA_PATCH}-devel-ubuntu24.04

ARG PACKAGE_NAME=zed_wrapper
ARG ZED_SDK_VERSION=5.4.0
ARG ROS_DISTRO=jazzy

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=${ROS_DISTRO} \
    NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}compute,video,utility

# ---- Base system tools -------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales curl gnupg lsb-release software-properties-common \
    build-essential cmake git wget zstd usbutils \
    python3 python3-dev python3-pip \
    libopencv-dev libpng-dev libgomp1 libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# ---- ROS 2 Jazzy + Zenoh middleware ------------------------------------------
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
       http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
       > /etc/apt/sources.list.d/ros2.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    ros-${ROS_DISTRO}-rmw-zenoh-cpp \
    ros-${ROS_DISTRO}-zed-msgs \
    ros-${ROS_DISTRO}-zed-description \
    ros-${ROS_DISTRO}-robot-localization \
    ros-${ROS_DISTRO}-backward-ros \
    ros-${ROS_DISTRO}-image-transport-plugins \
    ros-${ROS_DISTRO}-compressed-image-transport \
    ros-${ROS_DISTRO}-compressed-depth-image-transport \
    ros-${ROS_DISTRO}-theora-image-transport \
    ros-${ROS_DISTRO}-zstd-image-transport \
    python3-rosdep python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir \
    argcomplete empy lark numpy

RUN rosdep init || true

# ---- ZED SDK (binary installer — not available via rosdep) -----------------
ARG ZED_SDK_URL=https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/cu12/ubuntu24
RUN wget -q -O /tmp/ZED_SDK.run "${ZED_SDK_URL}" \
    && chmod +x /tmp/ZED_SDK.run \
    && /tmp/ZED_SDK.run -- silent skip_tools \
    && ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so \
    && rm -f /tmp/ZED_SDK.run

# ---- Package sources (grip build context = repo root) ------------------------
WORKDIR /workspace

COPY src/zed-ros2-wrapper/zed_components /workspace/src/zed-ros2-wrapper/zed_components
COPY src/zed-ros2-wrapper/zed_wrapper /workspace/src/zed-ros2-wrapper/zed_wrapper
COPY src/zed-ros2-wrapper/zed_wrapper/docker/ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod 755 /ros_entrypoint.sh

# ---- Scoped rosdep + colcon build --------------------------------------------
RUN bash -c "set -eo pipefail; \
    source /opt/ros/${ROS_DISTRO}/setup.bash; \
    rosdep update; \
    PATHS=\$(colcon list --packages-up-to ${PACKAGE_NAME} --paths-only | tr '\n' ' '); \
    rosdep install --from-paths \${PATHS} --ignore-src -r -y; \
    colcon build --packages-up-to ${PACKAGE_NAME} --symlink-install \
      --cmake-args -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
        -DCMAKE_CXX_FLAGS='-Wl,--allow-shlib-undefined'"

ENTRYPOINT ["/ros_entrypoint.sh"]
