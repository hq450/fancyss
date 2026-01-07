### V2RAY 二进制存放
***
##### 由于路由器jffs空间有限，此处存放经过UPX压缩的v2ray二进制，以节约空间
压缩命令：`upx --lzma --ultra-brute v2ray`

v2ray 从v4.21.0版本开始，[v2ray官方项目](https://github.com/v2ray/v2ray-core)release页面提供的二进制在博通BCM470X型号CPU上运行出现报错（如RT-AC68U,RT-AC88U等机型），因此从此版本后的v2ray二进制为本项目自编译后，经过upx压缩大小后在此处提供。



**note**：从v2ray v5版本开始，v2ray的运行命令有所变更，为了避免使用老版本插件的用户更新到v5版本的v2ray，老版本插件仍然使用`latest.txt`获取v2ray最新版本（V4），新版本用户使用`latest_v5.txt`获取v2ray最新版本



  - 新增 TRIM_MODE：
      - vmess_v4_min：仅支持 inbound: socks + dokodemo-door、outbound: vmess、传
        输 tcp/ws/grpc(gun)/quic/kcp/h2（含 tls）
      - vmess_v4_min_req：在 vmess_v4_min 基础上，额外支持 meek/mekya（走 v5 风格
        的 streamSettings.transport + transportSettings；体积只多一点点）
  - 构建与体积对比（v5.42.0，UPX 后）：
      - 默认 v5.42.0：arm64 6,147,600 / armv7 6,053,136 / armv5 6,062,800
      - 旧 vmess_only：arm64 5,422,280 / armv7 5,339,820 / armv5 5,347,772
      - 新 vmess_v4_min：arm64 4,140,468 / armv7 4,085,632 / armv5 4,093,964
      - 新 vmess_v4_min_req：arm64 4,210,800 / armv7 4,151,864 / armv5 4,157,828
  - 已生成输出目录：
      - binaries/v2ray/v5.42.0_vmess_v4_min/
      - binaries/v2ray/v5.42.0_vmess_v4_min_req/

  使用示例：

  - TRIM_MODE=vmess_v4_min V2RAY_TAG=v5.42.0 ./binaries/v2ray/make_latest.sh
  - TRIM_MODE=vmess_v4_min_req V2RAY_TAG=v5.42.0 ./binaries/v2ray/make_latest.sh

  备注：vmess_only 我顺手补上了缺失的 socks inbound 注册，但它仍然只带最少传输
  （不保证你启用 kcp/quic/grpc/h2 时可用）；建议直接用 vmess_v4_min(_req)。
