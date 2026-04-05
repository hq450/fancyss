# fancyss 节点身份机制实施文档

## 1. 文档目的

本文用于定义 fancyss 的“节点身份机制”如何落地实现。

目标不是再引入一套模糊概念，而是要解决当前真实存在的几个问题：

- 订阅后当前正在使用的节点漂移
- 订阅后故障转移备用节点漂移
- 订阅后节点分流目标出口节点漂移或失联
- 订阅后 webtest 结果和节点对象错位
- 节点重命名、同名节点参数变化、协议切换时，系统无法判断“这是不是同一个节点”

这份文档聚焦：

- 身份模型
- 数据结构
- 匹配与重映射算法
- 受影响模块
- 分阶段实施方案
- 测试与回滚要求

本文是“实施文档”，不是纯脑暴文档。

如果后续只做第一阶段，也应严格按本文的数据结构和边界落地，避免后面返工。

---

## 2. 先区分三个概念

节点相关问题之所以容易混乱，是因为当前系统里实际上存在三种不同含义的“标识”：

### 2.1 显示顺序

这是用户在前端看到的节点顺序。

特点：

- 可拖动
- 可重排
- 只是 UI / 列表顺序

它不应该承担节点身份。

### 2.2 存储 ID / 运行时槽位

当前 schema2 下的：

- `_id`
- `fss_node_<id>`
- `fss_node_order`
- `fss_node_current`
- `fss_node_failover_backup`

本质上是“本地存储主键”，也可以理解为：

- 本地运行时槽位

特点：

- 在本地运行时是唯一的
- 适合做 dbus 引用
- 适合做 webtest cache key
- 适合做节点分流目标节点引用

它适合承担：

- 当前节点引用
- 故障转移引用
- webtest cache key
- 分流目标节点引用

但它不是跨订阅批次的天然稳定身份。

### 2.3 节点身份

本文要引入的“节点身份”是：

- 用来判断订阅前后的两个节点是否是“同一个节点”
- 用来在节点增删改后恢复 `_id` 和所有引用关系
- 用来承接“重命名 / 参数变化 / 协议切换”等复杂场景

结论：

- 顺序不是身份
- `_id` 是本地运行时主键 / 槽位，但不是跨批次天然稳定身份
- “节点身份”是 `_id` 之上的一层业务锚点

---

## 3. 为什么不能直接拿名字或 `_id` 当身份

### 3.1 只用 `_id` 不够

订阅重写时，节点集可能整体重建：

- 新节点重新分配 `_id`
- 原 `_id` 可能消失

这样：

- `fss_node_current`
- `fss_node_failover_backup`
- 分流规则 `target_node_id`
- webtest cache

都会失去锚点。

### 3.2 只用名字不够

机场经常会出现：

- 同名节点参数变化
- 同名不同倍率
- 同名不同协议

例如：

- `香港 09`
- `香港 09 [Premium]`
- `香港 09 - 2x`

有时用户感知上是“同一个节点更新了参数”，有时又确实是两个不同节点。

### 3.3 只用全部参数哈希也不够

如果只把完整参数一起哈希：

- 端口变化
- server 变化
- relay 变化
- 协议切换

都会被当成“全新节点”，这会让：

- 当前节点恢复
- 分流目标恢复
- 备用节点恢复

全部失效。

所以需要主身份 + 副身份。

---

## 4. 身份模型

## 4.1 总体设计

节点对象新增一组身份字段：

- `_identity_primary`
- `_identity_secondary`
- `_identity`
- `_identity_ver`

其中：

- `_identity = _identity_primary + "_" + _identity_secondary`

这和你提出的 `xxxxx_yyyyy` 结构一致。

### 4.2 主身份

主身份用于表达：

- “用户感知上这是不是同一个节点”

建议规则：

- 第一阶段直接以“原始名称”为主
- 同时纳入来源作用域，避免不同来源同名节点相互污染

推荐输入：

- `source_scope`
- `raw_name`

推荐定义：

```text
primary = hash_v1(source_scope + "\x1f" + raw_name)
```

其中：

- `source_scope`
  - 手动节点：固定为 `local`
  - 订阅节点：使用“机场身份 + 订阅实例后缀”
- `raw_name`
  - 当前节点对象里的原始名称，不做归一化

第一阶段建议把来源拆成两层：

- `airport_identity`
  - 表示“这是哪一个机场 / 来源组”
- `source_scope`
  - 表示“这是该机场下的哪一个具体订阅实例”

推荐：

- 本地手动节点：
  - `airport_identity = local`
  - `source_scope = local`
- 订阅节点：
  - `airport_identity = canonical airport key`
  - `source_scope = airport_identity + "_" + short_url_hash`

例如：

- `sslinks_78fd`

其中：

- `sslinks`
  - 机场级身份
- `78fd`
  - 当前订阅 URL 哈希前缀

这样做的目的不是为了好看，而是为了支持：

- 同一机场多个账号
- 同一机场多个订阅链接
- 同组但不同 URL 的来源并存

也就是说：

- 机场身份用于“属于哪个机场”
- 订阅实例身份用于“机场下的哪个具体来源”

这里采用保守策略：

- 不同机场命名风格差异很大
- 过早引入名称归一化，容易把不同节点误归为同一主身份
- 第一阶段宁可少识别一次“改名”，也不要错误合并两个不同节点

因此：

- v1 主身份不做名称归一化
- 改名识别优先依赖“副身份不变”
- 名称归一化只保留为未来可选增强
- `source_scope` 必须足够细，不能只用域名或 group

### 4.3 副身份

副身份用于表达：

- “这个节点当前的具体连接参数长什么样”

推荐输入：

- 协议族
- server / port
- 协议关键字段
- xray/tuic/hy2 的规范化配置

推荐定义：

```text
secondary = hash_v1(normalized_param_payload)
```

它必须：

- 排除运行时字段
- 排除 `_id`
- 排除时间戳
- 排除缓存字段
- 排除仅用于本地显示的字段

### 4.4 完整身份

完整身份：

```text
identity = primary + "_" + secondary
```

它的用途是：

- 唯一标识“同一来源下、同一主身份、当前这一版参数”的节点版本

---

## 5. 为什么不建议直接用 identity 取代 `_id`

你提到可以考虑直接把当前节点等引用改成 `identity`。

这里建议不要直接这么做。

原因：

### 5.1 `identity` 不是运行时最优主键

`identity` 更适合做：

- 跨订阅批次匹配
- 重映射
- diff

但不适合直接取代 `_id` 成为所有运行时引用的唯一主键。

### 5.2 需要允许“主身份相同、副身份不同”的节点临时共存

例如：

- 同名节点不同参数

这时：

- `_identity_primary` 相同
- `_identity_secondary` 不同

如果直接把“主身份”拿来引用，会产生歧义。

### 5.3 现有大量代码已经围绕 `_id` 建立

包括：

- `fss_node_current`
- `fss_node_failover_backup`
- shunt `target_node_id`
- webtest cache key
- node direct cache key
- 前端 `resolve_node_id()`

直接全量替换为 `identity`，侵入面过大，回归风险高。

### 5.4 更合理的方案

建议保留：

- `_id` 作为本地运行时主键 / 运行时槽位

新增：

- `_identity*` 作为跨变更锚点

然后在任何节点集重写前后：

- 先基于 identity 做匹配
- 再尽量复用旧 `_id`
- 必要时重写 `_id` 引用

也就是说：

- 运行时引用仍优先用 `_id`
- 订阅 / 编辑 / 恢复 / diff 过程用 `identity` 维持稳定性

换句话说：

- `_id` 代表“当前这份本地节点集里的槽位”
- `identity` 代表“跨变更时，这是不是同一个节点实体”

因此第一阶段不是去掉 `_id`，而是：

- 保留 `_id`
- 在每次节点集变化后，用 `identity` 去复用或重映射 `_id`

---

## 6. 名称归一化的定位

第一阶段不把名称归一化作为主身份输入。

原因：

- 不同机场命名风格差异大
- 很难在没有大量真实样本验证的前提下设计出稳定规则
- 一旦误归一，会把不同节点错误合并，风险比“少识别一次改名”更高

因此第一阶段的原则是：

- 主身份只使用原始名称
- 改名场景优先依赖“副身份不变”来识别

也就是：

- 主身份变
- 副身份不变

时，仍视为“同一个节点重命名”。

### 6.1 未来可选增强

名称归一化仍然有价值，但应降级为后续增强项。

只有在满足以下条件时才建议引入：

- 已收集足够多的真实机场命名样本
- 归一化规则可配置或可回退
- 能证明误判率足够低

未来若要引入，建议作为：

- `identity_primary_v2`

而不是直接替换第一阶段的主身份规则。

---

## 7. 副身份规范化规则

副身份要表达“当前连接参数版本”。

建议按协议族统一规范化：

### 7.1 SS / SSR

纳入：

- type
- server
- port
- method
- password
- obfs / protocol / param

### 7.2 Xray 系

纳入：

- `type`
- `xray_prot`
- `server`
- `port`
- `uuid`
- `flow`
- `network`
- `security`
- `sni`
- `host`
- `path`
- `alpn`
- `json` 规范化结果

### 7.3 TUIC / HY2 / Naive

纳入：

- `tuic_json` / `xray_json` / `hy2_*`
- 规范化后的结构化内容

### 7.4 明确排除

排除：

- `_id`
- `_schema`
- `_rev`
- `_source`
- `_updated_at`
- `_created_at`
- `_migrated_from`
- `_b64_mode`
- `server_ip`
- `latency`
- `ping`

这些原则和 `sub_nodes_file_md5()` 保持一致。

---

## 8. 数据结构建议

节点对象建议新增：

```json
{
  "_id": "108",
  "_identity_primary": "2f18a",
  "_identity_secondary": "7b9d1",
  "_identity": "2f18a_7b9d1",
  "_identity_ver": "1"
}
```

可选增加：

```json
{
  "_identity_scope": "abfa",
  "_identity_flags": ["name_match", "param_changed"]
}
```

其中：

- `_identity_scope`
  - 便于调试
- `_identity_flags`
  - 第一阶段可不落库

建议同时补充来源字段：

```json
{
  "_airport_identity": "sslinks",
  "_source_scope": "sslinks_78fd",
  "_source_url_hash": "78fd"
}
```

含义：

- `_airport_identity`
  - 机场级身份
- `_source_scope`
  - 订阅实例级身份，参与主身份计算
- `_source_url_hash`
  - 当前订阅链接哈希前缀，便于调试和排障

建议：

- `_identity*` 落入 schema2 节点对象
- `_airport_identity` / `_source_scope` / `_source_url_hash` 一并落入 schema2 节点对象
- JSON 备份应保留
- legacy 导出可忽略

### 8.1 运行时引用的建议结构

第一阶段不建议把所有 dbus 引用直接改成 identity。

建议保留：

```sh
fss_node_current=<node_id>
fss_node_failover_backup=<node_id>
```

可选增加影子字段：

```sh
fss_node_current_identity=<primary_secondary>
fss_node_failover_identity=<primary_secondary>
```

节点分流规则同理：

- 继续保留 `target_node_id`
- 新增 `target_node_identity`

这样做的好处是：

- 运行时主键不需要整体推翻
- 但每次节点集变化后，都可以用 identity 修复这些 `_id` 引用

---

## 9. 匹配规则

这里是整个机制的核心。

### 9.1 Case A: 主身份相同，副身份相同

说明：

- 同一个节点
- 参数没变

处理：

- 复用旧 `_id`
- 不改引用

### 9.2 Case B: 主身份相同，副身份不同

说明：

- 名字没变
- 参数变了

这正是机场最常见场景。

处理：

- 视为“同一节点更新参数”
- 复用旧 `_id`
- 更新节点对象内容
- 清理该 `_id` 对应的 webtest cache / node direct cache
- 当前节点 / 故障转移 / 分流引用都无需改 `_id`

### 9.3 Case C: 主身份不同，副身份相同

说明：

- 名字变了
- 参数没变

处理：

- 视为“节点重命名”
- 复用旧 `_id`
- 更新 `_identity_primary`
- 更新 `_identity`
- UI 应提示这是重命名，不是新节点

### 9.4 Case D: 主身份相同，存在多候选

说明：

- 同名不同参数共存

处理顺序：

1. 先按副身份精确匹配
2. 再按协议族 + 关键参数相似度匹配
3. 若仍冲突，则分配新 `_id`

### 9.5 Case E: 主身份和副身份都找不到

说明：

- 新节点

处理：

- 分配新 `_id`

### 9.6 Case F: 本地节点在新订阅中没有任何匹配

说明：

- 节点被删除

处理：

- 若不是当前节点 / 备用节点 / 分流目标节点：
  - 正常删除
- 若是关键引用节点：
  - 标记删除
- 触发替代策略
- 在前端提示用户

### 9.7 统一引用重映射

第一阶段真正的关键不是“尽量复用旧 `_id`”本身，而是：

- 任何节点集变更后，都统一执行一次引用重映射

也就是说：

- `_id` 复用是优化
- 引用重映射才是正确性保障

#### 9.7.1 触发事件

以下任一事件发生后，都应触发：

- 订阅
- 手动新增
- 手动删除
- 手动编辑
- URI 导入
- 拖动排序
- 去重
- 恢复配置

#### 9.7.2 输入

统一重映射函数至少需要：

- 变更前节点快照：`old_id -> old_identity`
- 变更后节点快照：`new_id -> new_identity`
- reconciliation 结果：
  - `old_id -> reused_id`
  - `old_identity -> new_id`
  - `deleted identities`

#### 9.7.3 输出

输出：

- `old_id -> new_id` 最终映射
- unresolved 引用列表
- 被删除但仍被引用的节点列表

#### 9.7.4 需要统一更新的引用

至少包括：

- `fss_node_current`
- `fss_node_failover_backup`
- 分流规则 `target_node_id`
- 分流默认节点
- 任何前端保存在 dbus 中的节点引用字段

对于 webtest：

- 如果 `_id` 复用，则尽量保留 cache
- 如果 `_id` 变化或参数变化，则清理旧 cache

#### 9.7.5 顺序变化场景

纯排序变化时，理论上 `_id` 可以完全不变。

但统一重映射函数仍然可以照常执行：

- 若 `old_id == new_id`
- 最终不会产生任何引用改动

这样逻辑最一致，也不容易漏场景

---

## 10. 去重策略

### 10.1 允许存在的情况

- 同主身份，不同副身份
- 不同主身份，相同副身份

原因：

- 同名不同参数需要允许
- 不同名字但参数相同，可能是机场重命名或镜像节点，不能贸然吞掉

### 10.2 不允许存在的情况

完整身份完全相同：

- `_identity_primary` 相同
- `_identity_secondary` 相同

这说明：

- 节点名称等价
- 参数也完全相同

应视为重复节点。

处理：

- 自动保留第一条
- 后续重复节点直接删除
- 前端给提示

---

## 11. 订阅流程如何接入

当前 `ss_node_subscribe.sh` 流程是：

1. 导出本地节点
2. 下载并解析在线节点
3. 比较 `local_*` 和 `online_*`
4. 生成写入文件
5. 重写节点并恢复当前节点/备用节点

节点身份机制接入后，建议改成：

1. 导出本地节点对象
2. 给本地节点补齐 `_identity*`
3. 解析在线节点对象
4. 给在线节点补齐 `_identity*`
5. 运行 identity reconciliation
6. 输出：
   - `mapped_online.jsonl`
   - `deleted_nodes.jsonl`
   - `new_nodes.jsonl`
   - `updated_nodes.jsonl`
   - `renamed_nodes.jsonl`
   - `id_reuse_map.tsv`
   - `id_replacement_map.tsv`
7. 再写库

关键点：

- 尽量让“同一节点更新参数”复用旧 `_id`

### 11.1 关于单机场多订阅

这一点必须在第一阶段就明确处理。

当前如果只用：

- 域名
- group

来识别来源，会导致：

- 同一机场两个账号
- 同一机场两个不同订阅 URL

无法同时存在。

因此在节点身份机制里，来源作用域不能只用机场名或域名。

推荐：

- 机场级身份：`airport_identity`
- 订阅实例级身份：`source_scope = airport_identity + "_" + short_url_hash`

这样即使两个订阅最终都显示成：

- `sslinks`

它们的具体 scope 仍然不同，例如：

- `sslinks_78fd`
- `sslinks_a13c`

这样主身份就不会冲突。

这样：

- 当前节点
- 备用节点
- webtest cache
- shunt 目标节点

大部分情况下自动稳定。

---

## 12. 当前节点 / 故障转移如何处理

### 12.1 当前节点

推荐策略：

- 优先复用旧 `_id`
- 如果旧 `_id` 不存在，再按 identity map 找对应新 `_id`
- 如果原节点被删除：
  - 优先同主身份族候选
  - 再同来源同地区
  - 再邻近顺序
  - 最后退到第一个可用节点

### 12.2 故障转移备用节点

同样策略。

但如果原备用节点失效：

- 前端应提示“备用节点已删除，请重新确认”

### 12.3 是否直接把 `fss_node_current` 改存 identity

第一阶段不建议。

推荐：

- `fss_node_current` 继续存 `_id`
- 可选新增：
  - `fss_node_current_identity`
  - `fss_node_failover_identity`

作为调试与恢复辅助字段。

原因是：

- 即使直接存 identity，也仍然需要在节点集变化后做 identity 匹配
- 纯 identity-only 不能消灭 remap，只是把 remap 从 `_id -> _id` 变成 `identity -> identity`
- 但运行时大量逻辑已经围绕 `_id` 建立，直接推翻收益不如风险大

---

## 13. 节点分流如何处理

当前节点分流规则里保存的是：

- `target_node_id`

第一阶段建议不要直接改前端协议，而是增加影子字段：

- `target_node_identity`

策略：

1. 规则保存时，同时记录：
   - `target_node_id`
   - `target_node_identity`
2. 订阅后：
   - 若 `target_node_id` 仍存在，直接保留
   - 若消失，按 `target_node_identity` 做恢复
   - 若 identity 也找不到，标记 unresolved
3. 前端卡片显示：
   - “目标节点已删除，请尽快切换”

这样可以平滑迁移，不需要一刀切改动所有前端逻辑。

更准确地说：

- `target_node_id` 是运行时槽位引用
- `target_node_identity` 是跨变更锚点
- 任何节点集变化后，统一重映射函数都要尝试修复 `target_node_id`

---

## 14. webtest 如何处理

当前 webtest cache 是按 `_id` 组织的。

这本身没有问题。

只要订阅后 identity reconciliation 能做到：

- 相同节点尽量复用旧 `_id`

那么：

- webtest 结果天然就不会错位

另外要增加：

- 节点参数变化但 `_id` 复用时，清理该 `_id` 旧 cache
- 节点删除时，清理被删除 `_id` 的 cache

不建议第一阶段把 webtest cache key 改成 identity。

---

## 15. 手动增删改也要纳入

节点身份不是只服务订阅。

手动增删改也必须接入。

### 15.1 手动新增

- 创建节点时就生成 `_identity*`
- 若发现完整身份重复，自动去重并提示

### 15.2 手动编辑

- 编辑后重新计算 `_identity*`
- 若只是改名字：
  - 主身份变
  - 副身份不变
- 若只是改参数：
  - 主身份不变
  - 副身份变

### 15.3 手动删除

若删除的是：

- 当前节点
- 备用节点
- 分流目标节点

前端要提示用户。

---

## 16. 受影响文件范围

第一阶段至少要评估这些文件：

### 16.1 后端

- `fancyss/scripts/ss_node_common.sh`
- `fancyss/scripts/ss_node_subscribe.sh`
- `fancyss/scripts/ss_conf.sh`
- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_node_shunt.sh`
- `fancyss/scripts/ss_status_main.sh`

### 16.2 前端

- `fancyss/webs/Module_shadowsocks.asp`

### 16.3 文档 / 参考

- `doc/design/node_data_storage_refactor_design.md`
- `doc/implementation/webtest_design_and_maintenance.md`
- `doc/implementation/node-shunt-mvp.md`

### 16.4 第一阶段最小改动清单

#### `fancyss/scripts/ss_node_common.sh`

- 新增 identity 计算函数
- 新增节点快照导出函数
- 新增统一引用重映射函数
- 新增当前节点/备用节点 remap 函数

#### `fancyss/scripts/ss_node_subscribe.sh`

- 订阅前导出旧 identity map
- 在线节点生成 identity
- 写库前做 reconciliation
- 尽量复用旧 `_id`
- 写库后统一执行引用重映射

#### `fancyss/scripts/ss_node_shunt.sh`

- 规则对象增加 `target_node_identity`
- 读取时优先 `target_node_id`
- 若 `target_node_id` 失效，则尝试用 `target_node_identity` 恢复

#### `fancyss/scripts/ss_webtest.sh`

- 当节点参数变化但 `_id` 复用时，清理该 `_id` 的旧 cache
- 当 `_id` 变化时，清理旧 `_id` cache，并按新 `_id` 重建

#### `fancyss/webs/Module_shadowsocks.asp`

- schema2 节点对象读写支持 `_identity*`
- 分流规则保存时同时写入 `target_node_identity`
- 当前节点 / 备用节点 UI 仍继续使用 `_id`
- 对被删除或 unresolved 的引用给出前端提示

---

## 17. 实施阶段

### 阶段 1：补身份字段

目标：

- 所有 schema2 节点对象都有 `_identity*`

只做：

- 字段生成
- 备份保留
- 前后端可见
- `_id` 继续作为运行时槽位

### 阶段 2：订阅重写复用 `_id`

目标：

- 同一节点更新参数时复用旧 `_id`

只做：

- identity reconciliation
- 统一引用重映射
- 当前节点 / 备用节点恢复增强

### 阶段 3：分流目标恢复

目标：

- 订阅后分流规则不乱指

只做：

- `target_node_identity`
- unresolved 提示

### 阶段 4：manual / webtest / status 联动

目标：

- 所有修改入口一致

---

## 18. 测试清单

GS7 先测，其他机型后补。

至少覆盖：

1. 订阅后只改顺序
2. 订阅后同名节点参数变化
3. 订阅后节点重命名
4. 订阅后协议切换
5. 订阅后当前节点被删除
6. 订阅后备用节点被删除
7. 订阅后 shunt 目标节点被删除
8. 手动编辑节点名
9. 手动编辑节点参数
10. 手动删除当前节点
11. exact duplicate 自动去重
12. webtest cache 与节点对象是否仍一一对应

---

## 19. 一句话结论

节点身份机制的正确落地方向不是“直接用 identity 替代一切”，而是：

- 保留 `_id` 作为本地运行时主键 / 运行时槽位
- 引入 `_identity` 作为跨变更锚点
- 在任何节点集变更后统一执行引用重映射

这样才能同时解决：

- 当前节点漂移
- 备用节点漂移
- 节点分流目标漂移
- webtest 错位
- 节点重命名 / 参数更新后的引用失效
