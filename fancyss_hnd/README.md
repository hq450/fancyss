## [fancyss_hnd](https://github.com/hq450/fancyss/tree/master/fancyss_hnd)

### fancyss_hnd 离线包下载

从2.0.0开始，插件包名从shadowsocks更名为fancyss，并同时提供full版本和lite版本，请直接下载本页面的以下文件：

- fancyss_hnd_full.tar.gz，全功能版本，安装包大
- fancyss_hnd_lite.tar.gz，精简功能版本，安装包小

如果需要其它版本的离线安装包，请前往此处：[fancyss_hnd 离线包](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd)

### lite版本和full版本区别

- lite版本是支持SS、 SSR、 V2ray、 Xray、 Trojan 五种客户端的科学上网、游戏加速工具。
- 和全功能版本相比，lite版本没有KCP加速、UDP加速、SS+v2ray-plugin、负载均衡、独立的socks5设定、koolgame协议，并且精简了一些直连解析的国外DNS解析方案。
- 更详细的区别请参考此处：[lite版本和full版本区别](https://github.com/hq450/fancyss_history_package/blob/master/fancyss_hnd/README.md#lite版本和full版本区别)。

### lite版本和full版本用哪个

- 如果是不折腾以上被精简功能的用户，完全可以使用体积更小的lite版本。
- 当然，RT-AX56U_V2这种jffs分区极小的机型，也建议直接使用lite版本。
- 如果希望用v2ray跑v2ray节点，trojan跑trojan节点，而不是用xray替代，那么用full版本。
- 如果希望有更多的直连DNS解析方案，如cdns、chinadns1、chinadns2、smartdns，用full版本。

### lite版本和full版本切换

-   要切换为lite版本，直接安装fancyss_hnd_lite.tar.gz即可，以后在线更新也维持为lite版本。

-   要切换为full版本，直接安装fancyss_hnd_full.tar.gz即可，以后在线更新也维持为full版本。


### fancyss_hnd 支持机型/固件：

| 机型/固件下载                                            | 类型   | 平台           | CPU     | 架构  | 支持版本 | 皮肤            |
| -------------------------------------------------------- | ------ | -------------- | ------- | ----- | -------- | --------------- |
| RT-AC86U                                                 | 梅林改 | hnd            | BCM4906 | ARMV8 | 全部     | asuswrt         |
| RT-AC86U                                                 | 官改   | hnd            | BCM4906 | ARMV8 | 全部     | rog/asuswrt[^1] |
| GT-AC2900                                                | 梅林改 | hnd            | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt [^2]    |
| GT-AC2900                                                | 官改   | hnd            | BCM4906 | ARMV8 | ≥ 1.9.1  | rog             |
| GT-AC5300                                                | 官改   | hnd            | BCM4908 | ARMV8 | 全部     | rog             |
| RT-AX88U                                                 | 梅林改 | axhnd          | BCM4908 | ARMV8 | 全部     | asuswrt         |
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
| RT-AX56U                                                 | 梅林改 | axhnd.675x     | BCM6755 | ARMV7 | ≥ 1.9.1  | asuswrt         |
| RT-AX68U                                                 | 官改   | p1axhnd.675x   | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| RT-AX68U                                                 | 梅林改 | p1axhnd.675x   | BCM4906 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| RT-AX86U                                                 | 官改   | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.8.3  | asuswrt         |
| RT-AX86U                                                 | 梅林改 | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| GT-AXE11000                                              | 梅林改 | p1axhnd.675x   | BCM4908 | ARMV8 | ≥ 1.9.1  | asuswrt         |
| [GT-AX6000](https://www.koolcenter.com/posts/125)        | 官改   | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | rog             |
| [GT-AX6000](https://www.koolcenter.com/posts/148)        | 梅林改 | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.8  | asuswrt         |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/133) | 官改   | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | asuswrt         |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/149) | 梅林改 | 5.04axhnd.675x | BCM4912 | ARMV8 | ≥ 1.9.6  | asuswrt         |
| [TUF-AX3000_V2](https://www.koolcenter.com/posts/161)    | 官改   | 5.04axhnd.675x | BCM6756 | ARMV7 | ≥ 1.9.8  | tuf             |

### 注意：

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

### 相关链接：

* fancyss_hnd离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd)
* fancyss_hnd更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt
* fancyss_hnd机型的固件下载地址：[https://koolcenter.com](https://koolcenter.com)