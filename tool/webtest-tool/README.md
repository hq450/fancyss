# webtest-tool

`webtest-tool` 是面向 fancyss 批量测速场景的独立 Zig 工具。

目标：

- 替代 `ss_webtest.sh` 中最重的 `curl_test()` 探测部分
- 不关心节点协议，只关心本地测试端口
- 支持批任务 JSON 输入
- 输出 `webtest.json` 和 `webtest.stream.jsonl`
- 配套控制端为 `webtestctl`
