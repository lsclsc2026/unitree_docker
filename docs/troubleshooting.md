# 故障排查

| 现象 | 核对与处理 |
|---|---|
| Docker permission denied | 先确认宿主机 Docker Engine 的账号访问权限；脚本不会替你改组或 socket 权限 |
| 构建拉取基础镜像失败 | 核对官方镜像网络；通过 `UNITREE_BASE_IMAGE` 指定可访问镜像或 digest，再用新标签构建 |
| apt 找不到包/版本漂移 | 保存完整构建错误与基础镜像 digest；本仓库 apt 包未逐项锁版本，不把旧容器版本清单直接当可下载锁文件 |
| `fetch-sdk.sh` 拒绝目录 | 在新工作区下载，或先独立检查已有目录提交/修改；脚本不会 reset 或覆盖设备 SDK |
| `unitree_api` 找不到 | `sdk/unitree_ros2` 必须与项目同级，使用导航仓库 `scripts/build.sh` 同时编译消息 |
| A2 URDF 或 mesh 找不到 | 默认获取脚本必须完整准备 `sdk/unitree_ros/robots/a2_description` 与 `unitree_ros/LICENSE`；只下载 SDK2 和 ROS2 消息不足以构建导航模型包 |
| `audio_client.hpp` 或音频符号缺失 | 核对 SDK 固定提交和库哈希，排除旧 `/opt/unitree_robotics` 安装与错误架构库 |
| `libddsc` / `libddscxx` ABI 或符号问题 | 检查项目 native 后端启动环境；取消全局 SDK DDS 路径污染，不加载旧 CycloneDDS overlay |
| DDS 看不到机器人 | 默认 `none` 模式是离线环境；新建显式 host 网络容器，核对接口、ROS_DOMAIN_ID 和项目后端参数 |
| 新网络/挂载参数没有应用 | 配置只在创建时生效；脚本遇到同名容器会拒绝，使用新容器名，`start` 不更新配置 |
| `shell` 报容器未运行 | 先 `status`，若为本脚本已停止容器，执行 `start` 后再进入 |
| build/install 文件无写权限 | 镜像 UID/GID 应与宿主机项目文件拥有者一致；不要用 root 执行 `build.sh` |
| 容器删除后数据丢失 | 节点输出可能落在非挂载路径；将项目的数据目录指向 `/home/unitree/data` 并核对宿主机文件 |
| RViz cannot open display | 检查 `DISPLAY`、显式 `--x11`、会话鉴权；优先使用 Foxglove 远端浏览器 |
| 鸭子云端推理缺少 torch/模型 | 按数据仓库 cloud 文档准备独立 GPU 环境；ROS 开发镜像不包含模型权重 |

排查环境先执行 `scripts/check-env.sh`。它不发现 ROS 图、不向机器人发命令。需要业务接口、停止动作或实机检查时使用对应项目的正式操作文档。
