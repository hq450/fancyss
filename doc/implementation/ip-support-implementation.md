# ss_node_shunt.sh IP 支持实现方案

## 修改概述

### 1. 扩展规则文件格式
当前只输出 `domain_file`，需要新增：
- `ip_file` - 存储 ip-cidr 规则
- `geoip_file` - 存储 geoip 规则

### 2. 修改 fss_shunt_materialize_rule_domains 函数

#### 当前签名
```bash
fss_shunt_materialize_rule_domains() {
    local source_type="$1"
    local preset="$2"
    local custom_b64="$3"
    local domain_file="$4"
    local proxy_file="$5"
```

#### 新增参数
```bash
fss_shunt_materialize_rule_domains() {
    local source_type="$1"
    local preset="$2"
    local custom_b64="$3"
    local domain_file="$4"
    local proxy_file="$5"
    local ip_file="$6"        # 新增
    local geoip_file="$7"     # 新增
```

#### AWK 解析逻辑扩展
```awk
function normalize(line, lower, prefix, value, token, rule_type) {
    # ... 现有逻辑 ...

    # 新增 IP-CIDR 解析
    if (lower ~ /^ip-cidr:/) {
        rule_type = "ip"
        value = substr(lower, 9)
        # 验证 IP/CIDR 格式
        if (value ~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(\/[0-9]{1,2})?$/ ||
            value ~ /^[0-9a-f:]+\/[0-9]{1,3}$/) {
            return "ip-cidr:" value "|" rule_type
        }
        return ""
    }

    # 新增 GEOIP 解析
    if (lower ~ /^geoip:/) {
        rule_type = "geoip"
        value = substr(lower, 7)
        # 验证 geoip 标签
        if (value ~ /^[a-z0-9_-]+$/) {
            return "geoip:" value "|" rule_type
        }
        return ""
    }

    # 域名规则返回
    return prefix ":" value "|domain"
}

{
    token = normalize($0)
    if (token == "" || seen[token]++) next

    # 分离 token 和 rule_type
    split(token, parts, "|")
    rule = parts[1]
    rule_type = parts[2]

    if (rule_type == "ip") {
        print substr(rule, 9) > ip_file
        ip_count++
    } else if (rule_type == "geoip") {
        print substr(rule, 7) > geoip_file
        geoip_count++
    } else {
        print rule > domain_file
        if (rule ~ /^(full|domain):/) print substr(rule, index(rule, ":") + 1) >> proxy_file
        domain_count++
    }
}

END {
    printf "%d|%d|%d\n", domain_count + 0, ip_count + 0, geoip_count + 0
}
```

### 3. 修改 fss_shunt_prepare_runtime 函数

在准备规则时创建 IP 和 GEOIP 文件：

```bash
domain_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.domains"
ip_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.ips"
geoip_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.geoips"

rm -f "${domain_file}" "${ip_file}" "${geoip_file}" >/dev/null 2>&1

count_str="$(fss_shunt_materialize_rule_domains "${source_type}" "${preset}" "${custom_b64}" \
    "${domain_file}" "${proxy_tmp}" "${ip_file}" "${geoip_file}" 2>/dev/null)"

# 解析返回的计数：domain_count|ip_count|geoip_count
domain_count="$(echo "${count_str}" | cut -d'|' -f1)"
ip_count="$(echo "${count_str}" | cut -d'|' -f2)"
geoip_count="$(echo "${count_str}" | cut -d'|' -f3)"
total_count=$((domain_count + ip_count + geoip_count))
```

### 4. 修改 fss_shunt_emit_routing_rules_json 函数

#### 当前逻辑
```bash
awk -F'|' '
{
    target = $2
    file = $3  # domain_file
    # 读取 domain_file，生成 "domain": [...]
}
' "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"
```

#### 新逻辑
```bash
awk -F'|' '
{
    rule_id = $1
    target = $2
    domain_file = $3

    # 构造 IP 和 GEOIP 文件路径
    ip_file = domain_file
    sub(/\.domains$/, ".ips", ip_file)
    geoip_file = domain_file
    sub(/\.domains$/, ".geoips", geoip_file)

    if (target == "") next

    # 读取域名规则
    has_domains = 0
    domain_json = ""
    if ((getline line < domain_file) > 0) {
        has_domains = 1
        domain_json = "\"domain\":["
        first = 1
        do {
            gsub(/\\/, "\\\\", line)
            gsub(/"/, "\\\"", line)
            if (!first) domain_json = domain_json ","
            domain_json = domain_json "\"" line "\""
            first = 0
        } while ((getline line < domain_file) > 0)
        domain_json = domain_json "]"
        close(domain_file)
    }

    # 读取 IP 规则
    has_ips = 0
    ip_json = ""
    if ((getline line < ip_file) > 0) {
        has_ips = 1
        ip_json = "\"ip\":["
        first = 1
        do {
            gsub(/\\/, "\\\\", line)
            gsub(/"/, "\\\"", line)
            if (!first) ip_json = ip_json ","
            ip_json = ip_json "\"" line "\""
            first = 0
        } while ((getline line < ip_file) > 0)
        ip_json = ip_json "]"
        close(ip_file)
    }

    # 读取 GEOIP 规则
    has_geoips = 0
    geoip_json = ""
    if ((getline line < geoip_file) > 0) {
        has_geoips = 1
        geoip_json = "\"geoip\":["
        first = 1
        do {
            gsub(/\\/, "\\\\", line)
            gsub(/"/, "\\\"", line)
            if (!first) geoip_json = geoip_json ","
            geoip_json = geoip_json "\"" line "\""
            first = 0
        } while ((getline line < geoip_file) > 0)
        geoip_json = geoip_json "]"
        close(geoip_file)
    }

    # 如果没有任何规则，跳过
    if (!has_domains && !has_ips && !has_geoips) next

    # 输出规则
    if (!first_rule) printf ",\n"
    first_rule = 0
    printf "        {\"type\":\"field\""

    # 拼接各类规则
    if (has_domains) printf ",%s", domain_json
    if (has_ips) printf ",%s", ip_json
    if (has_geoips) printf ",%s", geoip_json

    printf ",\"outboundTag\":\"proxy%s\"}", target
}
' "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"
```

## 实施步骤

1. 备份 ss_node_shunt.sh
2. 修改 fss_shunt_materialize_rule_domains 函数（405-523行）
3. 修改调用处，传入 ip_file 和 geoip_file 参数（约 608 行）
4. 修改 fss_shunt_emit_routing_rules_json 函数（714-743行）
5. 在 GS7 上测试 telegram 规则

## 测试用例

### 用例 1：纯域名规则（向后兼容）
```
规则：ai.txt（只有域名）
预期：生成 {"type":"field","domain":[...],"outboundTag":"proxy1"}
```

### 用例 2：域名 + IP 混合规则
```
规则：telegram.txt（域名 + IP）
预期：生成 {"type":"field","domain":[...],"ip":[...],"outboundTag":"proxy2"}
```

### 用例 3：域名 + GEOIP 混合规则
```
规则：chnlist.txt（域名 + geoip:cn）
预期：生成 {"type":"field","domain":[...],"geoip":["cn","private"],"outboundTag":"direct"}
```

## 性能考虑

- IP 规则内联到 xray.json，telegram 26 条规则约增加 1KB
- GEOIP 规则轻量，只是标签引用
- 解析性能：AWK 单次遍历，O(n) 复杂度
- 启动耗时增加：< 0.1s（可忽略）
