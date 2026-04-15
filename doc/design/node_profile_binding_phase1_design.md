# fancyss 节点与订阅 Profile 绑定一期设计

## 1. 文档目标

本文只解决一个问题：

- 如何让节点库与订阅 profile 建立稳定、可操作、可兼容的绑定关系

本文不覆盖：

- 节点列表最终 UI 形态
- 节点分页 / 分表 / 虚拟渲染
- 独立 daemon / nbus
- SQLite 等新存储引擎引入

一期目标是先把“关系模型”建立好，让后续无论是表格、tab 分表还是 chip 布局，都可以复用同一套底层数据面。

---

## 2. 结论摘要

### 2.1 主关联键

节点与订阅 profile 的主关联键使用：

```text
_profile_id
```

而不是订阅链接 hash。

原因：

- 订阅链接可能变化，但业务上仍是同一个 profile
- 当前短 hash 只适合作为辅助索引，不适合作为长期稳定主键
- profile 承载启停、UA、过滤规则、计划任务等完整业务语义

### 2.2 存储位置

`_profile_id` 放在节点对象内部，也就是：

```text
fss_node_<id> -> base64(JSON)
```

的 JSON 内部。

不做外部映射表作为 source of truth。

### 2.3 兼容策略

一期不在 `install.sh` 中做重型全量迁移。

采用三层兼容：

1. 新同步写入的节点，直接带 `_profile_id`
2. 旧节点在运行时按 `_source_scope / _source_url_hash / last_group` 回退识别归属
3. 后续再提供显式“补齐 `_profile_id`”修复命令

也就是说：

- 新节点：强绑定
- 旧节点：弱绑定回退

---

## 3. 为什么不用 URL hash 做主桥梁

设某个订阅 profile：

```text
profile_id = 77a9ea57
url = https://example.com/api?token=abc
url_hash = 50d8
```

如果用户更新为：

```text
https://example.com/api?token=xyz
```

那么：

- `profile_id` 不变
- `url_hash` 变化

如果系统以 hash 为主桥梁，则：

- 关闭 profile
- 删除 profile
- 统计节点数
- 清理 webtest 缓存

都必须跟着 URL 一起漂移，模型会很脆。

所以：

- `profile_id` 是业务主键
- `url_hash` 只是辅助定位字段

---

## 4. 节点对象新增字段

一期节点对象增加：

```json
{
  "_profile_id": "77a9ea57"
}
```

节点相关元数据统一为：

```json
{
  "_source": "subscribe",
  "_profile_id": "77a9ea57",
  "_airport_identity": "amytelecom",
  "_source_scope": "amytelecom_50d8",
  "_source_url_hash": "50d8"
}
```

字段职责：

- `_profile_id`
  节点属于哪个订阅 profile

- `_airport_identity`
  机场级聚合键

- `_source_scope`
  同一机场下某次订阅实例的聚合键

- `_source_url_hash`
  订阅链接辅助 hash，兼容旧逻辑

---

## 5. Profile 与节点的关系模型

### 5.1 一对多关系

```text
一个 profile_id -> 多个节点
```

### 5.2 允许同机场多 profile

```text
多个 profile_id -> 一个 airport_identity
```

例如：

- `profile A` 使用主订阅链接
- `profile B` 使用备用订阅链接
- 二者都属于 `amytelecom`

### 5.3 source_scope 的定位

`_source_scope` 用于区分：

- 同一机场
- 不同订阅入口 / 不同链接 hash

它不是主业务键，但适合：

- 节点实例级删除
- 精确缓存清理
- 兼容旧节点回退识别

---

## 6. 有效视图规则

一期定义统一有效视图：

```text
effective =
  node exists
  && node not deleted
  && (
       node._profile_id 为空
       || profile.enabled == true
     )
```

以后如果要支持手动隐藏单节点，再加：

```text
&& node._hidden != true
```

当前阶段先不要把“关闭订阅”做成批量写节点 `close:true`。

原因：

- 会产生写放大
- profile 状态和节点状态会双写，容易漂移
- 关闭 / 开启只属于 profile，不属于节点本身

---

## 7. 一期兼容策略

## 7.1 为什么不在 install.sh 做全量迁移

不建议在升级安装时直接扫描全部节点并重写所有 `fss_node_*`：

- 风险高
- 升级耗时不可控
- 一旦中断不好恢复
- 节点数大时会引入明显写放大

所以一期不在 `install.sh` 做强制全量迁移。

当前 install 只做：

- profile legacy migrate
- `_profile_id` 轻量补齐 reconcile

也就是：

- 不会无条件重写所有节点 JSON
- 只对“能够根据现有 profile runtime 推导出归属”的旧节点补 `_profile_id`
- 且这一步是幂等的，可重复执行

## 7.2 运行时回退规则

当节点没有 `_profile_id` 时：

1. 若 profile 的 `last_group + last_url_hash` 存在
2. 且节点的 `_source_scope` 可匹配
3. 则运行时把该节点视为属于该 profile

伪规则：

```text
if node._profile_id exists:
  use node._profile_id
else:
  fallback match by node._source_scope == profile.airport_identity + "_" + profile.last_url_hash
```

其中：

- `profile.airport_identity` 由 `last_group -> slugify` 推导
- `profile.last_url_hash` 取 profile state 中最近一次成功/失败记录

## 7.3 新节点写入规则

所有新同步写入的订阅节点，必须直接写入：

```text
_profile_id
```

这样兼容仅是过渡，不是常态。

## 7.4 显式补齐入口

后续提供一个显式修复入口，例如：

```bash
node-tool migrate-profile-binding
```

或 shell 包装：

```bash
ss_node_profile_reconcile.sh
```

用途：

- 扫描旧节点
- 根据 `_source_scope` 回填 `_profile_id`
- 只在用户需要时执行

---

## 8. 一期施工范围

一期只做以下内容：

1. 节点对象支持 `_profile_id`
2. 订阅同步写入节点时注入 `_profile_id`
3. `node-tool` 读取/保留 `_profile_id`
4. 订阅 profile runtime 输出支持 `node_count`
5. 关闭 profile 时可以优先使用 `_profile_id`，回退到 `_source_scope`

---

## 9. node-tool 一期需要补的能力

### 9.1 读取

`NodeJson` / `NodeRecord` 增加：

```text
_profile_id
profile_id
```

### 9.2 过滤

后续建议支持：

```bash
node-tool list --profile-id 77a9ea57
node-tool stat --profile-id 77a9ea57
node-tool delete-nodes --profile-id 77a9ea57
```

但一期可以先只把字段打通，不必一次把全部命令做完。

---

## 10. shell 层一期改造

### 10.1 订阅同步写入点

当前订阅同步最终会把节点对象写入：

- `fss_enrich_node_identity_json`
- `json_write_object`
- `sub-tool parse-uri-lines`

一期要求：

- 订阅同步上下文中已有 `SUB_ACTIVE_PROFILE_ID`
- 在写节点对象时，把 `SUB_ACTIVE_PROFILE_ID` 写成 `_profile_id`

### 10.2 profile 关闭行为

一期建议保留当前行为：

- 关闭 profile 时删除对应节点

但删除优先顺序改为：

1. 若节点有 `_profile_id`，按 `_profile_id` 精确删除
2. 若没有，再按 `_source_scope` 回退删除

这样可以兼容旧节点。

注意：

后续第二阶段再把“关闭只隐藏、不删除”切换为默认行为。

---

## 11. 前端一期改造

前端一期不做大 UI 改造。

仅需要知道：

- profile 维度节点数量优先按 `_profile_id` 统计
- 旧节点没有 `_profile_id` 时，回退 `_source_scope`

节点列表分页 / tab 分表 / chip 布局暂不在一期实现。

---

## 12. 未来第二阶段

当 `_profile_id` 已经稳定进入节点库后，再做第二阶段：

1. 关闭 profile 不再删节点，只改 `profile.enabled`
2. `node-tool` 增加 `--effective`
3. webtest / runtime-artifact / list 都走 effective view
4. 前端节点列表从“直接读全量 raw KV”改为“读 node-tool summary view”

---

## 13. 一期验收标准

满足以下条件即可认为一期完成：

1. 新同步生成的订阅节点都带 `_profile_id`
2. `node-tool` 读取节点时不会丢失 `_profile_id`
3. profile 关闭时，对新节点按 `_profile_id` 精确清理
4. profile 关闭时，对旧节点按 `_source_scope` 回退清理
5. 新旧节点混合环境下，不需要升级安装时全量迁移也能工作

---

## 14. 最终建议

一期的关键词不是“数据库替换”，而是：

```text
把 profile_id 正式变成节点库的一等元数据
```

只要这一步完成：

- 节点列表
- 订阅管理
- webtest

三者的耦合关系就有了稳定桥梁，后续无论是 tab 分表还是 chip 布局，都可以在这之上继续演进。
