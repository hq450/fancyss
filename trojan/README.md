# trojan on fancyss test

因为trojan的呼声实在是太高，没办法只好回应一下了：fancyss插件会做trojan的集成。不过最近工作忙，所以短期内没多少时间来给插件添加trojian功能。但是我先编译好了hnd平台的trojan二进制文件，所以在fancyss插件完成trojian集成之前，你可以这么做来实现trojan的使用。

1. 首先完成trojan服务器端配置，得到以下信息

   ```bash
   # 域名：fancyss.example.com
   # 端口：443
   # 密码：fancyss
   ```

2. 下载本目录下的trojan二进制文件，放进`/koolshare/bin`，此二进制文件适用于hnd机型。

   ```bash
   # ssh运行以下命令下载trojan二进制文件
   # fancyss_arm和fancyss_arm384用户请下载trojan_armv7l后改名为trojan
   cd /koolshare/bin
   wget https://raw.githubusercontent.com/hq450/fancyss/master/trojan/trojan
   chmod +x /koolshare/bin/trojan
   ```

3. 创建trojan.json配置文件到`/koolshare/ss/trojan.json`，使用trojan官方的配置文件：[**nat.json-example**](https://github.com/trojan-gfw/trojan/blob/master/examples/nat.json-example)来进行修改。

   ```bash
   # 下载配置文件模板
   cd /koolshare/ss
   wget https://raw.githubusercontent.com/trojan-gfw/trojan/master/examples/nat.json-example trojan.json
   ```
   
4. 修改`/koolshare/ss/trojan.json`

   - **local_port** 固定为 `3333`
   - **remote_addr**改为你的**域名**，比如：`fancyss.example.com`
   - **remote_port**改为你的**端口**，比如：`443`
   - **password**修改为你的**密码**，比如：`fancyss`
   - ssl下**cert**配置改成：`"cert": "/rom/etc/ssl/certs/ca-certificates.crt"`
   
5. 启用fancyss_hnd插件ssr模式，国外DNS使用不经过服务转发的方式，比如使用`cdns`、`chinadns2`、`https_dns_proxy`、`SmartDNS`。然后进入SSH，将监听在3333端口的rss-redir进程杀掉。(v2ray模式下杀v2ray进程，ss模式下杀ss-redir进程)

   ```bash
   # 杀掉占用3333端口的进程
   killall rss-redir
   ```
   
6. 启用trojan
   
   ```bash
   # 启动trojan前台运行
   trojan
   
   # 若需后台运行，使用下面命令
   trojan >/dev/null 2>&1 &
   ```

**总结**：以上操作其实就是利用了插件现成的DNS方案，iptables配置等，用trojan来提供透明代理，而不是ss/ssr/v2ray。选用直连的国外DNS方案是因为这里直接用了trojan的nat运行方式，不同于client方式，提供的是socks5端口。如果需要使用经由服务器转发的DNS方式，那么需要杀掉ss-local，rss-local进程，然后再开一个client模式的trojan，监听在23456端口即可。



更新记录：

1. **2020年4月11日** ，trojan二进制更新为全静态编译(使用axhnd工具链)，现在RT-AC86U和TUF-AX3000机型也能正常运行

   ```bash
   # TUF-AX3000运行信息 （正常）
   admin@TUF-AX3000-5580:/jffs/.koolshare/bin# trojan -v
   Welcome to trojan 1.15.1
   Boost 1_72, OpenSSL 1.1.1f  31 Mar 2020
   [Disabled] MySQL Support
    [Enabled] TCP_FASTOPEN Support
    [Enabled] TCP_FASTOPEN_CONNECT Support
    [Enabled] SSL KeyLog Support
    [Enabled] NAT Support
    [Enabled] TLS1.3 Ciphersuites Support
    [Enabled] TCP Port Reuse Support
   OpenSSL Information
   	Build Flags: compiler: /opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/bin/arm-buildroot-linux-gnueabi-gcc -fPIC -pthread -Wa,--noexecstack -Wall -O3 -Os -DOPENSSL_USE_NODELETE -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DAES_ASM -DBSAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DPOLY1305_ASM -DZLIB -DNDEBUG -DOPENSSL_PREFER_CHACHA_OVER_GCM
   
   # RT-AC5300运行信息 （此二进制不支持armv7l）
   admin@RT-AC5300-8E70:/jffs/.koolshare/bin# trojan 
   FATAL: kernel too old
   Aborted
   ```

   

2. **2020年4月13日** ，新增arm-linux-musleabi编译的全静态版本trojan（provided by sadog），该二进制文件可以在armv7l，armv8机型上使用。比如armv7l的RT-AC5300、RT-AC88U，armv8的GT-AC5300，RT-AC86U，RT-AX88U和TUF-AX3000等机型。覆盖了fancyss支持的arm全部机型。虽然该二进制支持TCP_FASTOPEN，但是因为armv7l机型的老旧内核（2.6.36版本内核），所以fancyss_arm，fancyss_arm384机型是没法使用TCP_FASTOPEN的。大家记得在配置的时候请将配置文件内tcp部分的`"fast_open"`改为`false`

   ```bash
   admin@RT-AC5300-8E70:/tmp/home/root# trojan -v
   Welcome to trojan 1.15.1
   Boost 1_72, OpenSSL 1.1.1f  31 Mar 2020
   [Disabled] MySQL Support
    [Enabled] TCP_FASTOPEN Support
    [Enabled] TCP_FASTOPEN_CONNECT Support
    [Enabled] SSL KeyLog Support
    [Enabled] NAT Support
    [Enabled] TLS1.3 Ciphersuites Support
    [Enabled] TCP Port Reuse Support
   OpenSSL Information
   	Build Flags: compiler: /home/sadog/merlin/arm-linux-musleabi-cross/arm-linux-musleabi-cross/bin/arm-linux-musleabi-gcc -fPIC -pthread -Wa,--noexecstack -Wall -O3 -Os -march=armv7-a -fomit-frame-pointer -mabi=aapcs-linux -marm -ffixed-r8 -msoft-float -ffunction-sections -fdata-sections -DOPENSSL_USE_NODELETE -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DAES_ASM -DBSAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DPOLY1305_ASM -DZLIB -DNDEBUG -I/home/sadog/merlin/arm-linux-musleabi-cross/dists/zlib/include -DOPENSSL_NO_HEARTBEATS -DL_ENDIAN -D__ARM_ARCH_7A__ -DOPENSSL_PREFER_CHACHA_OVER_GCM
   ```

   

