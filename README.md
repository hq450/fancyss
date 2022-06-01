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
- armv8机型支持tcp fast open和ss/ssr/trojan多核心运行

## 支持机型/固件

> 以下为fancyss 3.x.x支持的机型/固件，点击机型可以前往相应固件下载地址

| 机型/固件下载                                                | 类型 | 平台           | CPU       | 架构  | linux内核 | 插件皮肤    | fancyss版本 |
| ------------------------------------------------------------ | ---- | -------------- | --------- | ----- | --------- | ----------- | --------------- |
| [R6300V2](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/Netgear/R6300v2/) | 梅改 | 6.x.4708       | BCM4708   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC68U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AC68U/) | 梅改 | 6.x.4708       | BCM4708   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC88U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AC88U/) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC3100](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AC3100/) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC5300](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AC5300/) | 梅改 | 7.14.114.x     | BCM4709   | armv7 | 2.6.36.4  | asuswrt     | fancyss_arm     |
| [RT-AC86U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AC86U/) | 梅改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt     | fancyss_hnd     |
| RT-AC86U                                                     | 官改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt[^1] | fancyss_hnd     |
| [GT-AC2900](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/GT-AC2900/) | 梅改 | hnd            | BCM4906   | armv8 | 4.1.27    | asuswrt     | fancyss_hnd     |
| GT-AC2900                                                    | 官改 | hnd            | BCM4906   | armv8 | 4.1.27    | rog         | fancyss_hnd     |
| GT-AC5300                                                    | 官改 | hnd            | BCM4908   | armv8 | 4.1.27    | rog         | fancyss_hnd     |
| [RT-AX88U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AX88U/) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [RT-AX88U](https://www.koolcenter.com/posts/142)             | 官改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| [RAX80](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/Netgear/RAX80/) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| GT-AX11000                                                   | 官改 | axhnd          | BCM4908   | armv8 | 4.1.51    | rog         | fancyss_hnd     |
| [GT-AX11000](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/GT-AX11000/) | 梅改 | axhnd          | BCM4908   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| RT-AX92U                                                     | 官改 | axhnd          | BCM4906   | armv8 | 4.1.51    | asuswrt     | fancyss_hnd     |
| TUF-AX3000                                                   | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| [TUF-AX5400](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/TUF-AX5400/) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| TUF-AX5400                                                   | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | tuf         | fancyss_hnd     |
| [RT-AX58U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AX58U/) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RAX50](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/Netgear/RAX50/) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX82U                                                     | 官改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX82U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AX82U/) | 梅改 | axhnd.675x     | BCM6750   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| ZenWiFi_XT8                                                  | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [ZenWiFi_XT8](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/ZenWiFi_XT8/) | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| ZenWiFi_XD4                                                  | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX56U_V2                                                  | 官改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX1800                                                    | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX56U                                                     | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RAX70](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/Netgear/RAX70/) | 梅改 | axhnd.675x     | BCM6755   | armv7 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX68U                                                     | 官改 | p1axhnd.675x   | BCM4906   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX68U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AX88U/) | 梅改 | p1axhnd.675x   | BCM4906   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| RT-AX86U                                                     | 官改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [RT-AX86U](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/RT-AX86U/) | 梅改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| [GT-AXE11000](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/GT-AXE11000/) | 梅改 | p1axhnd.675x   | BCM4908   | armv8 | 4.1.52    | asuswrt     | fancyss_hnd     |
| GT-AX6000                                                    | 官改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | rog         | fancyss_hnd     |
| [GT-AX6000](https://fw.koolcenter.com/KoolCenter_Merlin_New_Gen_386/GT-AX6000/) | 梅改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/133)     | 官改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [ZenWiFi_Pro_XT12](https://www.koolcenter.com/posts/149)     | 梅改 | 5.04axhnd.675x | BCM4912   | armv8 | 4.19.183  | asuswrt     | fancyss_hnd     |
| [TUF-AX3000_V2](https://www.koolcenter.com/posts/161)        | 官改 | 5.04axhnd.675x | BCM6756   | armv7 | 4.19.183  | tuf         | fancyss_hnd     |
| [RT-AX89X](https://koolshare.cn/thread-188090-1-1.html)      | 官改 | qca-ipq806x    | ipq8074/a | armv7 | 4.4.60    | asuswrt     | fancyss_qca     |

## 注意事项

* 相关机型的梅林改/官改固件下载请前往：[https://www.koolcenter.com/](https://www.koolcenter.com/)
* 使用fancyss_hnd科学上网插件，强烈建议使用chrome或者chrouium内核的浏览器！以保证最佳兼容性！
* 强烈建议在`最新版本的固件`和`最新版本软件中心`上使用fancyss_hnd！
* GT-AC2900/GT-AC5300/GT-AX11000/GT-AX6000官改使用ROG皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* TUF-AX3000/TUF-AX5400官改固件使用的是TUF橙色皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* TUF-AX5400梅林改版固件使用的是TUF橙色皮肤，插件安装会自动识别机型并安装对应皮肤版本。
* 一些机型的联名版如GT-AX11000使命召唤黑色行动版/海妖版，RT-AX86U高达版/鬼灭之刃版，RT-AX82U高达版，RT-AX88U高达版本，GT-AX6000 EVA版等各种联名版均是默认支持的。

## 相关链接

- **fancyss 3.x.x**更新日志：https://github.com/hq450/fancyss/blob/3.0/Changelog.txt

* **fancyss_hnd**离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd)
* **fancyss_qca**离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca)
* **fancyss_arm**离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm384)
* 官改/梅改固件下载【网方网站】：[https://www.koolcenter.com](https://www.koolcenter.com/)
* 官改/梅改固件下载【固件镜像】：[https://fw.koolcenter.com](https://fw.koolcenter.com)

## 目录说明

1. **fancyss**：插件代码主目录，由build.sh打包成不同路由器的离线安装包
2. **binaries**：一些在线更新的二进制程序，如v2ray、xray
3. **packages**：不同平台的离线安装包的最新版本，用于插件的在线更新
4. **rules**：插件的规则文件，如gfwlist.conf、chnroute.txt、cdn.txt

## 如何编译

> 为了保证在不同路由器/固件版本之间都能运行，目前项目提供的所有二进制都是预编译好的，尽量提供全静态编译版本。

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

[^1]: RT-AC86U从384_81918_koolshare固件版本开始，使用的是asuswrt风格ui，而不是rog风格。
