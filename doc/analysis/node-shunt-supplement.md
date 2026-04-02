# fancyss 节点分流补充分析

> 本文是对 `doc/design/node-shunt-design.md`（设计文档）和 `doc/implementation/node-shunt-mvp.md`（MVP 文档）的补充分析。
> 基于 3.5.10 首版实现的代码审查，梳理设计与实现之间的差异、技术债务、后续功能方向和优先级建议。

---

## 1. 文档定位

- **设计文档**：定义了一期正式方案的完整蓝图，包括规则资产、routing 优先级、基础模板、IPv6 策略等。
- **MVP 文档**：记录了首个可用版的实际落地方案和 GS7 联调结果。
- **本文**：补充分析 MVP 未覆盖的技术细节，提出下一阶段可执行的优化和功能方向。

三者关系：设计文档是长期目标，MVP 文档是当前快照，本文是从当前快照到长期目标之间的桥接分析。

---

## 2. MVP 与设计文档差异追踪

| 设计文档章节 | 设计文档描述 | MVP 实际状态 | 影响评估 | 备注 |
|---|---|---|---|---|
| §2.7 geosite-fancyss.dat | 自建 geosite 资产 | 未实现，使用 TXT 内联到 xray routing domain 数组 | xray.json 体积偏大（gfw 6446条、media 1306条），但功能正常 | 可后续切换，不阻塞上线 |
| §2.7 geoip-fancyss.dat | 自建 geoip 资产 | 未实现 | ingress_mode=2 时由 iptables chnroute 兜底，无实际影响；ingress_mode=5 且关闭绕过大陆IP 时存在风险 | 见 §3 详细分析 |
| §12.2 shunt_direct / shunt_proxy | 独立 DNS 运行时域名文件 | 复用 `/tmp/black_list.txt` 追加分流域名 | keyword 规则不会同步到 DNS 侧 | 一版折中方案，后续需独立化 |
| §15 routing 优先级 | 10 级优先级，含 geoip/white_list/black_list/系统 tag | MVP 实现仅覆盖 1（socks-in→兜底）、8（域名规则→目标节点）、10（fallback） | 其余由 iptables 层承担，功能等效但语义分布在两层 | 后续引入 geosite/geoip 后可收拢 |
| §16 基础模板 | 三个基础模板（按需代理/代理优先/全局分流） | 简化为 ingress_mode=2（大陆白名单）和 ingress_mode=5（全量） | GFW 兼容引流（按需代理）暂不可用 | 见 §10 后续方向 |
| §19 规则存储 | TSV 文件存储 | dbus 存 base64(json) + 镜像到 node_shunt_rules.json | 规则量小时无问题，规则增多后 dbus 容量可能成瓶颈 | 后续迁移 |
| §25 实施顺序 | 先构建 geosite/geoip → 再实现 runtime → 再做 UI | 实际先做 runtime + UI，规则资产用 TXT 过渡 | 更务实的落地路径，但留下了资产债务 | 设计文档已追加说明 |

---

## 3. routing 层 geoip 规则缺失分析

### 3.1 当前状态

`fss_shunt_build_xray_config` 生成的 xray routing rules 如下：

```
1. inboundTag=socks-in → proxy{current_id}     （23456 走兜底节点）
2. inboundTag=api-in → api                       （stats API）
3. [DNS relay routes]                             （DNS UDP 中继，如有）
4. [用户节点分流域名规则]                         （按 active_rules.tsv 顺序）
5. fallback → default_outbound_tag               （兜底或 DIRECT）
```

没有任何 geoip 规则，也没有 white_list / black_list / cn / private 等系统 tag 的 routing 规则。

### 3.2 为什么当前能正常工作

在 `ingress_mode=2`（大陆白名单引流）下：

- iptables `SHADOWSOCKS_SHU` 链已经做了 `chnroute → RETURN`
- 大陆 IP 流量在 iptables 层就被放行，不会进入 xray
- xray 只收到"应该走代理"的流量，routing 中只做节点分流即可

### 3.3 风险场景

在 `ingress_mode=5`（全量引流）下：

- iptables `SHADOWSOCKS_SHU` 链只放行 `white_list`，其余全部进入 xray
- 如果用户同时关闭"绕过大陆IP"（即不加载 chnroute ipset），**所有流量**都会进入 xray
- 此时 xray routing 中没有 `geoip:cn → direct`，大陆流量会命中 fallback
- 若 fallback 是 `default_proxy`，大陆流量会被送往代理节点

### 3.4 分阶段建议

**短期（当前版本）**：

- `ingress_mode=5` 时，iptables 链仍然保留 chnroute 放行逻辑（当前 `init_shunt_chain_v4` 在 ingress_mode=5 时没有 chnroute 规则，但"绕过大陆IP"开关在上层 `load_nat` 中统一处理）
- 在文档和前端明确：`全量引流` 模式建议配合"绕过大陆IP=开启"使用

**中期（geoip-fancyss.dat 就绪后）**：

- 在 `fss_shunt_build_xray_config` 中，当 `ingress_mode=5` 且绕过大陆IP关闭时，插入：
  ```json
  {"type":"field","ip":["geoip:cn"],"outboundTag":"direct"}
  ```
- 需要把 `geoip-fancyss.dat` 放到 xray 可加载的路径

**长期**：

- routing 规则逐步收拢到 xray 层，减少对 iptables 的依赖
- 但始终保留 iptables 层的 chnroute 快速放行作为性能优化手段

---

## 4. geoip-fancyss.dat 构建方案

### 4.1 目标

从 fancyss 自维护的 `chnroute.txt` + `chnroute6.txt` 生成 `geoip-fancyss.dat`，仅包含：

- `cn`：大陆 IPv4 + IPv6 网段
- `private`：RFC1918 / RFC4193 等私有地址段

### 4.2 构建方式

建议参考 `v2fly/geoip` 项目的自定义构建方式：

1. 将 `chnroute.txt` 和 `chnroute6.txt` 合并为一个 CIDR 列表
2. 使用 `v2fly/geoip` 的 `custom` 模式或直接用 Go 工具 `geoip` 编译
3. `private` tag 使用固定的 RFC 私有地址列表

### 4.3 构建脚本位置

建议新建：

- `fancyss/scripts/ss_build_geoip_fancyss.sh`

构建流程：

```
rules_ng/chnroute.txt + chnroute6.txt → geoip-fancyss.dat
                                       → fancyss/ss/rules/geoip-fancyss.dat
```

### 4.4 运行时加载

xray 通过 `XRAY_LOCATION_ASSET` 环境变量指定 `.dat` 文件目录。当前 fancyss 已有类似机制，确认 `geoip-fancyss.dat` 放入该目录即可被 routing 引用。

### 4.5 IPv6 约束

`geoip-fancyss.dat:cn` 必须同时包含 IPv4 和 IPv6 网段。这是设计文档 §8.3 的硬要求：若只做 IPv4 版 `cn`，双栈场景下 IPv6 大陆地址会被误送代理。

---

## 5. geosite-fancyss.dat 构建方案

### 5.1 问题

当前 `fss_shunt_emit_routing_rules_json` 将每条规则的所有域名逐行拼接到 xray routing 的 `domain` JSON 数组中。以 `gfw.txt`（6446 条）为例，单条规则就会产生约 130KB 的 JSON。多条规则叠加后，`xray.json` 可达数百 KB。

路由器上的影响：

- xray 启动时解析大 JSON 文件的内存和 CPU 开销增加
- 配置文件读写和调试变得困难
- `test_xray_conf` 验证时间变长

### 5.2 方案

将 `rules_ng2/shunt/*.txt` 编译成 `geosite-fancyss.dat`，xray routing 中改用 `geosite` 引用：

```json
{"type":"field","domain":["geosite:fancyss-ai"],"outboundTag":"proxy36"}
```

替代当前的：

```json
{"type":"field","domain":["domain:openai.com","domain:anthropic.com",...],"outboundTag":"proxy36"}
```

### 5.3 构建方式

参考 `v2fly/domain-list-community` 的构建链：

1. 将每个 `shunt/*.txt` 中的 `domain:` / `full:` / `keyword:` 转换为 `domain-list-community` 格式
2. 使用 `v2fly/domain-list-community` 的编译工具生成 `.dat`
3. 每个 txt 对应 `geosite-fancyss.dat` 中的一个 tag，如 `fancyss-ai`、`fancyss-media` 等

### 5.4 兼容策略

切换到 `.dat` 后，TXT 文件仍需保留：

- DNS 侧（smartdns / chinadns-ng）需要纯文本域名列表
- 前端 manifest 展示需要 count 等元数据
- 调试时需要可读的规则源

因此 TXT 和 `.dat` 是并存关系，不是替代关系。

### 5.5 自定义域名集合的处理

用户自定义域名集合（`custom` 类型规则）数量较少，继续使用 domain 数组内联即可，不需要编入 `.dat`。

---

## 6. 内置分类扩充建议

### 6.1 建议提前纳入的分类

| tag | 理由 | 预估域名数 |
|---|---|---|
| `telegram` | 节点分流最高频目标之一，用户手动输入域名易出错 | ~30 |
| `github` | 开发者群体核心需求，且 GitHub 域名分散（github.com, githubusercontent.com, githubassets.com 等） | ~40 |

这两个分类在 `DustinWin/domain-list-custom` 中已有现成源。

### 6.2 建议暂不纳入的分类

| tag | 原因 |
|---|---|
| `google` | 域名量大，且 google-cn 已做直连分流，完整 google 分类的边界难界定 |
| `applications` | 定义模糊，不同用户理解差异大 |
| `trackerslist` | BT Tracker 场景小众，且域名变动频繁 |

### 6.3 实现方式

在 `ss_build_shunt_rules_ng2.sh` 的 tag 列表中追加 `telegram` 和 `github` 条目即可，同时更新 `shunt_manifest.json.js` 和 `fss_shunt_rule_tag_file` 的 case 分支。

---

## 7. 规则重叠检测

### 7.1 问题

当前内置分类之间存在包含关系：

- `media` 是 `youtube` + `netflix` + `disney` + `max` + `primevideo` + `appletv` + `spotify` + ... 的超集
- 如果用户同时添加 `media → 节点A` 和 `youtube → 节点B`，youtube 域名的实际出口取决于规则顺序

这不是 bug，但用户可能不理解为什么调整顺序后行为变化。

### 7.2 manifest 增强

在 `shunt_manifest.json.js` 中为有包含关系的分类添加 `includes` 字段：

```json
{
  "id": "media",
  "label": "媒体合集",
  "includes": ["youtube", "netflix", "disney", "max", "primevideo", "appletv", "spotify", "bilibili"]
}
```

### 7.3 前端提示

当用户添加一条新规则时，前端检查：

- 新规则的 preset 是否已被某条已有规则的 `includes` 覆盖
- 或新规则的 preset 的 `includes` 列表中是否包含已有规则的 preset

若检测到重叠，显示提示（不阻止操作）：

> "当前规则 `YouTube` 已被规则 `媒体合集` 覆盖，实际生效取决于规则顺序。"

### 7.4 后端日志

`fss_shunt_prepare_runtime` 中可选地输出重叠告警到 syslog，便于排障。

---

## 8. 流量统计前端展示

### 8.1 当前基础

`ss_shunt_stats.sh` 已经通过 Xray Stats API 采集各 outbound 的上行/下行流量，输出到 `/tmp/upload/ss_shunt_stats.json`，格式如：

```json
{
  "ok": 1,
  "enabled": 1,
  "updated_at": 1711700000,
  "stats": {
    "proxy15": {"uplink": 12345, "downlink": 67890, "total": 80235},
    "proxy2": {"uplink": 1000, "downlink": 5000, "total": 6000},
    "direct": {"uplink": 500, "downlink": 2000, "total": 2500}
  }
}
```

`ss_conf.sh` 中已有 `shunt_stats` 命令入口。

### 8.2 前端展示建议

在节点分流页面顶部的运行状态区域，增加流量统计卡片：

- 每个出站节点显示"上行 / 下行 / 总计"
- 兜底节点和 DIRECT 各显示一行
- 定时轮询（10-30 秒）刷新

### 8.3 与规则列表的关联

规则列表的每一行可以在右侧显示该目标节点的累计流量，帮助用户直观判断规则是否命中、分流比例是否合理。

---

## 9. 规则导入导出

### 9.1 导出

前端增加"导出规则"按钮：

- 读取当前 `ss_basic_shunt_rules` 的 base64 json
- 解码后下载为 `node_shunt_rules.json`
- 文件中仅包含规则定义（preset、custom_b64、target_node_id 等），不含节点详情

### 9.2 导入

前端增加"导入规则"按钮：

- 上传 JSON 文件
- 校验格式（必须是规则数组）
- 校验 target_node_id 引用有效性：
  - 节点存在 → 保留
  - 节点不存在 → 标记为失效，但仍导入（用户可后续修改目标节点）
- 与现有规则的合并策略：替换 or 追加，由用户选择

### 9.3 备份恢复集成

需确认 `ss_conf.sh` 的 `backup_conf_json` / `backup_tar` 已经覆盖以下 dbus key：

- `ss_basic_shunt_rules`
- `ss_basic_shunt_default_node`
- `ss_basic_shunt_ingress_mode`
- `ss_basic_shunt_rule_ts`

若 dbus 全量导出覆盖 `ss_*` 前缀，则 dbus 部分已自动包含。但文件侧需确认 `configs/fancyss/node_shunt_rules.json` 是否纳入备份 tar 包。

---

## 10. ingress_mode=1（GFW 兼容引流）后续方向

### 10.1 场景

部分用户希望：

- 只有 GFW 域名和自定义分流域名走代理
- 其余全部直连
- 但在代理流量中仍然要做节点分流

这对应设计文档 §16.1 的"按需代理（GFW 兼容）"。

### 10.2 iptables 行为

`ingress_mode=1` 的 `SHADOWSOCKS_SHU` 链行为应类似当前 `mode=1`（gfwlist 黑名单模式）：

- `black_list` 命中 → 送入代理
- `gfwlist` ipset 命中 → 送入代理
- 其余 → RETURN（直连）

但需要额外把 `shunt_proxy` 域名解析的 IP 也加入 gfwlist ipset，否则分流规则中引用的非 GFW 域名无法进入 xray。

### 10.3 复杂度评估

这需要在 DNS 侧实现 `shunt_proxy.txt` 独立化（当前复用 black_list.txt），否则会和 gfwlist 模式的 ipset 逻辑混淆。建议在 DNS 侧独立化完成后再引入。

---

## 11. 技术优化项

### 11.1 awk 规范化逻辑去重

`fss_shunt_materialize_rule_domains` 中 `builtin` 和 `custom` 两个分支的 awk `normalize()` 函数完全相同（约 30 行）。

建议抽取为共享 awk 脚本文件：

```
scripts/awk/normalize_domain_token.awk
```

两个分支改为 `awk -f normalize_domain_token.awk -v ...` 调用。

### 11.2 域名内联 JSON 拼接性能

`fss_shunt_emit_routing_rules_json` 使用 awk 逐行 `printf` 拼接 JSON 字符串。对于大规则文件（如 gfw 6446 条），每次 `printf` 一个域名开销累积可观。

短期优化：在 awk 中用数组收集后一次性 `printf`，减少 I/O 次数。

长期方案：切换到 `geosite-fancyss.dat` 引用后，此问题自然消失。

### 11.3 缓存一致性时间戳

`fss_shunt_runtime_key` 用 `ingress_mode | rule_ts | node_config_ts` 三元组判断缓存新鲜度。但如果规则 TXT 文件（如 `rules_ng2/shunt/ai.txt`）通过在线更新脚本更新了内容，这个 key 不会变化。

建议：

- 在规则更新脚本 `ss_build_shunt_rules_ng2.sh` 或 `ss_rule_update.sh` 执行后，主动 bump `ss_basic_shunt_rule_ts`
- 或在 runtime_key 中加入规则资产目录的聚合 mtime

---

## 12. 前端美化方向

### 12.1 规则列表交互

- **拖拽排序**：fancyss 已引入 `tablednd.js`，可直接用于规则表格的拖拽排序，替代当前的上移/下移按钮
- **行内编辑**：类别和目标节点可以在表格行内直接切换，不需要弹窗

### 12.2 节点选择增强

- 下拉列表显示：节点名称 + 协议类型标签（如 `[VLESS] 香港节点01`）
- 不支持参与分流的节点灰显并标注原因

### 12.3 状态指示

- 有效规则：正常样式
- 失效规则（目标节点已删除或类型不支持）：标红 + 感叹号图标
- 兜底规则：视觉区分（底色不同或分隔线）

### 12.4 流量统计卡片

见 §8，在分流页顶部渲染各出站的实时流量。

### 12.5 分类图标

为常用内置分类添加小图标（16x16 PNG 或 SVG）：

- AI / YouTube / Netflix / Disney+ / Spotify 等都有辨识度高的品牌色或符号
- 可以用简单的首字母色块或抽象图标，避免品牌商标风险

---

## 13. 配置备份恢复集成确认项

以下各项需要逐一确认是否已正确覆盖：

| 确认项 | 备份方向 | 恢复方向 | 当前状态 |
|---|---|---|---|
| `ss_basic_shunt_rules` (dbus) | dbus 全量导出应已包含 | dbus 全量导入应已包含 | 待确认 |
| `ss_basic_shunt_default_node` (dbus) | 同上 | 同上 | 待确认 |
| `ss_basic_shunt_ingress_mode` (dbus) | 同上 | 同上 | 待确认 |
| `ss_basic_shunt_rule_ts` (dbus) | 同上 | 同上 | 待确认 |
| `configs/fancyss/node_shunt_rules.json` (文件) | 需确认是否纳入 tar | 需确认恢复后是否触发 runtime rebuild | 待确认 |
| 恢复后 node_direct 刷新 | - | 需确认 | 待确认 |
| 恢复后 outbound cache 重建 | - | 需确认 | 待确认 |

---

## 14. 建议优先级排序

基于"用户感知收益 × 实现可行性 ÷ 风险"排序：

### P0：当前版本应尽快补齐

1. **确认备份恢复覆盖**（§13）：不补齐则用户恢复配置后分流规则丢失
2. **缓存时间戳 bump**（§11.3）：规则更新后缓存不失效会导致难以排查的问题

### P1：下一版本建议纳入

3. **流量统计前端展示**（§8）：后端已就绪，前端工作量小，用户感知强
4. **内置分类扩充 telegram + github**（§6）：改动极小（加两条 tag），覆盖高频需求
5. **规则重叠提示**（§7）：避免用户困惑，manifest 改动 + 前端几行检查逻辑
6. **前端美化 - 状态指示**（§12.3）：失效规则标红，实现简单但体验提升大

### P2：中期规划

7. **geoip-fancyss.dat 构建**（§4）：解除 ingress_mode=5 的风险
8. **geosite-fancyss.dat 构建**（§5）：解决 xray.json 体积问题，提升启动性能
9. **前端美化 - 拖拽排序**（§12.1）：已有 tablednd.js 基础
10. **规则导入导出**（§9）：用户迁移和分享场景

### P3：长期方向

11. **ingress_mode=1 GFW 兼容引流**（§10）：需要 DNS 侧独立化作为前置
12. **awk 去重 + 域名内联性能优化**（§11.1, §11.2）：切到 geosite.dat 后自然解决
13. **前端美化 - 分类图标**（§12.5）：锦上添花
