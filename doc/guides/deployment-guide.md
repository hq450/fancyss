# 节点分流 IP 支持部署指南

## 部署清单

### 1. 文件部署

#### 后端脚本
```bash
# 上传到路由器
scp fancyss/scripts/ss_parse_ip_geoip.sh admin@router:/koolshare/scripts/
chmod +x /koolshare/scripts/ss_parse_ip_geoip.sh
```

#### 规则集文件
```bash
# 上传新规则集
scp rules_ng2/shunt/telegram.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/twitter.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/discord.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/openai.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/google.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/apple.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/google-cn.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/apple-cn.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/chnlist.txt admin@router:/koolshare/ss/rules_ng2/shunt/
scp rules_ng2/shunt/github.txt admin@router:/koolshare/ss/rules_ng2/shunt/
```

#### 前端资源
```bash
# 上传 manifest
scp fancyss/res/shunt_manifest.json.js admin@router:/koolshare/res/
```

### 2. 集成到构建流程

#### build.sh 修改
```bash
# 确保新文件被打包
# rules_ng2/shunt/*.txt
# scripts/ss_parse_ip_geoip.sh
# res/shunt_manifest.json.js
```

### 3. 验证部署

#### 检查文件
```bash
ssh admin@router "
  ls -lh /koolshare/scripts/ss_parse_ip_geoip.sh
  ls -lh /koolshare/ss/rules_ng2/shunt/*.txt | wc -l
  ls -lh /koolshare/res/shunt_manifest.json.js
"
```

#### 测试解析
```bash
ssh admin@router "
  cd /tmp
  sh /koolshare/scripts/ss_parse_ip_geoip.sh \
    /koolshare/ss/rules_ng2/shunt/telegram.txt \
    test.ips test.geoips
  echo 'IPs:' && wc -l test.ips
"
```

## 使用指南

### 1. 前端操作

#### 添加分流规则
1. 进入"节点分流"页面
2. 点击"添加规则"
3. 选择预设规则（如 Telegram）
4. 选择目标节点
5. 保存并应用

#### 规则优先级
- 规则按列表顺序匹配
- 上方规则优先级更高
- 可拖拽调整顺序

### 2. 规则格式

#### 支持的规则类型
```
domain:example.com          # 域名匹配
full:exact.example.com      # 完整匹配
keyword:example             # 关键词匹配
ip-cidr:1.2.3.4/24         # IP CIDR
geoip:cn                    # GeoIP 标签
```

#### 自定义规则示例
```
# 自定义 Telegram 规则
domain:telegram.org
domain:t.me
ip-cidr:91.108.4.0/22
ip-cidr:149.154.160.0/20
```

### 3. 故障排查

#### 规则不生效
```bash
# 检查规则文件
cat /tmp/fancyss_shunt/active_rules.tsv

# 检查 xray 配置
jq '.routing.rules' /koolshare/ss/xray.json

# 检查 xray 日志
tail -f /tmp/xray.log
```

#### IP 规则未加载
```bash
# 检查 IP 文件
ls -lh /tmp/fancyss_shunt/rules/*.ips

# 手动测试解析
sh /koolshare/scripts/ss_parse_ip_geoip.sh \
  /koolshare/ss/rules_ng2/shunt/telegram.txt \
  /tmp/test.ips /tmp/test.geoips
```

## 维护指南

### 1. 规则更新

#### 更新单个规则集
```bash
# 编辑规则文件
vi rules_ng2/shunt/telegram.txt

# 上传到路由器
scp rules_ng2/shunt/telegram.txt admin@router:/koolshare/ss/rules_ng2/shunt/

# 重启插件应用
ssh admin@router "sh /koolshare/scripts/ss_conf.sh restart"
```

#### 批量更新规则
```bash
# 使用 rsync 同步
rsync -avz -e "ssh -p 2223" \
  rules_ng2/shunt/ \
  admin@router:/koolshare/ss/rules_ng2/shunt/
```

### 2. 添加新规则集

#### 步骤
1. 创建规则文件：`rules_ng2/shunt/newrule.txt`
2. 更新 manifest：`fancyss/res/shunt_manifest.json.js`
3. 统计规则数量：`grep -v '^#' newrule.txt | grep -v '^$' | wc -l`
4. 上传文件到路由器
5. 重启插件

#### Manifest 格式
```javascript
{
  "id": "newrule",
  "label": "新规则",
  "description": "新规则描述",
  "file": "rules_ng2/shunt/newrule.txt",
  "count": 42
}
```

### 3. 性能监控

#### 启动耗时
```bash
# 查看启动日志
grep "shunt" /tmp/ss.log | grep "took"
```

#### 内存占用
```bash
# 查看 xray 内存
ps | grep xray | awk '{print $6}'
```

#### 规则数量
```bash
# 统计规则总数
jq '.routing.rules | length' /koolshare/ss/xray.json
```

## 最佳实践

### 1. 规则设计
- 优先使用域名规则（性能更好）
- IP 规则用于无域名场景
- GEOIP 规则用于大范围匹配

### 2. 性能优化
- 限制规则数量（建议 < 16 条）
- 避免过多 keyword 规则
- 定期清理无效规则

### 3. 安全建议
- 定期更新规则集
- 验证规则来源
- 备份配置文件

## 常见问题

### Q1: IP 规则不生效？
A: 检查 xray.json 中是否包含 "ip" 字段，确认 ss_parse_ip_geoip.sh 正确执行。

### Q2: 规则太多导致启动慢？
A: 减少规则数量，或考虑使用 geosite.dat 替代内联域名。

### Q3: 如何验证规则生效？
A: 查看 xray 日志，或使用 curl 测试目标域名的出口 IP。

### Q4: 支持正则表达式吗？
A: 当前不支持，仅支持 domain/full/keyword/ip-cidr/geoip。

## 升级路径

### 短期（已完成）
- ✅ IP-CIDR 规则支持
- ✅ GEOIP 规则格式支持
- ✅ 10 个新规则集

### 中期（待实现）
- ⏳ geoip-fancyss.dat 构建
- ⏳ 规则资产下载机制
- ⏳ 前端 UI 完善

### 长期（规划中）
- 📋 geosite-fancyss.dat 构建
- 📋 规则包自动更新
- 📋 高级匹配功能

## 参考资料
- [设计文档](../design/node-shunt-design.md)
- [MVP 文档](../implementation/node-shunt-mvp.md)
- [实施方案](../implementation/ip-support-implementation.md)
- [最终总结](../reports/ip-support-final-summary.md)
