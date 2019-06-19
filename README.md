# fancyss - 科学上网

Fancyss is a project providing tools to across the GFW on asuswrt/merlin/openwrt based router with software center. 

此项目提供用于asuswrt/merlin/openwrt为基础的，带软件中心固件路由器的科学上网。

## 机型/固件支持

### [fancyss_hnd](https://github.com/hq450/fancyss/tree/master/fancyss_hnd)
**fancyss_hnd**离线安装包仅适用于asus/merlin koolshare hnd/axhnd平台机型改版固件（armV8架构，linux内核版本：4.1.27/4.1.51，bcm490X系列cpu）

**fancyss_hnd**支持机型/固件：
 * [RT-AC86U merlin改版固件](http://koolshare.cn/thread-127878-1-1.html)
 * [RT-AX88U merlin改版固件](http://koolshare.cn/thread-158199-1-1.html)
 * [RT-AC86U 官改固件](http://koolshare.cn/thread-139965-1-1.html)
 * [GT-AC5300 官改固件](http://koolshare.cn/thread-130902-1-1.html)
 * [GT-AX11000 官改固件](http://koolshare.cn/thread-159465-1-1.html)

#### 注意： 
* 其它arm架构或mipsel架构的merlin固件不能使用fancyss_hnd！
* 强烈建议在最新版本的固件和最新版本软件中心上使用fancyss_hnd！
* GT-AC5300/RT-AC86U官该固件使用的是ROG皮肤，插件安装会自动识别机型并安装对应皮肤版本。

#### 相关链接：
* hnd机型的科学上网离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd)
* hnd机型的科学上网更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt
* hnd机型的固件下载地址：[http://koolshare.cn/forum-96-1.html](http://koolshare.cn/forum-96-1.html)

----

### [fancyss_arm](https://github.com/hq450/fancyss/tree/master/fancyss_arm)
**fancyss_arm**离线安装包仅适用于merlin koolshare arm架构机型改版固件（armV7架构，linux内核版本：2.6.36.4，bcm470X系列cpu）

**fancyss_arm**支持机型（需刷梅林koolshare改版固件）：
* 华硕系列：`RT-AC56U` `RT-AC68U` `RT-AC66U-B1` `RT-AC1900P` `RT-AC87U` `RT-AC88U` `RT-AC3100` `RT-AC3200` `RT-AC5300`
* 网件系列：`R6300V2` `R6400` `R6900` `R7000` `R8000` `R8500`
* linksys EA系列：`EA6200` `EA6400` `EA6500v2` `EA6700` `EA6900`
* 华为：`ws880`

#### 注意： 
* fancyss_arm仅支持版本号≥X7.2的固件（订阅功能需要版本号≥X7.7）
* `RT-AC86U`和`GT-AC5300`两款机器不能使用fancyss_arm！因为这两款机器的是新架构，请使用fancyss_hnd！
* `RT-AC66U`和`RT-N66U`也不能使用fancyss_arm！因为这两款机器的是mipsel架构，请使用fancyss_mipsel！

#### 相关链接：

* arm机型的科学上网离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm)
* arm机型的科学上网更新日志：https://github.com/hq450/fancyss/blob/master/fancyss_arm/Changelog.txt
* arm机型的固件下载地址：[http://koolshare.cn/forum-96-1.html](http://koolshare.cn/forum-96-1.html)

----

### [fancyss_mipsel](https://github.com/hq450/fancyss/tree/master/fancyss_mipsel)
适用于merlin koolshare mipsel架构机型的改版固件，由于mipsel架构老旧且性能较低，此架构机型的科学上网插件已经不再维护，最后的版本是3.0.4，此处作为仓库搬迁后的备份留存。

**fancyss_mipsel**支持机型（需刷梅林koolshare改版固件）：
* 华硕系列：`RT-N66U` `RT-AC66U（非RT-AC66U-B1）`

#### 相关链接：
* mipsel机型的科学上网离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mipsel](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mipsel)
* mipsel机型的固件下载地址：[http://koolshare.cn/forum-96-1.html](http://koolshare.cn/forum-96-1.html)

----

### [fancyss_X64](https://github.com/hq450/fancyss/tree/master/fancyss_X64)
适用于koolshare OpenWRT/LEDE X64 带酷软的固件，由于该固件酷软下架了koolss插件，本项目将其收入。

#### 相关链接：
* koolshare OpenWRT/LEDE X64机型的科学上网离线包：[https://github.com/hq450/fancyss_history_package/tree/master/fancyss_X64](https://github.com/hq450/fancyss_history_package/tree/master/fancyss_X64)
