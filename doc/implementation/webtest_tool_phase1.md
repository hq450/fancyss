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
