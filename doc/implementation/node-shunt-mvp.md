# fancyss 3.5.10 节点分流 MVP 说明

## 1. 范围

本文描述 `3.5.10` 首个可用版“节点分流”的实际落地方案。

这份文档对应当前代码实现，不等同于 `doc/design/node-shunt-design.md` 中更完整的长期规划。

当前版本优先保证：

- 有独立运行模式
- 有前端规则管理入口
- 有可用的多节点 Xray routing
- 与现有 DNS / `node_direct` / `webtest` 缓存体系兼容
- 路由器上资源消耗可控

当前版本暂不追求：

- 自建 `geosite-fancyss.dat / geoip-fancyss.dat`
- 导入第三方 geosite 规则包
- 非 Xray 原生协议作为分流目标节点
- 复杂匹配（regexp / process / port / ASN）

---

## 2. 运行模式

新增独立模式：

- `ss_basic_mode=7`
- 前端名称：`xray分流模式`

`mode=7` 不复用当前节点自身保存的 `mode` 作为运行模式。

实际行为：

- 全局运行模式由 `ss_basic_mode` 决定
- 当前节点仍然保留自己的历史 `mode` 字段，用于退出 `mode=7` 后回到原有体系
- 当全局处于 `mode=7` 时，切换当前节点不会把插件带回旧的 `mode=1/2/5`

这部分在前后端都做了保护：

- 后端：`ss_base.sh` 会在导出当前节点字段后恢复全局 `mode=7`
- 前端：节点选择切换时，页面模式下拉不会被当前节点旧模式覆盖
- 前端保存时，不再把 `mode=7` 回写进当前节点自身的 `mode` 字段

---

## 3. 基础行为

当前版本已经移除“基础模板”选择，但新增了 `入口策略`：

- `ss_basic_shunt_ingress_mode=2`：`大陆白名单引流`
- `ss_basic_shunt_ingress_mode=5`：`全量引流`

默认值为 `2`。

也就是说，`mode=7` 当前不是简单复用 `SHADOWSOCKS_CHN / SHADOWSOCKS_GLO`，而是：

1. 先生成独立的 `SHADOWSOCKS_SHU / SHADOWSOCKS6_SHU`
2. 由该专用链决定哪些流量进入 xray 分流
3. 进入代理路径的流量，再进入 Xray 做“节点二次分流”

这样做的原因很直接：

- 与现有 ACL、QUIC、UDP、IPv6 抑制逻辑兼容最好
- iptables 层能明确看见 `xray分流模式` 的独立链，便于调试
- 允许访问控制里混用传统模式和 `xray分流模式`
- 前端语义更直接，用户只需要维护“分类 -> 出站节点”和“兜底节点”

---

## 4. 规则模型

当前版本支持两类规则：

- `builtin`：内置预设分类
- `custom`：用户自定义域名列表

每条规则包含：

- `id`
- `enabled`
- `source`
- `preset`
- `custom_b64`
- `target_node_id`
- `remark`

另有一条固定兜底规则：

- 始终显示在规则列表最下方
- 当动态分流规则数 `>= 1` 时，兜底出站允许选择 `DIRECT`
- 当动态分流规则数为 `0` 时，兜底出站必须是一个可用节点

当前规则仍存 DBus：

- `ss_basic_shunt_rules`
- `ss_basic_shunt_ingress_mode`

同时会镜像一份到文件，便于排障：

- `/koolshare/configs/fancyss/node_shunt_rules.json`

运行时会展开到：

- `/tmp/fancyss_shunt/active_rules.tsv`
- `/tmp/fancyss_shunt/target_nodes.txt`
- `/tmp/fancyss_shunt/rules/*.domains`
- `/tmp/ss_shunt_proxy.txt`

当前限制：

- 最多 `16` 条规则
- 最多 `8` 个启用中的目标节点

---

## 5. 内置分类

当前版本采用轻量的 TXT 规则集，而不是运行时加载 `.dat`：

- `rules_ng2/shunt/*.txt`（仓库源目录）
- `fancyss/ss/rules_ng2/shunt/*.txt`（打包后的运行时目录）
- `fancyss/res/shunt_manifest.json.js`
- `fancyss/scripts/ss_build_shunt_rules_ng2.sh`

已内置分类：

- `ai`
- `media`
- `youtube`
- `netflix`
- `disney`
- `max`
- `primevideo`
- `appletv`
- `spotify`
- `tiktok`
- `bilibili`
- `games`
- `networktest`
- `gfw`

这些规则只用于节点分流 MVP。

当前 `rules_ng2` 的生成方式：

- `ai/media/youtube/...` 等分类来自 `DustinWin/domain-list-custom`
- `gfw` 分类来自 fancyss 自己的 `rules_ng/gfwlist.gz`
- 构建脚本会将源规则转换成 Xray 可直接使用的 token：
  - `DOMAIN` -> `full:`
  - `DOMAIN-SUFFIX` -> `domain:`
  - `DOMAIN-KEYWORD` -> `keyword:`

当前目录职责：

- `rules_ng2/` 是规则源资产目录，和 `rules_ng/` 平行
- `build.sh` 会把 `rules_ng2/` 同步进插件包
- `ss_build_shunt_rules_ng2.sh` 会同步更新源目录、运行时目录和前端 manifest

因此首版虽然仍是轻量 TXT 资产，但已经保留了 Xray routing 的匹配语义，而不是简单扁平化成纯域名后缀。

当前不做：

- geosite 浏览器
- 第三方 geosite 包导入
- geosite/geoip 与 DNS 侧的完整统一编译链

这是后续演进方向，不是首版上线条件。

---

## 6. 支持的节点类型

当前版本仅允许以下节点参与 `mode=7`：

- `SS`（无 obfs）
- `VMess`
- `VLESS`
- `Trojan`
- `Hysteria2`

当前不允许作为兜底节点或目标节点：

- `SSR`
- `Naive`
- `TUIC`
- `SS + obfs`

后端会做两层校验：

1. 前端编辑/保存时限制
2. 后端生成分流配置时再次限制

当前主节点即使不支持，只要用户为“所有剩余流量”选择了一个受支持的兜底节点，`mode=7` 仍然可以正常启动。

---

## 7. DNS 侧实现

当前版本没有新增独立的 `shunt_direct.txt / shunt_proxy.txt` 完整体系，而是先走一个兼容实现：

- 节点服务器域名仍然走 `node_direct`
- 节点分流命中的业务域名，会按可下发到 DNS 的子集追加到 `/tmp/black_list.txt`

这意味着：

- `node_direct` 继续负责所有节点服务器域名的直连解析
- 命中节点分流规则的业务域名，会被视为“需要走代理解析路径”的域名
- smartdns / chinadns-ng 不需要另开一套大改造，就能先稳定支持首版功能

注意：

- `full:` / `domain:` 规则会同步提取纯域名写入 `/tmp/black_list.txt`
- `keyword:` 规则只在 Xray routing 中生效，不会反向展开到 DNS 黑名单
- 这是一版资源优先的折中，后续如有需要再考虑更完整的 DNS 侧分类资产

当前依赖链路：

1. 节点服务器域名 -> `node_direct`
2. 分流业务域名 -> `/tmp/black_list.txt`
3. DNS 解析结果进入现有 fancyss 分流链路
4. 最终代理流量进入 `mode=7` 的 Xray dispatcher

---

## 8. Xray 侧实现

当前版本由一个统一的 `xray dispatcher` 承担分流：

- `23456`：本地 socks5，仅走当前兜底节点
- `3333`：透明代理入口，走完整 routing

当前 routing 结构：

1. `inboundTag = socks-in` -> 当前运行节点
2. 节点分流规则域名 -> 对应 `proxy<node_id>`
3. fallback -> 兜底节点或 `DIRECT`

注意：

- `23456` 被刻意固定到当前运行节点，保持与现有插件状态检测/故障转移/脚本调用兼容
- 节点分流实际生效入口是透明代理 `3333`
- 当兜底规则选择 `DIRECT` 时，Xray 会额外生成一个 `freedom` 出站，最终剩余流量直接放行

当前前端规则编辑方式：

- 动态规则的“类别”和“出站节点”都可直接在列表里改成 `select`
- 切到“自定义域名集合”时，会弹出编辑层填写集合名称和域名合集
- 兜底规则始终固定在表格底部
- 分流页顶部会显示当前运行节点、入口策略、规则数量和兜底节点

当前 ACL 兼容行为：

- `get_action_chain(7)` / `get_action_chain6(7)` 会指向独立的 `SHADOWSOCKS_SHU / SHADOWSOCKS6_SHU`
- 访问控制里可以把单个主机切到 `xray分流模式`
- 因此在主模式为 `mode=7` 时，可以出现：
  - 某台主机继续走传统 `gfw黑名单模式`
  - 另一台主机走 `xray分流模式`

当前版本启用 sniffing：

- `http`
- `tls`

不额外做 QUIC sniffing。

---

## 9. 与 webtest 缓存的关系

当前版本不另造一套 outbound 缓存。

节点分流直接复用 `webtest` 已有的每节点 outbound cache：

- `/koolshare/configs/fancyss/webtest_cache/nodes/*_outbounds.json`

但首版实现里，不能直接调用 `warm_cache`，原因是：

- `warm_cache` 会面向所有 Xray-like 节点做全量缓存预热
- 在节点分流场景下，启动只需要“当前节点 + 被引用目标节点”这几个缓存
- 如果每次 `mode=7` 启动都全量预热，会造成明显启动卡顿

因此当前版本新增了一条轻量路径：

- `ss_webtest.sh ensure_cache_ids_file <ids_file>`

这条路径只会确保指定节点的 outbound cache 可用，不会对所有节点做全量重建。

首版实测收益很明显：

- 旧实现：创建分流配置前约 `16~17s`
- 新实现：创建分流配置前约 `1~2s`

这个优化是 `mode=7` 首版可用性的关键。

---

## 10. 当前实现与 webtest 的边界

虽然节点分流复用了 webtest cache，但两者职责不同：

- `webtest`
  - 目标是测速
  - 需要 group 批量配置、端口分配、状态流输出

- `mode=7`
  - 目标是运行时分流
  - 只需要稳定拿到少量已缓存的 outbound 对象

因此当前实现只复用：

- 每节点 outbound cache
- 节点 JSON / ENV cache
- `node_direct` 运行时准备逻辑

不复用：

- webtest 的批量执行器
- webtest 的 group 启动逻辑
- webtest 的所有全局聚合缓存

---

## 11. 前端行为

当前前端新增：

- 模式下拉中的 `xray分流模式`
- 紧跟在“节点管理”后的 `节点分流` 标签页
- 顶部 ACL 风格的“类别 / 出站节点 / 操作”添加行
- 动态规则表格
- 一条固定的“所有剩余流量”兜底规则

当前前端行为：

- 只有进入 `mode=7` 才显示“节点分流”页签
- 模式切到 `mode=7` 后会自动切到“节点分流”页签
- 内置类别在顶部直接添加，不再弹基础模板或类别定义窗口
- 只有选择“自定义域名集合”时，才弹出“集合名称 + 域名合集”编辑窗口
- 目标节点列表只展示当前支持参与分流的节点类型

前端同时处理了两个容易出错的点：

- 当用户在 `mode=7` 下切换当前节点时，页面模式不会被该节点原有 `mode` 字段带偏
- 当前主节点不支持时，会自动改用兜底规则中选定的受支持节点作为运行节点

---

## 12. GS7 实测记录

本次在 GS7 上做了实际联调，覆盖了以下关键点：

### 12.1 后端生成

验证通过：

- `mode=7` 会进入 `creat_shunt_json`
- 不再落回普通 `creat_vless_json`
- 运行时会生成：
  - 当前兜底节点 outbound
  - 目标节点 outbound
  - 节点分流 routing 规则

### 12.2 节点切换不丢模式

验证通过：

- 全局 `mode=7` 时切换 `fss_node_current`
- 重启后仍生成 `xray分流配置文件`
- 不会因为目标节点自身保存的是旧模式而退回 `mode=1/2/5`

### 12.3 不支持主节点时的兜底接管

验证通过：

- 把当前主节点切到 `TUIC`
- 显式把兜底节点设为一个受支持的 `VLESS`
- 后端会直接使用兜底节点生成并启动 `mode=7`
- 不再因为当前主节点不支持而直接拒绝启动

### 12.4 实际分流命中

通过一个额外测试 socks inbound 做验证：

- 当前兜底节点：`15`
- 目标节点：`2`
- 规则：`api.ip.sb -> 2`

实测结果：

- `api.ip.sb` -> 命中目标节点 `2`
- `ip-api.com` -> 继续走当前兜底节点 `15`

说明 routing 已按规则正常分流。

### 12.5 启动耗时

优化前：

- 分流配置准备阶段约 `16~17s`

优化后：

- 分流配置准备阶段约 `1~2s`

主要改动：

- 不再调用全量 `warm_cache`
- 改为只确保“当前节点 + 被引用目标节点”的 webtest cache

### 12.6 前端浏览器联调

在 GS7 后台页面做了实机浏览器联调，确认以下行为：

- `xray分流模式` 出现在模式下拉中
- 进入 `mode=7` 后，会自动切到 `节点分流` 标签页
- `节点分流` 标签位于 `节点管理` 后方
- 页面不再提供“开关”和“基础模板”
- 顶部新增行采用 `类别 / 出站节点 / 操作` 三列表结构
- 内置类别直接添加，不弹窗
- 选择“自定义域名集合”时，弹出“集合名称 + 域名合集 + 出站节点”窗口
- 固定兜底规则 `所有剩余流量` 可单独选择兜底节点
- 规则支持编辑、删除、上移、下移
- 保存后刷新页面，规则顺序、兜底节点、`mode=7` 状态都能正确回显

### 12.7 浏览器联调发现并修复的问题

浏览器联调时发现一个真实问题：

- 前端 `save()` 提交参数里漏了 `ss_basic_mode`

表现为：

- 页面 loading 会显示 `xray分流模式启用中 ...`
- 但后端实际仍按普通单节点模式生成配置

已在 `fancyss/webs/Module_shadowsocks.asp` 修复：

- 将 `ss_basic_mode` 加回保存参数列表

修复后，GS7 实测日志已正确进入：

- `创建xray分流配置文件到 /koolshare/ss/xray.json`

---

## 13. 已知限制

当前版本明确存在以下限制：

1. 规则集仍是 TXT 预设，不是正式 geosite/geoip 资产体系
2. DNS 侧当前先复用 `/tmp/black_list.txt`，不是最终态
3. 只支持域名规则，不支持更复杂的匹配语法
4. 只支持 Xray 原生可承载节点
5. `23456` 入口固定走当前兜底节点，不参与节点分流
6. 路由器自身流量是否进入透明代理链，不作为节点分流有效性的判断依据

最后一点很关键：

- 节点分流真实生效点是透明代理入口 `3333`
- 路由器自己执行 `curl` 是否走透明代理，和 LAN 设备经过透明代理时的行为不是一回事

因此实测分流时，不能只看“路由器本机普通 curl”的出口结果。

---

## 14. 后续演进建议

后续版本建议按以下方向推进：

1. 建立正式的 `geosite-fancyss / geoip-fancyss` 构建链
2. 为 DNS 侧补齐 `shunt_direct / shunt_proxy` 独立运行时文件
3. 把节点分流规则从 DBus 迁移为文件存储
4. 为失效目标节点、已删除节点、规则不可用状态补更明确的 UI 状态
5. 评估 `TUIC / Naive / SSR / SS+obfs bridge` 的后续接入模型
6. 视资源成本决定是否引入 Xray observatory / 更高级别的健康检查

---

## 15. 维护入口

当前与节点分流直接相关的主要文件：

- `fancyss/scripts/ss_node_shunt.sh`
- `fancyss/ss/ssconfig.sh`
- `fancyss/scripts/ss_base.sh`
- `fancyss/webs/Module_shadowsocks.asp`
- `fancyss/scripts/ss_webtest.sh`
- `fancyss/scripts/ss_webtest_gen.sh`
- `fancyss/res/shunt_manifest.json.js`
- `fancyss/ss/rules_ng2/shunt/*.txt`
- `fancyss/scripts/ss_shunt_stats.sh`
- `fancyss/scripts/ss_build_shunt_rules_ng2.sh`
- `fancyss/configs/fancyss/node_shunt_rules.json`

如果后续要继续维护 `mode=7`，优先从这几处入手。

---

## 16. 与设计文档的差异追踪

以下是 MVP 实际实现与 `doc/design/node-shunt-design.md` 设计文档之间的关键差异：

| 设计文档章节 | 设计目标 | MVP 实际 | 备注 |
|---|---|---|---|
| §2.7 geosite-fancyss.dat | 自建 geosite 资产 | TXT 内联到 xray routing domain 数组 | xray.json 体积偏大但功能正常 |
| §2.7 geoip-fancyss.dat | 自建 geoip 资产 | 未实现，依赖 iptables chnroute | ingress_mode=2 时无影响 |
| §12.2 shunt_direct / shunt_proxy | 独立 DNS 运行时域名文件 | 复用 `/tmp/black_list.txt` 追加 | keyword 规则不同步到 DNS 侧 |
| §15 routing 优先级 | 10 级 xray routing 优先级 | 仅覆盖 1、8、10 项 | 其余由 iptables 层承担 |
| §16 基础模板 | 三个模板（按需/代理优先/全局） | 简化为 ingress_mode 2/5 | GFW 兼容引流暂缺 |
| §19 规则存储 | TSV 文件 | dbus base64(json) + 文件镜像 | 规则量小时可用 |
| §25 实施顺序 | 先构建资产 → runtime → UI | 先 runtime + UI，资产用 TXT 过渡 | 更务实的落地路径 |

完整分析和后续演进建议见 `doc/analysis/node-shunt-supplement.md`。
