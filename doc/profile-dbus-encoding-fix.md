# Profile dbus 存储编码问题修复

## 问题描述

### 现象
前端访问 fancyss 页面时出现错误提示：
```
skipd数据读取错误，请格式化jffs分区后重新尝试！
```

### 根本原因

1. **httpdb API 的行为**
   - `/_api/ss` 接口会将所有 `ss_` 前缀的 dbus key-value 组装成一个大的 JSON 对象
   - 例如：`{"ss_basic_mode":"1", "ss_subprof_xxx":"{...}", ...}`

2. **JSON 嵌套问题**
   - 当 Profile 数据以明文 JSON 存储在 dbus 时：
     ```bash
     dbus set "ss_subprof_77a9ea57={\"version\":1,\"name\":\"test\"}"
     ```
   - httpdb 组装时会产生：
     ```json
     {
       "ss_subprof_77a9ea57": "{"version":1,"name":"test"}"
     }
     ```
   - 内层 JSON 的双引号会破坏外层 JSON 结构，导致解析失败

3. **历史解决方案**
   - fancyss 中其他复杂数据（如 `ss_online_links`、`ss_basic_custom`）都使用 base64 编码
   - 这样可以避免 JSON 嵌套问题

## 解决方案

### 1. 修改存储逻辑

在 `ss_subscribe_profile_lib.sh` 中：

**写入时进行 base64 编码**：
```bash
# 原来（错误）
dbus set "${profile_key}=${profile_json}"

# 修改后（正确）
dbus set "${profile_key}=$(printf '%s' "${profile_json}" | base64_encode)"
```

**读取时进行 base64 解码**：
```bash
# 原来（错误）
profile_json="$(dbus get "${profile_key}" 2>/dev/null)"

# 修改后（正确）
profile_json="$(dbus get "${profile_key}" 2>/dev/null | base64_decode)"
```

### 2. 修改的函数

- `subprof_write_profile_json()` - 写入 Profile 时编码
- `subprof_merge_profile_and_state()` - 读取 Profile 时解码
- `subprof_mark_state_success()` - 更新 State 时编码/解码
- `subprof_mark_state_failure()` - 更新 State 时编码/解码

### 3. 修复已存在的数据

创建了修复脚本 `ss_fix_profile_dbus_encoding.sh`：

```bash
# 修复明文 JSON 数据
sh /koolshare/scripts/ss_fix_profile_dbus_encoding.sh fix

# 验证编码是否正确
sh /koolshare/scripts/ss_fix_profile_dbus_encoding.sh verify
```

**检测逻辑**：
- 检查 dbus 值是否以 `{` 开头
- 如果是，说明是明文 JSON，需要转换为 base64
- 如果不是，说明已经是 base64 编码，跳过

### 4. 重启 httpdb 服务

修复数据后需要重启 httpdb 服务：
```bash
killall httpdb && sleep 2 && /koolshare/perp/perp.sh
```

## 修复记录

### GS7 (192.168.7.1)
- **修复时间**: 2026-04-17 13:27
- **Profile 数量**: 2 个 (77a9ea57, d4ff7151)
- **修复结果**: ✓ 成功 2 个
- **验证结果**: ✓ 编码正确

### TUF-AX3000 (192.168.89.241)
- **修复时间**: 2026-04-17 13:28
- **Profile 数量**: 1 个 (e09927e7)
- **修复结果**: ✓ 成功 1 个
- **验证结果**: ✓ 编码正确

## 技术细节

### base64 编码示例

**原始 JSON**：
```json
{"version":1,"id":"77a9ea57","name":"AmyTelecom","url":"https://..."}
```

**base64 编码后**：
```
eyJ2ZXJzaW9uIjoxLCJpZCI6Ijc3YTllYTU3IiwibmFtZSI6IkFteVRlbGVjb20iLCJ1cmwiOiJodHRwczovLy4uLiJ9
```

**httpdb 返回的 JSON**：
```json
{
  "ss_subprof_77a9ea57": "eyJ2ZXJzaW9uIjoxLCJpZCI6Ijc3YTllYTU3IiwibmFtZSI6IkFteVRlbGVjb20iLCJ1cmwiOiJodHRwczovLy4uLiJ9"
}
```

前端收到后再进行 base64 解码即可得到原始 JSON。

### 为什么不在 httpdb 中修复？

1. **httpdb 是编译好的二进制文件**，位于 ROM 中，无法修改
2. **修改存储格式更简单**，且与其他复杂数据的处理方式一致
3. **向后兼容**，修复脚本可以自动转换旧数据

## 预防措施

### 1. 代码规范

所有存储到 dbus 的复杂 JSON 数据都应该使用 base64 编码：

```bash
# ✓ 正确
dbus set "key=$(echo "$json" | base64_encode)"

# ✗ 错误
dbus set "key=$json"
```

### 2. 迁移脚本

`ss_migrate_profile_to_dbus.sh` 已更新，新迁移的数据会自动使用 base64 编码。

### 3. 测试检查

在测试时应该：
1. 检查 dbus 中的数据格式（是否为 base64）
2. 测试前端是否能正确读取和显示
3. 重启 httpdb 服务后再次验证

## 相关文件

- `fancyss/scripts/ss_subscribe_profile_lib.sh` - Profile 库函数（已修复）
- `fancyss/scripts/ss_migrate_profile_to_dbus.sh` - 迁移脚本（已修复）
- `fancyss/scripts/ss_fix_profile_dbus_encoding.sh` - 修复脚本（新增）
- `fancyss/webs/Module_shadowsocks.asp` - 前端页面

## 提交记录

- **Commit**: 9458625
- **日期**: 2026-04-17
- **标题**: fix: use base64 encoding for Profile dbus storage to avoid JSON nesting

---

**修复完成时间**: 2026-04-17 13:30
**修复人员**: Claude Code
**版本**: 3.0
