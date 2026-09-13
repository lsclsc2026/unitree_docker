# 安装与工作区

## 平台和前提

首版针对 Linux x86_64、Ubuntu 22.04 用户空间及 ROS 2 Humble。SDK 也携带 aarch64 库，但整个配套项目（尤其遥控接收器和设备相机）没有完成 aarch64 验证。Docker Desktop 的网络行为与机器人 Linux 主机不同，暂不作为实机部署验证平台。

宿主机需要 Git、Bash、SHA256 工具及可访问的 Docker Engine。Docker 的宿主机安装按 [官方 Ubuntu 安装文档](https://docs.docker.com/engine/install/ubuntu/) 完成；本仓库脚本不安装 Docker、不改宿主机网络。镜像内依赖由 Dockerfile 的 apt 清单安装，包含 ROS 2、Nav2、SLAM Toolbox、Foxglove、CycloneDDS RMW、OpenCV、GStreamer、FFmpeg、C++ 工具链和 colcon。

## 同级目录

```text
unitree-workspace/
├── unitree_docker/          # 本仓库，唯一 Docker 构建上下文
├── u_robot_move/            # ROS 工作区：src/build/install/log
├── u_robot_audio/           # ROS 工作区：src/build/install/log
├── u_robot_duck_dataset/    # Python 采集/离线处理/云端工具
├── sdk/
│   ├── unitree_sdk2/
│   ├── unitree_ros2/
│   └── unitree_ros/         # A2 URDF、网格与许可，导航必需
└── data/
    ├── maps/
    ├── logs/
    └── rosbags/
```

按 README 克隆四个仓库。GitHub 私有仓库权限由宿主机 Git 管理，不把 token、SSH 私钥或 `.gitconfig` 放入镜像。`fetch-sdk.sh` 默认向本仓库父目录的 `sdk` 克隆三个必需依赖（SDK2、ROS2 消息、A2 模型）；不会复制已有设备目录。A2 消息和 C++ SDK 的相对路径要求配套仓库与 `sdk` 同级。

## 构建镜像

```bash
./build.sh --dry-run
UNITREE_IMAGE=unitree-dev:humble-review ./build.sh --execute
```

构建参数：`UNITREE_BASE_IMAGE` 默认 `ros:humble-ros-base-jammy`，`UNITREE_IMAGE` 默认 `unitree-dev:humble-review`；用户 UID/GID 来自执行构建的宿主机账号。以普通用户构建，避免 UID 0 与镜像 root 冲突。需要注册表镜像或 digest 时，通过 `UNITREE_BASE_IMAGE` 设置，无硬编码第三方镜像站。

Dockerfile 只复制 `docker/env.sh` 与 `docker/entrypoint.sh`。`.dockerignore` 使用白名单，仓库源码、SDK 二进制、原始数据和旧 payload 均不进入上下文。镜像构建只安装环境依赖；项目源码随后由挂载提供。镜像中的 `/usr/local/share/unitree-image-packages.txt` 记录实际安装版本。基础 tag 和 apt 仓库会变化，首版不宣称位级可复现；归档测试镜像 digest 和包清单后才可比较升级。

## 构建工作区

```bash
./unitree run
./unitree shell
# 以下在容器内
cd "$UNITREE_PROJECT_ROOT"
bash unitree_docker/scripts/check-env.sh
bash u_robot_move/scripts/build.sh
bash u_robot_audio/scripts/build.sh
source /etc/unitree/env.sh
```

导航 `u_robot_description` 从同级 `unitree_ros/robots/a2_description` 安装 A2 URDF/网格及上游根 LICENSE，因此该仓库为必需依赖，不运行 ROS 1 节点。导航构建脚本同时编译同级 `unitree_ros2` 中 `unitree_api/unitree_go/unitree_hg` 消息，不执行上游 `setup.sh`，也不编译旧 CycloneDDS 工作区。音频直接导入同级 `unitree_sdk2/lib/<架构>/libunitree_sdk2.a`。两者具体功能和测试以各自文档为准。

换工作区位置可设置宿主机 `UNITREE_PROJECT_ROOT=/absolute/path`；容器中的路径固定为 `/home/unitree/unitree_robot_development`，兼容现有启动脚本。不要在宿主机与容器之间复用不同路径生成的 CMake 缓存；迁移时在副本删除该项目 `build/install/log` 后重新构建。
