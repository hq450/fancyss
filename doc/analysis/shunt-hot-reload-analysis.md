# 节点分流规则热更新可行性分析

## 需求

用户编辑分流规则（新增/编辑/删除）后，通过 xray API 热更新配置，无需重启 xray 或插件。

## 技术可行性分析

### 1. xray API 能力

**当前状态**：
- xray 26.2.6 已启用 API（127.0.0.1:10085）
- 当前仅启用 `StatsService`（流量统计）

**xray API 支持的服务**：
```json
{
  "tag": "api",
  "services": [
    "HandlerService",      // ✅ 管理 inbound/outbound
    "RoutingService",      // ✅ 管理 routing 规则
    "StatsService"         // ✅ 已启用
  ]
}
```

**关键 API**：
- `HandlerService.AddOutbound()` - 添加出站
- `HandlerService.RemoveOutbound()` - 删除出站
- `HandlerService.AlterOutbound()` - 修改出站
- `RoutingService.AddRule()` - 添加路由规则
- `RoutingService.RemoveRule()` - 删除路由规则

**结论**：✅ xray API 完全支持热更新 outbound 和 routing

---

### 2. DNS 一致性问题

#### 问题描述
新增规则集合走代理时，DNS 解析应该：
1. **理想情况**：使用可信 DNS（gfw 组）解析，避免污染
2. **当前情况**：smartdns/chinadns-ng 配置是静态的，无法热更新

#### 三种方案对比

##### 方案 A：启用 xray DNS（推荐）
```json
{
  "dns": {
    "servers": [
      {
        "address": "223.5.5.5",
        "domains": ["geosite:cn"],
        "expectIPs": ["geoip:cn"]
      },
      {
        "address": "8.8.8.8",
        "domains": ["geosite:geolocation-!cn"]
      }
    ]
  }
}
```

**优点**：
- ✅ DNS 和 routing 完全一致（都在 xray 内）
- ✅ 支持热更新（通过 API 修改 DNS 规则）
- ✅ 无需重启 smartdns/chinadns-ng

**缺点**：
- ⚠️ 需要 geosite.dat（11MB，可接受）
- ⚠️ 改变现有 DNS 架构

**实现难度**：⭐⭐⭐ 中等

---

##### 方案 B：重启 smartdns（次选）
```bash
# 1. 更新 xray routing（热更新）
xray api add-outbound / add-rule

# 2. 重新生成 smartdns 配置
smartdns_generate_runtime_conf

# 3. 重启 smartdns（~1 秒）
killall smartdns
smartdns -c /tmp/smartdns_fancyss.conf
```

**优点**：
- ✅ 保持现有 DNS 架构
- ✅ 实现简单

**缺点**：
- ⚠️ 需要重启 smartdns（短暂中断）
- ⚠️ 丢失 DNS 缓存

**实现难度**：⭐⭐ 简单

---

##### 方案 C：smartdns 热重载（理想但不可行）
smartdns 不支持配置热重载，必须重启。

**结论**：❌ 不可行

---

### 3. 实现复杂度评估

#### 核心组件

##### 3.1 xray API 客户端
```bash
# 使用 xray api 命令行工具
/koolshare/bin/xray api --server=127.0.0.1:10085 \
  hs.ao '{"outbound": {...}}'  # add outbound

/koolshare/bin/xray api --server=127.0.0.1:10085 \
  routing.addRule '{"rule": {...}}'
```

**实现难度**：⭐ 简单（xray 自带工具）

---

##### 3.2 增量更新逻辑
```bash
# 伪代码
fss_shunt_hot_reload() {
  local old_rules="$(cat /tmp/fancyss_shunt/active_rules.tsv)"
  local new_rules="$(fss_shunt_prepare_runtime)"

  # 计算差异
  local added="$(diff old new | grep '^>')"
  local removed="$(diff old new | grep '^<')"
  local modified="$(diff old new | grep '^!')"

  # 应用变更
  for rule in $removed; do
    xray api hs.ro "{\"tag\": \"$tag\"}"
    xray api routing.removeRule "{\"tag\": \"$tag\"}"
  done

  for rule in $added; do
    xray api hs.ao "{\"outbound\": $(generate_outbound)}"
    xray api routing.addRule "{\"rule\": $(generate_rule)}"
  done
}
```

**实现难度**：⭐⭐⭐ 中等（需要差异计算）

---

##### 3.3 DNS 同步
```bash
# 方案 A：xray DNS
fss_shunt_update_xray_dns() {
  # 生成 DNS 配置
  local dns_config="$(fss_shunt_generate_xray_dns_config)"

  # 通过 API 更新（需要 xray 支持 DNS API）
  # 注意：xray 当前可能不支持 DNS 热更新
}

# 方案 B：重启 smartdns
fss_shunt_reload_smartdns() {
  smartdns_generate_runtime_conf /tmp/smartdns_fancyss.conf
  killall smartdns
  smartdns -c /tmp/smartdns_fancyss.conf
}
```

**实现难度**：
- 方案 A：⭐⭐⭐⭐ 困难（xray DNS API 支持未知）
- 方案 B：⭐⭐ 简单

---

### 4. 推荐方案

#### 阶段 1：最小可行方案（MVP）
**目标**：实现基本热更新，可接受短暂 DNS 中断

**实现**：
1. ✅ 启用 xray `HandlerService` 和 `RoutingService`
2. ✅ 实现 xray API 客户端封装
3. ✅ 实现增量更新逻辑（diff + apply）
4. ✅ 重启 smartdns（方案 B）

**优点**：
- 实现简单（1-2 天）
- 风险低
- 用户体验提升明显（无需重启插件）

**缺点**：
- smartdns 重启 ~1 秒中断

**实现难度**：⭐⭐⭐ 中等

---

#### 阶段 2：完美方案（可选）
**目标**：零中断热更新

**实现**：
1. ✅ 启用 xray DNS
2. ✅ 下载 geosite.dat（11MB）
3. ✅ 实现 xray DNS 配置生成
4. ✅ 通过 API 更新 DNS 规则（如果支持）

**优点**：
- 零中断
- DNS 和 routing 完全一致

**缺点**：
- 实现复杂（3-5 天）
- 增加包体积（11MB）
- 改变现有架构

**实现难度**：⭐⭐⭐⭐ 困难

---

## 实现建议

### 推荐：阶段 1（MVP）

**原因**：
1. 实现简单，风险低
2. 用户体验提升明显（无需重启插件）
3. smartdns 重启 ~1 秒，用户可接受
4. 可以后续升级到阶段 2

**实现步骤**：
1. 修改 xray.json 启用 `HandlerService` 和 `RoutingService`
2. 实现 `fss_shunt_hot_reload.sh` 脚本
3. 前端调用 `/api/shunt/reload` 接口
4. 后端执行热更新 + 重启 smartdns

**预计工作量**：1-2 天

---

## 技术风险

### 风险 1：xray API 稳定性
**风险等级**：⭐⭐ 低

xray API 是官方支持的功能，稳定性高。但需要测试：
- 大量规则更新是否稳定
- 并发更新是否安全

**缓解措施**：
- 加锁防止并发更新
- 失败时回滚到重启方案

---

### 风险 2：DNS 缓存丢失
**风险等级**：⭐⭐ 低

重启 smartdns 会丢失 DNS 缓存，导致短暂性能下降。

**缓解措施**：
- smartdns 缓存持久化（已启用）
- 重启前保存缓存，重启后恢复

---

### 风险 3：规则不一致
**风险等级**：⭐⭐⭐ 中

如果热更新失败，可能导致 xray routing 和 DNS 规则不一致。

**缓解措施**：
- 事务性更新（全部成功或全部失败）
- 失败时回滚到重启方案
- 记录更新日志

---

## 结论

**热更新分流规则是可行的，推荐实现阶段 1（MVP）方案。**

**核心要点**：
1. ✅ xray API 完全支持热更新 outbound 和 routing
2. ✅ DNS 一致性通过重启 smartdns 解决（~1 秒中断）
3. ✅ 实现难度中等（1-2 天）
4. ✅ 用户体验提升明显（无需重启插件）

**是否实现**：建议实现，性价比高。
