# Clash/Singbox 规则集调研报告

## 调研日期
2026-03-30

## 调研目标
分析 clash 和 singbox 用户常用的规则集分类，确定 fancyss 节点分流需要补充的规则。

## 当前 fancyss 已有规则集（14 个）

### 代理类（需走代理）
1. **AI** (145条) - OpenAI, Anthropic, Google AI 等
2. **YouTube** (180条) - YouTube 及 Google Video
3. **Netflix** (36条)
4. **Disney+** (172条)
5. **Max** (87条)
6. **Prime Video** (31条)
7. **Apple TV+** (8条)
8. **Spotify** (28条)
9. **TikTok** (54条)
10. **Games** (824条) - 游戏平台
11. **GFW 扩展** (6446条) - 被墙域名
12. **媒体合集** (1306条) - 流媒体总集

### 特殊类
13. **Bilibili** (116条) - 海外/国际化域名
14. **测速站点** (83条) - 网络测试

## Clash/Singbox 生态常见规则集分析

### 高频使用的规则集（需补充）

#### 1. 通讯社交类
- **Telegram** - 极高频，几乎所有配置都有
  - 域名：t.me, telegram.org, telegram.me 等
  - IP段：Telegram 专用 IP 段（91.108.0.0/16, 149.154.160.0/20 等）
  - **优先级：P0**

- **GitHub** - 开发者必备
  - 域名：github.com, githubusercontent.com, githubassets.com 等
  - **优先级：P0**

- **Twitter/X** - 社交媒体
  - 域名：twitter.com, x.com, twimg.com 等
  - **优先级：P1**

- **Discord** - 游戏/开发者社区
  - 域名：discord.com, discordapp.com 等
  - **优先级：P1**

#### 2. 直连类（国内服务）
- **Google-CN** - Google 中国服务
  - 域名：google.cn, google.com.hk 等
  - **优先级：P0**（补充文档已提及）

- **Apple-CN** - Apple 中国服务
  - 域名：Apple CDN 中国节点
  - **优先级：P0**（补充文档已提及）

- **ChinaList** - 国内常见域名
  - 域名：大陆主流网站
  - **优先级：P0**（补充文档已提及）

- **Microsoft-CN** - 微软中国服务
  - 域名：微软中国 CDN
  - **优先级：P1**

#### 3. 广告拦截类
- **AdBlock** - 广告域名
  - 用途：可选择 REJECT 出站
  - **优先级：P2**（可选功能）

#### 4. 隐私安全类
- **Private Tracker** - PT 站点
  - 域名：常见 PT 站
  - **优先级：P2**（小众需求）

## IP 集合需求分析

### 当前 fancyss 规则匹配
- ✅ 域名匹配：domain/full/keyword
- ❌ IP 匹配：**不支持**

### Clash/Singbox IP 规则类型
1. **IP-CIDR** - IP 段匹配（如 91.108.0.0/16）
2. **GEOIP** - 国家/地区 IP（如 geoip:cn, geoip:us）
3. **SRC-IP-CIDR** - 来源 IP 匹配（未来需求）

### 高频使用场景
1. **Telegram IP 段** - 必须用 IP 匹配，因为部分连接不走 DNS
2. **CN IP 直连** - geoip:cn 直连，避免大陆 IP 走代理
3. **局域网直连** - private IP 段直连

## 规则集格式分析

### Clash 格式
```yaml
payload:
  - DOMAIN-SUFFIX,google.com
  - DOMAIN-KEYWORD,google
  - IP-CIDR,8.8.8.8/32
  - GEOIP,CN
```

### Singbox 格式
```json
{
  "version": 1,
  "rules": [
    {
      "domain_suffix": [".google.com"],
      "domain_keyword": ["google"],
      "ip_cidr": ["8.8.8.8/32"],
      "geoip": ["cn"]
    }
  ]
}
```

### Fancyss 当前格式
```
domain:google.com
full:www.google.com
keyword:google
```

### 建议扩展格式
```
domain:google.com
full:www.google.com
keyword:google
ip-cidr:8.8.8.8/32
ip-cidr:91.108.0.0/16
geoip:cn
geoip:telegram
```

## 规则资产分发方案

### 方案对比

| 方案 | 优点 | 缺点 | 建议 |
|------|------|------|------|
| TXT 列表 | 简单，易调试 | 体积大，解析慢 | 保留作为备选 |
| geosite.dat | 体积小，加载快 | 构建复杂 | 主推方案 |
| geoip.dat | 体积小，加载快 | 构建复杂 | 主推方案 |
| tar.gz 打包 | 便于批量下发 | 解压开销 | 可选 |

### 推荐方案
**混合方案**：
1. **内置规则** → 编译为 geosite-fancyss.dat / geoip-fancyss.dat
2. **自定义规则** → 保持 TXT 格式，内联到 xray routing
3. **规则更新** → 下载预编译的 .dat 文件

## 需要新增的规则集（优先级排序）

### P0（必须）
1. ✅ **Telegram** - 域名 + IP 段
2. ✅ **GitHub** - 域名
3. ✅ **Google-CN** - 直连规则
4. ✅ **Apple-CN** - 直连规则
5. ✅ **ChinaList** - 直连规则

### P1（重要）
6. **Twitter/X** - 社交媒体
7. **Discord** - 社区平台
8. **Microsoft-CN** - 直连规则

### P2（可选）
9. **AdBlock** - 广告拦截
10. **Private Tracker** - PT 站点

## 实施建议

### 阶段 1：补充高频规则（迭代 2-3）
- 新增 telegram.txt（域名部分）
- 新增 github.txt
- 新增 google-cn.txt（直连）
- 新增 apple-cn.txt（直连）
- 新增 chnlist.txt（直连）

### 阶段 2：IP 集合支持（迭代 4-8）
- 扩展规则格式支持 ip-cidr / geoip
- 构建 geoip-fancyss.dat（包含 cn, telegram, private）
- 修改 xray routing 生成逻辑

### 阶段 3：geosite 构建（迭代 9-12）
- 构建 geosite-fancyss.dat
- 切换内置规则到 .dat 引用
- 保持自定义规则 TXT 兼容

## 参考来源
- DustinWin/domain-list-custom（当前使用）
- v2fly/domain-list-community（geosite 标准）
- Loyalsoldier/clash-rules（clash 规则集）
- MetaCubeX/meta-rules-dat（singbox 规则集）

## 下一步行动
1. 创建新规则文件（telegram/github/google-cn/apple-cn/chnlist）
2. 更新 shunt_manifest.json.js
3. 设计 IP 集合匹配方案
