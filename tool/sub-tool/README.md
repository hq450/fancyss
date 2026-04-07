# sub-tool

`sub-tool` 是一个使用 Zig 编写的轻量级订阅内容工具。

维护文档：

- [sub-tool 维护文档](../../doc/implementation/sub-tool-maintenance.md)

它的定位不是立即“完全替代 `ss_node_subscribe.sh`”，而是先把订阅链路里最适合下沉到 Zig 的部分独立出来：

- 订阅内容识别
- Base64 订阅解码
- URI 行订阅解析
- 节点归一化输出
- 汇总统计

也就是说，当前更合理的职责边界是：

- `ss_node_subscribe.sh`
  - 下载
  - 重试
  - 代理下载策略
  - 缓存编排
  - `dbus` 写回
  - 当前节点/备用节点恢复
  - 订阅任务 orchestration
- `sub-tool`
  - 识别“拿到手的订阅内容”是什么
  - 把内容转成结构化节点集
  - 为后续 `SSEP` 解密、订阅 diff、更多格式支持提供稳定入口

## 当前版本

`0.1.8`

当前代码按 Zig `0.15.2` 编写并验证。

## 当前命令

```bash
sub-tool inspect
sub-tool parse-uri-lines
sub-tool summary
sub-tool version
```

## 当前能力

### `inspect`

识别输入内容类型，当前支持识别：

- 直接 URI 行订阅
- Base64 包裹的 URI 行订阅
- 疑似 `SSEP Envelope`
- HTML 登录页
- HTML/JS 跳转页
- 其它普通 HTML 页面
- Clash/Mihomo YAML 配置
- 普通 JSON
- JSON 错误响应
- 文本错误响应
- gzip 内容
- 未知内容

当识别结果为 `HTML/JS` 跳转页时，`inspect` 会额外输出 `redirect_url`，
用于让 shell 在无 Python 环境下继续跟随跳转并重新下载真正的订阅内容。

### `parse-uri-lines`

把订阅内容解析成标准 `jsonl`。

当前支持协议：

- `ss`
- `ssr`
- `vmess`
- `vless`
- `trojan`
- `naive+https`
- `naive+quic`
- `tuic`
- `hy2`
- `hysteria2`

当前也支持解析 `Clash/Mihomo YAML` 订阅中的 `proxies` 节点，现阶段至少包括：

- `ss`
- `ss2022`
- `ss + obfs`
- `trojan`

### `summary`

输出订阅内容的结构化摘要，当前包括：

- 总行数
- 有效节点数
- 错误节点数
- 各协议节点数量
- 检测到的输入类型

## 当前输出格式

`parse-uri-lines` 当前支持两种输出：

- 默认输出：通用归一化节点 JSONL
- `--format fancyss`：输出 `fancyss` 当前可直接消费的订阅节点 JSONL

默认输出保持通用格式，这是有意的，原因是：

- 先把“解析”和“写库”解耦
- 后续可以让 `node-tool` 或 shell 再做 schema2/legacy 映射
- 避免一开始就把 `sub-tool` 和 `dbus`、旧字段兼容、当前节点恢复强绑定

当前每行节点至少会包含：

- `scheme`
- `name`
- `server`
- `port`

并按协议输出必要字段，例如：

- `method`
- `password`
- `uuid`
- `network`
- `security`
- `sni`
- `host`
- `path`
- `protocol`
- `obfs`

如果使用：

```bash
sub-tool parse-uri-lines --format fancyss
```

则当前会直接输出兼容 `fancyss` 订阅落库链路的 JSONL，已接入：

- `fancyss/scripts/ss_node_subscribe.sh`

当前实际接入策略是：

- 路由器上检测到 `/koolshare/bin/sub-tool` 时，优先用 `sub-tool`
- `sub-tool` 失败时，回退旧的 shell 协议解析分支

也就是说：

- 当前已经不是“纯旁路工具”
- 但仍然保留旧解析器作为保险回退

`parse-uri-lines` 还支持一组日志参数：

- `--log-level none|summary|verbose`
- `--log-output <path>`

含义如下：

- `none`
  - 不输出解析日志
- `summary`
  - 输出解析摘要
- `verbose`
  - 在摘要基础上追加逐节点日志

当前 `fancyss` 的接入策略是：

- 默认只输出摘要
- 用户在前端勾选开关后，才输出逐节点日志

## 还没做的事

当前版本还没有实现：

- `SSEP` 真正的会话解密
- `Sing-box` 格式订阅解析
- 节点 diff
- 直接写入 `schema2`
- 直接替代 `ss_node_subscribe.sh` 的下载/缓存/落库逻辑
- 自动进入 `fancyss` 打包产物分发链路

## 构建

直接构建：

```bash
zig build
```

运行测试：

```bash
zig build test
```

构建后可执行文件位于：

```bash
./zig-out/bin/sub-tool
```

如需一次性输出发布产物：

```bash
bash ./scripts/build-release.sh
```

发布脚本默认启用 UPX 压缩：

- `armv5te` 使用 `UPX 4.2.4`
- 其它目标使用 `UPX 5.0.2`

关闭 UPX：

```bash
bash ./scripts/build-release.sh --no-upx
```

## 使用示例

识别订阅内容：

```bash
./zig-out/bin/sub-tool inspect --input sample.txt
```

解析 URI 行订阅为 JSONL：

```bash
./zig-out/bin/sub-tool parse-uri-lines --input sample.txt --output nodes.jsonl
```

解析为 `fancyss` 兼容 JSONL：

```bash
./zig-out/bin/sub-tool parse-uri-lines \
  --input sample.txt \
  --format fancyss \
  --group "airport-a" \
  --source-tag "sub_a" \
  --mode 2 \
  --pkg-type full \
  --log-level summary \
  --log-output parse.log \
  --include-raw
```

附带来源信息：

```bash
./zig-out/bin/sub-tool parse-uri-lines \
  --input sample.txt \
  --group "airport-a" \
  --source-tag "sub_a" \
  --include-raw
```

输出摘要：

```bash
./zig-out/bin/sub-tool summary --input sample.txt
```

在无 Python 的路由器环境做兼容性分类：

```bash
sh ./tool/sub-tool/scripts/test-compat-sh.sh \
  --input /tmp/airport_all.txt \
  --limit 50
```

这个脚本只依赖：

- `sh`
- `curl` 或 `wget`
- `sub-tool`
- `awk` / `sed` / `sort` / `uniq`

输出目录默认在 `/tmp/subtool_compat_runs/`，会生成：

- `results.tsv`
- `summary.txt`
- `samples/`

## 一句话定位

`sub-tool` 的合理定位是：

- 先替代 `ss_node_subscribe.sh` 里“订阅内容识别 + 解码 + 解析 + 归一化”这一段
- 而不是立刻替代整个订阅脚本
