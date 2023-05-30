#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
RULE_FILE=/koolshare/ss/rules/rules.json.js
URL_MAIN="https://raw.githubusercontent.com/hq450/fancyss/3.0/rules"

run(){
	env -i PATH=${PATH} "$@"
}

start_update(){
	# 1. 检测规则版本号文件
	if [ ! -f ${RULE_FILE} ];then
		echo_date "没有找到规则版本号文件: rules.json.js！请尝试覆盖安装插件解决！退出！"
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
		exit
	fi
	
	# 2. 检测规则本地版本号
	version_gfw_local=$(cat ${RULE_FILE} | run jq -r '.gfwlist.date' | sed 's/[[:space:]]/_/g')
	version_chn_local=$(cat ${RULE_FILE} | run jq -r '.chnroute.date' | sed 's/[[:space:]]/_/g')
	version_cdn_local=$(cat ${RULE_FILE} | run jq -r '.cdn_china.date' | sed 's/[[:space:]]/_/g')
	if [ -z ${version_gfw_local} -o -z ${version_chn_local} -o -z ${version_cdn_local} -o ];then
		echo_date "没有找到规则版本号！退出！"
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

	# 6. 获取在线版本及其它信息
	version_gfw_online=$(cat /tmp/rules.json.js | run jq -r '.gfwlist.date' | sed 's/[[:space:]]/_/g')
	version_chn_online=$(cat /tmp/rules.json.js | run jq -r '.chnroute.date' | sed 's/[[:space:]]/_/g')
	version_cdn_online=$(cat /tmp/rules.json.js | run jq -r '.cdn_china.date' | sed 's/[[:space:]]/_/g')
	
	md5sum_gfw_online=$(cat /tmp/rules.json.js | run jq -r '.gfwlist.md5')
	md5sum_chn_online=$(cat /tmp/rules.json.js | run jq -r '.chnroute.md5')
	md5sum_cdn_online=$(cat /tmp/rules.json.js | run jq -r '.cdn_china.md5')

	count_gfw_online=$(cat /tmp/rules.json.js | run jq -r '.gfwlist.count')
	count_chn_online=$(cat /tmp/rules.json.js | run jq -r '.chnroute.count')
	count_ip_chn_online=$(cat /tmp/rules.json.js | run jq -r '.chnroute.count_ip')
	count_cdn_online=$(cat /tmp/rules.json.js | run jq -r '.cdn_china.count')
	
	# update gfwlist
	if [ "${ss_basic_gfwlist_update}" == "1" ];then
		echo_date "--------------------------------------------------------------------"
		if [ "${version_gfw_local}" != "${version_gfw_online}" ];then
			echo_date "检测到新版本gfwlist，开始更新..."
			echo_date "下载gfwlist到临时文件..."
			wget -4 --no-check-certificate --timeout=8 -qO - ${URL_MAIN}/gfwlist.conf > /tmp/gfwlist.conf
			md5sum_gfwlist_local=$(md5sum /tmp/gfwlist.conf | awk '{print $1}')
			if [ "${md5sum_gfwlist_local}" == "${md5sum_gfw_online}" ];then
				echo_date "下载完成，校验通过，将临时文件覆盖到原始gfwlist文件"
				local version_gfw_online_tmp="$(echo ${version_gfw_online} | sed 's/_/ /g')"
				mv /tmp/gfwlist.conf /koolshare/ss/rules/gfwlist.conf
				run jq --arg variable "${version_gfw_online_tmp}" '.gfwlist.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${md5sum_gfw_online}" '.gfwlist.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${count_gfw_online}" '.gfwlist.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				reboot="1"
				echo_date "【更新成功】你的gfwlist已经更新到最新！"
			else
				echo_date "下载完成，但是校验没有通过！"
			fi
		else
			echo_date "检测到gfwlist本地版本号和在线版本号相同，不进行更新!"
		fi
	else
		echo_date "你并没有勾选gfwlist更新！"
	fi
	
	# update chnroute
	if [ "${ss_basic_chnroute_update}" == "1" ];then
		echo_date "--------------------------------------------------------------------"
		if [ "${version_chn_local}" != "${version_chn_online}" ];then
			echo_date "检测到新版本chnroute，开始更新..."
			echo_date "下载chnroute到临时文件..."
			wget -4 --no-check-certificate --timeout=8 -qO - ${URL_MAIN}/chnroute.txt > /tmp/chnroute.txt
			md5sum_chnroute_local=$(md5sum /tmp/chnroute.txt | awk '{print $1}')
			if [ "${md5sum_chnroute_local}" == "${md5sum_chn_online}" ];then
				echo_date "下载完成，校验通过，将临时文件覆盖到原始chnroute文件"
				local version_chn_online_tmp="$(echo ${version_chn_online} | sed 's/_/ /g')"
				mv /tmp/chnroute.txt /koolshare/ss/rules/chnroute.txt
				run jq --arg variable "${version_chn_online_tmp}" '.chnroute.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${md5sum_chn_online}" '.chnroute.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${count_chn_online}" '.chnroute.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${count_ip_chn_online}" '.chnroute.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				reboot="1"
				echo_date "【更新成功】你的chnroute已经更新到最新！"
			else
				echo_date "下载完成，但是校验没有通过！"
			fi
		else
			echo_date "检测到chnroute本地版本号和在线版本号相同，不进行更新!"
		fi
	else
		echo_date "你并没有勾选chnroute更新！"
	fi
	
	# update cdn file
	if [ "$ss_basic_cdn_update" == "1" ];then
		echo_date "--------------------------------------------------------------------"
		if [ "${version_cdn_local}" != "${version_cdn_online}" ];then
			echo_date "检测到新版本cdn名单，开始更新..."
			echo_date "下载cdn名单到临时文件..."
			wget -4 --no-check-certificate --timeout=8 -qO - ${URL_MAIN}/cdn.txt > /tmp/cdn.txt
			md5sum_cdn_local=$(md5sum /tmp/cdn.txt | awk '{print $1}')
			if [ "${md5sum_cdn_local}" == "${md5sum_cdn_online}" ];then
				echo_date "下载完成，校验通过，将临时文件覆盖到原始cdn名单文件"
				local version_cdn_online_tmp="$(echo ${version_cdn_online} | sed 's/_/ /g')"
				mv /tmp/cdn.txt /koolshare/ss/rules/cdn.txt
				run jq --arg variable "${version_cdn_online_tmp}" '.cdn_china.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${md5sum_cdn_online}" '.cdn_china.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				run jq --arg variable "${count_cdn_online}" '.cdn_china.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
				reboot="1"
				echo_date "【更新成功】你的cdn名单已经更新到最新！"
			else
				echo_date "下载完成，但是校验没有通过！"
			fi
		else
			echo_date "检测到cdn名单本地版本号和在线版本号相同，不进行更新!"
		fi
	else
		echo_date "你并没有勾选cdn名单更新！"
	fi
	echo_date " --------------------------------------------------------------------"
	rm -rf /tmp/rules.json.js
	
	echo_date "规则更新进程运行完毕！"
	# write number
	nvram set update_ipset="$(cat ${RULE_FILE} | run jq -r '.gfwlist.date')"
	nvram set update_chnroute="$(cat ${RULE_FILE} | run jq -r '.chnroute.date')"
	nvram set update_cdn="$(cat ${RULE_FILE} | run jq -r '.cdn_china.date')"
	
	nvram set ipset_numbers="$(cat ${RULE_FILE} | run jq -r '.gfwlist.count')"
	nvram set chnroute_numbers="$(cat ${RULE_FILE} | run jq -r '.chnroute.count')"
	nvram set chnroute_ips="$(cat ${RULE_FILE} | run jq -r '.chnroute.count_ip')"
	nvram set cdn_numbers="$(cat ${RULE_FILE} | run jq -r '.cdn_china.count')"
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

if [ -z "$2" ];then
	#this is for autoupdate
	change_cru
	start_update
fi

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
	ss_basic_cdn_update=1
	change_cru > /tmp/upload/ss_log.txt
	start_update >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac