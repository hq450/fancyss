# fancyss 未来待办：订阅解析与二维码生成

本文用于记录当前未立即实施，但后续可能继续推进的订阅解析和二维码生成相关工作。

适用范围：

- `fancyss full`
- 节点分享链接 / 订阅解析
- 标准 URI / 社区 URI 二维码生成

---

## 一、当前状态简表

### 1. 已支持的订阅解析

- `ss://`
- `ssr://`
- `vmess://`
- `vless://`
- `trojan://`
- `hysteria2://`
- `hy2://`
- `tuic://`
- `naive+https://`
- `naive+quic://`

说明：

- `tuic`、`naive` 仅 `full` 版本可导入
- `lite` 版即使识别到这两类链接，也只能跳过

### 2. 已支持的二维码生成

- `ss`
- `ssr`
- 标准 `vmess`
- 标准 `vless/xray`
- `trojan`
- `hysteria2`
- `tuic`
- `naive`

### 3. 当前仍不支持的二维码场景

- `v2ray json` 节点
- `xray json` 节点
- 部分无法稳定映射为标准 URI 的 `xray` 组合：
  - 旧 `VMess alterId`
  - `TCP + HTTP` 伪装
  - `QUIC`
  - 其它只能靠原始 JSON 才能完整表达的组合

---

## 二、后续建议优先级

### P1：Naive 节点补齐 `extra-headers`

当前状态：

- 订阅解析时，如果 `naive` 分享链接带有 `extra-headers`，只会提示检测到该参数
- 该参数不会进入节点模型
- 启动参数、导出、二维码也都不会保留

后续建议：

1. 为 `naive` 增加独立字段，例如：
   - `naive_extra_headers`
2. 前端节点编辑页增加对应输入框
3. 后端启动 `naive` 时，将该字段写入实际配置
4. 导出 / 导入 / 订阅恢复 / schema2 节点迁移保持该字段
5. 二维码 / 标准分享 URI 生成时，按社区约定拼回 `extra-headers`

风险点：

- `extra-headers` 本质上不是 `naiveproxy` 官方标准分享字段，而是社区扩展
- 需要确认 fancyss 当前 `naive` 启动方式是否能稳定表达多组 header

---

### P1：TUIC 社区 URI 参数扩展支持

当前状态：

- 目前仅保守支持这些字段：
  - `server`
  - `uuid`
  - `password`
  - `ip`
  - `alpn`
  - `congestion_control`
  - `allow_insecure / skip_cert_verify`
  - `sni`（仅在 `host` 为 IP 时做 server/ip 拆分映射）

后续建议：

1. 评估并补齐更多社区常见参数：
   - `udp_relay_mode`
   - `zero_rtt_handshake`
   - `disable_sni`
   - `heartbeat`
   - `reduce_rtt`
   - `request_timeout`
   - `max_udp_relay_packet_size`
2. 明确哪些字段可以安全映射到 `relay`
3. 对无法稳定映射的字段，考虑：
   - 保留原始 URI 扩展字段
   - 或新增“高级 JSON 补充字段”
4. 若未来 fancyss 的 TUIC 运行模型调整，再同步升级订阅解析与二维码生成

风险点：

- `tuic://` 目前更接近社区约定，而非统一官方标准
- 不同客户端对 query 参数命名、布尔值、默认值兼容性可能不完全一致

---

### P2：Trojan 衍生分享格式继续兼容

当前状态：

- 已支持常见 `trojan://password@host:port?...`
- 已兼容常见 ws 风格：
  - `type=ws`
  - `host=`
  - `path=`
- 也兼容一部分旧社区写法：
  - `plugin=obfs-local`
  - `obfs=websocket`
  - `obfs-host=`
  - `obfs-uri=`

后续建议：

1. 评估是否补充 `trojan-go://` 单独 scheme
2. 评估是否补充更多社区 TLS / mux / websocket 衍生参数
3. 对 fancyss 内部实际未使用的参数，需要明确：
   - 忽略
   - 保留
   - 或落地为节点字段

说明：

- 这项优先级低于 `naive extra-headers` 和 `TUIC` 参数扩展

---

### P2：二维码生成继续扩大覆盖范围

后续可评估：

1. `xray json` 节点二维码
   - 难点在于标准 URI 无法完整表达全部 JSON 能力
2. `v2ray json` 节点二维码
3. 对无法表达为标准 URI 的节点，改为：
   - 生成“原始 JSON 二维码”
   - 或弹出“复制原始配置”按钮
4. 当前二维码弹窗只有“复制节点 URI”
   - 后续可补：
     - 复制 JSON
     - 复制分享链接
     - 下载节点配置

---

## 三、实现时建议保持的约束

后续继续做这块时，建议遵守以下原则：

1. 只把 fancyss 当前运行模型能稳定消费的字段纳入订阅解析
2. 对社区扩展字段，优先“保留 + 可见”，不要贸然“解析后丢失”
3. 订阅解析、前端编辑、导出恢复、二维码生成、schema2 节点存储必须同步考虑
4. `full` / `lite` 的能力边界继续保持清晰
5. 如果某种 URI 只是社区习惯写法，不是官方标准，要在文档中明确标注

---

## 四、建议的后续实施顺序

建议顺序：

1. `naive extra-headers` 全链路支持
2. `TUIC` 更多 query 参数落地
3. `trojan` 衍生 scheme / 参数兼容增强
4. `xray json` / `v2ray json` 的二维码策略设计

---

## 五、参考资料

后续继续做时，可优先参考这些资料：

- Hiddify URL Scheme wiki
  <https://github.com/hiddify/hiddify-app/wiki/URL-Scheme>
- Trojan-Go URL Scheme
  <https://p4gefau1t.github.io/trojan-go/developer/url/>
- NaiveProxy 官方 README
  <https://github.com/klzgrad/naiveproxy>
- DuckSoft 对 `naive+https` / `naive+quic` 的社区 URI 整理
  <https://gist.github.com/DuckSoft/ca03913b0a26fc77a1da4d01cc6ab2f1>
- dae 讨论中的 TUIC URI 示例
  <https://github.com/daeuniverse/dae/discussions/182>
