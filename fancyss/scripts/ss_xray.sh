#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
XRAY_CONFIG_FILE="/koolshare/ss/xray.json"
url_main="https://raw.githubusercontent.com/hq450/fancyss/3.0/binaries/xray"

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
	local VERSION_FILE=$1
	rm -rf /tmp/xray_latest_info.txt
	echo_date "检测Xray最新版本..."
	curl --connect-timeout 8 -s ${url_main}/${VERSION_FILE}.txt > /tmp/xray_latest_info.txt
	if [ "$?" == "0" ];then
		if [ -z "$(cat /tmp/xray_latest_info.txt)" ];then
			echo_date "获取Xray最新版本信息失败！使用备用服务器检测！"
			failed_warning_xray
		fi
		if [ -n "$(cat /tmp/xray_latest_info.txt|grep 404)" ];then
			echo_date "获取Xray最新版本信息失败！使用备用服务器检测！"
			failed_warning_xray
		fi
		XVERSION=$(cat /tmp/xray_latest_info.txt | sed 's/v//g')
		[ -z "${XVERSION}" ] && XVERSION="0"
		
		echo_date "检测到Xray最新版本：${XVERSION}"
		if [ ! -f "/koolshare/bin/xray" ];then
			echo_date "xray安装文件丢失！重新下载！"
			CUR_VER="0"
		else
			CUR_VER=$(xray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g')
			[ -z "${CUR_VER}" ] && CUR_VER="0"
			echo_date "当前已安装Xray版本：${CUR_VER}"
		fi
		COMP=$(versioncmp ${CUR_VER} ${XVERSION})
		if [ "${COMP}" == "1" ];then
			[ "${CUR_VER}" != "0" ] && echo_date "Xray已安装版本号低于更新版本，开始更新程序..."
			update_now v${XVERSION}
		elif [ "${COMP}" == "-1" ];then
			[ "${CUR_VER}" != "0" ] && echo_date "Xray已安装版本号高于更新版本，开始降级程序..."
			update_now v${XVERSION}
		else
			XRAY_LOCAL_VER=$(/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2)
			[ -n "${XRAY_LOCAL_VER}" ] && dbus set ss_basic_xray_version="${XRAY_LOCAL_VER}"
			echo_date "Xray已安装版本号等于更新版本，退出更新程序!"
		fi
	else
		echo_date "获取Xray最新版本信息失败！使用备用服务器检测！"
		failed_warning_xray
	fi
}

failed_warning_xray(){
	echo_date "获取Xray最新版本信息失败！请检查到你的网络！"
	exit 1
}

update_now(){
	rm -rf /tmp/xray
	mkdir -p /tmp/xray && cd /tmp/xray

	echo_date "开始下载校验文件：md5sum.txt"
	wget -4 --no-check-certificate --timeout=20 -qO - ${url_main}/$1/md5sum.txt > /tmp/xray/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi
	
	echo_date "开始下载xray程序"
	echo_date "下载地址：${url_main}/$1/xray_${ARCH}"
	wget -4 --no-check-certificate --timeout=20 --tries=1 ${url_main}/$1/xray_${ARCH}
	#curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray $url_main/$1/xray
	if [ "$?" != "0" ];then
		echo_date "xray下载失败！"
		xray_ok=0
	else
		xray_ok=1
		echo_date "xray程序下载成功..."
		mv xray_${ARCH} xray
	fi

	if [ "${md5sum_ok}" == "1" -a "${xray_ok}" == "1" ];then
		check_md5sum
	else
		echo_date "使用备用服务器下载..."
		echo_date "下载失败，请检查你的网络！"
		exit 1
	fi
}

check_md5sum(){
	cd /tmp/xray
	echo_date "校验下载的文件!"
	XRAY_LOCAL_MD5=$(md5sum xray|awk '{print $1}')
	XRAY_ONLINE_MD5=$(cat md5sum.txt|grep -w xray_${ARCH}|awk '{print $1}')
	if [ "${XRAY_LOCAL_MD5}" == "${XRAY_ONLINE_MD5}" ];then
		echo_date "文件校验通过!"
		install_binary
	else
		echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
		exit 1
	fi
}

install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "$(pidof xray)" ];then
		echo_date "为了保证更新正确，先关闭xray主进程... "
		xray_process=$(pidof xray)
		if [ -n "$xray_process" ]; then
			echo_date 关闭xray进程...
			[ -f "/koolshare/perp/xray/rc.main" ] && perpctl d xray >/dev/null 2>&1
			rm -rf /koolshare/perp/xray
			killall xray >/dev/null 2>&1
			kill -9 "$xray_process" >/dev/null 2>&1
		fi
		move_binary
		sleep 1
		start_xray
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始更新xray二进制文件... "
	mv /tmp/xray/xray /koolshare/bin/xray
	chmod +x /koolshare/bin/xray
	XRAY_LOCAL_VER=$(/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2)
	XRAY_LOCAL_DATE=$(/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f5)
	[ -n "$XRAY_LOCAL_VER" ] && dbus set ss_basic_xray_version="$XRAY_LOCAL_VER"
	[ -n "$XRAY_LOCAL_DATE" ] && dbus set ss_basic_xray_date="$XRAY_LOCAL_DATE"
	echo_date "xray二进制文件更新成功... "
}

start_xray() {
	# tfo start
	if [ "$ss_basic_tfo" == "1" ]; then
		echo_date 开启tcp fast open支持.
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi
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
		xray run -c $XRAY_CONFIG_FILE >/dev/null 2>&1 &
	fi
	local XPID
	local i=25
	until [ -n "$XPID" ]; do
		i=$(($i - 1))
		XPID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "Xray进程启动失败！"
			close_in_five
		fi
		usleep 250000
	done
	echo_date Xray启动成功，pid：$XPID
}

case $2 in
1)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo_date "                xray程序更新(Shell by sadog)" | tee -a /tmp/upload/ss_log.txt
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	get_latest_version latest | tee -a /tmp/upload/ss_log.txt 2>&1
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	;;
2)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo_date "                xray程序更新(Shell by sadog)" | tee -a /tmp/upload/ss_log.txt
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	get_latest_version latest_2 | tee -a /tmp/upload/ss_log.txt 2>&1
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	;;
esac