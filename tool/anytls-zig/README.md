# anytls-zig

`anytls-zig` 是面向 fancyss full 版本的 AnyTLS 客户端实验实现。

当前目标：

- 提供本地 SOCKS5 入站；
- 连接远端 AnyTLS 服务端；
- 支持 `anytls://password@host:port/?sni=name&insecure=1` URI；
- 用 Zig 0.15.2 生成小体积多平台二进制。

当前限制：

- 仅支持 TCP 代理，不支持 UDP/UoT；
- 每个 SOCKS5 连接独立建立 AnyTLS session，尚未实现官方要求的 session 复用；
- 默认 `--insecure` 关闭 CA 校验以兼容现有订阅节点；受 Zig TLS API 限制，带 SNI 时仍可能触发主机名校验，遇到证书主机名不匹配会自动退回不发送 SNI 重连；可用 `--verify` 启用系统 CA 校验和严格主机名校验；
- 会解析但暂不应用服务端下发的 padding scheme 更新。

常用命令：

```sh
anytls-zig --server-uri-file /tmp/anytls.uri -l 127.0.0.1:18081
curl -x socks5h://127.0.0.1:18081 http://www.google.com/generate_204
```
