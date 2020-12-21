#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
eval `dbus export v2ray`
LOCK_FILE=/var/lock/v2ray_sub.lock
LOG_FILE=/tmp/upload/v2ray_log.txt

set_lock(){
	exec 233>"$LOCK_FILE"
	flock -n 233 || {
		echo_date "订阅脚本已经在运行，请稍候再试！"
		exit 1
	}
}

unset_lock(){
	flock -u 233
	rm -rf "$LOCK_FILE"
}

decode_url_link(){
	local link=$1
	local len=`echo $link| wc -L`
	local mod4=$(($len%4))
	if [ "$mod4" -gt "0" ]; then
		local var="===="
		local newlink=${link}${var:$mod4}
		echo -n "$newlink" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	else
		echo -n "$link" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	fi
}

get_v2ray_remote_config(){
	decode_link="$1"
	v2ray_v=$(echo "$decode_link" | jq -r .v)
	v2ray_ps=$(echo "$decode_link" | jq -r .ps | sed 's/[ \t]*//g')
	v2ray_add=$(echo "$decode_link" | jq -r .add | sed 's/[ \t]*//g')
	v2ray_port=$(echo "$decode_link" | jq -r .port | sed 's/[ \t]*//g')
	v2ray_id=$(echo "$decode_link" | jq -r .id | sed 's/[ \t]*//g')
	v2ray_aid=$(echo "$decode_link" | jq -r .aid | sed 's/[ \t]*//g')
	v2ray_net=$(echo "$decode_link" | jq -r .net)
	v2ray_type=$(echo "$decode_link" | jq -r .type)
	v2ray_tls_tmp=$(echo "$decode_link" | jq -r .tls)
	[ "$v2ray_tls_tmp"x == "tls"x ] && v2ray_tls="tls" || v2ray_tls="none"
	
	if [ "$v2ray_v" == "2" ];then
		#echo_date "new format"
		v2ray_path=$(echo "$decode_link" |jq -r .path)
		v2ray_host=$(echo "$decode_link" |jq -r .host)
	else
		#echo_date "old format"
		case $v2ray_net in
		tcp)
			v2ray_host=$(echo "$decode_link" |jq -r .host)
			v2ray_path=""
			;;
		kcp)
			v2ray_host=""
			v2ray_path=""
			;;
		ws)
			v2ray_host_tmp=$(echo "$decode_link" |jq -r .host)
			if [ -n "$v2ray_host_tmp" ];then
				format_ws=`echo $v2ray_host_tmp|grep -E ";"`
				if [ -n "$format_ws" ];then
					v2ray_host=`echo $v2ray_host_tmp|cut -d ";" -f1`
					v2ray_path=`echo $v2ray_host_tmp|cut -d ";" -f1`
				else
					v2ray_host=""
					v2ray_path=$v2ray_host
				fi
			fi
			;;
		h2)
			v2ray_host=""
			v2ray_path=$(echo "$decode_link" |jq -r .path)
			;;
		esac
	fi

	[ -z "$v2ray_ps" -o -z "$v2ray_add" -o -z "$v2ray_port" -o -z "$v2ray_id" -o -z "$v2ray_aid" -o -z "$v2ray_net" -o -z "$v2ray_type" ] && return 1 || return 0
}

add_v2ray_servers(){
	local kcp="null"
	local tcp="null"
	local ws="null"
	local h2="null"
	local tls="null"
	local v2rayindex
	usleep 250000
	if [ -z "$1" ]; then
		#[ -z "$v2ray_sub_node_max" ] && v2ray_sub_node_max=0
		v2rayindex=$(($(dbus list v2ray_sub_|cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
	else
		#[ -z "$v2ray_server_node_max" ] && v2ray_server_node_max=0
		v2rayindex=$(($(dbus list v2ray_server_|cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
		#v2rayindex=`expr $v2ray_server_node_max + 1`
	fi
	
	[ "$v2ray_tls" == "none" ] && local v2ray_network_security=""
	#if [ "$v2ray_sub_v2ray_network" == "ws" -o "$v2ray_sub_v2ray_network" == "h2" ];then
	case "$v2ray_tls" in
		tls)
			local tls="{
			\"allowInsecure\": true,
			\"serverName\": \"$v2ray_host\"
			}"
		;;
		*)
			local tls="null"
		;;
		esac
	#fi
	# incase multi-domain input
	if [ "`echo $v2ray_host | grep ","`" ];then
		v2ray_host=`echo $v2ray_host | sed 's/,/", "/g'`
	fi
	
	case "$v2ray_net" in
		tcp)
			if [ "$v2ray_type" == "http" ];then
				local tcp="{
				\"connectionReuse\": true,
				\"header\": {
				\"type\": \"http\",
				\"request\": {
				\"version\": \"1.1\",
				\"method\": \"GET\",
				\"path\": [\"/\"],
				\"headers\": {
				\"Host\": [\"$v2ray_host\"],
				\"User-Agent\": [\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\",\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"],
				\"Accept-Encoding\": [\"gzip, deflate\"],
				\"Connection\": [\"keep-alive\"],
				\"Pragma\": \"no-cache\"
				}
				},
				\"response\": {
				\"version\": \"1.1\",
				\"status\": \"200\",
				\"reason\": \"OK\",
				\"headers\": {
				\"Content-Type\": [\"application/octet-stream\",\"video/mpeg\"],
				\"Transfer-Encoding\": [\"chunked\"],
				\"Connection\": [\"keep-alive\"],
				\"Pragma\": \"no-cache\"
				}
				}
				}
				}"
			else
				local tcp="null"
			fi        
		;;
		kcp)
			local kcp="{
			\"mtu\": 1350,
			\"tti\": 50,
			\"uplinkCapacity\": 12,
			\"downlinkCapacity\": 100,
			\"congestion\": false,
			\"readBufferSize\": 2,
			\"writeBufferSize\": 2,
			\"header\": {
			\"type\": \"$v2ray_type\",
			\"request\": null,
			\"response\": null
			}
			}"
		;;
		ws)
			local ws="{
			\"connectionReuse\": true,
			\"path\": \"$v2ray_path\",
			\"headers\": { 
				\"Host\": \"$v2ray_host\"
			}
			}"
		;;
		h2)
			local h2="{
			\"path\": \"$v2ray_path\",
			\"headers\": { 
				\"Host\": \"$v2ray_host\"
			}
			}"
		;;
	esac
	local v2ray_config="
		{
			\"outbound\": {
				\"protocol\": \"vmess\",
				\"settings\": {
					\"vnext\": [
						{
							\"address\": \"$v2ray_add\",
							\"port\": $v2ray_port,
							\"users\": [
								{
									\"id\": \"$v2ray_id\",
									\"alterId\": $v2ray_aid,
									\"security\": \"auto\"
								}
							]
						}
					]
				},
				\"streamSettings\": {
					\"network\": \"$v2ray_net\",
					\"security\": \"$v2ray_tls\",
					\"tlsSettings\": $tls,
					\"tcpSettings\": $tcp,
					\"kcpSettings\": $kcp,
					\"wsSettings\": $ws,
					\"httpSettings\": $h2
				},
				\"mux\": {
					\"enabled\": true
				}
			}
		}"
	if [ -z "$1" ]; then
		dbus set "v2ray_sub_tag_$v2rayindex"="$v2ray_ps"
		dbus set "v2ray_sub_config_$v2rayindex"=$(echo $v2ray_config|base64_encode)
		dbus set v2ray_sub_node_max=$v2rayindex
		echo_date V2ray 通过订阅：新增加 【$v2ray_ps】 到节点列表第 $v2rayindex 位。
	else
		dbus set "v2ray_server_tag_$v2rayindex"="$v2ray_ps"
		dbus set "v2ray_server_config_$v2rayindex"=$(echo $v2ray_config|base64_encode)
		dbus set v2ray_server_node_max=$v2rayindex
		echo_date V2ray 通过链接：新增加 【$v2ray_ps】 到节点列表第 $v2rayindex 位。
	fi
}


get_oneline_rule_now(){
	# ss订阅
	v2ray_subscribe_link="$1"
	LINK_FORMAT=`echo "$v2ray_subscribe_link" | grep -E "^http://|^https://"`
	[ -z "$LINK_FORMAT" ] && return 4
	
	echo_date "开始更新在线订阅列表..." 
	echo_date "开始下载订阅链接到本地临时文件，请稍等..."
	rm -rf /tmp/v2ray_subscribe_file* >/dev/null 2>&1
	
	if [ "$v2ray_basic_suburl_socks" == "1" ];then
		socksopen=`netstat -nlp|grep -w 1280|grep -E "local|v2ray"`
		if [ -n "$socksopen" ];then
			echo_date "使用 V2ray 提供的socks代理网络下载..."
			curl --connect-timeout 8 -s -L --socks5-hostname 127.0.0.1:1280 $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
		else
			echo_date "没有可用的socks5代理端口，改用常规网络下载..."
			curl --connect-timeout 8 -s -L $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
		fi
	else
		echo_date "使用常规网络下载..."
		curl --connect-timeout 8 -s -L $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
	fi

	#虽然为0但是还是要检测下是否下载到正确的内容
	if [ "$?" == "0" ];then
		#订阅地址有跳转
		blank=`cat /tmp/v2ray_subscribe_file.txt|grep -E " |Redirecting|301"`
		if [ -n "$blank" ];then
			echo_date 订阅链接可能有跳转，尝试更换wget进行下载...
			rm /tmp/v2ray_subscribe_file.txt
			if [ "`echo $v2ray_subscribe_link|grep ^https`" ];then
				wget --no-check-certificate -qO /tmp/v2ray_subscribe_file.txt $v2ray_subscribe_link
			else
				wget -qO /tmp/v2ray_subscribe_file.txt $v2ray_subscribe_link
			fi
		fi
		#下载为空...
		if [ -z "`cat /tmp/v2ray_subscribe_file.txt`" ];then
			echo_date 下载为空...
			return 3
		fi
		#产品信息错误
		wrong1=`cat /tmp/v2ray_subscribe_file.txt|grep "{"`
		wrong2=`cat /tmp/v2ray_subscribe_file.txt|grep "<"`
		if [ -n "$wrong1" -o -n "$wrong2" ];then
			return 2
		fi
	else
		return 1
	fi

	if [ "$?" == "0" ];then
		echo_date 下载订阅成功...
		echo_date 开始解析节点信息...
		decode_url_link `cat /tmp/v2ray_subscribe_file.txt` > /tmp/v2ray_subscribe_file_temp1.txt
		v2ray_group=`echo $v2ray_subscribe_link|awk -F'[/:]' '{print $4}'`
		# 检测vmess
		NODE_FORMAT1=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -E "^ss://"`
		NODE_FORMAT2=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -E "^vmess://"`
		if [ -n "$NODE_FORMAT2" ];then
			# v2ray 订阅
			
			# detect format again
			if [ -n "$NODE_FORMAT1" ];then
				#vmess://里夹杂着ss://
				NODE_NU=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -Ec "vmess://|ss://|ssr://"`
				echo_date 检测到vmess和ss节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link `cat /tmp/v2ray_subscribe_file.txt` | sed 's/vmess:\/\///g')
			else
				#纯vmess://
				NODE_NU=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -Ec "vmess://"`
				echo_date 检测到vmess节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link `cat /tmp/v2ray_subscribe_file.txt` | sed 's/vmess:\/\///g')
			fi

			remove_sub
			for link in $urllinks
			do
				decode_link=$(decode_url_link $link)
				decode_link=$(echo $decode_link|jq -c .)
				if [ -n "$decode_link" ];then
					get_v2ray_remote_config "$decode_link"
					[ "$?" == "0" ] && add_v2ray_servers || echo_date "检测到一个错误节点，已经跳过！"
				else
					echo_date "解析失败！！！"
				fi
			done

			ONLINE_GET=$(dbus list v2ray_sub_tag_|wc -l) || 0
			echo_date "本次更新订阅来源 【$v2ray_group】"
			echo_date "现共有订阅v2ray节点：$ONLINE_GET 个。"
			echo_date "在线订阅列表更新完成!"
			echo_date "在线订阅列表不会在自建服务列表中显示，请在【账号设置】-【服务器类型】选择【订阅】使用！"
			set_cru
		else
			return 3
		fi
	else
		return 1
	fi
}

start_update(){
	online_url_nu=`dbus get v2ray_basic_suburl|base64_decode|sed 's/$/\n/'|sed '/^$/d'|wc -l`
	url=`dbus get v2ray_basic_suburl|base64_decode|awk '{print $1}'|sed -n "$z p"|sed '/^#/d'`
	[ -z "$url" ] && continue
	echo_date "==================================================================="
	echo_date "                             V2ray 服务器订阅程序"
	echo_date "==================================================================="
	echo_date "从 $url 获取订阅..."
	addnum=0
	updatenum=0
	delnum=0
	get_oneline_rule_now "$url"

	case $? in
	0)
		continue
		;;
	2)
		echo_date "无法获取产品信息！请检查你的服务商是否更换了订阅链接！"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	3)
		echo_date "该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	4)
		echo_date "订阅地址错误！检测到你输入的订阅地址并不是标准网址格式！"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	1|*)
		echo_date "下载订阅失败...请检查你的网络..."
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	esac

	# 结束
	echo_date "-------------------------------------------------------------------"
	echo_date "一点点清理工作..."
	rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/v2ray_subscribe_file_temp1.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
}

add() {
	echo_date "==================================================================="
	echo_date 通过v2ray链接添加节点...
	rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/v2ray_subscribe_file_temp1.txt >/dev/null 2>&1
	#echo_date 添加链接为：`dbus get v2ray_base64_links`
	v2raylinks=`dbus get v2ray_base64_links|sed 's/$/\n/'|sed '/^$/d'`
	for v2raylink in $v2raylinks
	do
		if [ -n "$v2raylink" ];then
			if [ -n "`echo -n "$v2raylinks" | grep "vmess://"`" ]; then
				echo_date 检测到vmess链接...开始尝试解析...
				new_v2raylink=`echo -n "$v2raylink" | sed 's/vmess:\/\///g'`
				decode_v2raylink=$(decode_url_link $new_v2raylink)
				decode_v2raylink=$(echo $decode_v2raylink|jq -c .)
				get_v2ray_remote_config $decode_v2raylink
				add_v2ray_servers 1
			else
				echo_date 没有检测到vmess信息，添加失败，请检查输入...
			fi
		fi
		dbus remove v2ray_base64_links
	done
	echo_date "==================================================================="
}

set_cru(){
	if [ "$v2ray_basic_node_update" = "1" ];then
		sed -i '/v2raynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
		if [ "$v2ray_basic_node_update_day" = "7" ];then
			echo "0 $v2ray_basic_node_update_hr * * * /koolshare/scripts/v2ray_sub.sh 3 3 #v2raynodeupdate#" >> /etc/crontabs/root
			echo_date "设置自动更新订阅服务在每天 $v2ray_basic_node_update_hr 点。" >> $LOG_FILE
		else
			echo "0 $v2ray_basic_node_update_hr * * v2ray_basic_node_update_day /koolshare/scripts/v2ray_sub.sh 3 3 #v2raynodeupdate#" >> /etc/crontabs/root
			echo_date "设置自动更新订阅服务在星期 $v2ray_basic_node_update_day 的 $v2ray_basic_node_update_hr 点。" >> $LOG_FILE
		fi
	else
		echo_date "自动更新订阅服务已关闭！" >> $LOG_FILE
		sed -i '/v2raynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	fi
}

remove_server(){
	# 2 清除已有的ss节点配置
	echo_date 删除所有普通节点信息！
	confs=`dbus list v2ray_server_ | cut -d "=" -f 1`
	for conf in $confs
	do
		#echo_date 移除$conf
		dbus remove $conf
	done
	dbus set v2ray_server_node_max=0
}

remove_sub(){
	# 2 清除已有的ss节点配置
	echo_date 删除所有订阅节点信息！
	confs=`dbus list v2ray_sub_ | cut -d "=" -f 1`
	for conf in $confs
	do
		#echo_date 移除$conf
		dbus remove $conf
	done
	dbus set v2ray_sub_node_max=0
}

case $2 in
1)
	# 删除所有节点
	set_lock
	echo " " > $LOG_FILE
	remove_server >> $LOG_FILE
	remove_sub >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
2)
	# 删除所有订阅节点
	set_lock
	echo " " > $LOG_FILE
	remove_sub >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
3)
	# 订阅节点
	set_lock
	echo " " > $LOG_FILE
	start_update >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
4)
	# 链接添加v2ray
	set_lock
	echo " " > $LOG_FILE
	add >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
esac