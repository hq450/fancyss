# koolshare.github.io
####For koolshare.cn 小宝merlin改版固件 软件中心

<b>shadowsocks文件夹下的内容，用于向路由器内shadowsocks功能推送更新</b><br/>
<b>此项目仅用于merlin koolshare mipsel架构改版固件</b><br/>
* <b>shadowsocks/ss 文件夹 </b><br/>
该文件夹用于存放shadowsocks相关脚本和规则文件：

* <b>shadowsocks/webs</b><br/>
该文件夹用于存放shadowsocks的网页。

* <b>shadowsocks/res</b><br/>
该文件夹用于存放shadowsocks网页元素。

* <b>shadowsocks/bin</b><br/>
该文件夹用于存放shadowsocks的二进制文件。

* <b>shadowsocks/init.d</b><br/>
该文件夹用于存放shadowsocks的开机启动文件，目前因为shadowsocks的启动依赖wan-start和nat-start两个启动文件，所以并没有用init.d的启动方式，而socks5使用了该方式



* <b>shadowsocks.tar.gz</b><br/>
此文件为shadowsocks文件夹的打包，通过路由器访问 [https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/shadowsocks_mips/shadowsocks.tar.gz](https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/shadowsocks_mips/shadowsocks.tar.gz) 获取安装包更新。
如果你更新出现问题，请按照以下方式手动更新：
<pre>
wget --no-check-certificate --timeout=15 -P /tmp https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/shadowsocks/shadowsocks.tar.gz
tar -zxvf /tmp/shadowsocks.tar.gz
chmod +x /tmp/shadowsocks/install.sh
sh /tmp/shadowsocks/install.sh
</pre>

* <b>history文件夹</b><br/>
该文件夹用于存放shadowsocks历史安装包，需要回滚历史版本的，可以下载对应版本，然后手动安装。

* <b>version</b><br/>
在线版本号和shadowsocks.tar.gz的md5校验值，用于判断更新。

<b>怎样提交修改</b>
需要再次说明的是，ss的在线更新是通过请求shadowsocks.tar.gz文件进行的，如果你有发现bug，并希望提交你的更改，需要做以下几点：<br/>
1. 发现bug，修改需要修改的文件；<br/>
2. 更新shadowsocks/ss_mips/version，更新版本号；<br/>
3. 修改Changelog.txt文件，添加更新日志；<br/>
4. 运行build.sh文件，这样会自动打包shadowsocks文件夹，并且更新versionn内的版本号和md5值，同时会把就版本丢进history中；<br/>
5. 运行git status，查看被修改的文件，然后添加，评论，提交；<br/>



