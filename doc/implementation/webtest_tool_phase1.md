# webtest-tool Phase 1 实施文档

## 1. 定位

`webtest-tool` 是独立于 `status-tool` 的批量测速工具。

它不关心节点协议，只关心：

- 本轮公共测速参数
- 需要测试的节点 `id / identity / test_port`

## 2. 二进制

- `webtest-tool webtestd`
- `webtestctl`

## 3. 输入模型

批任务 JSON：

```json
{
  "batch_id": "20260410T210501Z_01",
  "url": "http://www.google.com/generate_204",
  "timeout_ms": 3000,
  "warmup": 1,
  "attempts": 2,
  "concurrency": 8,
  "output_json": "/tmp/upload/webtest.json",
  "output_stream": "/tmp/upload/webtest.stream.jsonl",
  "targets": [
    {"id":"1974","identity":"18ca2f22_9eafa1af","test_port":41001}
  ]
}
```

## 4. 输出模型

- `webtest.json`：完整快照
- `webtest.stream.jsonl`：增量事件流

## 5. Phase 1 范围

- 先完成独立工具骨架
- 再完成 `run --config` + `status` + `stop`
- 探测只基于 `127.0.0.1:<test_port>`
- 后续再接 `ss_webtest.sh`

## 6. 当前落地方式

- `ss_webtest.sh` 的 xray-like 批量测速已接入 `webtest-tool run --config`
- Phase 1 只把 `output_json / output_stream` 作为工具真相
- shell 在每个分块结束后导入 `output_json`，再更新 `webtest.state / webtest.txt`
- 暂不让 `webtest-tool` 直接写 fancyss 的 legacy `webtest.txt`，避免分块场景提前写入 `stop>stop`

## 7. Phase 2：分组 manifest

### 7.1 目标

Phase 2 的目标是让 `webtest-tool` 从“测一组端口”升级为“执行一份测速计划”。

这份计划需要表达：

- 不同协议组的执行顺序
- 每个协议组自己的并发限制
- 每个节点的本地测试端口
- 每个节点可选的启动 / 停止 hook
- 每个节点进入测速前需要等待的本地端口

这样可以同时满足两类需求：

- `xray-like` 节点一次性准备全部入口，并由 `webtest-tool` 以较高并发测速。
- `ssr / naive / tuic` 这类需要临时拉进程的节点按协议分组限流，避免低性能机型一次性拉起过多进程。

### 7.2 输入模型 v2

v2 manifest 增加 `groups` 字段。为了兼容 Phase 1，顶层 `targets` 仍然保留。

```json
{
  "batch_id": "20260412T101000Z",
  "url": "http://www.google.com/generate_204",
  "timeout_ms": 3000,
  "warmup": 1,
  "attempts": 2,
  "concurrency": 12,
  "output_json": "/tmp/fancyss_webtest/webtest.json",
  "output_stream": "/tmp/fancyss_webtest/webtest.stream.jsonl",
  "legacy_result_file": "/tmp/fancyss_webtest/webtest.legacy",
  "legacy_stream_file": "/tmp/fancyss_webtest/webtest.legacy.stream",
  "legacy_emit_stop": false,
  "runtime_root": "/tmp/fancyss_webtest",
  "groups": [
    {
      "name": "xray-like",
      "concurrency": 12,
      "targets": [
        {"id":"101","identity":"...","test_port":41001}
      ]
    },
    {
      "name": "tuic",
      "concurrency": 2,
      "targets": [
        {
          "id":"201",
          "identity":"...",
          "test_port":42001,
          "start_script":"/tmp/fancyss_webtest/hooks_tc/201.start.sh",
          "stop_script":"/tmp/fancyss_webtest/hooks_tc/201.stop.sh",
          "wait_port":42001,
          "wait_timeout_ms":5000
        }
      ]
    }
  ]
}
```

### 7.3 执行语义

- 若存在 `groups`，`webtest-tool` 按 `groups[]` 顺序执行。
- 每个 group 内部使用该组 `concurrency`；缺省则回退到顶层 `concurrency`。
- 组与组之间串行，避免 `xray-like` 与 `tuic / naive / ssr` 混合抢资源。
- 同一组内由 worker 池并发执行。
- worker 在执行节点前：
  - 有 `start_script` 则先执行。
  - 有 `wait_port` 则等待端口 ready。
  - 端口 ready 后输出 `testing...`。
  - 探测完成后输出结果。
  - 有 `stop_script` 则执行清理。

### 7.4 输出语义

`webtest-tool` 输出继续保持：

- `output_json`：完整快照
- `output_stream`：JSONL 事件流
- `legacy_result_file` / `legacy_stream_file`：兼容 `webtest.txt` 格式

Phase 2 中，JSONL 事件建议增加 `group` 字段：

```json
{"type":"state","group":"tuic","id":"201","state":"testing","updated_at_ms":...}
{"type":"result","group":"tuic","id":"201","state":"ok","latency_ms":123}
```

legacy 文本仍保持：

```text
201>testing...
201>123
```

### 7.5 ss_webtest.sh 过渡策略

第一阶段仍由 `ss_webtest.sh` 生成 manifest：

- `xray-like` 组继续由 shell 准备 xray confdir。
- `ssr / naive / tuic` 组继续由 shell 生成 start / stop hook。
- `ss_webtest.sh` 将这些产物汇总为 `groups[]` manifest。
- `webtest-tool` 负责按组执行。

第二阶段由 `node-tool` 接管 manifest 生成：

- `node-tool webtest-manifest --output <file>`
- `ss_webtest.sh` 只负责状态初始化、调用 `node-tool`、调用 `webtest-tool` 和停止清理。

### 7.6 当前施工建议

1. 先让 `webtest-tool` 支持 `groups[]` 解析与执行，并兼容旧顶层 `targets`。
2. 再让 `ss_webtest.sh` 把当前 xray-like / ssr / naive / tuic 调用收敛为一份 grouped manifest。
3. 维持现有 `webtest.txt / webtest.stream` 兼容输出，避免前端一次性大改。
4. 确认 GS7/TUF 上 xray-like 仍保持 12 并发，非 xray-like 按原协议线程限制运行。
