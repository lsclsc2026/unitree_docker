# 来源与版本记录

## 2026-09-13 私有审阅首版

来源：现有 Docker 项目的 `Dockerfile/build.sh/docker/*.sh`、宿主机 `unitree` 入口、运行环境的只读检查，以及三个配套仓库的实际依赖声明。发布目录单独创建，原目录和运行容器保持原状。

旧 `build.sh` 收集过 `graph_pid_ws/slam_config/a2_nav2/slam_command/arm_remote/src` 等历史目录，根 Dockerfile 与 context 副本也存在差异。新版采用唯一根 Dockerfile、构建上下文白名单、同级源码挂载、独立 SDK 下载和持久化数据。旧 payload、build/install、运行日志、模型和数据未复制进本仓库。集成复核发现导航模型包同时需要上游 `unitree_ros` 的 A2 URDF/网格，已纳入默认固定提交获取范围；只有 Python SDK 保持可选。随后从空目录验证三个必需上游仓库下载及模型文件完整性。

旧 launcher 默认 privileged/host IPC/host network，并可能复用已有容器。新版使用独立默认名称、管理标签、显式 host 网络、默认离线和非特权运行。原有主机上的运行容器曾存在源码未挂载的情况，不能用当前宿主机源码自动推断其运行内容；检查时运行容器与当前同名镜像 tag 也存在历史差异，tag 名称不足以确定源码或镜像身份。

## 版本证据

SDK 完整提交写入 `sdk.lock.tsv`，架构库 SHA256 写入 `sdk-binaries.sha256`。实际新环境 apt 版本由 Dockerfile 写入 `/usr/local/share/unitree-image-packages.txt`。配套业务仓库的最终首版提交由各自 Git 历史确认；发布后记录所有仓库 SHA、SDK SHA、镜像 ID/digest、包清单，作为下一次升级比较基线。

本仓库不附原始机器容器镜像，也不以重建/修改现有容器来证明可复现。详见 [验证记录](validation.md)。
