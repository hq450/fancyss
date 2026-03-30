#!/bin/bash
# geoip-fancyss.dat 构建脚本
# 从 chnroute.txt 和 chnroute6.txt 生成 xray 可用的 geoip.dat

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="${SCRIPT_DIR}/../fancyss/ss/rules"
OUTPUT_DIR="${SCRIPT_DIR}/../fancyss/ss"
OUTPUT_FILE="${OUTPUT_DIR}/geoip-fancyss.dat"

# 检查依赖
if ! command -v go >/dev/null 2>&1; then
    echo "错误: 需要 Go 环境"
    exit 1
fi

# 创建临时工作目录
WORK_DIR=$(mktemp -d)
trap "rm -rf ${WORK_DIR}" EXIT

cd "${WORK_DIR}"

# 克隆 v2ray geoip 构建工具
echo "克隆 v2ray/geoip 构建工具..."
git clone --depth=1 https://github.com/v2fly/geoip.git

cd geoip

# 创建 cn.txt（合并 IPv4 和 IPv6）
echo "准备 CN IP 列表..."
cat "${RULES_DIR}/chnroute.txt" > data/cn.txt
cat "${RULES_DIR}/chnroute6.txt" >> data/cn.txt

# 创建 private.txt（RFC1918 + RFC4193）
echo "准备 Private IP 列表..."
cat > data/private.txt << 'EOF'
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
127.0.0.0/8
169.254.0.0/16
224.0.0.0/4
240.0.0.0/4
fc00::/7
fe80::/10
::1/128
EOF

# 构建
echo "构建 geoip.dat..."
go run ./ --outputdir="${OUTPUT_DIR}" --outputname=geoip-fancyss.dat

echo "完成: ${OUTPUT_FILE}"
ls -lh "${OUTPUT_FILE}"
