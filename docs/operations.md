# 容器与数据管理

## 命令

所有入口在本仓库执行。无参数只输出帮助；任何操作都可先加 `--dry-run`，不会访问 Docker socket 或创建数据目录。

| 命令 | 行为 |
|---|---|
| `./unitree run` | 新建并运行独立容器，默认 `--network none`，主进程仅 `sleep infinity` |
| `./unitree shell` | 进入正在运行的容器并加载 ROS/已构建工作区 |
| `./unitree status` | 检查容器运行状态、镜像、网络 |
| `./unitree logs` | 输出容器主进程最近 100 行；节点日志通常写入挂载目录 |
| `./unitree stop` | 停止容器 |
| `./unitree start` | 按原有配置启动已停止的容器 |
| `./unitree remove` | 删除已停止容器；运行中容器由 Docker 拒绝删除 |

`exit` 只离开 shell。运行机器人节点期间应先使用各项目规定的停止方式，再停止容器。入口不会自动重启容器或恢复业务节点。进入、停止、启动和删除只接受带本脚本管理标签的容器，防止误操作旧环境。重名容器不会覆盖；新参数不会被默默套用到已存在容器。

## 配置变量

| 变量 | 宿主机默认值 / 意义 |
|---|---|
| `UNITREE_IMAGE` | `unitree-dev:humble-review` |
| `UNITREE_CONTAINER` | `unitree-review` |
| `UNITREE_PROJECT_ROOT` | 本仓库父目录，挂载整个同级工作区 |
| `UNITREE_DATA_ROOT` | `$UNITREE_PROJECT_ROOT/data` |
| `ROS_DOMAIN_ID` | `0`；与机器人对应配置一致 |
| `UNITREE_NETWORK_INTERFACE` | 空；host 网络时必须提供它或 `--interface` |
| `CYCLONEDDS_URI` | 可选自定义 XML / 容器内可读文件 URI |

变量通过命令行 `export` 设置，脚本不自动读取 `.env`。挂载绝对路径不能包含逗号（Docker `--mount` 分隔符）；含空格路径受支持。

默认可写挂载：整个工作区到 `/home/unitree/unitree_robot_development`，数据到 `/home/unitree/data`。创建时准备 `maps/logs/rosbags`。具体节点保存路径由项目配置决定，必须指向持久化目录才能保留数据；没有自动把任意路径的数据搬入挂载。不要把数据、build、install、log、模型权重提交进 Git。

## 升级与迁移

保持旧容器不变，用新 `UNITREE_IMAGE` 构建环境，用新 `UNITREE_CONTAINER` 创建验证容器。验证副本应使用独立工作区和独立数据根目录，避免两个容器同时改写构建目录或日志。通过 `status` 核对镜像、网络后再运行项目自身操作流程。`start` 保留旧配置；修改镜像、网络、挂载或 UID/GID 需要新建容器。

备份宿主机项目源码、地图、配置与采集数据即可，不依赖导出运行容器。镜像不会自动发布到 GHCR；若以后分发镜像，须另外检查镜像中不包含私有数据，并记录 digest 和依赖许可。
