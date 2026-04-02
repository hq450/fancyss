# fancyss Webtest 设计、联调与维护说明

## 1. 文档目的

本文记录 fancyss 当前节点 `webtest` 的实现结构、缓存体系、前后端交互、与 DNS / 节点存储 / 订阅恢复的耦合点，以及后续维护时需要注意的事项。

适用代码范围：

- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_node_common.sh`
- `fancyss/webs/Module_shadowsocks.asp`
- `fancyss/ss/websocket`

本文基于 2026 年 3 月 27 日 GS7 实机联调结果整理。

---

## 2. 功能目标

`webtest` 的目标不是做“最短时间内的单包 RTT”，而是尽量用可控的路由器资源，给出一组更接近“用户真实落地延迟下限”的结果。

当前设计明确围绕以下约束展开：

1. 路由器 CPU / 内存有限，不能为每个节点都长期起一个独立核心进程。
2. 首次 `socks5h` 请求会叠加远端 DNS 解析开销，首包延迟偏高。
3. 代理核心刚建立链路时，前几次请求通常比稳定态更慢。
4. 结果要尽量快地反馈到前端，用户要能立即看到状态变化。
5. 节点列表、订阅、恢复、编辑等动作会持续改变节点集合，因此测速配置必须有缓存，但缓存必须可验证是否过期。

所以，当前实现选择：

- 批量测速时优先复用 `xray` 的多 outbound 能力；
- `curl` 侧采用“warm + score”串行多 transfer，而不是盲目并发多个 curl 进程；
- 把“节点域名直连解析规则”和“xray-like 节点 outbound 配置”做成缓存，避免每次测速都全量重建；
- 前端优先 websocket 流式跟随 `webtest.stream`，失败时回退到 API 轮询 `webtest.txt`。

---

## 3. 用户可见状态机

前端节点表格里，当前会看到以下状态：

- `waiting...`
  - 前端点击后立即写入；
  - 后端初始化批量状态文件时也会写入，保证刷新页面后仍能看到“测速已开始”。
- `loading...`
  - 当前节点已经进入待测试批次，正在准备配置或等待所属协议组进入执行窗口。
- `booting...`
  - 对应协议核心已经开始启动，正在等待本地 socks5 监听端口就绪。
- `testing...`
  - 核心已就绪，`curl` 正在做 warm / score 阶段的串行请求。
- `NNN ms`
  - 最终成功结果。
- `failed!`
  - 核心启动失败、端口未拉起、协议不兼容、或请求阶段无有效响应且非 timeout。
- `timeout!`
  - `curl` 请求超时。
- `不支持!`
  - 当前插件或当前协议组合无法测速。
- `stopped`
  - 批量测速被用户停止，尚未完成的节点统一标记为 stopped。
- `canceled`
  - 批量测速进程异常退出或收到中断信号，未完成节点统一标记为 canceled。

---

## 4. 前端架构

### 4.1 入口函数

`Module_shadowsocks.asp` 中与测速直接相关的核心入口：

- `test_latency_single(node)`
- `latency_test('2')`
- `stop_latency_batch()`
- `clear_latency_cache()`
- `get_latency_data_single()`
- `get_latency_data()`
- `start_latency_ws()`
- `fallback_latency_ws()`
- `write_webtest()`

### 4.2 单节点测速

单节点测速走 `/_api/ -> ss_webtest.sh single_test <node>`。

前端行为：

1. 立即将该节点写成 `waiting...`。
2. 禁用其它单节点测速按钮，避免并发单测。
3. 后端开始单节点测速。
4. 前端通过 `get_latency_data_single()` 轮询 `/_temp/webtest.txt`。
5. 读到该节点最终状态后结束。

单节点测速没有 websocket 跟随，仍是轮询模式。

### 4.3 批量测速

批量测速走 `/_api/ -> ss_webtest.sh web_webtest`。

前端行为：

1. 页面进入节点管理页后，只要延迟测试功能开启，就会自动调用一次 `latency_test('2')`。
2. 该调用并不等于“一定启动一轮新的批量测速”，真正是否新开测速由后端 `web_webtest` 判断。
3. 只有后端返回 `ok1` 或 `ok4` 时，前端才认为当前处于真实批量测速中，并进入 websocket / 轮询跟随流程。
4. 若 `ws_flag == 1`，优先连接 `ws://<router>:803/`。
5. websocket 建立后发送 `follow_webtest`。
6. 后端先回放 `webtest.txt` 当前内容，再持续 `tail -f webtest.stream`。
7. 如果 websocket 打开失败、运行中断开、或浏览器不支持，则自动回退到 `get_latency_data()` 轮询 `/_temp/webtest.txt`。

`web_webtest` 的返回语义需要特别注意：

- `ok1`
  - 已存在 `/tmp/webtest.lock`，说明当前确实有一轮批量测速正在跑。
  - 前端应保持 `batch_test_running = true`，并继续跟随 `webtest.txt / webtest.stream`。
- `ok4`
  - 本次调用真正触发了 `start_webtest()`。
  - 后端会清空旧结果并尽快写入 `waiting... / loading...` 预览状态。
  - 前端应保持 `batch_test_running = true`。
- `ok2`
  - 现有 `webtest.txt` 仍在有效时间内，直接复用结果，不启动新一轮测速。
  - 前端不应把它当成“批量测速中”，也不应阻塞单节点测速。
- `ok3`
  - 当前结果不完整，但 `webtest_bakcup.txt` 中有足够可用结果，直接复用 backup，不启动新一轮测速。
  - 前端同样不应把它当成“批量测速中”。

这意味着一个很重要的判断：

- 如果页面上没有出现 `waiting... / loading... / booting... / testing...`，却提示“批量测速中”，通常不是后端真的在跑测速，而是前端错误把 `ok2 / ok3` 当成了运行态。
- 现在前端已经修正，只把 `ok1 / ok4` 视为真实批量测速。

### 4.4 websocket 跟随逻辑

`fancyss/ss/websocket` 中的 `follow_webtest` 分支行为：

1. 保证 `webtest.txt` 和 `webtest.stream` 存在；
2. 先把 `webtest.txt` 当前内容整段输出给前端；
3. 如果 `webtest.txt` 已经有 `stop>stop`，直接结束；
4. 否则从 `webtest.stream` 当前行号之后开始 `tail -f`；
5. 一旦读到 `stop>stop`，主动结束连接。

因此 websocket 只负责“更快地把已有文件内容流给前端”，并没有改变后端数据模型。后端仍然以文本文件为单一事实来源。

### 4.5 页面刷新后的结果恢复

页面刷新后，前端会重新读取：

- `/_temp/webtest.txt`
- `/_temp/webtest_bakcup.txt`

只要后端最终写回的是完整终态，刷新页面后就能恢复之前的测速结果。

这也是批量状态文件持久化必须准确的原因。

---

## 5. 后端总流程

### 5.1 入口动作

`ss_webtest.sh` 当前主要入口：

- `single_test <node>`
- `web_webtest`
- `manual_webtest`
- `stop_webtest`
- `clear_webtest`
- `warm_cache`
- `schedule_warm`
- `node_direct_refresh`
- `schedule_node_direct_refresh`

### 5.2 批量测速主链路

批量测速的主链路可概括为：

1. `wt_reset_webtest_output`
2. `wt_prepare_node_cache`
3. `wt_ensure_node_direct_dns_ready`
4. `sort_nodes`
5. `wt_init_batch_state_file`
6. `wt_prepare_webtest_preview`
7. `test_nodes`
8. `wt_finish_batch_run`

### 5.3 节点分组策略

测速不是按节点顺序逐个跑，而是先按协议能力分组。

分组基础文件：`${TMP2}/nodes_index.txt`

每行结构：

```text
node_id|type_tag|ss_obfs|method
```

当前分组规则：

- `00_01 / 00_02 / 00_04 / 00_05`
  - Shadowsocks 及其 obfs / 2022 细分
- `01`
  - SSR
- `03`
  - vmess / v2ray-like
- `04`
  - xray / vless-like
- `05`
  - trojan
- `06`
  - naive
- `07`
  - tuic
- `08`
  - hysteria2

其中 `00_01 / 00_02 / 00_04 / 00_05 / 03 / 04 / 05 / 08` 被视为 `xray-like` 组，统一走 `test_xray_group()`。

### 5.4 为什么 xray-like 合并测速

原因很直接：

- xray 能同时承载多个 outbound；
- 对同一批节点来说，复用一个 `wt-xray` 进程比一节点一起一个 xray 进程更省资源；
- 这样可以把开销集中在：
  - 生成 inbound / routing；
  - 组装 outbound；
  - 启动一次 xray；
  - 多个 socks5 入口并发跑 curl。

当前 `xray-like` 组包括：

- vmess/vless/xray
- trojan
- hysteria2
- 绝大多数直接由 xray 支持的 SS 类型

### 5.5 当前节点附近优先预览

测速开始后，前端不会等全部配置准备好才出现状态。

后端会先根据：

- 当前选中节点 `curr_node`
- 页面显示行数 `ss_basic_row`

计算一个“预览起点”，然后：

1. 旋转当前协议组文件；
2. 必要时旋转 `wt_xray_group.txt`；
3. 只把当前批次最先会启动的那一组前若干个节点先写成 `loading...`。

这样用户会优先看到“当前节点附近”的变化。

---

## 6. xray-like 批量测速链路

`test_xray_group()` 是当前 webtest 的核心热点。

### 6.1 预热缓存检查

先调用：

- `wt_ensure_webtest_cache_ready()`

它会：

1. 收集全部 xray-like 节点 id 到 `xray_like_nodes.all`；
2. 对照 `webtest_cache/cache.meta` 做全局新鲜度判断；
3. 若缓存过期，则在锁内重建缓存。

### 6.2 materialize 阶段

`wt_materialize_cached_nodes()` 会把当前待测速 id 列表映射成：

```text
node_id|/koolshare/configs/fancyss/webtest_cache/nodes/<id>_outbounds.json|start_port
```

输出文件就是 `materialized.txt`。

这一步只做“把缓存节点实体化成当前批次的输入”，不重新生成 outbound JSON。

### 6.3 端口分配与 list 生成

`wt_allocate_ports_and_lists()` 会一次性做完：

- 为当前批次全部节点分配 socks5 监听端口；
- 生成 inbound items；
- 生成 routing items；
- 生成 outbound list；
- 生成 `valid_nodes.txt`；
- 生成 `valid_pairs.txt`（`node_id|socks5_port`）。

这一步是批量测速启动前最关键的“批次物料准备”。

### 6.4 组装 xray confdir

基于前一步生成的列表，再构造三个文件：

- `00_inbounds.json`
- `01_outbounds.json`
- `02_routing.json`

其中：

- 若当前批次正好等于整套 xray-like 节点，且聚合缓存 `all_outbounds.json` 可直接复用，就直接复制聚合缓存；
- 否则按批次节点的 per-node outbound 现拼一个组内 `01_outbounds.json`。

### 6.5 启动一个 wt-xray

后端只启动一次：

```text
wt-xray run -confdir <json_dir>
```

然后等待首个 socks5 端口就绪，再进入并发 curl 阶段。

### 6.6 FIFO 多线程执行

`wt_open_fifo_pool()` 用命名管道实现固定 worker 池。

当前逻辑是：

1. 先往 fifo 里放入 `N` 个空 token；
2. 每个 worker 开始前先读一个 token；
3. worker 结束后把 token 写回；
4. 因此始终保持最多 `N` 个并发任务；
5. 任何一个 worker 提前结束，下一节点立即接力，不需要等整批一起结束。

这正是 webtest 现在的“动态补位并发”实现。

### 6.7 obfs sidecar 的处理

对于 SS + `obfs=http/tls` 节点，per-node cache 里还会生成：

- `<id>_start.sh`
- `<id>_stop.sh`

批量测速时不是一次性把所有 obfs-local 都拉起来，而是：

1. 某个节点拿到 worker token；
2. 执行它自己的 `start.sh`；
3. 跑 curl；
4. 执行它自己的 `stop.sh`；
5. 释放 token。

这样避免“几十上百个 obfs-local 同时常驻”。

---

## 7. 其它协议链路

### 7.1 SSR

SSR 仍走独立协议组，按 `WT_SSR_THREADS` 并发。

### 7.2 naive / tuic

`naive` 和 `tuic` 目前各自按“每节点一个临时进程 + FIFO 并发池”的方式处理：

- 为节点生成最小运行配置；
- 拉起临时本地 socks5；
- 进入 `curl_test()`；
- 结束后立刻杀掉进程。

其中：

- `naive` 使用 `WT_NAIVE_THREADS`
- `tuic` 使用 `WT_TUIC_THREADS`

### 7.3 机型并发分级

`detect_perf()` 现在拆成三步：

1. `wt_collect_perf_facts()`
   - 采集 `arch / cpu cores / mem / model`
2. `wt_select_perf_profile()`
   - 只负责把设备归类到一个 profile
3. `wt_apply_perf_profile()`
   - 只负责把 profile 映射到线程数和批次限制

这样后续如果要调优，只需要改 profile 对应表，不要把判断条件散落到多个函数里。

当前 profile 如下。

#### aarch64

| profile | 条件 | xray | tuic | naive | SSR | xray batch |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `aarch64_3plus_2g` | 3 核及以上，内存 >= 1536MB | 12 | 3 | 3 | 4 | 256 |
| `aarch64_3plus_1g` | 3 核及以上，768MB <= 内存 < 1536MB | 8 | 2 | 2 | 4 | 128 |
| `aarch64_3plus_512m` | 3 核及以上，内存 < 768MB | 6 | 1 | 1 | 2 | 64 |
| `aarch64_dual_core` | 2 核及以下 | 4 | 1 | 1 | 2 | 64 |

#### armv7l

| profile | 条件 | xray | tuic | naive | SSR | xray batch |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `armv7l_rt_ax89x` | `RT-AX89X` 特判，按 1G 强档处理 | 8 | 2 | 2 | 2 | 128 |
| `armv7l_quad_core_1g` | 4 核，内存 >= 768MB | 4 | 2 | 2 | 2 | 64 |
| `armv7l_quad_core_512m` | 4 核，内存 < 768MB | 4 | 1 | 1 | 1 | 32 |
| `armv7l_tri_core` | 3 核 | 4 | 1 | 1 | 1 | 32 |
| `armv7l_low_end` | 2 核及以下兜底 | 2 | 1 | 1 | 1 | 16 |

#### 其它 / 未识别架构

| profile | 条件 | xray | tuic | naive | SSR | xray batch |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `generic_low_end` | 未识别架构兜底 | 2 | 1 | 1 | 1 | 16 |

补充说明：

- `RT-AX89X` 单独特判，不走普通 `armv7l` 4 核档；
- `SSR` 没有单独在需求里分档，这里保持保守值，避免把 `rss-local` 并发拉得过高；
- `wt_get_cache_build_threads()` 也复用同一套 profile，避免缓存预热线程和测速线程各自有一套判断；
- `WT_LOW_END` 仍然保留，用于影响批量测速默认策略，例如是否默认开启 xray-like 分批。

---

## 8. curl_test 的设计取舍

### 8.1 不是单发 curl

`curl_test()` 不会只发一个 curl 请求。

它采用：

1. `warm`
2. `score1`
3. 必要时 `score2`

并且用 `curl -K config` 的多 transfer 串行执行方式，把多次请求放在一个 curl 进程里完成。

### 8.2 这么做的原因

主要是两个现实问题：

1. `socks5h` 下首个请求会触发远端 DNS 解析；
2. 首次链路建立成本较高，前几次请求比稳定态偏慢。

如果只打一枪，结果通常偏大；
如果起多个 curl 进程并发抢，也不代表真实稳定延迟，反而会放大并发竞争。

所以当前策略是：

- 用 `warm` 先把远端解析和初次建链尽快触发；
- 再用 `score1 / score2` 取更有代表性的下限值；
- 如果有历史延迟且首个评分明显偏大，再补一次 `score2` 做校正。

### 8.3 结果判定

- `200 / 204` 且 exit code 为 `0` 才算成功；
- 换算成毫秒后，取更优值；
- 若只出现超时，写 `timeout`；
- 若没有有效成功也没有 timeout，则写 `failed`。

---

## 9. 文件模型

### 9.1 前端消费文件

- `/tmp/upload/webtest.txt`
  - 当前运行态快照；
  - websocket 首屏和 API 轮询都读它。
- `/tmp/upload/webtest.stream`
  - 增量流；
  - websocket 连接建立后从这个文件继续跟随。
- `/tmp/upload/webtest_bakcup.txt`
  - 最近一次完成态快照；
  - 页面刷新后用于恢复上次结果。

### 9.2 批量内部状态文件

- `${TMP2}/webtest.state`
  - 批量测速的权威状态文件；
  - 最终由它复制到 `webtest.txt` 和 `webtest_bakcup.txt`。

2026-03-27 起，这个文件的并发写入已加锁，避免多 worker 同时 `sed -i` 造成最终快照丢状态。

### 9.3 node direct 缓存

- `/koolshare/configs/fancyss/node_direct_domains.txt`
- `/koolshare/configs/fancyss/node_direct_domains.meta`
- `/tmp/ss_node_domains.txt`

作用：

- 收集所有“节点服务器地址里是域名”的主机名；
- 动态解析模式下，把这些域名交给 chinadns-ng / smartdns 的直连上游解析；
- 让客户端配置可以直接保留域名，避免“代理尚未建立前，节点域名被送去代理侧解析”的鸡蛋问题。

### 9.4 节点 JSON / ENV 缓存

- `/koolshare/configs/fancyss/node_json_cache/*.json`
- `/koolshare/configs/fancyss/node_json_cache.meta`
- `/koolshare/configs/fancyss/node_env_cache/*.env`
- `/koolshare/configs/fancyss/node_env_cache.meta`
- `/koolshare/configs/fancyss/node_env_cache/ss_obfs_ids.txt`

作用：

- 把 schema2 节点对象预先落成紧凑 JSON；
- 再预展开成 shell 可 `source` 的 `.env`；
- 避免测速热路径里重复解析整份节点数据。

### 9.5 webtest cache

目录：`/koolshare/configs/fancyss/webtest_cache/`

包含：

- `nodes/<id>_outbounds.json`
  - 单节点 outbound 片段。
- `nodes/<id>_start.sh`
  - 节点需要的 sidecar 启动脚本（当前主要给 ss+obfs）。
- `nodes/<id>_stop.sh`
  - sidecar 停止脚本。
- `meta/<id>.meta`
  - 节点类型、节点 `_rev`、是否带 start/stop、预留 start_port 等信息。
- `materialize_index.txt`
  - `<id>|<start_port>` 索引，加速 materialize。
- `all_outbounds.json`
  - 全量 xray-like 聚合 outbound。
- `cache.meta`
  - 全局新鲜度签名。

`cache.meta` 当前记录：

- `cache_rev`
- `gen_rev`
- `linux_ver`
- `ss_basic_tfo`
- `server_resolv_mode`
- `server_resolver`
- `node_config_ts`
- `xray_count`
- `xray_ids_md5`
- `built_at`

只要这些条件有任一不匹配，就认为 webtest cache 过期。

---

## 10. 缓存刷新策略

### 10.1 node direct 缓存

以 `fss_node_catalog_ts` 为主签名。

触发路径：

- 节点手动新增
- 节点编辑
- 节点删除
- URI 添加节点
- 订阅写入节点
- 配置恢复
- webtest 运行前兜底检查

前端 schema2 场景下，新增 / 编辑 / 删除成功后会显式调：

- `schedule_schema2_node_direct_refresh()`
- `schedule_schema2_webtest_warm()`

### 10.2 webtest cache

以 `fss_node_config_ts` + 当前 xray-like 节点集合签名为主。

触发路径：

- 节点手动新增 / 编辑 / 删除
- URI 添加节点
- 订阅写入节点
- 配置恢复
- batch webtest 运行前
- 手动 `warm_cache`

### 10.3 增量重建

`wt_rebuild_webtest_cache_from_ids()` 支持增量模式：

1. 先检查全局设置签名是否匹配；
2. 若匹配，只收集 `_rev` 变化或缺失的节点做重建；
3. 若不匹配，则整批 xray-like 节点重建；
4. 重建完成后再统一生成：
   - `materialize_index.txt`
   - `all_outbounds.json`
   - `cache.meta`

### 10.4 页面自动触发与缓存复用的关系

节点管理页每次渲染完成后，前端都会自动调用一次 `latency_test('2')`。

但后端会分流成两种完全不同的路径：

1. 真正开跑批量测速
   - 条件：无结果、结果过期、或结果不可复用且 backup 也不够。
   - 行为：进入 `start_webtest()`，清空旧结果，写入 `waiting...` 等中间态。
2. 只复用已有结果
   - 条件：`webtest.txt` 仍有效，或 backup 仍足够可用。
   - 行为：直接返回 `ok2 / ok3`，不启动新测速。

因此“页面自动调用了批量测速接口”与“后台真的在测速”不是一回事。

维护时如果又出现以下症状：

- 页面没有任何 `waiting... / loading...`
- 单节点测速却被提示“批量测速中”

优先检查前端是否又把 `ok2 / ok3` 误判成了运行态。

### 10.5 一个重要细节

`fss_clear_webtest_cache_node()` 会同时删除：

- 该节点自己的 cache；
- `all_outbounds.json`
- `materialize_index.txt`
- `cache.meta`

这是故意设计：

- 单节点增删改之后，全局聚合文件已不可信；
- 后台 warm 或下一次 batch webtest 会重新生成聚合文件。

因此如果你在某次节点改动后发现 `nodes/` 和 `meta/` 还在，但 `cache.meta` / `all_outbounds.json` 暂时不存在，这不一定是 bug，通常表示“聚合层正在等待下一次 warm 重建”。

---

## 11. 与 DNS 的耦合

### 11.1 动态解析模式

当 `ss_basic_server_resolv_mode=1`：

- 节点 outbound 中服务器地址保留域名；
- `node_direct_domains.txt` 收集所有节点服务器域名；
- `wt_ensure_node_direct_dns_ready()` 在测速前兜底：
  1. 刷新 node_direct cache；
  2. 对比运行时 `/tmp/ss_node_domains.txt`；
  3. 若不同，则调用 `ssconfig.sh refresh_node_direct_dns`；
  4. 让 chinadns-ng / smartdns 重新加载直连域名规则。

这是当前 webtest 能正确测试域名节点的基础。

### 11.2 预解析模式

当 `ss_basic_server_resolv_mode=2`：

- 主流程仍允许把节点服务器预解析成 IP；
- webtest cache 也会把当前解析策略纳入 `cache.meta`；
- 若用户切换了解析模式或解析器，缓存会被判定过期并重建。

### 11.3 DNS 方案切换

当前已实测：

- `smartdns`
- `chinadns-ng`

两种方案下，webtest 都能工作。

需要注意：

- DNS 方案切换后，首次单节点测速可能明显更慢，因为远端解析链路和连接都处于冷态；
- 这是 warm / score 机制要解决的场景之一。

---

## 12. 与节点存储、订阅、恢复的耦合

### 12.1 schema2 节点存储

webtest 当前默认信任 schema2 节点对象缓存：

- `fss_node_<id>` -> `node_json_cache` -> `node_env_cache` -> `webtest_cache`

所以 schema2 的 `_rev`、`fss_node_order`、`fss_node_current`、`fss_node_next_id` 等元数据都会间接影响 webtest。

### 12.2 手动新增 / 编辑 / 删除

当前链路已覆盖：

- 新增后立即调度 node direct refresh 和 warm；
- 编辑 server / json 等影响域名解析的字段后，node direct 和 webtest cache 都会更新；
- 删除节点后，对应 cache 文件和 node direct 条目会被移除。

需要额外注意一个时序点：

- 前端对“节点变更后的 node_direct refresh / warm”做了短时间 debounce；
- 如果用户刚删改节点就立刻手动发起单节点 / 批量测速，旧实现里这些延后任务可能在测速刚启动后再落下来；
- `node_direct_refresh` 一旦在测速中途触发 `refresh_node_direct_dns`，会重载 smartdns / chinadns-ng，早批次的域名节点可能因此瞬时 `failed`，后批次又恢复正常。

当前修复分两层：

- 前端在手动单测 / 批量测速前，会先取消尚未发出的 schema2 post-change 定时任务；
- 后端 `schedule_warm / schedule_node_direct_refresh` 在发现已有前台 webtest 任务运行时，会直接跳过，不再与当前测速抢 DNS / cache 资源。

也就是说：

- 节点刚发生增删改时，如果用户马上点测速，当前这次测速进程自己负责执行 `wt_ensure_node_direct_dns_ready()` 和 `wt_ensure_webtest_cache_ready()`；
- 延后触发的 post-change 任务不会再中途插进来干扰当前测速。

### 12.3 URI 添加节点

URI 添加节点走订阅脚本导入路径，但最终也会：

- 写 schema2 节点对象；
- 更新节点时间戳；
- 调度 node direct refresh；
- 调度 webtest cache warm。

### 12.4 订阅节点

订阅写入节点时：

- 节点对象写入 schema2；
- `fss_node_catalog_ts` / `fss_node_config_ts` 单调更新；
- node direct cache 和 webtest cache 会在写入后刷新 / 预热。

注意：

- 前端 schema2 直改通常使用毫秒级时间戳；
- 后端 `fss_touch_node_*` 目前是秒级 `date +%s`，但若旧值更大，会自动 `old + 1` 保证单调递增；
- 因此当前时间戳的语义是“单调版本号”，不是严格的 wall clock 毫秒值。

### 12.5 配置恢复

恢复配置后：

1. 节点对象整体重写；
2. node direct meta 会先对齐恢复后的 `catalog_ts`；
3. webtest warm 异步执行；
4. 在 warm 尚未完成前，`cache.meta` 可能暂时不存在；
5. warm 完成后，`cache.meta` 会重新写回并对齐 `fss_node_config_ts`。

维护时不要把“恢复后几秒内 `cache.meta` 为空”直接判断成 bug，先确认后台 warm 是否还在运行。

---

## 13. 停止、异常退出与结果收尾

### 13.1 正常结束

`wt_finish_batch_run()` 会：

1. 把 `${TMP2}/webtest.state` 复制到 `webtest.txt`；
2. 追加 `stop>stop`；
3. 同步复制到 `webtest_bakcup.txt`；
4. 写 `ss_basic_webtest_ts`；
5. 清理运行锁。

### 13.2 用户手动停止

`stop_webtest` -> `wt_request_stop_batch()`：

- 将未完成节点统一标记为 `stopped`；
- 杀掉后台测速进程；
- 再收尾成完成态快照。

### 13.3 异常退出

批量测速期间设置了：

- `trap 'wt_batch_signal_handler' HUP INT TERM`
- `trap 'wt_batch_exit_guard' EXIT`

如果脚本被中断，会尽量把未完成节点补成 `canceled`，避免前端永远停留在 `testing...`。

---

## 14. 2026-03-27 实机联调覆盖项

联调环境：GS7，实机前端 + SSH。

已覆盖：

1. `smartdns`
   - 单节点测速：xray / ss / trojan / tuic / hysteria2
   - 批量测速：websocket
   - 批量测速：API fallback
   - 批量测速：中途停止
   - 停止后再次开始
2. `chinadns-ng`
   - 单节点测速：xray / ss / trojan / tuic / hysteria2
   - 批量测速：websocket
   - 批量测速：API fallback
3. 节点变更场景
   - 手动新增节点
   - 手动编辑节点
   - 手动删除节点
   - URI 添加节点
   - 订阅新增节点
   - 配置恢复
4. 缓存验证
   - `node_direct_domains.txt`
   - `/tmp/ss_node_domains.txt`
   - `webtest_cache/nodes/*_outbounds.json`
   - `webtest_cache/meta/*.meta`
   - `webtest_cache/cache.meta`
   - `node_direct_domains.meta`

### 本轮确认并修复的问题

问题：批量测速完成后，页面上已显示最终数值，但刷新页面后，个别节点会退回 `testing...`。

原因：

- `${TMP2}/webtest.state` 是批量结果的最终权威快照；
- 多个 worker 同时用 `sed -i` 修改它；
- 没有锁时，最终状态文件存在并发覆盖，导致 `webtest_bakcup.txt` 落盘时丢失最后结果。

修复：

- 为 `${TMP2}/webtest.state` 增加独立锁文件 `WT_WEBTEST_STATE_LOCK`；
- `wt_set_batch_state()` 内部改为加锁后再读改写状态文件；
- 批量结束 / 停止 / 异常清理时同步清掉状态锁。

修复后，批量测速完成后刷新页面，结果保持稳定，不再回退到 `testing...`。

问题：新增节点后进入节点管理页，页面没有出现 `waiting... / loading...`，但单节点测速被提示“批量测速中”，并且某些新节点单测会直接 `failed`。

原因：

- 前端在调用 `web_webtest` 前，过早把 `batch_test_running` 设为 `true`；
- 后端有可能只是返回 `ok2 / ok3` 复用已有结果，并没有真正启动批量测速；
- 旧逻辑会把这种“复用缓存”误判成“批量测速中”；
- 同时单节点测速复用了 `${TMP2}/nodes_index.txt` 的旧内容，可能按旧节点集合重建 `webtest cache`，把刚导入的新 xray-like 节点错误裁剪掉。

修复：

- 前端现在只在后端返回 `ok1 / ok4` 时才进入真实批量测速态；
- 返回 `ok2 / ok3` 时只刷新已有结果，不阻塞单节点测速；
- 单节点测速前强制清理旧的 `nodes_index.txt / nodes_file_name.txt / wt_*.txt`；
- `wt_ensure_webtest_cache_ready()` 不再复用 TMP 中旧索引，而是每次重建当前节点索引。

修复后：

- 如果后台真的在跑自动批量测速，页面会出现 `waiting... / loading...` 等中间状态；
- 如果只是复用现有结果，不会再出现“无中间状态却提示批量测速中”的假忙现象；
- 新导入的 xray-like 节点单节点测速不会再因旧索引裁剪缓存而直接 `failed`。

---

## 15. 维护建议

### 15.1 不要轻易改动的点

1. `curl_test()` 的 warm / score 设计
   - 这部分直接决定“测速快”与“测速更像稳定态”的平衡。
2. `xray-like` 合并策略
   - 这部分是当前性能能接受的核心。
3. `node_direct` 兜底刷新
   - 这是域名节点测速不失败的前提。
4. `cache.meta` 新鲜度判断
   - 改任何字段都要明确为什么仍能判断缓存是否过期。
5. `webtest.state` 并发写入
   - 如果以后改写状态文件逻辑，必须保留并发保护。

### 15.2 改动前建议先跑的回归项

至少回归：

1. `smartdns` 下单节点测速
2. `smartdns` 下 websocket 批量测速
3. `smartdns` 下停止批量测速
4. `chinadns-ng` 下单节点测速
5. `chinadns-ng` 下 API fallback 批量测速
6. 编辑一个域名节点后立即单测 / 批测
7. 恢复配置后等待 warm 完成再批测

---

## 16. 后续可继续推进的方向

### 16.1 近中期可做

1. 防止新路径回退到秒级时间戳
   - 当前节点 / catalog / config 时间戳已经统一到毫秒；
   - 后续如果新增节点写入路径，仍要确保继续沿用毫秒语义。
2. 暴露 warm 进度
   - 目前只能看到最终日志，不能看到缓存预热到第几个节点。
3. 单节点测速也支持 websocket 流式返回
   - 目前仍是轮询 `webtest.txt`。
4. 给前端增加更多批次进度信息
   - 比如“当前第几组 / 剩余多少节点 / 剩余多少 worker”。
5. 更细的失败原因
   - 目前 `failed` 聚合了多类错误，排障时还要看后台日志。

### 16.2 更大改造方向

1. 基于 Xray 连接观测 / health check 重做测速内核
   - 如果以后直接利用 Xray 自身观测能力，现有 `curl_test()` 和大量外部流程都可能重写。
2. 用 C / Rust 之类重写热点路径
   - 主要候选是批量配置拼装、状态管理、以及 curl 测试调度器。
3. 做更完整的测速结果数据库
   - 例如保留每节点历史最好值、最近值、失败原因、测速时间戳，而不仅是一个文本快照。
4. 针对 DNS 做更细的预取 / TTL / 缓存策略
   - 尤其是动态解析模式下，进一步减少域名节点冷启动时的等待。

---

## 17. 结论

当前 webtest 已经形成了较稳定的分层：

- 前端：状态展示、ws 跟随、API fallback
- 后端：协议分组、worker 调度、结果收尾
- 基础缓存：node direct / node json / node env / webtest cache
- DNS 耦合：动态解析模式下的直连域名兜底

这套结构的核心价值不在“代码最短”，而在于它已经把“路由器资源限制”“节点动态变化”“域名解析鸡蛋问题”“前端及时反馈”这几件事压到了一个可维护范围内。

后续如果要继续优化，优先建议沿着两条线推进：

1. 保持现有架构，继续打磨 warm / cache / 进度反馈；
2. 如果未来要跨一个量级提升测速能力，再考虑直接换内核实现。
