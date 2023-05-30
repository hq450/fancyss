#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
source /koolshare/scripts/ss_base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
url_main="https://raw.githubusercontent.com/hq450/fancyss/3.0/binaries/ss_rust"
DNLD=""

run(){
	env -i PATH=${PATH} "$@"
}

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
	flag=$1
	rm -rf /tmp/ssrust_latest_info.txt
	echo_date "检测shadowsocks-rust最新版本..."
	curl --connect-timeout 8 -s ${url_main}/latest.txt > /tmp/ssrust_latest_info.txt
	if [ "$?" == "0" ];then
		if [ -z "$(cat /tmp/ssrust_latest_info.txt)" ];then
			echo_date "获取shadowsocks-rust最新版本信息失败！使用备用服务器检测！"
			failed_warning
		fi
		if [ -n "$(cat /tmp/ssrust_latest_info.txt|grep "404")" ];then
			echo_date "获取shadowsocks-rust最新版本信息失败！使用备用服务器检测！"
			failed_warning
		fi
		RVERSION=$(cat /tmp/ssrust_latest_info.txt | sed 's/v//g' )
		if [ -z "${RVERSION}" ];then
			RVERSION="0"
		fi
		
		echo_date "检测到shadowsocks-rust最新版本：${RVERSION}"
		if [ ! -x "/koolshare/bin/sslocal" ];then
			echo_date "shadowsocks-rust二进制文件sslocal不存在！开始下载！"
			update_now v${RVERSION}
		else
			CUR_VER_ORIG=$(env -i /koolshare/bin/sslocal --version 2>/dev/null | awk '{print $NF}')
			CUR_VER=$(echo "${CUR_VER_ORIG}" | sed 's/-alpha//g')
			if [ -z "${CUR_VER}" ];then
				CUR_VER="0"
			fi
			echo_date "当前已安装shadowsocks-rust版本：${CUR_VER_ORIG}"

			COMP=$(versioncmp ${CUR_VER} ${RVERSION})
			if [ "${COMP}" == "1" ];then
				[ "${CUR_VER}" != "0" ] && echo_date "sslocal已安装版本号低于最新版本，开始更新程序..."
				update_now v${RVERSION}
			else
				echo_date "检测到本地版本已经是最新，退出更新程序!"
			fi
		fi
	else
		echo_date "获取shadowsocks-rust最新版本信息失败！使用备用服务器检测！"
		failed_warning
	fi
}

failed_warning(){
	echo_date "获取shadowsocks-rust最新版本信息失败！请检查到你的网络！"
	echo_date "==================================================================="
	return 1
}

update_now(){
	rm -rf /tmp/sslocal_bin
	mkdir -p /tmp/sslocal_bin
	cd /tmp/sslocal_bin

	echo_date "开始下载校验文件：md5sum.txt"
	wget -4 --no-check-certificate --timeout=20 -qO - ${url_main}/$1/md5sum.txt > /tmp/sslocal_bin/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi
	
	echo_date "开始下载shadowsocks-rust sslocal程序"
	echo_date "下载地址：${url_main}/$1/sslocal_${ARCH}"
	wget -4 --no-check-certificate --timeout=20 --tries=1 ${url_main}/$1/sslocal_${ARCH}
	if [ "$?" != "0" ];then
		echo_date "sslocal下载失败！"
		sslocal_ok=0
	else
		echo_date "sslocal程序下载成功..."
		mv sslocal_${ARCH} sslocal
		sslocal_ok=1
	fi

	if [ "${md5sum_ok}" == "1" -a "${sslocal_ok}" == "1" ];then
		check_md5sum
	else
		echo_date "使用备用服务器下载..."
		echo_date "下载失败，请检查你的网络！"
		echo_date "==================================================================="
		return
	fi
}

check_md5sum(){
	cd /tmp/sslocal_bin
	echo_date "校验下载的文件!"
	LOCAL_MD5=$(md5sum sslocal|awk '{print $1}')
	ONLINE_MD5=$(cat md5sum.txt|grep -w sslocal_${ARCH}|awk '{print $1}')
	if [ "${LOCAL_MD5}" == "${ONLINE_MD5}" ];then
		echo_date "文件校验通过!"
		install_binary
	else
		echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
		echo_date "==================================================================="
		return
	fi
}

install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "$(pidof sslocal)" ];then

		CMDS=$(ps|grep sslocal|grep -v grep | grep -Eo "sslocal*.+")

		echo_date "为了保证更新正确，先关闭sslocal主进程... "
		sslocal_process=$(pidof sslocal)
		if [ -n "$sslocal_process" ]; then
			echo_date 关闭sslocal进程...
			killall sslocal >/dev/null 2>&1
			kill -9 $sslocal_process >/dev/null 2>&1
		fi
		move_binary
		if [ -z "${DNLD}" ];then
			start_ss_rust
		fi
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始安装sslocal二进制文件... "
	mv /tmp/sslocal_bin/sslocal /koolshare/bin/sslocal
	chmod +x /koolshare/bin/sslocal
	LOCAL_VER=$(/koolshare/bin/sslocal --version 2>/dev/null | awk '{print $NF}')
	if [ -n "${LOCAL_VER}" ];then
		echo_date "shadowsocks-rust二进制文件:sslocal替换成功... "
	fi
	rm -rf /tmp/sslocal_bin
}

start_ss_rust() {
	if [ "${ss_basic_enable}" == "1" -a "${ss_basic_type}" == "0" -a "${ss_basic_rust}" == "1" ]; then
		echo_date "重启插件！ "
		cd /koolshare/ss
		run sh ssconfig.sh restart
	fi
}

case $1 in
download)
	echo_date "==================================================================="
	echo_date "                shadowsocks-rust程序更新"
	echo_date "==================================================================="
	DNLD="1"
	get_latest_version
	echo_date "==================================================================="
	;;
esac

case $2 in
1)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo_date "                shadowsocks-rust程序更新" | tee -a /tmp/upload/ss_log.txt
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	get_latest_version | tee -a /tmp/upload/ss_log.txt 2>&1
	echo_date "===================================================================" | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	;;
esac