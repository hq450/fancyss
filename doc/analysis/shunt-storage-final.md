# 节点分流存储方案最终评估

## 问题重新定义

### 核心矛盾
1. **路由器空间宝贵**：工具体积必须 < 200KB
2. **xray.json 体积问题**：如果用明文，xray.json 会包含 1.8MB 规则
3. **规则重复问题**：geosite + 明文会重复存储

### 完整规则集大小
```
未压缩明文：
- chnlist.txt:      1.4 MB  (国内域名)
- gfwlist.txt:      96 KB   (被墙域名)
- chnroute.txt:     128 KB  (国内 IP)
- shunt/*.txt:      203 KB  (分流规则)
总计:               1.8 MB

压缩后:             584 KB
```

---

## 方案对比

### 方案 A：纯明文（不可行）
```
存储：
- rules.tar.gz:     584 KB
- 解压到 /tmp:     1.8 MB

xray.json：
- routing.rules:    1.8 MB (包含所有明文规则)
- 总计:             ~2 MB

问题：
❌ xray.json 体积过大
❌ xray 加载慢
❌ 内存占用高
```

---

### 方案 B：geosite.dat + 2MB Go 工具（不可行）
```
存储：
- geosite.dat:      2.5 MB
- geoip.dat:        0.5 MB
- geosite-extract:  2.0 MB
总计:               5.0 MB

xray.json：
- routing.rules:    10 KB (只有 geosite:cn 引用)

问题：
❌ 工具体积 2MB，超出预算
```

---

### 方案 C：geosite.dat + 自写 C 工具（可行但困难）
```
存储：
- geosite.dat:      2.5 MB
- geoip.dat:        0.5 MB
- geosite-extract:  50 KB (C 语言)
总计:               3.05 MB

xray.json：
- routing.rules:    10 KB

优点：
✅ xray.json 体积小
✅ 工具体积 < 200KB
✅ xray 加载快

缺点：
⚠️ 需要开发 C 工具（protobuf-c 依赖）
⚠️ 开发成本高（3-5 天）
⚠️ 维护成本高
```

---

### 方案 D：混合方案（推荐）

#### 核心思路
**分流规则用明文，核心规则用 geosite**

```
分流规则（明文）：
- ai.txt, media.txt, telegram.txt 等
- 总计: 203 KB
- 用途: xray routing 直接引用

核心规则（geosite）：
- geosite:cn (chnlist)
- geosite:gfw (gfwlist)
- geoip:cn (chnroute)
- 用途: xray routing 引用 geosite

存储：
- shunt_rules.tar.gz:   53 KB (分流规则压缩)
- geosite-lite.dat:     500 KB (只包含 cn/gfw/private)
- geoip-lite.dat:       200 KB (只包含 cn/private)
总计:                   753 KB

xray.json：
- 分流规则 (明文):      203 KB
- 核心规则 (geosite):   1 KB (geosite:cn, geoip:cn)
总计:                   204 KB
```

#### 优势
✅ **无需提取工具**（xray 原生支持 geosite）
✅ **xray.json 体积可控**（204 KB vs 2 MB）
✅ **存储空间合理**（753 KB）
✅ **维护简单**（分流规则明文可编辑）

#### 实现
```bash
# 1. 构建精简 geosite-lite.dat (只包含 cn/gfw/private)
geosite-builder \
  --input chnlist.txt:cn \
  --input gfwlist.txt:gfw \
  --input private.txt:private \
  --output geosite-lite.dat

# 2. 压缩分流规则
tar czf shunt_rules.tar.gz -C rules_ng2/shunt .

# 3. xray.json 配置
{
  "routing": {
    "rules": [
      // 分流规则（明文）
      {
        "domain": ["domain:openai.com", "domain:anthropic.com", ...],
        "ip": ["91.108.4.0/22", ...],
        "outboundTag": "proxy_ai"
      },
      // 核心规则（geosite）
      {
        "domain": ["geosite:cn"],
        "ip": ["geoip:cn"],
        "outboundTag": "direct"
      },
      {
        "domain": ["geosite:gfw"],
        "outboundTag": "proxy"
      }
    ]
  }
}
```

---

### 方案 E：完全依赖 xray 内置 geosite（最优）

#### 核心发现
**xray 已经内置了 geosite.dat 和 geoip.dat！**

检查 xray 是否内置：
```bash
xray version
# 如果支持 geosite，则已内置
```

如果 xray 内置了 geosite，我们可以：
```
存储：
- shunt_rules.tar.gz:   53 KB (分流规则)
- 无需额外 geosite.dat (xray 内置)
总计:                   53 KB

xray.json：
- 分流规则 (明文):      203 KB
- 核心规则 (内置):      1 KB
总计:                   204 KB
```

#### 验证
```bash
# 检查 xray 是否内置 geosite
xray version
ls -lh /koolshare/bin/xray
strings /koolshare/bin/xray | grep -i geosite
```

---

## 推荐方案

### 优先级 1：验证 xray 内置 geosite（方案 E）
如果 xray 内置了 geosite.dat，直接使用，无需额外存储。

**优势**：
- ✅ 存储空间最小（53 KB）
- ✅ 无需工具
- ✅ xray.json 体积可控

### 优先级 2：混合方案（方案 D）
如果 xray 未内置，使用精简 geosite-lite.dat（500 KB）。

**优势**：
- ✅ 存储空间合理（753 KB）
- ✅ 无需提取工具
- ✅ xray.json 体积可控

### 不推荐：方案 C（自写 C 工具）
除非前两个方案都不可行，否则不值得投入开发成本。

---

## 下一步

1. **验证 xray 是否内置 geosite**
2. **如果内置**：直接使用方案 E
3. **如果未内置**：使用方案 D（精简 geosite-lite）

需要我先验证 GS7 上的 xray 是否内置 geosite 吗？
