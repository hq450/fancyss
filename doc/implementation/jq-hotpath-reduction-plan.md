# fancyss shell 脚本 `jq` 热点减负施工清单

日期：`2026-04-19`

## 1. 目标

本文用于指导 fancyss 后续对 shell 脚本中 `jq` 调用的减负改造。

本次只做静态审计和施工拆解，不修改任何业务代码。

当前目标不是“机械地删掉所有 `jq`”，而是：

- 优先消灭循环内的 `jq`
- 优先消灭同一份 JSON 上的重复 `jq` 取值
- 优先处理节点 / 订阅 / 分流这三条热路径
- 允许在冷路径、复杂 JSON 变换场景继续保留 `jq`
- 避免把原始 JSON 解析工作错误地下沉给 `sed` / `awk`

---

## 2. 审计范围

本次扫描范围：

- `fancyss/ss/*.sh`
- `fancyss/scripts/*.sh`

不包含：

- 前端 JavaScript
- Zig / C / 其它工具链源码
- 文档中的示例代码

---

## 3. 总体统计

原始命中数：

- `240` 处 `jq` 相关命中

剔除以下“假命中”后，实际执行点约为：

- `command -v jq`
- `type jq`
- `/koolshare/bin/jq` 路径探测
- 安装时复制 `jq`
- 提示日志中出现的 `jq`

实际运行点约为：

- `211` 处

按粗分类统计：

- 文本提取：`120`
- 紧凑变换：`29`
- JSON 构造：`11`
- 校验 / pretty / parse：`13`
- 布尔判断：`8`
- 其余混合：`59`

按文件分布，热点主要集中在：

| 文件 | 实际运行点估计 | 说明 |
| --- | ---: | --- |
| `fancyss/scripts/ss_node_common.sh` | `64` | 节点结构转换、字段访问、备份恢复 |
| `fancyss/scripts/ss_node_subscribe.sh` | `57` | 订阅导入、节点比对、分流引用同步 |
| `fancyss/ss/ssconfig.sh` | `43` | 配置生成、配置校验、规则版本读取 |
| `fancyss/scripts/ss_rule_update.sh` | `16` | 规则版本读取与更新 |
| `fancyss/scripts/ss_node_postsave.sh` | `6` | 保存后 identity 修正 |
| `fancyss/scripts/ss_base_dns.sh` | `6` | smartdns JSON 构造 / 校验 |

结论很明确：

- `jq` 问题不是均匀分布的
- 真正该优先动的是节点与订阅链路
- `ssconfig.sh` 虽然多，但很多是冷路径的复杂 JSON 拼装，优先级低于节点 / 订阅热路径

---

## 4. 替换原则

### 4.1 允许替换为 `sed` / `awk` / `tr` / `head` / `tail` 的前提

只在以下场景使用文本工具替代：

- 输入已经不是原始 JSON，而是 TSV / CSV / JSONL / USV 等扁平结构
- 输入是固定格式、字段无嵌套、已知不会出现转义歧义的简单字符串
- 已经由 `node-tool` / 后端一次性把结构化数据吐平

### 4.2 不建议直接用文本工具硬抠原始 JSON 的场景

以下场景不建议直接用 `sed` / `awk` 解析：

- 节点 JSON 对象
- 订阅 profile JSON
- 含引号、反斜杠、换行、嵌套对象、数组的值
- `xray_json` / `v2ray_json` / `tuic_json` 这类 JSON 套 JSON 的字段

原因很直接：

- shell 文本工具不具备通用 JSON 语义
- 解析错误比性能问题更难排查
- 误伤节点名、备注、密码、路径、header 的概率很高

### 4.3 优先替代模式

推荐按以下模式减负：

1. 同一份 JSON 连续取多个字段：
   一次性导出为 TSV，再由 shell 处理。
2. 循环内逐条 `jq`：
   改成先整批导出 JSONL / TSV，再进入 `while read`。
3. 对同一文件重复执行多次 `jq`：
   改成一次解析、一次投影、后续复用。
4. shell 很难安全完成的结构操作：
   优先扩 `node-tool` / `sub-tool`，而不是写脆弱的 `sed` 正则。

### 4.4 保留 `jq` 的合理场景

以下场景保留 `jq` 是合理的：

- 配置文件合法性校验
- 冷路径的复杂 JSON 合并与补字段
- `del(.. | nulls)` 这类递归清洗
- `slurpfile` / `with_entries` / `fromjson` / `tojson` 这类复杂结构变换

本次审计发现 fancyss 中已使用到的高阶特性包括：

- `select`
- `map`
- `with_entries`
- `to_entries`
- `try / catch`
- `fromjson / tojson`
- `@tsv`
- `@base64`
- `--slurpfile`
- `del(.. | nulls)`

这意味着“做一个完全替代 jq 的 shell 方案”并不现实。

---

## 5. 最高优先级热点

### P0. 节点访问器：必须先处理

热点文件：

- `fancyss/scripts/ss_node_common.sh`
- `fancyss/scripts/ss_node_subscribe.sh`

核心函数：

- `fss_enrich_node_identity_json()`：`ss_node_common.sh:539`
- `fss_get_node_identity_by_id()`：`ss_node_common.sh:1738`
- `fss_get_node_source_scope_by_id()`：`ss_node_common.sh:1760`
- `fss_get_node_profile_id_by_id()`：`ss_node_common.sh:1777`
- `fss_get_node_airport_identity_by_id()`：`ss_node_common.sh:1794`
- `fss_get_node_field_plain()`：`ss_node_common.sh:1874`
- `sub_get_node_field_plain()`：`ss_node_subscribe.sh:2219`
- `sub_get_node_identity_plain()`：`ss_node_subscribe.sh:2256`
- `sub_get_node_snapshot_plain()`：`ss_node_subscribe.sh:2273`

当前问题：

- 同一份 `node_json` 连续执行多次 `jq -r`
- 访问器在上层循环里被反复调用，形成“循环套访问器，访问器内再跑 `jq`”
- 订阅、节点比对、节点切换、分流同步都会复用这批函数

这是当前最值得优先处理的部分。

建议改造方向：

- 新增统一的“多字段读取”帮助函数，只对单个节点 JSON 做一次解析
- 更进一步，优先扩 `node-tool`，支持：
  - 单节点多字段导出
  - 多节点批量字段导出
  - JSONL -> TSV 投影
- shell 层只负责消费扁平文本，不再对每个字段单独调 `jq`

建议第一阶段落地项：

- 为单节点增加一次性投影输出，替代连续 `jq -r '.field // empty'`
- 让 `fss_get_node_identity_by_id()` 等访问器复用同一条投影路径
- 让 `sub_get_node_field_plain()` 和 `sub_get_node_identity_plain()` 复用 `ss_node_common.sh` 的统一读取接口

预期收益：

- 节点 / 订阅相关热路径立即降压
- 后续节点卡片、表格、订阅同步、节点比对都能间接受益

风险：

- 这些函数被引用面很广，施工必须分阶段替换
- 不能一上来改业务语义，只能先压缩读取成本

---

### P0. 分流规则同步：存在明显循环内多次 `jq`

热点函数：

- 分流规则同步逻辑：`ss_node_subscribe.sh:3435` 附近

当前问题：

- 把规则 JSON 数组拆成逐行 JSON 后
- 每一条规则循环内再次多次 `jq` 取：
  - `target_node_id`
  - `target_node_identity`
  - `id`
  - `remark`
  - `preset`
- 命中后还会再次用 `jq` 写回单字段

这类属于标准的“循环内多次 `jq` 读写”。

建议改造方向：

- 先整批投影成 TSV
- shell 只处理映射关系和条件判断
- 最后统一回写，避免单条规则上反复 `jq`

如果 shell 实现过于别扭，更适合新增一个受限工具能力：

- 输入规则 JSON 数组
- 输入节点 ID / identity 映射表
- 输出一次性更新后的规则 JSON

预期收益：

- 订阅变更后分流引用同步更稳定
- 避免节点多、规则多时的累计开销

---

### P0. 本地节点分组拆分：循环里逐条取 `group`

热点函数：

- 本地节点分组拆分逻辑：`ss_node_subscribe.sh:4719` 附近

当前问题：

- 逐条 `node_json`
- 逐条 `jq -r '.group // "null"'`
- shell 再去算 group hash 和输出文件名

建议改造方向：

- 一次性把 `group + 原始 JSON` 导出为双列文本
- 后续用 `awk` / `sort` / `read` 处理

这里非常适合文本工具接管，因为：

- 结构化提取只做一次
- 分组、计数、汇总本来就是 `awk` 强项

---

## 6. 中优先级热点

### P1. 订阅离线去重：可继续压缩

热点函数：

- `sub_filter_offline_duplicate_nodes()`：`ss_node_subscribe.sh:2600`

当前问题：

- 这里不是典型循环内多次 `jq`
- 但仍存在对离线节点 JSON 做字段投影和重命名回写

建议改造方向：

- 保留一次性 `jq -> TSV` 的模式
- 减少单节点 rename 时的再次 `jq '.name = ...'`
- 如果后续 `node-tool` 已支持简单 set-field，则可转给工具实现

优先级判断：

- 该逻辑是用户触发、非高频
- 可排在主热路径之后

---

### P1. `ss_rule_update.sh`：重复读取同一 JSON 文件

热点函数：

- `update_rule()`：`ss_rule_update.sh:58`
- `write_numbers()`：`ssconfig.sh:6492`

当前问题：

- 对同一个 `rules.json.js` 文件重复跑多次 `jq`
- 主要是在取：
  - `name`
  - `md5`
  - `date`
  - `count`
  - `count_ip`

建议改造方向：

- 单次 `jq` 输出一个固定顺序的 TSV
- shell 使用 `read` / `awk` 取值
- 或者用一次 `jq` 同时输出多个键值对

这里不建议用 `sed` 直接解析 JSON 文件本体。

原因：

- 规则文件虽然结构简单，但仍是标准 JSON
- 与其写脆弱文本规则，不如一次 `jq` 提取多个字段

预期收益：

- 代码更整洁
- 更新规则、启动后写版本号的重复成本下降

---

### P1. `ss_status.sh`：同一 JSON 连续取两个字段

热点函数：

- `json_probe_line()`：`ss_status.sh:80`

当前问题：

- 对同一份 `json_text` 连续执行两次 `jq`
- 只为了拿同一个 probe 的 `ok` 和 `elapsed_ms`

建议改造方向：

- 一次 `jq` 输出 `ok<TAB>ms`
- shell 用一次 `read` 消费

这是非常适合顺手修掉的小点。

---

### P1. `ss_node_postsave.sh`：同一节点 JSON 连续取 6 个字段

热点函数：

- `ss_node_postsave.sh:21` 附近

当前问题：

- 保存后对同一份节点 JSON 连续提取：
  - `_identity`
  - `_source`
  - `_airport_identity`
  - `_source_scope`
  - `_source_url_hash`

建议改造方向：

- 一次投影成 TSV
- 再调用 `fss_enrich_node_identity_json()`

优先级略低于节点访问器，但改造成本很小。

---

## 7. 低优先级热点

### P2. 备份恢复链路：有明显 `jq`，但属于冷路径

热点函数：

- `fss_restore_native_backup_to_legacy()`：`ss_node_common.sh:2798`
- `fss_restore_legacy_backup_sh_fast()`：`ss_node_common.sh:2863`

当前问题：

- 有循环内 `jq`
- 有按 node_id 反复在 `.nodes[]` 上筛选的逻辑

为什么不先做：

- 这是备份导入导出路径
- 不属于用户日常高频操作
- 真实收益低于节点 / 订阅 / 分流热路径

建议：

- 先记录，不在第一轮施工中处理
- 第二轮如需优化，可改成：
  - 一次导出 `nodes.tsv`
  - 一次导出 `global.tsv`
  - 一次导出 `acl.tsv`
  - shell 只消费扁平文本

---

### P2. `ssconfig.sh`：复杂 JSON 拼装保留 `jq`

热点函数：

- `append_xray_dns_relay_inbounds()`：`ssconfig.sh:2861`
- `append_xray_ipv6_tproxy_inbound()`：`ssconfig.sh:2936`
- VMess / VLESS / SS / TUIC 配置生成相关逻辑

当前判断：

- `jq` 数量虽然多
- 但多数是冷路径
- 且属于复杂 JSON 读改写

不建议当前阶段用 `sed` / `awk` 替换：

- 容易破坏配置语义
- 收益远不如节点 / 订阅热路径

建议：

- 保留 `jq`
- 后续若需要进一步提速，优先考虑单独的 JSON config tool，而不是 shell 正则替换

---

### P2. `ss_base_dns.sh`：smartdns JSON 保留 `jq`

热点函数：

- `smartdns_default_group_json()`：`ss_base_dns.sh:506`
- `smartdns_validate_group_value()`：`ss_base_dns.sh:580`
- `smartdns_group_json()`：`ss_base_dns.sh:602`
- `smartdns_iter_group_items()`：`ss_base_dns.sh:614`
- `smartdns_resolve_item_tsv()`：`ss_base_dns.sh:619`
- `smartdns_group_items_tsv()`：`ss_base_dns.sh:647`

判断：

- 这里的 `jq` 主要用于 JSON 构造、校验、数组展开
- 并没有形成明显的大规模热点

建议：

- 当前阶段保留
- 若后续发现 DNS 组读取成为热点，再考虑把“数组展开为 TSV”交给小工具

---

## 8. 不必优先处理的文件

以下文件本次扫描里没有形成真正的 `jq` 热点，或者只是探测路径：

- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_status_main.sh`
- `fancyss/scripts/ss_subscribe_profile_lib.sh`
- `fancyss/scripts/ss_node_data_api.sh`
- `fancyss/scripts/ss_conf.sh`

这部分当前不作为减负主战场。

---

## 9. 可执行的分阶段施工方案

### 第一阶段：先消灭节点 / 订阅链路里的重复读取

目标：

- 不改业务语义
- 只减少同一份节点 JSON 的重复解析

任务：

- 为节点对象增加统一多字段投影接口
- 让 `fss_get_node_*` 访问器复用统一投影
- 让 `sub_get_node_*` 访问器复用统一投影
- 审核所有“循环 -> 访问器 -> jq”的调用点

优先文件：

- `fancyss/scripts/ss_node_common.sh`
- `fancyss/scripts/ss_node_subscribe.sh`

验收标准：

- 节点主访问器不再对同一份 JSON 连续做多次 `jq -r`
- 节点列表、订阅同步、节点比对相关路径的单节点字段读取显著收敛

---

### 第二阶段：处理分流规则同步与分组拆分

目标：

- 消灭循环内逐条多字段 `jq`

任务：

- 重写订阅后的分流规则同步流程
- 重写本地节点按 group 拆分流程
- 让 shell 主要消费 TSV / JSONL

优先文件：

- `fancyss/scripts/ss_node_subscribe.sh`

验收标准：

- 分流规则同步逻辑不再在单条规则上反复 `jq`
- 本地节点分组拆分不再逐条对原始 JSON 取 `group`

---

### 第三阶段：扫尾低成本优化

目标：

- 用最小改动收拾散落的小热点

任务：

- `ss_rule_update.sh` 单次提取多字段
- `ss_status.sh` 单次提取 `ok + ms`
- `ss_node_postsave.sh` 单次提取 identity 相关字段

优先文件：

- `fancyss/scripts/ss_rule_update.sh`
- `fancyss/scripts/ss_status.sh`
- `fancyss/scripts/ss_node_postsave.sh`

---

### 第四阶段：决定是否继续推进工具化

目标：

- 在前三阶段完成后再判断是否还需要更进一步抽工具

评估问题：

- 节点 / 订阅热路径是否已经足够轻
- 是否还有大量“shell 做结构化 JSON 操作”的负担
- 是否需要为后续更多数据结构迁移做准备

---

## 10. 关于 Zig 版 `minijq` 的评估

结论先说：

- 不建议现在就做“完全替代 jq 的 Zig minijq”
- 可以考虑做“受限功能集”的结构化小工具

原因：

- fancyss 当前用到的 `jq` 特性已经不算少
- 若追求兼容 `jq` 语法，本质上是在重造半个 `jq`
- 真正的热点主要集中在节点 / 订阅对象处理，不是所有 JSON 场景

更合适的方向：

- 优先扩 `node-tool`
- 若有必要，再做受限子命令式工具，而不是兼容 `jq` DSL

更合适的能力范围：

- `get-many`
  - 输入：单节点 JSON / 多节点 JSONL
  - 输出：固定字段顺序的 TSV
- `set-field`
  - 设置简单字符串字段
- `del-field`
  - 删除简单字段
- `project`
  - JSONL 投影为 TSV
- `filter`
  - 按简单字段值筛选 JSONL
- `length`
  - 获取数组 / 对象长度

不建议在第一版覆盖：

- `try / catch`
- `with_entries`
- `fromjson / tojson`
- 递归 `del(.. | nulls)`
- `slurpfile`

也就是说：

- 第一阶段应该是“扩现有工具，让热点业务脱离 `jq`”
- 不是“先造一个通用 `jq` 替身，再回头改业务”

---

## 11. 推荐实施顺序

建议严格按以下顺序推进：

1. `ss_node_common.sh` 节点访问器
2. `ss_node_subscribe.sh` 节点访问器复用
3. `ss_node_subscribe.sh` 分流规则同步
4. `ss_node_subscribe.sh` 本地节点分组拆分
5. `ss_rule_update.sh`
6. `ss_status.sh`
7. `ss_node_postsave.sh`
8. 复评 `ssconfig.sh` / `ss_base_dns.sh` 是否还有必要继续动

---

## 12. 本清单对应的核心判断

本次审计的核心结论只有三条：

- 第一，不要执着于“删光 `jq`”，真正该做的是“删掉热路径里无效的 `jq`”
- 第二，不要用 `sed` / `awk` 直接去硬抠原始 JSON，应先把 JSON 扁平化
- 第三，节点 / 订阅热路径更适合扩 `node-tool`，而不是先做通用 `minijq`

这也是后续实际施工时的判断基线。
