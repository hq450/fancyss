# Binary for MTK platform

此文件夹下的二进制文件可以在华硕天选TX-AX6000上运行，二进制采用天选TX-AX6000编译固件的工具链：`openwrt-gcc840_musl.aarch64`编译，全部为64bit二进制。

所有二进制文件适配天选AX6000官改固件，天选AX6000采用联发科Filogic 830平台，SoC型号MT7986A，四核心A53 2.0GHz，固件linux内核版本5.4.171，为64位固件。

由于天选AX6000固件jffs空间为87.58Mb，空间有限，所以所有二进制文件均使用upx进行压缩。

```bash
chinadns-ng:     ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
dns2socks:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
dns2tcp:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
dnsclient:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
dns-ecs-forcer:  ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
dohclient:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
dohclient-cache: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
haproxy:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
haveged:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
httping:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
ipt2socks:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
isutf8:          ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
jq:              ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
kcptun:          ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
naive:           ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
obfs-local:      ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
rss-local:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
rss-redir:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
smartdns:        ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
speederv1:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
speederv2:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
sponge:          ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
sslocal:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
ss-local:        ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
ss-redir:        ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
ss-tunnel:       ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
trojan:          ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
udp2raw:         ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
uredir:          ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
v2ray:           ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
v2ray-plugin:    ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
xray:            ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, corrupted section header size
```

