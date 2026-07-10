# zed_wrapper container

## Owner / maintainer

Grip Robotics — vision / perception team (Stereolabs ZED integration).

## Base image

Standalone GPU image (does **not** use `grip-ros-zenoh:jazzy`):

```
nvcr.io/nvidia/cuda:12.8.0-devel-ubuntu24.04
```

ZED SDK v5.4.0 is installed from the Stereolabs binary installer inside the Dockerfile.

## Package build closure

Built with `colcon build --packages-up-to zed_wrapper`:

| Package | Source |
|---------|--------|
| `zed_components` | Same repo — copied from `src/zed-ros2-wrapper/zed_components` |
| `zed_wrapper` | Same repo — copied from `src/zed-ros2-wrapper/zed_wrapper` |
| `zed_msgs` | Apt — `ros-jazzy-zed-msgs` |
| `zed_description` | Apt — `ros-jazzy-zed-description` |

No `deps.repos` is required; external interface packages are available as Jazzy binaries.

## Non-rosdep system dependencies

| Dependency | How installed |
|------------|---------------|
| NVIDIA CUDA 12.8 | Base image |
| ZED SDK 5.4.0 | Binary installer in Dockerfile (`skip_tools`) |
| OpenCV, libusb | Apt in Dockerfile |

## Build

From the **grip repo root** (after `import-deps.sh` has pulled `zed-ros2-wrapper`):

```bash
docker compose --profile build build ros-zenoh-base   # once, if not already built
docker compose build zed-wrapper
```

Dockerfile path: `src/zed-ros2-wrapper/zed_wrapper/docker/Dockerfile`

Build context must be the grip repo root (`.`).

## Default run command

The node is started via launch file (composable components — no standalone `ros2 run` executable):

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedx
```

Replace `zedx` with your camera model: `zed`, `zedm`, `zed2`, `zed2i`, `zedx`, `zedxm`, `zedxnano`, `zedxhdrmini`, `zedxhdr`, `zedxhdrmax`, `virtual`, `zedxonegs`, `zedxone4k`, `zedxonehdr`.

## Runtime environment (set by grip compose, not the image)

```yaml
RMW_IMPLEMENTATION: rmw_zenoh_cpp
ROS_DOMAIN_ID: <shared-id>
ZENOH_ROUTER_CHECK_ATTEMPTS: "0"
ZENOH_CONFIG_OVERRIDE: 'mode="client";connect/endpoints=["tcp/zenoh-router:7447"]'
```

The entrypoint does **not** start `rmw_zenohd` or any ROS node.

## Suggested compose service

```yaml
zed-wrapper:
  build:
    context: .
    dockerfile: src/zed-ros2-wrapper/zed_wrapper/docker/Dockerfile
  profiles: [zed, stack-vision-zed]
  networks: [grip-net]
  environment: *ros-env
  depends_on: [zenoh-router]
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
  devices:
    - /dev/bus/usb:/dev/bus/usb
  volumes:
    - /usr/local/zed/resources:/usr/local/zed/resources
    - /usr/local/zed/settings:/usr/local/zed/settings
    - /dev/shm:/dev/shm
  command:
    - ros2
    - launch
    - zed_wrapper
    - zed_camera.launch.py
    - camera_model:=zedx
```

### Hardware / network notes

- **GPU**: NVIDIA driver + `nvidia-container-toolkit` required on the host.
- **USB3 cameras** (ZED, ZED2, ZED2i, ZED X Mini): pass `/dev/bus/usb`.
- **GMSL2 cameras** (ZED X, ZED X One): additionally mount `/tmp`, `/var/nvidia/nvcam/settings/`, and the `zed_x_daemon` systemd unit — see [Stereolabs Docker guide](https://www.stereolabs.com/docs/docker/).
- **AI models**: bind-mount `/usr/local/zed/resources` to avoid re-downloading on every container restart.
- **Offline calibration**: bind-mount `/usr/local/zed/settings` if cameras lack internet access.

## Test mode

Interactive shell without auto-starting a node:

```bash
docker compose run --rm zed-wrapper bash
```

Inside the shell, verify the build:

```bash
ros2 pkg list | grep zed
ros2 launch zed_wrapper zed_camera.launch.py -s
```

## Local subrepo development

When developing outside the grip monorepo, build with a grip-style directory layout as build context:

```
build-context/
  src/zed-ros2-wrapper/
    zed_components/
    zed_wrapper/
```

```bash
docker build \
  -f zed_wrapper/docker/Dockerfile \
  --build-arg PACKAGE_NAME=zed_wrapper \
  -t zed-wrapper:dev \
  build-context/
```
