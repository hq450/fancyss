# fancyss 节点数据结构重构设计

## 1. 文档目的

本文用于规划 fancyss 节点数据从当前的“多 KV 平铺结构”升级到“对象化节点存储结构”的完整方案，重点覆盖：

- 当前节点数据结构的现状与痛点
- 新节点数据结构的设计目标
- 新旧结构的兼容与迁移
- 前端/后端/API 的改造方向
- 回退旧版本时的兼容策略

本文只做设计，不涉及当前代码修改。

如果要继续推进实现层，请同时参考：`doc/implementation/node_data_storage_refactor_spec.md`。

---

## 2. 当前实现概览

### 2.1 当前节点存储方式

当前每个节点按字段平铺到 skipdb/dbus 中，格式类似：

```sh
ssconf_basic_name_1=LA-xhttp_reality_2
ssconf_basic_server_1=la.sadog.me
ssconf_basic_port_1=443
ssconf_basic_type_1=4
ssconf_basic_xray_uuid_1=...
ssconf_basic_xray_network_1=xhttp
ssconf_basic_xray_network_path_1=/bnojblqc
...
```

节点的“身份”和“顺序”耦合在一起：

- `1`、`2`、`3` 既是节点序号，也是节点主键
- 当前选中的节点为 `ssconf_basic_node=<序号>`
- 备用节点等也通过“序号”关联

### 2.2 当前前后端读取方式

- 前端页面通过 `/_api/ss` 一次性拉取所有 `ss*` 相关 KV
- 前端自行扫描 `ssconf_basic_name_*`，再从 `db_ss` 中拼出每个节点对象
- 后端脚本通过 `ss_base.sh` 读取 `ssconf_basic_node` 对应的所有字段，再导出为 `ss_basic_*` 环境变量

### 2.3 当前节点数据的中间形态

订阅脚本已经内置一套“节点对象化中间态”：

- `skipdb2json()`：把平铺 KV 聚合成“一节点一行 JSON”
- `json2skipd()`：再把一行 JSON 写回旧式 `ssconf_basic_*` KV

这说明 fancyss 代码已经天然具备“节点对象化”的中间桥梁。

---

## 3. 当前结构的主要问题

### 3.1 KV 数量膨胀

以当前 `ss_base.sh` 中定义的字段为例，单节点可涉及约 88 个字段。

如果节点数较多：

- 100 个节点：理论上可达约 8800 个节点相关 KV
- 300 个节点：理论上可达约 26400 个节点相关 KV

虽然实际不会每个字段都非空，但数量级已经很大。

### 3.2 前端加载成本高

当前节点列表页需要：

1. 拉取整份 `/_api/ss`
2. 扫描所有 `ssconf_basic_name_*`
3. 对每个节点逐字段组装对象
4. 某些节点类型还要额外解析 `xray_json` / `v2ray_json` / `tuic_json`

节点越多，前端初始化越重。

### 3.3 拖动排序 / 删除成本极高

当前删除和拖动排序的处理方式是：

- 先把所有节点所有字段标记为空
- 再按新顺序把全部节点全部字段重写一遍

即使只是“节点 5 和节点 6 交换位置”，本质上也是一次全量重写。

### 3.4 字段定义分散且重复维护

当前节点字段列表在多个文件中重复维护，例如：

- `fancyss/scripts/ss_base.sh`
- `fancyss/scripts/ss_node_subscribe.sh`
- `fancyss/webs/Module_shadowsocks.asp`

新增协议字段时，需要同步改多处，维护成本高，容易漏。

### 3.5 节点顺序与节点身份耦合

这是当前结构最根本的问题。

节点“序号”既是：

- 前端表格顺序
- 当前节点索引
- 删除/拖动时的主键
- 旧版本兼容映射基础

这导致：

- 排序必须重排数据
- 删除必须整体搬迁
- 后续引入新 API / 新缓存 / 新状态字段都很别扭

---

## 4. 是否有必要升级节点数据结构

结论：**有必要**。

原因不是 skipdb 一定承载不了，而是当前结构已经开始限制 fancyss 的演进：

- 前端渲染效率越来越受节点数量影响
- 节点管理动作（删除、拖动）代价过高
- 新协议持续增加，字段平铺维护越来越重
- 现有 `/_api/ss` 过大，职责混杂
- 订阅/测速/状态/导入导出都需要重复做“字段聚合/拆分”

如果 fancyss 后续还会继续增加协议、优化前端、加强导入导出和订阅，那么节点对象化是值得做的一次基础设施升级。

---

## 5. 重构目标

### 5.1 主要目标

- 一个节点尽可能用一个 KV 表示
- 节点身份与显示顺序解耦
- 节点列表加载不再依赖 `/_api/ss`
- 前后端围绕统一节点对象工作
- 新增协议时不再需要到处补字段平铺逻辑
- 保证对旧版本有明确、可操作的回退路径

### 5.2 非目标

- 本次不同时重构 ACL / 全局设置
- 不要求旧版本 fancyss 原生识别新数据
- 不要求长期双写新旧两套 live 数据

---

## 6. 推荐的新结构

## 6.1 核心设计原则

推荐同时完成三件事：

1. 节点对象化
2. 节点 ID 稳定化
3. 节点顺序独立存储

如果只做“单节点单 KV”，但不做“稳定 ID + 顺序分离”，收益是不完整的。

---

## 6.2 推荐前缀设计

**不建议**继续使用 `ss_node_*` 作为新节点前缀。

原因：

- 前端当前大量使用 `/_api/ss`
- 如果新节点前缀仍以 `ss` 开头，那么它们仍会被 `/_api/ss` 拉回
- 无法真正达到“节点数据独立拉取”的目的

因此推荐新节点使用独立前缀，例如：

```sh
fss_data_schema=2
fss_node_next_id=159
fss_node_order=1,2,5,9,12
fss_node_current=2
fss_node_failover_backup=12
fss_node_1=<base64-json>
fss_node_2=<base64-json>
...
```

说明：

- `fss_` 不会被 `/_api/ss` 误拉取
- 前端可独立通过 `/_api/fss_node` 获取节点 blob
- 旧的 `ss_*` 继续用于全局设置

---

## 6.3 节点主键与顺序

### 节点主键

建议使用稳定递增 ID，而不是“当前顺序号”：

- 新增节点时分配 `fss_node_next_id`
- 已存在节点的 ID 永不因为拖动/删除而变化

### 节点顺序

单独存：

```sh
fss_node_order=7,3,15,2,21
```

### 当前节点

单独存：

```sh
fss_node_current=15
```

### 备用节点

原来的 `ss_failover_s4_3` 本质上也是“节点引用”，建议后续迁移为：

```sh
fss_node_failover_backup=21
```

旧版本兼容导出时，再动态映射回旧的“顺序号”。

---

## 6.4 节点对象结构

推荐节点对象使用 **结构化 JSON**，而不是简单把旧字段原样平铺进一个大对象。

建议结构如下：

```json
{
  "schema": 2,
  "id": "158",
  "type": "vless",
  "name": "LA-xhttp_reality_2",
  "group": "Nexitally_abcd",
  "mode": "2",
  "server": "la.sadog.me",
  "port": "443",
  "summary": {
    "display_type": "Vless",
    "display_server": "la.sadog.me",
    "display_group": "Nexitally"
  },
  "proto": {
    "engine": "xray",
    "transport": "xhttp",
    "uuid": "881796b3-e86e-455b-80a4-5fdc389f6e8d",
    "encryption": "none",
    "flow": "",
    "path": "/bnojblqc",
    "host": "",
    "security": {
      "type": "reality",
      "sni": "tesla.com",
      "fingerprint": "chrome",
      "public_key": "zPIYxUpZMmyY67ix6MqxIDzHzdkUai812Lcx5ZG_y14",
      "short_id": "f0",
      "spider_x": "/",
      "allow_insecure": false,
      "pinned_peer_cert_sha256": "",
      "verify_peer_cert_by_name": ""
    },
    "xhttp_mode": "auto"
  },
  "raw": {
    "use_json": false,
    "config_type": "",
    "config": ""
  },
  "meta": {
    "created_by": "manual",
    "source": "",
    "updated_at": 1770000000
  }
}
```

### 设计原则

- 顶层放公共字段：`id/type/name/group/mode/server/port`
- 协议相关放入 `proto`
- 自定义 JSON 放入 `raw`
- UI 展示所需字段放入 `summary`
- 来源、更新时间等放入 `meta`

### 是否还要继续单独 base64 密码 / JSON

**不建议。**

新结构整体已经会做一次 base64 编码，因此：

- `password`
- `xray_json`
- `v2ray_json`
- `tuic_json`

这些旧时代需要单独 base64 的字段，在新结构中可以直接存原文字符串。

好处：

- 降低多层编码复杂度
- 减少前后端反复 decode/encode
- 兼容导出到旧格式时再做一次映射编码即可

---

## 6.5 节点存储值格式

推荐：

```sh
fss_node_158=$(echo -n '<compact-json>' | base64)
```

原因：

- 避免引号、换行、特殊字符污染 dbus
- shell 中处理更稳定
- 前后端都容易统一

---

## 7. API 设计

## 7.1 新的节点拉取方式

推荐新增独立节点 API 前缀：

- `/_api/fss_node`：返回所有节点 blob
- `/_api/fss_data`：返回元信息（如果需要）

示意：

```json
{
  "result": [
    {
      "fss_node_1": "eyJzY2hlbWEiOjIsLi4ufQ==",
      "fss_node_2": "eyJzY2hlbWEiOjIsLi4ufQ==",
      "fss_node_order": "1,2,5,9",
      "fss_node_current": "2"
    }
  ]
}
```

前端收到后再统一 decode 成节点对象数组。

---

## 7.2 前端加载拆分建议

当前 `/_api/ss` 过大，后续推荐拆分：

- `/_api/ss_basic`：基础设置
- `/_api/ss_failover`：故障转移
- `/_api/ss_wan`：黑白名单
- `/_api/ss_online`：订阅相关
- `/_api/ss_acl`：ACL（已独立）
- `/_api/fss_node`：节点数据

第一阶段也可以保守处理：

- 保持 `/_api/ss` 不动
- 节点列表页和编辑页优先改走 `/_api/fss_node`

这样风险更低。

---

## 7.3 列表与详情分层

建议在节点对象层面做“summary/detail”分层。

### 列表页只依赖 summary

例如：

- 名称
- 协议类型
- server 展示
- group 展示
- 是否 json 节点

### 编辑页才加载 detail

对于大字段，例如：

- `raw.config`
- `tuic` 大 JSON

可以在后续版本考虑拆分为：

- `fss_node_<id>`：常规节点对象
- `fss_node_raw_<id>`：大 JSON 负载

这样列表页无需解码大块原始 JSON。

**建议：**

- 第一版先不强制拆分 raw
- 但对象结构中预留 `raw` 区域
- 如果后续证明自定义 JSON 节点过多导致前端仍偏重，再做第二步拆分

---

## 8. 后端脚本改造方向

## 8.1 `ss_base.sh`

当前 `ss_base.sh` 的职责：

1. 读取全局 `ss_*`
2. 读取当前节点的平铺字段
3. 导出 `ss_basic_*` 环境变量

新结构下建议改为：

1. 继续读取全局 `ss_*`
2. 读取 `fss_node_current`
3. 读取 `fss_node_<id>` 并 decode JSON
4. 通过统一 mapping 导出兼容的 `ss_basic_*`

这样其他脚本基本不需要一次性重写。

### 关键原则

新存储结构是新的“真实来源”，但 `ss_base.sh` 继续对下游脚本暴露旧风格环境变量。

这样可以显著降低首轮重构风险。

---

## 8.2 统一节点读写 helper

推荐新增一层公共 helper，例如：

```sh
node_get_blob <id>
node_get_json <id>
node_set_json <id> <json>
node_list_ids
node_current_id
node_order_list
node_to_legacy_env <id>
legacy_kv_to_node_json <legacy_json_line>
```

实现后：

- 订阅脚本
- 手动添加
- 删除节点
- 节点排序
- 导出配置
- 测速

都可以围绕这层统一 helper 运行。

---

## 9. 前端改造方向

## 9.1 节点列表页

当前逻辑：

- 扫描 `db_ss`
- 找 `ssconf_basic_name_*`
- 拼 `confs`

新逻辑：

- 从 `/_api/fss_node` 取节点 blob
- decode 为 `nodes[]`
- 用 `fss_node_order` 排序
- 直接渲染

### 直接收益

- 不再依赖大规模字段拼装
- 节点类型扩展时前端字段表不需要到处同步

---

## 9.2 拖动排序

当前：

- 清空全部旧节点字段
- 按顺序全量重写

新结构：

- 只修改 `fss_node_order`

这是本次重构最直接、最确定的性能收益点。

---

## 9.3 删除节点

当前：

- 删除一个节点，仍要整体搬迁剩余节点序号

新结构：

- 删除 `fss_node_<id>`
- 从 `fss_node_order` 中移除该 id
- 如果删除的是当前节点，再选择新的 `fss_node_current`

同样无需整体重排。

---

## 10. 迁移设计

## 10.1 迁移触发条件

升级到支持新节点结构的 fancyss 版本后，如果同时满足：

- `fss_data_schema` 不存在
- 存在旧节点 `ssconf_basic_name_*`

则触发一次迁移。

---

## 10.2 迁移中间态

迁移不建议直接从分散 KV 到新结构硬拼。

推荐复用现有订阅脚本中的中间态：

1. 先运行类似 `skipdb2json()` 的逻辑
2. 得到“一节点一行 JSON”的旧结构中间态
3. 再把每一行转换为新的 `fss_node_<id>`

这是当前代码里最成熟、最稳的桥梁。

---

## 10.3 迁移步骤

建议迁移流程如下：

1. 检测到需要迁移
2. 生成“迁移时旧版本快照”：
   - 生成 `legacy_migration_<timestamp>.sh`
3. 读取当前旧节点，聚合成一行 JSON
4. 为每个节点分配稳定新 ID
5. 写入：
   - `fss_node_<id>`
   - `fss_node_order`
   - `fss_node_current`
   - `fss_node_failover_backup`（如适用）
6. 校验：
   - 节点数一致
   - 当前节点映射正确
   - 至少一个节点可成功 decode
7. 写入迁移标记：
   - `fss_data_schema=2`
   - `fss_data_migrated=1`
   - `fss_data_migration_notice=1`
   - `fss_data_legacy_snapshot=<path>`
8. 删除旧 `ssconf_basic_*`

### 注意

删除旧 `ssconf_basic_*` 必须放在最后一步，并且仅在新结构写入和校验成功后执行。

---

## 11. 兼容与回退策略

这是本设计最关键的部分。

## 11.1 为什么单纯“迁移时生成一次旧备份”不够

如果只在升级当时生成一次旧版本备份：

- 用户后续在新版本上添加了节点、修改了节点
- 再想回退时，这份旧备份已经过期

因此，必须区分两种兼容备份：

### A. 迁移时旧版本快照

用途：

- 保留用户升级前的那一刻配置
- 作为保底回滚材料

### B. 按当前新数据实时生成的旧版本兼容备份

用途：

- 用户已经在新版本继续使用、继续添加/修改节点
- 希望随时导出一个“老版本可恢复”的配置

这正是你提出的“映射表导出旧格式”的思路，**这是正确且必须的。**

---

## 11.2 推荐的兼容策略

### 兼容策略 A：迁移时自动快照

升级迁移时自动生成：

```sh
/koolshare/configs/fancyss/migration/legacy_migration_20260320_120000.sh
```

特点：

- 只反映迁移那一刻的旧数据
- 不会包含迁移后新增/修改的内容

### 兼容策略 B：长期支持“导出旧版本兼容配置”

新版本前端增加一个导出入口：

- 下载新版本原生备份（JSON）
- 下载旧版本兼容备份（SH）

其中“旧版本兼容备份（SH）”不再直接 `dbus list ss` 导出，而是：

1. 读取当前 `fss_node_*`
2. 按 `fss_node_order` 重新生成旧格式的连续顺序号
3. 用映射表导出为 `ssconf_basic_*_<n>`
4. 再生成传统的 `dbus set ...` shell 文件

这样即使用户在新版本上继续改过节点，依然可以随时拿到一个老版本可恢复的配置。

---

## 11.3 推荐前端提示

当检测到本次是“首次迁移到新节点结构”时，前端弹窗提示一次：

建议内容：

1. 当前版本已完成节点数据结构升级
2. 老版本 fancyss 无法直接识别新节点结构
3. 如果未来需要回退旧版本：
   - 推荐回退后全新配置
   - 如需保留当前配置，请先下载“旧版本兼容备份”
4. 同时提供两个按钮：
   - 下载迁移时旧版本快照
   - 下载当前配置的旧版本兼容备份

弹窗显示一次后，写 `fss_data_migration_notice=0`。

---

## 11.4 新版本原生备份格式

推荐新增正式 JSON 备份格式：

```json
{
  "format": "fancyss-backup",
  "schema_version": 2,
  "created_at": "2026-03-20T12:00:00+08:00",
  "plugin_version": "3.6.0",
  "global": {
    "...": "..."
  },
  "nodes": [
    { "...": "..." }
  ],
  "node_order": ["7", "3", "15"],
  "node_current": "15",
  "acl": {
    "...": "..."
  }
}
```

### 恢复原则

- 新版本支持恢复 JSON
- 新版本也支持恢复旧 SH
- 旧版本仍只支持 SH

---

## 11.5 旧格式导出映射原则

从新结构导出旧结构时，核心规则如下：

### 顺序映射

新结构：

```sh
fss_node_order=7,3,15
fss_node_current=15
```

导出旧格式时，需要生成：

```sh
ssconf_basic_node=3
```

因为 `15` 在顺序数组里的位置是第 3 个。

### 节点字段映射

例如某个新结构节点：

```json
{
  "type": "vless",
  "name": "LA",
  "server": "la.example.com",
  "port": "443",
  "proto": {
    "uuid": "...",
    "transport": "ws",
    "path": "/ws",
    "host": "host.example.com",
    "security": {
      "type": "tls",
      "sni": "host.example.com",
      "fingerprint": "chrome"
    }
  }
}
```

导出旧格式时应映射为：

```sh
ssconf_basic_type_1=4
ssconf_basic_name_1=LA
ssconf_basic_server_1=la.example.com
ssconf_basic_port_1=443
ssconf_basic_xray_prot_1=vless
ssconf_basic_xray_uuid_1=...
ssconf_basic_xray_network_1=ws
ssconf_basic_xray_network_path_1=/ws
ssconf_basic_xray_network_host_1=host.example.com
ssconf_basic_xray_network_security_1=tls
ssconf_basic_xray_network_security_sni_1=host.example.com
ssconf_basic_xray_fingerprint_1=chrome
```

这正是你提到的：

- `ss_node_current -> ssconf_basic_node`
- `proto.uuid -> ssconf_basic_xray_uuid`

这条思路完全正确，且应当成为长期兼容机制的一部分。

---

## 11.6 导入/恢复的判定方式

**不建议主要依赖 fancyss 版本号判断导入逻辑。**

更稳的做法应当是“按备份文件自身格式判定”：

- 如果是新结构原生备份：
  - 文件里带 `schema_version=2`
  - 走 `fss_*` 恢复路径
- 如果是旧版本兼容备份：
  - 本质是传统 `dbus set ss...` / `dbus set ssconf_basic...` shell
  - 走旧结构恢复路径

原因：

- 版本号不一定严格等价于数据结构版本
- 后续如果有测试版 / 分支版，纯按版本号判断容易出错
- 用备份文件格式自身做判定，恢复逻辑更稳定

也就是说，导出和恢复时应该优先看：

- `backup format`
- `schema version`
- 文件头标识

而不是优先看“当前 fancyss 是不是小于某个版本”。

---

## 11.7 是否要做“一个文件同时兼容新旧版本”

从技术上说，可以生成一个自包含的 `.sh` 文件，里面既携带新结构节点 JSON，也携带旧结构映射逻辑，执行时再判断当前环境应该写入哪种格式。

**但不建议把它作为主方案。**

原因：

- 这个文件会同时承载：
  - 备份数据
  - 格式探测逻辑
  - 新旧两套恢复逻辑
- 复杂度高，后续维护成本大
- 一旦恢复脚本里有 bug，排查难度明显高于“单一格式单一路径”
- 旧版本 fancyss 本身并不知道新结构，最终仍然需要在导出阶段先投影成旧格式

因此更推荐的主方案仍然是：

### A. 新版本原生备份

- 格式：JSON
- 作用：完整保留新结构信息
- 恢复目标：新版本 fancyss

### B. 旧版本兼容备份

- 格式：传统 `.sh`
- 作用：把当前新结构数据实时映射成旧结构
- 恢复目标：旧版本 fancyss

### C. 迁移时旧版本快照

- 格式：传统 `.sh`
- 作用：保留升级当时的原始旧数据
- 恢复目标：兜底回滚

如果后续要进一步优化用户体验，可以考虑提供一个“组合下载包”：

- `backup_v2.json`
- `backup_legacy.sh`
- `migration_legacy_snapshot.sh`
- `manifest.txt`

但不建议一开始就把三者揉成一个智能脚本。

---

## 11.8 兼容导出的长期机制

用户的关键诉求是：

- 升级完成后，继续在新版本里新增节点、修改节点
- 之后如果想回退旧版本，仍希望把“当前这份最新配置”带回去

因此旧版本兼容导出不能只是一次性的迁移附件，而必须是一个**长期能力**。

也就是说：

1. 迁移时自动生成一份旧快照
2. 新版本后续任意时刻，都能从当前 `fss_*` 实时生成一份最新的旧格式导出

这是兼容策略里不可省略的一层。

---

## 12. 映射表设计建议

## 12.1 不建议把映射散落在多个脚本里

旧结构最大问题之一，就是字段定义散落。

因此新结构落地时，建议引入一份唯一映射表定义，例如：

```sh
NODE_FIELD_MAP_V1_V2
NODE_FIELD_MAP_V2_V1
```

或者一份 JSON/YAML 描述文件，由脚本和前端共用生成。

### 目的

- 新旧导出/导入逻辑统一
- `ss_base.sh` 的兼容导出统一
- 订阅脚本和恢复脚本共享同一套映射

---

## 12.2 映射粒度建议

建议分层：

### 公共字段

- `name`
- `group`
- `mode`
- `server`
- `port`
- `type`

### 协议字段

- SS / SSR
- V2Ray
- Xray / VLESS / VMess
- Trojan
- Naive
- Tuic
- Hysteria2

### 特殊字段

- `password`
- `raw.config`
- `summary`
- `meta`

其中：

- `summary`
- `meta`

属于新结构增强信息，不需要导出到旧结构。

---

## 13. 推荐分阶段实施路线

## 第 1 阶段：建立节点对象 helper 与导出能力

目标：

- 定义新 schema
- 定义新旧映射表
- 实现新结构 <-> 旧结构互转
- 增加“导出旧版本兼容配置”

此阶段不一定立即切换实际存储。

### 收益

- 先把最难的兼容层打好
- 后续迁移风险显著下降

---

## 第 2 阶段：引入新节点存储并迁移

目标：

- install/upgrade 时自动迁移
- 前端增加迁移提示弹窗
- 节点数据写入改走新结构

---

## 第 3 阶段：切换前端节点页到独立节点 API

目标：

- 节点列表页不再依赖 `/_api/ss`
- 节点拖动/删除彻底改为基于 `fss_node_order`

---

## 第 4 阶段：逐步让下游脚本改用 node helper

目标：

- 订阅
- 测速
- 状态脚本
- 导入导出

最终逐步减少脚本内部对旧平铺字段的直接依赖。

---

## 14. 本设计的主要收益

### 明确收益

- 节点数量越多，前端渲染收益越明显
- 拖动排序从“全量重写节点字段”降为“只改顺序列表”
- 删除节点从“整体搬迁”降为“删一个 blob + 更新顺序”
- 新增协议更容易
- 导出/恢复体系更清晰

### 中长期收益

- 节点对象 schema 成为协议扩展基座
- 可以逐步引入更清晰的 runtime/cache/state 结构
- 可以考虑后续加入节点标签、来源、更新时间、统计等元信息

---

## 15. 风险与注意事项

### 15.1 最大风险：旧版本无法直接识别新结构

这是无法彻底消除的，只能通过：

- 迁移提示
- 自动快照
- 长期支持旧格式兼容导出

来解决。

### 15.2 不建议长期双写

即每次改节点时同时写：

- `fss_node_*`
- `ssconf_basic_*`

不推荐。

原因：

- 又把 KV 数量写回来了
- 复杂度非常高
- 容易出现双写不一致

建议采用：

- **新结构单写**
- **兼容备份按需导出**

---

## 16. 最终建议

综合考虑收益、风险和兼容性，推荐最终方案为：

### 推荐方案

1. 新节点前缀使用独立命名空间：`fss_node_*`
2. 节点使用稳定 ID
3. 顺序单独存 `fss_node_order`
4. 当前节点单独存 `fss_node_current`
5. 节点对象使用结构化 JSON，并整体 base64
6. 升级时自动迁移，并生成一次“迁移时旧版本快照”
7. 新版本长期支持“按当前数据实时导出旧版本兼容备份”
8. 前端迁移后弹窗提醒用户新旧结构差异

### 不推荐方案

- 仅仅把 `ssconf_basic_*` 改成 `ss_node_1`、`ss_node_2`
- 但仍继续使用“顺序号 = 节点主键”

这个方案只能减少 KV 数量，但不能真正解决拖动/删除/兼容导出等核心问题。

---

## 17. 一句话总结

这次重构真正值得做的，不是“把 88 个 KV 变成 1 个 KV”本身，而是借此机会把节点从“平铺字段 + 顺序号主键”升级为“对象化节点 + 稳定 ID + 独立顺序 + 可持续兼容导出”的新体系。
