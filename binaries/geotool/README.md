# geotool

`geotool` 是一个使用 Zig 编写的轻量级命令行工具，用于解析 `geosite.dat` / `dlc.dat` 这类 geosite 文件。

它的目标很明确：

- 列出 geosite 文件中的全部分类
- 导出一个或多个分类下的原始规则
- 保留规则类型前缀，而不是只导出裸域名
- 保持二进制体积尽可能小，便于后续跨平台静态编译

当前实现已经支持：

- `list` 列出全部分类
- `export` 导出单个分类
- `export` 导出多个分类
- `geoip-list` 列出 geoip 分类
- `geoip-export` 导出 geoip CIDR 规则
- 多分类合并时按完整规则去重
- 分类名大小写不敏感
- 输出保留 `domain:` / `full:` / `keyword:` / `regexp:` 前缀
- 输出保留属性，格式为 `@attr` 或 `@key=value`
- `geoip-export` 支持 `--ipv4` / `--ipv6` 过滤
- `export` 支持 `--format` 输出模式切换
- `batch-export` 支持在一个进程内完成多项 geosite / geoip 导出任务
- `stat` / `geoip-stat` 支持输出分类规则条数

## 为什么选 Zig

这个项目更适合 Zig，而不是 C，主要原因如下：

- Zig 原生支持静态编译和交叉编译，后续生成 `armv7`、`aarch64` 版本更直接
- 只依赖 Zig 标准库，不需要额外引入 protobuf 库
- 代码可以保持接近 C 的控制力，同时减少手写二进制解析时的样板代码
- 对于这个工具的目标体积，Zig 已经足够小

当前代码在 `x86_64-linux-musl + ReleaseSmall` 下生成的静态二进制约为 `38K`。

## 构建

当前版本：`1.3`

当前代码已在 Zig `0.15.2` 下验证。

构建 `x86_64` 静态版本：

```bash
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall
```

生成的二进制位于：

```bash
./zig-out/bin/geotool
```

如果要一次性输出多平台发布包，可以直接运行：

```bash
bash ./scripts/build-release.sh
```

默认会生成以下版本：

- `x86_64`
- `armv5te`
- `armv7a`
- `armv7hf`
- `aarch64`

输出目录为：

```bash
./dist
```

脚本默认行为：

- 默认不使用 UPX
- 如需压缩，再显式加 `--upx`
- 输出文件名带版本号，例如 `geotool-v1.0-linux-armv7a`

默认会启用 UPX 压缩。

关闭 UPX：

```bash
bash ./scripts/build-release.sh --no-upx
```

显式启用 UPX：

```bash
bash ./scripts/build-release.sh --upx
```

脚本默认使用：

- `/tmp/zig` 或系统中可找到的最新 Zig
- `--upx` 模式下优先读取环境变量中的 UPX 路径
- 如果没设置环境变量，则会从 `PATH` 中查找 `upx-4.2.4` 和 `upx-5.0.2`

也可以通过环境变量覆盖：

```bash
ZIG=/path/to/zig \
UPX_4_2_4=/path/to/upx-4.2.4 \
UPX_5_0_2=/path/to/upx-5.0.2 \
bash ./scripts/build-release.sh --upx
```

只构建指定目标：

```bash
bash ./scripts/build-release.sh armv7a aarch64
```

说明：

- `armv5te` 使用 `UPX 4.2.4`
- 其它目标使用 `UPX 5.0.2`
- 为了兼容构建与压缩流程，发布脚本中的各目标会使用静态 musl + `-lc` 方式构建
- `armv7a` 默认 CPU 为 `mpcorenovfp`，更适合 RT-AC88U 这类 Broadcom BCM4709 / Cortex-A9 路由器
- `armv7hf` 默认 CPU 为 `cortex_a9`，用于硬浮点 ARMv7 设备的对照测试，不建议替代 RT-AC88U 的默认选择

## 使用方法

列出全部分类：

```bash
./zig-out/bin/geotool list -i geosite.dat
```

导出单个分类：

```bash
./zig-out/bin/geotool export -i geosite.dat -c GFW
```

列出 geoip 分类：

```bash
./zig-out/bin/geotool geoip-list -i geoip.dat
```

查看 geosite 分类条数：

```bash
./zig-out/bin/geotool stat -i geosite.dat
./zig-out/bin/geotool stat -i geosite.dat -c CN,GFW
```

查看 geoip 分类条数：

```bash
./zig-out/bin/geotool geoip-stat -i geoip.dat
./zig-out/bin/geotool geoip-stat -i geoip.dat -c CN --ipv4
```

导出 geoip 分类：

```bash
./zig-out/bin/geotool geoip-export -i geoip.dat -c CN
```

只导出 geoip 中的 IPv4：

```bash
./zig-out/bin/geotool geoip-export -i geoip.dat -c CN --ipv4
```

只导出 geoip 中的 IPv6：

```bash
./zig-out/bin/geotool geoip-export -i geoip.dat -c CN --ipv6
```

导出多个分类：

```bash
./zig-out/bin/geotool export -i geosite.dat -c GFW,AI,GOOGLE
```

导出到文件：

```bash
./zig-out/bin/geotool export -i geosite.dat -c GFW,AI,GOOGLE -o rules.txt
```

导出为纯域名列表：

```bash
./zig-out/bin/geotool export -i geosite.dat -c CN,GFW --format domain
```

如果逗号后包含空格，请给整个分类列表加引号：

```bash
./zig-out/bin/geotool export -i geosite.dat -c 'GFW, AI, GOOGLE'
```

## 导出规则格式

导出的不是纯域名，而是带规则类型的明文规则。

示例：

```text
domain:google.com
full:firebase.google.com
keyword:google
regexp:^adservice\.google\.([a-z]{2}|com?)(\.[a-z]{2})?$
domain:example.com @ads
full:test.example.com @region=cn
```

说明：

- `domain:` 表示后缀域名匹配
- `full:` 表示完整域名匹配
- `keyword:` 表示关键字匹配
- `regexp:` 表示正则匹配
- `@attr` 表示布尔属性
- `@key=value` 表示带值属性

## Geosite 导出模式

`export` 默认使用 `raw` 模式，也可以通过 `--format` 切换：

- `raw`：保留 `domain:` / `full:` / `keyword:` / `regexp:` 与属性
- `domain`：只输出 `domain` / `full` 两类规则的纯域名
- `full`：只输出 `full` 规则的纯域名
- `suffix`：只输出 `domain` 规则的纯域名
- `keyword`：只输出 `keyword` 规则的值
- `regexp`：只输出 `regexp` 规则的值

其中 `domain` 模式最适合 fancyss 这类需要生成 DNS 域名列表的场景。

## GeoIP 导出格式

`geoip-export` 输出的是 CIDR 明文规则，每行一条。

示例：

```text
1.0.1.0/24
1.0.2.0/23
2001:250::/36
```

说明：

- 默认同时输出 IPv4 和 IPv6
- `--ipv4` 只输出 IPv4
- `--ipv6` 只输出 IPv6
- 多分类导出时，同样按完整规则文本去重

## 轻量统计

`stat` 和 `geoip-stat` 只输出最基础的条目数统计，格式为：

```text
CATEGORY<TAB>COUNT
```

示例：

```text
CN	128566
GFW	5939
```

`geoip-stat` 支持 `--ipv4` / `--ipv6`，可以只统计某一族地址数。

## 多分类导出规则

当 `-c` 指定多个分类时：

- 按你给出的分类顺序依次导出
- 重复分类名会自动忽略
- 分类名比较时不区分大小写
- 如果不同分类中存在完全相同的规则，只输出一次
- 去重依据是完整规则文本，不只是域名部分

例如：

```bash
./zig-out/bin/geotool export -i geosite.dat -c google,GOOGLE,github
```

这条命令里：

- `google` 和 `GOOGLE` 会被视为同一个分类
- 若 `google` 和 `github` 中有完全相同的规则，最终只保留一条

## Batch Export

`batch-export` 用于在一个进程里完成多项 geosite / geoip 导出，减少多次启动命令和重复读文件的开销。

示例：

```bash
cat > plan.txt <<'EOF'
site|raw|AI,OPENAI|ai.rules
site|domain|CN,GFW|dns_domains.txt
ip|cidr4|CN|chnroute.txt
ip|cidr6|CN|chnroute6.txt
EOF

./zig-out/bin/geotool batch-export \
  --geosite geosite.dat \
  --geoip geoip.dat \
  --plan plan.txt
```

任务文件格式：

```text
site|<format>|<category[,category...]>|<output>
ip|<cidr|cidr4|cidr6>|<category[,category...]>|<output>
```

支持：

- 空行
- `#` 注释行
- geosite 与 geoip 任务混合
- 各任务独立去重输出

## 命令行参数

```text
Usage:
  geotool list -i <geosite.dat> [-o <file>]
  geotool stat -i <geosite.dat> [-c <category[,category...]>] [-o <file>]
  geotool export -i <geosite.dat> -c <category[,category...]> [-f <raw|domain|full|suffix|keyword|regexp>] [-o <file>]
  geotool geoip-list -i <geoip.dat> [-o <file>]
  geotool geoip-stat -i <geoip.dat> [-c <category[,category...]>] [--ipv4] [--ipv6] [-o <file>]
  geotool geoip-export -i <geoip.dat> -c <category[,category...]> [--ipv4] [--ipv6] [-o <file>]
  geotool batch-export --geosite <geosite.dat> --geoip <geoip.dat> --plan <file>
```

参数说明：

- `-i, --input`：输入 geosite 文件路径
- `-c, --category`：一个或多个分类名，使用逗号分隔
- `-f, --format`：仅用于 `export`，选择 geosite 导出格式
- `-o, --output`：输出到文件，而不是标准输出
- `--geosite`：仅用于 `batch-export`，指定 geosite.dat
- `--geoip`：仅用于 `batch-export`，指定 geoip.dat
- `--plan`：仅用于 `batch-export`，指定批量任务文件
- `--ipv4`：仅用于 `geoip-export`，只导出 IPv4
- `--ipv6`：仅用于 `geoip-export`，只导出 IPv6
- `-v, --version`：显示版本号
- `-h, --help`：显示帮助

## 项目结构

```text
.
├── build.zig
├── README.md
├── DESIGN.md
└── src
    ├── geoip.zig
    ├── geosite.zig
    ├── main.zig
    └── pb.zig
```

各文件职责：

- `src/main.zig`：命令行参数解析与入口
- `src/geoip.zig`：geoip 数据解析与 CIDR 导出
- `src/geosite.zig`：geosite 数据解析、分类导出、规则去重
- `src/pb.zig`：最小 protobuf 读取器
- `build.zig`：构建脚本

## 测试

当前包含最小单元测试，覆盖：

- 分类列表解析
- 单分类导出
- 多分类合并导出
- 重复分类名去重
- 重复规则去重
- 分类不存在时返回错误
- geoip CIDR 导出
- geoip IPv4/IPv6 过滤

运行测试：

```bash
zig test src/geosite.zig -O ReleaseSmall
```

## 限制与说明

- 当前只实现 geosite / geoip 文件读取，不负责生成数据文件
- 当前错误提示较简洁，分类不存在时统一返回 `category not found`
- 多分类导出时，只要其中任意一个分类不存在，命令会失败
- 当前默认面向本地文件使用，不包含网络下载逻辑

## 后续可扩展方向

- 增加“列出某分类规则数量”的子命令
- 增加“模糊搜索分类名”的子命令
- 增加“导出全部分类到多个文件”的批处理模式
- 补充 `armv7`、`aarch64` 的构建脚本或发布流程
