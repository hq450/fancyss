# fancyss 状态检测当前实现设计

本文档记录 `3.5.26` 阶段 fancyss 顶部插件运行状态、故障转移状态缓存、详细状态历史窗口的当前实现。目标是作为维护现状的依据，不描述未落地的未来方案。

## 目标与边界

状态检测当前分为三类交互：

1. 顶部插件运行状态
   - 显示国外/国内连通性和延迟。
   - 未开启故障转移时由前端页面按需触发探测。
   - 开启故障转移时读取后台常驻检测结果。

2. 故障转移健康检测
   - 只在 `ss_failover_enable=1` 时启用。
   - 后台持续检测并写缓存、写历史日志。
   - `ss_status_main.sh` 根据历史结果执行故障转移动作。

3. 详细状态历史窗口
   - 点击详细状态后显示国外/国内状态历史日志。
   - 这是历史日志流，不是顶部状态实时探测链路。
   - WebSocket 可用时使用 `ss_status_ws.sh follow_*` 追踪 stream 文件；不可用时走 HTTP 轮询日志文件。

## 关键配置项

- `ss_basic_enable`
  - 插件总开关；未开启时前端不继续状态检测。

- `ss_failover_enable`
  - `1`：启用故障转移，使用后台 `status-tool daemon` 和 `/tmp/upload/ss_status.txt`。
  - 非 `1`：不启用故障转移，顶部状态由前端请求触发。

- `ss_basic_status_mode`
  - `serve`：默认模式。非故障转移时常驻 `status-tool serve`，前端每次通过 `statusctl probe-once` 触发单次探测，避免反复启动 `status-tool`。
  - `once`：非故障转移时由 `ss_status.sh` 启动 `status-tool fancyss` 做一次性探测。
  - 空值/其它值：脚本层默认按 `serve` 处理，前端选项里保留“兼容模式”。

- `ss_basic_interval`
  - 前端顶部状态下一次刷新间隔的基础值。
  - `status-tool daemon/serve` 启动时也会转换为内部 interval 参数。

- `ss_basic_proxy_ipv6`
  - `1`：顶部状态显示三行：国外 IPv4、国外 IPv6、国内连接。
  - 非 `1`：顶部状态显示两行：国外链接、国内连接。

- `ss_basic_curl` / `ss_basic_furl`
  - 国内、国外状态检测 URL。
  - 为空时由默认 URL 补齐。

- `ss_heart_beat`
  - 故障转移切换节点后写入心跳标记。
  - 前端读取到心跳后提示刷新页面，并通过 `dummy_script.sh` 清零。

## 前端入口

主要实现位于 `fancyss/webs/Module_shadowsocks.asp`。

页面初始化流程：

1. `init()` 调用 `try_ws_connect(true)` 异步探测 WebSocket。
2. `get_dbus_data()` 加载 dbus 数据。
3. `wait_ws_probe_then_start_status(0)` 等待 WebSocket 探测短时间完成，然后调用 `get_ss_status(is_ws_available())`。
4. `get_ss_status()` 根据 `ss_failover_enable` 和 WebSocket 可用性进入对应链路。

顶部状态轮询：

- `should_run_front_status_live()` 当前始终返回 `true`。
- 因此顶部状态只要页面未卸载就持续按间隔轮询，即使浏览器标签页处于后台也不会停止。
- `visibilitychange` 只停止节点延迟、分流统计、详细状态历史流等非顶部状态任务，不停止顶部状态轮询。
- `pagehide` / `beforeunload` 会调用 `stop_page_live_runtime()`，关闭顶部状态和其它页面运行时任务。

刷新间隔：

- `get_status_refresh_delay_ms()` 根据 `ss_basic_interval` 计算基础刷新间隔，并加入随机抖动。
- `finish_front_status_poll()` 在每次非故障转移探测完成后调度下一次轮询。

等待态：

- 首次 `get_ss_status()` 会调用 `set_ss_status_waiting("Waiting..")`。
- 后续请求失败时，只有尚未收到过有效状态时才覆盖为 waiting。
- `apply_ss_status()` 会拒绝不符合当前 IPv6 展示模式的旧 payload，避免 IPv4/IPv6 模式切换后显示错行。

## WebSocket 可用性判定

当前 WebSocket 只能在以下条件全部满足时使用：

1. `ws_enable == 1`。
2. `try_ws_connect(true)` 成功收到 `echo ws_ok`。
3. 当前页面协议是 `http:`。
4. 当前访问 host 是路由器 LAN IP、`localhost` 或私有 IPv4 地址。

关键函数：

- `is_ws_transport_allowed()`：只允许 `window.location.protocol == "http:"`。
- `ws_host_allowed(host)`：只允许 LAN/localhost/私有 IPv4。
- `is_ws_available()`：综合 `ws_flag`、协议和 host 判定。

设计原因：

- 浏览器在 `https://` 页面下会阻止不安全的 `ws://` 连接。
- fancyss 当前不提供 `wss://`，所以 HTTPS 访问后台时必须全局禁用 WebSocket，并统一走 HTTP(S) API fallback。
- 这个判定不仅影响顶部状态，也影响保存应用、订阅、webtest、详细状态等所有依赖 `is_ws_available()` 的交互。

## 非故障转移模式

条件：`ss_failover_enable != 1`。

语义：

- 不使用后台周期测速作为状态来源。
- 顶部状态由前端页面按间隔主动触发。
- 默认使用 `status-tool serve` 常驻空闲进程，收到请求时才探测。
- 页面关闭后前端不再发起请求；`status-tool serve` 可继续常驻，避免弱机型反复拉起进程。

### 非故障转移 + WebSocket 可用 + serve

前端路径：

1. `get_ss_status_front_websocket()`。
2. `status_front_ws_direct = true`。
3. WebSocket 发送：

```sh
/koolshare/bin/statusctl --socket-path /tmp/status-tool.sock probe-once
```

后端路径：

1. `statusctl` 连接 `/tmp/status-tool.sock`。
2. `status-tool serve` 执行一次探测。
3. `status-tool serve` 返回 fancyss legacy 文本格式，例如：

```text
国外链接 【2026-05-07 15:00:00】 ✓&nbsp;&nbsp;86 ms@@国内连接 【2026-05-07 15:00:00】 ✓&nbsp;&nbsp;12 ms
```

4. 前端 `apply_ss_status()` 直接渲染。

失败处理：

- 如果 WebSocket 返回内容不包含 `@@`，前端认为不是有效状态 payload，降级到 HTTP(S) API。
- WebSocket 连接或发送失败时，也会降级到 HTTP(S) API。

### 非故障转移 + WebSocket 不可用 + serve

典型场景：

- HTTPS 访问路由器后台。
- WebSocket 探测失败。
- Host 不允许使用 WebSocket。

前端路径：

1. `get_ss_status_front_httpd()`。
2. POST `/_api/`：

```json
{"method":"ss_status.sh","params":[id]}
```

后端路径：

1. 软件中心 HTTP API 执行 `/koolshare/scripts/ss_status.sh id`。
2. `ss_status.sh` 判断为非故障转移。
3. `resolve_payload_once_only()` 根据 `ss_basic_status_mode` 选择 `serve`。
4. `ensure_status_serve_runtime()` 检查：
   - `/tmp/status-tool.sock` 是否存在；
   - `/tmp/status-tool-serve.args` 中的 URL 和 IPv6 参数是否匹配当前配置；
   - `status-tool serve` 进程是否存在。
5. 如不满足则调用 `ss_status_daemon.sh restart` 重启 `status-tool serve`。
6. 调用 `statusctl --socket-path /tmp/status-tool.sock probe-once` 获取最新状态。
7. 通过 `http_response` 返回给前端。

并发控制：

- HTTP 分支使用 `/tmp/fancyss_status_http.lock`。
- 如果已有 HTTP 探测在运行，新请求优先读取 `/tmp/upload/ss_status_front.txt` 或 `/tmp/upload/ss_status_ws.txt` 的新鲜缓存。
- HTTP 锁最大年龄为 20 秒，避免异常残留永久阻塞。

### 非故障转移 + once/兼容路径

当 `ss_basic_status_mode=once` 时：

1. 前端仍通过 WebSocket 或 HTTP(S) API 调用状态路径。
2. 后端 `ss_status.sh` 不使用 `statusctl`。
3. 直接调用：

```sh
/koolshare/bin/status-tool fancyss --china-url ... --foreign-url ... --proxy-ipv6 ... --foreign-proxy socks5://127.0.0.1:23456
```

该模式保留为兼容和对照测试路径。缺点是每轮前端状态刷新都会启动一次 `status-tool` 进程，弱机型上可能产生 CPU 间隔峰值。

## 故障转移模式

条件：`ss_failover_enable=1`。

语义：

- 状态检测是后台常驻能力，不依赖浏览器页面是否打开。
- `status-tool daemon` 周期探测并写状态缓存。
- `ss_status_main.sh` 读取缓存，写历史日志，并执行故障转移判定。
- 前端只读取已有缓存，不主动触发真实探测。

### 后台启动流程

入口：

- 插件启动完成后，`ssconfig.sh` 的 `check_status()` 会调用：

```sh
sh /koolshare/scripts/ss_status_daemon.sh restart
sh /koolshare/scripts/ss_status_main.sh >/dev/null 2>&1 &
```

- 在附加功能里修改故障转移相关配置时，前端通过 `ss_status_reset.sh` 重置状态运行时。

`ss_status_daemon.sh restart` 行为：

1. 停止已有 `status-tool daemon` / `status-tool serve`。
2. 清理 socket、pidfile、state、legacy cache、锁。
3. 当 `ss_failover_enable=1` 时启动：

```sh
/koolshare/bin/status-tool daemon \
  --china-url ... \
  --foreign-url ... \
  --proxy-ipv6 ... \
  --foreign-proxy socks5://127.0.0.1:23456 \
  --interval-ms ... \
  --state-file /tmp/upload/ss_status_daemon.json \
  --legacy-file /tmp/upload/ss_status_front.txt
```

### 后台状态文件

`status-tool daemon` 写入：

- `/tmp/upload/ss_status_daemon.json`
  - JSON 状态文件，保留结构化探测结果。

- `/tmp/upload/ss_status_front.txt`
  - 兼容前端的 legacy 文本格式。

`ss_status_main.sh` 写入：

- `/tmp/upload/ss_status.txt`
  - 顶部状态读取文件。
  - 内容为 `ss_status_front.txt` 加上 `@@${ss_heart_beat}`。

- `/tmp/upload/ssf_status.txt`
  - 国外状态历史日志。

- `/tmp/upload/ssc_status.txt`
  - 国内状态历史日志。

- `/tmp/upload/ssf_status.stream` / `/tmp/upload/ssc_status.stream`
  - 详细状态历史 WebSocket 追踪用 stream 文件。

### 故障转移 + WebSocket 可用

前端路径：

1. `get_ss_status_back()`。
2. `setup_status_ws(..., with_heartbeat=true, ...)`。
3. WebSocket 每秒发送：

```sh
cat /tmp/upload/ss_status.txt
```

4. `apply_ss_status(res, true, showRefreshPrompt)` 渲染状态并处理心跳。

### 故障转移 + WebSocket 不可用

前端路径：

1. `get_ss_status_back_httpd()`。
2. 每秒 GET：

```text
/_temp/ss_status.txt?_={timestamp}
```

3. 读取 `/tmp/upload/ss_status.txt` 的 HTTP 暴露副本。
4. `apply_ss_status(res, true, true)` 渲染。

注意：故障转移模式下 HTTP fallback 是读取缓存文件，不调用 `ss_status.sh` 主动探测。

## status-tool / statusctl 角色

`status-tool` 当前提供三种 fancyss 相关模式：

1. `status-tool fancyss`
   - 一次性探测。
   - 输出 legacy 文本格式。
   - 用于 `ss_basic_status_mode=once` 或兜底。

2. `status-tool serve`
   - 常驻 Unix socket 服务。
   - 默认空闲。
   - 收到 `probe_once` 后执行一次探测并返回 legacy 文本。
   - 同时维护 `/tmp/upload/ss_status_daemon.json` 和 `/tmp/upload/ss_status_front.txt`。
   - 用于非故障转移默认路径，降低弱机型 CPU 峰值。

3. `status-tool daemon`
   - 后台周期探测。
   - 按 `--interval-ms` 写状态文件。
   - 用于故障转移模式。

`statusctl` 是极薄 Unix socket 客户端：

- `probe-once`：向 `serve` 发送 `probe_once`，触发一次探测。
- `get-cache`：读取 `serve` 最近缓存。
- `ping`：探测 socket 可交互性。

当前 `ss_status.sh` 检查 `serve` 是否有效时，主要检查 socket、参数文件和进程，不依赖 `ping` 作为唯一依据。原因是 `status-tool serve` 探测期间可能暂时忙碌，单纯 `ping` 容易导致误判并反复重启 `serve`。

## 探测内容和输出格式

`status-tool` 为 fancyss 构造固定探测组：

- 国内连接：
  - `name=china`
  - IPv4 direct
  - 不走代理

- 未开启 IPv6 代理时的国外链接：
  - `name=foreign4`
  - IPv4 socks5
  - 代理为 `socks5://127.0.0.1:23456`

- 开启 IPv6 代理时的国外 IPv4 / IPv6：
  - `name=foreign4`
  - IPv4 direct
  - `name=foreign6`
  - IPv6 direct

输出给前端的 legacy 格式：

- 非 IPv6：

```text
国外链接 【YYYY-MM-DD HH:MM:SS】 ...@@国内连接 【YYYY-MM-DD HH:MM:SS】 ...
```

- IPv6：

```text
国外IPv4 【YYYY-MM-DD HH:MM:SS】 ...@@国外IPv6 【YYYY-MM-DD HH:MM:SS】 ...@@国内连接 【YYYY-MM-DD HH:MM:SS】 ...
```

成功状态使用 `✓  N ms`，失败状态使用红色 `X`。

## 锁、缓存和新鲜度

`ss_status.sh` 维护两类锁：

- `/tmp/fancyss_status_ws.lock`
  - WebSocket 脚本路径使用。
  - 最大年龄 60 秒。

- `/tmp/fancyss_status_http.lock`
  - HTTP(S) API 路径使用。
  - 最大年龄 20 秒。

缓存文件：

- `/tmp/upload/ss_status_front.txt`
  - `status-tool serve/daemon` 写入的前端 legacy cache。

- `/tmp/upload/ss_status_ws.txt`
  - `ss_status.sh` 的 WebSocket 路径缓存。

- `/tmp/upload/ss_status.txt`
  - 故障转移模式前端读取文件，带心跳字段。

缓存有效性：

- payload 不能包含 `等待` 或 `Waiting`。
- payload 必须符合当前 IPv6 展示模式。
- payload 时间戳默认 120 秒内视为新鲜。

## 启动、停止和重置

插件启动：

- `ssconfig.sh` 完成代理和 DNS 启动后调用 `check_status()`。
- 开启故障转移：启动 `status-tool daemon` 和 `ss_status_main.sh`。
- 未开启故障转移：按 `ss_basic_status_mode` 启动 `status-tool serve`，或不启动后台状态进程。

插件停止：

- `ssconfig.sh` 的 `stop_status()` 会关闭：
  - `ss_status_main.sh`
  - `ss_status.sh`
  - `curl-status`
  - `statusctl`
  - 详细状态 stream follower
  - `status-tool daemon`
  - `status-tool serve`
  - 残留 `status-tool fancyss`
- 同时删除 pidfile、socket、state、legacy cache、锁和 `/tmp/upload/ss_status.txt`。

配置重置：

- 前端保存故障转移/状态模式相关设置时调用 `ss_status_reset.sh`。
- 该脚本先停止状态运行时，再根据当前 `ss_failover_enable` 和 `ss_basic_status_mode` 启动对应运行时。

## 详细状态历史窗口

主要实现：

- 前端：`lookup_status_log()`、`get_status_log_ws()`、`get_status_log_httpd()`。
- 后端：`ss_status_ws.sh`。

WebSocket 可用时：

```sh
sh /koolshare/scripts/ss_status_ws.sh follow_ssf_status
sh /koolshare/scripts/ss_status_ws.sh follow_ssc_status
```

`ss_status_ws.sh` 会：

1. 确保 stream 文件存在。
2. 输出当前日志快照。
3. `tail -f` 对应 stream 文件，把新增日志推给前端。

WebSocket 不可用时：

- 前端使用 HTTP 方式读取状态历史日志文件。

边界：

- `follow_ssf_status` / `follow_ssc_status` 只应该在用户打开详细状态历史窗口时出现。
- 顶部插件运行状态不需要启动 `ss_status_ws.sh follow_*` 或 `tail -f /tmp/upload/ssf_status.stream`。
- 停止状态运行时、重启 daemon/serve、页面关闭详细窗口时都应清理这些 follower。

## WS / HTTP(S) / 故障转移组合矩阵

| 场景 | 前端入口 | 后端行为 | 真实探测来源 | 前端读取源 |
| --- | --- | --- | --- | --- |
| 非故障转移 + WS + serve | `get_ss_status_front_websocket()` | WS 调 `statusctl probe-once` | `status-tool serve` 按需探测 | WS 返回 payload |
| 非故障转移 + HTTP(S) + serve | `get_ss_status_front_httpd()` | `_api/ss_status.sh id` 调 `statusctl probe-once` | `status-tool serve` 按需探测 | HTTP API result |
| 非故障转移 + WS + once | `get_ss_status_front_websocket()` | WS 调 `ss_status.sh ws` | `status-tool fancyss` 一次性探测 | WS 返回 payload |
| 非故障转移 + HTTP(S) + once | `get_ss_status_front_httpd()` | `_api/ss_status.sh id` | `status-tool fancyss` 一次性探测 | HTTP API result |
| 故障转移 + WS | `get_ss_status_back()` | WS 周期 `cat /tmp/upload/ss_status.txt` | `status-tool daemon` 后台探测 | WS 返回文件内容 |
| 故障转移 + HTTP(S) | `get_ss_status_back_httpd()` | GET `/_temp/ss_status.txt` | `status-tool daemon` 后台探测 | `_temp` 文件内容 |
| 详细状态 + WS | `get_status_log_ws()` | `ss_status_ws.sh follow_*` | `ss_status_main.sh` 写历史 stream | WS 流式日志 |
| 详细状态 + HTTP(S) | `get_status_log_httpd()` | HTTP 读取历史日志 | `ss_status_main.sh` 写历史文件 | 日志文件内容 |

## 常见诊断命令

查看状态相关进程：

```sh
ps | grep status | grep -v grep
```

非故障转移 serve 模式应主要看到：

```sh
/koolshare/bin/status-tool serve --socket-path /tmp/status-tool.sock ...
```

故障转移模式应看到：

```sh
/koolshare/bin/status-tool daemon ...
sh /koolshare/scripts/ss_status_main.sh
```

HTTPS 访问、未开启故障转移时，不应该仅因为顶部状态出现以下进程：

```sh
sh /koolshare/scripts/ss_status_ws.sh follow_ssf_status
tail -f /tmp/upload/ssf_status.stream
```

检查 serve 参数是否匹配：

```sh
cat /tmp/status-tool-serve.args
```

手动触发非故障转移状态探测：

```sh
/koolshare/bin/statusctl --socket-path /tmp/status-tool.sock probe-once
```

读取 serve 最近缓存：

```sh
/koolshare/bin/statusctl --socket-path /tmp/status-tool.sock get-cache
```

查看缓存文件：

```sh
cat /tmp/upload/ss_status_front.txt
cat /tmp/upload/ss_status.txt
cat /tmp/upload/ss_status_daemon.json
```

清理并重启状态运行时：

```sh
sh /koolshare/scripts/ss_status_daemon.sh restart
```

完整重置故障转移/状态运行时：

```sh
sh /koolshare/scripts/ss_status_reset.sh
```

## 维护注意事项

1. HTTPS 下不要尝试建立 `ws://`。
   - 所有状态、日志和操作路径都必须能通过 HTTP(S) API fallback 工作。

2. 非故障转移模式不要读取 `/tmp/upload/ss_status.txt` 作为唯一状态来源。
   - 该文件是故障转移后台缓存，非故障转移时应由前端触发 `statusctl probe-once` 或 `status-tool fancyss`。

3. 故障转移模式不要由前端主动触发真实探测。
   - 前端只读取 `status-tool daemon` 的缓存结果。

4. 不要把详细状态历史流和顶部状态混在一起。
   - `ss_status_ws.sh follow_*` 只服务详细历史窗口。

5. 修改 IPv6 代理、检测 URL、检测模式后，需要重启 `status-tool serve/daemon`。
   - 当前通过 `/tmp/status-tool-serve.args` 校验 serve 参数是否匹配。

6. 修改 `status-tool serve` 可用性检查时，不要只依赖 `statusctl ping`。
   - serve 正在探测时可能短暂忙碌，误判会造成反复重启和 waiting。

7. 弱机型优先使用 `serve`。
   - `once` 路径稳定但每轮都会拉起进程，适合排障对照，不适合作为弱机型默认模式。
