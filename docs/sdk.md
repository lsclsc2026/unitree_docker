# SDK、固定版本与设备兼容性

## 获取方式

```bash
./scripts/fetch-sdk.sh
# 可选：额外下载 Python SDK
./scripts/fetch-sdk.sh --all
# 自定义完整工作区的 sdk 路径
./scripts/fetch-sdk.sh --dest /absolute/workspace/sdk
```

脚本读取 [sdk.lock.tsv](../sdk.lock.tsv)，按提交 SHA 下载并 detached checkout。已存在目录必须为同一提交且没有本地修改，否则直接报错，不覆盖设备副本。最后校验 [sdk-binaries.sha256](../sdk-binaries.sha256)。默认下载 `unitree_sdk2`、`unitree_ros2` 和 `unitree_ros` 三个必需依赖。`unitree_ros` 虽是 ROS 1 上游仓库，但导航的 `u_robot_description` 需要其中的 A2 URDF、网格及根 LICENSE；不启动其 ROS 1 节点。只有 Python SDK 不参与基础 colcon 构建，需 `--all` 才下载。

| 依赖 | 固定提交 | 用途 |
|---|---|---|
| [unitree_sdk2](https://github.com/unitreerobotics/unitree_sdk2) | `9754cd153af3da471b0fe5f3aa535e426fb11db3` | A2 sport/audio 头文件、架构静态库及其 native DDS |
| [unitree_ros2](https://github.com/unitreerobotics/unitree_ros2) | `668d1ec5a05d1c38d3306bdca7d59f2ba3581a88` | 导航构建的 Unitree 消息 |
| [unitree_sdk2_python](https://github.com/unitreerobotics/unitree_sdk2_python) | `65691c8a8bc53b98d3976dba4dbf9d5d20b2e7f5` | 可选 Python 设备实验 |
| [unitree_ros](https://github.com/unitreerobotics/unitree_ros) | `daadf41ee9afce8f90fdc09a98506012691fa122` | 导航必需的 A2 URDF、网格与许可证（不运行 ROS 1） |

2026-09-13 检查：三个共享 SDK 的宿主机/运行容器提交一致且 `git status --short` 无修改；ROS 1 仓库仅在宿主机核实。四个提交均通过 GitHub API 查询成功。核心库的宿主机与容器哈希一致。发布集成修正后，从空目录完整下载三个必需依赖，三个 HEAD 与锁文件一致且工作树干净；两架构静态库再次通过 SHA256 校验，A2 URDF 的 17 个网格引用全部存在，根 LICENSE 完整。

## 音频的“设备新版 SDK”具体指什么

当前音频后端需要 A2 `audio_client.hpp`，并直接链接工作区中的 `lib/<架构>/libunitree_sdk2.a`。这里锁定的提交已包含 A2 音频头文件和相应库，因此本次没有发现必须额外复制的私有音频 SDK 补丁。它不能被未经核对的旧全局 SDK 或随意选择的上游最新版替换。导航的 CMake 也可能优先查找 `/opt/unitree_robotics` 的全局安装；本 Dockerfile 不安装该全局版本，使同级 SDK 成为默认来源。

库 SHA256：

```text
x86_64  08402aea74150dfbfc3fbfded4ca746916a8d892b54d2bade0cbf392a3be4029
aarch64 a084cc0087b6dc1b6361f874aabed8bd525f0574b3b2228f91b4b512e1bf035e
```

SDK CMake 导入上游预编译静态库；这个仓库并没有该库完整实现源码，“构建 SDK”不代表能从 C++ 源码重新生成库。公开上游提供这些文件，因此不另建私有依赖包。机器人固件、音频服务支持和实际发声仍需设备验证，编译成功不能证明所有设备兼容。

## 可选 Python SDK

基础 ROS 导航、音频原生后端和鸭子工具不要求全局安装 Python SDK。固定版本的上游 `setup.py` 要求 `cyclonedds==0.10.2`、numpy 和 opencv-python；不能把它的 pip 安装混入系统 ROS Python 环境。确需 SDK Python 实验时，在独立 venv 中按照该固定提交的 README 准备匹配的 CycloneDDS，单独记录 Python/native 库版本。本仓库只提供下载，不宣称此可选环境已完成安装或测试。

下载树内保留上游 `LICENSE` 和 `licenses/`；如果转移离线 SDK 文件，也应一起携带许可与版本记录。许可清单见 [第三方说明](../THIRD_PARTY.md)。
