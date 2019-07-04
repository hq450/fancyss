# [fancyss_arm384](https://github.com/hq450/fancyss/tree/master/fancyss_arm384)

> **fancyss_arm384**离线安装包仅能在koolshare 梅林 arm 384平台，且linux内核为2.6.36.4的armv7架构的机器上使用！

## 使用须知：

建议使用此版本科学上网插件（fancyss_arm384）的朋友仔细阅读以下内容：

- **fancyss_arm384**	仅能在koolshare 梅林 arm 384平台，且linux内核为2.6.36.4的armv7架构的机器上使用
- **fancyss_arm**		仅能在koolshare 梅林 arm 380平台，且linux内核为2.6.36.4的armv7架构的机器上使用
- **fancyss_hnd**		仅能在koolshare 梅林/官改 hnd/axhnd 384平台，且linux内核为4.1.27/4.1.51的armv8架构机器上使用

fancyss_arm384可以用在比如RT-AC88U_384.12_0，RT-AC5300_384.12_0的koolshare梅林384固件。
安装本插件请使用软件中心自带的离线安装功能，插件安装成功后回在软件中心显示名为【科学上网】的图标。

## 插件介绍

1. 在web方面：此版本科学上网插件在web上使用的是是软件中心1.5代的api(与fancyss_hnd软件中心api一致)，

2. 在程序方面：此版本科学上网集成的相关程序仍然是armv7架构程序(与fancyss_arm 所用的二进制程序文件一致)。
   

​		fancyss_arm384相当于fancyss_arm 和 fancyss_hnd的合体，但是不兼容其中任何一个（因为web api或者二进制架构不同的原因），   不过因为部分二进制文件是全静态编译的，所以部分二进制文件在两个不同的平台是可以通用的，   所以fancyss_arm384会用到一些fancyss_hnd的二进制文件，如ss-redir，rss-redir等，   也有很多不通用的，比如dnsmasq-fastlookup，v2ray，httping，dns2socks等程序。

​		fancyss_arm384在功能上几乎复刻了fancyss_hnd，所以fancyss_hnd本来已有的功能，在fancyss_arm384几乎都会有，fancyss_arm384/fancyss_hnd相比fancyss_arm，有更精简的代码、更好节点管理功能、新增的故障转移等等功能，但是由于fancyss_arm384 所支持的梅林固件linux内核版本2.6.36太老旧，因此不支持fancyss_hnd有的一些特性，目前已知的fancyss_arm384比fancyss_hnd会少**[ss/ssr 开启多核心支持]**和**[tcp fast open]**功能。

​		fancyss_arm384的一些特性的相关功能多数时候可以参考fancyss_hnd的更新日志：[Changelog.txt](https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt)
