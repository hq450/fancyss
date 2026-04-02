# IP 集合匹配方案设计

## 设计日期
2026-03-30

## 目标
扩展 fancyss 节点分流规则系统，支持 IP 地址和 IP 段匹配，为未来支持来源 IP 等高级匹配做好架构准备。

## 当前规则系统

### 现有格式
```
domain:example.com       # 域名后缀匹配
full:www.example.com     # 完整域名匹配
keyword:google           # 关键词匹配
```

### 现有实现位置
- 规则文件：`rules_ng2/shunt/*.txt`
- 解析逻辑：`fancyss/scripts/ss_node_shunt.sh`
- Xray 配置生成：`creat_shunt_json()` 函数

## 新增 IP 匹配类型

### 1. IP-CIDR（IP 段匹配）
```
ip-cidr:8.8.8.8/32           # 单个 IP
ip-cidr:91.108.0.0/16        # IP 段
ip-cidr:149.154.160.0/20     # Telegram IP 段
```

**用途**：
- Telegram IP 段（必须，因为部分连接不走 DNS）
- 特定服务的 IP 白名单/黑名单

### 2. GEOIP（地理位置 IP）
```
geoip:cn                     # 中国大陆 IP
geoip:us                     # 美国 IP
geoip:telegram               # Telegram 专用 IP（自定义）
geoip:private                # 私有 IP 段（192.168.0.0/16 等）
```

**用途**：
- CN IP 直连（避免大陆 IP 走代理）
- 局域网 IP 直连
- 特定国家/地区 IP 分流

### 3. SRC-IP-CIDR（来源 IP 匹配，未来扩展）
```
src-ip-cidr:192.168.1.0/24   # 来源 IP 段
```

**用途**：
- 不同设备走不同出站
- 访客网络单独分流

## Xray Routing 规则映射

### Domain 规则映射
```bash
# 当前实现
domain:example.com  →  "domain": ["example.com"]
full:www.example.com  →  "domain": ["full:www.example.com"]
keyword:google  →  "domain": ["keyword:google"]
```

### IP 规则映射（新增）
```bash
# IP-CIDR 映射
ip-cidr:8.8.8.8/32  →  "ip": ["8.8.8.8/32"]
ip-cidr:91.108.0.0/16  →  "ip": ["91.108.0.0/16"]

# GEOIP 映射
geoip:cn  →  "geoip": ["cn"]
geoip:telegram  →  "geoip": ["telegram"]  # 需要 geoip.dat 支持

# SRC-IP-CIDR 映射（未来）
src-ip-cidr:192.168.1.0/24  →  "source": ["192.168.1.0/24"]
```

### Xray Routing Rule 结构
```json
{
  "type": "field",
  "outboundTag": "proxy_ai",
  "domain": [
    "openai.com",
    "anthropic.com"
  ],
  "ip": [
    "8.8.8.8/32",
    "91.108.0.0/16"
  ],
  "geoip": [
    "telegram"
  ]
}
```

## 规则文件格式扩展

### 混合规则示例（telegram.txt）
```
# 域名规则
domain:telegram.org
domain:t.me
full:telegram.dog
keyword:telegram

# IP 规则
ip-cidr:91.108.4.0/22
ip-cidr:91.108.8.0/22
ip-cidr:91.108.12.0/22
ip-cidr:91.108.16.0/22
ip-cidr:91.108.56.0/22
ip-cidr:149.154.160.0/20
ip-cidr:149.154.164.0/22
ip-cidr:149.154.168.0/22
ip-cidr:149.154.172.0/22

# GEOIP 规则（如果有 geoip.dat）
geoip:telegram
```

### 直连规则示例（chnlist.txt）
```
# 域名规则
domain:baidu.com
domain:qq.com

# GEOIP 规则
geoip:cn
geoip:private
```

## 后端实现方案

### 方案 A：内联 IP 列表（当前可行）
**优点**：
- 实现简单，无需额外文件
- 调试方便
- 立即可用

**缺点**：
- IP 列表过长时 xray.json 体积大
- 解析性能略低

**实现**：
```bash
# ss_node_shunt.sh 中解析规则
parse_shunt_rule() {
    local rule_file="$1"
    local domains=()
    local ips=()
    local geoips=()

    while IFS= read -r line; do
        case "$line" in
            domain:*|full:*|keyword:*)
                domains+=("${line#*:}")
                ;;
            ip-cidr:*)
                ips+=("${line#ip-cidr:}")
                ;;
            geoip:*)
                geoips+=("${line#geoip:}")
                ;;
        esac
    done < "$rule_file"

    # 生成 xray routing rule
    local rule_json='{"type":"field","outboundTag":"'$outbound'"'
    [[ ${#domains[@]} -gt 0 ]] && rule_json+=', "domain":['$(printf '"%s",' "${domains[@]}" | sed 's/,$//')']'
    [[ ${#ips[@]} -gt 0 ]] && rule_json+=', "ip":['$(printf '"%s",' "${ips[@]}" | sed 's/,$//')']'
    [[ ${#geoips[@]} -gt 0 ]] && rule_json+=', "geoip":['$(printf '"%s",' "${geoips[@]}" | sed 's/,$//')']'
    rule_json+='}'
}
```

### 方案 B：geoip.dat 文件（最优方案）
**优点**：
- 体积小，加载快
- Xray 原生支持
- 性能最优

**缺点**：
- 需要构建 geoip.dat
- 更新机制复杂

**实现**：
1. 构建 `geoip-fancyss.dat`，包含：
   - `cn` - 中国大陆 IP
   - `telegram` - Telegram IP 段
   - `private` - 私有 IP 段
2. 放置到 `/koolshare/ss/rules/`
3. Xray 启动时指定：`-geoip /koolshare/ss/rules/geoip-fancyss.dat`

### 推荐方案：混合方案
- **IP-CIDR**：内联到 xray.json（方案 A）
- **GEOIP**：使用 geoip.dat（方案 B）

## geoip.dat 构建方案

### 数据源
1. **CN IP**：
   - https://github.com/Loyalsoldier/geoip（推荐）
   - https://github.com/misakaio/chnroutes2

2. **Telegram IP**：
   - 官方 API：https://core.telegram.org/resources/cidr.txt
   - 社区维护：https://github.com/Loyalsoldier/geoip/tree/release/text

3. **Private IP**：
   - RFC 1918：10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
   - RFC 4193：fc00::/7（IPv6）

### 构建工具
使用 v2ray-geoip 工具：
```bash
# 安装
go install github.com/v2fly/geoip@latest

# 构建
geoip -c config.json -o geoip-fancyss.dat
```

### 构建配置（config.json）
```json
{
  "input": [
    {
      "type": "text",
      "action": "add",
      "args": {
        "name": "cn",
        "uri": "https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/cn.txt"
      }
    },
    {
      "type": "text",
      "action": "add",
      "args": {
        "name": "telegram",
        "uri": "https://core.telegram.org/resources/cidr.txt"
      }
    },
    {
      "type": "text",
      "action": "add",
      "args": {
        "name": "private",
        "uri": "private-ip-list.txt"
      }
    }
  ],
  "output": {
    "type": "v2rayGeoIPDat",
    "action": "output"
  }
}
```

## 前端支持

### 规则编辑器扩展
```javascript
// 规则类型选择
<select id="rule_type">
  <option value="domain">域名规则</option>
  <option value="ip">IP 规则</option>
  <option value="mixed">混合规则</option>
</select>

// IP 规则输入
<textarea id="ip_rules" placeholder="每行一个 IP 或 IP 段&#10;例如：&#10;8.8.8.8/32&#10;91.108.0.0/16"></textarea>

// GEOIP 选择
<select id="geoip_select" multiple>
  <option value="cn">中国大陆 IP</option>
  <option value="telegram">Telegram IP</option>
  <option value="private">私有 IP</option>
</select>
```

### 规则预览
```javascript
// 显示规则统计
function preview_rule(rule) {
    var domainCount = rule.domains ? rule.domains.length : 0;
    var ipCount = rule.ips ? rule.ips.length : 0;
    var geoipCount = rule.geoips ? rule.geoips.length : 0;

    return `域名: ${domainCount} 条, IP: ${ipCount} 条, GeoIP: ${geoipCount} 个`;
}
```

## 性能考虑

### 启动耗时控制
1. **延迟加载**：geoip.dat 由 xray 按需加载，不影响插件启动
2. **缓存机制**：规则解析结果缓存到 `/tmp/ss_shunt_rules.cache`
3. **增量更新**：只在规则变更时重新生成 xray.json

### 内存占用
- 内联 IP 列表：约 10KB/1000 条
- geoip.dat：约 2MB（包含全球 IP）
- 推荐：单个规则 IP 条目 < 100 时内联，否则用 geoip

## 兼容性保障

### 向后兼容
- 现有纯域名规则文件无需修改
- IP 规则为可选扩展
- 不影响非 mode=7 模式

### 未来扩展
预留字段支持：
- `src-ip-cidr:` - 来源 IP
- `src-port:` - 来源端口
- `network:` - 网络类型（tcp/udp）
- `protocol:` - 协议类型（http/tls/quic）

## 实施计划

### 阶段 1：基础 IP-CIDR 支持（迭代 2-3）
- [x] 扩展规则文件格式
- [ ] 修改 ss_node_shunt.sh 解析逻辑
- [ ] 测试 telegram IP 段分流

### 阶段 2：GEOIP 支持（迭代 4-6）
- [ ] 构建 geoip-fancyss.dat
- [ ] 集成到 xray 启动流程
- [ ] 测试 CN IP 直连

### 阶段 3：前端集成（迭代 7-8）
- [ ] 规则编辑器支持 IP 输入
- [ ] 规则预览显示 IP 统计
- [ ] GS7 完整测试

## 测试用例

### 用例 1：Telegram 完整分流
```
规则文件：telegram.txt
域名：t.me, telegram.org
IP：91.108.0.0/16, 149.154.160.0/20
预期：所有 Telegram 流量走指定出站
```

### 用例 2：CN IP 直连
```
规则文件：chnlist.txt
域名：baidu.com, qq.com
GEOIP：cn
预期：国内网站和国内 IP 走直连
```

### 用例 3：混合规则
```
规则文件：custom.txt
域名：example.com
IP：1.2.3.4/32
GEOIP：us
预期：域名、IP、GEOIP 规则同时生效
```

## 参考资料
- Xray Routing 文档：https://xtls.github.io/config/routing.html
- v2ray-geoip 工具：https://github.com/v2fly/geoip
- Telegram IP 段：https://core.telegram.org/resources/cidr.txt
- Loyalsoldier/geoip：https://github.com/Loyalsoldier/geoip
