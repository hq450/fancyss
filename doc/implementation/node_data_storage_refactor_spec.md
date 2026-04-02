# fancyss 节点数据结构重构实施规格（v2）

## 1. 文档目标

本文是在 `doc/design/node_data_storage_refactor_design.md` 的基础上，进一步给出可以直接落地的实施规格，回答以下问题：

- 新节点数据到底存成什么样
- 新旧字段如何一一映射
- 迁移时如何做事务、校验和回滚
- 前端、后端、备份、恢复各自如何切换
- 如何长期兼容旧版本，而不是只兼容升级当时那一刻

本文仍然不直接修改代码，但默认后续实现将按本文规格推进。

---

## 2. 落地原则

## 2.1 这次重构真正要解决的问题

本次不是单纯把“一个节点 80+ 个 KV”压缩成“一个节点 1 个 KV”。

真正要一次解决的，是四件事：

1. 节点配置对象化
2. 节点身份与顺序解耦
3. 节点加载从 `/_api/ss` 中拆出去
4. 长期提供旧版本兼容导出能力

---

## 2.2 首轮落地采用“扁平字段 JSON + 保留元字段”

概念设计里，节点对象可以做成更语义化的嵌套结构，例如 `proto/security/raw/meta`。

**但首轮真正落地时，不建议直接走完全语义化嵌套。**

原因很现实：

- 当前前端、订阅脚本、`ss_base.sh`、`ssconfig.sh`、测速脚本，大量逻辑都是围绕旧字段名工作的
- 如果首轮就把字段彻底改成新语义层级，改动范围会从“存储升级”扩大成“全仓节点逻辑重写”
- 这会显著放大迁移风险，也会让兼容导出逻辑变复杂

因此首轮推荐使用：

- **独立键空间**：`fss_*`
- **稳定节点 ID**
- **独立顺序表**
- **节点值为一个 compact JSON**
- **JSON 内部仍沿用旧字段名作为主字段**
- **保留 `_schema/_id/_rev/_updated_at/_source` 等保留元字段**

这样做的好处是：

- 迁移实现成本最低
- 前后端现有字段数组大部分可以复用
- 新旧导出映射几乎是规则化转换，而不是大规模手工翻译
- 后续如果要继续升级为更语义化 schema，可以在 `schema=3` 再做

结论：

**v2 落地采用“对象化存储 + 扁平字段载荷”，而不是一步到位做深层语义化对象。**

---

## 2.3 节点配置与节点状态分离

节点配置是“用户设置”，例如：

- `server`
- `port`
- `xray_uuid`
- `tuic_json`

节点状态是“运行时/缓存信息”，例如：

- `latency`
- `server_ip`
- `ping`

**v2 首轮只迁移节点配置，不把运行态字段并入节点主存储。**

原因：

- 节点配置很稳定，适合一节点一 blob
- 运行态经常变化，如果和主配置写在一起，会导致频繁重写整个 blob
- 运行态天然不适合进入“旧版本兼容导出”

因此：

- `fss_node_<id>`：只放节点配置
- 运行态先继续保持现状，或后续单独引入 `fss_node_state_<id>`
- `server_ip/latency/ping` 不列入 v2 节点配置 schema

---

## 3. 新键空间定义

## 3.1 元信息键

```sh
fss_data_schema=2
fss_data_migrated=1
fss_data_migration_notice=1
fss_data_migration_time=20260320_120000
fss_data_legacy_snapshot=/koolshare/configs/fancyss/migration/legacy_migration_20260320_120000.sh
```

说明：

- `fss_data_schema`：当前节点数据结构版本
- `fss_data_migrated`：是否已经完成旧结构迁移
- `fss_data_migration_notice`：前端是否还需要弹升级提醒
- `fss_data_migration_time`：首次迁移时间
- `fss_data_legacy_snapshot`：升级当时生成的旧版本快照路径

---

## 3.2 节点索引与引用键

```sh
fss_node_next_id=159
fss_node_order=101,102,108,115
fss_node_current=102
fss_node_failover_backup=115
```

说明：

- `fss_node_next_id`：下一个可分配稳定 ID
- `fss_node_order`：节点显示顺序，值为稳定 ID 列表
- `fss_node_current`：当前正在使用的节点稳定 ID
- `fss_node_failover_backup`：故障转移备用节点稳定 ID

注意：

- 这里的值都不再是“列表位置”，而是稳定 ID
- 节点排序、删除、插入，都只修改 `fss_node_order`，不会再重排节点实体

---

## 3.3 节点实体键

```sh
fss_node_101=<base64-compact-json>
fss_node_102=<base64-compact-json>
fss_node_108=<base64-compact-json>
```

节点值统一格式：

- JSON：单行、紧凑、UTF-8
- 外层：base64
- 内层：不再对 `password/xray_json/tuic_json` 做二次 base64

---

## 3.4 预留键

首轮不强制实现，但保留命名空间：

```sh
fss_node_state_<id>
fss_node_tag_<id>
fss_node_stats_<id>
```

后续如果要把测速缓存、解析 IP、节点标签等从现有散乱逻辑中拆出去，直接接这个命名空间即可。

---

## 4. v2 节点 JSON 规格

## 4.1 JSON 总体结构

示例：

```json
{
  "_schema": 2,
  "_id": "102",
  "_rev": 1,
  "_source": "manual",
  "_updated_at": 1770000000,
  "type": "4",
  "name": "LA-xhttp_reality_2",
  "group": "Nexitally_abcd",
  "mode": "2",
  "server": "la.sadog.me",
  "port": "443",
  "xray_prot": "vless",
  "xray_uuid": "881796b3-e86e-455b-80a4-5fdc389f6e8d",
  "xray_encryption": "none",
  "xray_network": "xhttp",
  "xray_network_path": "/bnojblqc",
  "xray_network_security": "reality",
  "xray_network_security_sni": "tesla.com",
  "xray_fingerprint": "chrome",
  "xray_publickey": "zPIYxUpZMmyY67ix6MqxIDzHzdkUai812Lcx5ZG_y14",
  "xray_shortid": "f0",
  "xray_spiderx": "/",
  "xray_xhttp_mode": "auto"
}
```

---

## 4.2 保留元字段

所有以 `_` 开头的字段都是保留字段，不参与旧结构直写映射：

- `_schema`
- `_id`
- `_rev`
- `_source`
- `_source_url`
- `_updated_at`
- `_created_at`
- `_migrated_from`

首轮强制字段：

- `_schema`
- `_id`
- `_rev`
- `_source`
- `_updated_at`

建议值：

- `_schema=2`
- `_rev=1`
- `_source=manual|subscribe|import|migration`

---

## 4.3 字段值规范

### 一律使用字符串

除保留元字段外，所有业务字段统一存成字符串。

这样做的原因：

- shell 最稳
- dbus 导入导出最稳
- 现有前端表单值本来就是字符串
- 避免布尔、数字在 shell/JS/jq 三端出现类型歧义

### 布尔统一规范化为 `0/1`

v2 中以下布尔字段建议统一存成：

- `"1"`：开启
- `"0"`：关闭

不再使用旧结构里混杂的“空字符串/缺失/1”。

### 敏感字段存原文

以下字段在 v2 内部存原文：

- `password`
- `naive_pass`
- `v2ray_json`
- `xray_json`
- `tuic_json`

因为整个节点值本身已经做了 base64 包装。

### 不存运行态字段

以下字段不进入 v2 节点配置：

- `server_ip`
- `latency`
- `ping`

---

## 4.4 v2 节点字段清单

### 公共字段

```text
name group type mode server port
```

### SS / SSR 相关字段

```text
method password ss_obfs ss_obfs_host
rss_protocol rss_protocol_param rss_obfs rss_obfs_param
```

### V2Ray 相关字段

```text
v2ray_use_json v2ray_uuid v2ray_alterid v2ray_security v2ray_network
v2ray_headtype_tcp v2ray_headtype_kcp v2ray_kcp_seed
v2ray_headtype_quic v2ray_grpc_mode
v2ray_network_path v2ray_network_host
v2ray_network_security v2ray_network_security_ai
v2ray_network_security_alpn_h2 v2ray_network_security_alpn_http
v2ray_network_security_sni
v2ray_mux_enable v2ray_mux_concurrency
v2ray_json
```

### Xray / VLESS / VMess / JSON 相关字段

```text
xray_use_json xray_uuid xray_alterid xray_prot xray_encryption xray_flow
xray_network xray_headtype_tcp xray_headtype_kcp xray_kcp_seed
xray_headtype_quic xray_grpc_mode xray_xhttp_mode
xray_network_path xray_network_host
xray_network_security xray_network_security_ai
xray_network_security_alpn_h2 xray_network_security_alpn_http
xray_network_security_sni
xray_pcs xray_vcn
xray_fingerprint xray_show xray_publickey xray_shortid xray_spiderx
xray_json
```

### Trojan 相关字段

```text
trojan_ai trojan_uuid trojan_sni trojan_tfo
trojan_plugin trojan_obfs trojan_obfshost trojan_obfsuri
trojan_pcs trojan_vcn
```

### Naive 相关字段

```text
naive_prot naive_server naive_port naive_user naive_pass
```

### TUIC 相关字段

```text
tuic_json
```

### Hysteria2 相关字段

```text
hy2_server hy2_port hy2_pass hy2_up hy2_dl
hy2_obfs hy2_obfs_pass hy2_sni
hy2_pcs hy2_vcn hy2_ai hy2_tfo hy2_cg
```

### 兼容保留字段（仅为导入/导出保留）

```text
koolgame_udp use_kcp use_lb lbmode weight
```

这些字段首轮可以继续进入 v2 payload，以保证老配置导入后不丢值；
但新前端不再主动生成这些字段。

---

## 5. 新旧映射规则

## 5.1 顺序与引用映射

假设：

```sh
fss_node_order=101,102,108,115
fss_node_current=108
fss_node_failover_backup=115
```

则导出旧结构时：

```sh
ssconf_basic_node=3
ss_failover_s4_3=4
```

即：

- 旧结构里所有“节点引用值”，都必须通过 `fss_node_order` 投影为连续顺序号
- 老版本永远只看到 `1..n`

---

## 5.2 字段映射总原则

### 原则 1：绝大多数字段是同名直映射

例如：

```text
v2.name                    -> ssconf_basic_name_<n>
v2.server                  -> ssconf_basic_server_<n>
v2.xray_uuid               -> ssconf_basic_xray_uuid_<n>
v2.hy2_sni                 -> ssconf_basic_hy2_sni_<n>
```

### 原则 2：保留元字段不导出到旧结构

例如：

```text
_schema _id _rev _source _updated_at
```

### 原则 3：少数字段需要编解码转换

见下一节。

---

## 5.3 特殊转换字段

### 旧 -> 新：需要 decode

以下旧字段原来在 dbus 中是 base64，需要迁移时 decode 成原文：

```text
password
naive_pass
v2ray_json
xray_json
tuic_json
```

### 新 -> 旧：需要 encode

旧版本兼容导出时，这些字段要重新编码回旧结构：

```text
password        -> Base64.encode(value)
naive_pass      -> Base64.encode(value)
v2ray_json      -> Base64.encode(pack_js(value))
xray_json       -> Base64.encode(pack_js(value))
tuic_json       -> Base64.encode(pack_js(value))
```

---

## 5.4 规范化规则

### `xray_prot`

- 旧结构里很多 vless 节点根本没有 `ssconf_basic_xray_prot_<n>`
- 当前前端用“如果值是 `vmess` 就按 vmess，否则按 vless”兜底

v2 迁移时统一规则：

- `type=4` 且旧值缺失时，写入 `xray_prot=vless`

### 布尔字段

v2 内统一规范为 `0/1`，迁移时：

- 旧值为 `1` -> `1`
- 旧值为空/缺失 -> `0`

涉及字段至少包括：

```text
v2ray_use_json
v2ray_mux_enable
v2ray_network_security_ai
v2ray_network_security_alpn_h2
v2ray_network_security_alpn_http
xray_use_json
xray_network_security_ai
xray_network_security_alpn_h2
xray_network_security_alpn_http
xray_show
trojan_ai
trojan_tfo
hy2_ai
hy2_tfo
```

旧版本兼容导出时再做反向投影：

- `1` -> `1`
- `0` -> 空值或不写，保持旧版本兼容行为

---

## 6. 新旧备份与恢复规格

## 6.1 新版本原生备份

格式：JSON

建议文件名：

```text
ssconf_backup_v2.json
```

结构：

```json
{
  "format": "fancyss-backup",
  "schema_version": 2,
  "created_at": "2026-03-20T12:00:00+08:00",
  "plugin_version": "3.6.0",
  "global": {
    "ss_basic_enable": "0",
    "ss_basic_mode": "2"
  },
  "nodes": [
    {"_schema": 2, "_id": "101", "type": "4", "name": "A"},
    {"_schema": 2, "_id": "102", "type": "7", "name": "B"}
  ],
  "node_order": ["101", "102"],
  "node_current": "101",
  "node_failover_backup": "102",
  "acl": {
    "...": "..."
  }
}
```

---

## 6.2 旧版本兼容备份

格式：传统 `.sh`

建议文件名：

```text
ssconf_backup_legacy.sh
```

生成逻辑不是直接 `dbus list ss`，而是：

1. 读取当前 `fss_node_order`
2. 按顺序把稳定 ID 投影成 `1..n`
3. 把 `fss_node_<id>` 按映射表转换为 `ssconf_basic_*_<n>`
4. 把 `fss_node_current` / `fss_node_failover_backup` 映射为旧顺序号
5. 生成传统 `dbus set ...` shell

这一步必须长期保留，而不是只在升级那次生成一次。

---

## 6.3 迁移时旧快照

格式：传统 `.sh`

建议路径：

```text
/koolshare/configs/fancyss/migration/legacy_migration_YYYYmmdd_HHMMSS.sh
```

用途：

- 保留升级当时的原始旧结构
- 作为最保守的兜底回滚材料

它和“当前数据生成的旧版本兼容备份”不是一回事，必须同时存在。

---

## 6.4 恢复判定原则

**按备份文件格式判定，不按 fancyss 版本号判定。**

恢复时：

- 如果是 `schema_version=2` JSON：走 v2 恢复路径
- 如果是传统 `dbus set` shell：走 legacy 恢复路径

这样比按版本号判断稳定得多。

---

## 7. 迁移事务设计

## 7.1 触发条件

满足以下条件时触发迁移：

- `fss_data_schema` 不存在
- 存在至少一个 `ssconf_basic_name_<n>`

---

## 7.2 迁移锁与中间目录

建议：

```text
LOCK: /var/lock/fss_node_migrate.lock
DIR:  /tmp/fancyss_node_migrate
```

并设置中间标记：

```sh
fss_data_migrating=1
```

如果系统在迁移过程中重启，下次启动先检查：

- 若 `fss_data_migrating=1` 且 `fss_data_schema` 不完整
- 说明上次迁移中断
- 应先清理残留的 `fss_node_*` 临时写入，再重新迁移

---

## 7.3 迁移步骤

### Step 1：生成旧快照

先调用现有旧结构导出能力，生成：

```text
legacy_migration_YYYYmmdd_HHMMSS.sh
```

这一步必须放在任何新结构写入之前。

### Step 2：导出旧节点中间态

复用当前已有的 `skipdb2json()` 思路，得到旧结构一节点一行 JSON。

### Step 3：逐节点转换为 v2 payload

对每行旧节点：

- 分配稳定 ID
- decode 特殊字段
- 规范化布尔为 `0/1`
- 补全缺省值（例如 `xray_prot=vless`）
- 增加保留元字段
- 写入临时文件 `nodes_v2.jsonl`

### Step 4：写入新结构暂存键

按临时文件写入：

- `fss_node_<id>`
- `fss_node_order`
- `fss_node_current`
- `fss_node_failover_backup`
- `fss_node_next_id`

### Step 5：校验

至少校验以下项：

- 节点数一致
- `fss_node_order` 长度和节点数一致
- `fss_node_current` 能在顺序表中找到
- 随机抽样或全量 decode 所有 `fss_node_<id>` 成功
- 当前节点名称与迁移前名称一致
- 若有备用节点，其名称映射一致

### Step 6：提交迁移标记

写入：

```sh
fss_data_schema=2
fss_data_migrated=1
fss_data_migration_notice=1
fss_data_migration_time=<timestamp>
fss_data_legacy_snapshot=<path>
```

### Step 7：删除旧节点键

仅删除旧节点相关键：

```text
ssconf_basic_*_<n>
ssconf_basic_node
```

保留其它全局 `ss_*`、ACL、订阅配置等。

### Step 8：清理中间标记

```sh
dbus remove fss_data_migrating
```

---

## 7.4 失败回滚

如果任一步失败：

- 删除本次写入的 `fss_node_*`
- 删除 `fss_node_order/fss_node_current/fss_node_next_id`
- 删除 `fss_data_migrating`
- **不删除任何旧 `ssconf_basic_*` 节点键**
- 打日志并继续按旧结构运行

这次失败不能导致用户节点丢失。

---

## 8. 前端实施规格

## 8.1 节点 API

新增：

```text
/_api/fss_node
```

返回内容至少包括：

- `fss_node_*`
- `fss_node_order`
- `fss_node_current`
- `fss_node_failover_backup`
- `fss_node_next_id`
- `fss_data_migration_notice`
- `fss_data_legacy_snapshot`

`/_api/ss` 继续保留，但不再承载节点实体。

---

## 8.2 前端节点对象构造

当前前端通过扫描 `ssconf_basic_name_*` 拼节点对象。

改造后：

1. 请求 `/_api/fss_node`
2. 取 `fss_node_order`
3. 依次 decode 对应 `fss_node_<id>`
4. 直接得到节点对象数组

不再做全量 `ssconf_basic_*` 扫描。

---

## 8.3 添加 / 编辑节点

### 新增节点

流程：

1. 读取 `fss_node_next_id`
2. 生成新 payload
3. 写 `fss_node_<new_id>`
4. 追加 `fss_node_order`
5. `fss_node_next_id += 1`

### 编辑节点

流程：

1. 读取当前 `fss_node_<id>`
2. 修改 payload
3. 回写同一稳定 ID 的 `fss_node_<id>`

不再出现“编辑节点 A 后，打开添加节点弹窗继承旧索引残留值”的问题。

---

## 8.4 排序 / 删除

### 排序

只更新：

```sh
fss_node_order
```

### 删除

只做三件事：

1. `dbus remove fss_node_<id>`
2. 从 `fss_node_order` 中移除该 id
3. 如果删除的是当前节点/备用节点，重新选择引用目标

不再整体重写全部节点。

---

## 8.5 首次迁移提示弹窗

触发条件：

- `fss_data_migration_notice=1`

弹窗内容需要明确告诉用户：

1. 当前版本已完成节点数据结构升级
2. 老版本 fancyss 不能直接识别新结构
3. 如果未来需要回退旧版本，建议先下载“旧版本兼容备份”
4. 如需保底回滚，还可下载“迁移时旧版本快照”

弹窗操作建议提供：

- 下载当前旧版本兼容备份
- 下载迁移时旧快照
- 我知道了

点“我知道了”后：

```sh
fss_data_migration_notice=0
```

---

## 9. 后端 helper 规格

## 9.1 建议新增统一 helper 层

建议在 `fancyss/scripts/` 下新增统一 helper，例如：

```text
ss_node_common.sh
```

至少提供：

```sh
fss_node_list_ids
fss_node_get_order
fss_node_set_order
fss_node_get_current
fss_node_set_current
fss_node_get_json <id>
fss_node_set_json <id> <json>
fss_node_remove <id>
fss_node_alloc_id
fss_node_decode_blob <blob>
fss_node_encode_json <json>
fss_node_v2_to_legacy_env <id>
fss_node_v2_to_legacy_dump
fss_node_legacy_to_v2_json <legacy_json_line> <id>
fss_node_export_native_backup
fss_node_export_legacy_backup
```

原则：

- 不允许各脚本继续散着自己 decode/encode
- 不允许每个脚本自己维护一份字段表

---

## 9.2 `ss_base.sh` 的职责

`ss_base.sh` 是整个兼容层的核心，改造后应负责：

1. 读取全局 `ss_*`
2. 读取 `fss_node_current`
3. decode 当前节点 `fss_node_<id>`
4. 把它投影回兼容的 `ss_basic_*` 环境变量
5. 兼容导出：保留 `ssconf_basic_node=<stable-id>` 的运行时环境变量或单独暴露 `FSS_NODE_CURRENT_ID`

注意：

- `ss_base.sh` 对下游脚本继续提供 `ss_basic_*`
- 但不再依赖 live 的 `ssconf_basic_*_<n>` dbus

这样 `ssconfig.sh` 这类大脚本无需首轮整体重写。

---

## 9.3 必须停止直接读取旧节点 KV 的文件

以下文件当前仍直接 `dbus get ssconf_basic_*`，后续必须收敛到 helper：

- `fancyss/ss/ssconfig.sh`
- `fancyss/scripts/ss_status.sh`
- `fancyss/scripts/ss_status_main.sh`
- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_webtest_gen.sh`
- `fancyss/scripts/ss_proc_status.sh`
- `fancyss/scripts/ss_node_subscribe.sh`
- `fancyss/install.sh`
- `fancyss/webs/Module_shadowsocks.asp`

这些文件里，只要还存在对 live `ssconf_basic_*_<n>` 的直接依赖，就意味着旧结构还没有真正退场。

---

## 10. 分阶段实施建议

## 阶段 1：helper + 映射 + 备份能力

目标：

- 落地 `ss_node_common.sh`
- 固化 v2 schema
- 落地旧 -> 新 / 新 -> 旧映射
- 新增“旧版本兼容备份”导出
- 新增“新版本原生 JSON 备份”导出

此阶段可以先不切换 live 存储。

---

## 阶段 2：迁移与恢复

目标：

- 增加升级迁移逻辑
- 增加迁移事务与回滚
- 增加 JSON 恢复能力
- 增加首次迁移提示弹窗

实现备注：

- 迁移引擎、JSON 恢复、迁移提示可以先落地
- **但自动触发真正的 live 迁移，必须等阶段 3 的前端节点页切到 `/_api/fss_node` 之后再打开**

原因：

- 当前节点页、节点编辑、节点排序仍然直接依赖 `/_api/ss` 下的 `ssconf_basic_*`
- 如果在阶段 2 就删除旧节点 KV，前端会直接看不到节点
- 如果阶段 2 迁移后又保留旧节点 KV 继续作为 live 数据，则会形成新旧两套节点数据漂移

因此实际 rollout 应当是：

1. 先把迁移引擎和提示机制写好
2. 再切前端节点读写路径
3. 最后再打开自动迁移开关

---

## 阶段 3：前端节点页切换到 `/_api/fss_node`

目标：

- 节点列表、编辑、删除、排序、下拉选择全部改走新结构
- 彻底移除前端对 `ssconf_basic_name_*` 扫描的依赖

此阶段收益最明显：

- 排序只改 `fss_node_order`
- 删除只删一个 blob
- 节点页加载不再扫上千个 `ssconf_basic_*`

---

## 阶段 4：脚本侧移除 direct dbus 旧节点读取

目标：

- `ssconfig.sh`
- `ss_webtest*.sh`
- `ss_status*.sh`
- 订阅脚本

逐步只通过 helper / `ss_base.sh` 兼容层拿节点数据。

---

## 11. 验收标准

迁移完成后，至少要满足以下验收项：

### 数据正确性

- 节点数量与迁移前一致
- 当前节点名称与迁移前一致
- 备用节点名称与迁移前一致
- 订阅分组不丢失
- JSON 节点、TUIC 节点、Naive 节点、Hy2 节点都能正确恢复

### 前端行为

- 节点列表正常显示
- 节点编辑正常回填
- 添加节点不会再串上一次编辑数据
- 排序后节点顺序正确，当前节点引用不乱
- 删除后当前节点和备用节点引用正确调整

### 运行行为

- `ss_base.sh` 能正确导出当前节点 `ss_basic_*`
- `ssconfig.sh` 能正确启用各类节点
- 订阅更新正常
- Web 延迟测试正常
- 故障转移正常

### 兼容行为

- 能导出新版本原生 JSON 备份
- 能导出当前配置的旧版本兼容备份
- 能恢复 v2 JSON
- 能恢复旧版 `.sh`
- 迁移失败时旧节点不丢失

---

## 12. 最终结论

从“设计”走到“实施”，我建议做一个关键收敛：

- 键空间、节点 ID、顺序、迁移、兼容导出，这些按设计方案直接落地
- 但节点 payload 内部先不要做过深的语义重构
- 首轮用“**扁平字段 JSON + 保留元字段**”承接旧结构

这样能最大化降低重构风险，同时把最有价值的收益先拿到：

- 节点 KV 数量显著下降
- 排序 / 删除不再全量重写
- 节点页不再过度依赖 `/_api/ss`
- 可以长期生成旧版本兼容导出
- 后续新增协议只需要扩展节点 payload 和映射表，不必再往 skipdb 平铺几十个新 KV

这才是对 fancyss 当前代码体量和兼容压力最现实、最稳妥的落地路径。
