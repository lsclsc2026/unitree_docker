# Unitree Docker 共用开发环境

**Portable ROS 2 Humble development environment for Unitree A2 Pro.**

为 A2 Pro 的室内导航、语音播报和机器人端鸭子数据采集提供 Ubuntu 22.04 / ROS 2 Humble 环境、固定版本 SDK 获取脚本和可配置容器入口。三个项目是同级工作区，构建产物和采集数据保存在宿主机。

这是私有审阅首版。环境材料已重新整理；当前运行环境与本仓库干净构建的验证范围见 [验证记录](docs/validation.md)。不把旧镜像可运行等同于新 Dockerfile 已完成重建。

| 配套项目 | 功能 |
|---|---|
| [u_robot_move](https://github.com/lsclsc2026/u_robot_move) | 建图、定位、Nav2、多点巡逻、Foxglove 与相机 |
| [u_robot_audio](https://github.com/lsclsc2026/u_robot_audio) | 原生 TTS 后端、ROS 2 播报和状态 |
| [u_robot_duck_dataset](https://github.com/lsclsc2026/u_robot_duck_dataset) | 相机采集、抽帧、数据校验和云端检测研究 |

## 快速开始

前提：Linux Docker Engine 已可使用，Git 已配置私有仓库访问权限。以下步骤只构建环境，不启动导航、运动或播报节点。

```bash
mkdir -p "$HOME/unitree-workspace"
cd "$HOME/unitree-workspace"
for repo in unitree_docker u_robot_move u_robot_audio u_robot_duck_dataset; do
  git clone "https://github.com/lsclsc2026/$repo.git"
done
cd unitree_docker
./scripts/fetch-sdk.sh
./build.sh --dry-run
./build.sh --execute
./unitree run --dry-run
./unitree run
./unitree shell
```

在容器中检查并构建：

```bash
cd "$UNITREE_PROJECT_ROOT"
bash unitree_docker/scripts/check-env.sh
bash u_robot_move/scripts/build.sh
bash u_robot_audio/scripts/build.sh
source /etc/unitree/env.sh
exit
```

鸭子采集项目的机器人端 Python 工具直接使用该环境；Grounding DINO 云端依赖、模型与 GPU 环境按它自己的文档单独准备。默认获取三个必需依赖：SDK2、ROS2 消息与 `unitree_ros` 的 A2 模型；只有 Python SDK 可选。下载 SDK 需要网络，默认离线容器中的工作区构建不执行 apt/pip 下载。

## 文档

- [安装、目录布局与构建](docs/installation.md)
- [容器管理、挂载与数据](docs/operations.md)
- [网络、DDS 与可视化](docs/networking.md)
- [SDK 获取、版本与音频兼容性](docs/sdk.md)
- [环境架构](docs/architecture.md)
- [检查、验证与升级](docs/validation.md)
- [故障排查](docs/troubleshooting.md)
- [来源与版本记录](docs/provenance.md)
- [第三方依赖说明](THIRD_PARTY.md)

默认镜像名 `unitree-dev:humble-review`，容器名 `unitree-review`，不会复用旧 `unitree-dev`。原创部分未授予开源许可证；第三方组件按各自许可证使用。
