#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
#alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOG_FILE=/tmp/upload/ss_log.txt

backup_conf(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	dbus list ss | grep -v "ss_basic_enable" | grep -v "ssid_" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 isource /koolshare/scripts/base.sh' |sed '1 i#!/bin/sh' > /koolshare/webs/files/ssconf_backup.sh
}

backup_tar(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	echo_date "开始打包..."
	cd /tmp
	mkdir shadowsocks
	mkdir shadowsocks/bin
	mkdir shadowsocks/scripts
	mkdir shadowsocks/webs
	mkdir shadowsocks/res
	echo_date "请等待一会儿..."
	local pkg_name=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_NAME=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_exta=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_EXTA=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_vers=$(dbus get ss_basic_version_local)
	local _pkg_name=${pkg_name}_${pkg_arch}_${pkg_type}${pkg_exta}
	TARGET_FOLDER=/tmp/shadowsocks
	cp /koolshare/scripts/ss_install.sh ${TARGET_FOLDER}/install.sh
	cp /koolshare/scripts/uninstall_shadowsocks.sh ${TARGET_FOLDER}/uninstall.sh
	cp /koolshare/scripts/ss_* ${TARGET_FOLDER}/scripts/
	# binary
	cp /koolshare/bin/isutf8 ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/obfs-local ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/rss-local ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/rss-redir ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/smartdns ${TARGET_FOLDER}/bin/
	if [ -x "/koolshare/bin/dns_cache_mgr" ];then
		cp /koolshare/bin/dns_cache_mgr ${TARGET_FOLDER}/bin/
	fi
	cp /koolshare/bin/chinadns-ng ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/sponge ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/jq ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/xray ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/curl-fancyss ${TARGET_FOLDER}/bin/
	cp /koolshare/bin/dnsclient ${TARGET_FOLDER}/bin/
	if [ -f "/koolshare/bin/sslocal" ];then
		cp /koolshare/bin/sslocal ${TARGET_FOLDER}/bin/
	fi
	if [ -x "/koolshare/bin/websocketd" ];then
		cp /koolshare/bin/websocketd ${TARGET_FOLDER}/bin/
	fi
	if [ "${pkg_type}" != "lite" ];then
		cp /koolshare/bin/dohclient ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/dohclient-cache ${TARGET_FOLDER}/bin/
		#cp /koolshare/bin/smartdns ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/v2ray ${TARGET_FOLDER}/bin/
		[ -f "/koolshare/bin/haveged" ] && cp /koolshare/bin/haveged ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/ipt2socks ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/naive ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/tuic-client ${TARGET_FOLDER}/bin/
		[ -f "/koolshare/bin/tuic-client" ] && cp /koolshare/bin/tuic-client ${TARGET_FOLDER}/bin/
		cp /koolshare/bin/hysteria2 ${TARGET_FOLDER}/bin/
	fi
	cp /koolshare/webs/Module_shadowsocks*.asp ${TARGET_FOLDER}/webs/
	# others
	cp /koolshare/res/arrow-down.gif ${TARGET_FOLDER}/res/
	cp /koolshare/res/arrow-up.gif ${TARGET_FOLDER}/res/
	cp /koolshare/res/accountadd.png ${TARGET_FOLDER}/res/
	cp /koolshare/res/accountdelete.png ${TARGET_FOLDER}/res/
	cp /koolshare/res/accountedit.png ${TARGET_FOLDER}/res/
	cp /koolshare/res/icon-shadowsocks.png ${TARGET_FOLDER}/res/
	cp /koolshare/res/ss-menu.js ${TARGET_FOLDER}/res/
	cp /koolshare/res/tablednd.js ${TARGET_FOLDER}/res/
	cp /koolshare/res/qrcode.js ${TARGET_FOLDER}/res/
	cp /koolshare/res/fancyss.css ${TARGET_FOLDER}/res/
	cp -r /koolshare/ss ${TARGET_FOLDER}/
	rm -rf ${TARGET_FOLDER}/ss/*.json
	rm -rf ${TARGET_FOLDER}/ss/*.conf
	rm -rf ${TARGET_FOLDER}/ss/*.yaml
	# arch
	echo ${pkg_arch} > ${TARGET_FOLDER}/.valid
	tar -czv -f /tmp/shadowsocks.tar.gz shadowsocks/
	rm -rf ${TARGET_FOLDER}
	mv /tmp/shadowsocks.tar.gz /tmp/files

	if [ -n "${_pkg_name}" -a -n "${pkg_vers}" ];then
		echo_date "打包文件名：${_pkg_name}_${pkg_vers}.tar.gz"
		ln -sf /tmp/files/shadowsocks.tar.gz /tmp/files/${_pkg_name}_${pkg_vers}.tar.gz
	fi
	echo_date "打包完毕！"
}

remove_now(){
	# 1. 关闭插件
	echo_date "尝试关闭科学上网..."
	dbus set ss_basic_enable="0"
	sh /koolshare/ss/ssconfig.sh stop

	# 2. 清空配置
	echo_date "开始清理科学上网配置..."
	confs=$(dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign")
	for conf in $confs
	do
		echo_date "移除$conf"
		dbus remove $conf
	done
	
	# 2. 设置默认值
	echo_date "设置一些默认参数..."

	# default values
	eval $(dbus export ss)
	local PKG_TYPE=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')

	[ -z "${ss_basic_proxy_newb}" ] && dbus set ss_basic_proxy_newb=1
	[ -z "${ss_basic_proxy_ipv6}" ] && dbus set ss_basic_proxy_ipv6=0
	[ -z "${ss_basic_udpoff}" ] && dbus set ss_basic_udpoff=0
	[ -z "${ss_basic_udpall}" ] && dbus set ss_basic_udpall=0
	[ -z "${ss_basic_udpgpt}" ] && dbus set ss_basic_udpgpt=1
	[ -z "${ss_basic_nonetcheck}" ] && dbus set ss_basic_nonetcheck=1
	[ -z "${ss_basic_notimecheck}" ] && dbus set ss_basic_notimecheck=1
	[ -z "${ss_basic_nocdnscheck}" ] && dbus set ss_basic_nocdnscheck=1
	[ -z "${ss_basic_nofdnscheck}" ] && dbus set ss_basic_nofdnscheck=1
	
	# others
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=2
	[ -z "$(dbus get ss_acl_default_udp)" ] && dbus set ss_acl_default_udp=0
	[ -z "$(dbus get ss_acl_default_quic)" ] && dbus set ss_acl_default_quic=1
	[ -z "$(dbus get ss_acl_default_ports)" ] && dbus set ss_acl_default_ports="22,80,443,8080,8443"
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	[ -z "$(dbus get ss_basic_furl)" ] && dbus set ss_basic_furl="http://www.gstatic.com/generate_204"
	[ -z "$(dbus get ss_basic_curl)" ] && dbus set ss_basic_curl="http://connectivitycheck.platform.hicloud.com/generate_204"

	# fancyss_arm 默认关闭延迟测试
	PKG_ARCH=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+" | awk -F"=" '{print $2}' | sed 's/"//g')
	if [ "${PKG_ARCH}" == "arm" ];then
		[ -z "${ss_basic_latency_opt}" ] && dbus set ss_basic_latency_opt="0"
	else
		[ -z "${ss_basic_latency_opt}" ] && dbus set ss_basic_latency_opt="2"
	fi
	
	# lite
	if [ ! -x "/koolshare/bin/v2ray" ];then
		dbus set ss_basic_vcore=1
	else
		dbus set ss_basic_vcore=0
	fi
	
	if [ ! -x "/koolshare/bin/trojan" ];then
		dbus set ss_basic_tcore=1
	else
		dbus set ss_basic_tcore=0
	fi

	echo_date "设置完毕"
}

remove_silent(){
	echo_date "先清除已有的参数..."
	confs=$(dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign")
	for conf in $confs
	do
		echo_date "移除$conf"
		dbus remove $conf
	done
	echo_date "设置一些默认参数..."
	dbus set ss_basic_version_local=$(cat /koolshare/ss/version) 
	echo_date "--------------------"
}

restore_sh(){
	echo_date "检测到科学上网备份文件..."
	echo_date "开始恢复配置..."
	chmod +x /tmp/upload/ssconf_backup.sh
	sh /tmp/upload/ssconf_backup.sh
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=$(cat /koolshare/ss/version) 
	echo_date "配置恢复成功！"
}

restore_now(){
	[ -f "/tmp/upload/ssconf_backup.sh" ] && restore_sh
	echo_date "一点点清理工作..."
	rm -rf /tmp/ss_conf_*
	echo_date "完成！"
}

reomve_ping(){
	# flush previous ping value in the table
	pings=$(dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1)
	if [ -n "$pings" ];then
		for ping in $pings
		do
			echo "remove $ping"
			dbus remove "$ping"
		done
	fi
}

download_ssf(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	if [ -f "/tmp/upload/ssf_status.txt" ];then
		cp -rf /tmp/upload/ssf_status.txt /tmp/files/ssf_status.txt
	else
		echo "日志为空" > /tmp/files/ssf_status.txt
	fi
}

download_ssc(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	if [ -f "/tmp/upload/ssc_status.txt" ];then
		cp -rf /tmp/upload/ssc_status.txt /tmp/files/ssc_status.txt
	else
		echo "日志为空" > /tmp/files/ssc_status.txt
	fi
}

restart_dnsmasq(){
	echo_date "重启dnsmasq..."
	local OLD_PID=$(pidof dnsmasq)
	if [ -n "${OLD_PID}" ];then
		echo_date "当前dnsmasq正常运行中，pid: ${OLD_PID}，准备重启！"
	else
		echo_date "当前dnsmasq未运行，尝试重启！"
	fi
	
	service restart_dnsmasq >/dev/null 2>&1

	local DPID
	local i=50
	until [ -n "${DPID}" ]; do
		i=$(($i - 1))
		DPID=$(pidof dnsmasq)
		if [ "$i" -lt 1 ]; then
			echo_date "dnsmasq重启失败，请检查你的dnsmasq配置！"
		fi
		usleep 250000
	done
	echo_date "dnsmasq重启成功，pid: ${DPID}"
}

restart_chinadnsng(){
	local CHNG_PID=$(pidof chinadns-ng)
	if [ -n "${CHNG_PID}" ];then
		echo_date "当前chinadns-ng正常运行中，pid: ${CHNG_PID}，准备重启！"
		killall chinadns-ng >/dev/null 2>&1
		kill -9 ${CHNG_PID} >/dev/null 2>&1
	fi
	
	local OLD_PID=$(pidof smartdns)
	if [ -n "${OLD_PID}" ];then
		echo_date "当前smartdns正常运行中，pid: ${OLD_PID}，准备关闭！"
		kill ${OLD_PID}
	else
		echo_date "尝试启动chinadns-ng...！"
	fi
	sh /koolshare/ss/ssconfig.sh restart_chinadns_ng
	echo XU6J03M6
}

start_smartdns(){
	local idx=$1
	local conf_name=smartdns_smrt_$idx
	local save_path=/koolshare/ss/rules
	local show_path=/tmp/upload
	local conf_path=/tmp
	local smartdns_conf
	local ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
	local ISP_DNS2=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 2p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")

	# remove previous file
	rm -rf /tmp/smartdns_log.txt
	rm -rf /tmp/smartdns_audit.txt

	# gen list for smartdns conf
	cat /koolshare/ss/rules/chnroute.txt | sed 's/^/whitelist-ip /g' >/tmp/whitelist_ip.txt

	# copy smartdns conf file
	if [ -f ${save_path}/${conf_name}_user.conf ];then
		local smartdns_conf=${conf_path}/${conf_name}_user.conf
		echo_date "复制smartdns配置文件：${save_path}/${conf_name}_user.conf → ${conf_path}"
		cp -rf ${save_path}/${conf_name}_user.conf ${smartdns_conf}
	else
		echo_date "复制smartdns配置文件：${save_path}/${conf_name}.conf → ${conf_path}"
		local smartdns_conf=${conf_path}/${conf_name}.conf
		cp -rf ${save_path}/${conf_name}.conf ${smartdns_conf}
	fi

	# modify smartdns conf file
	if [ "${ss_basic_dns_serverx}" == "1" ];then
		echo_date "编辑smartdns配置文件：${smartdns_conf}，监听端口7913 → 53，以替换dnsmasq！"
		sed -i 's/7913/53/g' ${smartdns_conf}
	fi

	if [ "${ss_basic_add_ispdns}" == "1" ];then
		if [ -n "${ISP_DNS1}" ]; then
			echo_date "编辑smartdns配置文件：${smartdns_conf}，追加ISP DNS: ${ISP_DNS1}"
			sed -i "s/117.50.10.10/${ISP_DNS1}/g" ${smartdns_conf} 2>/dev/null
		fi
		
		if [ -n "${ISP_DNS2}" ]; then
			echo_date "编辑smartdns配置文件：${smartdns_conf}，追加ISP DNS: ${ISP_DNS2}"
			sed -i "s/117.50.60.30/${ISP_DNS2}/g" ${smartdns_conf} 2>/dev/null
		fi
	fi

	# start smartdns	
	echo_date "启动smartdns，使用smartdns配置文件：${smartdns_conf}"
	run_bg smartdns -c ${smartdns_conf}
	detect_running_status3 "smartdns" "53|7913" "0" "force"

	# detect process by binary name and key word
	local caches=$(head /tmp/smartdns_log.txt 2>/dev/null | grep "load cache file" | awk '{print $(NF-1)}')
	if [ -n "${caches}" ];then
		echo_date "smartdns启动成功，成功加载缓存：${caches}条"
	else
		echo_date "smartdns启动成功!"
	fi
}

restart_smartdns(){
	local CHNG_PID=$(pidof chinadns-ng)
	if [ -n "${CHNG_PID}" ];then
		echo_date "当前chinadns-ng正常运行中，pid: ${CHNG_PID}，准备关闭！"
		killall chinadns-ng >/dev/null 2>&1
		kill -9 ${CHNG_PID} >/dev/null 2>&1
	fi
		
	local OLD_PID=$(pidof smartdns)
	if [ -n "${OLD_PID}" ];then
		echo_date "当前smartdns正常运行中，pid: ${OLD_PID}，准备重启！"
		kill ${OLD_PID}
	else
		echo_date "尝试启动smartdns！"
	fi

	start_smartdns ${ss_basic_smrt}

	# sleep 1
	# if [ -f "/tmp/smartdns_log.txt" ];then
	# 	echo_date "--------------------------------------------------------"
	# 	echo_date "smartdns 启动日志如下:"
	# 	cat /tmp/smartdns_log.txt | awk -F "] " '{print $NF}'
	# fi
	# run end
	echo XU6J03M6
}
# 1. ----------------------------------------------------
edit_smartdns_conf(){
	local flag=$1
	local idx=$2
	local temp_path=/tmp
	local save_path=/koolshare/ss/rules
	local show_path=/tmp/upload
	local conf_name=smartdns_smrt_$idx
	local user_conf=${conf_name}_user
	local ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
	local ISP_DNS2=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 2p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")

	if [ "${flag}" == "edit" ];then
	
		if [ -f "${save_path}/${user_conf}.conf" ];then
			cp -f ${save_path}/${user_conf}.conf ${show_path}/${conf_name}.conf
			http_response "11111111" >/dev/null
		else
			cp -f ${save_path}/${conf_name}.conf ${show_path}/${conf_name}.conf
			http_response "22222222" >/dev/null
		fi
	fi

	if [ "${flag}" == "save" ];then
		http_response "$ID" >/dev/null
		local conf_rule=$(dbus get ss_basic_smartdns_rule)
		if [ -n "${conf_rule}" ];then
			echo ${conf_rule} | base64_decode | sed 's/\\n/\n/g' > ${temp_path}/${user_conf}.conf
			local md5sum_default=$(md5sum ${save_path}/${conf_name}.conf | awk '{print $1}')
			local md5sum_usernew=$(md5sum ${temp_path}/${user_conf}.conf | awk '{print $1}')
			if [ -f "${save_path}/${user_conf}.conf" ];then
				local md5sum_userold=$(md5sum ${save_path}/${user_conf}.conf | awk '{print $1}')
				if [ "${md5sum_userold}" == "${md5sum_usernew}" ];then
					rm -rf ${temp_path}/${user_conf}.conf
					echo_date "配置文件相较于之前的自定义配置无变化，不保存！"
				else
					echo_date "保存新配置到${save_path}/${user_conf}.conf"
					mv -f ${temp_path}/${user_conf}.conf ${save_path}/${user_conf}.conf
					cp -f ${save_path}/${user_conf}.conf ${show_path}/${conf_name}.conf
					dbus remove ss_basic_smartdns_rule
					echo_date "保存成功！请重启科学上网插件，使用新配置！"
				fi
			else
				if [ "${md5sum_default}" == "${md5sum_usernew}" ];then
					rm -rf ${temp_path}/${user_conf}.conf
					rm -rf ${save_path}/${user_conf}.conf
					echo_date "配置文件相较于默认配置无变化，不保存为自定义配置，继续使用默认配置！"
				else
					echo_date "保存新配置到${save_path}/${user_conf}.conf"
					mv ${temp_path}/${user_conf}.conf ${save_path}/${user_conf}.conf
					cp -f ${save_path}/${user_conf}.conf ${show_path}/${conf_name}.conf
					dbus remove ss_basic_smartdns_rule
					echo_date "保存成功！请重启科学上网插件，使用新配置！"
				fi
			fi
		else
			echo_date "检测到新配置为空，不保存！"
		fi
		echo XU6J03M6 >> ${LOG_FILE}
	fi

	if [ "${flag}" == "reset" ];then
		http_response "$ID" >/dev/null
		if [ -f "${save_path}/${user_conf}.conf" ];then
			echo_date "切换到smartdns默认配置！"
			rm -f ${save_path}/${user_conf}.conf
			cp -f ${save_path}/${conf_name}.conf ${show_path}/${conf_name}.conf
			echo_date "切换成功！请重启科学上网插件，以使用默认配置！"
		else
			echo_date "当前使用的即为默认配置，无需恢复，退出！"
		fi
		echo XU6J03M6 >> ${LOG_FILE}
	fi
}

download_resv_log(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	local FILE_NAME=$(dbus get ss_basic_logname)
	local TIME_NOW=$(date -R +%Y%m%d_%H%M%S)
	cp -rf /tmp/upload/${FILE_NAME}.txt /tmp/files/${FILE_NAME}.txt
}

download_dig_log(){
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files
	cp -rf /tmp/upload/dns_dig_result.txt /tmp/files/dns_dig_result.txt
	sed -i '/XU6J03M6/d' /tmp/files/dns_dig_result.txt
}

if [ -n "$1" -a -z "$2" ];then
	# run by ws
	act=$1
	ws_flag=1
elif [ -n "$1" -a -n "$2" ];then
	# run by httpd
	act=$2
	ws_flag=0
elif [ -z "$1" -a -z "$2" ];then
	echo_date "缺少运行参数！"
	exit
fi

if [ -z "$1" -a -z "$2" ];then
	prepare
	get_china_status $1
	get_foreign_status $1
	echo "${log1}@@${log2}"
	exit
fi

case $act in
1)
	true > ${LOG_FILE}
	backup_conf
	http_response "$1"
	;;
2)
	true > ${LOG_FILE}
	backup_tar >> ${LOG_FILE}
	sleep 1
	http_response "$1"
	sleep 2	
	echo XU6J03M6 >> ${LOG_FILE}
	;;
3)
	true > ${LOG_FILE}
	http_response "$1"
	remove_now >> ${LOG_FILE}
	echo XU6J03M6 >> ${LOG_FILE}
	;;
4)
	true > ${LOG_FILE}
	http_response "$1"
	remove_silent >> ${LOG_FILE}
	restore_now >> ${LOG_FILE}
	echo XU6J03M6 >> ${LOG_FILE}
	;;
5)
	reomve_ping
	;;
6)
	true > ${LOG_FILE}
	download_ssf
	http_response "$1"
	;;
7)
	true > ${LOG_FILE}
	download_ssc
	http_response "$1"
	;;
8)
	true > ${LOG_FILE}
	http_response "$1"
	restart_dnsmasq >> ${LOG_FILE}
	echo XU6J03M6 >> ${LOG_FILE}
	;;
10)
	true > ${LOG_FILE}
	download_resv_log
	http_response "$1"
	;;
11)
	true > ${LOG_FILE}
	download_dig_log
	http_response "$1"
	;;
restart_chng)
	true > ${LOG_FILE}
	[ "${ws_flag}" == "0" ] && http_response "$1"
	restart_chinadnsng | tee -a ${LOG_FILE}
	;;
restart_smrt)
	true > ${LOG_FILE}
	[ "${ws_flag}" == "0" ] && http_response "$1"
	restart_smartdns | tee -a ${LOG_FILE}
	;;
edit_smartdns_smrt_*)
	order=${2##*_}
	edit_smartdns_conf edit ${order} >> ${LOG_FILE}
	;;
save_smartdns_smrt_*)
	order=${2##*_}
	true > ${LOG_FILE}
	edit_smartdns_conf save ${order} >> ${LOG_FILE}
	;;
reset_smartdns_smrt_*)
	order=${2##*_}
	true > ${LOG_FILE}
	edit_smartdns_conf reset ${order} >> ${LOG_FILE}
	;;
esac
