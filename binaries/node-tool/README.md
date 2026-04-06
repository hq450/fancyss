# node-tool binaries

`node-tool` 的发布二进制来源于：

- `tool/node-tool`

当前用途：

- 为 `fancyss` 的本地节点库操作提供轻量级结构化 CLI
- 服务订阅脚本中的 schema2 节点导出、删除、写入
- 服务节点缓存预热与计划生成

发布约定：

- 由 `tool/node-tool/scripts/build-release.sh` 统一生成
- 默认启用 `UPX`
- `armv5te` 使用 `UPX 4.2.4`
- 其它目标使用 `UPX 5.0.2`

打包链路：

- `build.sh` 会将本目录下的 `node-tool-v<ver>-linux-*` 同步到各平台 `bin-*`
- 路由器导出包会在检测到 `/koolshare/bin/node-tool` 时将其一起打包
