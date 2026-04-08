# node_env_cache 退役施工文档

## 目标

将 `node_env_cache` 从“持久缓存机制”降级为“历史兼容残留”，并逐步推动：

1. 取消持久 `env` 缓存的生成、复用、预热
2. 保留必要的运行时临时 `env` 目录，保证当前 `webtest` / `shunt` 不回归
3. 后续继续推进到“彻底去 env 化”，统一直接消费最终 `json / outbound`

## 背景

当前节点配置链路中同时存在两套中间表达：

- `node_json_cache`
- `node_env_cache`

其中：

- `node_json_cache` 已经能直接承载节点最终字段
- `webtest` 运行时产物也已经能直接生成 `outbounds.json`
- `node_env_cache` 的主要作用退化为 shell 读取字段时的中间视图

问题在于：

- 持久 `env` 缓存会产生额外复杂度
- 需要维护 `*.env / meta / obfs 索引`
- 还会留下 `node_env_cache.tmp.*` / `node_env_cache.tmp.node_tool` 之类的目录
- 新增协议/字段时，要同时维护 `json` 和 `env` 两套抽象

## 设计原则

### 1. 先废持久 env，再考虑废临时 env

当前 `webtest` / `shunt` 还存在 shell 字段读取路径，直接删除所有 env 会造成较大回归面。

因此分两阶段：

- 第一阶段：
  删除持久 `node_env_cache`
- 第二阶段：
  删除运行时临时 `env`

### 2. 统一真相源为 node json / outbound

长期目标：

- `webtest` 只负责任务调度和测速
- `shunt` 只负责运行时规则和 outbounds 组织
- 字段真相统一来自：
  - `node_json_cache`
  - `webtest_cache`
  - runtime outbound

## 当前阶段实施结果

### 已完成

#### A. 持久 node_env_cache 已停止生产

已处理：

- `fss_refresh_node_env_cache()` 不再生成持久 env cache
- `fss_node_env_cache_is_fresh()` 不再返回可复用
- `node-tool warm-cache --env` 不再生成持久 env cache

现状：

- `/koolshare/configs/fancyss/node_env_cache`
- `/koolshare/configs/fancyss/node_env_cache.meta`
- `node_env_cache.tmp.*`
- `node_env_cache.tmp.node_tool`

正常路径下均不会再被创建。

#### B. webtest 不再依赖持久 node_env_cache

`ss_webtest.sh` 已调整为：

- 继续复用 `node_json_cache`
- `env` 仅在 `TMP2/node_env` 下临时生成
- `warm_cache` / 批量测速 / 运行时批量构建都不再读取持久 `node_env_cache`

#### C. shunt 不再依赖持久 node_env_cache

`ss_node_shunt.sh` 已调整为：

- 优先复用 `node_json_cache`
- `env` 仅在 `FSS_SHUNT_RUNTIME_NODE_ENV_DIR` 这类运行时目录内临时生成
- 不再走全局持久 `node_env_cache`

## 当前仍保留的机制

### 运行时临时 env

以下目录仍会在运行时产生：

- `webtest`:
  - `/tmp/fancyss_webtest/node_env`
  - `/tmp/node_tool_env_cache.$$`
- `shunt`:
  - `/tmp/fancyss_shunt/.../node_env`

这些目录的职责是：

- 供当前仍在使用 shell 字段访问接口的逻辑读取节点字段
- 生命周期仅限当前运行任务
- 不再属于“持久缓存”

## 为什么临时 env 还不能立即删除

当前仍有这些 shell 访问接口存在：

- `wt_node_get_plain_from_cache`
- `wt_node_get`
- `fss_shunt_load_node_env`

这些逻辑还把节点字段当作：

- `WTN_server`
- `WTN_port`
- `WTN_method`
- `WTN_password`

来读取。

因此：

- 持久 `env` 缓存可以先删
- 临时 `env` 仍需保留，避免运行期回归

## 下一阶段施工计划

### 阶段 2：webtest 去 env 化

目标：

- `webtest` shell 路径不再依赖 `WT_NODE_ENV_DIR`
- 直接从 `node_json_cache` 或最终产物读取字段

建议拆分：

1. 将 `wt_node_get_plain_from_cache` 改为直接读 `json`
2. 将 `wt_build_node_env_file / wt_build_node_env_files_bulk / wt_load_node_env` 退役
3. 将 `wt_assign_webtest_cache_start_ports` 改为只基于 `nodes_index.txt` / `json`
4. 清理 `WT_NODE_ENV_DIR` 相关状态变量

预期结果：

- `webtest` 只负责调度
- 不再生成临时 `node_env`

### 阶段 3：shunt 去 env 化

目标：

- `fss_shunt_prepare_selected_node_env()` 退役
- runtime outbound 直接基于 `json` 读取字段

建议拆分：

1. 把 `wt_node_get*` 依赖点在 shunt 内替换成 json 读取
2. 保留 `node_json_cache`
3. 去掉 `FSS_SHUNT_RUNTIME_NODE_ENV_DIR`

预期结果：

- `shunt` 不再维护 env 视图
- `json` 成为唯一字段输入面

## 验证点

### 已验证

1. 清空 `/koolshare/configs/fancyss/node_env_cache*` 后运行：

```sh
sh /koolshare/scripts/ss_webtest.sh warm_cache
```

结果：

- `webtest` 预热成功
- `node_env_cache*` 不会重新出现

2. 手工运行：

```sh
/koolshare/bin/node-tool warm-cache --env
```

结果：

- 仅输出 `env: 0`
- 不会创建任何持久 `node_env_cache*`

### 后续需要继续验证

1. `webtest` 在多协议节点场景下无回归
2. `shunt` 生成 runtime outbound 无回归
3. `ss + obfs` sidecar 端口分配仍正确
4. `subscribe/manual/user` 三类节点读取字段一致

## 结论

当前这轮施工已经完成：

- 持久 `node_env_cache` 退役
- 运行时临时 `env` 保留

后续真正的终局目标是：

- 彻底删除临时 `env`
- 统一直接消费最终 `json / outbound`

这一步是值得做的，但应继续分阶段推进，优先 `webtest`，再 `shunt`。
