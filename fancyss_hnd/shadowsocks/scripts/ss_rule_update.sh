#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

start_update(){
	url_main="https://raw.githubusercontent.com/hq450/fancyss/master/rules"
	url_back=""
	# version dectet
	version_gfwlist1=$(cat /koolshare/ss/rules/version | sed -n 1p | sed 's/ /\n/g'| sed -n 1p)
	version_chnroute1=$(cat /koolshare/ss/rules/version | sed -n 2p | sed 's/ /\n/g'| sed -n 1p)
	version_cdn1=$(cat /koolshare/ss/rules/version | sed -n 4p | sed 's/ /\n/g'| sed -n 1p)
	
	echo ==================================================================================================
	echo_date 开始更新shadowsocks规则，请等待...
	wget --no-check-certificate --timeout=8 -qO - "$url_main"/version1 > /tmp/ss_version
	if [ "$?" == "0" ]; then
		echo_date 检测到在线版本文件，继续...
	else
		echo_date 没有检测到在线版本，可能是访问github有问题，去大陆白名单模式试试吧！
		rm -rf /tmp/ss_version
		exit
	fi
	
	online_content=$(cat /tmp/ss_version)
	if [ -z "$online_content" ];then
		rm -rf /tmp/ss_version
	fi
	
	git_line1=$(cat /tmp/ss_version | sed -n 1p)
	git_line2=$(cat /tmp/ss_version | sed -n 2p)
	git_line4=$(cat /tmp/ss_version | sed -n 4p)
	
	version_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| sed -n 1p)
	version_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| sed -n 1p)
	version_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| sed -n 1p)
	
	md5sum_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	
	# update gfwlist
	if [ "$ss_basic_gfwlist_update" == "1" ];then
		echo_date " --------------------------------------------------------------------"
		if [ ! -z "$version_gfwlist2" ];then
			if [ "$version_gfwlist1" != "$version_gfwlist2" ];then
				echo_date 检测到新版本gfwlist，开始更新...
				echo_date 下载gfwlist到临时文件...
				wget --no-check-certificate --timeout=8 -qO - "$url_main"/gfwlist.conf > /tmp/gfwlist.conf
				md5sum_gfwlist1=$(md5sum /tmp/gfwlist.conf | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_gfwlist1"x = "$md5sum_gfwlist2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始gfwlist文件
					mv /tmp/gfwlist.conf /koolshare/ss/rules/gfwlist.conf
					sed -i "1s/.*/$git_line1/" /koolshare/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的gfwlist已经更新到最新！
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到gfwlist本地版本号和在线版本号相同，不进行更新!
			fi
		else
			echo_date gfwlist文件下载失败！
		fi
	else
		echo_date 然而你并没有勾选gfwlist更新！
	fi
	
	
	# update chnroute
	if [ "$ss_basic_chnroute_update" == "1" ];then
		echo_date " --------------------------------------------------------------------"
		if [ ! -z "$version_chnroute2" ];then
			if [ "$version_chnroute1" != "$version_chnroute2" ];then
				echo_date 检测到新版本chnroute，开始更新...
				echo_date 下载chnroute到临时文件...
				wget --no-check-certificate --timeout=8 -qO - "$url_main"/chnroute.txt > /tmp/chnroute.txt
				md5sum_chnroute1=$(md5sum /tmp/chnroute.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_chnroute1"x = "$md5sum_chnroute2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始chnroute文件
					mv /tmp/chnroute.txt /koolshare/ss/rules/chnroute.txt
					sed -i "2s/.*/$git_line2/" /koolshare/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的chnroute已经更新到最新！
				else
					echo_date md5sum 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到chnroute本地版本号和在线版本号相同，不进行更新!
			fi
		else
			echo_date chnroute文件下载失败！
		fi
	else
		echo_date 然而你并没有勾选chnroute更新！
	fi
	
	# update cdn file
	if [ "$ss_basic_cdn_update" == "1" ];then
		echo_date " --------------------------------------------------------------------"
		if [ ! -z "$version_cdn2" ];then
			if [ "$version_cdn1" != "$version_cdn2" ];then
				echo_date 检测到新版本cdn名单，开始更新...
				echo_date 下载cdn名单到临时文件...
				wget --no-check-certificate --timeout=8 -qO - "$url_main"/cdn.txt > /tmp/cdn.txt
				md5sum_cdn1=$(md5sum /tmp/cdn.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_cdn1"x = "$md5sum_cdn2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始cdn名单文件
					mv /tmp/cdn.txt /koolshare/ss/rules/cdn.txt
					sed -i "4s/.*/$git_line4/" /koolshare/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的cdn名单已经更新到最新！
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到cdn名单本地版本号和在线版本号相同，不进行更新!
			fi
		else
			echo_date cdn名单文件下载失败！
		fi
	else
		echo_date 然而你并没有勾选cdn名单更新！
	fi
	echo_date " --------------------------------------------------------------------"
	rm -rf /tmp/gfwlist.conf1
	rm -rf /tmp/chnroute.txt1
	rm -rf /tmp/cdn.txt1
	rm -rf /tmp/ss_version
	
	echo_date Shadowsocks更新进程运行完毕！
	# write number
	nvram set update_ipset="$(cat /koolshare/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_cdn="$(cat /koolshare/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p)"
	
	nvram set ipset_numbers=$(cat /koolshare/ss/rules/gfwlist.conf | grep -c ipset)
	nvram set chnroute_numbers=$(cat /koolshare/ss/rules/chnroute.txt | grep -c .)
	nvram set chnroute_ips=$(awk -F "/" '{sum += 2^(32-$2)};END {print sum}' /koolshare/ss/rules/chnroute.txt)
	nvram set cdn_numbers=$(cat /koolshare/ss/rules/cdn.txt | grep -c .)
	#======================================================================
	# reboot ss
	if [ "$reboot" == "1" ];then
		echo_date 自动重启shadowsocks，以应用新的规则文件！请稍后！
		sh /koolshare/ss/ssconfig.sh restart
	fi
	echo ==================================================================================================
}

change_cru(){
	echo ==================================================================================================
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date 应用ss规则定时更新任务：每天"$ss_basic_rule_update_time"自动检测更新规则.
		cru a ssupdate "0 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date ss规则定时更新任务未启用！
	fi
}

if [ -z "$2" ];then
	#this is for autoupdate
	change_cru
	start_update
fi

case $2 in
1)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	change_cru > /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
2)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	ss_basic_gfwlist_update=1
	ss_basic_chnroute_update=1
	ss_basic_cdn_update=1
	change_cru > /tmp/upload/ss_log.txt
	start_update >> /tmp/upload/ss_log.txt
	dbus remove 2
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac