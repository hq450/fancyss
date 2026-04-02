# 节点服务器域名动态解析实施方案

## 背景

fancyss 目前对节点服务器地址长期采用“启动前预解析”的方式：

1. 插件启动前，使用 `ss_basic_server_resolv` 指定的 DNS 将节点服务器域名解析为 IP。
2. 将解析出的 IP 写入 Xray / Naive / Tuic / Hysteria2 等客户端配置。
3. 运行期间客户端不会再使用域名重新解析服务器地址。

该方案可以规避“代理尚未建立，节点域名却被 DNS 分流到代理侧解析”的鸡蛋问题，但会带来两个副作用：

- 机场调整节点域名解析后，插件仍连接旧 IP，节点会进入失效窗口。
- 只能依赖“定时重启插件”或“定时检查节点 IP 变化后重启”来恢复。

目标是增加“动态解析”模式，使客户端配置直接保留域名，并通过 chinadns-ng / smartdns 的直连解析规则，保证节点服务器域名始终走直连 DNS 解析，从而支持运行期自动更新解析结果。

## 目标

新增节点服务器解析方式：

1. `动态解析`
2. `预解析`

要求：

- `动态解析`：
  - 客户端配置文件中保留域名。
  - 当前节点服务器域名必须被注入到 chinadns-ng / smartdns 的“直连解析规则”中。
  - 运行中客户端可自行重新解析域名。
- `预解析`：
  - 保持现有行为。
  - 仍可选择 `节点域名解析DNS方案`。

## 现状梳理

### 1. 启动链路

当前启动顺序位于 `fancyss/ss/ssconfig.sh`：

1. `prepare_system`
2. `resolv_server_ip`
3. `create_dnsmasq_conf`
4. `add_white_black`
5. 生成代理核心配置
6. 启动代理核心
7. `restart_dnsmasq`
8. `start_dns_x`

这意味着当前 DNS 分流核心晚于代理核心启动。

### 2. server 相关变量现状

- `ss_basic_server`
  - 当前运行时使用的 server 容器。
  - 会根据节点类型被折叠为：
    - 普通协议：`server`
    - naive：`naive_server`
    - hy2：`hy2_server`
  - 在预解析后还会被覆盖成 IP。

- `ss_basic_server_orig`
  - 目前是为保留原始地址临时补出的兼容变量。
  - 不同协议路径下写入时机不一致。

- `ss_basic_server_ip`
  - 当前运行实例的解析结果。
  - 是全局 dbus 值。
  - 停插件时会清空。

- `server_ip`
  - schema 2 节点内的运行时字段。
  - 目前已定义为 runtime field，但启动链路没有统一使用。

### 3. 当前节点服务器来源不统一

不同协议的服务器地址来源不同：

- ss / ssr / vmess / vless / trojan：`server`
- naive：`naive_server`
- hy2：`hy2_server`
- vmess json / xray json：需从 json 的 `outbounds[0]` 提取
- tuic：需从 `tuic_json.relay.server` 提取 host

因此不能继续仅依赖 `ss_basic_server` 作为“原始 server”的唯一来源。

## 设计原则

1. 原始服务器地址与运行时配置地址分离。
2. 节点解析结果 IP 仅作为运行时缓存，不再混入原始节点配置语义。
3. 动态解析不借用 `white_list`，避免给普通业务域名带来路由副作用。
4. 节点服务器域名解析必须走“直连 DNS upstream”，但不能携带 `blacklist-ip` / `whitelist-ip` 等 CDN 判定副作用。
5. 尽量复用现有 chinadns-ng / smartdns 动态生成框架，避免引入新的静态模板。

## 数据模型

### 新增 dbus

- `ss_basic_server_resolv_mode`
  - `1`：动态解析
  - `2`：预解析

### 保留 dbus

- `ss_basic_server_resolv`
- `ss_basic_server_resolv_user`

仅在 `ss_basic_server_resolv_mode=2` 时参与运行。

### 运行时语义收敛

- `ss_basic_server_orig`
  - 始终表示“当前节点原始 server host”
  - 若原始值本身就是 IP，则该值就是 IP
  - 不再被预解析流程改写为其它值

- `ss_basic_server`
  - 始终表示“当前要写入客户端配置文件的 address/server”
  - 动态解析：写原始 host
  - 预解析：优先写预解析 IP，失败时回退写原始 host

- `ss_basic_server_ip`
  - 始终表示“当前运行期已知的解析结果 IP”
  - 可为空
  - 同步写入 schema 2 节点 runtime field：`server_ip`

## 前端改动

### 新增项

在 DNS 页面原“节点域名解析DNS方案”前增加一行：

- 标题：`节点服务器地址解析方式`
- 选项：
  - `1 动态解析`
  - `2 预解析`

### 交互规则

- 当选择 `动态解析`：
  - 隐藏 `ss_basic_server_resolv`
  - 隐藏 `ss_basic_server_resolv_user`
- 当选择 `预解析`：
  - 显示现有 `节点域名解析DNS方案`
  - 若选中 `99`，显示自定义 DNS 输入框

### 默认值

- 新安装默认：`动态解析`
- 升级用户若无该值，也默认写入 `动态解析`

## 后端改造

### 第一层：统一提取当前节点原始 server 元数据

新增统一函数，输出当前节点：

- `server_host`
- `server_port`
- `is_ip`
- `source_field`

支持以下来源：

- 普通节点字段
- naive 字段
- hy2 字段
- vmess json
- xray json
- tuic json

该函数只负责提取“原始 server”，不做解析，不改写配置。

### 第二层：统一初始化运行时 server 状态

新增统一流程：

1. 取得当前节点原始 `server_host`
2. 写入 `ss_basic_server_orig`
3. 默认令 `ss_basic_server=ss_basic_server_orig`
4. 清理旧的 `ss_basic_server_ip`
5. 若原始值本身是 IP：
   - `ss_basic_server_ip=该 IP`
   - schema 2 的 `server_ip=该 IP`

### 第三层：按模式决定是否预解析

#### 动态解析

- 若 `server_host` 是域名：
  - 不调用 `__resolve_server_domain`
  - 保持 `ss_basic_server=域名`
  - 仅在 DNS 核心启动后做一次非阻塞直连解析，更新 `ss_basic_server_ip/server_ip`

#### 预解析

- 若 `server_host` 是域名：
  - 调用 `__resolve_server_domain`
  - 成功：
    - `ss_basic_server=解析 IP`
    - `ss_basic_server_ip=解析 IP`
    - `server_ip=解析 IP`
  - 失败：
    - 配置文件回退写域名
    - 但日志明确提示当前仍处于兼容回退状态

## DNS 注入方案

### 1. 统一生成节点域名文件

新增运行时文件：

- `/tmp/ss_node_domains.txt`

内容规则：

- 动态解析 + 当前节点 server 为域名：写入该域名
- 其余情况：文件为空或不存在

### 2. smartdns

在运行时配置中新增：

- `domain-set -name node_direct -file /tmp/ss_node_domains.txt`
- `domain-rules /domain-set:node_direct/ -c none -n node_direct`

并新增专用 upstream group：

- group 名：`node_direct`
- upstream 来源：复用 chn 组 DNS 条目
- 但不附带：
  - `-blacklist-ip`
  - `-whitelist-ip`
  - `-proxy`

原因：

- 需要“直连解析”
- 但不应该对返回 IP 施加国内/国外优选限制

#### IPv6 处理

当 smartdns 策略中存在：

- `force-AAAA-SOA yes`

时，需要追加：

- `address /domain-set:node_direct/-6`

保证节点服务器域名不会被全局 AAAA 抑制误伤。

### 3. chinadns-ng

新增 group：

- `group node`
- `group-dnl /tmp/ss_node_domains.txt`
- `group-upstream ${CDNS_LINE}`

不配置：

- `group-ipset`

原因：

- 只需要保证解析直连
- 不希望影响业务流量路由

#### IPv6 处理

当前 `no-ipv6` 规则中，原有“全部过滤”使用了无条件 `no-ipv6`。

为了给 `node` 组留出豁免空间，需要改为显式 tag 组合，而不是无条件过滤：

- 过滤代理
- 过滤直连
- 过滤全部

都改成显式 tag 规则，唯独不包含 `tag:node`

这样节点服务器域名在动态解析模式下仍可返回 AAAA。

## 启动顺序调整

### 仅对“动态解析 + 当前节点 server 为域名”场景生效

新增 bootstrap 标志：

- 当前模式为动态解析
- 当前节点服务器是域名

满足时调整启动顺序：

1. `prepare_system`
2. 初始化当前节点 server 元数据
3. `create_dnsmasq_conf`
4. `add_white_black`
5. 生成代理核心配置
6. `restart_dnsmasq`
7. `start_dns_x`
8. 启动代理核心

原因：

- 先让 chinadns-ng / smartdns 的 `node_direct` 规则生效
- 再让客户端首次请求系统 DNS

### 其它场景

保留原顺序，降低回归风险。

## 各协议写配置策略

### 动态解析

- Xray/SS/Trojan/Hy2：写域名
- Naive：不再添加 `--host-resolver-rules=MAP`
- Tuic：不再写 `relay.ip`

### 预解析

- Xray/SS/Trojan/Hy2：优先写解析 IP
- Naive：继续使用 `--host-resolver-rules=MAP`
- Tuic：继续写 `relay.ip`

## 触发重启逻辑

`动态解析` 下：

- `ss_basic_tri_reboot_time` 不再需要检查节点 IP 变化
- 后端直接 no-op，并在日志说明当前模式无需该功能

`预解析` 下：

- 保持现有功能
- 后续可再收敛为直接读取当前节点 runtime `server_ip`，不再依赖 `/tmp/ss_host.conf`

## 实施顺序

1. 前端新增“动态解析 / 预解析”模式，并控制旧 resolver 选项显示
2. 后端新增统一的当前节点原始 server 提取函数
3. 收敛 `ss_basic_server / ss_basic_server_orig / ss_basic_server_ip` 语义
4. 生成 `/tmp/ss_node_domains.txt`
5. 为 smartdns 增加 `node_direct`
6. 为 chinadns-ng 增加 `node` group
7. 调整动态解析场景下的启动顺序
8. 处理 Naive / Tuic / JSON 节点差异
9. 处理 trigger reboot 在动态解析下的 no-op
10. 实机回归

## 回归测试清单

### GS7 本地实机

- smartdns + 动态解析
- chinadns-ng + 动态解析
- smartdns + 预解析
- chinadns-ng + 预解析
- 切换节点后 `/tmp/ss_node_domains.txt` 是否更新
- 运行期间客户端配置中是否保留域名
- 节点状态页是否仍能显示解析结果 IP
- 动态解析模式下触发重启任务是否 no-op

### 协议覆盖

- ss
- ssr
- vmess
- vmess json
- vless
- xray json
- trojan
- naive
- tuic
- hy2

## 风险

1. 动态解析场景下，若用户直连 DNS upstream 本身不可用，节点仍可能失败。
2. 部分自定义 JSON 可能没有标准 `outbounds[0]` 结构，无法可靠提取 server。
3. chinadns-ng 的 `no-ipv6` 规则调整需要实机验证，确保不影响现有直连/代理 AAAA 行为。
4. Tuic / Naive 是否完全依赖系统 resolver，需要通过 GS7 实机验证。
