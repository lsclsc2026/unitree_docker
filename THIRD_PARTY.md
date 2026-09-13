# 第三方依赖与使用边界

本项目原创脚本与文档目前未授予开源许可证；私有仓库审阅不等同于开源许可。以下说明保留第三方来源，不更改其许可。

| 组件 | 来源与许可记录 | 处理方式 |
|---|---|---|
| Unitree C++ SDK2 | `unitreerobotics/unitree_sdk2` 固定提交，根 LICENSE 为 BSD-3-Clause | 脚本下载完整上游树；静态库与头文件不再复制到本仓库 |
| Unitree ROS2 消息 | `unitreerobotics/unitree_ros2` 固定提交，根 LICENSE 为 BSD-3-Clause | 导航构建从共享 SDK 树引用消息包 |
| Unitree A2 模型（unitree_ros） | `unitreerobotics/unitree_ros` 固定提交，根 LICENSE 为 BSD-3-Clause | 默认下载；导航安装其中的 A2 URDF、网格与根 LICENSE |
| 可选 Unitree Python SDK | 对应上游固定提交，根 LICENSE 为 BSD-3-Clause | 仅 `fetch-sdk.sh --all` 额外下载 |
| SDK 捆绑依赖 | 上游 `licenses/Tencent/rapidjson`、`licenses/eclipse-cyclonedds/{cyclonedds,cyclonedds-cxx}`、`licenses/eclipse-iceoryx/iceoryx`，及 `thirdparty/include/ddscxx/dds/LICENSE` | 保留上游各组件许可；不要仅用 SDK 根 BSD 许可概括所有内含组件 |
| ROS 2 / Ubuntu / Nav2 / OpenCV / FFmpeg / GStreamer 等 | 官方镜像及 apt 软件包，组件许可各异 | 构建后查阅 `/usr/share/doc/<package>/copyright` 和镜像包清单 |

SDK 获取与精确提交见 [SDK 文档](docs/sdk.md)。上游预编译库是第三方交付物；本仓库没有重新生成其内部实现。向他人分发镜像或离线 SDK 时需要连同组件 notices/许可证一起保留。本文记录现有来源，不作原创代码开源授权。
