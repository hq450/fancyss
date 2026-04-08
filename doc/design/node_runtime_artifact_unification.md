# 节点运行产物统一设计

## 背景

当前节点相关运行链路已经从“读 env 视图”逐步收口到“读 node json / 最终产物”。

但仍存在一类重复：

- `webtest` 产物生成一套
- `shunt` runtime outbound 生成一套
- `ss_webtest_gen.sh` shell 生成器一套
- `node-tool` native 生成器一套

这会导致：

- 同一协议变更要改多处
- shell/native 覆盖范围不一致
- `webtest / shunt / 未来 ssconfig` 之间无法稳定共享最终运行产物

## 目标

建立统一的“节点运行产物层”。

给定：

- `node_id`
- `profile`

输出：

- `outbounds.json`
- 非 xray-like 节点的 `start/stop`
- `meta`

其中 `profile` 先考虑：

- `webtest`
- `shunt`

后续再评估：

- `runtime`

## 当前状态

### 已完成

1. `webtest` 已直接读 `node_json_cache`
2. `shunt` 已直接读 `node_json_cache`
3. 持久 `node_env_cache` 已从插件运行链路退役
4. `shunt` 已优先复用 `webtest_cache` 中的新鲜 `outbounds.json`

### 当前缺口

1. `webtest` 与 `shunt` 仍各自组织 runtime 产物
2. `node-tool` native 生成覆盖还不完整
3. shell 生成器仍然是重要 fallback

## 统一策略

### 1. 把 webtest_cache 视为第一批统一产物

当前最现实的统一入口不是新造一套目录，而是继续强化：

- `webtest_cache/nodes/*.json`
- `webtest_cache/nodes/*_start.sh`
- `webtest_cache/nodes/*_stop.sh`
- `webtest_cache/meta/*.meta`

原因：

- 已经进入运行链路
- `shunt` 已经能复用
- 风险最低

### 2. 逐步扩展 node-tool native 覆盖

优先顺序：

1. `vmess`
2. 继续补 shell fallback 仍覆盖不到的常见协议/分支

目标：

- 让 `webtest_cache` 更多节点直接由 `node-tool` native 生成
- 让 `shunt` 的“复用 webtest_cache”命中率更高

### 3. shell 生成器退居 fallback

不是立刻删除 `ss_webtest_gen.sh`，而是：

- 优先 native
- shell 兜底

这样可以控制回归风险。

## 分阶段施工

### 阶段 A

目标：

- `webtest` 去 env 化
- `shunt` 去 env 化

状态：

- 已完成

### 阶段 B

目标：

- 扩展 `node-tool` native 运行产物覆盖
- 让 `shunt` 尽量通过 `webtest_cache` 直接复用

状态：

- 进行中

### 阶段 C

目标：

- 提炼统一的“节点运行产物生成接口”

例如未来可能抽象为：

- `node-tool runtime-artifact --profile webtest`
- `node-tool runtime-artifact --profile shunt`

状态：

- 待开始

### 阶段 D

目标：

- 评估 `ssconfig` 是否复用统一运行产物生成层

说明：

- 这一步收益高
- 但风险也最高
- 必须放到最后

## 原则

1. 先统一 `webtest` 与 `shunt`
2. 再考虑 `ssconfig`
3. 优先让已有稳定产物被更多链路复用
4. 不为了“抽象漂亮”牺牲当前稳定性

## 当前推荐的下一步

1. 补 `vmess` native 运行产物生成
2. 在 `shunt` 中继续提高 `webtest_cache` 复用比例
3. 观察 shell fallback 还剩哪些协议/分支
4. 再决定是否引入明确的 `runtime-artifact` 命令
