#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
source /koolshare/scripts/ss_node_common.sh
#alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOG_FILE=/tmp/upload/ss_log.txt

prepare_download_dir(){
	mkdir -p /tmp/files
	ln -snf /tmp/files /koolshare/webs/files
}

with_download_job_lock(){
	local lock_name="$1"
	shift
	local lock_dir="/tmp/${lock_name}.lock"
	local pid_file="${lock_dir}/pid"
	local owner_pid=""

	while ! mkdir "${lock_dir}" 2>/dev/null
	do
		owner_pid=""
		[ -f "${pid_file}" ] && owner_pid=$(cat "${pid_file}" 2>/dev/null)
		if [ -n "${owner_pid}" ] && ! kill -0 "${owner_pid}" 2>/dev/null; then
			rm -rf "${lock_dir}"
			continue
		fi
		echo_date "检测到相同导出任务已在进行，复用当前导出任务..." >&2
		return 2
	done

	echo "$$" > "${pid_file}"
	[ -n "${LOG_FILE}" ] && true > "${LOG_FILE}"
	"$@"
	local ret=$?
	rm -rf "${lock_dir}"
	return "${ret}"
}

report_export_progress(){
	echo_date "$1" >&2
}

generate_download_file_atomically(){
	local target_file="$1"
	local tmp_file="$2"
	shift 2

	[ -n "${target_file}" ] || return 1
	[ -n "${tmp_file}" ] || return 1

	rm -f "${target_file}" "${tmp_file}"
	if "$@" "${tmp_file}"; then
		mv -f "${tmp_file}" "${target_file}"
	else
		local ret=$?
		rm -f "${tmp_file}" "${target_file}"
		return "${ret}"
	fi
}

generate_legacy_backup_file(){
	local output_file="$1"
	echo_date "开始生成旧版兼容配置..." >&2
	fss_export_legacy_backup "${output_file}" report_export_progress
	echo_date "旧版兼容配置生成完成，准备下载..." >&2
}

generate_native_backup_file(){
	local output_file="$1"
	echo_date "开始生成新版本JSON配置..." >&2
	fss_export_native_backup "${output_file}"
	echo_date "新版本JSON配置生成完成，准备下载..." >&2
}

backup_conf(){
	prepare_download_dir
	with_download_job_lock "fancyss_export_legacy" \
		generate_download_file_atomically \
			"/tmp/files/ssconf_backup.sh" \
			"/tmp/files/.ssconf_backup.sh.tmp.$$" \
			generate_legacy_backup_file
}

backup_conf_json(){
	prepare_download_dir
	with_download_job_lock "fancyss_export_json" \
		generate_download_file_atomically \
			"/tmp/files/ssconf_backup_v2.json" \
			"/tmp/files/.ssconf_backup_v2.json.tmp.$$" \
			generate_native_backup_file
}

backup_tar(){
	prepare_download_dir
	echo_date "开始打包..."
	cd /tmp
	mkdir shadowsocks
	mkdir shadowsocks/bin
	mkdir shadowsocks/scripts
	mkdir shadowsocks/webs
	mkdir shadowsocks/res
	echo_date "请等待一会儿..."
	local pkg_name=$(get_pkg_name)
	local pkg_arch=$(get_pkg_arch)
	local pkg_type=$(get_pkg_type)
	local pkg_exta=$(get_pkg_exta)
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

list_ss_clearable_keys(){
	dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" | grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"
}

clear_ss_config_storage(){
	local confs conf_count node_count
	confs=$(list_ss_clearable_keys)
	conf_count=$(printf '%s
' "${confs}" | sed '/^$/d' | awk 'END{print NR + 0}')
	node_count=$(fss_get_node_count)
	[ -z "${node_count}" ] && node_count=0

	echo_date "开始清理科学上网配置..."
	echo_date "检测到可清理配置 ${conf_count} 项，节点 ${node_count} 个。"
	for conf in ${confs}
	do
		dbus remove "${conf}"
	done
	fss_clear_v2_nodes
	echo_date "旧配置清理完成：普通配置 ${conf_count} 项，节点 ${node_count} 个。"
}

remove_now(){
	# 1. 关闭插件
	echo_date "尝试关闭科学上网..."
	dbus set ss_basic_enable="0"
	sh /koolshare/ss/ssconfig.sh stop

	# 2. 清空配置
	clear_ss_config_storage
	
	# 2. 设置默认值
	echo_date "设置一些默认参数..."

	# default values
	eval $(dbus export ss)
	local PKG_TYPE=$(get_pkg_type)

	[ -z "${ss_basic_proxy_newb}" ] && dbus set ss_basic_proxy_newb=1
	[ -z "${ss_basic_proxy_ipv6}" ] && dbus set ss_basic_proxy_ipv6=0
	[ -z "${ss_basic_udpoff}" ] && dbus set ss_basic_udpoff=0
	[ -z "${ss_basic_udpall}" ] && dbus set ss_basic_udpall=0
	[ -z "${ss_basic_udpgpt}" ] && dbus set ss_basic_udpgpt=1
	[ -z "${ss_basic_nonetcheck}" ] && dbus set ss_basic_nonetcheck=1
	[ -z "${ss_basic_notimecheck}" ] && dbus set ss_basic_notimecheck=1
	[ -z "${ss_basic_nocdnscheck}" ] && dbus set ss_basic_nocdnscheck=1
	[ -z "${ss_basic_nofdnscheck}" ] && dbus set ss_basic_nofdnscheck=1
	[ -z "${ss_basic_qrcode}" ] && dbus set ss_basic_qrcode=1

	# others
	fss_cleanup_acl_default_port_keys >/dev/null 2>&1
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=follow
	[ -z "$(dbus get ss_acl_default_mode_format)" ] && dbus set ss_acl_default_mode_format=2
	[ -z "$(dbus get ss_acl_default_udp)" ] && dbus set ss_acl_default_udp=0
	[ -z "$(dbus get ss_acl_default_quic)" ] && dbus set ss_acl_default_quic=1
	[ -z "$(dbus get ss_acl_default_ports)" ] && dbus set ss_acl_default_ports="22,80,443,8080,8443"
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	[ -z "$(dbus get ss_basic_furl)" ] && dbus set ss_basic_furl="http://www.google.com/generate_204"
	[ -z "$(dbus get ss_basic_curl)" ] && dbus set ss_basic_curl="http://connectivitycheck.platform.hicloud.com/generate_204"

	# fancyss_arm 默认关闭延迟测试
	PKG_ARCH=$(get_pkg_arch)
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
	clear_ss_config_storage
	echo_date "设置一些默认参数..."
	dbus set ss_basic_version_local=$(cat /koolshare/ss/version) 
	echo_date "--------------------"
}

restore_sh(){
	echo_date "检测到科学上网备份文件..."
	echo_date "开始恢复配置..."
	echo_date "兼容SH备份恢复耗时可能较长，请耐心等待..."
	chmod +x /tmp/upload/ssconf_backup.sh
	if fss_restore_legacy_backup_sh_fast /tmp/upload/ssconf_backup.sh; then
		echo_date "兼容SH备份快速恢复完成！"
	else
		echo_date "快速恢复失败，回退到兼容恢复模式..."
		echo_date "开始执行备份脚本..."
		sh /tmp/upload/ssconf_backup.sh
		echo_date "备份脚本执行完成，开始迁移节点数据..."
		if fss_auto_migrate_if_needed 1 >/dev/null 2>&1; then
			echo_date "节点数据迁移完成！"
		else
			echo_date "节点数据迁移未执行或无需迁移，继续..."
		fi
	fi
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=$(cat /koolshare/ss/version) 
	fss_refresh_node_direct_cache >/dev/null 2>&1
	fss_schedule_webtest_cache_warm >/dev/null 2>&1
	echo_date "配置恢复成功！"
}

restore_json(){
	echo_date "检测到科学上网JSON备份文件..."
	echo_date "开始恢复JSON备份..."
	echo_date "JSON备份恢复期间可能耗时较长，请耐心等待..."
	if fss_restore_native_backup_v2 /tmp/upload/ssconf_backup.json; then
		dbus set ss_basic_enable="0"
		dbus set ss_basic_version_local=$(cat /koolshare/ss/version)
		fss_refresh_node_direct_cache >/dev/null 2>&1
		fss_schedule_webtest_cache_warm >/dev/null 2>&1
		echo_date "JSON备份恢复成功！"
	else
		echo_date "JSON备份恢复失败！请检查备份文件格式是否正确。"
		return 1
	fi
}

restore_now(){
	local json_file="/tmp/upload/ssconf_backup.json"
	local sh_file="/tmp/upload/ssconf_backup.sh"
	local latest_file="" restore_rc=0

	if [ -f "${json_file}" ] && [ -f "${sh_file}" ];then
		latest_file=$(ls -1t "${json_file}" "${sh_file}" 2>/dev/null | sed -n '1p')
		if [ "${latest_file}" = "${sh_file}" ];then
			echo_date "同时检测到JSON和兼容SH备份文件，按最新上传的兼容SH备份处理..."
			restore_sh || restore_rc=$?
		else
			echo_date "同时检测到JSON和兼容SH备份文件，按最新上传的JSON备份处理..."
			restore_json || restore_rc=$?
		fi
	elif [ -f "${json_file}" ];then
		restore_json || restore_rc=$?
	elif [ -f "${sh_file}" ];then
		restore_sh || restore_rc=$?
	else
		echo_date "没有检测到可恢复的备份文件！"
		restore_rc=1
	fi
	echo_date "一点点清理工作..."
	rm -rf /tmp/ss_conf_*
	rm -f "${json_file}" "${sh_file}"
	echo_date "完成！"
	return "${restore_rc}"
}

reomve_ping(){
	# schema 1 stores runtime fields as split KVs; schema 2 stores them inside node json.
	fss_clear_all_runtime_fields
}

report_migration_progress(){
	echo_date "$1"
}

migrate_schema2_now(){
	echo_date "检测到旧版节点数据，开始升级到 schema 2 存储..."
	fss_auto_migrate_if_needed 1 report_migration_progress
	local rc=$?
	case "${rc}" in
	0)
		echo_date "节点数据迁移完成！"
		return 0
		;;
	2)
		echo_date "当前没有可迁移的旧版节点数据，跳过。"
		return 0
		;;
	*)
		echo_date "节点数据迁移失败！保留旧版节点结构。"
		return 1
		;;
	esac
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
	if [ "${ws_flag}" == "0" ];then
		backup_conf >> ${LOG_FILE} 2>&1
		ret=$?
		[ "${ret}" != "2" ] && echo XU6J03M6 >> ${LOG_FILE}
		http_response "$1"
	else
		backup_conf 2>&1 | tee -a ${LOG_FILE}
		echo XU6J03M6 | tee -a ${LOG_FILE}
	fi
	;;
12)
	if [ "${ws_flag}" == "0" ];then
		backup_conf_json >> ${LOG_FILE} 2>&1
		ret=$?
		[ "${ret}" != "2" ] && echo XU6J03M6 >> ${LOG_FILE}
		http_response "$1"
	else
		backup_conf_json 2>&1 | tee -a ${LOG_FILE}
		echo XU6J03M6 | tee -a ${LOG_FILE}
	fi
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
	if [ "${ws_flag}" == "0" ];then
		http_response "$1"
		remove_now >> ${LOG_FILE}
		echo XU6J03M6 >> ${LOG_FILE}
	else
		remove_now | tee -a ${LOG_FILE}
		echo XU6J03M6 | tee -a ${LOG_FILE}
	fi
	;;
4)
	true > ${LOG_FILE}
	if [ "${ws_flag}" == "0" ];then
		http_response "$1"
		remove_silent >> ${LOG_FILE}
		restore_now >> ${LOG_FILE}
		echo XU6J03M6 >> ${LOG_FILE}
	else
		remove_silent | tee -a ${LOG_FILE}
		restore_now | tee -a ${LOG_FILE}
		echo XU6J03M6 | tee -a ${LOG_FILE}
	fi
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
	if [ "${ws_flag}" == "0" ];then
		http_response "$1"
		restart_dnsmasq >> ${LOG_FILE}
		echo XU6J03M6 >> ${LOG_FILE}
	else
		restart_dnsmasq | tee -a ${LOG_FILE}
		echo XU6J03M6 | tee -a ${LOG_FILE}
	fi
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
migrate_schema2)
	true > ${LOG_FILE}
	http_response "$1"
	migrate_schema2_now >> ${LOG_FILE} 2>&1
	echo XU6J03M6 >> ${LOG_FILE}
	;;
esac
