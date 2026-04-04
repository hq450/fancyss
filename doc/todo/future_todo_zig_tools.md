# fancyss 未来待办：Zig 工具路线图

本文用于记录 `fancyss` 后续围绕 Zig 小工具的长期规划。

当前已经有两个方向明确且已落地到工程中的工具：

- `geotool`
- `xapi-tool`

后续目标不是把 `fancyss` 整体重写成 Zig，而是持续把以下类型的问题下沉到 Zig：

- shell 很难优雅实现的结构化数据处理
- 高频调用、对性能和内存占用敏感的热路径
- 适合做成稳定 CLI 接口、供多个脚本复用的能力

反过来，像 `dbus`、`nvram`、`iptables/ip6tables`、`ipset`、`dnsmasq`、进程启停、平台差异编排这类“路由器运行时 orchestration”，短期内仍应以 shell 为主。

---

## 一、总体原则

### 1. 一工具一职责

后续 Zig 工具建议按“数据面/控制面/构建面”拆分，不要做一个过大的万能二进制。

建议原则：

- `xapi-tool` 只负责 `Xray API` 运行时控制
- `geotool` 只负责 geodata 资产读取、校验、构建
- `sub-tool` 只负责订阅内容入口、解密、解析、归一化
- `node-tool` 只负责本地节点数据、分类、挑选、规划
- `webtest-tool` 只负责测速计划、缓存、结果聚合

### 2. shell 仍然是 orchestrator

短期内不建议 Zig 直接接管这些内容：

- 插件整体启动/停止/重启
- `iptables/ip6tables/ipset` 规则增删
- `dnsmasq` / `smartdns` / `chinadns-ng` 生命周期管理
- `dbus` 大量写回和兼容老字段的全套逻辑
- 软件中心打包和安装脚本

原因很直接：

- 这些逻辑高度依赖当前固件环境
- 平台差异很多
- shell 虽然不优雅，但在“调用系统命令并串起来”这件事上仍然最适合

### 3. 所有 Zig 工具都要先定义稳定 I/O

建议统一约束：

- 输入优先支持：`stdin`、文件、显式参数
- 输出优先支持：`json`、`jsonl`、稳定文本
- 错误码明确
- 尽量避免工具内部直接读写 `dbus`
- 尽量避免工具内部直接写死 `fancyss` 路径

这样可以保证：

- 脚本层容易替换
- 单元测试容易做
- 以后可以独立复用到别的项目

### 4. 优先做“热点上的小而硬”能力

未来 Zig 化的优先级排序，不按“谁看起来最大”来定，而按以下维度综合判断：

- 是否已经进入运行时热路径
- shell 是否已经明显复杂失控
- 是否频繁做 `jq/awk/sed/sort/base64/openssl` 链式处理
- 是否涉及并发、增量、缓存新鲜度、结构化 diff
- 是否能明显降低 CPU、内存、时延

---

## 二、建议的 Zig 工具版图

### 1. `geotool`

定位：

- geodata 资产工具
- 服务 `rules_ng2/`、`geosite.dat`、`geoip.dat`

当前状态：

- 已有读取、导出、统计类能力

后续建议继续保留并扩展，不要新建平行工具替代它。

#### MVP TODO

- [ ] 增加 `geosite-build`
  - 从 `rules_ng2/site/*.txt` 生成 `geosite.dat`
- [ ] 增加 `geoip-build`
  - 从 `rules_ng2/ip/*.txt` 生成 `geoip.dat`
- [ ] 增加 `lint`
  - 校验分类名、重复项、空分类、非法行、引用缺失
- [ ] 增加 `diff`
  - 对比两版 `site/ip/dat` 资产的增删改摘要
- [ ] 增加 `manifest/stat`
  - 输出每个分类条目数、来源、大小、构建时间等统计

#### 二期 TODO

- [ ] 支持从 `meta/assets.json` 直接驱动批量构建
- [ ] 支持导出“分类依赖图”或“资产引用关系”
- [ ] 支持 `pack/unpack`
  - 在文本资产和 `dat` 之间做双向检查
- [ ] 支持构建前预归一化
  - 域名规则标准化
  - `CIDR` 归一化
  - 重复合并

#### 边界

`geotool` 不建议承担：

- 在线抓取上游规则源
- 发布目录打包
- `fancyss` 运行时分流逻辑

也就是说：

- 拉取上游仍可由仓库脚本做
- `geotool` 只做“构建、校验、读取、分析”

#### 对 fancyss 的价值

- 把 geodata 从“只能读”升级到“可构建、可校验、可分析”
- 让 `rules_ng2` 的真相完全落到一套轻量工具上
- 为后续 `AB` 两套规则集、广告过滤扩展、规则差异发布提供基础

---

### 2. `xapi-tool`

定位：

- `Xray API` 轻量控制客户端
- 服务节点分流热重载、路由规则管理、流量统计

当前状态：

- 已用于 routing / stats 相关链路

它已经证明方向正确，后续应继续作为 `fancyss` 的运行时控制核心工具，而不是回退到频繁调用 `xray api ...`。

#### MVP TODO

- [ ] 增加 `outbound-list`
  - 列出当前运行中所有 `outbound tag`
- [ ] 增加 `outbound-get`
  - 获取指定 `outbound` 的运行时信息
- [ ] 增加 `outbound-add`
  - 动态添加新的 `outbound`
- [ ] 增加 `outbound-remove`
  - 动态移除指定 `outbound`
- [ ] 增加 `outbound-replace`
  - 在不重启 `xray` 的情况下替换某个 `outbound`

#### 二期 TODO

- [ ] 增加“分流 generation 批量应用”能力
  - 把“append 新规则 + cleanup 旧规则”固化到工具内
- [ ] 增加 `routing-apply-plan`
  - 输入一份目标规则状态，内部做最小侵入式应用
- [ ] 增加 `stats-snapshot`
  - 导出运行时统计快照
- [ ] 增加 `stats-diff`
  - 对比两次快照，直接输出增量
- [ ] 增加 `stats-summary`
  - 按 `outbound` 聚合上下行

#### 三期 TODO

- [ ] 如果 `Xray API` 能力足够，进一步支持更细粒度的 `outbound/routing` 热更新
- [ ] 为前端状态卡片提供更稳定的结构化输出
- [ ] 评估是否提供“热重载事务回滚辅助”

#### 边界

`xapi-tool` 不建议承担：

- 生成整份 `xray.json`
- 接管 `fancyss` 的节点存储
- 管理 `iptables` / `dnsmasq`

它的职责应该始终聚焦：

- “已运行的 Xray 实例，如何用最轻量的方式被查询和修改”

#### 对 fancyss 的价值

- 为“配置热重载而不重启 xray”打基础
- 为后续“outbound 动态增删改”打基础
- 为运行时统计、节点分流面板、流量面板提供高性能接口

---

### 3. `sub-tool`

定位：

- 订阅入口工具
- 负责“拿到订阅原文之后”的识别、解密、解析、归一化

建议把它和 `node-tool` 分开。

原因：

- `sub-tool` 面向“外部订阅内容”
- `node-tool` 面向“本地节点数据集”

#### MVP TODO

- [ ] 增加 `inspect`
  - 识别输入是明文、Base64、`gzip`、还是 `SSEP Envelope`
- [ ] 增加 `decrypt-ssep`
  - 按 `doc/design/subscription_session_encryption_draft_v1.md`
  - 支持 `HKDF-SHA256`
  - 支持 `AES-256-GCM`
  - 支持可选 `gzip` 解压
- [ ] 增加 `parse-uri-lines`
  - 解析 `SS/SSR/VMess/VLESS/Trojan/Naive/TUIC/Hy2`
- [ ] 增加 `normalize`
  - 输出统一的节点 `jsonl`
- [ ] 增加 `dedupe`
  - 支持基于关键字段去重
- [ ] 增加 `summary`
  - 输出节点总数、协议分布、分组分布、异常节点数量

#### 二期 TODO

- [ ] 支持 `Clash/Mihomo` 类订阅
- [ ] 支持 `Sing-box` 类订阅
- [ ] 支持订阅解析 diff
  - 输出本次新增、删除、变化节点摘要
- [ ] 支持订阅内容脱敏预览
- [ ] 支持按组、地区、协议做结构化筛选

#### 与加密订阅的关系

`SSEP` 落地时，建议职责划分为：

- `sub-tool`
  - 负责识别 `Envelope`
  - 负责会话解密
  - 负责把结果还原成普通订阅内容
- `node-tool`
  - 负责把“受保护来源”写入本地节点元数据
  - 负责受保护节点的后续分类、展示掩码、规划逻辑

也就是说：

- “订阅会话加密”的密码学入口，优先属于 `sub-tool`
- “受保护节点进入本地后的生命周期”，优先属于 `node-tool`

#### 边界

`sub-tool` 第一阶段不建议接管：

- `curl/wget` 下载
- 代理下载重试策略
- `dbus` 写回
- 订阅任务调度

短期更合理的分工是：

- shell 负责下载和任务控制
- `sub-tool` 负责解析、解密、归一化

#### 从 `ss_node_subscribe.sh` 继续下沉的优先顺序

现阶段结合代码现状，`sub-tool` 后续最值得继续吃掉的，不是整条下载链，而是下载之后这几层：

1. 内容识别增强

- [x] 区分 `uri-lines` / `base64-uri-lines` / `html-login` / `html-redirect` / `html-page` / `json-error` / `text-error`
- [x] 为 `html-redirect` 提供跳转目标提取
- [ ] 支持更多跳转壳模式
- [ ] 支持 `gzip` 解压
- [ ] 支持 `SSEP Envelope` 真正解密

2. 下载后预处理

- [x] shell 基于 `sub-tool inspect` 跟随常见 HTML/JS 跳转页
- [ ] 把“跳转页提取 + 相对链接解析 + 重定向链保护”进一步收敛进 `sub-tool`
- [ ] 输出结构化错误码，而不是只给 `kind`

3. 订阅内容标准化

- [ ] 让 `sub-tool` 直接产出“解码后规范文本”
- [ ] 逐步替代 `sub_prepare_decoded_file()` 里的明文/`base64` 判定和解码
- [ ] 统一行清洗、BOM、CRLF、空行、注释处理

4. 节点过滤与归一化

- [ ] 把 `sub_filter_fancyss_jsonl_file()` 的关键词过滤继续下沉
- [ ] 把“订阅信息节点”识别继续下沉
- [ ] 输出过滤统计与过滤原因摘要

5. 订阅 diff

- [ ] 输出“新增 / 删除 / 变化”节点摘要
- [ ] 让 shell 不再只靠 `md5 + 本地文件覆盖` 做变化判断

6. 最后才考虑整体下载器替换

- [ ] 是否把 `curl/wget` 进一步包进 Zig，需要等前面几层稳定后再评估

换句话说，`ss_node_subscribe.sh` 里最应该变薄的顺序是：

- 先变薄“内容识别与解码”
- 再变薄“过滤与 diff”
- 最后才考虑“下载器本身”

#### 对 fancyss 的价值

- 大幅减轻 `ss_node_subscribe.sh` 里海量协议解析和 `jq/sed/awk/base64` 链式处理
- 为 `SSEP` 订阅会话加密提供一条清晰落地路径
- 为后续支持更多订阅格式打基础

---

### 4. `node-tool`

定位：

- 本地节点数据工具
- 负责节点集的转换、分类、挑选、规划

它是未来“智能分流”的核心支撑工具之一。

#### MVP TODO

- [ ] 增加 `schema-export`
  - 从标准输入或文件导出统一节点集
- [ ] 增加 `schema-import`
  - 把标准节点集转换成 schema2 友好的中间结果
- [ ] 增加 `legacy-to-schema2`
- [ ] 增加 `schema2-to-legacy`
- [ ] 增加 `classify-region`
  - 按 `name/group/server` 归一化分类
  - 支持 `hk/sg/tw/us/jp/...`
- [ ] 增加 `pick-node`
  - 支持随机
  - 支持按 `webtest` 最低延迟
  - 支持简单回退逻辑
- [ ] 增加 `mask-node`
  - 对受保护节点做地址掩码输出

#### 二期 TODO

- [ ] 增加 `smart-shunt-plan`
  - 输入节点集、策略模板、测速结果
  - 输出 `fancyss` 可直接使用的分流规则快照
- [ ] 增加 `failover-pick`
  - 基于当前节点、备份节点、节点池和历史结果选出候选
- [ ] 增加 `node-diff`
  - 比较两份节点集的变化
- [ ] 增加 `validate`
  - 检查关键字段是否缺失、协议字段是否冲突

#### 三期 TODO

- [ ] 支持把 `_protected_sub` 之类的保护元字段纳入统一处理
- [ ] 支持输出“地区桶摘要”
  - 每个地区多少节点
  - 每个地区最佳节点是谁
  - 哪些地区缺失
- [ ] 为前端“智能分流预览”输出结构化结果

#### 边界

`node-tool` 不建议第一阶段直接做：

- 大规模 `dbus` 读写
- 前端页面逻辑
- 实际订阅下载
- 实际测速发起

更合理的边界是：

- “输入一批节点和辅助数据，输出结构化结论”

#### 对 fancyss 的价值

- 让“智能分流”不必继续堆在 shell 和 ASP 里
- 让节点分类逻辑独立成可维护、可测试、可复用的核心
- 让故障转移、分组择优、策略模板都能共享同一套节点视图

---

### 5. `webtest-tool`

定位：

- 测速编排与结果处理工具
- 服务 `webtest` 缓存、批量测速、分组选优

它的重要性很高，但可以排在 `xapi-tool`、`sub-tool`、`node-tool` 之后做。

#### MVP TODO

- [ ] 增加 `cache-inspect`
  - 检查缓存是否新鲜
- [ ] 增加 `cache-diff`
  - 判断哪些节点需要增量重建
- [ ] 增加 `build-plan`
  - 为一批节点生成测速计划和端口分配结果
- [ ] 增加 `result-merge`
  - 把多进程/多批次结果合并成统一输出
- [ ] 增加 `pick-best`
  - 按全局、分组、地区选择最优节点

#### 二期 TODO

- [ ] 支持测速结果统计摘要
  - 成功率
  - 平均延迟
  - 最低延迟
  - 超时比例
- [ ] 支持给“智能分流”直接输出地区最优节点
- [ ] 支持给“故障转移”直接输出候选序列

#### 三期 TODO

- [ ] 评估是否把部分 `webtest` 缓存元数据写入逻辑下沉
- [ ] 评估是否把测速状态机做成稳定 JSON 接口供前端复用

#### 边界

`webtest-tool` 第一阶段不建议直接承担：

- 启停各种代理核心
- 接管全部 `ss_webtest.sh`

因为这些部分仍然和路由器运行环境高度绑定。

#### 对 fancyss 的价值

- 减少 `ss_webtest.sh` 中缓存增量判断、并发编排、结果汇总的复杂 shell 逻辑
- 为“智能分流按地区择优节点”提供可靠基础
- 为故障转移中的“切到延迟最低节点”提供更稳定的数据源

---

### 6. `diag-tool`（低优先级，可选）

定位：

- 诊断与状态汇总工具

这个方向不是当前重点，但后续可以考虑。

#### 可能的 TODO

- [ ] 统一导出进程状态、内存占用、端口占用
- [ ] 统一解析 `iptables/ip6tables` 输出为结构化 JSON
- [ ] 输出当前 `fancyss` 运行态摘要
- [ ] 为前端或日志提供更稳定的诊断接口

#### 优先级判断

它的价值主要在“可观测性”，不是当前功能演进的主线。

所以：

- 可以做
- 但不应该排到 `xapi-tool`、`sub-tool`、`node-tool` 之前

---

## 三、哪些方向暂时不建议 Zig 化

### 1. 插件整体启动/停止/重启

不建议单独做“启动工具”或“重启工具”。

原因：

- `ssconfig.sh` 本质是系统编排脚本
- 它耦合了：
  - `dbus`
  - `nvram`
  - `iptables/ip6tables`
  - `ipset`
  - `dnsmasq`
  - `smartdns/chinadns-ng`
  - 不同平台差异

这部分如果整体迁到 Zig，收益不如成本高。

### 2. 防火墙规则控制工具

短期不建议做 `iptables-tool` / `ipset-tool`。

原因：

- 主要瓶颈不在 shell 文本处理
- 而在系统命令调用本身
- 同时兼容不同平台和内核更复杂

### 3. 订阅下载器整体替换

短期不建议用 Zig 直接取代 `curl/wget` 完整下载链路。

原因：

- `curl/wget` 在 HTTPS、重定向、证书、代理下载、边角兼容上已经很成熟
- 真正复杂且值得替换的，是“下载后怎么识别、解密、解析、归一化”

---

## 四、推荐的实施顺序

### 阶段 0：接口和打包约定

- [ ] 统一 Zig 工具输出格式
- [ ] 统一错误码和日志级别
- [ ] 统一交叉编译和发布流程
- [ ] 统一基准测试方式

### 阶段 1：运行时收益最高的工具

- [ ] `xapi-tool` 增加 `outbound` 动态增删改
- [ ] `xapi-tool` 增加批量 routing 应用能力

### 阶段 2：订阅入口工具

- [ ] `sub-tool` 完成 URI 行解析最小闭环
- [ ] `sub-tool` 接入 `SSEP` 解密最小闭环

### 阶段 3：节点数据与智能分流

- [ ] `node-tool` 完成地区分类
- [ ] `node-tool` 完成节点挑选
- [ ] `node-tool` 完成 `smart-shunt-plan`

### 阶段 4：测速与择优

- [ ] `webtest-tool` 完成缓存 diff 与结果聚合
- [ ] `webtest-tool` 为智能分流和故障转移输出候选结果

### 阶段 5：geodata 构建闭环

- [ ] `geotool` 增加构建、校验、差异分析

### 阶段 6：诊断增强

- [ ] 视需要增加 `diag-tool`

---

## 五、工具之间的依赖关系

- `xapi-tool`
  - 基本独立
  - 直接服务运行中的 `xray`

- `geotool`
  - 基本独立
  - 直接服务 `rules_ng2` 和 geodata 资产

- `sub-tool`
  - 是订阅入口层
  - 可为 `node-tool` 提供标准节点 `jsonl`

- `node-tool`
  - 依赖 `sub-tool` 的标准节点输出
  - 可依赖 `webtest-tool` 的测速结果

- `webtest-tool`
  - 可复用 `node-tool` 的节点分类和挑选能力

从这个关系看，后续的主线其实很清楚：

1. `xapi-tool`
2. `sub-tool`
3. `node-tool`
4. `webtest-tool`
5. `geotool`

---

## 六、建议的最终形态

未来比较理想的版图是：

- `tool/geotool`
  - geodata 资产工具
- `tool/xapi-tool`
  - Xray 运行时控制工具
- `tool/sub-tool`
  - 订阅入口、解密、解析、归一化工具
- `tool/node-tool`
  - 本地节点分类、挑选、规划工具
- `tool/webtest-tool`
  - 测速计划、缓存、结果聚合工具
- `tool/diag-tool`
  - 可选诊断工具

如果后续你希望减少项目数量，一个可接受的收敛方式是：

- 保留 `geotool`
- 保留 `xapi-tool`
- 保留 `sub-tool`
- 把 `webtest-tool` 的一部分能力并入 `node-tool`

但不建议把所有东西继续堆进 `xapi-tool` 或某一个巨型工具里。

---

## 七、与现有文档的关系

本路线图和以下文档直接相关：

- `doc/todo/future_todo_smart_shunt.md`
  - 智能分流将主要依赖 `node-tool`、`webtest-tool`、`xapi-tool`
- `doc/todo/future_todo_subscription_session_encryption.md`
  - `SSEP` 的密码学实现入口优先归属 `sub-tool`
- `doc/design/subscription_session_encryption_draft_v1.md`
  - `sub-tool` 后续需要按该草案实现解密与识别

---

## 八、一句话结论

未来 fancyss 的 Zig 路线，不应该是“把 shell 全部推翻重写”，而应该是：

- 用 `xapi-tool` 吃掉 `Xray API` 运行时控制
- 用 `sub-tool` 吃掉订阅解密与解析
- 用 `node-tool` 吃掉节点分类、挑选与智能分流规划
- 用 `webtest-tool` 吃掉测速缓存与结果聚合
- 用 `geotool` 完成 geodata 读取到构建的闭环

这条路线既符合 fancyss 当前的工程现实，也最容易逐步落地。
