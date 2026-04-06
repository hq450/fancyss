# sub-tool 维护文档

## 1. 文档目的

本文用于给后续维护者说明 `sub-tool` 的职责边界、当前接入方式、代码结构、常见维护入口、加协议/加字段的方法，以及出现订阅相关 bug 时应如何排查与回归。

这不是面向最终用户的使用说明，而是面向：

- `fancyss` 后续开发者
- 订阅链路维护者
- 新增协议/字段支持的实现者
- 处理订阅兼容性与性能问题的维护者

当前 `sub-tool` 已经不是一个“纯旁路实验工具”，而是 `fancyss` 订阅链路中的正式组成部分。

---

## 2. 当前定位

`sub-tool` 的定位是：

- 面向“外部订阅内容”的轻量 Zig 工具
- 负责把订阅原文转换成 `fancyss` 可消费的结构化节点集
- 尽量把“结构化解析、过滤、diff、归一化、摘要统计”从 shell 下沉到 Zig

它当前不负责：

- 订阅下载
- `dbus` 写回
- 本地节点库真正写入
- 代理进程启停
- `iptables/ipset/dnsmasq` orchestration

也就是说：

- shell 仍然负责 orchestration
- `sub-tool` 负责“订阅输入 -> 订阅结果”

---

## 3. 当前职责边界

### 3.1 shell 负责的部分

当前 shell 仍负责：

- 下载订阅内容
- 代理下载 / 重试 / curl-wget 回退
- 订阅缓存编排
- 本地节点导出
- schema2 写入
- 当前节点 / 故障转移节点恢复
- 分流引用同步
- webtest / direct cache 收尾

主要入口文件：

- [ss_node_subscribe.sh](/home/sadog/koolshare/fancyss/fancyss/scripts/ss_node_subscribe.sh)

### 3.2 sub-tool 负责的部分

当前 `sub-tool` 已经负责：

- 输入内容识别
- Base64 订阅解码
- URI 行订阅解析
- `fancyss` 节点 JSON 生成
- identity 生成
- 简单关键词过滤
- 信息节点过滤
- `reuse-ids-from`
- `compare-with`
- `diff.tsv`
- `diff.summary.json`
- `summary.json`

主要源码文件：

- [main.zig](/home/sadog/koolshare/fancyss/tool/sub-tool/src/main.zig)

---

## 4. 当前命令与参数

当前命令：

- `inspect`
- `parse-uri-lines`
- `compare-fancyss`
- `summary`
- `version`

### 4.1 `inspect`

用途：

- 识别订阅原文类型

当前可识别：

- `uri-lines`
- `base64-uri-lines`
- `html-login`
- `html-redirect`
- `html-page`
- `clash-yaml`
- `json-error`
- `json`
- `text-error`
- `gzip`
- `unknown`

### 4.2 `parse-uri-lines`

这是当前最核心的命令。

常用参数：

- `--input`
- `--output`
- `--format fancyss`
- `--group`
- `--source-tag`
- `--source-url-hash`
- `--airport-identity`
- `--source-scope`
- `--reuse-ids-from`
- `--compare-with`
- `--diff-output`
- `--diff-summary-output`
- `--summary-output`
- `--exclude-pattern`
- `--include-pattern`
- `--keep-info-node`
- `--mode`
- `--pkg-type`
- `--sub-ai`
- `--hy2-up`
- `--hy2-dl`
- `--hy2-tfo-switch`
- `--hy2-cg-opt`
- `--log-level`
- `--log-output`
- `--include-raw`

### 4.3 `compare-fancyss`

用途：

- 对比两份 `fancyss jsonl`

当前主要用途：

- 独立 fallback 工具
- parsed cache restore 的变化摘要
- 手工调试 compare 内核

### 4.4 `summary`

用途：

- 对订阅输入做结构化摘要

它更偏排查和调试，不是当前 shell 主链路的核心入口。

---

## 5. 当前订阅接入链路

当前 `fancyss` 的默认订阅链路大致是：

1. shell 下载原始订阅内容
2. shell 用 `inspect` 做内容识别 / HTML 跳转判断
3. shell 将原始 payload 直接交给 `sub-tool parse-uri-lines`
4. `sub-tool` 输出：
   - 节点 `jsonl`
   - `summary.json`
   - `diff.tsv`
   - `diff.summary.json`
5. shell 消费这些结果并打印日志
6. shell 决定是否写入 schema2

对应 shell 入口主要在：

- [ss_node_subscribe.sh](/home/sadog/koolshare/fancyss/fancyss/scripts/ss_node_subscribe.sh): `sub_try_parse_uri_lines_with_tool`

---

## 6. 代码结构说明

当前 `sub-tool` 基本都集中在 [main.zig](/home/sadog/koolshare/fancyss/tool/sub-tool/src/main.zig)。

可以粗分为这几块：

### 6.1 CLI 与参数解析

主要是：

- `Command`
- `Options`
- `parseArgs()`
- `printUsage()`

维护者加参数时，通常至少要改：

- `Options`
- `printUsage()`
- `parseArgs()`

### 6.2 输入内容识别

主要是：

- `detectContentInfo()`
- `looksLikeHtml*`
- `looksLikeClashYaml()`
- `looksLikeJson*()`
- `looksLikeSsepEnvelope()`
- `maybeDecodeBase64Text()`

如果以后要扩展：

- 新的订阅 envelope
- 新的错误页模式
- 新的识别类型

通常从这里入手。

### 6.3 订阅解析主链路

主要是：

- `parseSubscription()`
- `parseLine()`

这里决定：

- 哪些 scheme 被支持
- 每行如何分派到对应 parser

### 6.4 协议 parser

当前主要 parser：

- `parseSs()`
- `parseSsr()`
- `parseVmess()`
- `parseVmessUriEncoded()`
- `parseVlessLike()`
- `parseTrojan()`
- `parseNaive()`
- `parseTuic()`
- `parseHy2()`

如果要新增协议支持，基本就是：

1. `parseLine()` 增加分支
2. 新增一个 `parseXxx()` 函数
3. 让它输出 `NormalizedNode`

### 6.5 fancyss 节点落地映射

主要是：

- `buildFancyssNodeJsonAlloc()`

这是“协议解析结果 -> fancyss 节点字段”最核心的位置。

如果以后：

- 新增协议
- 现有协议新增字段
- 现有字段改名

这里通常是必须修改的。

### 6.6 identity 与 compare

主要是：

- `appendIdentityFieldsAlloc()`
- `parseCompareNodeAlloc()`
- `writeCompareDiff()`
- `compare-fancyss`

这一块当前负责：

- canonical identity 生成
- diff 计算
- diff summary

如果以后出现：

- “同一节点被误判成删除+新增”
- “参数改变判定错误”
- “rename/param/new/deleted 统计不准”

优先看这里。

### 6.7 过滤与统计

主要是：

- `KeywordFilter`
- `shouldKeepRenderedNode()`
- `writeFancyssParseSummaryFile()`
- `writeParseLogs()`

这里当前负责：

- 简单关键词过滤
- 信息节点过滤
- 协议统计
- `summary.json`
- 解析摘要日志

---

## 7. 维护场景一：新增协议支持

## 7.1 需要改哪些地方

假设未来要新增某个新协议 `foo://`，维护顺序建议是：

1. 在 `parseLine()` 增加 scheme 分发
2. 新增 `parseFoo()`，输出 `NormalizedNode`
3. 在 `buildFancyssNodeJsonAlloc()` 增加 fancyss 映射
4. 在 `schemeSummaryKey()` / `renderSummaryKey()` 增加统计映射
5. 在 shell 的日志前缀函数里补类型映射
6. 补 README / 维护文档 / 测试样本

## 7.2 评估标准

新增协议前先问三个问题：

1. `fancyss` 运行时是否真的支持它
2. 订阅 URI 是否有稳定可依赖的社区格式
3. 这个协议在 `lite/full` 中的包型边界是什么

如果第 1 条都不成立，就不要先在 `sub-tool` 里解析。

---

## 8. 维护场景二：现有协议新增字段

这是以后最常见的维护场景，尤其是：

- `vless`
- `vmess`
- `trojan`
- `hy2`
- `tuic`

### 8.1 典型步骤

假设未来 `vless` 要支持一个新字段：

1. 在对应 parser 里把 query/path/auth 中的字段读出来
2. 在 `NormalizedNode` 增加字段，或者复用已有抽象字段
3. 在 `buildFancyssNodeJsonAlloc()` 映射到 fancyss 存储字段
4. 确认这个字段是否应该影响 identity secondary
5. 确认该字段是否需要进入二维码 / 分享链接 / 导出恢复链路
6. 做订阅测试 + 节点编辑测试 + 运行时测试

### 8.2 关于 identity 的原则

新增字段时，要判断：

- 这个字段是不是“连接参数”
- 它是否应该进入 secondary identity

一般来说：

- 会影响实际连接行为的字段，应当进入 secondary
- 纯显示字段，不应进入 secondary

如果加错，会直接导致：

- 参数改变无法识别
- 同节点被误判成新节点

---

## 9. 维护场景三：订阅 bug 排查顺序

如果以后订阅出问题，建议按下面顺序排：

### 9.1 先判断是哪一层

1. 下载层
   - 下载失败
   - HTML 跳转
   - 登录页
   - JSON 错误响应
2. 识别层
   - `inspect` 识别错
3. 解析层
   - `parse-uri-lines` 失败
   - 节点数不对
4. 映射层
   - 解析成功，但字段丢失 / 类型不对
5. compare 层
   - 误判 param/rename/new/deleted
6. shell 接入层
   - 日志不对
   - 缓存逻辑不对
   - 写库逻辑不对

### 9.2 排查时优先看的文件

- [ss_node_subscribe.sh](/home/sadog/koolshare/fancyss/fancyss/scripts/ss_node_subscribe.sh)
- [main.zig](/home/sadog/koolshare/fancyss/tool/sub-tool/src/main.zig)

### 9.3 优先收集的现场文件

路由器上优先看这些：

- `/tmp/upload/ss_log.txt`
- `/tmp/fancyss_subs/sub_file_encode_*.txt`
- `/tmp/fancyss_subs/sub_file_decode_*.txt`
- `/tmp/fancyss_subs/online_*_*.txt`
- `/tmp/fancyss_subs/local_*_*.txt`
- `/tmp/fancyss_subs/*.summary.*`
- `/tmp/fancyss_subs/*.diff.*`

### 9.4 常见 bug 类型

#### A. 节点整批误判成删除+新增

优先看：

- compare 的 canonical 逻辑
- `password` / `tuic_json` / `xray_json` 的规范化
- identity primary / secondary 的输入口径

#### B. 协议数量统计不对

优先看：

- `summary.json`
- `schemeSummaryKey()`
- `renderSummaryKey()`
- shell 是否还在混用旧 grep 统计

#### C. “初步解析成功”数字不对

优先看：

- `summary.json` 里的 `uri_lines`
- shell 是否错误使用了 `total_lines`

#### D. 用户手动改节点后再订阅，恢复摘要不对

优先看：

- `compare-fancyss`
- parsed cache restore 分支
- 明文字段与 base64 字段的 compare 规范化

---

## 10. 维护场景四：性能问题排查

### 10.1 先区分 shell 慢还是 sub-tool 慢

如果日志里：

- `🧩检测到sub-tool` 到 `🧩sub-tool解析完成` 很慢
  说明是 `sub-tool` 解析本身
- `🧩sub-tool解析完成` 到 `ℹ️在线节点解析完毕` 很慢
  说明是 shell 后处理
- `⌛节点写入前准备` 到 `😀准备完成` 很慢
  说明是 shell 导出/备份/引用捕获
- `开始写入节点` 到 `写入成功` 很慢
  说明是 schema2 写库

### 10.2 当前已知容易慢的点

- shell 全量导出 schema2 节点
- shell 全量 identity 重算
- schema2 全量重写
- 订阅后收尾的 direct cache / webtest warm

### 10.3 性能优化原则

- 优先减少 shell 的 `grep/cat/wc/jq` 多轮扫描
- 优先让 `sub-tool` 一次调用产出更多可复用结果
- 不要为了“升级兼容一次性补算”长期拖慢热路径

---

## 11. 构建与发布

本地常用：

```bash
cd tool/sub-tool
zig build
```

当前本地验证使用的 Zig 版本：

- `0.15.2`

发布构建：

```bash
cd tool/sub-tool
bash scripts/build-release.sh --no-upx aarch64
```

常见产物：

- `tool/sub-tool/dist/sub-tool-vX.Y.Z-linux-aarch64`
- `tool/sub-tool/dist/sub-tool-vX.Y.Z-linux-x86_64`

路由器上实际同步位置：

- `/koolshare/bin/sub-tool`

---

## 12. 回归测试建议

### 12.1 本地最小样本

每次改 parser / compare / summary，至少做：

- 单协议最小样本
- `reuse-ids-from`
- `compare-with`
- `diff-summary-output`
- `summary-output`

### 12.2 GS7 实测

后续所有 `fancyss` 前后端改动，订阅相关优先在 GS7 验证。

建议至少测：

1. 正常订阅
2. 原始内容未变化 -> parsed cache restore
3. 节点增删改后再订阅
4. 全删订阅节点后重新全新订阅
5. 复杂过滤表达式回退提示

### 12.3 tmp_test_file 批量兼容性

常用脚本：

- [test_subtool_airport_compat.py](/home/sadog/koolshare/fancyss/tmp_test_file/test_subtool_airport_compat.py)

它适合做：

- 当前版本对历史样本的批量兼容性扫描
- 协议覆盖统计
- 失败类型聚类

输出目录示例：

- `tmp_test_file/subtool_compat_YYYYmmddHHMMSS/`

---

## 13. 当前仍未完成的点

截至当前版本，`sub-tool` 仍然没有完成：

- `SSEP` 真正会话解密
- `Clash/Mihomo` 配置解析
- `Sing-box` 配置解析
- 本地节点库导出 / 写入计划生成
- schema2 真正写库
- 复杂 regex 过滤引擎
- 订阅下载

这些要么不属于 `sub-tool` 边界，要么应当放到未来 `node-tool`。

---

## 14. 一句话结论

维护 `sub-tool` 时，请始终把它当成“订阅输入 -> 结构化订阅结果”的数据面工具，而不是 shell orchestration 的替代品。
