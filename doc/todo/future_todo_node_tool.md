# fancyss 未来待办：node-tool 规划

本文用于记录 `node-tool` 的目标边界、命令草案和实施优先级。

`node-tool` 的定位不是订阅解析器，也不是直接改写运行时状态的“大而全管理器”，而是：

- 面向本地节点库的结构化 CLI
- 服务 `schema2` 节点导出、变更规划、批量操作、缓存预热
- 给 shell 提供稳定的数据面接口，减少 `jq/awk/sed/base64/dbus list` 链式处理

---

## 一、定位

### 1. 负责什么

- 本地节点导出与导入
- 节点增删改查
- 节点分组/来源/身份视图
- 节点库变更计划生成
- 节点相关缓存预热计划

### 2. 不负责什么

- 订阅下载
- 订阅格式识别与 URI 解析
- `dbus` 之外的路由器运行时 orchestration
- `iptables/ipset/dnsmasq` 规则管理
- 代理进程启动/停止

也就是说：

- 订阅输入仍然归 `sub-tool`
- Xray API 运行时控制仍然归 `xapi-tool`
- geodata 资产仍然归 `geotool`
- `node-tool` 只处理“本地节点库”

---

## 二、第一阶段必须实现的功能

### 1. `node2json`

用途：

- 把当前本地节点库导出为结构化 `json/jsonl`
- 供 shell、测试脚本、前端、后续 `sub-tool` / `node-tool` 互操作

建议能力：

- `node-tool node2json --schema2`
- `node-tool node2json --ids 1,2,3`
- `node-tool node2json --source user`
- `node-tool node2json --source-tag 08f2`
- `node-tool node2json --format json|jsonl`
- `node-tool node2json --canonical`

建议输出：

- `schema2 raw`
- `canonical compare view`
- `display view`

### 2. `json2node`

用途：

- 把一份节点 `json/jsonl` 导入本地节点库

建议能力：

- `node-tool json2node --input nodes.jsonl`
- `node-tool json2node --mode append`
- `node-tool json2node --mode replace`
- `node-tool json2node --reuse-ids`
- `node-tool json2node --dry-run`

建议输出：

- 实际写入节点数量
- 新增 / 覆盖 / 跳过数量
- 最终 `order`
- 新生成的 `_id` 清单

### 3. `add-node`

用途：

- 添加单个节点

建议能力：

- `node-tool add-node --input node.json`
- `node-tool add-node --stdin`
- `node-tool add-node --position tail|head|before:<id>|after:<id>`
- `node-tool add-node --source user|subscribe`

### 4. `delete-node`

用途：

- 删除单个节点

建议能力：

- `node-tool delete-node --id 23`
- `node-tool delete-node --identity xxx_yyy`
- `node-tool delete-node --dry-run`

### 5. `delete-nodes`

用途：

- 批量删除节点

建议能力：

- `node-tool delete-nodes --ids 21,22,23`
- `node-tool delete-nodes --source-tag 08f2`
- `node-tool delete-nodes --source user`
- `node-tool delete-nodes --group Nexitally`
- `node-tool delete-nodes --all-subscribe`
- `node-tool delete-nodes --all`
- `node-tool delete-nodes --dry-run`

### 6. `warm-cache`

用途：

- 节点配置预热
- 为 webtest / 运行时缓存提前准备结构化结果

建议能力：

- `node-tool warm-cache --env`
- `node-tool warm-cache --json`
- `node-tool warm-cache --direct-domains`
- `node-tool warm-cache --ids 1,2,3`

---

## 三、第一阶段强烈建议一起做的功能

### 1. `list`

用途：

- 列出节点基础信息

建议能力：

- `node-tool list`
- `node-tool list --source-tag 08f2`
- `node-tool list --group Nexitally`
- `node-tool list --protocol vmess`
- `node-tool list --format table|json|jsonl`

### 2. `stat`

用途：

- 统计节点库结构

建议能力：

- 总节点数
- 用户节点数
- 订阅节点数
- 各协议数量
- 各机场数量
- 各来源数量

### 3. `find`

用途：

- 按名称 / 身份 / 来源定位节点

建议能力：

- `node-tool find --name "Hong Kong 01"`
- `node-tool find --identity xxx_yyy`
- `node-tool find --source-tag 08f2`
- `node-tool find --airport-identity nexitally`

### 4. `reorder`

用途：

- 调整前端展示顺序

建议能力：

- `node-tool reorder --ids 5,3,1,...`
- `node-tool reorder --source-tag 08f2 --sort name`
- `node-tool reorder --group user --sort created`

### 5. `plan`

用途：

- 生成节点库变更计划，不直接写入

建议能力：

- `node-tool plan --input nodes.jsonl`
- 输出：
  - append
  - replace
  - delete
  - final order

这个命令后续可以成为 shell 快路径和写库路径的核心基础。

---

## 四、第二阶段建议功能

### 1. `source-prune`

用途：

- 删除某机场/某订阅来源所有节点

建议能力：

- `node-tool source-prune --source-tag 08f2`
- `node-tool source-prune --airport-identity nexitally`

### 2. `dedupe`

用途：

- 检测并移除重复节点

建议规则建议：

- 完全相同主副身份重复
- 完全相同配置重复
- 仅名称不同但配置完全相同

### 3. `validate`

用途：

- 校验本地节点库一致性

建议检查项：

- `_id` 唯一性
- `order` 与节点集合一致
- identity 字段完整性
- `_source/_source_url_hash` 完整性
- `type` 与字段匹配性
- `raw`/`canonical` 视图能否正常生成

### 4. `repair`

用途：

- 对节点库做轻量修复

建议能力：

- 补 identity
- 清理无效 order
- 修正重复 `_id`
- 清理无效 group/source 字段

### 5. `diff`

用途：

- 对比两份本地节点集

建议能力：

- `node-tool diff --old a.jsonl --new b.jsonl`
- 输出：
  - param
  - rename
  - new
  - deleted
  - summary

这部分可以复用 `sub-tool compare-fancyss` 的 compare 内核。

---

## 五、与 sub-tool 的边界建议

### 1. `sub-tool`

负责：

- 原始订阅 payload
- 内容识别
- 订阅解码
- URI 解析
- 订阅结果 diff

### 2. `node-tool`

负责：

- 本地节点库导出
- 本地节点库修改
- 本地节点库计划生成
- 本地节点缓存预热

### 3. 共享内核建议

建议后续抽共享模块：

- canonical compare node
- identity 计算
- fancyss node json normalize
- diff summary

这样可以避免：

- `sub-tool` 和 `node-tool` 各自维护一套 identity / compare 逻辑

---

## 六、建议的实施顺序

### P1

- `node2json`
- `json2node`
- `add-node`
- `delete-node`
- `delete-nodes`
- `warm-cache`

### P2

- `list`
- `stat`
- `find`
- `reorder`
- `plan`

### P3

- `source-prune`
- `dedupe`
- `validate`
- `repair`
- `diff`

---

## 七、预期收益

### 1. 对 shell 的直接减负

- 少大量 `dbus list | jq | awk | sed | base64`
- 少本地节点导出时的重复扫描
- 少“先导出再拆分再统计”的临时文件流水线

### 2. 对性能的直接收益

- 本地节点库视图生成更快
- 快路径 append / replace 计划更清晰
- webtest / node json / env cache 预热逻辑更稳定

### 3. 对一致性的收益

- 节点 identity、order、source 处理有统一实现
- 手动增删改、订阅、恢复、导入导出可以共享同一套节点库内核

---

## 八、一句话结论

`node-tool` 的核心目标不是“替代 shell”，而是把“本地节点库”从 shell 管理对象，升级成一套可导出、可比较、可计划、可写入的稳定数据面工具。
