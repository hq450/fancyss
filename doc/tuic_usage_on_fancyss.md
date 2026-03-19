# fancyss 3.5.5+ 下的 TUIC 使用指南

本文适用于：

- `fancyss 3.5.5` 及以上版本
- `tuic-client 1.7.1` 及以上版本
- 其它支持tuic协议的服务器端如singbox等仅供参考
- 服务端使用 `Itsusinn/tuic` 分支的 `tuic-server 1.7.1` 及以上版本

不适用于：

- `fancyss 3.5.4` 及以下版本
- 老的 `tuic 1.0.0` 配置格式

`fancyss 3.5.5+` 已按 `tuic 1.7.1+` 的配置格式适配，旧版 TUIC 示例不能直接套用。

## 一、先说结论

在 `fancyss 3.5.5+` 中使用 TUIC，最重要的几点是：

1. 服务端和客户端的 `alpn` 必须一致，推荐都使用 `["h3"]`
2. 如果服务端使用真实证书，服务端必须设置 `self_sign: false`
3. 如果服务端使用自签证书，客户端必须额外加 `skip_cert_verify: true`，否则会报证书不受信任
4. 客户端建议始终使用：
   - `relay.server` 填域名和端口
   - `relay.ip` 单独填服务器 IP

推荐写法：

- `relay.server = "example.com:443"`
- `relay.ip = "1.2.3.4"`

这样做的原因是：

- `relay.server` 用于 SNI 和证书主机名匹配
- `relay.ip` 用于实际连接，避免路由器每次都重新解析服务器域名

## 二、fancyss 对 TUIC 节点的处理方式

在 fancyss 中，TUIC 节点最终写入运行文件 `/koolshare/ss/tuic.json`。

需要注意：

1. fancyss 实际只使用你自定义 JSON 里的 `relay` 字段
2. `local` 和 `log_level` 会由 fancyss 重写
3. 如果 `relay.ip` 没填，fancyss 会检查 `relay.server`
   - 如果 `relay.server` 本身就是 IP，则直接使用这个 IP
   - 如果 `relay.server` 是域名，则会尝试解析后写入 `relay.ip`

所以在 fancyss 节点里，真正需要你关心的是 `relay`。

## 三、服务端配置：使用真实证书

这是推荐方案。

适用场景：

- 你已经有域名
- 你已经签发了有效证书（比如 Let's Encrypt）
- 希望客户端正常校验证书

### 1. 服务端示例

文件：`/root/tuic.json`

```json5
{
  log_level: "info",
  server: "[::]:443",
  users: {
    "00000000-0000-0000-0000-000000000000": "password"
  },
  tls: {
    self_sign: false,
    hostname: "example.com",
    certificate: "/path/to/cert/xxx.crt",
    private_key: "/path/to/cert/xxx.key",
    alpn: ["h3"]
  }
}
```

### 2. 关键说明

- `self_sign` 必须是 `false`
  - 如果写成 `true`，`tuic-server 1.7.1` 会直接生成自签证书
  - 你填写的 `certificate` 和 `private_key` 不会按“指定证书模式”工作
- `hostname` 应与证书中的域名一致
- `alpn` 必须显式写 `["h3"]`
  - 如果服务端 `alpn = []`，而客户端写了 `["h3"]`
  - 会报错：
    - `peer doesn't support any known protocol`

### 3. 启动服务端

```bash
./tuic-server-x86_64-linux -c /root/tuic.json
```

## 四、客户端配置：对应真实证书服务端

这是 fancyss 节点里建议填写的内容。

```json
{
  "relay": {
    "server": "example.com:443",
    "uuid": "00000000-0000-0000-0000-000000000000",
    "password": "password",
    "ip": "1.2.3.4",
    "alpn": ["h3"],
    "congestion_control": "bbr"
  }
}
```

说明：

- `server` 建议填域名，不建议直接填 IP
- `ip` 建议同时填写服务器 IP
- `alpn` 建议显式填 `["h3"]`
- `skip_cert_verify` 在“真实证书”场景下不要开启

## 五、服务端配置：使用自签证书

适用场景：

- 临时测试
- 不想申请公开证书
- 纯内网或实验环境

### 1. 服务端示例

```json5
{
  log_level: "info",
  server: "[::]:443",
  users: {
    "00000000-0000-0000-0000-000000000000": "password"
  },
  tls: {
    self_sign: true,
    hostname: "example.com",
    alpn: ["h3"]
  }
}
```

### 2. 关键说明

- `self_sign: true` 表示由服务端自动生成自签证书
- 此时证书不是公开 CA 签发，客户端默认不会信任
- 所以客户端如果不额外处理，会报：
  - `invalid peer certificate: UnknownIssuer`

## 六、客户端配置：对应自签证书服务端

### 1. 推荐测试写法

```json
{
  "relay": {
    "server": "example.com:443",
    "uuid": "00000000-0000-0000-0000-000000000000",
    "password": "password",
    "ip": "1.2.3.4",
    "alpn": ["h3"],
    "congestion_control": "bbr",
    "skip_cert_verify": true
  }
}
```

### 2. `skip_cert_verify: true` 的使用场景

这一项我已经实测验证过：

- 自签证书服务端
- `alpn = ["h3"]`
- 客户端不加 `skip_cert_verify`
  - 握手失败
  - 错误为：
    - `invalid peer certificate: UnknownIssuer`
- 客户端加 `skip_cert_verify: true`
  - 握手成功
  - 可正常通过本地 socks5 访问外网

因此：

- `skip_cert_verify: true` 只建议用于：
  - 自签证书
  - 临时测试
  - 你明确知道自己在跳过证书校验
- 如果服务端使用真实证书，不建议开启它

### 3. 注意

`skip_cert_verify: true` 只能跳过“证书校验”问题，不能解决下面这些错误：

- 服务端和客户端 `alpn` 不一致
- `uuid` / `password` 错误
- 服务端端口、防火墙、UDP 未放行
- `server` / `ip` / `hostname` 配置错误

例如：

- 服务端 `alpn = []`
- 客户端 `alpn = ["h3"]`

此时即使加了 `skip_cert_verify: true`，依然会因为 ALPN 不匹配而握手失败。

## 七、推荐的节点填写方式

### 推荐方案 A：真实证书

服务端：

- `self_sign: false`
- `certificate` / `private_key` 正确
- `alpn: ["h3"]`

客户端：

```json
{
  "relay": {
    "server": "你的域名:端口",
    "uuid": "你的UUID",
    "password": "你的密码",
    "ip": "服务器IP",
    "alpn": ["h3"],
    "congestion_control": "bbr"
  }
}
```

### 推荐方案 B：自签证书测试

服务端：

- `self_sign: true`
- `alpn: ["h3"]`

客户端：

```json
{
  "relay": {
    "server": "你的域名:端口",
    "uuid": "你的UUID",
    "password": "你的密码",
    "ip": "服务器IP",
    "alpn": ["h3"],
    "congestion_control": "bbr",
    "skip_cert_verify": true
  }
}
```

## 八、常见错误与排查

### 1. `peer doesn't support any known protocol`

通常是 `ALPN` 不匹配。

检查：

- 服务端 `tls.alpn`
- 客户端 `relay.alpn`

建议统一为：

```json
["h3"]
```

### 2. `invalid peer certificate: UnknownIssuer`

通常是：

- 服务端使用了自签证书
- 客户端没有加 `skip_cert_verify: true`

### 3. 节点能启动，但无法联网

检查：

1. VPS 防火墙是否放行对应 UDP 端口
2. 服务端是否真的在监听 UDP
3. `relay.ip` 是否正确
4. `uuid` 和 `password` 是否与服务端一致

## 九、fancyss 3.5.5+ 的 TUIC 使用建议

1. 使用 TUIC 1.7.1+ 时，不要再沿用 TUIC 1.0.0 的旧示例
2. 优先使用真实证书，`self_sign: false`
3. 服务端和客户端都显式写 `alpn: ["h3"]`
4. 节点里始终建议同时写：
   - `relay.server`
   - `relay.ip`
5. 只有在自签证书测试时才建议开启：
   - `skip_cert_verify: true`

## 十、一个已验证通过的真实证书示例

服务端：

```json5
{
  log_level: "info",
  server: "[::]:443",
  users: {
    "00000000-0000-0000-0000-000000000000": "password"
  },
  tls: {
    self_sign: false,
    hostname: "example.com",
    certificate: "/path/to/cert/xxx.crt",
    private_key: "/path/to/cert/xxx.key",
    alpn: ["h3"]
  }
}
```

fancyss 节点：

```json
{
  "relay": {
    "server": "example.com:443",
    "uuid": "00000000-0000-0000-0000-000000000000",
    "password": "password",
    "ip": "1.2.3.4",
    "alpn": ["h3"],
    "congestion_control": "bbr"
  }
}
```

这个组合已经实测可在 fancyss 中正常工作。
