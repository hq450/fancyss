# fancyss 未来待办：全面移除节点服务器预解析

本文用于记录 fancyss 后续“全面移除节点服务器预解析，统一改为动态解析”的实施计划。

注意，这里的“预解析”特指：

- 节点启动前手工将节点域名解析为 IP
- 将解析结果写入代理配置
- 依赖解析快照、解析模式、解析 DNS 选择等状态继续驱动运行逻辑

不特指所有 DNS 预热行为。

例如：

- 启动阶段为了让域名节点能正常拉起，先启动 DNS 方案
- 启动后对少量常用域名做一次轻量查询预热

这类行为不一定要一起删除，需要单独评估。

---

## 一、目标

将 fancyss 的节点服务器地址处理方式统一收敛为：

- 默认使用动态解析
- 客户端配置尽量保留原始域名
- 节点域名解析统一交给 chinadns-ng / smartdns 的直连 DNS 路径
- 不再维护“预解析模式”和“预解析所用 DNS 方案”这套分支

预期收益：

- 减少启动链路复杂度
- 避免机场切 IP 后仍长期使用旧 IP
- 删除 `webtest`、`shunt`、`reboot_job` 中围绕预解析扩散出的重复逻辑
- 降低 Naive / TUIC / Xray-like 节点的双路径维护成本

---

## 二、范围定义

### 1. 本次要移除的内容

- `ss_basic_server_resolv_mode` 的“预解析”分支
- `ss_basic_server_resolv`
- `ss_basic_server_resolv_user`
- `ss_basic_lastru`
- 启动前 `__resolve_server_domain()` 及其派生控制流
- `/tmp/ss_host.conf` 这类预解析快照文件
- `naive` 的 `--host-resolver-rules="MAP ..."`
- `tuic` 的 `relay.ip` 预写入分支
- `webtest` 内部自带的节点服务器预解析器
- `shunt/webtest cache` 中与 resolver 相关的 freshness 条件
- “节点 IP 变化后触发重启”功能

### 2. 本次不自动等同删除的内容

- 动态解析场景下，启动代理前先启动 DNS 核心
- 机场特调 DNS
- 节点域名直连清单生成
- 非节点用途的轻量 DNS 预热

这些行为虽然也和“解析”有关，但职责不同，不能和节点服务器预解析混为一谈。

---

## 三、现状耦合点

### 1. 启动主链路

核心文件：

- `fancyss/ss/ssconfig.sh`

主要耦合：

- `server_resolv_mode_is_dynamic()`
- `server_resolv_mode_is_preresolve()`
- `__resolve_server_domain()`
- `resolv_server_ip()`
- `record_current_node_server_ip()`
- `write_current_node_host_snapshot()`
- `refresh_current_node_server_ip_runtime()`

### 2. 协议特例

- `naive` 启动时会根据预解析结果追加 `MAP host ip`
- `tuic` 启动时会在预解析模式下写入 `relay.ip`

### 3. webtest

核心文件：

- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_webtest_gen.sh`

主要耦合：

- `_get_server_ip()`
- `wt_server_resolv_mode_is_dynamic()`
- `wt_server_resolv_mode_is_preresolve()`
- cache meta 里的 `server_resolv_mode`
- cache meta 里的 `server_resolver`

### 4. shunt

核心文件：

- `fancyss/scripts/ss_node_shunt.sh`

主要耦合：

- 复用 webtest cache 时会校验 `server_resolv_mode`
- 复用 webtest cache 时会校验 `server_resolver`

### 5. 定时任务与触发重启

核心文件：

- `fancyss/scripts/ss_reboot_job.sh`

主要耦合：

- `check_ip_now()`
- `/tmp/ss_host.conf`
- “服务器 IP 变化则重启插件” 的整套逻辑

### 6. 前端与配置项

核心文件：

- `fancyss/webs/Module_shadowsocks.asp`

主要耦合：

- `节点服务器地址解析方式`
- `预解析所用DNS方案`
- 保存 `ss_basic_server_resolv_mode`
- 保存 `ss_basic_server_resolv`
- 保存 `ss_basic_server_resolv_user`
- 根据 `ss_basic_lastru` 给 DNS 选项打勾

### 7. 运行时状态

核心文件：

- `fancyss/scripts/ss_status.sh`
- `fancyss/scripts/ss_node_common.sh`

主要耦合：

- `server_ip` 运行时字段
- `ss_basic_server_ip`
- 启动末尾“节点服务器解析地址”展示

---

## 四、实施原则

### 1. 先退场，再清理

建议先让后端完全不再依赖预解析分支，再删除前端、dbus、缓存字段。

不建议一次性同时删所有入口，否则容易把“动态解析本身依赖的 DNS 前置启动”一起误删。

### 2. 只保留一种运行时真相

后续运行期语义应收敛为：

- 原始节点地址：始终是节点真实配置
- 写入代理配置的地址：默认直接使用原始值
- `server_ip` 不再参与控制流

### 3. 保留 DNS 前置启动

全面移除预解析，不等于启动顺序里不再需要：

- 先起 dnsmasq
- 再起 chinadns-ng / smartdns
- 再起代理主程序

这条链对域名节点仍然是必要的。

### 4. 机场特调优先级高于通用清理

机场特调 DNS 本质是为了动态解析服务的。

实施本项时不能破坏：

- 当前节点特调
- 非当前节点但存在特调机场时，强制 smartdns 的逻辑
- webtest / 启动 / 分流场景下统一复用特调 DNS

---

## 五、建议施工顺序

### 阶段 1：后端强制动态解析

- 归一化 `ss_basic_server_resolv_mode=1`
- `resolv_server_ip()` 仅保留：
  - 原始值是 IP：直通
  - 原始值是域名：保留域名
- 让启动主链路不再依赖 `__resolve_server_domain()` 决定配置写入

目标：

- 先让主链路摆脱预解析
- 不要求第一步就把所有旧字段删干净

### 阶段 2：删除协议特例中的预解析分支

- `naive` 删除 `MAP host ip`
- `tuic` 删除 `relay.ip` 写入逻辑

目标：

- 所有协议都统一接受“保留域名写配置”

### 阶段 3：退役重启触发功能

- 删除“服务器 IP 变化后触发重启”
- 删除 `/tmp/ss_host.conf` 相关逻辑
- 前端隐藏或删除对应设置

目标：

- 去掉最典型的预解析遗留功能

### 阶段 4：webtest 去预解析化

- 删除 `ss_webtest.sh` 内部 `_get_server_ip()` 的 resolver 选择逻辑
- `ss_webtest_gen.sh` 统一使用原始域名
- webtest 缓存键不再包含 resolver 维度

目标：

- 避免 webtest 继续维护一套独立解析器

### 阶段 5：shunt cache 清理

- 删除 `shunt` 对 `server_resolv_mode/server_resolver` 的 freshness 依赖

目标：

- 避免分流运行时继续继承一套已退役的 cache 条件

### 阶段 6：前端和 DBus 收口

- 移除：
  - `节点服务器地址解析方式`
  - `预解析所用DNS方案`
- 保存动作不再提交：
  - `ss_basic_server_resolv_mode`
  - `ss_basic_server_resolv`
  - `ss_basic_server_resolv_user`
- 清理历史兼容：
  - `ss_basic_lastru`
  - `ss_basic_server_ip`

目标：

- 用户侧不再感知预解析功能存在

### 阶段 7：运行时字段瘦身

- 评估 `server_ip` 是否彻底降级为仅观测字段
- 若无实际价值，进一步从 runtime 控制流中移除

目标：

- 真正完成“预解析退场后的结构收口”

---

## 六、风险点

### 1. DNS 前置启动误删

这是最大风险。

如果把“预解析”和“DNS 前置启动”一并删掉，域名节点可能在冷启动时无法建立代理。

### 2. Naive / TUIC 行为回退

这两个协议此前对预解析分支有额外适配，移除时必须单独验证。

### 3. webtest 缓存误判

如果只删一半：

- 生成侧不再带 resolver
- 校验侧还在比 resolver

就会造成缓存始终失效。

### 4. 特调机场 DNS 被破坏

机场特调是当前动态解析体系的重要扩展。

这次施工不能把：

- 节点域名清单
- smartdns 专属 DNS 通道
- webtest 的特调复用

一起打掉。

---

## 七、验收口径

### 1. 功能验收

- 所有协议节点默认保留域名写入配置
- 域名节点在 cold start 下可正常启动
- 机场特调 DNS 继续生效
- webtest 不再依赖预解析 DNS 选择项
- shunt 不再因为 resolver 设置变化而强制重建

### 2. 清理验收

- 前端不再出现预解析相关选项
- `dbus list` 中不再依赖：
  - `ss_basic_server_resolv_mode`
  - `ss_basic_server_resolv`
  - `ss_basic_server_resolv_user`
  - `ss_basic_lastru`
- 启动/测速/分流主链路中不再有预解析控制分支

### 3. 设备验收

至少验证：

- GS7
- TUF-AX3000
- RT-AX86U

重点关注：

- 启动成功率
- 启动耗时
- webtest 成功率
- smartdns / chinadns-ng 行为一致性

---

## 八、关联文档

- `doc/design/node-server-dynamic-resolve-design.md`

该设计文档记录了“从预解析走向动态解析”的原始设计背景。

本 TODO 文档记录的是进一步把“预解析功能彻底退场”的施工计划。
