# fancyss 订阅体系统一改造 v1（按订阅链接拆分配置 + Zig 并发下载/UA 探测）

本文是对 fancyss 订阅链路的一次“前后端统一改造”设计稿，目标是把当前“多个订阅链接共享一套全局配置”的模式，升级为“一个订阅链接对应一个订阅配置（profile）+ 独立 meta/state”，并为后续更深的订阅能力（UA、过滤、TFO、不安全、SSEP 等）打好可扩展基础。

重点同时覆盖：

- 前端 UI 形态（订阅管理）
- 后端存储与 orchestration（shell 仍负责落库/兼容）
- Zig 工具化（并发下载 + UA 探测 + 结果分析，减少多次 curl 进程开销）

---

## 1. 现状与痛点

当前实现（以 `ss_online_links` 为中心）：

- 多个订阅链接写在一个 textarea 中（仅 URL 列表）
- UA、过滤关键词、下载是否走代理、允许不安全等，全部是“全局设置”
- 每个订阅链接虽然已有独立缓存：`raw/sub_<hash>.txt`、`parsed/sub_<hash>.txt`、`parsed/sub_<hash>.meta`，但“配置”仍是全局的
- UA 的本质需求是“按订阅源差异化”，而不是“全局开关”

主要问题：

- 一个机场需要 `v2rayN UA`，另一个机场需要默认 UA 或 `shadowrocket UA` 时无法同时满足
- 未来想做“每个订阅链接单独配置：UA/过滤/是否走代理/是否允许不安全/是否开启 tfo...”时，继续堆在同一张表会失控
- 若用 shell 并发多次 `curl` 做 UA 探测，在弱机型上会产生明显 CPU/进程负担

---

## 2. 目标与非目标

目标：

- 一个订阅链接 = 一个订阅 profile（配置文件 + 状态文件）
- 前端提供“订阅管理”入口：增删改查 profile，支持单机场配置
- 订阅下载/解析/落库链路支持按 profile 执行（失败可见，不做自动 curl 回退）
- UA 探测支持“同一订阅链接在多个 UA + direct/proxy 下做对比分析”，并尽量在 Zig 内一次性完成，避免 24 次 curl 进程
- 升级时自动迁移旧 `ss_online_links`：按链接拆分生成 profile，并清理旧字段
- 允许逐步演进：先落地 profile + UI，再落地 Zig 下载器，再逐步把更多逻辑下沉

非目标（v1 不强求）：

- 立刻把订阅链路的所有 orchestration 都下沉到 Zig（dbus 写回、节点恢复、缓存收尾仍由 shell 负责）
- 立刻实现 SSEP 真正解密（可在后续版本逐步落地）

---

## 3. 新的订阅实体模型：Subscription Profile

### 3.1 目录与文件布局（建议）

建议新增：

- `/koolshare/configs/fancyss/subscriptions/`

每个订阅 profile 两个文件：

- `profiles/<id>.json`：用户配置（前端编辑产生）
- `profiles/<id>.state.json`：运行态状态（订阅成功/失败后更新，包含 UA 选择结果、上次错误等）

说明：

- `id` 建议是独立稳定短 ID：创建时生成随机十六进制字符串，后续不随 URL 变化
- `state.json` 由后端更新，前端只读，不直接编辑
- 订阅 raw/parsed cache 仍可继续用现有 `${SUB_RAW_CACHE_DIR}` / `${SUB_PARSED_CACHE_DIR}`，并以 `url_hash` 作为 key（便于兼容旧缓存）

### 3.2 Profile 配置文件格式（草案）

```json
{
  "version": 1,
  "id": "78fd9b2a",
  "name": "sslinks 主号",
  "url": "https://example.com/api/v1/client/subscribe?token=xxx",
  "enabled": true,

  "download": {
    "policy": "auto",
    "proxy": "socks5://127.0.0.1:23456",
    "timeout_ms": 8000,
    "max_bytes": 4194304,
    "insecure_tls": true,
    "follow_redirects": true
  },

  "ua": {
    "mode": "auto",
    "fixed": "",
    "candidates": ["default", "curl", "wget", "v2rayn", "v2rayng", "shadowrocket"]
  },

  "filter": {
    "exclude": ["测试", "过期", "剩余"],
    "include": [],
    "keep_info_node": false
  },

  "defaults": {
    "allow_insecure": "inherit",
    "tfo": "inherit",
    "hy2_tfo_switch": "inherit",
    "hy2_up_mbps": "",
    "hy2_dl_mbps": "",
    "hy2_cg_opt": "inherit"
  },

  "schedule": {
    "enabled": false,
    "cron": ""
  }
}
```

字段说明（核心约束）：

- `download.policy`
  - `auto`：先 direct，失败再 proxy（对齐现有行为）
  - `direct`：强制直连
  - `proxy`：强制 socks5
- `ua.mode`
  - `fixed`：只用 `fixed` UA
  - `auto`：运行 UA 探测并缓存结果
  - `inherit`：沿用“订阅全局默认值”（仅作为 profile 缺省值/迁移用，不再依赖旧 `ss_basic_online_ua`）
- `defaults.*`
  - `inherit` 表示不强制覆盖订阅内容（保持当前“按订阅/按节点原始字段”语义）
  - 后续可扩展为 `on/off/inherit` 三态

### 3.3 State 状态文件格式（草案）

```json
{
  "version": 1,
  "id": "78fd9b2a",
  "url_hash": "78fd",
  "last_ok_ts": 1770000000,
  "last_error_ts": 0,
  "last_error": "",

  "ua_selected": {
    "mode": "direct",
    "profile": "default",
    "ua": "AsusWRT|koolcenter|...|curl|v2rayN"
  },

  "probe": {
    "last_probe_ts": 1770000000,
    "best_score": 123,
    "summary": [
      {
        "mode": "direct",
        "profile": "default",
        "ok": true,
        "http_status": 200,
        "kind": "base64-uri-lines",
        "bytes": 68076,
        "recognized_nodes": 231,
        "protocol_kinds": 7,
        "unknown_lines": 0
      }
    ]
  }
}
```

原则：

- `state` 不写订阅明文内容
- `state` 可以写“UA 选择结果 + 摘要”，便于后续调试

---

## 4. Zig 并发下载与 UA 探测：建议方案

### 4.1 为什么不直接并发 24 次 curl

在弱性能路由器上，24 个 curl/wget 进程的主要负担来自：

- 多进程启动成本（加载、链接、初始化、解析参数）
- 每个进程独立的 DNS/TLS/HTTP 栈初始化
- 并发时进程调度与内存压力显著增大

单个 Zig 二进制做并发下载的优势：

- 一个进程内复用 allocator、DNS 缓存（可选）、日志与统计逻辑
- 避免多进程启动开销
- 更易做统一并发上限、超时、重试和早停策略

### 4.2 HTTPS/TLS 的实现选型（关键）

订阅链接几乎都是 `https`，因此 Zig 工具必须具备 TLS 能力。

可选路径与权衡：

- 方案 A：Zig `std.http` + `std.crypto.tls`（优先推荐）
  - 优点：纯 Zig，易跨平台静态分发；与 fancyss 现有 Zig 工具链一致；不依赖固件的 libcurl/openssl
  - 缺点：TLS/HTTP 兼容性风险需要验证；遇到个别机场服务端奇怪实现时可能需要快速迭代

- 方案 B：静态内嵌 libcurl（multi interface）+ OpenSSL
  - 优点：兼容性最好；重定向、压缩、各种边界行为成熟
  - 缺点：构建与分发复杂；二进制体积显著增大；多平台静态链接难度高；仍需处理“某些固件 libcurl 代理能力不一致”的历史问题

- 方案 C：使用系统 libcurl
  - 不建议。固件差异大，proxy/socks/tls 特性不稳定，难以作为 fancyss 的一致性基础

建议结论：

- v1 首选方案 A（纯 Zig https），不做自动 curl 回退
- 若后续真实兼容性证明不足，再评估方案 B

### 4.3 Zig 工具形态：扩展 sub-tool vs 新工具

建议优先“扩展 `sub-tool`”而不是新建工具：

- `sub-tool` 已承担订阅内容识别/解析/diff/统计
- 下载能力与“订阅输入”语义一致，属于同一域
- 减少新二进制数量与分发复杂度

建议新增命令（草案）：

- `sub-tool fetch`
  - 输入：profile json 或参数（url、ua、mode、proxy）
  - 输出：raw payload（stdout 或写文件），同时输出 head 信息（JSON）

- `sub-tool probe-ua`
  - 输入：profile json 或 batch plan json
  - 行为：对 `links * ua_candidates * (direct/proxy)` 执行下载，做轻量识别 + 解析统计，给出每个链接的推荐 UA
  - 输出：`probe.json`（结构化结果），可选把每个 candidate 的 raw 写到临时目录（便于后续复用避免二次下载）

### 4.4 Batch Plan 输入（支持 2 个或更多订阅一次性并发）

```json
{
  "version": 1,
  "jobs": [
    {
      "id": "78fd9b2a",
      "url": "https://...",
      "modes": ["direct", "proxy"],
      "proxy": "socks5://127.0.0.1:23456",
      "ua_profiles": [
        { "name": "default", "ua": "AsusWRT|...|curl|v2rayN" },
        { "name": "curl", "ua": "" },
        { "name": "wget", "ua": "" },
        { "name": "v2rayn", "ua": "v2rayn" }
      ],
      "timeout_ms": 8000,
      "max_bytes": 4194304,
      "follow_redirects": true,
      "insecure_tls": true
    }
  ],
  "parallelism": 6
}
```

说明：

- `parallelism` 必须存在，默认不建议过大（例如 4-8）
- 即使 job=2，candidate=24，也不应该无脑 24 并发
- 弱机型更应控制并发以避免 CPU 峰值

### 4.5 轻量“识别 + 统计”逻辑（复用 sub-tool 内核）

对每个候选下载结果做：

1. 内容类型识别（复用 `sub-tool inspect` 内核）：
   - `uri-lines / base64-uri-lines / clash-yaml / html-login / html-redirect / json-error ...`
2. 对可解析类型做“轻量解析统计”（复用 `summary` 内核或抽出共用函数）：
   - recognized_nodes
   - protocol_kinds
   - unknown_lines
   - raw_bytes
3. 评分排序并选出 best candidate

注意：

- 在订阅场景下，“某 UA 下载失败 / 某出站策略下载失败”是常见现象，应当作为 probe 的真实输入被记录与展示，而不是触发自动 curl 回退。

评分建议（可调）：

- recognized_nodes 降序
- protocol_kinds 降序
- unknown_lines 升序
- bytes 降序（仅作为弱 tie-break）
- candidate_priority（尽量优先 default，避免频繁跳变）

### 4.6 早停与缓存策略（避免不必要下载）

必须支持：

- 若 `state.ua_selected` 存在且近期成功：优先只用该 candidate 下载，失败才 probe
- probe 时支持早停：
  - 若某 candidate 已达到“明显领先阈值”（例如 recognized_nodes 比第二名高 30% 且 kind 正常），则跳过剩余候选
- probe 结果写入 `state.json`，下次直接复用

---

## 5. 后端 orchestration（shell）改造建议

### 5.1 新增订阅管理脚本

建议新增脚本（命名仅示例）：

- `/koolshare/scripts/ss_subscribe_profile.sh`
  - `list`：列出 profiles（JSON）
  - `create/update/delete`：写 profile 文件
  - `sync <id|all>`：触发订阅执行（日志走 realtime）

### 5.2 订阅执行入口

建议保留现有：

- `ss_node_subscribe.sh` 作为订阅执行主入口（保留脚本名以减少周边改动）

并逐步增加：

- `ss_node_subscribe_v2.sh`（可选）或在原脚本内分支：
  - `sync_profile <profile_file>`：按 profile 执行一次订阅（下载、解析、落库）

执行链路建议：

1. 读取 profile
2. 决定下载策略：
   - 若 `ua.mode=fixed`：一次下载
   - 若 `ua.mode=auto`：调用 `sub-tool probe-ua` 获取推荐 candidate（必要时）
3. 下载得到 raw（可复用 probe 结果避免二次下载）
4. 调用 `sub-tool parse-uri-lines --format fancyss ...` 输出 JSONL
5. 走现有 schema2 写库 / diff / reference notice / cache refresh 逻辑

---

## 6. 前端 UI 设计建议（v1 推荐形态）

### 6.1 总体原则

- 订阅的“配置维度”从“全局”变成“每个订阅链接一份”
- UI 不应继续把所有配置塞进当前订阅表格，否则会继续膨胀
- v1 推荐新增一个独立入口：`订阅管理`（弹窗）
- “URI 添加节点”不再单独占用页面区域，纳入同一弹窗的标签页

### 6.2 推荐交互：订阅管理弹窗 + Tabs

入口位置建议：

- 节点订阅设置区域保留一个按钮：`订阅管理`
- 更新管理处保留一个入口（可直接打开订阅管理弹窗）
- 节点管理页也可放同名入口（减少用户找入口成本）

弹窗结构建议：

- 顶部 Tabs：
  - `订阅`（默认 Tab）
  - `URI 导入`

订阅 Tab（列表视图）：

- 顶部：
  - `+ 添加订阅`
  - `全部订阅`（立即同步 all）
- 内容：订阅卡片列表（card 或 chip）
  - 显示：别名、启用状态、上次成功时间、上次错误摘要、UA 模式（fixed/auto）、下载策略（auto/direct/proxy）
  - 操作：`同步`、`编辑`、`删除`

订阅 Tab（编辑视图，建议在同一弹窗内“进入详情页”，顶部提供返回按钮，避免弹两层 modal）：

- 基本信息：
  - 别名
  - 订阅链接
  - 启用开关
- 下载：
  - 策略：auto/direct/proxy
  - socks5 地址（高级选项，默认 127.0.0.1:23456）
  - 超时、最大字节数（高级选项）
- UA：
  - fixed / auto / inherit
  - fixed 值输入框
  - auto 候选勾选（默认 6 个）
- 过滤：
  - include / exclude（支持多关键词）
  - keep_info_node
- defaults（v1 可先只放在“高级”折叠区）：
  - allow_insecure
  - tfo
  - hy2 参数
- 底部按钮：
  - `保存`
  - `保存并同步`
  - `测试下载/探测`（跑 probe，输出摘要，不落库）

URI 导入 Tab：

- 一个 textarea（填 `ss:// ssr:// vmess:// vless:// trojan:// hy2:// hysteria2:// tuic:// naive+https:// naive+quic://` 等）
- 按钮：
  - `解析并保存为节点`（保持现有能力）
- 可选增强：
  - 解析摘要（成功/失败数量）
  - 失败行原因（折叠展示）

### 6.3 升级迁移策略（不做旧版长期兼容）

原则：

- 不保留旧 `ss_online_links` 作为长期入口
- 在插件升级/安装阶段做一次性迁移：把 `ss_online_links` 中的订阅链接拆成独立 profile

迁移输入：

- `ss_online_links`（base64 解码后的原始文本）
- 全局订阅设置（用于生成 profile 初始默认值），例如：
  - `ss_basic_online_ua`
  - `ss_basic_online_links_proxy`
  - `ss_basic_exclude / ss_basic_include`
  - `ss_basic_sub_ai / ss_basic_hy2_* / ss_basic_sub_keep_info_node` 等

迁移规则（建议）：

- 仅提取 `https://` 链接（与现有做法一致也可放宽到 `http(s)://`，以实现时为准）
- 每个链接生成一个 profile：
  - `id = random_hex_id()`
  - `name`（别名）：
    - 优先：根据 URL host 走现有映射文件（例如 `node-tool.conf` 的 `domain -> label`）
    - 其次：host 本身（去掉常见前缀）
    - 如发生重名：自动追加 `-<id4>` 后缀保证唯一
  - 其余字段按全局设置填充到 profile
- 迁移完成后：
  - 清空/移除 `ss_online_links`
  - 前端不再渲染旧 textarea
  - “订阅计划任务”建议保留为全局：执行 `sync all profiles`

---

## 7. 迭代拆分（推荐优先级）

P0（打基础，风险低）：

- 升级迁移：`ss_online_links` -> profiles（并清理旧字段，前端移除旧 textarea）
- 引入 profile 文件存储与 CRUD 脚本
- 前端 `订阅管理` UI（先能增删改查 + 手工同步）
- 后端按 profile 逐个订阅（仍复用 curl/wget 单次下载，不做并发 UA 探测）

P1（性能关键，按需落地）：

- `sub-tool probe-ua`（或独立工具）支持 batch plan 并发下载
- 结果写入 `state.json`，后续订阅直接复用
- 不做自动 curl 回退（失败就是失败，UI/日志应可解释）

P2（能力扩展）：

- profile 级别更多参数落地：per-profile allow-insecure/tfo 等默认覆盖策略
- SSEP、更多订阅格式、订阅 diff 更深集成

---

## 8. 风险与验证清单

必须提前验证：

- Zig https 在目标平台（armv7/aarch64）对常见机场订阅站点的兼容性
- socks5 + https（TLS over socks5）的稳定性
- redirect（3xx）与 HTML redirect（sub-tool inspect 提取 redirect_url）的兼容性
- 并发上限在弱机型上的 CPU 峰值（parallelism 默认值要保守）

失败处理与人工介入策略：

- UA auto probe 失败：允许用户切到 fixed，或调整候选与下载策略（direct/proxy/auto）
