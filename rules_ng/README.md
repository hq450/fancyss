此目录下的规则文件经过重新整理，以适应fancyss 3.3.9及以上版本

fancyss 3.3.9及以上版本的chinadns-ng为魔改版本，支持读取gz压缩包域名列表

---

**域名列表**

gfwlist.gz，包含已知的被墙的域名，上游：[Loukky/gfwlist-by-loukky](https://github.com/Loukky/gfwlist-by-loukky)，[pexcn/daily](pexcn/daily)

chnlist.gz，包含全部cn域名和10万+条非cn的国内域名

udplist.txt，用于在【附加功能】-【udp代理控制】中设置的需要走udp代理的域名

rotlist.txt，用于控制路由器自己的流量哪些域名走代理

white_list.txt，域名白名单，不走代理，比如steam的一些域名，防止游戏下载走代理

black_list.txt，域名黑名单，走代理，gfwlist以外额外要走代理的名单，效果等同gfwlist

block_list.txt，需要屏蔽dns解析的域名，比如adobe相关域名，防止adobe软件弹非正版提示窗口

adslist.gz，要屏蔽dns解析的广告域名，列表来源：https://anti-ad.net

**域名列表（附加）**

apple_china.txt，苹果在中国大陆的域名

google_china.txt，谷歌在中国大陆的域名

cdn_test.txt，cdn测试域名，用于fancyss dig测试

**ip列表**

chnroute.txt，中国大陆ipv4地址

chnroute6.txt，中国大陆ipv6地址