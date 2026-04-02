# fancyss 节点字段精简速查表

本文是 `doc/reference/dbus_key_mapping_reference.md` 的节点专用精简版，只保留：

- 当前节点/备用节点/顺序相关键
- 节点本体字段的新旧对应
- 编码差异与运行态字段说明

适合在改前后端节点逻辑、订阅脚本、导入导出脚本时快速查阅。

---

## 1. 节点结构速记

### 1.1 旧结构（Schema 1）

```sh
ssconf_basic_name_1=...
ssconf_basic_server_1=...
ssconf_basic_port_1=...
ssconf_basic_xray_uuid_1=...
...
ssconf_basic_node=1
ss_failover_s4_3=2
```

- 节点字段按 `ssconf_basic_<field>_<seq>` 平铺
- `<seq>` 既是节点顺序，也是节点主键

### 1.2 新结构（Schema 2）

```sh
fss_node_order=101,102,108
fss_node_current=102
fss_node_failover_backup=108
fss_node_101=<base64(json)>
fss_node_102=<base64(json)>
```

- 节点主存储变为 `fss_node_<id>`
- `<id>` 是稳定节点 ID
- 显示顺序单独保存在 `fss_node_order`

---

## 2. 节点引用键速查

| 旧键 | 新键 | 说明 |
| --- | --- | --- |
| `ssconf_basic_node` | `fss_node_current` | 当前正在使用的节点；旧值是顺序号，新值是稳定节点 ID |
| `ss_failover_s4_3` | `fss_node_failover_backup` | 故障转移备用节点；旧值是顺序号，新值是稳定节点 ID |
| 无 | `fss_node_order` | 节点显示顺序，如 `101,102,108` |
| 无 | `fss_node_next_id` | 下一个可分配的稳定节点 ID |

---

## 3. 节点公共字段

> 新字段指 `fss_node_<id>` 解码后的 JSON 字段名。

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_name_<seq>` | `name` | 节点名称 |
| `ssconf_basic_group_<seq>` | `group` | 订阅分组/来源标记 |
| `ssconf_basic_type_<seq>` | `type` | 节点类型代码 |
| `ssconf_basic_mode_<seq>` | `mode` | 节点代理模式 |
| `ssconf_basic_server_<seq>` | `server` | 服务器地址 |
| `ssconf_basic_port_<seq>` | `port` | 服务器端口 |

### 3.1 `type` 类型值

| 值 | 协议 |
| --- | --- |
| `0` | SS |
| `1` | SSR |
| `3` | V2Ray |
| `4` | Xray |
| `5` | Trojan |
| `6` | NaiveProxy |
| `7` | TUIC |
| `8` | Hysteria2 |

---

## 4. 按协议划分的节点字段

### 4.1 SS / SSR

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_method_<seq>` | `method` | 加密方式 |
| `ssconf_basic_password_<seq>` | `password` | 密码 |
| `ssconf_basic_ss_obfs_<seq>` | `ss_obfs` | SS 混淆类型 |
| `ssconf_basic_ss_obfs_host_<seq>` | `ss_obfs_host` | SS 混淆 Host |
| `ssconf_basic_rss_protocol_<seq>` | `rss_protocol` | SSR protocol |
| `ssconf_basic_rss_protocol_param_<seq>` | `rss_protocol_param` | SSR protocol 参数 |
| `ssconf_basic_rss_obfs_<seq>` | `rss_obfs` | SSR obfs |
| `ssconf_basic_rss_obfs_param_<seq>` | `rss_obfs_param` | SSR obfs 参数 |

### 4.2 V2Ray

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_v2ray_use_json_<seq>` | `v2ray_use_json` | 是否使用完整 JSON |
| `ssconf_basic_v2ray_json_<seq>` | `v2ray_json` | V2Ray JSON 配置 |
| `ssconf_basic_v2ray_uuid_<seq>` | `v2ray_uuid` | UUID |
| `ssconf_basic_v2ray_alterid_<seq>` | `v2ray_alterid` | alterId |
| `ssconf_basic_v2ray_security_<seq>` | `v2ray_security` | 用户级 security |
| `ssconf_basic_v2ray_network_<seq>` | `v2ray_network` | 传输层类型 |
| `ssconf_basic_v2ray_headtype_tcp_<seq>` | `v2ray_headtype_tcp` | TCP 头类型 |
| `ssconf_basic_v2ray_headtype_kcp_<seq>` | `v2ray_headtype_kcp` | KCP 头类型 |
| `ssconf_basic_v2ray_kcp_seed_<seq>` | `v2ray_kcp_seed` | KCP seed |
| `ssconf_basic_v2ray_headtype_quic_<seq>` | `v2ray_headtype_quic` | QUIC 头类型 |
| `ssconf_basic_v2ray_grpc_mode_<seq>` | `v2ray_grpc_mode` | gRPC 模式 |
| `ssconf_basic_v2ray_network_path_<seq>` | `v2ray_network_path` | Path / ServiceName |
| `ssconf_basic_v2ray_network_host_<seq>` | `v2ray_network_host` | Host |
| `ssconf_basic_v2ray_network_security_<seq>` | `v2ray_network_security` | TLS 等安全层类型 |
| `ssconf_basic_v2ray_network_security_sni_<seq>` | `v2ray_network_security_sni` | SNI |
| `ssconf_basic_v2ray_network_security_ai_<seq>` | `v2ray_network_security_ai` | allowInsecure |
| `ssconf_basic_v2ray_network_security_alpn_h2_<seq>` | `v2ray_network_security_alpn_h2` | ALPN h2 |
| `ssconf_basic_v2ray_network_security_alpn_http_<seq>` | `v2ray_network_security_alpn_http` | ALPN http/1.1 |
| `ssconf_basic_v2ray_mux_enable_<seq>` | `v2ray_mux_enable` | Mux 开关 |
| `ssconf_basic_v2ray_mux_concurrency_<seq>` | `v2ray_mux_concurrency` | Mux 并发数 |

### 4.3 Xray / VLESS / VMess

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_xray_use_json_<seq>` | `xray_use_json` | 是否使用完整 JSON |
| `ssconf_basic_xray_json_<seq>` | `xray_json` | Xray JSON 配置 |
| `ssconf_basic_xray_uuid_<seq>` | `xray_uuid` | UUID |
| `ssconf_basic_xray_alterid_<seq>` | `xray_alterid` | alterId，主要兼容旧 VMess 配置 |
| `ssconf_basic_xray_prot_<seq>` | `xray_prot` | 协议类型，如 `vless` / `vmess` |
| `ssconf_basic_xray_encryption_<seq>` | `xray_encryption` | 加密方式 |
| `ssconf_basic_xray_flow_<seq>` | `xray_flow` | flow |
| `ssconf_basic_xray_network_<seq>` | `xray_network` | 传输层类型 |
| `ssconf_basic_xray_headtype_tcp_<seq>` | `xray_headtype_tcp` | TCP 头类型 |
| `ssconf_basic_xray_headtype_kcp_<seq>` | `xray_headtype_kcp` | KCP 头类型 |
| `ssconf_basic_xray_kcp_seed_<seq>` | `xray_kcp_seed` | KCP seed |
| `ssconf_basic_xray_headtype_quic_<seq>` | `xray_headtype_quic` | QUIC 头类型 |
| `ssconf_basic_xray_grpc_mode_<seq>` | `xray_grpc_mode` | gRPC 模式 |
| `ssconf_basic_xray_xhttp_mode_<seq>` | `xray_xhttp_mode` | XHTTP 模式 |
| `ssconf_basic_xray_network_path_<seq>` | `xray_network_path` | Path / ServiceName |
| `ssconf_basic_xray_network_host_<seq>` | `xray_network_host` | Host |
| `ssconf_basic_xray_network_security_<seq>` | `xray_network_security` | TLS / REALITY 等安全层类型 |
| `ssconf_basic_xray_network_security_sni_<seq>` | `xray_network_security_sni` | SNI |
| `ssconf_basic_xray_network_security_ai_<seq>` | `xray_network_security_ai` | allowInsecure |
| `ssconf_basic_xray_network_security_alpn_h2_<seq>` | `xray_network_security_alpn_h2` | ALPN h2 |
| `ssconf_basic_xray_network_security_alpn_http_<seq>` | `xray_network_security_alpn_http` | ALPN http/1.1 |
| `ssconf_basic_xray_pcs_<seq>` | `xray_pcs` | pinnedPeerCertSha256 |
| `ssconf_basic_xray_vcn_<seq>` | `xray_vcn` | verifyPeerCertByName |
| `ssconf_basic_xray_fingerprint_<seq>` | `xray_fingerprint` | uTLS 指纹 |
| `ssconf_basic_xray_show_<seq>` | `xray_show` | REALITY `show` |
| `ssconf_basic_xray_publickey_<seq>` | `xray_publickey` | REALITY 公钥 |
| `ssconf_basic_xray_shortid_<seq>` | `xray_shortid` | REALITY shortId |
| `ssconf_basic_xray_spiderx_<seq>` | `xray_spiderx` | REALITY spiderX |

> 说明：Shell 兼容层里仍保留 `xray_svn` 这个旧别名，但节点 JSON 内正式字段是 `xray_vcn`。

### 4.4 Trojan

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_trojan_uuid_<seq>` | `trojan_uuid` | Trojan 密码/身份字段 |
| `ssconf_basic_trojan_sni_<seq>` | `trojan_sni` | SNI |
| `ssconf_basic_trojan_ai_<seq>` | `trojan_ai` | allowInsecure |
| `ssconf_basic_trojan_tfo_<seq>` | `trojan_tfo` | TFO 开关 |
| `ssconf_basic_trojan_pcs_<seq>` | `trojan_pcs` | pinnedPeerCertSha256 |
| `ssconf_basic_trojan_vcn_<seq>` | `trojan_vcn` | verifyPeerCertByName |
| `ssconf_basic_trojan_plugin_<seq>` | `trojan_plugin` | 插件名，兼容保留 |
| `ssconf_basic_trojan_obfs_<seq>` | `trojan_obfs` | 插件 obfs，兼容保留 |
| `ssconf_basic_trojan_obfshost_<seq>` | `trojan_obfshost` | 插件 Host，兼容保留 |
| `ssconf_basic_trojan_obfsuri_<seq>` | `trojan_obfsuri` | 插件 URI，兼容保留 |

### 4.5 NaiveProxy

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_naive_prot_<seq>` | `naive_prot` | 协议类型，通常为 `https` |
| `ssconf_basic_naive_server_<seq>` | `naive_server` | 服务器地址 |
| `ssconf_basic_naive_port_<seq>` | `naive_port` | 端口 |
| `ssconf_basic_naive_user_<seq>` | `naive_user` | 用户名 |
| `ssconf_basic_naive_pass_<seq>` | `naive_pass` | 密码 |

### 4.6 TUIC

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_tuic_json_<seq>` | `tuic_json` | TUIC JSON 配置 |

### 4.7 Hysteria2

| 旧键模式 | 新字段 | 作用 |
| --- | --- | --- |
| `ssconf_basic_hy2_server_<seq>` | `hy2_server` | 服务器地址 |
| `ssconf_basic_hy2_port_<seq>` | `hy2_port` | 端口 |
| `ssconf_basic_hy2_pass_<seq>` | `hy2_pass` | 密码 |
| `ssconf_basic_hy2_up_<seq>` | `hy2_up` | 上行速率 |
| `ssconf_basic_hy2_dl_<seq>` | `hy2_dl` | 下行速率 |
| `ssconf_basic_hy2_obfs_<seq>` | `hy2_obfs` | 混淆类型 |
| `ssconf_basic_hy2_obfs_pass_<seq>` | `hy2_obfs_pass` | 混淆密码 |
| `ssconf_basic_hy2_sni_<seq>` | `hy2_sni` | SNI |
| `ssconf_basic_hy2_pcs_<seq>` | `hy2_pcs` | pinnedPeerCertSha256 |
| `ssconf_basic_hy2_vcn_<seq>` | `hy2_vcn` | verifyPeerCertByName |
| `ssconf_basic_hy2_ai_<seq>` | `hy2_ai` | allowInsecure |
| `ssconf_basic_hy2_tfo_<seq>` | `hy2_tfo` | TFO 开关 |
| `ssconf_basic_hy2_cg_<seq>` | `hy2_cg` | 拥塞控制类型 |

> 说明：Shell 兼容层里仍保留 `hy2_svn` 这个旧别名，但节点 JSON 内正式字段是 `hy2_vcn`。

---

## 5. 兼容/保留字段

这些字段当前主要用于兼容旧配置、旧订阅或旧脚本，不建议新逻辑继续扩散使用。

| 旧键模式 | 新字段 | 说明 |
| --- | --- | --- |
| `ssconf_basic_koolgame_udp_<seq>` | `koolgame_udp` | 历史兼容保留 |
| `ssconf_basic_use_kcp_<seq>` | `use_kcp` | 历史兼容保留 |
| `ssconf_basic_use_lb_<seq>` | `use_lb` | 历史兼容保留 |
| `ssconf_basic_lbmode_<seq>` | `lbmode` | 历史兼容保留 |
| `ssconf_basic_weight_<seq>` | `weight` | 历史兼容保留 |

---

## 6. 编码规则速记

### 6.1 旧结构中字段值单独 base64 的字段

| 字段 | 旧结构 | 新结构 |
| --- | --- | --- |
| `password` | 单字段值 base64 | JSON 内存原文，节点外层统一 base64 |
| `naive_pass` | 单字段值 base64 | JSON 内存原文，节点外层统一 base64 |
| `v2ray_json` | 单字段值 base64(JSON) | JSON 内存原文字符串，节点外层统一 base64 |
| `xray_json` | 单字段值 base64(JSON) | JSON 内存原文字符串，节点外层统一 base64 |
| `tuic_json` | 单字段值 base64(JSON) | JSON 内存原文字符串，节点外层统一 base64 |

### 6.2 规范化为 `0/1` 的布尔字段

```text
v2ray_use_json
v2ray_mux_enable
v2ray_network_security_ai
v2ray_network_security_alpn_h2
v2ray_network_security_alpn_http
xray_use_json
xray_network_security_ai
xray_network_security_alpn_h2
xray_network_security_alpn_http
xray_show
trojan_ai
trojan_tfo
hy2_ai
hy2_tfo
```

---

## 7. 运行态字段

以下字段可能在运行期写入，但不视为稳定节点配置：

| 旧键模式 | 新字段 | 说明 |
| --- | --- | --- |
| `ssconf_basic_server_ip_<seq>` | `server_ip` | 节点域名解析结果缓存 |
| `ssconf_basic_latency_<seq>` | `latency` | Web/连接延迟缓存 |
| `ssconf_basic_ping_<seq>` | `ping` | Ping 缓存 |

这些字段在以下场景中会被主动剔除：

- Schema 1 -> Schema 2 迁移
- 原生 JSON 备份导出
- 旧版本兼容 SH 导出

---

## 8. 最常用的 10 条映射

| 旧键 | 新键 | 说明 |
| --- | --- | --- |
| `ssconf_basic_node` | `fss_node_current` | 当前节点引用 |
| `ss_failover_s4_3` | `fss_node_failover_backup` | 备用节点引用 |
| `ssconf_basic_name_<seq>` | `fss_node_<id>.name` | 节点名称 |
| `ssconf_basic_server_<seq>` | `fss_node_<id>.server` | 服务器地址 |
| `ssconf_basic_port_<seq>` | `fss_node_<id>.port` | 端口 |
| `ssconf_basic_type_<seq>` | `fss_node_<id>.type` | 节点类型 |
| `ssconf_basic_mode_<seq>` | `fss_node_<id>.mode` | 节点模式 |
| `ssconf_basic_xray_uuid_<seq>` | `fss_node_<id>.xray_uuid` | Xray UUID |
| `ssconf_basic_tuic_json_<seq>` | `fss_node_<id>.tuic_json` | TUIC JSON 配置 |
| `ssconf_basic_hy2_server_<seq>` | `fss_node_<id>.hy2_server` | Hysteria2 服务器 |
