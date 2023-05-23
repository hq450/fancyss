### V2RAY 二进制存放
***
##### 由于路由器jffs空间有限，此处存放经过UPX压缩的v2ray二进制，以节约空间
压缩命令：`upx --lzma --ultra-brute v2ray`

v2ray 从v4.21.0版本开始，[v2ray官方项目](https://github.com/v2ray/v2ray-core)release页面提供的二进制在博通BCM470X型号CPU上运行出现报错（如RT-AC68U,RT-AC88U等机型），因此从此版本后的v2ray二进制为本项目自编译后，经过upx压缩大小后在此处提供。



**note**：从v2ray v5版本开始，v2ray的运行命令有所变更，为了避免使用老版本插件的用户更新到v5版本的v2ray，老版本插件仍然使用`latest.txt`获取v2ray最新版本（V4），新版本用户使用`latest_v5.txt`获取v2ray最新版本

