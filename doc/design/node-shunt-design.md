# fancyss 节点分流设计文档（一期正式方案）

> 说明：`3.5.10` 首个可用版的实际落地与优化细节，见 `doc/implementation/node-shunt-mvp.md`。当前已落地版本前端不再提供“节点分流开关”和“基础模板”选择，而是固定启用 `mode=7` 并维护“兜底节点 + 分类规则”。

## 1. 文档目的

本文用于定义 fancyss `3.5.10` 版本的“节点分流”功能一期正式实施方案。

本文重点覆盖：

- 节点分流的运行模式设计
- 规则资产（`geosite/geoip/txt`）设计
- 与现有 DNS / iptables / xray / 节点缓存 / webtest / 订阅 / 故障转移 / 备份恢复的耦合关系
- IPv4 / IPv6 双栈下的行为边界
- 路由器资源受限场景下的上线约束

本文为正式设计文档，不直接包含代码实现。

---

## 2. 设计结论

一期方案的核心结论如下：

1. 新增独立运行模式：`ss_basic_mode=7`，名称为：`xray分流模式`
2. `mode=7` 额外引入 `ss_basic_shunt_ingress_mode`，一期支持：
   - `2`：大陆白名单引流
   - `5`：全量引流
3. `mode=7` 使用独立 iptables 链：
   - `SHADOWSOCKS_SHU`
   - `SHADOWSOCKS6_SHU`
4. 不复用当前 `gfw黑名单模式 / 大陆白名单模式 / 游戏模式 / 全局代理模式`
5. 不占用当前仍有历史逻辑残留的 `mode=6`
6. 不直接使用第三方现成 `geosite.dat / geoip.dat` 作为运行时最终资产
7. 采用 fancyss 自建规则资产：
   - `geosite-fancyss.dat`
   - `geoip-fancyss.dat`
   - `shunt_manifest.json`
   - `shunt_tags/*.txt(.gz)`
8. 一期仅支持 `xray` 原生可承载协议参与节点分流运行
9. 继续复用当前 fancyss 的 DNS 分流体系（`chinadns-ng / smartdns`），不在一期引入“Xray DNS 全接管”
10. 规则引用节点必须使用 schema 2 的稳定节点 ID，不能使用表格顺序号
11. 与 `node_direct` 域名缓存、`webtest` 的 outbound cache 体系统一设计，避免重复生成配置

> **MVP 过渡说明**：`3.5.10` 首个可用版的实际落地采用了务实的过渡策略——先跳过 geosite/geoip 资产构建，用 `rules_ng2/shunt/*.txt` 的 TXT 规则内联到 xray routing domain 数组中；基础模板简化为 `ingress_mode`（2=大陆白名单引流，5=全量引流）；规则存储暂用 dbus base64(json) + 文件镜像。实际落地细节见 `doc/implementation/node-shunt-mvp.md`，后续优化方向见 `doc/analysis/node-shunt-supplement.md`。

---

## 3. 背景与问题定义

fancyss 当前的流量处理逻辑以 iptables / ipset / DNS 分流为核心，主要提供：

- `gfw黑名单模式`
- `大陆白名单模式`
- `游戏模式`
- `全局代理模式`

这些模式擅长解决“流量是否走代理”的问题，但不适合解决“代理流量该走哪个节点”的问题。

节点分流的目标不是重新定义“是否代理”，而是进一步定义：

- AI 域名走美国节点
- 媒体域名走新加坡节点
- 其它代理流量走香港节点

该能力需要：

1. 对代理流量做更细粒度域名分类
2. 为一个 xray 运行实例生成多个出站代理（outbounds）
3. 通过 xray routing 在多个节点之间做二次分流

问题在于，fancyss 当前体系存在以下天然约束：

- 现有黑白名单模式的入口语义已经固定
- DNS 分流与 iptables 分流均依赖当前 `chnlist / gfwlist / chnroute`
- 第三方 `geosite/geoip` 与 fancyss 自己的规则存在不一致风险
- 路由器 CPU / RAM / Flash 资源有限
- 部分节点协议需要外挂 sidecar，不适合一期直接纳入

因此一期不能简单“给 xray 配个 routing 就结束”，而必须从模式、规则资产、一致性和资源消耗四个层面整体重构。

---

## 4. 一期目标与非目标

## 4.1 一期目标

- 新增独立的 `xray分流模式`
- 在该模式下允许用户为“域名分类”指定不同代理节点
- 保留一个“默认兜底节点”
- 保持 fancyss 现有 DNS / 节点域名动态解析机制可继续工作
- 保持与当前 `node_direct` 缓存体系兼容
- 保持与当前 `webtest` 配置缓存体系可复用
- 在 IPv4 / IPv6 双栈下行为明确、可预期

## 4.2 一期非目标

- 不实现 `tuic / naive / ssr / ss+obfs` 作为节点分流运行时目标节点
- 不实现节点分流目标节点自动健康检查 / 自动切换
- 不实现负载均衡 / 自动优选节点
- 不实现“导入任意第三方 geosite.dat 后动态生成 UI 选项”
- 不实现 Xray DNS 全接管
- 不实现进程级 / ASN / 端口级高级匹配

---

## 5. 设计原则

1. **模式独立**
   - 节点分流必须是独立运行模式，不能嵌套到现有黑白名单模式中。

2. **规则一致性优先**
   - DNS、iptables、xray routing 所使用的核心直连/代理规则必须同源。

3. **路由器资源优先**
   - 少进程、少常驻、少重复编译、少热路径 `jq` 调用。

4. **节点配置复用**
   - 复用 `webtest` 已经验证过的节点 outbound cache，不重复设计第二套配置缓存。

5. **双栈行为明确**
   - IPv4 / IPv6 在 DNS、透明代理、路由规则、节点服务器解析上的行为必须可解释。

6. **扩展路径保留**
   - 一期虽不支持 `tuic / naive / ssr / ss+obfs bridge`，但数据模型和编译器接口必须预留。

---

## 6. 运行模式设计

## 6.1 新增模式

新增：

- `ss_basic_mode=7`
- 前端显示：`xray分流模式`

该模式是一个独立于当前四种主要模式的新模式。

## 6.2 为什么必须独立

如果将节点分流直接附着在当前 `gfw黑名单模式` 或 `大陆白名单模式` 上，会带来以下问题：

- 入口流量在 iptables 层就已经被当前模式大量裁剪
- 很多未收录于 `gfwlist` 的海外域名无法进入 xray routing
- “按需代理”和“多节点细分代理”会互相扭曲
- UI 与后端语义均会变得难以解释

因此一期的正确做法是：

- `xray分流模式` 自己定义基础模板
- 与现有黑白名单模式逻辑解耦
- 但继续复用现有的部分底层能力，如：
  - `绕过大陆IP`
  - `UDP 是否代理`
  - `屏蔽 QUIC`
  - `IPv6 代理开关`

---

## 7. 规则资产设计

## 7.1 总体结论

一期不直接使用：

- `Loyalsoldier/v2ray-rules-dat` 的完整 `geosite.dat`
- `DustinWin/ruleset_geodata` 的完整 `geosite-all-lite.dat`

而是自建：

- `geosite-fancyss.dat`
- `geoip-fancyss.dat`
- `shunt_manifest.json`
- `shunt_tags/*.txt(.gz)`

补充说明：

- 以上是长期正式资产方向
- `3.5.10` 首个可用版实际先落地为 `rules_ng2/shunt/*.txt`
- `rules_ng2` 中的每一行都已经是 Xray 可直接使用的 `full:/domain:/keyword:` token
- 这样可以先把分类语义和前后端联调跑通，再决定后续是否收敛成 `.dat` 资产
- `rules_ng2/` 为仓库源目录，和 `rules_ng/` 平行；构建时同步到 `fancyss/ss/rules_ng2/`

## 7.2 为什么不直接使用第三方成品 geosite

### 7.2.1 `geosite-xray.dat` 的问题

- 分类过多，远超路由器场景实际需要
- 文件大，加载开销高
- 与 fancyss 当前 `chnlist / gfwlist / apple_china / google_china` 不一致

### 7.2.2 `geosite-all-lite.dat` 的问题

- 体积明显更合适
- 但分类仍不足以完整支撑 fancyss 的精细节点分流需求
- 且其 `cn / gfw / proxy` 仍然不是 fancyss 当前规则源的直接镜像

### 7.2.3 根本问题

节点分流要的不只是 xray 能吃的 `.dat`，还需要：

- DNS 可用的纯文本分类名单
- 前端可展示的分类 manifest
- 与当前规则体系一致的核心标签

仅引入一个第三方 `.dat` 无法解决这三个问题。

## 7.3 一期规则资产形态

### 7.3.1 `geosite-fancyss.dat`

用途：

- 仅供 xray routing 使用

### 7.3.2 `geoip-fancyss.dat`

用途：

- 仅供 xray routing 使用

### 7.3.3 `shunt_manifest.json`

用途：

- 前端分类展示
- 后端 tag -> txt/dat 资产映射
- 更新日志与规则版本展示

### 7.3.4 `shunt_tags/*.txt(.gz)`

用途：

- 供 smartdns / chinadns-ng 生成运行时域名名单
- 供规则一致性检查和调试

### 7.3.5 `rules_ng2/shunt/*.txt`

用途：

- `3.5.10` 首版节点分流的实际运行时规则源
- 由 `fancyss/scripts/ss_build_shunt_rules_ng2.sh` 生成
- 构建时保留 Xray routing 所需的匹配语义

当前转换规则：

- `DOMAIN` -> `full:`
- `DOMAIN-SUFFIX` -> `domain:`
- `DOMAIN-KEYWORD` -> `keyword:`
- fancyss 自带 `gfwlist.gz` -> `domain:`

## 7.4 一期建议内置 tag

### 7.4.1 一致性核心 tag

- `cn`
- `gfw`
- `apple-cn`
- `google-cn`
- `private`

### 7.4.2 节点分流常用 tag

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
- `games-cn`
- `networktest`
- `proxy`

### 7.4.3 二期或更后续再考虑的 tag

- `telegram`
- `github`
- `google`
- `applications`
- `trackerslist`

> 注：这些 tag 可在一期 manifest 中预留，但不一定在第一轮 UI 默认展示。

## 7.5 一期规则源建议

### 7.5.1 由 fancyss 自己维护的核心一致性源

- `cn`：由当前 `chnlist.gz` 编译生成
- `gfw`：由当前 `gfwlist.gz` 编译生成
- `apple-cn`：由当前 `apple_china.txt` 编译生成
- `google-cn`：由当前 `google_china.txt` 编译生成
- `private`：由固定私有域名集合维护

### 7.5.2 由外部项目提供扩展分类源

建议主要参考：

- `DustinWin/domain-list-custom`
- `v2fly/domain-list-community`
- 必要时辅以 `blackmatrix7/ios_rule_script`

不建议在运行时直接依赖这些项目；应当在 fancyss 规则构建阶段离线编译后再下发到路由器。

---

## 8. `geoip-fancyss.dat` 的一致性策略

## 8.1 核心要求

`geoip-fancyss.dat` 不能直接沿用第三方 `geoip.dat` 的 `cn`，必须与当前 fancyss 的：

- `chnroute.txt`
- `chnroute6.txt`

保持一致。

## 8.2 一期最小集合

一期只生成：

- `cn`
- `private`

即可满足节点分流所需的基础能力。

## 8.3 IPv6 约束

若 `mode=7` 允许关闭“绕过大陆IP”，则 `geoip-fancyss.dat:cn` 必须同时覆盖：

- IPv4 大陆网段
- IPv6 大陆网段

否则会出现：

- IPv4 大陆地址被 xray 判直连
- IPv6 大陆地址却被兜底送往代理

这会导致双栈下严重不一致。

因此一期规定：

- `geoip-fancyss.dat:cn` 由 `chnroute.txt + chnroute6.txt` 同步生成
- 不允许只做 IPv4 版 `cn`

---

## 9. 第三方 geosite 支持策略

## 9.1 一期不支持“裸 geosite.dat 导入”

原因：

1. xray 能用 `.dat`，DNS 不能直接用 `.dat`
2. 路由器上运行时解析 `.dat` 生成 UI 选项成本高
3. 无法保证 DNS / xray routing / UI 三者一致

## 9.2 后续若支持第三方规则包

必须支持的是“规则包”，而不是单文件。

规则包最小形态应包含：

- `geosite-xxx.dat`
- `geoip-xxx.dat`（可选）
- `manifest.json`
- `tags/*.txt.gz`

其中：

- xray 用 `.dat`
- DNS 用 `txt`
- 前端用 `manifest`

---

## 10. 基础运行架构

`xray分流模式` 的运行架构分三层：

1. **iptables / ip6tables 层**
   - 做最轻量、最确定的拦截与放行

2. **DNS 层**
   - 使用 fancyss 当前 `chinadns-ng / smartdns`
   - 根据新的直连/代理运行时域名列表决定解析路径

3. **xray 层**
   - 作为统一的透明代理分流器
   - 负责多 outbounds 与 routing

---

## 11. iptables / ip6tables 设计

## 11.1 mode=7 下 iptables 的职责

iptables 不再承担最终的“是否代理”全部逻辑，而是只做：

- `ignlist / LAN / router / 本地保留地址` 放行
- ACL 的“不代理”设备放行
- 用户 `white_list` 中的 IP/CIDR 放行
- 用户 `black_list` 中的 IP/CIDR 强制送入代理
- 可选的 `绕过大陆IP`
- `UDP 是否代理`
- `屏蔽 QUIC`
- IPv6 透明代理入口控制

## 11.2 绕过大陆 IP

建议在 `mode=7` 默认开启。

开启时：

- IPv4：`chnroute` 命中流量在 iptables 层直接放行
- IPv6：`chnroute6` 命中流量在 ip6tables 层直接放行
- xray 无需再对 `geoip:cn` 做直连匹配

关闭时：

- IPv4 / IPv6 均进入 xray
- 由 `geoip-fancyss.dat:cn` 在 routing 中判定直连

## 11.3 为什么默认建议开启

- 大量大陆直连流量无需进入 xray
- 显著降低透明代理入口负载
- 减少 sniffing 和 routing 命中压力
- 对路由器设备更友好

---

## 12. DNS 设计

## 12.1 一期不采用 Xray DNS 全接管

一期仍继续使用：

- `chinadns-ng`
- `smartdns`

理由：

- fancyss 已有成熟 DNS 分流链路
- 已有 `node_direct` 动态解析体系
- 一期继续沿用可以显著降低改造面和联调风险

## 12.2 mode=7 下新增运行时名单

新增运行时文件：

- `/tmp/ss_shunt_direct.txt`
- `/tmp/ss_shunt_proxy.txt`

继续保留：

- `/tmp/ss_node_domains.txt`

三者语义：

- `node_direct`
  - 所有节点服务器域名
  - 永远走直连 DNS upstream
- `shunt_direct`
  - 当前模式下必须走直连解析的业务域名
- `shunt_proxy`
  - 当前模式下必须走代理/可信上游解析的业务域名

## 12.3 DNS 与 xray routing 的一致性要求

以下标签必须做到 DNS 与 xray 使用同源数据：

- `cn`
- `gfw`
- `apple-cn`
- `google-cn`
- 用户自定义 `white_list` 域名
- 用户自定义 `black_list` 域名
- 用户自定义节点分流域名

## 12.4 `node_direct` 的地位

`node_direct` 继续作为所有节点服务器域名的全集缓存存在。

这是节点分流模式的一项硬依赖：

- 只要 `node_direct` 准确
- 节点 outbound 中就可以保留原始域名
- 后续无需再为了 runtime 改写节点 server 为 IP

## 12.5 DNS 运行时更新要求

当以下任一事件发生时，必须重新评估 `node_direct` / `shunt_direct` / `shunt_proxy`：

- 新增节点
- 编辑节点
- 删除节点
- URI 导入节点
- 订阅更新节点
- 恢复配置
- 节点分流规则变更
- 切换 `mode=7` 的基础模板

若运行时域名集发生变化，则：

1. 先刷新 cache
2. 再同步运行时文件
3. 如有必要，重启 DNS 分流核心
4. 最后才启动或重启 `mode=7` 的 xray dispatcher

---

## 13. IPv6 设计与约束

IPv6 是节点分流设计中的重点，不可作为附属功能对待。

## 13.1 设计原则

1. IPv4 / IPv6 直连与代理语义必须一致
2. AAAA 过滤策略必须可解释
3. 不能让业务域名和节点服务器域名互相误伤
4. 关闭 IPv6 代理时，必须防止“域名被解析出 AAAA 后直接漏连”

## 13.2 现有基础

当前 fancyss 已经具备：

- IPv6 透明代理入口
- `chnroute6`
- smartdns 下对 AAAA 的运行时抑制策略
- `node_direct` 场景下的 `address /domain-set:node_direct/-6`

这些逻辑在 `mode=7` 下应继续复用，而不是重新发明一套。

## 13.3 节点服务器域名的 IPv6 处理

### 13.3.1 动态解析模式

当节点服务器地址是域名，且启用动态解析：

- 节点 outbound 中保留域名
- 该域名必须进入 `node_direct`
- DNS 必须允许 `node_direct` 按当前直连 DNS 组解析

若全局关闭 IPv6 代理：

- 不能简单粗暴地把 `node_direct` 的 AAAA 一并屏蔽
- 否则纯 IPv6 可用的节点服务器可能无法连接

因此一期建议：

- `node_direct` 默认允许 AAAA 解析
- 仅在明确检测到当前 DNS 策略会让该 AAAA 结果绕过代理且造成误路由时，再做精细抑制
- smartdns 保持现有 `address /domain-set:node_direct/-6` 兼容逻辑，但在 `mode=7` 下需要按实际模板重审其默认启用条件

### 13.3.2 预解析模式

若用户选择预解析：

- 节点 outbound 中直接写入解析所得 IP
- 若解析结果为 IPv6，则必须确认当前对应协议和透明代理链路可正常使用 IPv6 server literal

一期要求：

- 预解析模式允许得到 IPv4 或 IPv6
- 但配置生成器必须确保：
  - IPv6 literal 地址格式正确
  - `[]` 包装与端口拼接逻辑正确

## 13.4 业务域名的 AAAA 策略

### 13.4.1 当 `ss_basic_proxy_ipv6=1`

表示代理链路允许 IPv6 代理。

此时：

- `shunt_direct` 允许返回 AAAA
- `shunt_proxy` 允许返回 AAAA
- xray routing 中必须对 IPv6 目的地址具备明确处理能力

### 13.4.2 当 `ss_basic_proxy_ipv6=0`

表示代理链路不代理 IPv6。

此时：

- `shunt_proxy` 不应保留 AAAA 结果
- 否则客户端很可能直连 IPv6 出口，绕过代理
- `shunt_direct` 则应根据基础模板允许或保留 AAAA

建议：

- `mode=7` 下继续沿用当前 smartdns/chinadns-ng 的“代理域名抑制 AAAA、直连域名保留 AAAA”的大方向
- 只是把 `gfwlist/chnlist` 语义替换为 `shunt_proxy/shunt_direct`

## 13.5 `geoip-fancyss.dat:cn` 的 IPv6 要求

若关闭“绕过大陆IP”，则 `geoip-fancyss.dat:cn` 必须完整覆盖：

- 大陆 IPv4
- 大陆 IPv6

否则双栈行为会分裂。

## 13.6 IPv6 透明代理入口

`mode=7` 必须保证：

- 若启用 IPv6 代理，xray dispatcher 具备 IPv6 透明代理 inbound
- 若关闭 IPv6 代理，ip6tables 不应再把普通 IPv6 流量导入代理入口

这意味着 `mode=7` 的 IPv6 行为不是单纯复制现有模式，而是要按以下两类分别处理：

1. **IPv6 代理开启**
   - ip6tables 接管目标流量
   - xray routing 对 IPv6 IP 和基于 sniffing 得到的域名统一处理

2. **IPv6 代理关闭**
   - `shunt_proxy` 域名的 AAAA 必须在 DNS 层抑制
   - ip6tables 不应导入普通 IPv6 业务流量

## 13.7 IPv6-only 目的站点

若某业务域名仅提供 AAAA，无 A 记录：

- 当 `ss_basic_proxy_ipv6=0`：
  - 该站点在代理路径上不可达是预期行为
  - 前端和文档需明确这一点

- 当 `ss_basic_proxy_ipv6=1`：
  - 必须允许其通过 AAAA 命中 `shunt_proxy`
  - 进入 xray routing 后正常转发

## 13.8 IPv6-only 节点服务器

若节点服务器本身仅有 IPv6：

- 动态解析模式下，`node_direct` 不能无条件抑制 AAAA
- 预解析模式下，解析器必须允许得到 IPv6 地址
- outbound 生成器必须支持 IPv6 literal server

这类节点在一期必须明确“支持”，否则 `mode=7` 将天然排斥一部分真实可用节点。

---

## 14. xray 架构设计

## 14.1 总体结构

`mode=7` 下只启动一个统一的 `xray dispatcher` 主进程。

该进程承担：

- 透明代理入口（LAN 业务流量）
- 本地 socks5 入口（插件内部自用）
- 多个代理出站（多个节点）
- 一个直连出站

## 14.2 `23456` 的语义

保留 `23456` 作为本地 socks5 入口，但其语义固定为：

- 只走当前默认兜底节点

这样可以保证以下功能尽量继续沿用：

- 插件运行状态测试
- 国外状态检测
- 故障转移检测
- 若干依赖本地 `23456` 的脚本逻辑

## 14.3 `3333` 的语义

透明代理入口 `3333` 才是完整的节点分流入口。

即：

- LAN 设备流量进入 `3333`
- 由 xray routing 决定：
  - `direct`
  - `default_proxy`
  - `proxy_<node_id>`

## 14.4 sniffing 策略

一期建议：

- 开启 sniffing
- `destOverride = ["http", "tls"]`
- `routeOnly = true`

不建议一期默认启用：

- `quic` sniffing

原因：

- CPU 成本更高
- 与当前“屏蔽 QUIC”策略容易产生额外耦合

---

## 15. routing 优先级设计

一期建议固定以下优先级：

1. 本地 `23456` 入站 -> `default_proxy`
2. 私有地址 / 保留地址 / 用户直连 IP/CIDR -> `direct`
3. 若关闭“绕过大陆IP”，`geoip-fancyss:cn` -> `direct`
4. 用户 `white_list` 域名 -> `direct`
5. 系统直连 tag（如 `cn / apple-cn / google-cn / private`）-> `direct`
6. 用户 `black_list` IP/CIDR -> `default_proxy`
7. 用户 `black_list` 域名 -> `default_proxy`
8. 用户节点分流规则（按用户顺序）-> 对应 `proxy_<node_id>`
9. 系统代理 tag（如 `gfw`）-> `default_proxy`
10. fallback -> `direct` 或 `default_proxy`

其中第 10 项由基础模板决定。

> **MVP 实现说明**：`3.5.10` 首版实现仅覆盖了上述优先级的第 1 项（socks-in → 兜底节点）、第 8 项（用户节点分流域名规则 → 目标节点）和第 10 项（fallback）。第 2-7、9 项的直连/代理判断由 iptables 层的 `SHADOWSOCKS_SHU` 链承担（chnroute / white_list / black_list 等 ipset 匹配），功能等效但语义分布在两层。后续引入 geosite/geoip 资产后，可逐步将这些规则收拢到 xray routing 层。详见 `doc/analysis/node-shunt-supplement.md` §3。

---

## 16. 基础模板设计

一期提供三个基础模板：

## 16.1 按需代理（GFW兼容）

- 系统直连：`private / cn / apple-cn / google-cn / white_list`
- 系统代理：`gfw / black_list`
- 用户节点分流规则：插在系统直连之后、兜底之前
- fallback：`direct`

## 16.2 代理优先（白名单兼容）

- 系统直连：`private / cn / apple-cn / google-cn / white_list`
- 系统代理：`black_list`
- 用户节点分流规则：插在系统直连之后
- fallback：`default_proxy`

## 16.3 全局分流

- 系统直连：`private / white_list`
- 系统代理：`black_list`
- 用户节点分流规则：正常生效
- fallback：`default_proxy`

## 16.4 MVP 实际简化

`3.5.10` 首版移除了前端"基础模板"选择，改为 `入口策略`（`ss_basic_shunt_ingress_mode`）：

- `ingress_mode=2`：大陆白名单引流，对应 §16.2 的 iptables 行为
- `ingress_mode=5`：全量引流，对应 §16.3 的 iptables 行为
- §16.1 的"按需代理（GFW 兼容）"暂不提供（`mode=7` 的分流语义本身超越了 GFW 黑名单范畴）

"基础模板"概念不再作为前端选项暴露，但其语义通过 `ingress_mode` 继续保留。后续若需要 GFW 兼容引流，可引入 `ingress_mode=1`。

---

## 17. 节点支持范围

## 17.1 一期允许运行的节点类型

仅允许 `xray` 原生可承载节点作为：

- 默认兜底节点
- 节点分流目标节点

建议一期包含：

- `vmess`
- `vless`
- `trojan`
- `hy2`
- `ss`
- `ss2022`
- `xray/vmess json` 中可被 xray 原生承载的 outbound

## 17.2 一期不允许运行的节点类型

- `ssr`
- `naive`
- `tuic`
- `ss + obfs`

## 17.3 架构保留

虽然一期不允许运行上述协议，但缓存和编译器接口必须保留未来扩展能力：

- `native_xray`
- `bridge_socks`

后续若支持：

- `tuic / naive / ssr / ss+obfs`

则以 `bridge_socks` 类型接入，而不改变规则层与 UI 层数据模型。

---

## 18. 节点缓存体系复用

## 18.1 总体要求

节点分流不能重新发明第二套节点配置缓存。

应基于当前 `webtest` 已有成果，抽象为共享缓存：

- `node_outbound_cache`

## 18.2 缓存内容

每个节点缓存一份“单出站描述”：

- 节点 ID
- 节点修订号 `node_rev`
- 解析模式
- server 运行时地址
- provider 类型
- 构建时间

## 18.3 与 `webtest` 的关系

- `webtest` 使用该缓存进行测速配置拼装
- `mode=7` 使用同一缓存生成 runtime outbounds

这样可保证：

- 节点编辑后只失效一次
- 生成逻辑唯一
- 后续维护点唯一

---

## 19. 规则存储设计

## 19.1 为什么不把规则体存 dbus

原因：

- dbus 更适合存放小控制项
- 规则体可能包含较多自定义域名
- 文件格式更利于 shell 解析、备份恢复和调试

## 19.2 存储文件

建议：

- `/koolshare/configs/fancyss/node_shunt_rules.txt`
- `/koolshare/configs/fancyss/node_shunt_rules.meta`

## 19.3 一行一条规则

建议 TSV：

```text
rule_id<TAB>enabled<TAB>match_type<TAB>match_value<TAB>target_node_id<TAB>remark
```

其中：

- `match_type`
  - `builtin`
  - `custom`

- `match_value`
  - `builtin`：一个或多个内置 tag/preset
  - `custom`：base64 编码后的多行域名

- `target_node_id`
  - 必须是稳定节点 ID

## 19.4 dbus 中仅保留控制值

例如：

- `ss_basic_mode=7`
- `ss_basic_shunt_rules=<base64(json)>`
- `ss_basic_shunt_default_node=<node_id|DIRECT>`
- `ss_basic_shunt_rule_ts=<ts>`

## 19.5 MVP 过渡方案

`3.5.10` 首版未采用 §19.3 的 TSV 文件方案，而是直接将规则存入 dbus：

- `ss_basic_shunt_rules`：base64 编码的 JSON 数组
- 每条规则包含 `id / enabled / source / preset / custom_b64 / target_node_id / remark`
- 同时镜像一份到 `/koolshare/configs/fancyss/node_shunt_rules.json`，便于排障

这一方案的优势是与 fancyss 现有的前端 save/load 机制完全兼容（前端通过 dbus set/get 与后端交互），改造面最小。

后续迁移到文件存储的触发条件：

- 自定义域名规则增多导致 dbus 单 key 体积超限
- 规则导入导出功能要求独立文件格式
- 需要支持多规则集切换（如按场景切换不同规则配置）

---

## 20. 自定义域名规则边界

一期自定义域名当前支持：

- 后缀匹配：`example.com`
- Xray token：`domain:example.com`
- 全匹配：`full:api.example.com`
- 关键词匹配：`keyword:openai`
- Clash 风格：
  - `DOMAIN,api.example.com`
  - `DOMAIN-SUFFIX,example.com`
  - `DOMAIN-KEYWORD,openai`

一期仍不支持：

- `regexp`

原因：

- 需要保证 DNS 与 xray routing 行为一致
- 纯文本 DNS 规则无法优雅表达复杂正则/关键字匹配

---

## 21. ACL、故障转移、节点切换的耦合

## 21.1 ACL

`mode=7` 下，ACL 建议只允许：

- `跟随当前模式`
- `不通过代理`

不再允许对单设备选择旧模式。

## 21.2 故障转移

故障转移只影响：

- 当前默认兜底节点 `default_proxy`

不自动改写：

- 用户在节点分流规则中指定的目标节点

## 21.3 节点切换

当全局运行于 `mode=7` 时：

- 切换默认节点不得覆盖全局 `ss_basic_mode`
- 节点自身保存的旧 `mode` 字段不参与当前模式切换

否则会出现：

- 用户处于 `mode=7`
- 仅切换一个节点
- 全局被带回 `mode=1/2/5`

该行为必须明确禁止。

---

## 22. 订阅、编辑、删除、恢复的耦合

## 22.1 统一要求

节点增删改后，必须统一触发：

- `node_direct` cache 校验/更新
- `node_outbound_cache` 校验/失效/重建
- `mode=7` 运行时配置重编译（若当前正在使用）

## 22.2 删除被引用节点

若某规则引用的节点被删除：

- 不自动删除规则
- 将规则标记为 `invalid`
- 编译时跳过
- 前端提示该规则失效

## 22.3 编辑被引用节点

若编辑后该节点仍可生成 outbound：

- 规则继续有效

若编辑后该节点变成不支持类型：

- 该规则标记为 `invalid`

## 22.4 订阅更新

订阅更新后需要尽量保留稳定节点 ID，否则节点分流规则会大面积失效。

因此节点分流功能的前置条件之一是：

- 当前 schema 2 节点体系在订阅更新时必须尽可能保留稳定节点 ID

## 22.5 配置恢复

恢复配置时：

- 恢复节点分流规则文件
- 重新校验所有被引用节点
- 触发：
  - `node_direct` refresh
  - `node_outbound_cache` refresh
  - `mode=7` runtime rebuild

---

## 23. 前端设计

## 23.1 入口

在模式下拉中新增：

- `xray分流模式`

## 23.2 标签页

新增标签页：

- `节点分流`

仅在 `mode=7` 可见。

## 23.3 页面结构

### 23.3.1 运行设置

- 启用状态
- 当前默认兜底节点
- 基础模板
- 绕过大陆IP
- 当前有效规则数

### 23.3.2 规则列表

- 顺序
- 启用/禁用
- 匹配项
- 目标节点
- 备注
- 状态（有效 / 失效）
- 编辑 / 删除

### 23.3.3 规则编辑弹窗

- 选择内置分类
- 或填写自定义域名
- 选择目标节点
- 备注

## 23.4 分类展示策略

一期不做完整 geosite 浏览器。

前端只展示：

- 常用预设分类
- 少量核心 tag

更多扩展 tag 可后续再开放。

---

## 24. 资源约束与限制

## 24.1 规则限制

建议：

- 最大启用规则数：`16`
- 自定义域名总数上限：`256`

## 24.2 目标节点数量限制

按设备档位限制“额外目标节点数”：

- 高配：`8`
- 中配：`6`
- 低配：`4`

这里的“额外目标节点数”不含默认兜底节点。

## 24.3 IPv6 相关额外限制

若设备处于低内存 / 低 CPU 档位，且用户开启：

- `mode=7`
- `IPv6代理`
- sniffing

则应在文档和 UI 中明确：

- 双栈场景 CPU 占用将高于仅 IPv4 场景
- 建议默认保持 `绕过大陆IP=开启`
- 不建议同时启用过多规则与过多目标节点

---

## 25. 一期实施顺序

为降低风险，建议严格按以下顺序落地：

1. 构建规则资产：
   - `geosite-fancyss.dat`
   - `geoip-fancyss.dat`
   - `manifest`
   - `txt/gz`
2. 将 `webtest` 的 per-node outbound cache 抽象为共享 `node_outbound_cache`
3. 实现 `mode=7` 的 xray runtime compiler
4. 实现 `mode=7` 的 DNS runtime generator
5. 实现前端 UI
6. 补齐 ACL / failover / restore / subscribe / status 等联动逻辑
7. 做 IPv4 / IPv6 双栈联调

> **MVP 实际执行顺序**：首版落地采用了不同于上述规划的顺序。实际路径为：先实现 xray runtime compiler（§3）和前端 UI（§5），规则资产用 `rules_ng2/shunt/*.txt` TXT 过渡（跳过 §1 的 geosite/geoip 构建），webtest cache 直接复用而非抽象为独立层（简化 §2），DNS 侧复用 `black_list.txt`（简化 §4）。这一路径更务实——先跑通端到端功能再补齐资产和架构，但留下了 geosite/geoip 资产、DNS 独立化等技术债务。详见 `doc/analysis/node-shunt-supplement.md` §2 差异追踪表。

---

## 26. 一期测试重点

## 26.1 基础功能

- 模式切换到 `mode=7`
- 添加 / 编辑 / 删除规则
- 默认兜底节点切换
- 节点分流规则命中正确

## 26.2 DNS 一致性

- `node_direct` 是否准确
- `shunt_direct` / `shunt_proxy` 是否与 routing 同源
- smartdns / chinadns-ng 是否按预期走不同上游

## 26.3 IPv6

- `IPv6代理=开` 时：
  - IPv6 目的站点能否正确直连/代理
  - IPv6 节点服务器是否可连接
  - `chnroute6` / `geoip-fancyss:cn` 是否一致

- `IPv6代理=关` 时：
  - 代理域名 AAAA 是否被正确抑制
  - 是否仍存在 IPv6 直连泄漏
  - `node_direct` 是否没有误伤 IPv6-only 节点服务器

## 26.4 生命周期

- 订阅更新后规则是否仍有效
- 节点删除后规则是否标记 invalid
- 恢复配置后 runtime 是否能自动恢复
- 故障转移后 `default_proxy` 是否切换正确

---

## 27. 后续扩展方向

一期完成后，后续可沿当前架构继续扩展：

1. 引入 `bridge_socks`，逐步支持：
   - `tuic`
   - `naive`
   - `ssr`
   - `ss + obfs`
2. 支持第三方“规则包”导入
3. 评估 Xray DNS 全接管方案
4. 评估基于 Xray 连接观测能力的更强节点分流
5. 评估更精细的 IPv6 策略，如：
   - 按 tag 单独控制 AAAA
   - 节点服务器域名的 IPv6 能力探测

---

## 28. 参考资料

- Xray Routing 文档  
  `https://xtls.github.io/en/config/routing`

- Xray DNS 文档  
  `https://xtls.github.io/en/config/dns`

- Xray Inbound / sniffing / routeOnly 文档  
  `https://xtls.github.io/en/config/inbound.html`

- Loyalsoldier `v2ray-rules-dat`  
  `https://github.com/Loyalsoldier/v2ray-rules-dat`

- DustinWin `ruleset_geodata`  
  `https://github.com/DustinWin/ruleset_geodata`

- DustinWin `domain-list-custom`  
  `https://github.com/DustinWin/domain-list-custom/tree/domains`

- fancyss 现有文档：
  - `doc/design/node-server-dynamic-resolve-design.md`
  - `doc/implementation/webtest_design_and_maintenance.md`
  - `doc/implementation/node_data_storage_refactor_spec.md`
