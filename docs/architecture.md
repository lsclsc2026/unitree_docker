# 环境架构

```mermaid
flowchart TB
  image[ROS Humble 环境镜像] --> container[独立开发容器]
  workspace[宿主机同级工作区] -->|可写 bind mount| container
  sdk[固定提交 SDK / 消息 / A2 模型] --> workspace
  repos[导航 / 音频 / 鸭子采集源码] --> workspace
  data[宿主机 maps / logs / rosbags] -->|可写 bind mount| container
  container --> env[ROS 环境 + 已构建工作区 overlay]
  env --> move[导航与相机进程]
  env --> audio[ROS 音频桥接 + 原生 SDK 后端]
  env --> capture[Python 数据采集]
  move -. 显式 host 网络 .-> robot[A2 Pro]
  audio -. 显式 host 网络 .-> robot
  capture -. 数据导出 .-> cloud[独立云端推理环境]
```

镜像负责系统依赖；SDK、消息与 A2 模型用 Git 提交锁定，SDK 静态库另有二进制哈希校验；业务源码由各自 Git 仓库管理。容器入口只加载环境和执行传入命令，不自动启动 ROS 节点。默认 launcher 主进程为空闲等待，因此容器运行不代表导航、定位或音频功能已经启动。

`env.sh` 顺序加载 ROS Humble、导航 `install/local_setup.bash`、音频 `install/local_setup.bash`。首次构建前 overlay 不存在也可进入。构建后再次 source 环境以获得新包。鸭子云端 GPU 模型不是该 ROS 镜像的组成部分。
