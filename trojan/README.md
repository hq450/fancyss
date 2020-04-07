# trojan on fancyss test

因为trojan的呼声实在是太高，没办法只好回应一下了：fancyss插件会做trojan的集成。不过最近工作忙，所以短期内没多少时间来给插件添加trojian功能。但是我先编译好了hnd平台的trojan二进制文件，所以在fancyss插件完成trojian集成之前，你可以这么做来实现trojan的使用。

1. 首先完成trojan服务器端配置，得到以下信息

   ```bash
   # 域名：fancyss.example.com
   # 端口：443
   # 密码：fancyss
   # 证书：cert.crt
   ```

2. 下载本目录下的trojan二进制文件，放进`/koolshare/bin`，此二进制文件适用于hnd机型。

   ```bash
   # ssh运行以下命令下载trojan二进制文件
   cd /koolshare/bin
   wget https://raw.githubusercontent.com/hq450/fancyss/master/trojan/trojan
   chmod +x /koolshare/bin/trojan
   ```

3. 用winscp登录路由器，将证书文件，如：`cert.crt`放进`/koolshare/ss/rules`目录

4. 创建trojan.json配置文件到`/koolshare/ss/trojan.json`，使用trojan官方的配置文件：**[nat.json-example](https://github.com/trojan-gfw/trojan/blob/master/examples/nat.json-example)**来进行修改。

   ```bash
   # 下载配置文件模板
   cd /koolshare/ss
   wget https://raw.githubusercontent.com/trojan-gfw/trojan/master/examples/nat.json-example trojan.json
   mv nat.json-example trojan_nat.json
   
   # 修改模板中以下配置为第1步中的值
   local_port 修改为 3333,
   "remote_addr": "fancyss.example.com",
   "remote_port": 443,
   "cert": "/koolshare/ss/rules/cert.crt",
   ```
   
5. 修改/koolshare/ss/trojan_nat.json

   1. local_port 修改为 3333
   
   2. remote_addr改为你的域名，比如：fancyss.example.com
   3. remote_port改为你的端口，比如：443
   
   4. password同理
   
   5. ssl下cert配置改成：`"cert": "/koolshare/ss/rules/cert.crt"`
   
6. 启用fancyss_hnd插件ssr模式，国外DNS使用不经过服务转发的方式，比如使用cdns、chinadns2、https_dns_proxy、SmartDNS。然后进入SSH，将监听在3333端口的rss-redir进程杀掉。v2ray模式下杀v2ray进程，ss模式下杀ss-redir进程

   ```bash
   # 杀掉占用3333端口的进程
   killall rss-redir
   ```
   
7. 启用trojan
   
   ```bash
   # 启动trojan前台运行
   /koolshare/bin/trojan -c /koolshare/ss/trojan_nat.json
   
# 若需后台运行，使用下面命令
   /koolshare/bin/trojan -c /koolshare/ss/trojan_nat.json >/dev/null 2>&1 &
   ```
   
   


**总结**：以上操作其实就是利用了插件现成的DNS方案，iptables配置等，用trojan来提供透明代理，而不是ss/ssr/v2ray。选用直连的国外DNS方案是因为这里直接用了trojan的nat运行方式，不同于client方式，提供的是socks5端口。如果需要使用经由服务器转发的DNS方式，那么需要杀掉ss-local，rss-local进程，然后再开一个client模式的trojan，监听在23456端口即可。