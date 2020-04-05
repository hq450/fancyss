### Trojan 二进制存放

***

##### 此处使用的二进制文件来源于[trojan 官方项目](https://github.com/trojan-gfw/trojan) 的一个 issue: [[BUG] 32位 ARM merlin 系统上运行不了](https://github.com/trojan-gfw/trojan/issues/189#issuecomment-600031473)

> trojan.v1.14.1.arm7l.static.rar，用 tomatoware 静态编译，适用于 Asus RT-AC68U，Netgear R7000 等基于博通 arm 方案的路由器，在 Asus 原版固件，Asus merlin 以及 Tomato，DD-WRT 下测试通过。
> 
> **需要在客户端配置文件中指定 cert 的位置：**
> 
> 1. Asus Merlin
>    `"cert": "/rom/etc/ssl/certs/certificates.crt",`
> 2. Tomato
>    `"cert": "/rom/cacert.pem",`
> 
> 下载：
> https://dfile.app/QmQYXEcqgt5EsutpLNJeEsiP5TscbZuA68y6F7HKCEwjQk.rar
> 
> 版本：
> 
> > trojan: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, stripped
> > Welcome to trojan 1.14.1
> > Boost 1_71, OpenSSL 1.1.1d  10 Sep 2019
> > [Disabled] MySQL Support
> > [Enabled] TCP_FASTOPEN Support
> > [Disabled] TCP_FASTOPEN_CONNECT Support
> > [Enabled] SSL KeyLog Support
> > [Enabled] NAT Support
> > [Enabled] TLS1.3 Ciphersuites Support
> > [Disabled] TCP Port Reuse Support
> > OpenSSL Information
> > Build Flags: compiler: arm-linux-gcc -fPIC -pthread -Wa,--noexecstack -Wall -O3 -march=armv7-a -mtune=cortex-a9 -DOPENSSL_USE_NODELETE -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DAES_ASM -DBSAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DPOLY1305_ASM -DZLIB -DNDEBUG

有其他版本需求的可使用上述相关参数自行编译。

【注】没有使用压缩包中的证书，默认关闭证书。
