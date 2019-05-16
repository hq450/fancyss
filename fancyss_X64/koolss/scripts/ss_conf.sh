#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo 【$(date +%Y年%m月%d日\ %X)】:'
eval `dbus export ss`
LOG_FILE=/tmp/upload/ss_log.txt


remove_conf_all(){
	echo_date 尝试关闭koolss...
	sh $KSROOT/ss/ssstart.sh stop
	echo_date 开始清理koolss配置...
	confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version"`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 设置一些默认参数...
	dbus set ss_basic_enable="0"
	dbus set ss_version=`cat $KSROOT/ss/version` 
	echo_date 完成！
}

remove_ss_node(){
	echo_date 开始清理koolss节点配置...
	confs1=`dbus list ssconf | cut -d "=" -f 1`
	confs2=`dbus list ssrconf | cut -d "=" -f 1`
	for conf in $confs1 $confs2 $confs3
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 完成！
}

remove_ss_acl(){
	echo_date 开始清理koolss配置...
	confs=`dbus list ss_acl | cut -d "=" -f 1`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 完成！
}

# ===============================================================================================
route_add(){
	devnu="$1"
	routeip="$2"
	cleanfile=/tmp/route_del
	if [ "$devnu" == "0" ];then
		echo_date "【出口设定】 不指定 $routeip 的出口"
	else
		GW=`ubus call network.interface dump|jq .interface["$devnu"].route[0].nexthop|sed 's/"//g'`
		l3_name=`ubus call network.interface dump|jq .interface["$devnu"].l3_device|sed 's/"//g'`
		#devname=`ubus call network.interface dump|jq .interface["$devnu"].device|sed 's/"//g'`
		if [ -n "$GW" ];then
			ip route add $routeip via $GW dev $l3_name >/dev/null 2>&1
			echo_date "【出口设定】设置 $routeip 出口为 $l3_name"
			if [ ! -f $cleanfile ];then
				cat	> $cleanfile <<-EOF
				#!/bin/sh
				EOF
			fi
			chmod +x $cleanfile
			echo "ip route del $routeip via $GW dev $l3_name" >> /tmp/route_del
		else
			echo_date "【出口设定】设置 $routeip 出口为 $l3_name 失败, 因为$l3_name 已经离线!!! $routeip将会自动选择出口！"
		fi
	fi
}

IFIP=`echo $ss_basic_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
resolv_server_ip(){
	if [ -z "$IFIP" ];then
		# resolve first
		if [ "$ss_basic_dnslookup" == "1" ];then
			server_ip=`nslookup "$ss_basic_server" $ss_basic_dnslookup_server | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
		else
			server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
		fi

		if [ -n "$server_ip" ];then
			ss_basic_server_ip="$server_ip"
			# store resoved ip in skipd
			if [ "$ss_basic_type"  == "1" ];then
				SSR_NODE=`expr $ss_basic_node - $ssconf_basic_max_node`
				dbus set ssrconf_basic_server_ip_$SSR_NODE="$server_ip"
			elif [ "$ss_basic_type"  == "0" ];then
				dbus set ssconf_basic_server_ip_$ss_basic_node="$server_ip"
			fi
		else
			# get pre-resoved ip in skipd
			echo_date 尝试获取上次储存的解析结果...
			if [ "$ss_basic_type"  == "1" ];then
				SSR_NODE=`expr $ss_basic_node - $ssconf_basic_max_node`
				ss_basic_server_ip=`dbus get ssrconf_basic_server_ip_$SSR_NODE`
			elif [ "$ss_basic_type"  == "0" ];then
				ss_basic_server_ip=`dbus get ssconf_basic_server_ip_$ss_basic_node`
			fi
		fi
	else
		ss_basic_server_ip="$ss_basic_server"
	fi
}
#=================================================================================================

case $2 in
1)
	#移除所有ss配置文件
	remove_conf_all > $LOG_FILE
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
2)
	#移除所有ss节点配置文件
	remove_ss_node > $LOG_FILE
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
3)
	#移除所有ss访问控制配置文件
	remove_ss_acl > $LOG_FILE
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
4)
	#备份ss配置
	echo "" > $LOG_FILE
	mkdir -p $KSROOT/webs/files
	dbus list ss | grep -v "status" | grep -v "enable" | grep -v "version" | grep -v "success" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 i\\n' | sed '1 isource /koolshare/scripts/base.sh' |sed '1 i#!/bin/sh' > $KSROOT/webs/files/ss_conf_backup.sh
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	sleep 10 
	rm -rf /koolshare/webs/files/ss_conf_backup.sh
	;;
5)
	#用备份的ss_conf_backup.sh 去恢复配置
	echo_date "开始恢复SS配置..." > $LOG_FILE
	file_nu=`ls /tmp/upload/ss_conf_backup | wc -l`
	x=10
	until [ -n "$file_nu" ]
	do
	    i=$(($x-1))
	    if [ "$x" -lt 1 ];then
	        echo_date "错误：没有找到恢复文件!"
	        exit
	    fi
	    sleep 1
	done
	format=`cat /tmp/upload/ss_conf_backup.sh |grep dbus`
	if [ -n "format" ];then
		echo_date "检测到正确格式的配置文件！" >> $LOG_FILE
		cd /tmp/upload
		chmod +x ss_conf_backup.sh
		echo_date "恢复中..." >> $LOG_FILE
		sh ss_conf_backup.sh
		sleep 1
		rm -rf /tmp/upload/ss_conf_backup.sh
		dbus set ss_version=`cat $KSROOT/ss/version`
		echo_date "恢复完毕！" >> $LOG_FILE
	else
		echo_date "配置文件格式错误！" >> $LOG_FILE
	fi
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
6)
	#打包ss插件
	rm -rf /tmp/koolss*
	rm -rf /koolshare/webs/files/koolss*
	echo_date "开始打包..." > $LOG_FILE
	echo_date "请等待一会儿...下载会自动开始." >> $LOG_FILE
	mkdir -p /koolshare/webs/files
	cd /tmp
	mkdir koolss
	mkdir koolss/bin
	mkdir koolss/scripts
	mkdir koolss/init.d
	mkdir koolss/webs
	mkdir koolss/webs/res
	TARGET_FOLDER=/tmp/koolss
	cp $KSROOT/scripts/ss_install.sh $TARGET_FOLDER/install.sh
	cp $KSROOT/scripts/uninstall_koolss.sh $TARGET_FOLDER/uninstall.sh
	cp $KSROOT/bin/ss-* $TARGET_FOLDER/bin/
	cp $KSROOT/bin/obfs-local $TARGET_FOLDER/bin/
	cp $KSROOT/bin/ssr-* $TARGET_FOLDER/bin/
	cp $KSROOT/bin/pdnsd $TARGET_FOLDER/bin/
	cp $KSROOT/bin/Pcap_DNSProxy $TARGET_FOLDER/bin/
	cp $KSROOT/bin/dns2socks $TARGET_FOLDER/bin/
	cp $KSROOT/bin/dnscrypt-proxy $TARGET_FOLDER/bin/
	cp $KSROOT/bin/chinadns $TARGET_FOLDER/bin/
	cp $KSROOT/bin/resolveip $TARGET_FOLDER/bin/
	cp $KSROOT/bin/haproxy $TARGET_FOLDER/bin/
	cp $KSROOT/bin/kcpclient $TARGET_FOLDER/bin/
	cp $KSROOT/scripts/ss_* $TARGET_FOLDER/scripts/
	cp $KSROOT/init.d/S99koolss.sh $TARGET_FOLDER/init.d
	cp $KSROOT/webs/Module_koolss.asp $TARGET_FOLDER/webs/
	cp $KSROOT/webs/res/icon-koolss* $TARGET_FOLDER/webs/res/
	cp -r $KSROOT/ss $TARGET_FOLDER/
	rm -rf $TARGET_FOLDER/ss/*.json

	tar -czv -f /koolshare/webs/files/koolss.tar.gz koolss/
	rm -rf $TARGET_FOLDER
	echo_date "打包完毕！该包可以在LEDE软件中心离线安装哦~" >> $LOG_FILE
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	sleep 4
	rm -rf /koolshare/webs/files/koolss*
	;;
7)
	# 老实说，我是一个假的日志，其实订阅节点删除操作全部在web里和httpdb配合完成，完全没有脚本的事
	# 但是删除过程中不显示点什么的话，貌似不是特别和谐，于是显示个假的日志好了
	# 顺便让路由器休息2秒
	echo_date "正在删除你选择的订阅节点，请不要做其它操作..." > $LOG_FILE
	sleep 2
	echo_date "清除成功！" >> $LOG_FILE
	http_response "$1"
	;;
8)
	echo "" > $LOG_FILE

	# do not use this arg
	local_groups=`dbus list ss|grep group|cut -d "=" -f2|sort -u|wc -l`
	online_group=`dbus list ss_online_link_|grep link|wc -l`
	echo_date "保存订阅节点成功，现共有 $online_group 组订阅来源，当前节点列表内已经订阅了 $local_groups 组..." >> $LOG_FILE
	
	sed -i '/ssnodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ];then
		if [ "$ss_basic_node_update_day" = "7" ];then
			echo "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh #ssnodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在每天 $ss_basic_node_update_hr 点。" >> $LOG_FILE
		else
			echo "0 $ss_basic_node_update_hr * * $ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh #ssnodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。" >> $LOG_FILE
		fi
	fi
	sleep 1
	http_response "$1"
	;;
9)
	if [ "$ss_dns_china" == "1" ];then
		IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		[ -n "$IFIP_DNS1" ] && CDN1="$ISP_DNS1" || CDN1="114.114.114.114"
		[ -n "$IFIP_DNS2" ] && CDN2="$ISP_DNS2" || CDN2="114.114.115.115"
	fi

	ISP_DNS1=`cat /tmp/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p`
	IFIP_DNS=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	[ -n "$IFIP_DNS" ] && CDN="$ISP_DNS1" || CDN="114.114.114.114"
	[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
	[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
	[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
	[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
	[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
	[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
	[ "$ss_dns_china" == "8" ] && CDN="112.124.47.27"
	[ "$ss_dns_china" == "9" ] && CDN="114.215.126.16"
	[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
	[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
	[ "$ss_dns_china" == "12" ] && CDN="$ss_dns_china_user"

	if [ -f "/tmp/route_del" ];then
		source /tmp/route_del >/dev/null 2>&1
		rm -f /tmp/route_del >/dev/null 2>&1
	fi
	rm -rf $LOG_FILE
	[ "$ss_mwan_china_dns_dst" != "0" ] && [ -n "$CDN" ] && route_add $ss_mwan_china_dns_dst $CDN
	[ "$ss_mwan_china_dns_dst" != "0" ] && [ -n "$CDN1" ] && route_add $ss_mwan_china_dns_dst $CDN1
	[ "$ss_mwan_china_dns_dst" != "0" ] && [ -n "$CDN2" ] && route_add $ss_mwan_china_dns_dst $CDN2
	[ "$ss_mwan_vps_ip_dst" != "0" ] && [ -n "$ss_basic_server_ip" ] && [ "$ss_basic_server_ip" != "127.0.0.1" ] && route_add $ss_mwan_vps_ip_dst $ss_basic_server_ip
	
	[ -z "$3" ] && http_response "$1"
	;;
10)
	echo "" > $LOG_FILE
	sed -i '/ssruleupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$ss_basic_rule_update" = "1" ];then
		if [ "$ss_basic_rule_update_day" = "7" ];then
			echo "0 $ss_basic_rule_update_hr * * * /koolshare/scripts/ss_rule_update.sh #ssupdate#" >> /etc/crontabs/root
			echo_date "设置SS规则自动更在每天 $ss_basic_rule_update_hr 点。" >> $LOG_FILE
		else
			echo "0 $ss_basic_rule_update_hr * * $ss_basic_rule_update_day /koolshare/scripts/ss_rule_update.sh #ssupdate#" >> /etc/crontabs/root
			echo_date "设置SS规则自动更新在星期 $ss_basic_rule_update_day 的 $ss_basic_rule_update_hr 点。" >> $LOG_FILE
		fi
	else
		echo_date "关闭SS规则自动更新." >> $LOG_FILE
	fi
	sed -i '/sspcapupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$ss_basic_pcap_update" = "1" ];then
		if [ "$ss_basic_pcap_update_day" = "7" ];then
			echo "0 $ss_basic_pcap_update_hr * * * /koolshare/scripts/ss_pcap_update.sh #sspcapupdate#" >> /etc/crontabs/root
			echo_date "设置PcapDNSproxy规则自动更新在每天 $ss_basic_pcap_update_hr 点。" >> $LOG_FILE
		else
			echo "0 $ss_basic_pcap_update_hr * * $ss_basic_pcap_update_day /koolshare/scripts/ss_pcap_update.sh #sspcapupdate#" >> /etc/crontabs/root
			echo_date "设置PcapDNSproxy规则自动更新在星期 $ss_basic_pcap_update_day 的 $ss_basic_pcap_update_hr 点。" >> $LOG_FILE
		fi
	else
		echo_date "关闭PcapDNSproxy规则自动更新." >> $LOG_FILE
	fi
	http_response "$1"
	;;
11)
	#update rule 
	sh /koolshare/scripts/ss_rule_update.sh update
	;;
esac