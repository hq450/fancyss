#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export ss`
alias echo_date='echo 【$(date +%Y年%m月%d日\ %X)】:'
url_back="https://koolshare.ngrok.wang/maintain_files"
url_main="https://raw.githubusercontent.com/hq450/fancyss/master/rules/"
# version dectet
version_gfwlist1=$(cat $KSROOT/ss/rules/version | sed -n 1p | sed 's/ /\n/g'| sed -n 1p)
version_chnroute1=$(cat $KSROOT/ss/rules/version | sed -n 2p | sed 's/ /\n/g'| sed -n 1p)
version_cdn1=$(cat $KSROOT/ss/rules/version | sed -n 4p | sed 's/ /\n/g'| sed -n 1p)
version_Routing1=$(cat $KSROOT/ss/rules/version | sed -n 5p | sed 's/ /\n/g'| sed -n 1p)
version_WhiteList1=$(cat $KSROOT/ss/rules/version | sed -n 6p | sed 's/ /\n/g'| sed -n 1p)

update_rule(){
	echo =======================================================================================================
	echo_date 开始更新koolss规则，请等待...
	wget --no-check-certificate --timeout=8 -qO - $url_main/version1 > /tmp/version1
	if [ "$?" == "0" ]; then
		echo_date 检测到在线版本文件，继续...
	else
		echo_date 没有检测到在线版本欸，可能是访问github有问题，去大陆白名单模式试试吧！
		rm -rf /tmp/version1
		exit
	fi
	
	online_content=$(cat /tmp/version1)
	if [ -z "$online_content" ];then
		rm -rf /tmp/version1
	fi
	
	git_line1=$(cat /tmp/version1 | sed -n 1p)
	git_line2=$(cat /tmp/version1 | sed -n 2p)
	git_line4=$(cat /tmp/version1 | sed -n 4p)
	git_line5=$(cat /tmp/version1 | sed -n 5p)
	git_line6=$(cat /tmp/version1 | sed -n 6p)
	
	version_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| sed -n 1p)
	version_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| sed -n 1p)
	version_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| sed -n 1p)
	version_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| sed -n 1p)
	version_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| sed -n 1p)
	
	md5sum_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	
	# update gfwlist
	if [ "$ss_basic_gfwlist_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_gfwlist2" ];then
			if [ "$version_gfwlist1" != "$version_gfwlist2" ];then
				echo_date 检测到新版本gfwlist，开始更新...
				echo_date 下载gfwlist到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/gfwlist.conf > /tmp/gfwlist.conf
				md5sum_gfwlist1=$(md5sum /tmp/gfwlist.conf | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_gfwlist1"x = "$md5sum_gfwlist2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始gfwlist文件
					mv /tmp/gfwlist.conf $KSROOT/ss/rules/gfwlist.conf
					sed -i "1s/.*/$git_line1/" $KSROOT/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的gfwlist刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到gfwlist本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date gfwlist文件下载失败！
		fi
	fi
	
	
	# update chnroute
	if [ "$ss_basic_chnroute_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_chnroute2" ];then
			if [ "$version_chnroute1" != "$version_chnroute2" ];then
				echo_date 检测到新版本chnroute，开始更新...
				echo_date 下载chnroute到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/chnroute.txt > /tmp/chnroute.txt
				md5sum_chnroute1=$(md5sum /tmp/chnroute.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_chnroute1"x = "$md5sum_chnroute2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始chnroute文件
					mv /tmp/chnroute.txt $KSROOT/ss/rules/chnroute.txt
					sed -i "2s/.*/$git_line2/" $KSROOT/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的chnroute刚才已经更新到最新了哦~
				else
					echo_date md5sum 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到chnroute本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date chnroute文件下载失败！
		fi
	fi
	
	# update cdn file
	if [ "$ss_basic_cdn_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_cdn2" ];then
			if [ "$version_cdn1" != "$version_cdn2" ];then
				echo_date 检测到新版本cdn名单，开始更新...
				echo_date 下载cdn名单到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/cdn.txt > /tmp/cdn.txt
				md5sum_cdn1=$(md5sum /tmp/cdn.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_cdn1"x = "$md5sum_cdn2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始cdn名单文件
					mv /tmp/cdn.txt $KSROOT/ss/rules/cdn.txt
					sed -i "4s/.*/$git_line4/" $KSROOT/ss/rules/version
					reboot="1"
					echo_date 【更新成功】你的cdn名单刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到cdn名单本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date cdn名单文件下载失败！
		fi
	fi

	# update pcap Routing file
	if [ "$ss_basic_pcap_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_Routing2" ];then
			if [ "$version_Routing1" != "$version_Routing2" ];then
				echo_date 检测到新版本pcap Routing列表，开始更新...
				echo_date 下载pcap Routing名单到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/Routing.txt > /tmp/Routing.txt
				md5sum_Routing1=$(md5sum /tmp/Routing.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_Routing1"x = "$md5sum_Routing2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始Routing名单文件
					mv /tmp/Routing.txt $KSROOT/ss/rules/Routing.txt
					sed -i "5s/.*/$git_line5/" $KSROOT/ss/rules/version
					reboot_pcap="1"
					echo_date 【更新成功】你的pcap Routing名单刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到pcap Routing名单本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date pcap Routing名单文件下载失败！
		fi
	fi

	# update pcap WhiteList file
	if [ "$ss_basic_pcap_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_WhiteList2" ];then
			if [ "$version_WhiteList1" != "$version_WhiteList2" ];then
				echo_date 检测到新版本pcap WhiteList名单，开始更新...
				echo_date 下载pcap WhiteList名单到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/WhiteList.txt > /tmp/WhiteList.txt
				md5sum_WhiteList1=$(md5sum /tmp/WhiteList.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_WhiteList1"x = "$md5sum_WhiteList2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始WhiteList名单文件
					mv /tmp/WhiteList.txt $KSROOT/ss/rules/WhiteList.txt
					sed -i "6s/.*/$git_line6/" $KSROOT/ss/rules/version
					reboot_pcap="1"
					echo_date 【更新成功】你的pcap WhiteList名单刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到pcap WhiteList名单本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date WhiteList名单文件下载失败！
		fi
		echo_date " ---------------------------------------------------------------------------------------"
	fi
	rm -rf /tmp/gfwlist.conf1
	rm -rf /tmp/chnroute.txt1
	rm -rf /tmp/cdn.txt1
	rm -rf /tmp/version1
	
	echo_date Shadowsocks更新进程运行完毕！
	# write number
	ipset_numbers=`cat $KSROOT/ss/rules/gfwlist.conf | grep -c ipset`
	chnroute_numbers=`cat $KSROOT/ss/rules/chnroute.txt | grep -c .`
	cdn_numbers=`cat $KSROOT/ss/rules/cdn.txt | grep -c .`
	Routing_numbers=`cat $KSROOT/ss/dns/Routing.txt |grep -c /`
	WhiteList_numbers=`cat $KSROOT/ss/dns/WhiteList.txt |grep -Ec "^\.\*"`
	
	update_ipset=`cat $KSROOT/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
	update_chnroute=`cat $KSROOT/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
	update_cdn=`cat $KSROOT/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
	update_Routing=`cat $KSROOT/ss/rules/version | sed -n 5p | sed 's/#/\n/g'| sed -n 1p`
	update_WhiteList=`cat $KSROOT/ss/rules/version | sed -n 6p | sed 's/#/\n/g'| sed -n 1p`
	dbus set ss_gfw_status="$ipset_numbers 条，最后更新版本： $update_ipset "
	dbus set ss_chn_status="$chnroute_numbers 条，最后更新版本： $update_chnroute "
	dbus set ss_cdn_status="$cdn_numbers 条，最后更新版本： $update_cdn "
	dbus set ss_Routing_status="$Routing_numbers 条，最后更新版本： $update_Routing "
	dbus set ss_WhiteList_status="$WhiteList_numbers 条，最后更新版本： $update_WhiteList "
	
	# reboot ss
	if [ "$reboot" == "1" ];then
		echo_date 自动重启koolss，以应用新的规则文件！请稍后！
		sh $KSROOT/ss/ssstart.sh restart
	fi
	
	pcap=`pidof Pcap_DNSProxy`
	# reboot pcap
	if [ "$reboot" != "1" ] && [ -n "$pcap" ] && [ "$reboot_pcap" == "1" ];then
		echo_date 自动重启Pcap_DNSProxy，以应用新的规则文件！请稍后！
		killall Pcap_DNSProxy >/dev/null 2>&1
		Pcap_DNSProxy -c /koolshare/ss/dns
	fi	
	echo =======================================================================================================
}
if [ -n "$1" ];then
	update_rule "$1" > /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	http_response "$1"
else
	update_rule > /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
fi
