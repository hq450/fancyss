# sub-get 接入纲要

本文记录 fancyss 现阶段为 `sub-get` 预留的接入点，以及后续把订阅下载从 `curl/wget` 切到独立 Zig 下载器时的实施顺序。

## 1. 定位

`sub-get` 的职责建议收敛为：

- 订阅下载
- direct / proxy / auto 三种下载策略
- HTTPS/TLS
- socks5 代理出站
- UA 指定
- Header 落盘
- 后续扩展：
  - 多 UA 探测
  - 多候选并发下载
  - 下载摘要输出

不负责：

- 订阅内容解析
- 节点写库
- dbus 写回
- 当前节点/故障转移恢复

也就是：

- `sub-get` 只做“拿内容”
- `sub-tool` 继续做“解析内容”
- `ss_node_subscribe.sh` 继续做 orchestration

## 2. 当前代码中的预留接口

当前已经在 [ss_node_subscribe.sh](/home/sadog/koolshare/fancyss/fancyss/scripts/ss_node_subscribe.sh) 里预留：

- `pick_sub_get()`
- `sub_get_supports_command()`
- `sub_write_sub_get_plan()`
- `download_by_sub_get()`
- `download_subscription_payload()`

当前行为：

- 若系统中不存在可执行的 `sub-get`，继续走现有 `curl -> wget` 路径
- 若存在 `sub-get`，且它未来实现 `fetch` 子命令，则可以直接接管下载

## 3. 建议的最小 CLI

建议 `sub-get` 第一版至少支持：

```bash
sub-get version
sub-get fetch \
  --url <url> \
  --output <payload-file> \
  --header-output <header-file> \
  --policy <auto|direct|proxy> \
  [--user-agent <ua>]
```

建议返回约定：

- `0`：下载成功，payload 已写入
- `1`：下载失败
- `2`：参数或环境不支持

## 4. 当前 shell 侧需要的最小契约

`download_by_sub_get()` 当前默认传入：

- `--url`
- `--output`
- `--header-output`
- `--policy`
- `--user-agent`（仅当 UA 非空）

此外，shell 会在临时目录生成一份调试计划文件：

- `sub_get_plan_<hash>.json`

这份文件当前只用于调试和后续联调，不作为正式接口强依赖。

## 5. 后续实施顺序

建议顺序：

1. `sub-get` 空仓库补一个初始提交
2. 接成 `tool/sub-get` submodule
3. 实现 `version` 和 `fetch`
4. 在本机环境先验证：
   - https direct
   - https via socks5
   - header 输出
5. 在 GS7 实机替换 `download_by_sub_get()` 的占位路径
6. 再做多 UA / 多策略 batch probe

## 6. 为什么先不直接切换

原因有两个：

- 现在 profile 和订阅管理这条线还在收口，先把 orchestration 稳住更重要
- 订阅下载在实机上差异很大，`sub-get` 最好直接拿真实机场样本做第一轮兼容目标

当前最有价值的真实样本之一就是 GS7 上 `Nexitally` 这个 profile：

- direct 失败
- proxy 下 curl 失败
- wget 最终为空响应

这类样本正适合作为 `sub-get` 第一轮兼容目标。
