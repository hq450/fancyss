### V2RAY arm二进制存放
***
##### 由于路由器jffs空间有限，此处存放经过UPX压缩的v2ray二进制，以节约空间<br/>
##### 此处存放的v2ray二进制来源于[v2ray官方项目](https://github.com/v2ray/v2ray-core)的[releases页面](https://github.com/v2ray/v2ray-core/releases)，仅使用UPX处理，用于路由器下的v2ray二进制更新<br/>

压缩命令：`upx --lzma --ultra-brute v2ray v2ray_armv7 v2ctl`

v2ray 从v4.21.0版本开始，[v2ray官方项目](https://github.com/v2ray/v2ray-core)release页面提供的二进制在博通BCM470X型号CPU上运行出现报错（如RT-AC68U,RT-AC88U等机型），因此从此版本后的v2ray二进制为本项目自编译后，经过upx压缩大小后在此处提供。

- 编译采用`go version go1.13.5`版本
- v2ray提供给fancyss_hnd使用，编译参数为GOARCH=arm, GOARM=7
- v2ray_armv7提供给fancyss_arm和fancyss_arm384，编译参数为GOARCH=arm, GOARM=5
- v2ctl提供给fancyss_arm、fancyss_arm384和fancyss_hnd，，编译参数为GOARCH=arm, GOARM=5