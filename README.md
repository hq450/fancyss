# [fancyss - 科学上网](https://hq450.github.io/fancyss/)

- Fancyss is a project providing tools to across the GFW on asuswrt/merlin based router with software center. 
- 此项目提供用于asuswrt、asuswrt-merlin为基础的，带软件中心固件路由器的科学上网。

## 插件特色

- 多客户端支持：Shadowsocks、ShadowsocksR、KoolGame、V2ray、Xray、Trojan
- shadowsocks支持SIP003插件：simple-obfs和v2ray-plugin；V2ray和Xray支持多种协议配置
- 多种模式支持：gfwlist模式、大陆白名单、游戏模式、全局模式、回国模式
- 支持SS/SSR/V2ray/Xray/Trojan节点的在线订阅，支持节点生成二维码用以分享
- 故障转移、主备切换、负载均衡、定时重启、定时订阅、规则更新、二进制更新
- 支持kcptun、udpspeeder、udp2raw，可以实现代理加速，游戏加速，应对丢包等
- ARMV8机型支持tcp fast open和ss/ssr/trojan多核心支持

## 机型/固件支持

### [fancyss_hnd](https://github.com/hq450/fancyss/tree/master/fancyss_hnd)

> **fancyss_hnd**离线安装包仅能在koolshare 梅林/官改 hnd/axhnd/axhnd.675x平台机器上使用！具体支持机型如下：

#### fancyss_hnd 支持机型/固件：

| 机型/固件下载                                            | 类型   | 平台           | CPU     | 架构  | 支持版本 | 皮肤            |
| -------------------------------------------------------- | ------ | -------------- | ------- | ----- | -------- | --------------- |
| RT-AC86U                                                 | 梅林改 | hnd            | BCM4906 | ARMV8 | 全部     | asuswrt         |
| RT-AC86U                                                 | 官改   | hnd            | BCM4906 | ARMV8 | 全部     | rog/asuswrt[^1] |
| GT-AC2900                                                | 梅林改 | hnd            | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt [^2]    |
| GT-AC2900                                                | 官改   | hnd            | BCM4906 | ARMV8 | ≥ 1.9.1  | rog             |
| GT-AC5300                                                | 官改   | hnd            | BCM4908 | ARMV8 | 全部     | rog             |
| RT-AX88U                                                 | 梅林改 | axhnd          | BCM4908 | ARMV8 | 全部     | asuswrt         |
| [RT-AX88U](https://www.koolcenter.com/posts/142)         | 官改   | axhnd          | BCM4908 | ARMV8 | 全部     | asuswrt         |
| RAX80                                                    | 梅林改 | axhnd          | BCM4908 | ARMV8 | 全部     | asuswrt         |
| GT-AX11000                                               | 官改   | axhnd          | BCM4908 | ARMV8 | 全部     | rog             |
| RT-AX92U                                                 | 官改   | axhnd          | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| TUF-AX3000                                               | 官改   | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.8.3  | tuf             |
| TUF-AX5400                                               | 梅林改 | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.9.7  | tuf             |
| TUF-AX5400                                               | 官改   | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.9.7  | tuf             |
| RT-AX58U                                                 | 梅林改 | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.8.4  | asuswrt         |
| RAX50                                                    | 梅林改 | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.8.4  | asuswrt         |
| RT-AX82U                                                 | 官改   | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.8.4  | asuswrt         |
| RT-AX82U                                                 | 梅林改 | axhnd.675x     | BCM6750 | ARMV7 | ≥ 1.9.1  | asuswrt         |
| ZenWiFi_XT8                                              | 官改   | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.8.7  | asuswrt         |
| ZenWiFi_XT8                                              | 梅林改 | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.9.1  | asuswrt         |
| ZenWiFi_XD4                                              | 官改   | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.8.8  | asuswrt         |
| RT-AX56U_V2                                              | 官改   | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.9.0  | asuswrt         |
| RT-AX1800                                                | 梅林改 | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.9.0  | asuswrt         |
| RT-AX56U                                                 | 梅林改 | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.9.1  | asuswrt         |
| RT-AX68U                                                 | 官改   | p1axhnd.675x   | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| RT-AX68U                                                 | 梅林改 | p1axhnd.675x   | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| RT-AX86U                                                 | 官改   | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.8.3  | asuswrt         |
| RT-AX86U                                                 | 梅林改 | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| GT-AXE11000                                              | 梅林改 | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| GT-AX6000                                                | 官改   | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | rog             |
| GT-AX6000                                                | 梅林改 | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.8  | asuswrt         |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/133) | 官改   | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | asuswrt         |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/149) | 梅林改 | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | asuswrt         |
| [TUF-AX3000_V2](https://www.koolcenter.com/posts/161)    | 官改   | 5.04axhnd.675x | BCM6756 | ARMV7 | ≥ 1.9.8  | tuf             |

#### 注意：

* fancyss_hnd目前仅支持以上改版固件机型，其它架构/平台固件，原版固件均不能使用fancyss_hnd！
* 相关机型的梅林改/官改固件下载请前往：[https://www.koolcenter.com/](https://www.koolcenter.com/)
* 使用fancyss_hnd科学上网插件，强烈建议使用chrome或者chrouium内核的浏览器！以保证最佳兼容性！
* 强烈建议在`最新版本的固件`和`最新版本软件中心`上使用fancyss_hnd！
* GT-AC2900/GT-AC5300/GT-AX11000/GT-AX6000官改使用ROG皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* TUF-AX3000/TUF-AX5400官改固件使用的是TUF橙色皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* TUF-AX5400梅林改版固件使用的是TUF橙色皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* 一些机型的联名版如GT-AX11000使命召唤黑色行动版/海妖版，RT-AX86U高达版/鬼灭之刃版，RT-AX82U高达版，RT-AX88U高达版本等各种联名版均是默认支持的。
* 部分机型只有达到特定版本后才能使用，386固件需要fancyss_hnd ≥ 1.9.1版本才能使用

[^1]: RT-AC86U从384_81918_koolshare固件版本开始，使用的是asuswrt风格ui，而不是rog风格。

[^2]: RT-AC86U从384_81918_koolshare固件版本开始，使用的是asuswrt风格ui，而不是rog风格。

#### 相关链接：

* fancyss_hnd离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd)
* fancyss_hnd更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt
* fancyss_hnd机型的固件下载地址：[https://koolcenter.com](https://koolcenter.com)

----

### [fancyss_qca](https://github.com/hq450/fancyss/tree/master/fancyss_qca)

> fancyss_qca适用于`koolshare 官改 qca-ipq806x`固件平台，目前仅支持华硕高通机型：RT-AX89X。

#### fancyss_qca  支持机型/固件：


| 机型/固件下载                                           | 类型 | CPU/SOC | 平台        | 架构    | 内核   | 皮肤    |
| ------------------------------------------------------- | ---- | ------- | ----------- | ------- | ------ | ------- |
| [RT-AX89X](https://koolshare.cn/thread-188090-1-1.html) | 官改 | IPQ8074 | qca-ipq806x | ARMV7/8 | 4.4.60 | asuswrt |


#### 注意：

* 其它架构/平台固件不能使用fancyss_qca！
* 使用本插件建议使用chrome或者chrome内核的浏览器！
* 强烈建议在`最新版本的固件`和`最新版本软件中心`上使用fancyss_qca！

#### 相关链接：

* fancyss_qca离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca)
* fancyss_qca更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_qca/Changelog.txt
* fancyss_qca机型的固件下载地址：[https://koolcenter.com](https://koolcenter.com)

----

### [fancyss_arm384](https://github.com/hq450/fancyss/tree/master/fancyss_arm)

> **fancyss_arm384**离线安装包仅能在koolshare 梅林 arm 384/386平台，且linux内核为2.6.36.4的armv7架构的机器上使用！

**fancyss_arm384**支持机型（需刷koolshare梅林**384/386**改版固件，如384_18、386_1）：

* 华硕系列：`RT-AC68U` `RT-AC66U-B1` `RT-AC1900P` `RT-AC87U` `RT-AC88U` `RT-AC3100` `RT-AC3200` `RT-AC5300`

#### 注意：

* 其它架构/平台固件不能使用fancyss_arm384！
* **386固件版本的机器只能使用≥ 1.0.5版本的fancyss_arm384！**
* 使用本插件建议使用chrome或者chrome内核的浏览器！
* 强烈建议在最新版本的固件和最新版本软件中心上使用fancyss_arm384！

#### 相关链接：

* arm384机型的科学上网离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm384](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm384)
* arm384机型的科学上网更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_arm384/Changelog.txt
* arm384机型的固件下载地址：[https://koolcenter.com](https://koolcenter.com)

