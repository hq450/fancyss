#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
V2RAY_CONFIG_FILE="/koolshare/ss/v2ray.json"
url_main="https://raw.githubusercontent.com/hq450/fancyss/3.0/binaries/v2ray"

# arm hnd hnd_v8 qca mtk
pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | grep -Eo "pkg_name=.+"|grep -Eo "fancyss\w+"|sed 's/_debug//g'|sed 's/fancyss_//g'|sed 's/_[a-z]\+$//g')
case $pkg_arch in
arm)
	ARCH=armv5
	;;
hnd)
	ARCH=armv7
	;;
hnd_v8)
	ARCH=arm64
	;;
qca)
	ARCH=armv7
	;;
mtk)
	ARCH=arm64
	;;
esac

get_latest_version(){
	rm -rf /tmp/v2ray_latest_info.txt
	echo_date "检测V2ray最新版本..."
	curl --connect-timeout 8 -s $url_main/latest_v5.txt > /tmp/v2ray_latest_info.txt
	if [ "$?" == "0" ];then
		if [ -z "$(cat /tmp/v2ray_latest_info.txt)" ];then
			echo_date "获取V2ray最新版本信息失败！使用备用服务器检测！"
			failed_warning_v2ray
		fi
		if [ -n "$(cat /tmp/v2ray_latest_info.txt|grep 404)" ];then
			echo_date "获取V2ray最新版本信息失败！使用备用服务器检测！"
			failed_warning_v2ray
		fi
		V2VERSION=$(cat /tmp/v2ray_latest_info.txt | sed 's/v//g')
		[ -z "${V2VERSION}" ] && V2VERSION="0"
		
		echo_date "检测到V2ray最新版本：${V2VERSION}"
		if [ ! -f "/koolshare/bin/v2ray" ];then
			echo_date "v2ray安装文件丢失！重新下载！"
			CUR_VER="0"
		else
			CUR_VER=$(v2ray version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g')
			[ -z "${CUR_VER}" ] && CUR_VER="0"
			echo_date "当前已安装V2ray版本：${CUR_VER}"
		fi
		COMP=$(versioncmp ${CUR_VER} ${V2VERSION})
		if [ "${COMP}" == "1" ];then
			[ "${CUR_VER}" != "0" ] && echo_date "V2ray已安装版本号低于最新版本，开始更新程序..."
			update_now v${V2VERSION}
		else
			V2RAY_LOCAL_VER=$(/koolshare/bin/v2ray version 2>/dev/null | head -n 1 | cut -d " " -f2)
			[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
			echo_date "V2ray已安装版本已经是最新，退出更新程序!"
		fi
	else
		echo_date "获取V2ray最新版本信息失败！使用备用服务器检测！"
		failed_warning_v2ray
	fi
}

failed_warning_v2ray(){
	echo_date "获取V2ray最新版本信息失败！请检查到你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}

update_now(){
	rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray && cd /tmp/v2ray

	echo_date "开始下载校验文件：md5sum.txt"
	wget -4 --no-check-certificate --timeout=20 -qO - ${url_main}/$1/md5sum.txt > /tmp/v2ray/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi
	
	echo_date "开始下载v2ray程序"
	echo_date "下载地址：${url_main}/$1/v2ray_${ARCH}"
	wget -4 --no-check-certificate --timeout=20 --tries=1 ${url_main}/$1/v2ray_${ARCH}
	#curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray/v2ray $url_main/$1/v2ray
	if [ "$?" != "0" ];then
		echo_date "v2ray下载失败！"
		v2ray_ok=0
	else
		v2ray_ok=1
		echo_date "v2ray程序下载成功..."
		mv v2ray_${ARCH} v2ray
	fi

	if [ "${md5sum_ok}" == "1" -a "${v2ray_ok}" == "1" ];then
		check_md5sum
	else
		echo_date "请检查你的网络！"
		echo_date "==================================================================="
		echo XU6J03M6
		exit 1
	fi
}

check_md5sum(){
	cd /tmp/v2ray
	echo_date "校验下载的文件!"
	V2RAY_LOCAL_MD5=$(md5sum v2ray|awk '{print $1}')
	V2RAY_ONLINE_MD5=$(cat md5sum.txt|grep -w v2ray_${ARCH}|awk '{print $1}')
	if [ "${V2RAY_LOCAL_MD5}" == "${V2RAY_ONLINE_MD5}" ];then
		echo_date "文件校验通过!"
		install_binary
	else
		echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
		echo_date "==================================================================="
		echo XU6J03M6
		exit 1
	fi
}

install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "$(pidof v2ray)" ];then
		echo_date "为了保证更新正确，先关闭v2ray主进程... "
		killall v2ray >/dev/null 2>&1
		move_binary
		sleep 1
		start_v2ray
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始替换v2ray二进制文件... "
	mv /tmp/v2ray/v2ray /koolshare/bin/v2ray
	chmod +x /koolshare/bin/v2*
	V2RAY_LOCAL_VER=$(/koolshare/bin/v2ray version 2>/dev/null | head -n 1 | cut -d " " -f2)
	V2RAY_LOCAL_DATE=$(/koolshare/bin/v2ray version 2>/dev/null | head -n 1 | cut -d " " -f5)
	[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
	[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
	echo_date "v2ray二进制文件替换成功... "
}

start_v2ray() {
	# set vcore name
	if [ "${ss_basic_vcore}" == "1" ];then
		VCORE_NAME=Xray
		V2RAY_CONFIG_FILE="/koolshare/ss/xray.json"
	else
		VCORE_NAME=V2ray
		V2RAY_CONFIG_FILE="/koolshare/ss/v2ray.json"
	fi
	
	# tfo start
	if [ "$ss_basic_tfo" == "1" ]; then
		echo_date 开启tcp fast open支持.
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi
	if [ "${ss_basic_vcore}" == "1" ];then
		# xray start
		if [ "${ss_basic_xguard}" == "1" ];then
			echo_date "开启Xray主进程 + Xray守护..."
			# use perp to start xray
			mkdir -p /koolshare/perp/xray/
			cat >/koolshare/perp/xray/rc.main <<-EOF
				#!/bin/sh
				source /koolshare/scripts/base.sh
				CMD="xray run -c /koolshare/ss/xray.json"
				
				exec 2>&1
				exec \$CMD
				
			EOF
			chmod +x /koolshare/perp/xray/rc.main
			chmod +t /koolshare/perp/xray/
			perpctl -u xray >/dev/null 2>&1
		else
			echo_date "开启Xray主进程..."
			cd /koolshare/bin
			xray run -c $V2RAY_CONFIG_FILE >/dev/null 2>&1 &
		fi
		local XPID
		local i=25
		until [ -n "$XPID" ]; do
			i=$(($i - 1))
			XPID=$(pidof xray)
			if [ "$i" -lt 1 ]; then
				echo_date "${VCORE_NAME}进程启动失败！"
				close_in_five
			fi
			usleep 250000
		done
		echo_date ${VCORE_NAME}启动成功，pid：$XPID
	else
		# v2ray start
		echo_date "开启V2ray主进程..."
		cd /koolshare/bin
		v2ray --config=$V2RAY_CONFIG_FILE >/dev/null 2>&1 &
		local V2PID
		local i=25
		until [ -n "$V2PID" ]; do
			i=$(($i - 1))
			V2PID=$(pidof v2ray)
			if [ "$i" -lt 1 ]; then
				echo_date "${VCORE_NAME}进程启动失败！"
				close_in_five
			fi
			usleep 250000
		done
		echo_date ${VCORE_NAME}启动成功，pid：$V2PID
	fi
}

case $2 in
1)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo_date "                v2ray程序更新(Shell by sadog)" | tee -a /tmp/upload/ss_log.txt
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	get_latest_version | tee -a /tmp/upload/ss_log.txt 2>&1
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	;;
esac