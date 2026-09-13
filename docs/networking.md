# 网络、DDS 与显示

## 默认离线

`./unitree run` 使用 `--network none` 与 `ROS_LOCALHOST_ONLY=1`，用于源码编译和不访问设备的检查。默认不授予 privileged、不共享宿主机 IPC、不暴露设备、不启用自动重启。不要在这个模式中执行联网下载；SDK 在宿主机预先准备。

## 机器人网络

在现场核对实际接口名与地址，保持设备厂商的网络配置。以下仅创建空闲开发容器，不启动任何控制节点：

```bash
ip -brief address
# 以实际连接机器人的接口替换 enp3s0
UNITREE_CONTAINER=unitree-review-robot ./unitree run --network host --interface enp3s0 --dry-run
UNITREE_CONTAINER=unitree-review-robot ./unitree run --network host --interface enp3s0
UNITREE_CONTAINER=unitree-review-robot ./unitree shell
```

host 模式将 `ROS_LOCALHOST_ONLY` 设为 `0`；`UNITREE_NETWORK_INTERFACE` 被转换为 CycloneDDS XML，除非已提供 `CYCLONEDDS_URI`。显式 URI 的文件路径必须在容器内存在，例如挂载工作区中的 XML。SDK 原生后端的 `network_interface` 参数仍由各项目 launch/参数文件配置；设置 ROS DDS 接口不会自动改写所有后端参数。

Linux host 模式共享宿主机网络命名空间，端口映射 `-p` 不生效。Foxglove 或数据浏览器监听的端口直接属于宿主机，应按项目配置检查端口和访问来源。见 [Docker host 网络文档](https://docs.docker.com/engine/network/drivers/host/)。多网卡、VPN、无线隔离和交换机组播策略会影响发现；先核对网卡，再按项目文档检查 DDS，避免为了发现问题随意混装另一套中间件。

## ROS 与 SDK DDS

ROS 2 使用 apt 安装的 `rmw_cyclonedds_cpp`。SDK 的 native 后端携带其匹配的 `libddsc/libddscxx`，由各项目独立后端启动环境处理。`docker/env.sh` 不把 SDK `thirdparty/lib` 加入全局 `LD_LIBRARY_PATH`，不加载旧 `cyclonedds_ws/install`，避免 ROS 2 与 SDK ABI 混用。

## 可选本地图形界面

Foxglove 可用远端浏览器连接，无需 X11。确需 RViz 时，在 Linux X11 主机上通过 `./unitree run --x11` 显式挂载 X11 socket，并传入现有 `DISPLAY`；网络参数可按需要同时设置。脚本不运行 `xhost +`，不设置全局 X11 访问权限。宿主机必须已允许对应 UID 使用显示服务；如果鉴权失败，按本机显示会话规则设置最小访问权限。Wayland、GPU 设备、USB/串口和实时优先级未在该入口中默认开启，需要另行适配和验证。
