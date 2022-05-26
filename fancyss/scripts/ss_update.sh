#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
mkdir -p /tmp/upload
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
main_url="https://raw.githubusercontent.com/hq450/fancyss/3.0/packages"

# --------------------------------------
# 6.x.4708			2.6.36.4		arm
# 7.14.114.x		2.6.36.4		arm
# hnd				4.1.27			hnd
# axhnd 			4.1.51			hnd
# axhnd.675x 		4.1.52			hnd
# p1axhnd.675x		4.1.27			hnd
# 5.04axhnd.675x	4.19.183		hnd
# qca (RT-AX89X)	4.4.60			qca
# --------------------------------------
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
if [ "${LINUX_VER}" -eq "41" -o "${LINUX_VER}" -eq "419" ];then
	PLATFORM=hnd
elif [ "${LINUX_VER}" -eq "44" ];then
	PLATFORM=qca
elif [ "${LINUX_VER}" -eq "26" ];then
	PLATFORM=arm
fi

if [ ! -x "/koolshare/bin/v2ray" ];then
	PKGTYPE=lite
else
	PKGTYPE=full
fi
MD5NAME=md5_${PLATFORM}_${PKGTYPE}
PACKAGE=fancyss_${PLATFORM}_${PKGTYPE}
VERSION=version.json.js

install_fancyss(){
	echo_date "开始解压压缩包..."
	tar -zxf shadowsocks.tar.gz
	chmod a+x /tmp/shadowsocks/install.sh
	echo_date "开始安装更新文件..."
	sh /tmp/shadowsocks/install.sh
	rm -rf /tmp/shadowsocks*
}

update_ss(){
	echo_date "更新过程中请不要刷新本页面或者关闭路由等，不然可能导致问题！"
	echo_date "检查科学上网插件更新，使用主服务器：github"
	echo_date "检测主服务器在线版本号..."
	echo_date "地址：${main_url}/${VERSION}"
	curl -4sk --connect-timeout 10 ${main_url}/${VERSION} >/tmp/version.json.js
	if [ "$?" != "0" ];then
		echo_date "没有检测到主服务器在线版本号，访问github服务器可能有点问题！"
		echo "XU6J03M6"
		exit
	fi
	jq --tab . /tmp/version.json.js >/dev/null 2>&1
	if [ "$?" != "0" ];then
		echo_date "在线版本号获取错误！请检测你的网络！"
		echo "XU6J03M6"
		exit
	fi
	
	fancyss_version_online=$(cat /tmp/version.json.js | jq -r '.version')
	echo_date "检测到主服务器在线版本号：${fancyss_version_online}"
	dbus set ss_basic_version_web="${fancyss_version_online}"
	if [ "${ss_basic_version_local}" != "${fancyss_version_online}" ];then
		echo_date "主服务器在线版本号：${fancyss_version_online} 和本地版本号：${ss_basic_version_local} 不同！"
		cd /tmp
		fancyss_md5_online=$(cat /tmp/version.json.js | jq -r .$MD5NAME)
		echo_date "开启下载进程，从主服务器上下载更新包..."
		echo_date "下载链接：${main_url}/${PACKAGE}.tar.gz"
		wget -4 --no-check-certificate --timeout=5 ${main_url}/${PACKAGE}.tar.gz
		if [ "$?" != "0" ];then
			echo_date "下载失败！请检查你的网络！"
		fi
		echo_date "${PACKAGE}.tar.gz 下载成功！"
		mv ${PACKAGE}.tar.gz shadowsocks.tar.gz
		fancyss_size_download=$(ls -lh /tmp/shadowsocks.tar.gz |awk '{print $5}')
		fancyss_md5_download=$(md5sum /tmp/shadowsocks.tar.gz | sed 's/ /\n/g'| sed -n 1p)
		echo_date "安装包大小：${fancyss_size_download}"
		echo_date "安装包md5校验值：${fancyss_md5_download}"
		echo_date "安装包在线md5：${fancyss_md5_online}"
		if [ "${fancyss_md5_download}" != "${fancyss_md5_online}" ]; then
			echo_date "更新包md5校验不一致！估计是下载的时候出了什么状况，请等待一会儿再试..."
			rm -rf /tmp/shadowsocks* >/dev/null 2>&1
		else
			echo_date "更新包md5校验一致！ 开始安装！..."
			install_fancyss
		fi
	else
		echo_date "主服务器在线版本号：${fancyss_version_online} 和本地版本号：${ss_basic_version_local} 相同！"
		echo_date "退出插件更新!"
	fi
}


case $2 in
update)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	update_ss >> /tmp/upload/ss_log.txt 2>&1
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac
