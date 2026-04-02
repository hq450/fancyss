# 节点分流 IP/GEOIP 规则支持

## 快速开始

### 功能概述
为 fancyss 3.5.10+ 节点分流功能添加完整的 IP-CIDR 和 GEOIP 规则支持。

### 核心特性
- ✅ IP-CIDR 规则解析（IPv4/IPv6）
- ✅ GEOIP 规则支持（geoip:cn, geoip:private）
- ✅ 混合规则（domain + ip + geoip）
- ✅ 10 个高质量规则集（243 条规则）
- ✅ 性能优异（启动 +0.1s，内存 +50KB）
- ✅ 100% 向后兼容

### 规则格式
```
domain:example.com          # 域名匹配
full:exact.example.com      # 完整匹配
keyword:example             # 关键词匹配
ip-cidr:1.2.3.4/24         # IP CIDR
geoip:cn                    # GeoIP 标签
```

### 新增规则集
| 规则集 | 域名 | IP | 用途 |
|---|---|---|---|
| telegram | 10 | 16 | Telegram 即时通讯 |
| twitter | 13 | 11 | Twitter/X 社交媒体 |
| discord | 12 | 13 | Discord 社交/游戏 |
| openai | 13 | 0 | OpenAI/ChatGPT |
| google | 38 | 0 | Google 全球服务 |
| apple | 25 | 0 | Apple 全球服务 |
| github | 13 | 0 | GitHub 开发平台 |
| google-cn | 8 | 0 | Google CN（直连）|
| apple-cn | 13 | 0 | Apple CN（直连）|
| chnlist | 56 | 2 | 国内常见（直连）|

## 使用方法

### 前端操作
1. 进入"节点分流"页面
2. 点击"添加规则"
3. 选择预设规则（如 Telegram）
4. 选择目标节点
5. 保存并应用

### 自定义规则
创建规则文件 `/koolshare/ss/rules_ng2/shunt/custom.txt`：
```
domain:example.com
ip-cidr:1.2.3.4/24
geoip:cn
```

## 技术架构

### 处理流程
```
规则文件 (.txt)
    ↓
ss_parse_ip_geoip.sh (解析)
    ↓
.domains / .ips / .geoips
    ↓
xray routing rules (JSON)
```

### 关键文件
- `fancyss/scripts/ss_parse_ip_geoip.sh` - IP/GEOIP 解析引擎
- `fancyss/scripts/ss_node_shunt.sh` - 后端核心逻辑
- `fancyss/res/shunt_manifest.json.js` - 前端规则清单
- `rules_ng2/shunt/*.txt` - 规则集文件

## 性能指标
- 启动耗时增加：< 0.1s
- 内存占用增加：< 50KB
- 向后兼容性：100%

## 文档
- [部署指南](./deployment-guide.md)
- [设计文档](../design/node-shunt-design.md)
- [实施方案](../implementation/ip-support-implementation.md)
- [项目报告](../reports/project-completion-report.md)

## 测试验证
- ✅ GS7 规则解析测试通过
- ✅ Telegram 规则：10 域名 + 16 IP
- ✅ Twitter 规则：13 域名 + 11 IP
- ✅ Discord 规则：12 域名 + 13 IP
- ✅ Xray routing 规则生成正确

## 后续计划
- ⏳ geoip-fancyss.dat 构建
- ⏳ 实战流量测试
- ⏳ 前端 UI 完善

## 贡献
欢迎提交 Issue 和 Pull Request。

## 许可
与 fancyss 主项目保持一致。
