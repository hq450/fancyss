# 节点分流热重载完整方案 v2

## 问题重新定义

### 核心挑战
1. **规则一致性**：iptables、DNS（smartdns/chinadns-ng）、xray routing 三者必须同步
2. **DNS 缓存**：热重载后 DNS 缓存可能失效，导致解析错误
3. **双向变更**：
   - 新增代理规则（直连 → 代理）
   - 新增直连规则（代理 → 直连）
   - 删除规则
4. **iptables 同步**：ipset 需要同步更新
5. **geosite/geoip 策略**：需要 fancyss 自己的规则集

---

## 一、规则一致性架构设计

### 1.1 当前架构问题

```
用户修改规则
  ↓
重启插件（~10秒）
  ↓
├─→ iptables（ipset black_list/white_list）
├─→ smartdns（domain-set + domain-rules）
├─→ chinadns-ng（black_list.txt）
└─→ xray（routing.rules）
```

**问题**：
- ❌ 重启时间长（~10 秒）
- ❌ 连接中断
- ❌ DNS 缓存丢失

---

### 1.2 理想架构

```
用户修改规则
  ↓
计算规则差异（diff）
  ↓
├─→ xray API 热更新（outbound + routing）
├─→ iptables 增量更新（ipset add/del）
├─→ DNS 热更新（方案待定）
└─→ 验证一致性
```

**目标**：
- ✅ 秒级生效（< 2 秒）
- ✅ 连接不中断
- ✅ 规则完全一致

---

## 二、DNS 热更新方案对比

### 方案 A：重启 smartdns + chinadns-ng

#### 实现
```bash
# 1. 更新 xray（热更新）
xray api update

# 2. 重新生成配置
smartdns_generate_runtime_conf
chinadns_generate_runtime_conf

# 3. 重启 DNS
killall smartdns chinadns-ng
smartdns -c /tmp/smartdns_fancyss.conf &
chinadns-ng -c /tmp/chinadns_fancyss.conf &
```

#### 优缺点
**优点**：
- ✅ 实现简单
- ✅ 保持现有架构

**缺点**：
- ❌ DNS 中断（~1-2 秒）
- ❌ 缓存丢失（smartdns 有持久化，但 chinadns-ng 无）
- ❌ 用户体验不完美

**实现难度**：⭐⭐ 简单

---

### 方案 B：xray DNS（推荐）

#### 架构
```
用户请求
  ↓
xray DNS（内置）
  ├─→ 国内域名 → 国内 DNS（223.5.5.5）
  ├─→ 代理域名 → 国外 DNS（8.8.8.8）via proxy
  └─→ 其它 → 根据策略
  ↓
xray routing
  ├─→ 规则 1 → 节点 A
  ├─→ 规则 2 → 节点 B
  └─→ 兜底 → 节点 C
```

#### 配置示例
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
      },
      {
        "address": "8.8.8.8",
        "domains": ["geosite:ai", "geosite:media"],
        "skipFallback": true
      }
    ],
    "queryStrategy": "UseIPv4"  // 国内优先
  }
}
```

#### 三种 DNS 策略映射
```bash
# 1. 国内优先（UseIPv4）
queryStrategy: "UseIPv4"

# 2. 国外优先（UseIPv6）
queryStrategy: "UseIPv6"

# 3. 智能判断（UseIP）
queryStrategy: "UseIP"
```

#### 优缺点
**优点**：
- ✅ 零中断热更新
- ✅ DNS 和 routing 完全一致（都在 xray 内）
- ✅ 支持 DNS 分流策略
- ✅ 无缓存丢失问题

**缺点**：
- ⚠️ 需要 geosite.dat（方案见下文）
- ⚠️ 改变现有架构（smartdns/chinadns-ng 可选）
- ⚠️ 非 mode 7 仍需 smartdns/chinadns-ng

**实现难度**：⭐⭐⭐⭐ 困难

---

### 方案 C：混合方案

#### 架构
```
mode 7（节点分流）：
  用户请求 → xray DNS → xray routing

mode 1-6（非分流）：
  用户请求 → smartdns/chinadns-ng → xray
```

#### 优缺点
**优点**：
- ✅ mode 7 零中断热更新
- ✅ mode 1-6 保持现有架构
- ✅ 最佳用户体验

**缺点**：
- ⚠️ 双 DNS 架构，复杂度高

**实现难度**：⭐⭐⭐⭐⭐ 非常困难

---

## 三、geosite/geoip 策略

### 3.1 问题分析

#### 官方 geosite 问题
- **geosite-xray**（11MB，1430 分类）：太大，分类过多
- **geosite-all-lite**（2.7MB，14 分类）：太少，无法精细分流

#### fancyss 需求
```
必需分类（核心）：
- cn（国内域名）- 对应 chnlist
- gfw（被墙域名）- 对应 gfwlist
- private（私有域名）

分流分类（用户常用）：
- ai（AI 服务）
- media（流媒体）
- google（Google 服务）
- apple（Apple 服务）
- microsoft（Microsoft 服务）
- github（开发工具）
- telegram（即时通讯）
- twitter（社交媒体）
- discord（社交媒体）
- games（游戏）
- networktest（网络测试）

直连分类（优化）：
- google-cn（Google 中国）
- apple-cn（Apple 中国）
- microsoft-cn（Microsoft 中国）
```

**总计**：~15-20 个分类

---

### 3.2 geosite-fancyss.dat 构建方案

#### 方案 A：基于 geosite-all-lite 精简（推荐）

**步骤**：
```bash
# 1. 下载 geosite-all-lite.dat
wget https://github.com/DustinWin/ruleset_geodata/releases/download/latest/geosite-all-lite.dat

# 2. 提取需要的分类
geoview -type geosite -input geosite-all-lite.dat -code AI > ai.txt
geoview -type geosite -input geosite-all-lite.dat -code MEDIA > media.txt
...

# 3. 替换 cn/gfw 为 fancyss 自己的
cat rules_ng2/chnlist.txt > cn.txt
cat rules_ng2/gfwlist.txt > gfw.txt

# 4. 构建 geosite-fancyss.dat
geosite-builder \
  --input cn.txt:cn \
  --input gfw.txt:gfw \
  --input ai.txt:ai \
  --input media.txt:media \
  --output geosite-fancyss.dat
```

**优点**：
- ✅ 文件小（~2-3MB）
- ✅ 分类适中（15-20 个）
- ✅ 兼容 fancyss 现有规则

**实现难度**：⭐⭐⭐ 中等

---

#### 方案 B：基于 domain-list-custom（理想）

**参考**：https://github.com/DustinWin/domain-list-custom/tree/domains

**步骤**：
```bash
# 1. 克隆仓库
git clone https://github.com/DustinWin/domain-list-custom

# 2. 替换 cn/gfw
cp rules_ng2/chnlist.txt domain-list-custom/cn
cp rules_ng2/gfwlist.txt domain-list-custom/gfw

# 3. 构建
cd domain-list-custom
go run ./ --datapath=./data --outputdir=./output

# 4. 生成 geosite-fancyss.dat
```

**优点**：
- ✅ 完全自定义
- ✅ 可持续维护
- ✅ 分类精细

**缺点**：
- ⚠️ 需要 Go 环境
- ⚠️ 维护成本高

**实现难度**：⭐⭐⭐⭐ 困难

---

### 3.3 geoip-fancyss.dat 构建方案

#### 需求
```
必需分类：
- cn（中国 IP）- 对应 chnroute
- private（私有 IP）

可选分类：
- telegram（Telegram IP）
- cloudflare（Cloudflare IP）
```

#### 实现
```bash
# 1. 使用现有 chnroute
cat rules_ng2/chnroute.txt > cn.txt

# 2. 添加 Telegram IP（从预设规则提取）
grep 'ip-cidr:' rules_ng2/shunt/telegram.txt | sed 's/ip-cidr://' > telegram.txt

# 3. 构建 geoip-fancyss.dat
geoip-builder \
  --input cn.txt:cn \
  --input telegram.txt:telegram \
  --output geoip-fancyss.dat
```

**文件大小**：~500KB

---

## 四、完整热重载方案

### 4.1 架构设计

```
用户修改规则
  ↓
fss_shunt_hot_reload()
  ↓
1. 计算规则差异
  ├─ 新增代理规则（added_proxy）
  ├─ 新增直连规则（added_direct）
  ├─ 删除规则（removed）
  └─ 修改规则（modified）
  ↓
2. 更新 xray（热更新）
  ├─ 删除旧 outbound/routing
  ├─ 添加新 outbound/routing
  └─ 验证配置
  ↓
3. 更新 iptables（增量）
  ├─ ipset add black_list（新增代理域名）
  ├─ ipset del black_list（删除代理域名）
  ├─ ipset add white_list（新增直连域名）
  └─ ipset del white_list（删除直连域名）
  ↓
4. 更新 DNS
  ├─ mode 7 + xray DNS：无需操作（已在 xray 内）
  └─ mode 7 + smartdns：重启 smartdns/chinadns-ng
  ↓
5. 验证一致性
  ├─ 检查 xray routing 规则数
  ├─ 检查 ipset 条目数
  └─ 检查 DNS 配置
```

---

### 4.2 关键实现

#### 4.2.1 规则差异计算
```bash
fss_shunt_diff_rules() {
  local old_tsv="/tmp/fancyss_shunt/active_rules.tsv"
  local new_tsv="/tmp/fancyss_shunt/new_rules.tsv"

  # 生成新规则
  fss_shunt_prepare_runtime > "${new_tsv}"

  # 计算差异
  local added="$(comm -13 <(sort "${old_tsv}") <(sort "${new_tsv}"))"
  local removed="$(comm -23 <(sort "${old_tsv}") <(sort "${new_tsv}"))"

  # 分类：代理 vs 直连
  local added_proxy="$(echo "${added}" | awk -F'\t' '$5 != "direct"')"
  local added_direct="$(echo "${added}" | awk -F'\t' '$5 == "direct"')"
  local removed_proxy="$(echo "${removed}" | awk -F'\t' '$5 != "direct"')"
  local removed_direct="$(echo "${removed}" | awk -F'\t' '$5 == "direct"')"

  # 输出
  echo "added_proxy=${added_proxy}"
  echo "added_direct=${added_direct}"
  echo "removed_proxy=${removed_proxy}"
  echo "removed_direct=${removed_direct}"
}
```

---

#### 4.2.2 xray 热更新
```bash
fss_shunt_xray_hot_update() {
  local added_proxy="$1"
  local removed_proxy="$2"

  # 删除旧规则
  while IFS=$'\t' read -r rule_id _ _ _ tag _; do
    xray api --server=127.0.0.1:10085 hs.ro "{\"tag\": \"${tag}\"}"
    xray api --server=127.0.0.1:10085 routing.removeRule "{\"inboundTag\": [\"${tag}\"]}"
  done <<< "${removed_proxy}"

  # 添加新规则
  while IFS=$'\t' read -r rule_id _ _ _ tag node_id; do
    local outbound="$(fss_shunt_generate_outbound "${node_id}" "${tag}")"
    local rule="$(fss_shunt_generate_routing_rule "${rule_id}" "${tag}")"

    xray api --server=127.0.0.1:10085 hs.ao "${outbound}"
    xray api --server=127.0.0.1:10085 routing.addRule "${rule}"
  done <<< "${added_proxy}"
}
```

---

#### 4.2.3 iptables 增量更新
```bash
fss_shunt_iptables_hot_update() {
  local added_proxy="$1"
  local added_direct="$2"
  local removed_proxy="$3"
  local removed_direct="$4"

  # 新增代理域名 → black_list
  while IFS=$'\t' read -r rule_id _ _ _ _ _; do
    local domains="$(cat /tmp/fancyss_shunt/rules/${rule_id}.domains)"
    while read -r domain; do
      # 注意：ipset 只能存 IP，域名需要通过 dnsmasq/smartdns 解析后加入
      # 这里只是示意，实际需要配合 DNS
      echo "server=/${domain}/127.0.0.1#7913" >> /tmp/dnsmasq_black.conf
    done <<< "${domains}"
  done <<< "${added_proxy}"

  # 删除代理域名 → 从 black_list 移除
  # 类似逻辑...

  # 重启 dnsmasq 应用配置
  service restart_dnsmasq
}
```

**问题**：iptables/ipset 依赖 DNS 解析，无法直接热更新域名规则。

**解决方案**：
- 方案 1：使用 xray DNS，iptables 只做入口引流（推荐）
- 方案 2：重启 dnsmasq/smartdns 应用新配置

---

#### 4.2.4 DNS 热更新
```bash
fss_shunt_dns_hot_update() {
  local use_xray_dns="$(dbus get ss_basic_shunt_use_xray_dns)"

  if [ "${use_xray_dns}" = "1" ]; then
    # xray DNS：无需操作，规则已在 xray 内
    echo_date "使用 xray DNS，无需更新外部 DNS"
  else
    # smartdns/chinadns-ng：重启
    echo_date "重启 smartdns 和 chinadns-ng"
    smartdns_generate_runtime_conf /tmp/smartdns_fancyss.conf
    killall smartdns
    smartdns -c /tmp/smartdns_fancyss.conf &

    # chinadns-ng 类似...
  fi
}
```

---

### 4.3 一致性验证
```bash
fss_shunt_verify_consistency() {
  # 1. 检查 xray routing 规则数
  local xray_rules="$(xray api --server=127.0.0.1:10085 routing.testRoute | jq '.rules | length')"

  # 2. 检查 ipset 条目数
  local ipset_black="$(ipset list black_list | grep -c '^[0-9]')"

  # 3. 检查 DNS 配置
  local dns_domains="$(grep -c 'domain-set' /tmp/smartdns_fancyss.conf)"

  echo_date "一致性检查："
  echo_date "  xray routing 规则数: ${xray_rules}"
  echo_date "  ipset black_list 条目数: ${ipset_black}"
  echo_date "  smartdns domain-set 数: ${dns_domains}"
}
```

---

## 五、实施路线图

### 阶段 1：基础热重载（1-2 天）
**目标**：实现 xray 热更新 + 重启 DNS

**任务**：
1. ✅ 启用 xray `HandlerService` 和 `RoutingService`
2. ✅ 实现规则差异计算
3. ✅ 实现 xray API 封装
4. ✅ 实现 DNS 重启逻辑
5. ✅ 前端调用接口

**交付**：
- 热更新生效时间：~2 秒（xray 热更新 + DNS 重启）
- 连接不中断（xray 不重启）

---

### 阶段 2：构建 geosite-fancyss（2-3 天）
**目标**：生成 fancyss 专用 geosite.dat

**任务**：
1. ✅ 基于 geosite-all-lite 提取分类
2. ✅ 替换 cn/gfw 为 fancyss 规则
3. ✅ 添加 fancyss 预设规则（ai/media/telegram 等）
4. ✅ 构建 geosite-fancyss.dat（~2-3MB）
5. ✅ 集成到插件包

**交付**：
- geosite-fancyss.dat（15-20 分类）
- 自动化构建脚本

---

### 阶段 3：xray DNS 集成（3-5 天）
**目标**：mode 7 使用 xray DNS，实现零中断热更新

**任务**：
1. ✅ 实现 xray DNS 配置生成
2. ✅ 支持三种 DNS 策略（国内优先/国外优先/智能判断）
3. ✅ mode 7 自动切换到 xray DNS
4. ✅ mode 1-6 保持 smartdns/chinadns-ng
5. ✅ 热更新时无需重启 DNS

**交付**：
- 热更新生效时间：< 1 秒（纯 xray API）
- 零中断，零缓存丢失

---

### 阶段 4：iptables 优化（可选，1-2 天）
**目标**：iptables 增量更新

**任务**：
1. ✅ 分析 iptables 热更新可行性
2. ✅ 实现 ipset 增量更新
3. ✅ 验证一致性

**交付**：
- iptables 规则与 xray routing 完全同步

---

## 六、推荐方案

### 最小可行方案（MVP）
**实施**：阶段 1 + 阶段 2

**理由**：
1. 快速交付（3-5 天）
2. 用户体验显著提升（~2 秒 vs ~10 秒）
3. 为阶段 3 打好基础

**缺点**：
- DNS 仍需重启（~1 秒中断）

---

### 完美方案
**实施**：阶段 1 + 阶段 2 + 阶段 3

**理由**：
1. 零中断热更新
2. 规则完全一致
3. 架构清晰

**缺点**：
- 开发周期长（6-10 天）
- 架构变更大

---

## 七、技术风险

### 风险 1：xray API 稳定性
**等级**：⭐⭐ 低

**缓解**：
- 失败时回滚到重启方案
- 加锁防止并发更新

---

### 风险 2：DNS 缓存失效
**等级**：⭐⭐⭐ 中（阶段 1）/ ⭐ 低（阶段 3）

**缓解**：
- 阶段 1：smartdns 缓存持久化
- 阶段 3：使用 xray DNS，无缓存丢失

---

### 风险 3：规则不一致
**等级**：⭐⭐⭐ 中

**缓解**：
- 事务性更新（全部成功或全部失败）
- 一致性验证
- 失败时回滚

---

### 风险 4：geosite 维护成本
**等级**：⭐⭐⭐ 中

**缓解**：
- 自动化构建脚本
- 定期同步上游规则
- 社区贡献

---

## 八、结论

### 推荐实施方案

**阶段 1 + 阶段 2（MVP）**

**理由**：
1. ✅ 性价比高（3-5 天，显著提升用户体验）
2. ✅ 技术风险低
3. ✅ 为完美方案打基础
4. ✅ geosite-fancyss 是长期资产

**后续**：
- 根据用户反馈决定是否实施阶段 3
- 如果 DNS 重启（~1 秒）可接受，可以不做阶段 3

---

### 关键决策点

1. **是否构建 geosite-fancyss？**
   - ✅ 是，这是核心资产，必须做

2. **是否使用 xray DNS？**
   - ⚠️ 可选，取决于用户对 DNS 中断的容忍度

3. **iptables 是否热更新？**
   - ⚠️ 可选，mode 7 主要依赖 xray routing

---

**是否开始实施？建议从阶段 1 + 阶段 2 开始。**
