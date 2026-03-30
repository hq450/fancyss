# 节点分流热重载 + geosite/geoip 统一方案

## 问题总结

### 1. telegram 规则未生效的根本原因
- `fss_shunt_materialize_rule_domains` 只处理域名，忽略 IP 规则
- telegram.txt 包含 10 个域名 + 16 个 IP-CIDR
- 当前实现只生成了 `.domains` 文件，没有生成 `.ips` 文件
- xray routing 需要同时包含 `domain` 和 `ip` 字段

### 2. 规则重复问题
```
当前状态：
- geosite:cn（来自 geosite.dat）
- chnlist.txt（明文列表）
- geoip:cn（来自 geoip.dat）
- chnroute.txt（明文列表）

问题：
- 存储重复（geosite + 明文）
- 维护困难（两份数据需要同步）
- 体积浪费（~3MB geosite + ~1MB 明文）
```

### 3. 兼容性需求
```
必须支持：
1. 明文 list（现有架构）
   - iptables/ipset 需要明文 IP
   - smartdns/chinadns-ng 需要明文域名

2. geosite/geoip（新架构）
   - xray routing 支持 geosite:xxx
   - 更高效的匹配性能
```

---

## 解决方案：统一规则源 + 运行时提取

### 架构设计

```
规则源（单一真相）
  ├─ geosite-fancyss.dat（~2-3MB）
  │   ├─ cn（国内域名）
  │   ├─ gfw（被墙域名）
  │   ├─ ai, media, telegram, etc.
  │   └─ ...
  └─ geoip-fancyss.dat（~500KB）
      ├─ cn（国内 IP）
      ├─ telegram（Telegram IP）
      └─ ...
  ↓
运行时提取（按需生成明文）
  ├─ geosite-extract cn → chnlist.txt
  ├─ geosite-extract gfw → gfwlist.txt
  ├─ geoip-extract cn → chnroute.txt
  └─ geoip-extract telegram → telegram_ips.txt
  ↓
使用
  ├─ xray routing → 直接使用 geosite:cn, geoip:cn
  ├─ smartdns → 使用提取的 chnlist.txt
  ├─ chinadns-ng → 使用提取的 chnlist.txt
  └─ iptables → 使用提取的 chnroute.txt
```

---

## 核心组件：geosite-extract 工具

### 需求
- 体积小（< 100KB）
- 速度快（< 100ms）
- 功能：从 geosite.dat/geoip.dat 提取指定分类到明文

### 方案对比

#### 方案 A：使用现有工具（推荐）
**工具**：https://github.com/Loyalsoldier/geoip

```bash
# 提取 geosite
geosite -c cn -o chnlist.txt geosite-fancyss.dat

# 提取 geoip
geoip -c cn -o chnroute.txt geoip-fancyss.dat
```

**优点**：
- ✅ 官方工具，稳定可靠
- ✅ 支持多种输出格式
- ✅ 体积小（~2MB，可接受）

**缺点**：
- ⚠️ Go 编译，体积比 C 大

---

#### 方案 B：自己写 C 工具
```c
// geosite-extract.c
#include <stdio.h>
#include "geosite.pb-c.h"

int main(int argc, char *argv[]) {
    // 读取 geosite.dat
    // 查找指定 code
    // 输出域名列表
}
```

**优点**：
- ✅ 体积极小（< 50KB）
- ✅ 速度极快

**缺点**：
- ⚠️ 需要 protobuf-c 依赖
- ⚠️ 开发成本高
- ⚠️ 维护成本高

---

#### 方案 C：使用 v2ray-geodata 工具
**工具**：https://github.com/v2fly/geoip

```bash
# 提取
v2dat unpack geosite -o chnlist.txt -c cn geosite-fancyss.dat
```

**优点**：
- ✅ 官方工具
- ✅ 功能完整

**缺点**：
- ⚠️ 体积较大（~5MB）

---

### 推荐：方案 A（Loyalsoldier/geoip）

**理由**：
1. 体积可接受（~2MB）
2. 功能完整，稳定可靠
3. 社区广泛使用

**集成方式**：
```bash
# 下载工具
wget https://github.com/Loyalsoldier/geoip/releases/download/latest/geoip-linux-arm64
chmod +x geoip-linux-arm64
mv geoip-linux-arm64 /koolshare/bin/geosite-extract

# 使用
/koolshare/bin/geosite-extract -c cn -o /tmp/chnlist.txt /koolshare/ss/geosite-fancyss.dat
```

---

## 完整实现方案

### 阶段 1：修复 IP 规则解析（立即）

#### 1.1 修复 `fss_shunt_materialize_rule_domains`
```bash
fss_shunt_materialize_rule_domains() {
  local source_type="$1"
  local preset="$2"
  local custom_b64="$3"
  local domain_file="$4"
  local proxy_file="$5"
  local ip_file="${domain_file%.domains}.ips"        # 新增
  local geoip_file="${domain_file%.domains}.geoips"  # 新增

  # 现有域名解析逻辑...

  # 新增：调用 IP 解析
  if [ "${source_type}" = "builtin" ] && [ -n "${preset}" ]; then
    local tag_file="$(fss_shunt_rule_tag_file "${preset}")"
    if [ -f "${tag_file}" ]; then
      sh /koolshare/scripts/ss_parse_ip_geoip.sh "${tag_file}" "${ip_file}" "${geoip_file}"
    fi
  fi
}
```

#### 1.2 修复 xray routing 生成
```bash
fss_shunt_generate_xray_routing_rule() {
  local rule_id="$1"
  local domain_file="/tmp/fancyss_shunt/rules/${rule_id}.domains"
  local ip_file="/tmp/fancyss_shunt/rules/${rule_id}.ips"
  local geoip_file="/tmp/fancyss_shunt/rules/${rule_id}.geoips"

  # 生成 JSON
  jq -n \
    --arg tag "${tag}" \
    --arg domains "$(cat "${domain_file}" 2>/dev/null | jq -R -s -c 'split("\n") | map(select(length > 0))')" \
    --arg ips "$(cat "${ip_file}" 2>/dev/null | jq -R -s -c 'split("\n") | map(select(length > 0))')" \
    --arg geoips "$(cat "${geoip_file}" 2>/dev/null | jq -R -s -c 'split("\n") | map(select(length > 0))')" \
    '{
      type: "field",
      domain: ($domains | fromjson),
      ip: ($ips | fromjson),
      geoip: ($geoips | fromjson),
      outboundTag: $tag
    }'
}
```

**预计时间**：1-2 小时

---

### 阶段 2：构建 geosite-fancyss.dat（1-2 天）

#### 2.1 选择基础 geosite
**推荐**：geosite-all-lite.dat（2.7MB，14 分类）

**原因**：
- 体积适中
- 分类实用
- 易于扩展

#### 2.2 构建流程
```bash
#!/bin/bash
# build-geosite-fancyss.sh

# 1. 下载 geosite-all-lite
wget https://github.com/DustinWin/ruleset_geodata/releases/download/latest/geosite-all-lite.dat

# 2. 提取需要的分类
geosite-extract -c AI -o ai.txt geosite-all-lite.dat
geosite-extract -c MEDIA -o media.txt geosite-all-lite.dat
geosite-extract -c GAMES -o games.txt geosite-all-lite.dat
# ...

# 3. 替换 cn/gfw 为 fancyss 规则
cp rules_ng2/chnlist.txt cn.txt
cp rules_ng2/gfwlist.txt gfw.txt

# 4. 添加 fancyss 预设规则
cp rules_ng2/shunt/telegram.txt telegram.txt
cp rules_ng2/shunt/twitter.txt twitter.txt
# ...

# 5. 构建 geosite-fancyss.dat
geosite-builder \
  --input cn.txt:cn \
  --input gfw.txt:gfw \
  --input ai.txt:ai \
  --input media.txt:media \
  --input telegram.txt:telegram \
  --input twitter.txt:twitter \
  --output geosite-fancyss.dat
```

#### 2.3 集成到插件
```bash
# 安装到路由器
cp geosite-fancyss.dat /koolshare/ss/
cp geoip-fancyss.dat /koolshare/ss/

# 启动时提取明文列表
geosite-extract -c cn -o /tmp/chnlist.txt /koolshare/ss/geosite-fancyss.dat
geosite-extract -c gfw -o /tmp/gfwlist.txt /koolshare/ss/geosite-fancyss.dat
geoip-extract -c cn -o /tmp/chnroute.txt /koolshare/ss/geoip-fancyss.dat
```

**预计时间**：1-2 天

---

### 阶段 3：热重载实现（2-3 天）

#### 3.1 启用 xray API
```json
{
  "api": {
    "tag": "api",
    "services": ["HandlerService", "RoutingService", "StatsService"]
  },
  "policy": {
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  },
  "inbounds": [{
    "tag": "api",
    "listen": "127.0.0.1",
    "port": 10085,
    "protocol": "dokodemo-door",
    "settings": {"address": "127.0.0.1"}
  }],
  "routing": {
    "rules": [{
      "type": "field",
      "inboundTag": ["api"],
      "outboundTag": "api"
    }]
  }
}
```

#### 3.2 热重载脚本
```bash
#!/bin/sh
# fss_shunt_hot_reload.sh

fss_shunt_hot_reload() {
  echo_date "开始热重载分流规则..."

  # 1. 计算规则差异
  local old_tsv="/tmp/fancyss_shunt/active_rules.tsv"
  local new_tsv="/tmp/fancyss_shunt/new_rules.tsv"

  fss_shunt_prepare_runtime > "${new_tsv}"

  local added="$(comm -13 <(sort "${old_tsv}") <(sort "${new_tsv}"))"
  local removed="$(comm -23 <(sort "${old_tsv}") <(sort "${new_tsv}"))"

  # 2. 更新 xray
  echo_date "更新 xray routing..."
  fss_shunt_xray_hot_update "${added}" "${removed}"

  # 3. 更新 DNS
  echo_date "更新 DNS 配置..."
  fss_shunt_dns_hot_update

  # 4. 验证一致性
  fss_shunt_verify_consistency

  echo_date "热重载完成！"
}

fss_shunt_xray_hot_update() {
  local added="$1"
  local removed="$2"

  # 删除旧规则
  while IFS=$'\t' read -r rule_id node_id _ _ tag _; do
    xray api --server=127.0.0.1:10085 hs.ro "{\"tag\": \"${tag}\"}"
    xray api --server=127.0.0.1:10085 routing.removeRule "{\"inboundTag\": [\"${tag}\"]}"
  done <<< "${removed}"

  # 添加新规则
  while IFS=$'\t' read -r rule_id node_id _ _ tag _; do
    local outbound="$(fss_shunt_generate_outbound "${node_id}" "${tag}")"
    local rule="$(fss_shunt_generate_routing_rule "${rule_id}" "${tag}")"

    xray api --server=127.0.0.1:10085 hs.ao "${outbound}"
    xray api --server=127.0.0.1:10085 routing.addRule "${rule}"
  done <<< "${added}"
}

fss_shunt_dns_hot_update() {
  # 重新生成 DNS 配置
  smartdns_generate_runtime_conf /tmp/smartdns_fancyss.conf

  # 重启 smartdns
  killall smartdns
  smartdns -c /tmp/smartdns_fancyss.conf &

  # chinadns-ng 类似...
}
```

#### 3.3 前端集成
```javascript
// 前端调用
function applyShuntRules() {
  // 保存规则到 dbus
  saveShuntRulesToDbus();

  // 调用热重载
  $.ajax({
    url: '/api/shunt/reload',
    method: 'POST',
    success: function() {
      alert('规则已生效！');
    }
  });
}
```

**预计时间**：2-3 天

---

## 最终架构

```
用户修改规则（前端）
  ↓
保存到 dbus
  ↓
调用热重载 API
  ↓
fss_shunt_hot_reload()
  ├─ 1. 计算规则差异
  ├─ 2. 更新 xray（热更新，< 1 秒）
  ├─ 3. 重启 DNS（~1 秒）
  └─ 4. 验证一致性
  ↓
总耗时：~2 秒（vs 当前 ~10 秒）
```

---

## 规则存储策略

### 单一真相源
```
/koolshare/ss/
  ├─ geosite-fancyss.dat（~2-3MB）
  │   ├─ cn, gfw, ai, media, telegram, ...
  │   └─ 15-20 个分类
  └─ geoip-fancyss.dat（~500KB）
      ├─ cn, telegram, cloudflare, ...
      └─ 5-10 个分类
```

### 运行时提取
```
/tmp/
  ├─ chnlist.txt（从 geosite:cn 提取）
  ├─ gfwlist.txt（从 geosite:gfw 提取）
  ├─ chnroute.txt（从 geoip:cn 提取）
  └─ telegram_ips.txt（从 geoip:telegram 提取）
```

### 使用
```
xray routing:
  - geosite:cn, geosite:gfw, geosite:telegram
  - geoip:cn, geoip:telegram

smartdns/chinadns-ng:
  - chnlist.txt, gfwlist.txt

iptables:
  - chnroute.txt
```

---

## 实施优先级

### P0 - 立即修复（今天）
1. ✅ 修复 IP 规则解析
2. ✅ 修复 xray routing 生成
3. ✅ 测试 telegram 规则

### P1 - 核心功能（1-2 天）
1. ✅ 构建 geosite-fancyss.dat
2. ✅ 集成 geosite-extract 工具
3. ✅ 启动时提取明文列表

### P2 - 热重载（2-3 天）
1. ✅ 启用 xray API
2. ✅ 实现热重载脚本
3. ✅ 前端集成

---

## 总结

**核心思路**：
1. **单一真相源**：geosite/geoip.dat 作为唯一规则源
2. **运行时提取**：按需生成明文列表供 DNS/iptables 使用
3. **热重载**：xray API + DNS 重启，~2 秒生效

**优势**：
- ✅ 消除规则重复
- ✅ 统一维护
- ✅ 体积优化（~3MB vs ~4MB）
- ✅ 热重载支持

**是否开始实施？建议从 P0 开始。**
