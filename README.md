# [fancyss - 科学上网](https://hq450.github.io/fancyss/)

- Fancyss is a project providing tools to across the GFW on asuswrt/merlin based router with software center. 
- 此项目提供用于asuswrt、asuswrt-merlin为基础的，带软件中心固件（≥384）路由器的科学上网功能。

## 插件特色

- 多客户端支持：Shadowsocks、ShadowsocksR、KoolGame、V2ray、Xray、Trojan
- shadowsocks支持SIP003插件：simple-obfs和v2ray-plugin；V2ray和Xray支持多种协议配置
- 多种模式支持：gfwlist模式、大陆白名单、游戏模式、全局模式、回国模式
- 支持SS/SSR/V2ray/Xray/Trojan节点的在线订阅，支持节点生成二维码用以分享
- 故障转移、主备切换、负载均衡、定时重启、定时订阅、规则更新、二进制更新
- 支持kcptun、udpspeeder、udp2raw，可以实现代理加速，游戏加速，应对丢包等
- armv8机型支持tcp fast open和ss/ssr/trojan多核心运行

## 支持机型/固件

> 以下为fancyss 3.0支持的机型/固件，点击机型可以前往相应固件下载地址

| 机型/固件下载                                                | 类型 | 平台           | CPU       | 架构  | linux内核 | 插件皮肤    | fancyss版本 |
| ------------------------------------------------------------ | ---- | -------------- | --------- | ----- | --------- | ----------- | --------------- |
| [R6300V2](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/Netgear/R6300v2/) | 梅改 | 6.x.4708       | BCM4708   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC68U](https://www.koolcenter.com/posts/38) | 梅改 | 6.x.4708       | BCM4708   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC88U](https://www.koolcenter.com/posts/39) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC3100](https://www.koolcenter.com/posts/40) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC5300](https://www.koolcenter.com/posts/41) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC86U](https://www.koolcenter.com/posts/36) | 梅改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt     | fancyss_hnd     |
| [RT-AC86U](https://www.koolcenter.com/posts/139)             | 官改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt[^1] | fancyss_hnd     |
| [GT-AC2900](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/GT-AC2900/) | 梅改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt     | fancyss_hnd     |
| [GT-AC2900](https://www.koolcenter.com/posts/37) | 官改 | hnd            | BCM4906   | armv8 | 4.1.27    | rog         | fancyss_hnd     |
| [GT-AC5300](https://www.koolcenter.com/posts/12)             | 官改 | hnd            | BCM4908   | armv8 | 4.1.27    | rog         | fancyss_hnd     |
| [RT-AX88U](https://www.koolcenter.com/posts/34) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [RT-AX88U](https://www.koolcenter.com/posts/142)             | 官改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [RAX80](https://www.koolcenter.com/posts/43) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [GT-AX11000](https://www.koolcenter.com/posts/140)           | 官改 | axhnd          | BCM4908   | armv8 | 4.1.51    | rog         | fancyss_hnd     |
| [GT-AX11000](https://www.koolcenter.com/posts/35) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [RT-AX92U](https://www.koolcenter.com/posts/20)              | 官改 | axhnd          | BCM4906   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [TUF-AX3000](https://www.koolcenter.com/posts/11)            | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| [TUF-AX5400](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| [TUF-AX5400](https://www.koolcenter.com/posts/141)           | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| [RT-AX58U](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RAX50](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX82U](https://www.koolcenter.com/posts/18)              | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX82U](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [ZenWiFi_XT8](https://www.koolcenter.com/posts/137)          | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [ZenWiFi_XT8](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [ZenWiFi_XD4](https://www.koolcenter.com/posts/21)           | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX56U_V2](https://www.koolcenter.com/posts/16)           | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX1800](https://www.koolcenter.com/posts/16)             | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX56U](https://www.koolcenter.com/posts/130)             | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RAX70](https://www.koolcenter.com/posts/130) | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX68U](https://www.koolcenter.com/posts/136)             | 官改 | p1axhnd.675x   | BCM4906   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX68U](https://www.koolcenter.com/posts/33) | 梅改 | p1axhnd.675x   | BCM4906   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX86U](https://www.koolcenter.com/posts/135)             | 官改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX86U](https://www.koolcenter.com/posts/5) | 梅改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [GT-AXE11000](https://www.koolcenter.com/posts/130) | 梅改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [GT-AX6000](https://www.koolcenter.com/posts/125)            | 官改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | rog         | fancyss_hnd     |
| [GT-AX6000](https://www.koolcenter.com/posts/148) | 梅改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/133)     | 官改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/149)     | 梅改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [TUF-AX3000_V2](https://www.koolcenter.com/posts/161)        | 官改 | 5.04axhnd.675x | BCM6756   | armv7 | 4.19.183  | tuf         | fancyss_hnd     |
| [RT-AX89X](https://www.koolcenter.com/posts/126) | 官改 | qca-ipq806x    | ipq8074/a | armv7 | 4.4.60    | asuswrt     | fancyss_qca     |

## 版本选择

fancyss 3.0支持hnd、qca、arm三个平台，每个平台又有full版本和lite版本

full版本为全功能版本，支持SS、 SSR、KoolGame、V2ray、 Xray、 Trojan 六种客户端，安装包体积较大

lite版本为精简版本，支持SS、 SSR、 V2ray、 Xray、 Trojan 五种客户端，安装包小巧，以下为lite版本精简内容：

1. lite版本移除了v2ray、trojan二进制文件，默认使用xray-core来运行v2ray和trojan协议

2. lite版本移除了shdowsocks的v2ray-plugin插件功能及其对应的二进制文件：v2ray-plugin

3. lite版本移除了UDP加速功能及其二进制文件：speederv1、speederv2、udp2raw

4. lite版本移除了KCP加速功能及其二进制文件：kcptun

5. lite版本移除了koolgame协议支持及其二进制文件：koolgame、pdu

6. lite版本移除了负载均衡支持及其页面和二进制文件：haproxy

7. lite版本移除了直连解析的国外DNS方案及其二进制文件：cdns、chinadns、chinadns1、smartdns

8. lite版本移除了haveged，因为现在较新的固件系统自带了熵增软件

9. lite版本移除了shdowsocks-rust替换shadowsocks-libev功能，默认由shadowsocks-libev运行ss协议

10. lite版本移除了socks5页面及其脚本及其acl规则文件

如果是不折腾以上被精简功能的用户，完全可以使用体积更小的lite版本

RT-AX56U_V2这种jffs分区极小(15MB)的机型，建议直接使用lite版本

要切换为lite版本，直接安装lite版本的离线安装包即可，以后在线更新也会维持为lite版本

要切换为full版本，直接安装full版本的离线安装包即可，以后在线更新也会维持为full版本

## 插件下载

插件下载有两种方式：

1. 在`packages`目录下，点击tar.gz后缀文件，下载当前最新版本的离线安装包
2. 在[fancyss_history_package](https://github.com/hq450/fancyss_history_package)项目中，包含**历史版本**和**最新版本**的离线安装包

插件离线包下载导航：

| 平台 | 最新full版本下载                                             | 最新lite版本下载                                             | 历史版本下载（包含最新版）                                   |
| ---- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| hnd  | [fancyss_hnd_full](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_hnd_full.tar.gz) | [fancyss_hnd_lite](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_hnd_lite.tar.gz) | [fancyss_hnd](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd) |
| qca  | [fancyss_qca_full](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_qca_full.tar.gz) | [fancyss_qca_lite](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_qca_lite.tar.gz) | [fancyss_qca](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca) |
| farm | [fancyss_arm_full](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_arm_full.tar.gz) | [fancyss_arm_lite](https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/fancyss_arm_lite.tar.gz) | [fancyss_arm](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm) |

## 插件安装

1. 离线安装：下载并校验好离线安装包后，在软件中心内使用**离线安装**/**手动安装**功能，选择安装包后上传并安装即可。

2. 命令安装：(以fancyss_hnd_lite.tar.gz为例，先下载好安装包，并将其上传到路由器的/tmp目录)

   ```bash
   mv /tmp/fancyss_hnd_lite.tar.gz /tmp/shadowsocks.tar.gz
   tar -zxvf /tmp/shadowsocks.tar.gz
   sh /tmp/shadowsocks/install.sh
   ```

## 注意事项

* 强烈建议使用chrome或者chrouium内核的浏览器！以保证最佳兼容性！
* 强烈建议在`最新版本的固件`和`最新版本软件中心`上使用fancyss_hnd！
* 插件会自动跟随当前固件的皮肤类型，支持assuwrt、rog、tuf三种皮肤。
* 一些机型的联名版，只要刷了官改/梅林改版固件的，均能安装本插件！

## 目录说明

1. **fancyss**：插件代码主目录，由build.sh打包成不同路由器的离线安装包
2. **binaries**：一些在线更新的二进制程序，如v2ray、xray
3. **packages**：不同平台的离线安装包的最新版本，用于插件的在线更新
4. **rules**：插件的规则文件，如gfwlist.conf、chnroute.txt、cdn.txt

## 打包插件

> 打包过程就是将fancyss目录下相关二进制和代码文件通过脚本生成不同平台，不同版本的离线安装包。
>
> 为保证在不同路由器/固件版本中都能运行，项目提供的所有二进制都是预编译好的，且尽量提供全静态编译版本。

1. 克隆本项目：使用linux系统，比如Ubuntu 20.04

   ```bash
   git clone https://github.com/hq450/fancyss.git
   ```

2. 切换到3.0分支

   ```bash
   cd fancyss
   git checkout 3.0
   ```

3. 修改代码：修改代码主目录fancyss目录下的相关文件，如`./fancyss/ss/ssconfig.sh`

4. 打包插件，运行打包命令后会自动同步rules下最新的规则和binaries下最新的二进制

   ```bash
   sh build.sh
   ```

5. 打包好的离线安装包位于`./packages/`目录，包含以下三个平台的离线安装文件，每个平台分为full版本和lite版本

   ```bash
   fancyss_arm_full.tar.gz
   fancyss_arm_lite.tar.gz
   fancyss_hnd_full.tar.gz
   fancyss_hnd_lite.tar.gz
   fancyss_qca_full.tar.gz
   fancyss_qca_lite.tar.gz
   ```

## 相关链接

* **fancyss 3.0**更新日志：https://github.com/hq450/fancyss/blob/3.0/Changelog.txt

* 官改/梅改固件下载【网方网站】（最新固件）：[https://www.koolcenter.com](https://www.koolcenter.com/)
* 官改/梅改固件下载【固件镜像】（次新固件）：[https://fw.koolcenter.com](https://fw.koolcenter.com)

[^1]: RT-AC86U从384_81918_koolshare固件版本开始，使用的是asuswrt风格ui，而不是rog风格。
