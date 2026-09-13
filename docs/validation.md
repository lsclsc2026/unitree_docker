# 验证记录与升级基线

日期：2026-09-13。验证过程不启动导航、运动、音频或机器人数据采集。

## 已完成

| 检查 | 方法 | 结果 |
|---|---|---|
| Shell 语法 | `bash -n` 检查 unitree、build.sh、docker/*.sh、scripts/*.sh | 6 个入口通过 |
| 入口行为 | `python3 -m unittest discover -s tests -v` | 12 项通过；10 项入口测试与 2 项 SDK 获取选择测试均使用模拟外部命令，不接触真实容器 |
| 默认及预览副作用 | 测试帮助、各操作 `--dry-run` | 不调用 Docker、不创建数据目录 |
| 容器保护 | 测试已有容器、外部容器标签、非 force 删除 | 均按预期拒绝或构造命令 |
| 网络配置 | 测试默认 none、显式 host/interface 与非法接口 | 默认离线；host 要求接口 |
| SDK 来源 | 宿主机/运行容器只读 Git 状态、GitHub API commit 查询 | 共享提交一致且干净；4 个上游固定提交均返回成功 |
| SDK 全新获取 | 从空目录实际运行默认获取脚本 | SDK2、ROS2 消息、A2 模型三个固定提交下载成功，工作树干净；Python SDK 未下载 |
| SDK 库与模型校验 | 宿主机/容器/全新下载 SHA256 对照；解析 A2 URDF | 两架构静态库哈希一致；A2 URDF、根 LICENSE 与 17 个网格文件完整 |

最初复用分支检查后，集成复核发现 A2 模型仓库也为必需依赖，已将默认获取范围补齐为 `unitree_sdk2/unitree_ros2/unitree_ros`，并添加先失败后通过的依赖选择回归测试。随后在空目录实际下载三个固定提交成功，未改写原 SDK。`--all` 的可选 Python SDK 分支由本地模拟测试覆盖，未另外完整下载。

## 尚未验证

全新 Dockerfile 从基础镜像完成 apt 安装、完整构建并运行环境检查，仍需独立镜像验证。已有设备容器的可运行状态不证明本仓库新镜像已构建。aarch64 完整业务构建、X11/Wayland、USB/GPU/实时权限、跨设备固件兼容和新的实机运行均未在 Docker 整理任务中验证。配套业务仓库的独立构建/测试结果分别记录在各自验证文档。

## 重复静态检查

```bash
bash -n unitree build.sh docker/env.sh docker/entrypoint.sh scripts/fetch-sdk.sh scripts/check-env.sh
python3 -m unittest discover -s tests -v
./build.sh --dry-run
./unitree run --dry-run
./unitree run --network host --interface enp3s0 --dry-run
```

测试使用临时目录和假 Docker 可执行文件。不会创建真实 host 网络容器，也不会执行 Docker stop/remove。

## 独立镜像验证步骤

以下由需要验证环境的开发者显式执行。使用新镜像标签、新容器名及独立工作区，不复用当前设备运行目录：

```bash
export UNITREE_IMAGE=unitree-dev:humble-review-validation
export UNITREE_CONTAINER=unitree-review-validation
# UNITREE_PROJECT_ROOT 指向按 installation.md 准备的独立完整工作区
./build.sh --execute
./unitree run
./unitree shell
# 容器内，只做环境检查与编译
bash "$UNITREE_PROJECT_ROOT/unitree_docker/scripts/check-env.sh"
bash "$UNITREE_PROJECT_ROOT/u_robot_move/scripts/build.sh"
bash "$UNITREE_PROJECT_ROOT/u_robot_audio/scripts/build.sh"
cat /usr/local/share/unitree-image-packages.txt
exit
# 宿主机
./unitree stop
./unitree remove
```

环境检查只检查命令、Python 导入、已安装包索引和 SDK 文件，不执行 ROS 图发现。业务测试按各仓库文档运行，涉及控制硬件的探针不属于离线验收。

记录完整构建日志、基础镜像 digest、最终镜像 ID、镜像包清单、三个业务仓库提交和 SDK 提交。成功后更新本记录再标记“干净镜像已验证”；修改基础镜像、SDK、ROS 依赖或硬件接口后重新执行受影响的检查。
