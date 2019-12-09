#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/ss_base.sh
LOCK_FILE=/tmp/online_update.lock
CONFIG_FILE=/koolshare/ss/ss.json
BACKUP_FILE_TMP=/tmp/ss_conf_tmp.sh
BACKUP_FILE=/tmp/ss_conf.sh

KEY_WORDS_1=`echo $ss_basic_exclude|sed 's/,$//g'|sed 's/,/|/g'|sed 's/^$//g'`
KEY_WORDS_2=`echo $ss_basic_include|sed 's/,$//g'|sed 's/,/|/g'|sed 's/^$//g'`
DEL_SUBSCRIBE=0
SOCKS_FLAG=0

# 一个节点里可能有的所有信息
readonly PREFIX="ssconf_basic_name_
		ssconf_basic_server_
		ssconf_basic_mode_
		ssconf_basic_method_
		ssconf_basic_password_
		ssconf_basic_port_
		ssconf_basic_ss_obfs_
		ssconf_basic_ss_obfs_host_
		ssconf_basic_rss_obfs_
		ssconf_basic_rss_obfs_param_
		ssconf_basic_rss_protocol_
		ssconf_basic_rss_protocol_param_
		ssconf_basic_koolgame_udp_
		ssconf_basic_use_kcp_
		ssconf_basic_use_lb_
		ssconf_basic_lbmode_
		ssconf_basic_weight_
		ssconf_basic_group_
		ssconf_basic_v2ray_use_json_
		ssconf_basic_v2ray_uuid_
		ssconf_basic_v2ray_alterid_
		ssconf_basic_v2ray_security_
		ssconf_basic_v2ray_network_
		ssconf_basic_v2ray_headtype_tcp_
		ssconf_basic_v2ray_headtype_kcp_
		ssconf_basic_v2ray_network_path_
		ssconf_basic_v2ray_network_host_
		ssconf_basic_v2ray_network_security_
		ssconf_basic_v2ray_mux_enable_
		ssconf_basic_v2ray_mux_concurrency_
		ssconf_basic_v2ray_json_
		ssconf_basic_ss_v2ray_
		ssconf_basic_ss_v2ray_opts_
		ssconf_basic_type_"

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

get_type_name() {
	case "$1" in
		0)
			echo "SS"
		;;
		1)
			echo "SSR"
		;;
		2)
			echo "koolgame"
		;;
		3)
			echo "v2ray"
		;;
	esac
}

# 清除已有的所有节点配置
remove_all_node(){
	echo_date 删除所有节点信息！
	confs=`dbus list ssconf_basic_ | cut -d "=" -f 1`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
}

# 删除所有订阅节点
remove_sub_node(){
	echo_date 删除所有订阅节点信息...自添加的节点不受影响！
	remove_nus=`dbus list ssconf_basic_|grep _group_ | cut -d "=" -f 1 | cut -d "_" -f4 | sort -n`
	for remove_nu in $remove_nus
	do
		echo_date 移除第 $remove_nu 节点...
		for item in $PREFIX
		do
			dbus remove ${item}${remove_nu}
		done
	done
}

# 删除所有订阅节点，安静
remove_sub_node_silent(){
	local index=$1
	for item in $PREFIX
	do
		dbus remove ${item}${index}
	done
	let delnum+=1
}


prepare(){
	# 0 检测排序
	seq_nu=`dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -n|wc -l`
	seq_max_nu=`dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1`
	if [ "$seq_nu" == "$seq_max_nu" ];then
		echo_date "节点顺序正确，无需调整!"
		return 0
	fi 
	# -----------------
	# 1 提取干净的节点配置，并重新排序（这里基本用不上了，因为web上已经会自动排序）
	echo_date 备份shadowsocks节点信息...
	echo_date 如果节点数量过多，此处可能需要等待较长时间，请耐心等待...
	rm -rf $BACKUP_FILE_TMP
	rm -rf $BACKUP_FILE
	local i=1
	export -p | grep ssconf_basic_name_ | awk -F"=" '{print $1}' | awk -F"_" '{print $NF}' | sort -n | while read nu
	do
		for item in $PREFIX
		do
		{
			local tmp=$(eval echo \$$item$nu)
			echo "export $item$i=\"$tmp\"" >> $BACKUP_FILE_TMP
		} &
		done
		if [ "$nu" == "$ssconf_basic_node" ];then
			echo "export ssconf_basic_node=\"$i\"" >> $BACKUP_FILE_TMP
		fi
		if [ -n "$ss_failover_s4_3" && "$nu" == "$ss_failover_s4_3" ];then
			echo "export ss_failover_s4_3=\"$i\"" >> $BACKUP_FILE_TMP
		fi
		if [ -n "$ss_basic_udp_node" && "$nu" == "$ss_basic_udp_node" ];then
			echo "export ss_basic_udp_node=\"$i\"" >> $BACKUP_FILE_TMP
		fi
		let i+=1
	done
	cat $BACKUP_FILE_TMP|awk -F"=" '{print $0"|"$1}' | awk -F"_" '{print $NF"|"$0}' | sort -t "|" -nk1,1 | awk -F"|" '{print $2}' | sed '1 i\#------------------------' | sed '1 isource /koolshare/scripts/base.sh' | sed '1 i#!/bin/sh' | sed '/ssconf_basic_weight_/a\#------------------------' > $BACKUP_FILE
	echo "dbus save ssconf" >> $BACKUP_FILE
	chmod +x $BACKUP_FILE
	cp $BACKUP_FILE /koolshare/configs/ss_conf.sh
	echo_date 备份完毕...
	# -----------------
	# 2 应用之前提取的干净的节点配置
	echo_date 检查完毕！节点信息备份在/koolshare/configs/ss_conf.sh
	sh /koolshare/configs/ss_conf.sh
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

add_ss_servers(){
	ssindex=$(($(dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
	dbus set ssconf_basic_name_$ssindex=$remarks
	dbus set ssconf_basic_mode_$ssindex="2"
	dbus set ssconf_basic_server_$ssindex=$server
	dbus set ssconf_basic_port_$ssindex=$server_port
	dbus set ssconf_basic_method_$ssindex=$encrypt_method
	dbus set ssconf_basic_password_$ssindex=$password
	dbus set ssconf_basic_type_$ssindex="0"
	echo_date SS节点：新增加【$remarks】到节点列表第 $ssrindex 位。
}

get_ss_config(){
	decode_link=$1
	server=$(echo "$decode_link" |awk -F':' '{print $2}'|awk -F'@' '{print $2}')
	server_port=$(echo "$decode_link" |awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $1}')
	password=$(echo "$decode_link" |awk -F':' '{print $2}'|awk -F'@' '{print $1}')
	password=`echo $password|base64_encode`
}

get_v2ray_remote_config(){
	decode_link="$1"
	v2ray_group="$2"
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

	#把全部服务器节点编码后写入文件 /usr/share/shadowsocks/serverconfig/all_onlineservers
	[ -n "$v2ray_group" ] && group_base64=`echo $v2ray_group | base64_encode | sed 's/ -//g'`
	[ -n "$v2ray_add" ] && server_base64=`echo $v2ray_add | base64_encode | sed 's/ -//g'`	
	[ -n "$v2ray_group" ] && [ -n "$v2ray_add" ] && echo $server_base64 $group_base64 >> /tmp/all_onlineservers

	# for debug
	# echo ------------------
	# echo v2ray_v: $v2ray_v
	# echo v2ray_ps: $v2ray_ps
	# echo v2ray_add: $v2ray_add
	# echo v2ray_port: $v2ray_port
	# echo v2ray_id: $v2ray_id
	# echo v2ray_net: $v2ray_net
	# echo v2ray_type: $v2ray_type
	# echo v2ray_host: $v2ray_host
	# echo v2ray_path: $v2ray_path
	# echo v2ray_tls: $v2ray_tls
	# echo ------------------
	
	[ -z "$v2ray_ps" -o -z "$v2ray_add" -o -z "$v2ray_port" -o -z "$v2ray_id" -o -z "$v2ray_aid" -o -z "$v2ray_net" -o -z "$v2ray_type" ] && return 1 || return 0
}

add_v2ray_servers(){
	usleep 100000
	v2rayindex=$(($(dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
	[ -z "$1" ] && dbus set ssconf_basic_group_$v2rayindex=$v2ray_group
	dbus set ssconf_basic_type_$v2rayindex=3
	dbus set ssconf_basic_v2ray_mux_enable_$v2rayindex=0
	dbus set ssconf_basic_v2ray_use_json_$v2rayindex=0
	dbus set ssconf_basic_v2ray_security_$v2rayindex="auto"
	dbus set ssconf_basic_mode_$v2rayindex=$ssr_subscribe_mode
	dbus set ssconf_basic_name_$v2rayindex=$v2ray_ps
	dbus set ssconf_basic_port_$v2rayindex=$v2ray_port
	dbus set ssconf_basic_server_$v2rayindex=$v2ray_add
	dbus set ssconf_basic_v2ray_uuid_$v2rayindex=$v2ray_id
	dbus set ssconf_basic_v2ray_alterid_$v2rayindex=$v2ray_aid
	dbus set ssconf_basic_v2ray_network_security_$v2rayindex=$v2ray_tls
	dbus set ssconf_basic_v2ray_network_$v2rayindex=$v2ray_net
	case $v2ray_net in
	tcp)
		# tcp协议设置【 tcp伪装类型 (type)】和【伪装域名 (host)】
		dbus set ssconf_basic_v2ray_headtype_tcp_$v2rayindex=$v2ray_type
		[ -n "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_$v2rayindex=$v2ray_host
		;;
	kcp)
		# kcp协议设置【 kcp伪装类型 (type)】
		dbus set ssconf_basic_v2ray_headtype_kcp_$v2rayindex=$v2ray_type
		;;
	ws|h2)
		# ws/h2协议设置【 伪装域名 (host))】和【路径 (path)】
		[ -n "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_$v2rayindex=$v2ray_host
		[ -n "$v2ray_path" ] && dbus set ssconf_basic_v2ray_network_path_$v2rayindex=$v2ray_path
		;;
	esac
	echo_date v2ray节点：新增加 【$v2ray_ps】 到节点列表第 $v2rayindex 位。
}

update_v2ray_config(){
	isadded_server=$(cat /tmp/all_localservers | grep -w $group_base64 | awk '{print $1}' | grep -c $server_base64|head -n1)
	if [ "$isadded_server" == "0" ]; then
		add_v2ray_servers
		let addnum+=1
	else
		# 如果在本地的订阅节点中已经有该节点（用group和server去判断），检测下配置是否更改，如果更改，则更新配置
		index=$(cat /tmp/all_localservers| grep $group_base64 | grep $server_base64 |awk '{print $4}'|head -n1)

		local i=0
		dbus set ssconf_basic_mode_$index="$ssr_subscribe_mode"
		local_v2ray_ps=$(dbus get ssconf_basic_name_$index)
		[ "$local_v2ray_ps" != "$v2ray_ps" ] && dbus set ssconf_basic_name_$index=$v2ray_ps && let i+=1
		local_v2ray_add=$(dbus get ssconf_basic_server_$index)
		[ "$local_v2ray_add" != "$v2ray_add" ] && dbus set ssconf_basic_server_$index=$v2ray_add && let i+=1
		local_v2ray_port=$(dbus get ssconf_basic_port_$index)
		[ "$local_v2ray_port" != "$v2ray_port" ] && dbus set ssconf_basic_port_$index=$v2ray_port && let i+=1
		local_v2ray_id=$(dbus get ssconf_basic_v2ray_uuid_$index)
		[ "$local_v2ray_id" != "$v2ray_id" ] && dbus set ssconf_basic_v2ray_uuid_$index=$v2ray_id && let i+=1
		local_v2ray_aid=$(dbus get ssconf_basic_v2ray_alterid_$index)
		[ "$local_v2ray_aid" != "$v2ray_aid" ] && dbus set ssconf_basic_v2ray_alterid_$index=$v2ray_aid && let i+=1
		local_v2ray_tls=$(dbus get ssconf_basic_v2ray_network_security_$index)
		[ "$local_v2ray_tls" != "$v2ray_tls" ] && dbus set ssconf_basic_v2ray_network_security_$index=$v2ray_tls && let i+=1
		local_v2ray_net=$(dbus get ssconf_basic_v2ray_network_$index)
		[ "$local_v2ray_net" != "$v2ray_net" ] && dbus set ssconf_basic_v2ray_network_$index=$v2ray_net && let i+=1
		case $local_v2ray_net in
		tcp)
			# tcp协议
			local_v2ray_type=$(dbus get ssconf_basic_v2ray_headtype_tcp_$index)
			local_v2ray_host=$(dbus get ssconf_basic_v2ray_network_host_$index)
			[ "$local_v2ray_type" != "$v2ray_type" ] && dbus set ssconf_basic_v2ray_headtype_tcp_$index=$v2ray_type && let i+=1
			[ "$local_v2ray_host" != "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_$index=$v2ray_host && let i+=1
			;;
		kcp)
			# kcp协议
			local_v2ray_type=$(dbus get ssconf_basic_v2ray_headtype_kcp_$index)
			[ "$local_v2ray_type" != "$v2ray_type" ] && dbus set ssconf_basic_v2ray_headtype_kcp_$index=$v2ray_type && let i+=1
			;;
		ws|h2)
			# ws/h2协议
			local_v2ray_host=$(dbus get ssconf_basic_v2ray_network_host_$index)
			local_v2ray_path=$(dbus get ssconf_basic_v2ray_network_path_$index)
			[ "$local_v2ray_host" != "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_$index=$v2ray_host && let i+=1
			[ "$local_v2ray_path" != "$v2ray_path" ] && dbus set ssconf_basic_v2ray_network_path_$index=$v2ray_path && let i+=1
			;;
		esac

		if [ "$i" -gt "0" ];then
			echo_date 修改v2ray节点：【$v2ray_ps】 && let updatenum+=1
		else
			echo_date v2ray节点：【$v2ray_ps】 参数未发生变化，跳过！
		fi
	fi
}

get_ssr_node_info(){
	decode_link="$1"
	action="$2"
	server=$(echo "$decode_link"|awk -F':' '{print $1}'|sed 's/\s//g')
	server_port=$(echo "$decode_link"|awk -F':' '{print $2}')
	protocol=$(echo "$decode_link"|awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $4}')
	obfs=$(echo "$decode_link"|awk -F':' '{print $5}'|sed 's/_compatible//g')
	
	password=$(decode_url_link $(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}'))
	password=`echo $password|base64_encode|sed 's/\s//g'`
	
	obfsparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "obfsparam.+"|sed 's/obfsparam=//g'|awk -F'&' '{print $1}')
	[ -n "$obfsparam_temp" ] && obfsparam=$(decode_url_link $obfsparam_temp) || obfsparam=''
	
	protoparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "protoparam.+"|sed 's/protoparam=//g'|awk -F'&' '{print $1}')
	[ -n "$protoparam_temp" ] && protoparam=$(decode_url_link $protoparam_temp|sed 's/_compatible//g') || protoparam=''
	
	remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "remarks.+"|sed 's/remarks=//g'|awk -F'&' '{print $1}')
	if [ "$action" == "1" ];then
		#订阅
		[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp) || remarks=""
	elif [ "$action" == "2" ];then
		# ssr://添加
		[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp) || remarks='AutoSuB'
	fi
	
	group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "group.+"|sed 's/group=//g'|awk -F'&' '{print $1}')
	if [ "$action" == "1" ];then
		#订阅
		[ -n "$group_temp" ] && group=$(decode_url_link $group_temp) || group=""
	elif [ "$action" == "2" ];then
		# ssr://添加
		[ -n "$group_temp" ] && group=$(decode_url_link $group_temp) || group='AutoSuBGroup'
	fi

	[ -n "$group" ] && group_base64=`echo $group | base64_encode | sed 's/ -//g'`
	[ -n "$server" ] && server_base64=`echo $server | base64_encode | sed 's/ -//g'`	
	[ -n "$remarks" ] && remarks_base64=`echo $remarks | base64_encode | sed 's/ -//g'`	
	#把全部服务器节点写入文件 /usr/share/shadowsocks/serverconfig/all_onlineservers
	[ -n "$group" ] && [ -n "$server" ] && echo $server_base64 $group_base64 $remarks_base64 >> /tmp/all_onlineservers
	echo "$group" >> /tmp/all_group_info.txt
	#echo ------
	#echo group: $group
	#echo remarks: $remarks
	#echo server: $server
	#echo server_port: $server_port
	#echo password: $password
	#echo encrypt_method: $encrypt_method
	#echo protocol: $protocol
	#echo protoparam: $protoparam
	#echo obfs: $obfs
	#echo obfsparam: $obfsparam
	#echo ------
}

update_ssr_nodes(){
	local UPDATE_FLAG
	local DELETE_FLAG
	# 用关键词匹配不需要添加的节点
	[ -n "$KEY_WORDS_1" ] && local KEY_MATCH_1=`echo $remarks $server | grep -Eo "$KEY_WORDS_1"`
	# 用关键词匹配需要添加的节点
	[ -n "$KEY_WORDS_2" ] && local KEY_MATCH_2=`echo $remarks $server | grep -Eo "$KEY_WORDS_2"`

	if [ -n "$KEY_WORDS_1" -a -z "$KEY_WORDS_2" ]; then
		if [ -n "$KEY_MATCH_1" ]; then
			echo_date SSR节点：不添加【$remarks】节点，因为匹配了[排除]关键词
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			if [ -n "$group" ] && [ -n "$server" ] && [ -n "$server_port" ] && [ -n "$password" ] && [ -n "$protocol" ] && [ -n "$obfs" ] && [ -n "$encrypt_method" ]; then
				local UPDATE_FLAG=0
			else
				local UPDATE_FLAG=1
				echo_date "检测到一个错误节点，跳过！"
				return 1
			fi
		fi
	elif [ -z "$KEY_WORDS_1" -a -n "$KEY_WORDS_2" ]; then
		if [ -z "$KEY_MATCH_2" ];then
			echo_date SSR节点：不添加【$remarks】节点，因为不匹配[包括]关键词
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			if [ -n "$group" ] && [ -n "$server" ] && [ -n "$server_port" ] && [ -n "$password" ] && [ -n "$protocol" ] && [ -n "$obfs" ] && [ -n "$encrypt_method" ]; then
				local UPDATE_FLAG=0
			else
				local UPDATE_FLAG=1
				echo_date "检测到一个错误节点，跳过！"
				return 1
			fi
		fi
	elif [ -n "$KEY_WORDS_1" -a -n "$KEY_WORDS_2" ]; then
		if [ -n "$KEY_MATCH_1" -a -z "$KEY_MATCH_2" ]; then
			echo_date SSR节点：不添加【$remarks】节点，因为匹配了[排除+包括]关键词
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "$KEY_MATCH_1" -a -n "$KEY_MATCH_2" ]; then
			echo_date SSR节点：不添加【$remarks】节点，因为匹配了[排除]关键词
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "$KEY_MATCH_1" -a -z "$KEY_MATCH_2" ]; then
			echo_date SSR节点：不添加【$remarks】节点，因为不匹配[包括]关键词
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			if [ -n "$group" ] && [ -n "$server" ] && [ -n "$server_port" ] && [ -n "$password" ] && [ -n "$protocol" ] && [ -n "$obfs" ] && [ -n "$encrypt_method" ]; then
				local UPDATE_FLAG=0
			else
				local UPDATE_FLAG=1
				echo_date "检测到一个错误节点，跳过！"
				return 1
			fi
		fi
	else
		if [ -n "$group" ] && [ -n "$server" ] && [ -n "$server_port" ] && [ -n "$password" ] && [ -n "$protocol" ] && [ -n "$obfs" ] && [ -n "$encrypt_method" ]; then
			local UPDATE_FLAG=0
		else
			local UPDATE_FLAG=1
			echo_date "检测到一个错误节点，跳过！"
			return 1
		fi
	fi

	isadded_server=$(cat /tmp/all_localservers | grep $group_base64 | awk '{print $1}' | grep -c $server_base64|head -n1)
	if [ "$isadded_server" == "0" ]; then
		#在本地节点里没有找到对应节点，且没有被关键词排除，该节点需要被添加
		if [ "$UPDATE_FLAG" == "0" ]; then
			add_ssr_nodes
			[ "$ssr_subscribe_obfspara" == "0" ] && dbus set ssconf_basic_rss_obfs_param_$ssrindex=""
			[ "$ssr_subscribe_obfspara" == "1" ] && dbus set ssconf_basic_rss_obfs_param_$ssrindex="$obfsparam"
			[ "$ssr_subscribe_obfspara" == "2" ] && dbus set ssconf_basic_rss_obfs_param_$ssrindex="$ssr_subscribe_obfspara_val"
			let addnum+=1
		fi
	else
		# 获取已有节点在本地的index
		index_line=$(cat /tmp/all_localservers| grep $group_base64 | grep $server_base64 |awk '{print $4}'|wc -l)
		if [ "$index_line" == "1" ];then
			local index=$(cat /tmp/all_localservers| grep $group_base64 | grep $server_base64 |awk '{print $4}'|sed -n "$index_line p")
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件后依次去取节点号
			local tmp_file=$(echo $server_base64|sed 's/\=//g')
			if [ ! -f /tmp/multi_${tmp_file}.txt ] || [ $(cat /tmp/multi_${tmp_file}.txt |wc -l) == 0 ];then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/all_localservers| grep $group_base64 | grep $server_base64 |awk '{print $4}' > /tmp/multi_${tmp_file}.txt
			fi
			local index=$(cat /tmp/multi_${tmp_file}.txt|sed -n '1 p')
			sed -i '1d' /tmp/multi_${tmp_file}.txt
		fi
		
		# 在本地的订阅节点中找到该节点，但是该节点被用户定义定义的关键词过滤了，那么删除它
		local KEY_LOCAL_NAME=$(cat /tmp/all_localservers | grep $group_base64 | grep -w $index | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/all_localservers | grep $group_base64 | grep -w $index | awk '{print $1}'| base64 -d)

		# 删除匹配到[排除关键词]的本地节点
		[ -n "$KEY_WORDS_1" -a -n "$KEY_LOCAL_NAME" -a -n "$KEY_LOCAL_SERVER" ] && local KEY_MATCH_3=`echo $KEY_LOCAL_NAME $KEY_LOCAL_SERVER | grep -Eo "$KEY_WORDS_1"`
		# 删除未匹配到[包括关键词]的本地节点
		[ -n "$KEY_WORDS_2" -a -n "$KEY_LOCAL_NAME" -a -n "$KEY_LOCAL_SERVER" ] && local KEY_MATCH_4=`echo $KEY_LOCAL_NAME $KEY_LOCAL_SERVER | grep -Eo "$KEY_WORDS_2"`


		if [ -n "$KEY_WORDS_1" -a -z "$KEY_WORDS_2" ]; then
			if [ -n "$KEY_MATCH_3" ]; then
				echo_date SSR节点：移除本地【$remarks】节点，因为匹配了[排除]关键词
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "$KEY_WORDS_1" -a -n "$KEY_WORDS_2" ]; then
			if [ -z "$KEY_MATCH_4" ];then
				echo_date SSR节点：移除本地【$remarks】节点，因为不匹配[包括]关键词
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "$KEY_WORDS_1" -a -n "$KEY_WORDS_2" ]; then
			if [ -n "$KEY_MATCH_1" -a -z "$KEY_MATCH_2" ]; then
				echo_date SSR节点：移除本地【$remarks】节点，因为匹配了[排除+包括]关键词
				local DELETE_FLAG=1
			elif [ -n "$KEY_MATCH_1" -a -n "$KEY_MATCH_2" ]; then
				echo_date SSR节点：移除本地【$remarks】节点，因为匹配了[排除]关键词
				local DELETE_FLAG=1
			elif  [ -z "$KEY_MATCH_1" -a -z "$KEY_MATCH_2" ]; then
				echo_date SSR节点：移除本地【$remarks】节点，因为不匹配[包括]关键词
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		else
			local DELETE_FLAG=0
		fi

		if [ "$DELETE_FLAG" == "1" ]; then
			remove_sub_node_silent $index
		else
			# 在本地的订阅节点中找到该节点，检测下配置是否更改，如果更改，则更新配置
			local_remarks=$(dbus get ssconf_basic_name_$index)
			local_server_port=$(dbus get ssconf_basic_port_$index)
			local_protocol=$(dbus get ssconf_basic_rss_protocol_$index)
			local_protocol_param=$(dbus get ssconf_basic_rss_protocol_param_$index)
			local_encrypt_method=$(dbus get ssconf_basic_method_$index)
			local_obfs=$(dbus get ssconf_basic_rss_obfs_$index)
			local_password=$(dbus get ssconf_basic_password_$index)
			#local_group=$(dbus get ssconf_basic_group_$index)
			
			#echo update $index
			local i=0
			[ "$ssr_subscribe_obfspara" == "0" ] && dbus remove ssconf_basic_rss_obfs_param_$index
			[ "$ssr_subscribe_obfspara" == "1" ] && dbus set ssconf_basic_rss_obfs_param_$index="$obfsparam"
			[ "$ssr_subscribe_obfspara" == "2" ] && dbus set ssconf_basic_rss_obfs_param_$index="$ssr_subscribe_obfspara_val"
			dbus set ssconf_basic_mode_$index="$ssr_subscribe_mode"
			[ "$local_remarks" != "$remarks" ] && dbus set ssconf_basic_name_$index=$remarks && let i+=1
			[ "$local_server_port" != "$server_port" ] && dbus set ssconf_basic_port_$index=$server_port && let i+=1
			[ "$local_protocol" != "$protocol" ] && dbus set ssconf_basic_rss_protocol_$index=$protocol && let i+=1
			[ "$local_protocol_param"x != "$protoparam"x ] && dbus set ssconf_basic_rss_protocol_param_$index=$protoparam && let i+=1
			[ "$local_encrypt_method" != "$encrypt_method" ] && dbus set ssconf_basic_method_$index=$encrypt_method && let i+=1
			[ "$local_obfs" != "$obfs" ] && dbus set ssconf_basic_rss_obfs_$index=$obfs && let i+=1
			[ "$local_password" != "$password" ] && dbus set ssconf_basic_password_$index=$password && let i+=1
			if [ "$i" -gt "0" ];then
				echo_date 修改SSR节点：【$remarks】 && let updatenum+=1
			else
				echo_date SSR节点：【$remarks】 参数未发生变化，跳过！
			fi
		fi
	fi

	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo $group >> /tmp/sub_group_info.txt
}

add_ssr_nodes(){
	usleep 100000
	ssrindex=$(($(dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
	dbus set ssconf_basic_name_$ssrindex=$remarks
	[ -z "$1" ] && dbus set ssconf_basic_group_$ssrindex=$group
	dbus set ssconf_basic_mode_$ssrindex=$ssr_subscribe_mode
	dbus set ssconf_basic_server_$ssrindex=$server
	dbus set ssconf_basic_port_$ssrindex=$server_port
	dbus set ssconf_basic_rss_protocol_$ssrindex=$protocol
	dbus set ssconf_basic_rss_protocol_param_$ssrindex=$protoparam
	dbus set ssconf_basic_method_$ssrindex=$encrypt_method
	dbus set ssconf_basic_rss_obfs_$ssrindex=$obfs
	dbus set ssconf_basic_type_$ssrindex="1"
	[ -n "$1" ] && dbus set ssconf_basic_rss_obfs_param_$ssrindex=$obfsparam
	dbus set ssconf_basic_password_$ssrindex=$password
	echo_date SSR节点：新增加【$remarks】到节点列表第 $ssrindex 位。
}

del_none_exist(){
	# 删除订阅服务器已经不存在的节点
	for localserver in $(cat /tmp/all_localservers| grep $group_base64|awk '{print $1}')
	do
		if [ "`cat /tmp/all_onlineservers | grep -c $localserver`" -eq "0" ];then
			del_index=`cat /tmp/all_localservers | grep $localserver | awk '{print $4}'`
			#for localindex in $(dbus list ssconf_basic_server|grep -v ssconf_basic_server_ip_|grep -w $localserver|cut -d "_" -f 4 |cut -d "=" -f1)
			for localindex in $del_index
			do
				echo_date 删除节点：`dbus get ssconf_basic_name_$localindex` ，因为该节点在订阅服务器上已经不存在...
				for item in $PREFIX
				do
					dbus remove ${item}${localindex}
				done
				let delnum+=1
			done
		fi
	done
}

remove_node_gap(){
	SEQ=$(dbus list ssconf_basic_|grep _name_|cut -d "_" -f 4|cut -d "=" -f 1|sort -n)
	MAX=$(dbus list ssconf_basic_|grep _name_|cut -d "_" -f 4|cut -d "=" -f 1|sort -rn|head -n1)
	NODES_NU=$(dbus list ssconf_basic_|grep _name_|wc -l)
	KCP_NODE=`dbus get ss_kcp_node`
	
	#echo_date 现有节点顺序：$SEQ
	echo_date 最大节点序号：$MAX
	echo_date 共有节点数量：$NODES_NU
	
	if [ "$MAX" != "$NODES_NU" ];then
		echo_date 节点排序需要调整!
		y=1
		for nu in $SEQ
		do
			if [ "$y" == "$nu" ];then
				echo_date 节点 $y 不需要调整 !
			else
				echo_date 调整节点 $nu 到 节点$y !
				[ -n "$(dbus get ssconf_basic_group_$nu)" ] && dbus set ssconf_basic_group_"$y"="$(dbus get ssconf_basic_group_$nu)" && dbus remove ssconf_basic_group_$nu
				[ -n "$(dbus get ssconf_basic_method_$nu)" ] && dbus set ssconf_basic_method_"$y"="$(dbus get ssconf_basic_method_$nu)" && dbus remove ssconf_basic_method_$nu
				[ -n "$(dbus get ssconf_basic_mode_$nu)" ] && dbus set ssconf_basic_mode_"$y"="$(dbus get ssconf_basic_mode_$nu)" && dbus remove ssconf_basic_mode_$nu
				[ -n "$(dbus get ssconf_basic_name_$nu)" ] && dbus set ssconf_basic_name_"$y"="$(dbus get ssconf_basic_name_$nu)" && dbus remove ssconf_basic_name_$nu
				[ -n "$(dbus get ssconf_basic_password_$nu)" ] && dbus set ssconf_basic_password_"$y"="$(dbus get ssconf_basic_password_$nu)" && dbus remove ssconf_basic_password_$nu
				[ -n "$(dbus get ssconf_basic_port_$nu)" ] && dbus set ssconf_basic_port_"$y"="$(dbus get ssconf_basic_port_$nu)" && dbus remove ssconf_basic_port_$nu
				[ -n "$(dbus get ssconf_basic_rss_obfs_$nu)" ] && dbus set ssconf_basic_rss_obfs_"$y"="$(dbus get ssconf_basic_rss_obfs_$nu)" && dbus remove ssconf_basic_rss_obfs_$nu
				[ -n "$(dbus get ssconf_basic_rss_obfs_param_$nu)" ] && dbus set ssconf_basic_rss_obfs_param_"$y"="$(dbus get ssconf_basic_rss_obfs_param_$nu)" && dbus remove ssconf_basic_rss_obfs_param_$nu
				[ -n "$(dbus get ssconf_basic_rss_protocol_$nu)" ] && dbus set ssconf_basic_rss_protocol_"$y"="$(dbus get ssconf_basic_rss_protocol_$nu)" && dbus remove ssconf_basic_rss_protocol_$nu
				[ -n "$(dbus get ssconf_basic_rss_protocol_param_$nu)" ] && dbus set ssconf_basic_rss_protocol_param_"$y"="$(dbus get ssconf_basic_rss_protocol_param_$nu)" && dbus remove ssconf_basic_rss_protocol_param_$nu
				[ -n "$(dbus get ssconf_basic_server_$nu)" ] && dbus set ssconf_basic_server_"$y"="$(dbus get ssconf_basic_server_$nu)" && dbus remove ssconf_basic_server_$nu
				[ -n "$(dbus get ssconf_basic_server_ip_$nu)" ] && dbus set ssconf_basic_server_ip_"$y"="$(dbus get ssconf_basic_server_ip_$nu)" && dbus remove ssconf_basic_server_ip_$nu
				[ -n "$(dbus get ssconf_basic_ss_obfs_host_$nu)" ] && dbus set ssconf_basic_ss_obfs_host_"$y"="$(dbus get ssconf_basic_ss_obfs_host_$nu)" && dbus remove ssconf_basic_ss_obfs_host_$nu
				[ -n "$(dbus get ssconf_basic_use_kcp_$nu)" ] && dbus set ssconf_basic_use_kcp_"$y"="$(dbus get ssconf_basic_use_kcp_$nu)" && dbus remove ssconf_basic_use_kcp_$nu
				[ -n "$(dbus get ssconf_basic_use_lb_$nu)" ] && dbus set ssconf_basic_use_lb_"$y"="$(dbus get ssconf_basic_use_lb_$nu)" && dbus remove ssconf_basic_use_lb_$nu
				[ -n "$(dbus get ssconf_basic_lbmode_$nu)" ] && dbus set ssconf_basic_lbmode_"$y"="$(dbus get ssconf_basic_lbmode_$nu)" && dbus remove ssconf_basic_lbmode_$nu
				[ -n "$(dbus get ssconf_basic_weight_$nu)" ] && dbus set ssconf_basic_weight_"$y"="$(dbus get ssconf_basic_weight_$nu)" && dbus remove ssconf_basic_weight_$nu
				[ -n "$(dbus get ssconf_basic_koolgame_udp_$nu)" ] && dbus set ssconf_basic_koolgame_udp_"$y"="$(dbus get ssconf_basic_koolgame_udp_$nu)" && dbus remove ssconf_basic_koolgame_udp_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_use_json_$nu)" ] && dbus set ssconf_basic_v2ray_use_json_"$y"="$(dbus get ssconf_basic_v2ray_use_json_$nu)" && dbus remove ssconf_basic_v2ray_use_json_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_uuid_$nu)" ] && dbus set ssconf_basic_v2ray_uuid_"$y"="$(dbus get ssconf_basic_v2ray_uuid_$nu)" && dbus remove ssconf_basic_v2ray_uuid_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_alterid_$nu)" ] && dbus set ssconf_basic_v2ray_alterid_"$y"="$(dbus get ssconf_basic_v2ray_alterid_$nu)" && dbus remove ssconf_basic_v2ray_alterid_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_security_$nu)" ] && dbus set ssconf_basic_v2ray_security_"$y"="$(dbus get ssconf_basic_v2ray_security_$nu)" && dbus remove ssconf_basic_v2ray_security_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_network_$nu)" ] && dbus set ssconf_basic_v2ray_network_"$y"="$(dbus get ssconf_basic_v2ray_network_$nu)" && dbus remove ssconf_basic_v2ray_network_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_headtype_tcp_$nu)" ] && dbus set ssconf_basic_v2ray_headtype_tcp_"$y"="$(dbus get ssconf_basic_v2ray_headtype_tcp_$nu)" && dbus remove ssconf_basic_v2ray_headtype_tcp_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_headtype_kcp_$nu)" ] && dbus set ssconf_basic_v2ray_headtype_kcp_"$y"="$(dbus get ssconf_basic_v2ray_headtype_kcp_$nu)" && dbus remove ssconf_basic_v2ray_headtype_kcp_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_network_path_$nu)" ] && dbus set ssconf_basic_v2ray_network_path_"$y"="$(dbus get ssconf_basic_v2ray_network_path_$nu)" && dbus remove ssconf_basic_v2ray_network_path_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_network_host_$nu)" ] && dbus set ssconf_basic_v2ray_network_host_"$y"="$(dbus get ssconf_basic_v2ray_network_host_$nu)" && dbus remove ssconf_basic_v2ray_network_host_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_network_security_$nu)" ] && dbus set ssconf_basic_v2ray_network_security_"$y"="$(dbus get ssconf_basic_v2ray_network_security_$nu)" && dbus remove ssconf_basic_v2ray_network_security_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_mux_enable_$nu)" ] && dbus set ssconf_basic_v2ray_mux_enable_"$y"="$(dbus get ssconf_basic_v2ray_mux_enable_$nu)" && dbus remove ssconf_basic_v2ray_mux_enable_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_mux_concurrency_$nu)" ] && dbus set ssconf_basic_v2ray_mux_concurrency_"$y"="$(dbus get ssconf_basic_v2ray_mux_concurrency_$nu)" && dbus remove ssconf_basic_v2ray_mux_concurrency_$nu
				[ -n "$(dbus get ssconf_basic_v2ray_json_$nu)" ] && dbus set ssconf_basic_v2ray_json_"$y"="$(dbus get ssconf_basic_v2ray_json_$nu)" && dbus remove ssconf_basic_v2ray_json_$nu
				[ -n "$(dbus get ssconf_basic_ss_v2ray_opts_$nu)" ] && dbus set ssconf_basic_ss_v2ray_opts_"$y"="$(dbus get ssconf_basic_ss_v2ray_opts_$nu)" && dbus remove ssconf_basic_ss_v2ray_opts_$nu
				[ -n "$(dbus get ssconf_basic_ss_v2ray_$nu)" ] && dbus set ssconf_basic_ss_v2ray_"$y"="$(dbus get ssconf_basic_ss_v2ray_$nu)" && dbus remove ssconf_basic_ss_v2ray_$nu
				[ -n "$(dbus get ssconf_basic_type_$nu)" ] && dbus set ssconf_basic_type_"$y"="$(dbus get ssconf_basic_type_$nu)" && dbus remove ssconf_basic_type_$nu
				usleep 100000
				# change node nu
				if [ "$nu" == "$ssconf_basic_node" ];then
					dbus set ssconf_basic_node="$y"
				fi
				if [ -n "$ss_failover_s4_3" && "$nu" == "$ss_failover_s4_3" ];then
					dbus set ss_failover_s4_3="$y"
				fi
				if [ -n "$ss_basic_udp_node" && "$nu" == "$ss_basic_udp_node" ];then
					dbus set ss_basic_udp_node="$y"
				fi
			fi
			let y+=1
		done
	else
		echo_date 节点排序正确!
	fi
}

open_socks_23456(){
	socksopen_a=`netstat -nlp|grep -w 23456|grep -E "local|v2ray"`
	if [ -z "$socksopen_a" ];then
		if [ "$ss_basic_type" == "1" ];then
			SOCKS_FLAG=1
			echo_date 开启ssr-local，提供socks5代理端口：23456
			rss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			SOCKS_FLAG=2
			echo_date 开启ss-local，提供socks5代理端口：23456
			if [ "$ss_basic_ss_obfs" == "0" ] && [ "$ss_basic_ss_v2ray" == "0" ];then
				ss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
			else
				ss-local -l 23456 -c $CONFIG_FILE $ARG_OBFS -u -f /var/run/sslocal1.pid >/dev/null 2>&1
			fi
		fi
	fi
	sleep 2
}

get_oneline_rule_now(){
	# ss订阅
	ssr_subscribe_link="$1"
	LINK_FORMAT=`echo "$ssr_subscribe_link" | grep -E "^http://|^https://"`
	[ -z "$LINK_FORMAT" ] && return 4
	
	echo_date "开始更新在线订阅列表..." 
	echo_date "开始下载订阅链接到本地临时文件，请稍等..."
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	
	if [ "$ss_basic_online_links_goss" == "1" ];then
		open_socks_23456
		socksopen_b=`netstat -nlp|grep -w 23456|grep -E "local|v2ray"`
		if [ -n "$socksopen_b" ];then
			echo_date "使用$(get_type_name $ss_basic_type)提供的socks代理网络下载..."
			echo_date "下载地址：$ssr_subscribe_link"
			curl --connect-timeout 8 -s -L --socks5-hostname 127.0.0.1:23456 $ssr_subscribe_link > /tmp/ssr_subscribe_file.txt
		else
			echo_date "没有可用的socks5代理端口，改用常规网络下载..."
			curl --connect-timeout 8 -s -L $ssr_subscribe_link > /tmp/ssr_subscribe_file.txt
		fi
	else
		echo_date "使用常规网络下载..."
		curl --connect-timeout 8 -s -L $ssr_subscribe_link > /tmp/ssr_subscribe_file.txt
	fi

	#虽然为0但是还是要检测下是否下载到正确的内容
	if [ "$?" == "0" ];then
		#订阅地址有跳转
		blank=`cat /tmp/ssr_subscribe_file.txt|grep -E " |Redirecting|301"`
		if [ -n "$blank" ];then
			echo_date 订阅链接可能有跳转，尝试更换wget进行下载...
			rm /tmp/ssr_subscribe_file.txt
			if [ "`echo $ssr_subscribe_link|grep ^https`" ];then
				wget --no-check-certificate --timeout=15 -qO /tmp/ssr_subscribe_file.txt $ssr_subscribe_link
			else
				wget -qO /tmp/ssr_subscribe_file.txt $ssr_subscribe_link
			fi
		fi
		#下载为空...
		if [ -z "`cat /tmp/ssr_subscribe_file.txt`" ];then
			echo_date 下载为空...
			return 3
		fi
		#产品信息错误
		wrong1=`cat /tmp/ssr_subscribe_file.txt|grep "{"`
		wrong2=`cat /tmp/ssr_subscribe_file.txt|grep "<"`
		if [ -n "$wrong1" -o -n "$wrong2" ];then
			return 2
		fi
	else
		echo_date 使用curl下载订阅失败，尝试更换wget进行下载...
		rm /tmp/ssr_subscribe_file.txt
		if [ "`echo $ssr_subscribe_link|grep ^https`" ];then
			wget --no-check-certificate --timeout=15 -qO /tmp/ssr_subscribe_file.txt $ssr_subscribe_link
		else
			wget -qO /tmp/ssr_subscribe_file.txt $ssr_subscribe_link
		fi

		if [ "$?" == "0" ];then
			#下载为空...
			if [ -z "`cat /tmp/ssr_subscribe_file.txt`" ];then
				echo_date 下载为空...
				return 3
			fi
			#产品信息错误
			wrong1=`cat /tmp/ssr_subscribe_file.txt|grep "{"`
			wrong2=`cat /tmp/ssr_subscribe_file.txt|grep "<"`
			if [ -n "$wrong1" -o -n "$wrong2" ];then
				return 2
			fi
		else
			return 1
		fi
	fi

	if [ "$?" == "0" ];then
		#删除上一个订阅的group信息
		rm -rf /tmp/sub_group_info.txt
		echo_date 下载订阅成功...
		echo_date 开始解析节点信息...
		decode_url_link `cat /tmp/ssr_subscribe_file.txt` > /tmp/ssr_subscribe_file_temp1.txt
		# 检测ss ssr vmess
		NODE_FORMAT1=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^ss://"`
		NODE_FORMAT2=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^ssr://"`
		NODE_FORMAT3=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^vmess://"`
		if [ -n "$NODE_FORMAT2" ];then
			# SSR 订阅
			NODE_NU=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -c "ssr://"`
			echo_date 检测到ssr节点格式，共计$NODE_NU个节点...
			#判断格式
			maxnum=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` | grep "MAX=" | awk -F"=" '{print $2}' | grep -Eo "[0-9]+")
			if [ -n "$maxnum" ]; then
				# 如果机场订阅解析后有MAX=xx字段存在，那么随机选取xx个节点，并去掉ssr://头部标识
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` | sed '/MAX=/d' | shuf -n $maxnum | sed 's/ssr:\/\///g')
			else
				# 生成全部节点的节点信息，并去掉ssr://头部标识
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` | sed 's/ssr:\/\///g')
			fi
			[ -z "$urllinks" ] && continue
			# 针对每个节点进行解码：decode_link，解析：get_ssr_node_info，添加/修改：update_ssr_nodes
 			for link in $urllinks
			do
				decode_link=$(decode_url_link $link)
				get_ssr_node_info $decode_link 1
				update_ssr_nodes
			done
			# 储存对应订阅链接的group信息
			group=`cat /tmp/sub_group_info.txt|sort -u|sed 's/$/ + /g'|sed ':a;N;$!ba;s#\n##g'|sed 's/\s+\s$//g'`
			if [ -n "$group" ];then
				dbus set ss_online_group_$z=$group
				echo $group >> /tmp/group_info.txt
			else
				# 如果最后一个节点是空的，那么使用这种方式去获取group名字
				group=`cat /tmp/all_group_info.txt | sort -u | tail -n1`
				[ -n "$group" ] && dbus set ss_online_group_$z=$group
				[ -n "$group" ] && echo $group >> /tmp/group_info.txt
			fi
			# 去除订阅服务器上已经删除的节点
			del_none_exist
			USER_ADD=$(($(dbus list ssconf_basic_|grep _name_|wc -l) - $(dbus list ssconf_basic_|grep _group_|wc -l))) || 0
			ONLINE_GET=$(dbus list ssconf_basic_|grep _group_|wc -l) || 0
			echo_date "本次更新订阅来源【$group】，共有节点$NODE_NU个，其中："
			echo_date "因关键词排除节点$exclude个，新增节点 $addnum个，修改 $updatenum个，删除 $delnum个；"
			echo_date "现共有自添加SSR节点：$USER_ADD 个；"
			echo_date "现共有订阅SSR节点：$ONLINE_GET 个；"
			echo_date "在线订阅列表更新完成!"
		elif [ -n "$NODE_FORMAT3" ];then
			# v2ray 订阅
			
			# use domain as group
			v2ray_group_tmp=`echo $ssr_subscribe_link|awk -F'[/:]' '{print $4}'`
			# 储存对应订阅链接的group信息
			dbus set ss_online_group_$z=$v2ray_group_tmp
			echo $v2ray_group_tmp >> /tmp/group_info.txt

			# detect format again
			if [ -n "$NODE_FORMAT1" ];then
				#vmess://里夹杂着ss://
				NODE_NU=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -Ec "vmess://|ss://"`
				echo_date 检测到vmess和ss节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` | sed 's/ssr:\/\///g')
			else
				#纯vmess://
				NODE_NU=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -Ec "vmess://"`
				echo_date 检测到vmess节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link `cat /tmp/ssr_subscribe_file.txt` | sed 's/vmess:\/\///g')
				for link in $urllinks
				do
					decode_link=$(decode_url_link $link)
					decode_link=$(echo $decode_link|jq -c .)
					if [ -n "$decode_link" ];then
						get_v2ray_remote_config "$decode_link" "$v2ray_group_tmp"
						[ "$?" == "0" ] && update_v2ray_config || echo_date "检测到一个错误节点，已经跳过！"
					else
						echo_date "解析失败！！！"
					fi
				done
			fi

			# 去除订阅服务器上已经删除的节点
			del_none_exist
			# 节点重新排序
			# remove_node_gap
			USER_ADD=$(($(dbus list ssconf_basic_|grep _name_|wc -l) - $(dbus list ssconf_basic_|grep _group_|wc -l))) || 0
			#TOTAL_V2=$(dbus list ssconf_basic_|grep _uuid_|wc -l) || 0
			#TOTAL_GET_SSR=$(dbus list ssconf_basic_|grep _rss_protocol_|wc -l) || 0
			ONLINE_GET=$(dbus list ssconf_basic_|grep _group_|wc -l) || 0
			echo_date "本次更新订阅来源 【$v2ray_group】， 新增节点 $addnum 个，修改 $updatenum 个，删除 $delnum 个；"
			echo_date "现共有自添加节点：$USER_ADD 个。"
			echo_date "现共有订阅SSR/v2ray节点：$ONLINE_GET 个。"
			echo_date "在线订阅列表更新完成!"			
		elif [ -n "$NODE_FORMAT1" ];then
			echo_date 暂时不支持ss节点订阅...
			echo_date 退出订阅程序...
		else
			return 3
		fi
	else
		return 1
	fi
}

# 使用订阅链接订阅ssr/v2ray节点
start_online_update(){
	prepare
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/all_group_info.txt >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	usleep 100000
	echo_date "收集本地节点名到文件"
	LOCAL_NODES=`dbus list ssconf_basic_|grep _group_|cut -d "_" -f 4|cut -d "=" -f 1|sort -n`
	if [ -n "$LOCAL_NODES" ];then
		for LOCAL_NODE in $LOCAL_NODES
		do
			# write: server group nu
			echo `dbus get ssconf_basic_server_$LOCAL_NODE|base64_encode` `dbus get ssconf_basic_group_$LOCAL_NODE|base64_encode` `dbus get ssconf_basic_name_$LOCAL_NODE|base64_encode` | eval echo `sed 's/$/ $LOCAL_NODE/g'` >> /tmp/all_localservers
		done
	else
		touch /tmp/all_localservers
	fi
	
	local z=0
	online_url_nu=`dbus get ss_online_links|base64_decode|sed 's/$/\n/'|sed '/^$/d'|wc -l`
	#echo_date online_url_nu $online_url_nu
	until [ "$z" == "$online_url_nu" ]
	do
		z=$(($z+1))
		#url=`dbus get ss_online_link_$z`
		url=`dbus get ss_online_links|base64_decode|awk '{print $1}'|sed -n "$z p"|sed '/^#/d'`
		[ -z "$url" ] && continue
		echo_date "==================================================================="
    	echo_date "                服务器订阅程序(Shell by stones & sadog)"
    	echo_date "==================================================================="
		echo_date "从 $url 获取订阅..."
		addnum=0
		updatenum=0
		delnum=0
		exclude=0
		get_oneline_rule_now "$url"

		case $? in
		0)
			continue
			;;
		2)
			echo_date "无法获取产品信息！请检查你的服务商是否更换了订阅链接！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1 &
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		3)
			echo_date "该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1 &
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		4)
			echo_date "订阅地址错误！检测到你输入的订阅地址并不是标准网址格式！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1 &
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		1|*)
			echo_date "下载订阅失败，请检查你的网络..."
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1 &
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		esac
	done

	if [ "$DEL_SUBSCRIBE" == "0" ];then
		# 尝试删除去掉订阅链接对应的节点
		local_groups=`dbus list ssconf_basic_group_|cut -d "=" -f2|sort -u`
		if [ -f "/tmp/group_info.txt" ];then
			for local_group in $local_groups
			do
				MATCH=`cat /tmp/group_info.txt | grep $local_group`
				if [ -z "$MATCH" ];then
					echo_date "==================================================================="
					echo_date 【$local_group】 节点已经不再订阅，将进行删除... 
					confs_nu=`dbus list ssconf |grep "$local_group"| cut -d "=" -f 1|cut -d "_" -f 4`
					for conf_nu in $confs_nu
					do
						for item in $PREFIX
						do
							dbus remove ${item}${conf_nu}
						done
					done
					# 删除不再订阅节点的group信息
					confs_nu_2=`dbus list ss_online_group_|grep "$local_group"| cut -d "=" -f 1|cut -d "_" -f 4`
					if [ -n "$confs_nu_2" ];then
						for conf_nu_2 in $confs_nu_2
						do
							dbus remove ss_online_group_$conf_nu_2
						done
					fi
					echo_date 删除完成完成！
					need_adjust=1
				fi
			done
			# usleep 100000
			# # 再次排序
			# if [ "$need_adjust" == "1" ];then
			# 	echo_date 因为进行了删除订阅节点操作，需要对节点顺序进行检查！
			# 	remove_node_gap
			# fi
		fi
	else
		echo_date "由于订阅过程有失败，本次不检测需要删除的订阅，以免误伤；下次成功订阅后再进行检测。"
	fi
	# 节点重新排序
	remove_node_gap
	# 结束
	echo_date "-------------------------------------------------------------------"
	if [ "$SOCKS_FLAG" == "1" ];then
		ssrlocal=`ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
		if [ -n "$ssrlocal" ];then 
			echo_date 关闭因订阅临时开启的ssr-local进程:23456端口...
			kill $ssrlocal  >/dev/null 2>&1
		fi
	elif [ "$SOCKS_FLAG" == "2" ];then
		sslocal=`ps | grep -w ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
		if [ -n "$sslocal" ];then 
			echo_date  关闭因订阅临时开启ss-local进程:23456端口...
			kill $sslocal  >/dev/null 2>&1
		fi
	fi
	usleep 100000
	echo_date "一点点清理工作..."
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/all_group_info.txt >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	rm -rf /tmp/sub_group_info.txt >/dev/null 2>&1
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
}

# 添加ss:// ssr:// vmess://离线节点
start_offline_update() {
	echo_date "==================================================================="
	usleep 100000
	echo_date 通过SS/SSR/v2ray链接添加节点...
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/all_group_info.txt >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	#echo_date 添加链接为：`dbus get ss_base64_links`
	ssrlinks=`dbus get ss_base64_links|sed 's/$/\n/'|sed '/^$/d'`
	for ssrlink in $ssrlinks
	do
		if [ -n "$ssrlink" ];then
			if [ -n "`echo -n "$ssrlink" | grep "ssr://"`" ]; then
				echo_date 检测到SSR链接...开始尝试解析...
				new_ssrlink=`echo -n "$ssrlink" | sed 's/ssr:\/\///g'`
				decode_ssrlink=$(decode_url_link $new_ssrlink)
				get_ssr_node_info $decode_ssrlink 2
				add_ssr_nodes 1
			elif [ -n "`echo -n "$ssrlink" | grep "vmess://"`" ]; then
				echo_date 检测到vmess链接...开始尝试解析...
				new_v2raylink=`echo -n "$ssrlink" | sed 's/vmess:\/\///g'`
				decode_v2raylink=$(decode_url_link $new_v2raylink)
				decode_v2raylink=$(echo $decode_v2raylink|jq -c .)
				get_v2ray_remote_config $decode_v2raylink
				add_v2ray_servers 1
			elif [ -n "`echo -n "$ssrlink" | grep "ss://"`" ]; then
				echo_date 检测到SS链接...开始尝试解析...
				if [ -n "`echo -n "$ssrlink" | grep "#"`" ];then
					new_sslink=`echo -n "$ssrlink" | awk -F'#' '{print $1}' | sed 's/ss:\/\///g'`
					remarks=`echo -n "$ssrlink" | awk -F'#' '{print $2}'`
				else
					new_sslink=`echo -n "$ssrlink" | sed 's/ss:\/\///g'`
					remarks='AddByLink'
				fi
				decode_sslink=$(decode_url_link $new_sslink)
				get_ss_config $decode_sslink
				add_ss_servers
			fi
		fi
		dbus remove ss_base64_links
	done
	echo_date "==================================================================="
}

case $2 in
0)
	# 删除所有节点
	set_lock
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_all_node >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	unset_lock
	;;
1)
	# 删除所有订阅节点
	set_lock
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_sub_node >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	unset_lock
	;;
2)
	# 保存订阅设置但是不订阅
	set_lock
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	local_groups=`dbus list ssconf_basic_|grep group|cut -d "=" -f2|sort -u|wc -l`
	online_group=`dbus get ss_online_links|base64_decode|sed 's/$/\n/'|sed '/^$/d'|wc -l`
	echo_date "保存订阅节点成功，现共有 $online_group 组订阅来源，当前节点列表内已经订阅了 $local_groups 组..." >> /tmp/upload/ss_log.txt
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ];then
		if [ "$ss_basic_node_update_day" = "7" ];then
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置自动更新订阅服务在每天 $ss_basic_node_update_hr 点。" >> /tmp/upload/ss_log.txt
		else
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * $ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置自动更新订阅服务在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。" >> /tmp/upload/ss_log.txt
		fi
	else
		echo_date "关闭自动更新订阅服务！" >> /tmp/upload/ss_log.txt
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	unset_lock
	;;
3)
	# 使用订阅链接订阅ssr/v2ray节点
	set_lock
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	echo_date "开始订阅" >> /tmp/upload/ss_log.txt
	start_online_update >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	unset_lock
	;;
4)
	# 添加ss:// ssr:// vmess://离线节点
	set_lock
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	start_offline_update >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	unset_lock
	;;
5)
	prepare
	;;
esac
