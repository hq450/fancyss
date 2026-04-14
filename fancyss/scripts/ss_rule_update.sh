#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y%m%d\ %X)】:'
RULE_FILE=/koolshare/ss/rules/rules.json.js
URL_MAIN="https://raw.githubusercontent.com/hq450/fancyss/3.0/rules_ng"

run(){
	env -i PATH=${PATH} "$@"
}

start_update(){
	# 1. 检测规则版本号文件
	if [ ! -f "${RULE_FILE}" ];then
		echo_date "没有找到规则版本号文件: rules.json.js！请尝试覆盖安装插件解决！退出！"
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
		exit
	fi
	run jq --tab . "${RULE_FILE}" >/dev/null 2>&1
	if [ "$?" != "0" ];then
		echo_date "本地规则版本号文件解析失败：${RULE_FILE}！请尝试覆盖安装插件解决！退出！"
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
		exit
	fi

	# 3. 准备下载文件夹
	rm -rf /tmp/fancyss_rule_download
	mkdir /tmp/fancyss_rule_download
	local rule_save_dir=/koolshare/ss/rules
	local rule_down_dir=/tmp/fancyss_rule_download

	# 4. 开始更新
	echo ==================================================================================================
	echo_date "开始更新fancyss规则，请等待..."

	# 5. 先下载版本号文件
	wget -4 --no-check-certificate --timeout=8 -qO - ${URL_MAIN}/rules.json.js > /tmp/rules.json.js
	if [ "$?" == "0" ]; then
		echo_date "检测到在线版本文件，继续..."
	else
		echo_date "没有检测到在线版本，可能是访问github有问题，去大陆白名单模式试试吧！"
		rm -rf /tmp/rules.json.js
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
		exit
	fi
	run jq --tab . /tmp/rules.json.js >/dev/null 2>&1
	if [ "$?" != "0" ];then
		echo_date "在线规则版本号文件解析失败：${URL_MAIN}/rules.json.js！退出！"
		rm -rf /tmp/rules.json.js
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
		exit
	fi


	update_rule() {
		# $1: key in rules.json.js
		# $2: enabled (1/0)
		local key="$1"
		local enabled="$2"

		local online_name online_md5 online_date_cmp online_obj
		local local_date_cmp local_md5
		local tmp_file dst_file tmp_md5

		if [ "${enabled}" != "1" ]; then
			echo_date "你并没有勾选${key}更新！"
			return 0
		fi

		online_name="$(cat /tmp/rules.json.js | run jq -r ".${key}.name")"
		online_md5="$(cat /tmp/rules.json.js | run jq -r ".${key}.md5")"
		online_date_cmp="$(cat /tmp/rules.json.js | run jq -r ".${key}.date" | sed 's/[[:space:]]/_/g')"

		if [ -z "${online_name}" ] || [ "${online_name}" = "null" ]; then
			echo_date "在线版本文件缺少字段：.${key}.name，跳过！"
			return 1
		fi
		if [ -z "${online_md5}" ] || [ "${online_md5}" = "null" ]; then
			echo_date "在线版本文件缺少字段：.${key}.md5，跳过！"
			return 1
		fi
		if [ -z "${online_date_cmp}" ] || [ "${online_date_cmp}" = "null" ]; then
			echo_date "在线版本文件缺少字段：.${key}.date，跳过！"
			return 1
		fi

		local_date_cmp="$(cat ${RULE_FILE} | run jq -r ".${key}.date" | sed 's/[[:space:]]/_/g')"
		local_md5="$(cat ${RULE_FILE} | run jq -r ".${key}.md5")"
		if [ -z "${local_date_cmp}" ] || [ "${local_date_cmp}" = "null" ]; then
			local_date_cmp="0"
		fi
		if [ -z "${local_md5}" ] || [ "${local_md5}" = "null" ]; then
			local_md5="0"
		fi

		echo_date "--------------------------------------------------------------------"
		if [ "${local_date_cmp}" = "${online_date_cmp}" ] && [ "${force_update}" != "1" ]; then
			echo_date "检测到${key}本地版本号和在线版本号相同，不进行更新!"
			return 0
		fi

		echo_date "检测到新版本${key}，开始更新..."
		echo_date "下载${online_name}到临时文件..."

		tmp_file="${rule_down_dir}/${online_name}"
		dst_file="${rule_save_dir}/${online_name}"
		rm -rf "${tmp_file}"

		wget -4 --no-check-certificate --timeout=8 -qO - "${URL_MAIN}/${online_name}" > "${tmp_file}"
		if [ "$?" != "0" ] || [ ! -s "${tmp_file}" ]; then
			echo_date "${online_name}下载失败！"
			rm -rf "${tmp_file}"
			return 1
		fi

		tmp_md5="$(md5sum "${tmp_file}" | awk '{print $1}')"
		if [ "${tmp_md5}" != "${online_md5}" ]; then
			echo_date "下载完成，但校验未通过！本地md5：${tmp_md5}，在线md5：${online_md5}"
			rm -rf "${tmp_file}"
			return 1
		fi

		echo_date "下载完成，校验通过，覆盖到：${dst_file}"
		mv "${tmp_file}" "${dst_file}"

		online_obj="$(cat /tmp/rules.json.js | run jq -c ".${key}")"
		if [ -n "${online_obj}" ] && [ "${online_obj}" != "null" ]; then
			local tmp_rule_json="${rule_down_dir}/rules.${key}.json.js"
			rm -rf "${tmp_rule_json}"
			run jq --argjson obj "${online_obj}" ".${key} = \$obj" "${RULE_FILE}" > "${tmp_rule_json}"
			if [ "$?" != "0" ] || [ ! -s "${tmp_rule_json}" ]; then
				echo_date "更新规则版本号文件失败：${RULE_FILE}（.${key}）"
				rm -rf "${tmp_rule_json}"
				return 1
			fi
			mv "${tmp_rule_json}" "${RULE_FILE}"
		fi

		reboot="1"
		echo_date "【更新成功】你的${key}已经更新到最新！"
		return 0
	}

	# 用户可选更新项（UI上有勾选项）
	update_rule "gfwlist" "${ss_basic_gfwlist_update}"
	update_rule "chnroute" "${ss_basic_chnroute_update}"
	update_rule "chnlist" "${ss_basic_chnlist_update}"

	# 必要/常用规则：无UI开关，默认跟随规则更新
	update_rule "chnroute6" "1"
	update_rule "adslist" "1"
	update_rule "rotlist" "1"
	update_rule "white_list" "1"
	update_rule "black_list" "1"
	update_rule "block_list" "1"
	update_rule "apple_china" "1"
	update_rule "google_china" "1"
	update_rule "cdn_test" "1"

	echo_date " --------------------------------------------------------------------"
	rm -rf /tmp/rules.json.js
	
	echo_date "规则更新进程运行完毕！"
	# write number
	nvram set update_gfwlist="$(cat ${RULE_FILE} | run jq -r '.gfwlist.date')"
	nvram set update_chnroute="$(cat ${RULE_FILE} | run jq -r '.chnroute.date')"
	nvram set update_chnlist="$(cat ${RULE_FILE} | run jq -r '.chnlist.date')"
	
	nvram set gfwlist_numbers="$(cat ${RULE_FILE} | run jq -r '.gfwlist.count')"
	nvram set chnroute_numbers="$(cat ${RULE_FILE} | run jq -r '.chnroute.count')"
	nvram set chnroute_ips="$(cat ${RULE_FILE} | run jq -r '.chnroute.count_ip')"
	nvram set chnlist_numbers="$(cat ${RULE_FILE} | run jq -r '.chnlist.count')"
	#======================================================================
	# reboot fancyss
	if [ "${reboot}" == "1" ];then
		echo_date "自动重启fancyss，以应用新的规则文件！请稍后！"
		run sh /koolshare/ss/ssconfig.sh restart
	fi
	echo ==================================================================================================
}

change_cru(){
	echo ==================================================================================================
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "${ss_basic_rule_update}" ]; then
		echo_date "应用fancyss规则定时更新任务：每天${ss_basic_rule_update_time}:00自动检测更新规则."
		cru a ssupdate "0 ${ss_basic_rule_update_time} * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date "fancyss规则定时更新任务未启用！"
	fi
}

case $1 in
force)
	ss_basic_gfwlist_update=1
	ss_basic_chnroute_update=1
	ss_basic_chnlist_update=1
	force_update=1
	start_update
	;;
update)
	ss_basic_gfwlist_update=1
	ss_basic_chnroute_update=1
	ss_basic_chnlist_update=1
	force_update=0
	start_update
	;;
*)
	change_cru
	start_update
	;;
esac

case $2 in
1)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	change_cru > /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
2)
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	ss_basic_gfwlist_update=1
	ss_basic_chnroute_update=1
	ss_basic_chnlist_update=1
	force_update=0
	change_cru > /tmp/upload/ss_log.txt
	start_update >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac
