# fancyss 新旧版本键值对应表（Schema 1 / Schema 2）

本文用于说明 fancyss 从旧节点存储结构（Schema 1）升级到新节点存储结构（Schema 2）后，
各类持久化键值的对应关系、用途和变化点。

适用范围：

- 旧结构：节点按 `ssconf_basic_<field>_<seq>` 平铺存储
- 新结构：节点按 `fss_node_<id>` 的 base64(JSON) 对象存储
- 全局配置、DNS 配置、ACL 配置仍主要保留在 `ss_*` / `ss_acl_*` 命名空间

说明：

- `×`：键名与语义不变
- `✔`：键名或存储位置发生变化
- `△`：键名基本不变，但存储语义或编码方式发生变化
- `✘`：不再作为稳定持久配置使用，或仅保留兼容意义
- 本文只覆盖“会进入 dbus/skipdb 的持久化键”和节点对象字段；前端内存态临时变量不在本文范围内
- `<seq>`：旧结构中的顺序号（1..n）
- `<id>`：新结构中的稳定节点 ID
- `<n>`：ACL 行号或可重复序号
- `{1..3}`：表示一组重复槽位，例如 DNS 第 1~3 个上游
- `fss_node_<id>.field`：表示解码 `fss_node_<id>` 后 JSON 对象内部的字段名；实际 DB 键仍然只有 `fss_node_<id>` 一个

---

## 1. 总览：结构层级变化

| 旧键/旧结构 | 新键/新结构 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ssconf_basic_<field>_<seq>` | `fss_node_<id>.field` | ✔ | 节点配置主体；旧结构一字段一 KV，新结构合并为一节点一 JSON Blob |
| `ssconf_basic_node` | `fss_node_current` | ✔ | 当前正在使用的节点；旧结构存顺序号，新结构存稳定节点 ID |
| `ss_failover_s4_3` | `fss_node_failover_backup` | ✔ | 故障转移备用节点；旧结构存顺序号，新结构存稳定节点 ID |
| 无 | `fss_node_order` | ✔ | 节点显示顺序；新结构显式记录顺序，旧结构顺序隐含在后缀编号中 |
| 无 | `fss_node_next_id` | ✔ | 下一个可分配的稳定节点 ID |
| 无 | `fss_data_schema` | ✔ | 当前节点存储结构版本，当前为 `2` |
| 无 | `fss_data_migrated` | ✔ | 是否已完成从旧节点结构迁移 |
| 无 | `fss_data_migration_notice` | ✔ | 前端是否需要显示迁移提醒 |
| 无 | `fss_data_migration_time` | ✔ | 首次迁移时间 |
| 无 | `fss_data_legacy_snapshot` | ✔ | 升级时自动生成的旧版本兼容备份路径 |
| 无 | `fss_data_migrating` | ✔ | 迁移过程中的临时状态位 |
| `ss_*`（非节点类） | `ss_*` | × | 全局基础配置、DNS 配置、订阅配置等，大多数保留原命名空间 |
| `ss_acl_*` | `ss_acl_*` | × | 访问控制规则仍保留原命名空间 |

---

## 2. 基础配置 / 运行状态键

除“节点本身”外，大多数全局键在新旧结构中保持不变。

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ss_basic_enable` | `ss_basic_enable` | × | fancyss 主开关 |
| `ss_basic_version_local` | `ss_basic_version_local` | × | 当前本地插件版本号 |
| `ss_basic_status` | `ss_basic_status` | × | 后端运行状态标记；通常 `1` 表示已启动，`0` 表示未启动 |
| `ss_basic_wait` | `ss_basic_wait` | × | 停止或切换过程中的等待标记 |
| `ss_basic_interval` | `ss_basic_interval` | × | 主循环/定时检查间隔 |
| `ss_basic_row` | `ss_basic_row` | × | 节点列表最大显示行数 |
| `ss_adv_sub` | `ss_adv_sub` | × | 订阅页高级选项显示状态（前端 UI 偏好） |
| `ss_basic_tablet` | `ss_basic_tablet` | × | 平板布局/简化布局开关（前端 UI 偏好） |
| `ss_basic_noserver` | `ss_basic_noserver` | × | 是否隐藏服务器地址等敏感展示信息（前端 UI 偏好） |
| `ss_basic_dragable` | `ss_basic_dragable` | × | 节点列表拖拽排序开关（前端 UI 偏好） |
| `ss_basic_qrcode` | `ss_basic_qrcode` | × | 节点二维码相关展示开关（前端 UI 偏好） |
| `ss_basic_tfo` | `ss_basic_tfo` | × | TCP Fast Open 总开关 |
| `ss_basic_mcore` | `ss_basic_mcore` | × | 多核/多线程相关优化开关 |
| `ss_basic_vcore` / `ss_basic_tcore` | 同名 | × | 当前固件/机型上 Xray / Tuic 核心能力标记 |
| `ss_basic_proxy_newb` | `ss_basic_proxy_newb` | × | New Bing 模式开关 |
| `ss_basic_proxy_ipv6` | `ss_basic_proxy_ipv6` | × | IPv6 透明代理总开关 |
| `ss_basic_udpoff` / `ss_basic_udpall` | 同名 | × | 全局 UDP 代理策略兼容位；新逻辑下主要作为全局默认/兼容状态 |
| `ss_basic_block_quic` | `ss_basic_block_quic` | × | 全局默认 QUIC 屏蔽策略；ACL 细化后仍作为默认值来源之一 |
| `ss_basic_nonetcheck` | `ss_basic_nonetcheck` | × | 启动时跳过联网检测 |
| `ss_basic_nochnipcheck` | `ss_basic_nochnipcheck` | × | 启动时跳过国内出口 IP 检测 |
| `ss_basic_nofrnipcheck` | `ss_basic_nofrnipcheck` | × | 启动时跳过代理出口 IP 检测 |
| `ss_basic_noruncheck` | `ss_basic_noruncheck` | × | 启动时跳过核心进程检查 |
| `ss_basic_notimecheck` / `ss_basic_nocdnscheck` / `ss_basic_nofdnscheck` | 同名 | × | 历史兼容/内部保护开关；分别用于跳过时间、CDN DNS、前置 DNS 等检查 |
| `ss_basic_internet6_flag` | `ss_basic_internet6_flag` | × | 当前系统 IPv6 连通性检测结果缓存 |
| `ss_basic_server_ip` | `ss_basic_server_ip` | × | 当前生效节点服务器域名解析后的 IP |
| `ss_basic_lastru` | `ss_basic_lastru` | × | 最近一次成功解析节点域名时使用的 DNS 解析器槽位 |
| `ss_failover_enable` | `ss_failover_enable` | × | 故障转移总开关 |
| `ss_failover_c{1..3}` | `ss_failover_c{1..3}` | × | 故障转移条件/检测项目相关开关 |
| `ss_failover_s1` / `ss_failover_s2_1` / `ss_failover_s2_2` / `ss_failover_s3_1` / `ss_failover_s3_2` / `ss_failover_s4_1` / `ss_failover_s4_2` / `ss_failover_s5` | 同名 | × | 故障转移策略、阈值、检测方式、切换行为等参数 |
| `ss_reboot_check` | `ss_reboot_check` | × | 定时任务模式选择（如每天/每周/间隔等） |
| `ss_basic_week` / `ss_basic_day` | 同名 | × | 定时任务中的星期/日期参数 |
| `ss_basic_inter_min` / `ss_basic_inter_hour` / `ss_basic_inter_day` / `ss_basic_inter_pre` | 同名 | × | 间隔型定时任务的时间粒度和周期 |
| `ss_basic_time_hour` / `ss_basic_time_min` | 同名 | × | 定时任务执行时刻 |
| `ss_basic_tri_reboot_time` | `ss_basic_tri_reboot_time` | × | 节点服务器 IP 变化触发重启的判定策略 |
| `ss_basic_hy2_up_speed` / `ss_basic_hy2_dl_speed` | 同名 | × | hy2 默认上/下行速率参数 |
| `ss_basic_hy2_tfo_switch` | `ss_basic_hy2_tfo_switch` | × | hy2 默认 TFO 行为开关 |
| `ss_basic_hy2_cg_opt` | `ss_basic_hy2_cg_opt` | × | hy2 默认拥塞控制选项 |
| `ss_basic_latency_opt` | `ss_basic_latency_opt` | × | Web 延迟测试能力默认策略/机型预设；主要由安装脚本初始化 |
| `ss_basic_latency_batch` | `ss_basic_latency_batch` | × | 批量 Web 延迟测试开关 |
| `ss_basic_lt_cru_opts` / `ss_basic_lt_cru_time` | 同名 | × | 批量 Web 延迟测试定时任务策略和执行时刻 |

---

## 3. DNS / 解析 / 自定义规则键

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ss_basic_dns_plan` | `ss_basic_dns_plan` | × | DNS 方案选择（chinadns-ng / smartdns / 组合方案） |
| `ss_basic_chng` | `ss_basic_chng` | × | chinadns-ng 工作模式/解析方案选择 |
| `ss_basic_smrt` | `ss_basic_smrt` | × | smartdns 工作模式/解析方案选择 |
| `ss_basic_add_ispdns` | `ss_basic_add_ispdns` | × | 是否把运营商 DNS 追加到中国 DNS 组 |
| `ss_basic_dns_hijack` | `ss_basic_dns_hijack` | × | DNS 劫持 / DNS 重定向开关 |
| `ss_basic_dns_serverx` | `ss_basic_dns_serverx` | × | 是否替换 dnsmasq 为插件内增强 DNS 组件 |
| `ss_basic_server_resolv` | `ss_basic_server_resolv` | × | 节点服务器域名解析器选择策略 |
| `ss_basic_server_resolv_user` | `ss_basic_server_resolv_user` | × | 自定义节点服务器解析器（自定义 DNS:Port） |
| `ss_basic_chng_china_dns_{1..3}_chk` | 同名 | × | chinadns-ng 中国上游第 1~3 槽位是否启用 |
| `ss_basic_chng_china_net_{1..3}_typ` | 同名 | × | chinadns-ng 中国上游第 1~3 槽位协议类型（UDP/TCP/DoT 等） |
| `ss_basic_chng_china_{udp\|tcp\|dot}_{1..3}_{opt\|usr}` | 同名 | × | chinadns-ng 中国上游第 1~3 槽位的预置值/用户自定义值 |
| `ss_basic_chng_trust_dns_{1..3}_chk` | 同名 | × | chinadns-ng 可信上游第 1~3 槽位是否启用 |
| `ss_basic_chng_trust_net_{1..3}_typ` | 同名 | × | chinadns-ng 可信上游第 1~3 槽位协议类型 |
| `ss_basic_chng_trust_{udp\|tcp\|dot}_{1..3}_{opt\|usr}` | 同名 | × | chinadns-ng 可信上游第 1~3 槽位的预置值/用户自定义值 |
| `ss_basic_chng_ipv6_drop_direc` | `ss_basic_chng_ipv6_drop_direc` | × | 直连域名是否过滤 AAAA 记录 |
| `ss_basic_chng_ipv6_drop_proxy` | `ss_basic_chng_ipv6_drop_proxy` | × | 代理域名是否过滤 AAAA 记录；开启 IPv6 代理后通常会自动关闭 |
| `ss_basic_block_resov` | `ss_basic_block_resov` | × | 是否拦截/阻止特定解析结果（如污染解析的保护项） |
| `ss_dnsmasq` | `ss_dnsmasq` | × | 自定义 dnsmasq 配置；值以 base64 形式保存 |
| `ss_basic_custom` | `ss_basic_custom` | × | 自定义脚本/规则片段；值以 base64 形式保存 |
| `ss_wan_white_ip` / `ss_wan_white_domain` | 同名 | × | WAN 白名单 IP / 域名；值以 base64 形式保存 |
| `ss_wan_black_ip` / `ss_wan_black_domain` | 同名 | × | WAN 黑名单 IP / 域名；值以 base64 形式保存 |
| `ss_basic_furl` / `ss_basic_curl` | 同名 | × | 状态检测 / 延迟测试使用的国外/国内测试 URL |

---

## 4. 订阅 / 规则更新 / 节点导入导出相关键

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ss_online_links` | `ss_online_links` | × | 订阅 URL 列表；多行文本，经 base64 保存 |
| `ssr_subscribe_mode` | `ssr_subscribe_mode` | × | 订阅模式/节点处理策略 |
| `ss_basic_online_links_proxy` | `ss_basic_online_links_proxy` | × | 下载订阅时是否走代理网络 |
| `ss_basic_online_ua` | `ss_basic_online_ua` | × | 订阅下载 User-Agent 策略 |
| `ss_basic_node_update` | `ss_basic_node_update` | × | 是否启用定时更新订阅 |
| `ss_basic_node_update_day` / `ss_basic_node_update_hr` | 同名 | × | 定时更新订阅的星期/小时 |
| `ss_basic_exclude` / `ss_basic_include` | 同名 | × | 订阅节点过滤关键词（排除/包含） |
| `ss_basic_sub_ai` | `ss_basic_sub_ai` | × | 订阅时自动修正/补全证书参数等智能处理开关 |
| `ss_basic_sub_node_log` | `ss_basic_sub_node_log` | × | 订阅时是否输出逐节点详细日志 |
| `ss_basic_gfwlist_update` | `ss_basic_gfwlist_update` | × | GFWList 自动更新开关 |
| `ss_basic_chnroute_update` | `ss_basic_chnroute_update` | × | chnroute 自动更新开关 |
| `ss_basic_chnlist_update` | `ss_basic_chnlist_update` | × | ChinaList 自动更新开关 |
| `ss_basic_rule_update` / `ss_basic_rule_update_time` | 同名 | × | 规则自动更新时间策略 |

补充说明：

- 订阅脚本还有一套**非 dbus** 的持久化缓存，目录为 `/koolshare/configs/fancyss/subscribe_cache/`
- 其中 `raw/` 保存每个订阅源最近一次成功下载并解码后的原始内容，`parsed/` 保存最近一次成功解析后的节点列表
- `parsed/sub_<hash>.meta` 保存“会影响最终订阅节点结果”的上下文摘要，例如：
  - `[排除]/[包括]` 关键词
  - `ssr_subscribe_mode`
  - `ss_basic_sub_ai`
  - hysteria2 订阅默认参数（上/下行、TFO、拥塞控制）
- `meta` 带有 `schema_version` 字段；当脚本升级并调整 meta 结构或比较语义时，只需提升该版本号，下一次订阅会自动判定旧 meta 失效并重建缓存

---

## 5. ACL / 局域网访问控制键

> 访问控制规则没有并入 `fss_node_*`，仍保留在 `ss_acl_*` 命名空间。

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ss_acl_default_mode` | `ss_acl_default_mode` | × | 默认规则（所有主机 / 剩余主机）的代理模式 |
| `ss_acl_default_port` | `ss_acl_default_ports` | ✔ | 默认规则的代理端口；`<= 3.5.3` 使用旧键，`>= 3.5.4` 使用新键；新版本运行态会自动归一到 `ss_acl_default_ports`，导出旧版兼容配置时会同时写入两者 |
| `ss_acl_default_udp` | `ss_acl_default_udp` | × | 默认规则的 UDP 代理开关 |
| `ss_acl_default_quic` | `ss_acl_default_quic` | × | 默认规则的 QUIC 屏蔽开关 |
| `ss_acl_name_<n>` | `ss_acl_name_<n>` | × | 第 `<n>` 条 ACL 的客户端地址（IPv4 / CIDR 文本显示） |
| `ss_acl_mac_<n>` | `ss_acl_mac_<n>` | × | 第 `<n>` 条 ACL 对应客户端 MAC；IPv4/IPv6 ACL 匹配的真实依据 |
| `ss_acl_mode_<n>` | `ss_acl_mode_<n>` | × | 第 `<n>` 条 ACL 的代理模式 |
| `ss_acl_port_<n>` | `ss_acl_port_<n>` | × | 第 `<n>` 条 ACL 的代理端口范围 |
| `ss_acl_udp_<n>` | `ss_acl_udp_<n>` | × | 第 `<n>` 条 ACL 的 UDP 代理开关 |
| `ss_acl_quic_<n>` | `ss_acl_quic_<n>` | × | 第 `<n>` 条 ACL 的 QUIC 屏蔽开关 |
| `ss_acl_name` / `ss_acl_mode` / `ss_acl_port` / `ss_acl_udp` / `ss_acl_quic` / `ss_acl_mac` | 同名 | × | ACL 编辑面板中的临时输入键；保存后会展开为带 `<n>` 后缀的正式规则 |

补充说明：

- `<= 3.5.3` 的默认 ACL 端口键为 `ss_acl_default_port`，前端是文本输入框，常见预置值为 `80,443`、`22,80,443`、`all`，也可接受自定义端口串。
- `>= 3.5.4` 的默认 ACL 端口键为 `ss_acl_default_ports`，前端改为下拉选择，并新增 `22,80,443,8080,8443` 这个预置值。
- Schema 2 / 新版本运行态、安装初始化、配置恢复时，会优先把旧键迁移为 `ss_acl_default_ports`，随后删除残留的 `ss_acl_default_port`，避免前后端回填冲突。
- 新版本 JSON 配置备份只保存 `ss_acl_default_ports`；旧版兼容 `.sh` 备份会同时导出 `ss_acl_default_ports` 和 `ss_acl_default_port`，以兼容回退到 `<= 3.5.3` 与 `>= 3.5.4` 的版本。

---

## 6. 节点元数据 / 引用关系键

### 6.1 节点引用与顺序

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ssconf_basic_node` | `fss_node_current` | ✔ | 当前正在使用的节点；旧值是顺序号，新值是稳定节点 ID |
| `ss_failover_s4_3` | `fss_node_failover_backup` | ✔ | 故障转移备用节点；旧值是顺序号，新值是稳定节点 ID |
| 无 | `fss_node_order` | ✔ | 节点显示顺序；值为稳定节点 ID 列表，如 `101,102,108` |
| 无 | `fss_node_next_id` | ✔ | 新增节点时下一个可用稳定 ID |

### 6.2 节点存储外壳

| 旧键 | 新键 | 变更 | 作用 |
| --- | --- | --- | --- |
| `ssconf_basic_<field>_<seq>` | `fss_node_<id>` | ✔ | 节点主存储；旧结构一字段一 KV，新结构整节点写入一个 base64(JSON) Blob |
| 无 | `fss_node_<id>._schema` | ✔ | 节点对象 schema 版本，当前为 `2` |
| 无 | `fss_node_<id>._id` | ✔ | 节点稳定 ID |
| 无 | `fss_node_<id>._rev` | ✔ | 节点对象修订号 |
| 无 | `fss_node_<id>._source` | ✔ | 节点来源：`manual` / `subscribe` / `import` / `migration` |
| 无 | `fss_node_<id>._updated_at` | ✔ | 节点最近更新时间戳 |
| 无 | `fss_node_<id>._created_at` | ✔ | 节点创建时间戳（如存在） |
| 无 | `fss_node_<id>._migrated_from` | ✔ | 从旧结构迁移时对应的旧顺序号 |

---

## 7. 节点字段映射：公共字段

> 以下表格中的“新键”列表示 `fss_node_<id>` 解码后的 JSON 字段名。

| 旧键模式 | 新键 | 变更 | 适用范围 | 作用 / 备注 |
| --- | --- | --- | --- | --- |
| `ssconf_basic_name_<seq>` | `name` | ✔ | 全协议 | 节点显示名称 |
| `ssconf_basic_group_<seq>` | `group` | ✔ | 订阅节点 | 订阅来源分组；新结构仍保留原值，例如 `Nexitally_abcd` |
| `ssconf_basic_type_<seq>` | `type` | ✔ | 全协议 | 节点类型：`0=SS`、`1=SSR`、`3=V2Ray`、`4=Xray`、`5=Trojan`、`6=Naive`、`7=TUIC`、`8=Hysteria2` |
| `ssconf_basic_mode_<seq>` | `mode` | ✔ | 全协议 | 节点代理模式 |
| `ssconf_basic_server_<seq>` | `server` | ✔ | SS / SSR / V2Ray / Xray / Trojan | 节点服务器地址 |
| `ssconf_basic_port_<seq>` | `port` | ✔ | SS / SSR / V2Ray / Xray / Trojan | 节点服务器端口 |
| `ssconf_basic_server_ip_<seq>` | `server_ip` | △ | 运行时 | 解析后的服务器 IP；新结构中属于运行态字段，默认不参与迁移/导出 |
| `ssconf_basic_latency_<seq>` | `latency` | △ | 运行时 | 节点测速缓存；新结构中属于运行态字段，默认不参与迁移/导出 |
| `ssconf_basic_ping_<seq>` | `ping` | △ | 运行时 | ping 测试缓存；新结构中属于运行态字段，默认不参与迁移/导出 |

### 公共字段特殊说明

- `server_ip / latency / ping` 在 Schema 2 中仍可作为临时运行态字段写入节点 JSON，
  但迁移、原生 JSON 备份、旧版本兼容导出时都会被主动剔除，不视为稳定配置项。
- 新结构下整个 `fss_node_<id>` 的值会整体做一次 base64，因此 JSON 内部的普通文本字段均以原文保存。

---

## 8. 节点字段映射：SS / SSR

| 旧键模式 | 新键 | 变更 | 适用协议 | 作用 / 备注 |
| --- | --- | --- | --- | --- |
| `ssconf_basic_method_<seq>` | `method` | ✔ | SS / SSR | 加密方式 |
| `ssconf_basic_password_<seq>` | `password` | △ | SS / SSR | 节点密码；旧结构单值为 base64，新结构 JSON 内存原文，节点外层整体 base64 |
| `ssconf_basic_ss_obfs_<seq>` | `ss_obfs` | ✔ | SS | simple-obfs 类型 |
| `ssconf_basic_ss_obfs_host_<seq>` | `ss_obfs_host` | ✔ | SS | simple-obfs 伪装 Host |
| `ssconf_basic_rss_protocol_<seq>` | `rss_protocol` | ✔ | SSR | SSR protocol |
| `ssconf_basic_rss_protocol_param_<seq>` | `rss_protocol_param` | ✔ | SSR | SSR protocol 参数 |
| `ssconf_basic_rss_obfs_<seq>` | `rss_obfs` | ✔ | SSR | SSR obfs 类型 |
| `ssconf_basic_rss_obfs_param_<seq>` | `rss_obfs_param` | ✔ | SSR | SSR obfs 参数 |

---

## 9. 节点字段映射：V2Ray

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_v2ray_use_json_<seq>` | `v2ray_use_json` | △ | 是否使用完整 JSON 出站配置；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_v2ray_json_<seq>` | `v2ray_json` | △ | V2Ray JSON 配置；旧结构值为 base64(JSON 文本)，新结构字段存原文 JSON 串 |
| `ssconf_basic_v2ray_uuid_<seq>` | `v2ray_uuid` | ✔ | UUID |
| `ssconf_basic_v2ray_alterid_<seq>` | `v2ray_alterid` | ✔ | alterId |
| `ssconf_basic_v2ray_security_<seq>` | `v2ray_security` | ✔ | 用户级 security 配置 |
| `ssconf_basic_v2ray_network_<seq>` | `v2ray_network` | ✔ | 传输层类型，如 `tcp/ws/h2/grpc/quic/httpupgrade` |
| `ssconf_basic_v2ray_headtype_{tcp\|kcp\|quic}_<seq>` | `v2ray_headtype_{tcp\|kcp\|quic}` | ✔ | 对应传输下的头部伪装类型 |
| `ssconf_basic_v2ray_kcp_seed_<seq>` | `v2ray_kcp_seed` | ✔ | mKCP seed |
| `ssconf_basic_v2ray_grpc_mode_<seq>` | `v2ray_grpc_mode` | ✔ | gRPC 模式 |
| `ssconf_basic_v2ray_network_path_<seq>` | `v2ray_network_path` | ✔ | Path / ServiceName / URI 等路径类参数 |
| `ssconf_basic_v2ray_network_host_<seq>` | `v2ray_network_host` | ✔ | Host / authority 等主机名参数 |
| `ssconf_basic_v2ray_network_security_<seq>` | `v2ray_network_security` | ✔ | TLS 等传输层安全类型 |
| `ssconf_basic_v2ray_network_security_sni_<seq>` | `v2ray_network_security_sni` | ✔ | TLS SNI |
| `ssconf_basic_v2ray_network_security_ai_<seq>` | `v2ray_network_security_ai` | △ | TLS allowInsecure；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_v2ray_network_security_alpn_{h2\|http}_<seq>` | `v2ray_network_security_alpn_{h2\|http}` | △ | TLS ALPN 选项；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_v2ray_mux_enable_<seq>` | `v2ray_mux_enable` | △ | Mux 开关；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_v2ray_mux_concurrency_<seq>` | `v2ray_mux_concurrency` | ✔ | Mux 并发值 |

---

## 10. 节点字段映射：Xray / VMess / VLESS

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_xray_use_json_<seq>` | `xray_use_json` | △ | 是否使用完整 Xray JSON；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_xray_json_<seq>` | `xray_json` | △ | Xray JSON 配置；旧结构值为 base64(JSON 文本)，新结构字段存原文 JSON 串 |
| `ssconf_basic_xray_uuid_<seq>` | `xray_uuid` | ✔ | UUID |
| `ssconf_basic_xray_alterid_<seq>` | `xray_alterid` | ✔ | VMess 兼容 alterId；主要为旧配置/订阅兼容保留 |
| `ssconf_basic_xray_prot_<seq>` | `xray_prot` | △ | 协议类型，如 `vless/vmess`；旧结构缺失时新结构迁移默认补为 `vless` |
| `ssconf_basic_xray_encryption_<seq>` | `xray_encryption` | ✔ | 加密方式，如 `none` |
| `ssconf_basic_xray_flow_<seq>` | `xray_flow` | ✔ | XTLS / Vision flow |
| `ssconf_basic_xray_network_<seq>` | `xray_network` | ✔ | 传输层类型，如 `tcp/ws/h2/grpc/quic/httpupgrade/xhttp` |
| `ssconf_basic_xray_headtype_{tcp\|kcp\|quic}_<seq>` | `xray_headtype_{tcp\|kcp\|quic}` | ✔ | 对应传输下的头部伪装类型 |
| `ssconf_basic_xray_kcp_seed_<seq>` | `xray_kcp_seed` | ✔ | mKCP seed |
| `ssconf_basic_xray_grpc_mode_<seq>` | `xray_grpc_mode` | ✔ | gRPC 模式 |
| `ssconf_basic_xray_xhttp_mode_<seq>` | `xray_xhttp_mode` | ✔ | XHTTP 模式 |
| `ssconf_basic_xray_network_path_<seq>` | `xray_network_path` | ✔ | Path / ServiceName / URI 等路径类参数 |
| `ssconf_basic_xray_network_host_<seq>` | `xray_network_host` | ✔ | Host / authority 等主机名参数 |
| `ssconf_basic_xray_network_security_<seq>` | `xray_network_security` | ✔ | TLS / REALITY 等安全类型 |
| `ssconf_basic_xray_network_security_sni_<seq>` | `xray_network_security_sni` | ✔ | TLS / REALITY SNI |
| `ssconf_basic_xray_network_security_ai_<seq>` | `xray_network_security_ai` | △ | TLS allowInsecure；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_xray_network_security_alpn_{h2\|http}_<seq>` | `xray_network_security_alpn_{h2\|http}` | △ | TLS ALPN 选项；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_xray_pcs_<seq>` | `xray_pcs` | ✔ | `pinnedPeerCertSha256` |
| `ssconf_basic_xray_vcn_<seq>` | `xray_vcn` | ✔ | `verifyPeerCertByName`；shell 环境层仍兼容旧别名 `xray_svn` |
| `ssconf_basic_xray_fingerprint_<seq>` | `xray_fingerprint` | ✔ | `fingerprint` / uTLS 指纹 |
| `ssconf_basic_xray_show_<seq>` | `xray_show` | △ | REALITY 的 `show` 开关；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_xray_publickey_<seq>` | `xray_publickey` | ✔ | REALITY 公钥 |
| `ssconf_basic_xray_shortid_<seq>` | `xray_shortid` | ✔ | REALITY shortId |
| `ssconf_basic_xray_spiderx_<seq>` | `xray_spiderx` | ✔ | REALITY spiderX |

---

## 11. 节点字段映射：Trojan / Naive / TUIC / Hysteria2

### 11.1 Trojan

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_trojan_uuid_<seq>` | `trojan_uuid` | ✔ | Trojan 密码 / UUID |
| `ssconf_basic_trojan_sni_<seq>` | `trojan_sni` | ✔ | SNI |
| `ssconf_basic_trojan_ai_<seq>` | `trojan_ai` | △ | allowInsecure；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_trojan_tfo_<seq>` | `trojan_tfo` | △ | Trojan TFO 开关；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_trojan_pcs_<seq>` | `trojan_pcs` | ✔ | `pinnedPeerCertSha256` |
| `ssconf_basic_trojan_vcn_<seq>` | `trojan_vcn` | ✔ | `verifyPeerCertByName` |
| `ssconf_basic_trojan_plugin_<seq>` | `trojan_plugin` | ✔ | Trojan 插件名；仅兼容旧配置/订阅保留 |
| `ssconf_basic_trojan_obfs_<seq>` | `trojan_obfs` | ✔ | Trojan 插件 obfs 类型；仅兼容旧配置/订阅保留 |
| `ssconf_basic_trojan_obfshost_<seq>` | `trojan_obfshost` | ✔ | Trojan 插件 Host；仅兼容旧配置/订阅保留 |
| `ssconf_basic_trojan_obfsuri_<seq>` | `trojan_obfsuri` | ✔ | Trojan 插件 URI；仅兼容旧配置/订阅保留 |

### 11.2 Naive

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_naive_prot_<seq>` | `naive_prot` | ✔ | Naive 传输协议，通常为 `https` |
| `ssconf_basic_naive_server_<seq>` | `naive_server` | ✔ | Naive 服务器地址 |
| `ssconf_basic_naive_port_<seq>` | `naive_port` | ✔ | Naive 端口 |
| `ssconf_basic_naive_user_<seq>` | `naive_user` | ✔ | Naive 用户名 |
| `ssconf_basic_naive_pass_<seq>` | `naive_pass` | △ | Naive 密码；旧结构单值为 base64，新结构 JSON 内存原文 |

### 11.3 TUIC

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_tuic_json_<seq>` | `tuic_json` | △ | TUIC JSON 配置；旧结构值为 base64(JSON 文本)，新结构字段存原文 JSON 串 |

### 11.4 Hysteria2

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_hy2_server_<seq>` | `hy2_server` | ✔ | Hysteria2 服务器地址 |
| `ssconf_basic_hy2_port_<seq>` | `hy2_port` | ✔ | Hysteria2 端口 |
| `ssconf_basic_hy2_pass_<seq>` | `hy2_pass` | ✔ | Hysteria2 密码 |
| `ssconf_basic_hy2_up_<seq>` / `ssconf_basic_hy2_dl_<seq>` | `hy2_up` / `hy2_dl` | ✔ | 上/下行速率 |
| `ssconf_basic_hy2_obfs_<seq>` / `ssconf_basic_hy2_obfs_pass_<seq>` | `hy2_obfs` / `hy2_obfs_pass` | ✔ | Hysteria2 混淆类型和密码 |
| `ssconf_basic_hy2_sni_<seq>` | `hy2_sni` | ✔ | SNI |
| `ssconf_basic_hy2_pcs_<seq>` | `hy2_pcs` | ✔ | `pinnedPeerCertSha256` |
| `ssconf_basic_hy2_vcn_<seq>` | `hy2_vcn` | ✔ | `verifyPeerCertByName`；shell 环境层仍兼容旧别名 `hy2_svn` |
| `ssconf_basic_hy2_ai_<seq>` | `hy2_ai` | △ | allowInsecure；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_hy2_tfo_<seq>` | `hy2_tfo` | △ | TFO 开关；新结构布尔值规范化为 `0/1` |
| `ssconf_basic_hy2_cg_<seq>` | `hy2_cg` | ✔ | 拥塞控制类型，如 `bbr/brutal` |

---

## 12. 保留 / 兼容 / 废弃字段

| 旧键模式 | 新键 | 变更 | 作用 / 备注 |
| --- | --- | --- | --- |
| `ssconf_basic_koolgame_udp_<seq>` | `koolgame_udp` | ✘ | 历史兼容保留字段；前端不再主动生成 |
| `ssconf_basic_use_kcp_<seq>` | `use_kcp` | ✘ | 历史兼容保留字段；前端不再主动生成 |
| `ssconf_basic_use_lb_<seq>` | `use_lb` | ✘ | 历史兼容保留字段；前端不再主动生成 |
| `ssconf_basic_lbmode_<seq>` | `lbmode` | ✘ | 历史兼容保留字段；前端不再主动生成 |
| `ssconf_basic_weight_<seq>` | `weight` | ✘ | 历史兼容保留字段；前端不再主动生成 |
| `ss_basic_udpgpt` | `ss_basic_udpgpt` | ✘ | 历史遗留兼容键，当前代码仅保留默认值，不再作为主逻辑开关 |

---

## 13. 编码与导出规则差异

### 13.1 节点敏感字段

以下字段在旧结构中为“字段值单独 base64”，迁移到新结构后改为“JSON 内原文 + 节点外层统一 base64”：

- `password`
- `naive_pass`
- `v2ray_json`
- `xray_json`
- `tuic_json`

### 13.2 布尔字段

以下字段在旧结构里常出现 `"" / 缺失 / 1` 三态，Schema 2 统一规范为 `"0" / "1"`：

- `v2ray_use_json`
- `v2ray_mux_enable`
- `v2ray_network_security_ai`
- `v2ray_network_security_alpn_h2`
- `v2ray_network_security_alpn_http`
- `xray_use_json`
- `xray_network_security_ai`
- `xray_network_security_alpn_h2`
- `xray_network_security_alpn_http`
- `xray_show`
- `trojan_ai`
- `trojan_tfo`
- `hy2_ai`
- `hy2_tfo`

### 13.3 运行态字段

以下字段虽然在运行期仍可能出现，但不再视为稳定配置项：

- `server_ip`
- `latency`
- `ping`

它们不会进入：

- Schema 1 -> Schema 2 迁移主体
- 原生 JSON 备份主体
- 旧版本兼容 SH 导出主体

---

## 14. 推荐的阅读顺序

如果你是为了理解当前实现，建议按下面顺序阅读代码：

1. `fancyss/scripts/ss_node_common.sh`：新旧结构迁移、导出、恢复的核心映射逻辑
2. `fancyss/scripts/ss_base.sh`：把当前节点导出为 `ss_basic_*` 环境变量的兼容层
3. `fancyss/webs/Module_shadowsocks.asp`：前端如何读写旧结构字段与新结构节点对象
4. `fancyss/scripts/ss_node_subscribe.sh`：订阅节点如何写入 Schema 2 节点对象
5. `fancyss/ss/ssconfig.sh`：后端运行时如何消费这些键值
