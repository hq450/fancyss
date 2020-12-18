#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo ��$(TZ=UTC-8 date -R +%Y��%m��%d��\ %X)��:'
eval `dbus export v2ray`
LOCK_FILE=/var/lock/v2ray_sub.lock
LOG_FILE=/tmp/upload/v2ray_log.txt

set_lock(){
	exec 233>"$LOCK_FILE"
	flock -n 233 || {
		echo_date "���Ľű��Ѿ������У����Ժ����ԣ�"
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
		echo_date V2ray ͨ�����ģ������� ��$v2ray_ps�� ���ڵ��б�� $v2rayindex λ��
	else
		dbus set "v2ray_server_tag_$v2rayindex"="$v2ray_ps"
		dbus set "v2ray_server_config_$v2rayindex"=$(echo $v2ray_config|base64_encode)
		dbus set v2ray_server_node_max=$v2rayindex
		echo_date V2ray ͨ�����ӣ������� ��$v2ray_ps�� ���ڵ��б�� $v2rayindex λ��
	fi
}


get_oneline_rule_now(){
	# ss����
	v2ray_subscribe_link="$1"
	LINK_FORMAT=`echo "$v2ray_subscribe_link" | grep -E "^http://|^https://"`
	[ -z "$LINK_FORMAT" ] && return 4
	
	echo_date "��ʼ�������߶����б�..." 
	echo_date "��ʼ���ض������ӵ�������ʱ�ļ������Ե�..."
	rm -rf /tmp/v2ray_subscribe_file* >/dev/null 2>&1
	
	if [ "$v2ray_basic_suburl_socks" == "1" ];then
		socksopen=`netstat -nlp|grep -w 1280|grep -E "local|v2ray"`
		if [ -n "$socksopen" ];then
			echo_date "ʹ�� V2ray �ṩ��socks������������..."
			curl --connect-timeout 8 -s -L --socks5-hostname 127.0.0.1:1280 $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
		else
			echo_date "û�п��õ�socks5����˿ڣ����ó�����������..."
			curl --connect-timeout 8 -s -L $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
		fi
	else
		echo_date "ʹ�ó�����������..."
		curl --connect-timeout 8 -s -L $v2ray_subscribe_link > /tmp/v2ray_subscribe_file.txt
	fi

	#��ȻΪ0���ǻ���Ҫ������Ƿ����ص���ȷ������
	if [ "$?" == "0" ];then
		#���ĵ�ַ����ת
		blank=`cat /tmp/v2ray_subscribe_file.txt|grep -E " |Redirecting|301"`
		if [ -n "$blank" ];then
			echo_date �������ӿ�������ת�����Ը���wget��������...
			rm /tmp/v2ray_subscribe_file.txt
			if [ "`echo $v2ray_subscribe_link|grep ^https`" ];then
				wget --no-check-certificate -qO /tmp/v2ray_subscribe_file.txt $v2ray_subscribe_link
			else
				wget -qO /tmp/v2ray_subscribe_file.txt $v2ray_subscribe_link
			fi
		fi
		#����Ϊ��...
		if [ -z "`cat /tmp/v2ray_subscribe_file.txt`" ];then
			echo_date ����Ϊ��...
			return 3
		fi
		#��Ʒ��Ϣ����
		wrong1=`cat /tmp/v2ray_subscribe_file.txt|grep "{"`
		wrong2=`cat /tmp/v2ray_subscribe_file.txt|grep "<"`
		if [ -n "$wrong1" -o -n "$wrong2" ];then
			return 2
		fi
	else
		return 1
	fi

	if [ "$?" == "0" ];then
		echo_date ���ض��ĳɹ�...
		echo_date ��ʼ�����ڵ���Ϣ...
		decode_url_link `cat /tmp/v2ray_subscribe_file.txt` > /tmp/v2ray_subscribe_file_temp1.txt
		v2ray_group=`echo $v2ray_subscribe_link|awk -F'[/:]' '{print $4}'`
		# ���vmess
		NODE_FORMAT1=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -E "^ss://"`
		NODE_FORMAT2=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -E "^vmess://"`
		if [ -n "$NODE_FORMAT2" ];then
			# v2ray ����
			
			# detect format again
			if [ -n "$NODE_FORMAT1" ];then
				#vmess://�������ss://
				NODE_NU=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -Ec "vmess://|ss://|ssr://"`
				echo_date ��⵽vmess��ss�ڵ��ʽ������$NODE_NU���ڵ�...
				urllinks=$(decode_url_link `cat /tmp/v2ray_subscribe_file.txt` | sed 's/vmess:\/\///g')
			else
				#��vmess://
				NODE_NU=`cat /tmp/v2ray_subscribe_file_temp1.txt | grep -Ec "vmess://"`
				echo_date ��⵽vmess�ڵ��ʽ������$NODE_NU���ڵ�...
				urllinks=$(decode_url_link `cat /tmp/v2ray_subscribe_file.txt` | sed 's/vmess:\/\///g')
			fi

			remove_sub
			for link in $urllinks
			do
				decode_link=$(decode_url_link $link)
				decode_link=$(echo $decode_link|jq -c .)
				if [ -n "$decode_link" ];then
					get_v2ray_remote_config "$decode_link"
					[ "$?" == "0" ] && add_v2ray_servers || echo_date "��⵽һ������ڵ㣬�Ѿ�������"
				else
					echo_date "����ʧ�ܣ�����"
				fi
			done

			ONLINE_GET=$(dbus list v2ray_sub_tag_|wc -l) || 0
			echo_date "���θ��¶�����Դ ��$v2ray_group��"
			echo_date "�ֹ��ж���v2ray�ڵ㣺$ONLINE_GET ����"
			echo_date "���߶����б�������!"
			echo_date "���߶����б������Խ������б�����ʾ�����ڡ��˺����á�-�����������͡�ѡ�񡾶��ġ�ʹ�ã�"
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
	echo_date "                             V2ray ���������ĳ���"
	echo_date "==================================================================="
	echo_date "�� $url ��ȡ����..."
	addnum=0
	updatenum=0
	delnum=0
	get_oneline_rule_now "$url"

	case $? in
	0)
		continue
		;;
	2)
		echo_date "�޷���ȡ��Ʒ��Ϣ��������ķ������Ƿ�����˶������ӣ�"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "�˳����ĳ���..."
		exit
		;;
	3)
		echo_date "�ö������Ӳ������κνڵ���Ϣ��������ķ������Ƿ�����˶������ӣ�"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "�˳����ĳ���..."
		exit
		;;
	4)
		echo_date "���ĵ�ַ���󣡼�⵽������Ķ��ĵ�ַ�����Ǳ�׼��ַ��ʽ��"
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "�˳����ĳ���..."
		exit
		;;
	1|*)
		echo_date "���ض���ʧ��...�����������..."
		rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "�˳����ĳ���..."
		exit
		;;
	esac

	# ����
	echo_date "-------------------------------------------------------------------"
	echo_date "һ���������..."
	rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/v2ray_subscribe_file_temp1.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "���ж���������ɣ���ȴ�6�룬�����ֶ��رձ����ڣ�"
	echo_date "==================================================================="
}

add() {
	echo_date "==================================================================="
	echo_date ͨ��v2ray������ӽڵ�...
	rm -rf /tmp/v2ray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/v2ray_subscribe_file_temp1.txt >/dev/null 2>&1
	#echo_date �������Ϊ��`dbus get v2ray_base64_links`
	v2raylinks=`dbus get v2ray_base64_links|sed 's/$/\n/'|sed '/^$/d'`
	for v2raylink in $v2raylinks
	do
		if [ -n "$v2raylink" ];then
			if [ -n "`echo -n "$v2raylinks" | grep "vmess://"`" ]; then
				echo_date ��⵽vmess����...��ʼ���Խ���...
				new_v2raylink=`echo -n "$v2raylink" | sed 's/vmess:\/\///g'`
				decode_v2raylink=$(decode_url_link $new_v2raylink)
				decode_v2raylink=$(echo $decode_v2raylink|jq -c .)
				get_v2ray_remote_config $decode_v2raylink
				add_v2ray_servers 1
			else
				echo_date û�м�⵽vmess��Ϣ�����ʧ�ܣ���������...
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
			echo_date "�����Զ����¶��ķ�����ÿ�� $v2ray_basic_node_update_hr �㡣" >> $LOG_FILE
		else
			echo "0 $v2ray_basic_node_update_hr * * v2ray_basic_node_update_day /koolshare/scripts/v2ray_sub.sh 3 3 #v2raynodeupdate#" >> /etc/crontabs/root
			echo_date "�����Զ����¶��ķ��������� $v2ray_basic_node_update_day �� $v2ray_basic_node_update_hr �㡣" >> $LOG_FILE
		fi
	else
		echo_date "�Զ����¶��ķ����ѹرգ�" >> $LOG_FILE
		sed -i '/v2raynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	fi
}

remove_server(){
	# 2 ������е�ss�ڵ�����
	echo_date ɾ��������ͨ�ڵ���Ϣ��
	confs=`dbus list v2ray_server_ | cut -d "=" -f 1`
	for conf in $confs
	do
		#echo_date �Ƴ�$conf
		dbus remove $conf
	done
	dbus set v2ray_server_node_max=0
}

remove_sub(){
	# 2 ������е�ss�ڵ�����
	echo_date ɾ�����ж��Ľڵ���Ϣ��
	confs=`dbus list v2ray_sub_ | cut -d "=" -f 1`
	for conf in $confs
	do
		#echo_date �Ƴ�$conf
		dbus remove $conf
	done
	dbus set v2ray_sub_node_max=0
}

case $2 in
1)
	# ɾ�����нڵ�
	set_lock
	echo " " > $LOG_FILE
	remove_server >> $LOG_FILE
	remove_sub >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
2)
	# ɾ�����ж��Ľڵ�
	set_lock
	echo " " > $LOG_FILE
	remove_sub >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
3)
	# ���Ľڵ�
	set_lock
	echo " " > $LOG_FILE
	start_update >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
4)
	# �������v2ray
	set_lock
	echo " " > $LOG_FILE
	add >> $LOG_FILE
	unset_lock
	echo XU6J03M6 >> $LOG_FILE
	http_response "$1"
	;;
esac