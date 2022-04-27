#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/ss_base.sh

LOCK_FILE=/var/lock/online_update.lock
LOG_FILE=/tmp/upload/ss_log.txt
CONFIG_FILE=/koolshare/ss/ss.json
BACKUP_FILE_TMP=/tmp/ss_conf_tmp.sh
BACKUP_FILE=/tmp/ss_conf.sh
KEY_WORDS_1=$(echo $ss_basic_exclude | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_2=$(echo $ss_basic_include | sed 's/,$//g' | sed 's/,/|/g')
DEL_SUBSCRIBE=0
NODES_SEQ=$(export -p | grep ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
#NODE_INDEX=${NODES_SEQ##*[[:space:]]}
NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
alias urldecode='sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"'

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
	exec 233>"${LOCK_FILE}"
	flock -n 233 || {
		local PID1=$$
		local PID2=$(ps|grep -w "ss_online_update.sh"|grep -vw "grep"|grep -vw ${PID1})
		if [ -n "${PID2}" ];then
			echo_date "订阅脚本已经在运行，请稍候再试！"
			exit 1			
		else
			rm -rf ${LOCK_FILE}
		fi
	}
}

unset_lock(){
	flock -u 233
	rm -rf "${LOCK_FILE}"
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

remove_node_info(){
	local MAX_INFO=$(dbus list ss_online_hash|cut -d "=" -f1|awk -F"_" '{print $NF}'|sort -n|tail -n1)
	local CUR_INFO="0"
	until [ "${CUR_INFO}" == "${MAX_INFO}" ]; do
		let CUR_INFO+=1
		dbus remove ss_online_hash_${CUR_INFO}
		dbus remove ss_online_group_${CUR_INFO}
	done
}

# 清除已有的所有节点配置
remove_all_node(){
	echo_date "删除所有节点信息！"
	confs=$(export -p | grep ssconf_basic_ | cut -d "=" -f1 | awk '{print $NF}')
	for conf in ${confs}
	do
		echo_date "移除配置：${conf}"
		dbus remove ${conf}
	done
	remove_node_info
}

# 删除所有订阅节点
remove_sub_node(){
	echo_date "删除所有订阅节点信息...自添加的节点不受影响！"
	remove_node_info
	remove_nus=$(export -p | grep ssconf_basic_ | grep _group_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
	if [ -z "${remove_nus}" ]; then
		echo_date "节点列表内不存在任何订阅来源节点，退出！"
		return 1
	fi
	for remove_nu in ${remove_nus}
	do
		echo_date "移除第$remove_nu节点：【$(eval echo \$ssconf_basic_name_${remove_nu})】"
		for item in ${PREFIX}
		do
			dbus remove ${item}${remove_nu}
		done
	done
	echo_date "所有订阅节点信息已经成功删除！"
}

prepare(){
	echo_date "开始节点数据检查..."
	local REASON=0
	local SEQ_NU=$(echo ${NODES_SEQ} | tr ' ' '\n' | sed '/^$/d' |wc -l)
	if [ "${SEQ_NU}" == "0" ];then
		echo_date "无本地节点，继续！"
		return
	fi
	local MAX_NU=${NODE_INDEX}
	local KEY_NU=$(export -p | grep ssconf_basic | cut -d "=" -f1 | sed '/^$/d' | wc -l)
	local VAL_NU=$(export -p | grep ssconf_basic | cut -d "=" -f2 | sed '/^$/d' | wc -l)
	echo_date "最大节点序号：${MAX_NU}"
	echo_date "共有节点数量：${SEQ_NU}"

	# 如果[节点数量 ${SEQ_NU}]不等于[最大节点序号 ${MAX_NU}]，说明节点排序是不正确的。
	if [ ${SEQ_NU} -ne ${MAX_NU} ]; then
		let REASON+=1
		echo_date "节点顺序不正确，需要调整！"
	fi

	# 如果key的数量不等于value的数量，说明有些key储存了空值，需要清理一下。
	if [ ${KEY_NU} -ne ${VAL_NU} ]; then
		let REASON+=2
		echo_date "节点配置有残余值，需要清理！"
	fi

	if [ ${REASON} == "1" -o ${REASON} == "3" ]; then
		# 提取干净的节点配置，并重新排序，现在web界面里添加/删除节点后会自动排序，所以以下基本不会运行到
		echo_date "备份所有节点信息并重新排序..."
		echo_date "如果节点数量过多，此处可能需要等待较长时间，请耐心等待..."
		rm -rf ${BACKUP_FILE_TMP}
		rm -rf ${BACKUP_FILE}
		local i=1
		export -p | grep ssconf_basic_name_ | awk -F"=" '{print $1}' | awk -F"_" '{print $NF}' | sort -n | while read nu
		do
			for item in $PREFIX; do
				#{
					local tmp=$(eval echo \$${item}${nu})
					if [ -n "${tmp}" ]; then
						echo "export ${item}${i}=\"${tmp}\"" >> ${BACKUP_FILE_TMP}
					fi
				#} &
			done
			if [ "${nu}" == "${ssconf_basic_node}" ]; then
				echo "export ssconf_basic_node=\"$i\"" >> ${BACKUP_FILE_TMP}
			fi
			if [ -n "${ss_basic_udp_node}" -a "$nu" == "${ss_basic_udp_node}" ]; then
				echo "export ss_basic_udp_node=\"$i\"" >> ${BACKUP_FILE_TMP}
			fi
			let i+=1
		done

		cat > $BACKUP_FILE <<-EOF
			#!/bin/sh
			source /koolshare/scripts/base.sh
			#------------------------
			confs=\$(dbus list ssconf_basic_ | cut -d "=" -f 1)
			for conf in \$confs
			do
			    dbus remove \$conf
			done
			usleep 300000
			#------------------------
		EOF

		cat ${BACKUP_FILE_TMP} | \
		awk -F"=" '{print $0"|"$1}' | \
		awk -F"_" '{print $NF"|"$0}' | \
		sort -t "|" -nk1,1 | \
		awk -F"|" '{print $2}' | \
		sed 's/export/dbus set/g' | \
		sed '1 i\#------------------------' \
		#sed '1 isource /koolshare/scripts/base.sh' | \
		#sed '1 i#!/bin/sh' | \
		#sed '$a #------------------------' \
		>> ${BACKUP_FILE}
		
		echo_date "备份完毕，开始调整..."
		# 2 应用提取的干净的节点配置
		chmod +x ${BACKUP_FILE}
		sh ${BACKUP_FILE}
		echo_date "节点调整完毕！"
	elif [ ${REASON} == "2" ]; then
		# 提取干净的节点配置
		echo_date "备份所有节点信息"
		rm -rf ${BACKUP_FILE}
		cat > ${BACKUP_FILE} <<-EOF
			#!/bin/sh
			source /koolshare/scripts/base.sh
			#------------------------
			confs=\$(dbus list ssconf_basic_ | cut -d "=" -f 1)
			for conf in \${confs}
			do
			    dbus remove \${conf}
			done
			usleep 300000
			#------------------------
		EOF
		
		local KEY="$(echo ${PREFIX} | sed 's/[[:space:]]/|/g')"
		export -p | \
		grep "ssconf_basic" | \
		awk -F"=" '{print $0"|"$1}' | \
		awk -F"_" '{print $NF"|"$0}' | \
		sort -t "|" -nk1,1 | \
		awk -F"|" '{print $2}'| \
		grep -E ${KEY} | \
		sed 's/^export/dbus set/g' | \
		sed "s/='/=\"/g" | \
		sed "s/'/\"/g" | \
		sed '/=""$/d' \
		>> ${BACKUP_FILE}

		echo dbus set ss_basic_udp_node=\"${ss_basic_udp_node}\" >> ${BACKUP_FILE}
		echo dbus set ssconf_basic_node=\"${ssconf_basic_node}\" >> ${BACKUP_FILE}

		echo_date "备份完毕"
		# 应用提取的干净的节点配置
		chmod +x ${BACKUP_FILE}
		sh ${BACKUP_FILE}
		echo_date "调整完毕！节点信息备份在/koolshare/configs/ss_conf.sh"
	else
		echo_date "节点顺序正确，节点配置信息OK！无需调整！"
	fi
}

decode_url_link(){
	local link=$1
	local len=$(echo ${link} | wc -L)
	local mod4=$(($len%4))
	if [ "$mod4" -gt "0" ]; then
		local var="===="
		local newlink=${link}${var:$mod4}
		echo -n "${newlink}" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	else
		echo -n "${link}" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	fi
}

add_ssr_nodes_offline(){
	let NODE_INDEX+=1
	dbus set ssconf_basic_name_${NODE_INDEX}=${remarks}
	dbus set ssconf_basic_mode_${NODE_INDEX}=${ssr_subscribe_mode}
	dbus set ssconf_basic_server_${NODE_INDEX}=${server}
	dbus set ssconf_basic_port_${NODE_INDEX}=${server_port}
	dbus set ssconf_basic_rss_protocol_${NODE_INDEX}=${protocol}
	dbus set ssconf_basic_rss_protocol_param_${NODE_INDEX}=${protoparam}
	dbus set ssconf_basic_method_${NODE_INDEX}=${encrypt_method}
	dbus set ssconf_basic_rss_obfs_${NODE_INDEX}=${obfs}
	dbus set ssconf_basic_type_${NODE_INDEX}="1"
	dbus set ssconf_basic_rss_obfs_param_${NODE_INDEX}=${obfsparam}
	dbus set ssconf_basic_password_${NODE_INDEX}=${password}
	echo_date "SSR节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
}

add_ss_servers(){
	let NODE_INDEX+=1
	dbus set ssconf_basic_name_${NODE_INDEX}=${remarks}
	dbus set ssconf_basic_mode_${NODE_INDEX}="2"
	dbus set ssconf_basic_server_${NODE_INDEX}=${server}
	dbus set ssconf_basic_port_${NODE_INDEX}=${server_port}
	dbus set ssconf_basic_method_${NODE_INDEX}=${encrypt_method}
	dbus set ssconf_basic_password_${NODE_INDEX}=${password}
	dbus set ssconf_basic_type_${NODE_INDEX}="0"
	echo_date "SS节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
}

get_ss_config(){
	decode_link=$1
	server=$(echo "${decode_link}" | awk -F':' '{print $2}' | awk -F'@' '{print $2}')
	server_port=$(echo "${decode_link}" | awk -F':' '{print $3}')
	encrypt_method=$(echo "${decode_link}" | awk -F':' '{print $1}')
	password=$(echo "${decode_link}" | awk -F':' '{print $2}' | awk -F'@' '{print $1}')
	password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
}

get_v2ray_remote_config(){
	decode_link="$1"
	unset v2ray_v v2ray_ps v2ray_add v2ray_port v2ray_id v2ray_aid v2ray_net v2ray_type v2ray_tls_tmp v2ray_path v2ray_host
	v2ray_v=$(echo "${decode_link}" | jq -r .v)
	v2ray_ps=$(echo "${decode_link}" | jq -r .ps | sed 's/[ \t]*//g')
	v2ray_add=$(echo "${decode_link}" | jq -r .add | sed 's/[ \t]*//g')
	v2ray_port=$(echo "${decode_link}" | jq -r .port | sed 's/[ \t]*//g')
	v2ray_id=$(echo "${decode_link}" | jq -r .id | sed 's/[ \t]*//g')
	v2ray_aid=$(echo "${decode_link}" | jq -r .aid | sed 's/[ \t]*//g')
	v2ray_net=$(echo "${decode_link}" | jq -r .net)
	v2ray_type=$(echo "${decode_link}" | jq -r .type)
	v2ray_tls_tmp=$(echo "${decode_link}" | jq -r .tls)
	[ "$v2ray_tls_tmp"x == "tls"x ] && v2ray_tls="tls" || v2ray_tls="none"
	
	if [ "$v2ray_v" == "2" ]; then
		# "new format"
		v2ray_path=$(echo "${decode_link}" | jq -r .path)
		v2ray_host=$(echo "${decode_link}" | jq -r .host)
	else
		# "old format"
		case $v2ray_net in
		tcp)
			v2ray_host=$(echo "${decode_link}" | jq -r .host)
			v2ray_path=""
			;;
		kcp)
			v2ray_host=""
			v2ray_path=""
			;;
		ws)
			v2ray_host_tmp=$(echo "${decode_link}" | jq -r .host)
			if [ -n "$v2ray_host_tmp" ]; then
				format_ws=$(echo $v2ray_host_tmp | grep -E ";")
				if [ -n "$format_ws" ]; then
					v2ray_host=$(echo $v2ray_host_tmp | cut -d ";" -f1)
					v2ray_path=$(echo $v2ray_host_tmp | cut -d ";" -f1)
				else
					v2ray_host=""
					v2ray_path=$v2ray_host
				fi
			fi
			;;
		h2)
			v2ray_host=""
			v2ray_path=$(echo "${decode_link}" | jq -r .path)
			;;
		esac
	fi

	#把全部服务器节点编码后写入文件 /usr/share/shadowsocks/serverconfig/all_subscservers.txt
	v2ray_group=${DOMAIN_NAME}_${GROUP_HASH:0:4}
	group_base64=$(echo ${v2ray_group}} | base64_encode)
	[ -n "${v2ray_add}" ] && server_base64=$(echo ${v2ray_add} | base64_encode)
	[ -n "${v2ray_group}" ] && [ -n "${v2ray_add}" ] && echo ${server_base64} ${group_base64} >> /tmp/all_subscservers.txt

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
	let NODE_INDEX+=1
	[ -z "$1" ] && dbus set ssconf_basic_group_${NODE_INDEX}=${v2ray_group}
	dbus set ssconf_basic_type_${NODE_INDEX}=3
	dbus set ssconf_basic_v2ray_mux_enable_${NODE_INDEX}=0
	dbus set ssconf_basic_v2ray_use_json_${NODE_INDEX}=0
	dbus set ssconf_basic_v2ray_security_${NODE_INDEX}="auto"
	dbus set ssconf_basic_mode_${NODE_INDEX}=$ssr_subscribe_mode
	dbus set ssconf_basic_name_${NODE_INDEX}=$v2ray_ps
	dbus set ssconf_basic_port_${NODE_INDEX}=$v2ray_port
	dbus set ssconf_basic_server_${NODE_INDEX}=$v2ray_add
	dbus set ssconf_basic_v2ray_uuid_${NODE_INDEX}=$v2ray_id
	dbus set ssconf_basic_v2ray_alterid_${NODE_INDEX}=$v2ray_aid
	dbus set ssconf_basic_v2ray_network_security_${NODE_INDEX}=$v2ray_tls
	dbus set ssconf_basic_v2ray_network_${NODE_INDEX}=$v2ray_net
	case $v2ray_net in
	tcp)
		# tcp协议设置【 tcp伪装类型 (type)】和【伪装域名 (host)】
		dbus set ssconf_basic_v2ray_headtype_tcp_${NODE_INDEX}=$v2ray_type
		[ -n "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_${NODE_INDEX}=$v2ray_host
		;;
	kcp)
		# kcp协议设置【 kcp伪装类型 (type)】
		dbus set ssconf_basic_v2ray_headtype_kcp_${NODE_INDEX}=$v2ray_type
		;;
	ws|h2)
		# ws/h2协议设置【 伪装域名 (host))】和【路径 (path)】
		[ -n "$v2ray_host" ] && dbus set ssconf_basic_v2ray_network_host_${NODE_INDEX}=$v2ray_host
		[ -n "$v2ray_path" ] && dbus set ssconf_basic_v2ray_network_path_${NODE_INDEX}=$v2ray_path
		;;
	esac
	echo_date "v2ray节点：新增加【$v2ray_ps】到节点列表第 ${NODE_INDEX} 位。"
}

update_v2ray_config(){
	isadded_server=$(cat /tmp/all_localservers.txt | grep -w ${group_base64} | awk '{print $1}' | grep -c ${server_base64} | head -n1)
	if [ "${isadded_server}" == "0" ]; then
		add_v2ray_servers
		let addnum+=1
	else
		# 如果在本地的订阅节点中已经有该节点（用group和server去判断），检测下配置是否更改，如果更改，则更新配置
		index=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep ${server_base64} | awk '{print $4}'|head -n1)
		local i=0
		dbus set ssconf_basic_mode_${index}="${ssr_subscribe_mode}"
		local local_v2ray_gp=$(eval echo \$ssconf_basic_group_${index})
		local local_v2ray_ps=$(eval echo \$ssconf_basic_name_${index})
		local local_v2ray_add=$(eval echo \$ssconf_basic_server_${index})
		local local_v2ray_port=$(eval echo \$ssconf_basic_port_${index})
		local local_v2ray_id=$(eval echo \$ssconf_basic_v2ray_uuid_${index})
		local local_v2ray_aid=$(eval echo \$ssconf_basic_v2ray_alterid_${index})
		local local_v2ray_tls=$(eval echo \$ssconf_basic_v2ray_network_security_${index})
		local local_v2ray_net=$(eval echo \$ssconf_basic_v2ray_network_${index})
		[ "$local_v2ray_gp" != "$v2ray_group" ] && dbus set ssconf_basic_group_${index}=${v2ray_group} && let i+=1
		[ "$local_v2ray_ps" != "$v2ray_ps" ] && dbus set ssconf_basic_name_${index}=${v2ray_ps} && let i+=1
		[ "$local_v2ray_add" != "$v2ray_add" ] && dbus set ssconf_basic_server_${index}=${v2ray_add} && let i+=1
		[ "$local_v2ray_port" != "$v2ray_port" ] && dbus set ssconf_basic_port_${index}=${v2ray_port} && let i+=1
		[ "$local_v2ray_id" != "$v2ray_id" ] && dbus set ssconf_basic_v2ray_uuid_${index}=${v2ray_id} && let i+=1
		[ "$local_v2ray_aid" != "$v2ray_aid" ] && dbus set ssconf_basic_v2ray_alterid_${index}=${v2ray_aid} && let i+=1
		[ "$local_v2ray_tls" != "$v2ray_tls" ] && dbus set ssconf_basic_v2ray_network_security_${index}=${v2ray_tls} && let i+=1
		[ "$local_v2ray_net" != "$v2ray_net" ] && dbus set ssconf_basic_v2ray_network_${index}=${v2ray_net} && let i+=1
		case $local_v2ray_net in
		tcp)
			# tcp协议
			local local_v2ray_type=$(eval echo \$ssconf_basic_v2ray_headtype_tcp_${index})
			local local_v2ray_host=$(eval echo \$ssconf_basic_v2ray_network_host_${index})
			[ "${local_v2ray_type}" != "${v2ray_type}" ] && dbus set ssconf_basic_v2ray_headtype_tcp_${index}=${v2ray_type} && let i+=1
			[ "${local_v2ray_host}" != "${v2ray_host}" ] && dbus set ssconf_basic_v2ray_network_host_${index}=${v2ray_host} && let i+=1
			;;
		kcp)
			# kcp协议
			local local_v2ray_type=$(eval echo \$ssconf_basic_v2ray_headtype_kcp_${index})
			[ "${local_v2ray_type}" != "${v2ray_type}" ] && dbus set ssconf_basic_v2ray_headtype_kcp_${index}=${v2ray_type} && let i+=1
			;;
		ws|h2)
			# ws/h2协议
			local local_v2ray_host=$(eval echo \$ssconf_basic_v2ray_network_host_${index})
			local local_v2ray_path=$(eval echo \$ssconf_basic_v2ray_network_path_${index})
			[ "${local_v2ray_host}" != "${v2ray_host}" ] && dbus set ssconf_basic_v2ray_network_host_${index}=${v2ray_host} && let i+=1
			[ "${local_v2ray_path}" != "${v2ray_path}" ] && dbus set ssconf_basic_v2ray_network_path_${index}=${v2ray_path} && let i+=1
			;;
		esac

		if [ "$i" -gt "0" ]; then
			echo_date "修改v2ray节点：【${v2ray_ps}】" && let updatenum+=1
		else
			echo_date "v2ray节点：【${v2ray_ps}】参数未发生变化，跳过！"
		fi
	fi
}

get_ss_node_info(){
	decode_link="$1"
	unset server_raw server server_port remarks encrypt_info decrypt_info encrypt_method password plugin_support obfs_para plugin_prog obfs_method obfs_host group
	
	# 机场众多，各家的格式有点点不一样，不保证完全兼容，以下SS订阅根据nexitally和JMS机场
	remarks=$(echo "${decode_link}" | awk -F"#" '{print $NF}'|urldecode)
	server_raw_1=$(echo "${decode_link}" | sed -n 's/.\+@\(.\+:[0-9]\+\).\+/\1/p')
	if [ -n "${server_raw_1}" ];then
		server_tmp=$(echo "${server_raw_1}" | awk -F':' '{print $1}')
		server_port_tmp=$(echo "${server_raw_1}" | awk -F':' '{print $2}')
	fi
	encrypt_info=$(echo "${decode_link}" | sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g'|cut -d "|" -f1)
	decrypt_info=$(decode_url_link $(echo "$encrypt_info"))
	server_raw_2=$(echo "${decrypt_info}" | sed -n 's/.\+@\(.\+:[0-9]\+\).\+/\1/p')
	if [ -n "${server_raw_2}" ];then
		server_tmp=$(echo "${server_raw_2}" | awk -F':' '{print $1}')
		server_port_tmp=$(echo "${server_raw_2}" | awk -F':' '{print $2}')
	fi
	if [ -n "${server_tmp}" ];then
		server=${server_tmp}
	fi
	if [ -n "${server_port_tmp}" ];then
		server_port=${server_port_tmp}
	fi
	encrypt_method=$(echo "${decrypt_info}" | awk -F':' '{print $1}')
	password=$(echo "${decrypt_info}" | sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g' | awk -F'|' '{print $2}')
	password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
	plugin_support=$(echo "${decode_link}"|grep -Eo "plugin")
	if [ -n "${plugin_support}" ];then
		obfs_para=$(echo "${decode_link}" | sed -n 's/.\+plugin=\(\)/\1/p'|sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g' | awk -F'|' '{print $1}'|sed 's/%3B/;/g;s/%3D/=/g')
		plugin_prog=$(echo "${obfs_para}" | awk -F';' '{print $1}')
		obfs_method=$(echo "${obfs_para}" | awk -F';' '{print $2}'| awk -F'=' '{print $2}')
		obfs_host=$(echo "${obfs_para}" | awk -F';' '{print $3}'| awk -F'=' '{print $2}')
	fi

	# ss订阅规范不一，目前我没有见到机场有给group信息，那么直接用订阅链接域名好了
	group=${DOMAIN_NAME}

	[ -n "${group}" ] && group_base64=$(echo ${group}_${GROUP_HASH:0:4} | base64_encode | sed 's/ -//g')
	[ -n "${server}" ] && server_base64=$(echo ${server} | base64_encode | sed 's/ -//g')
	[ -n "${remarks}" ] && remark_base64=$(echo ${remarks} | base64_encode | sed 's/ -//g')
 
	if [ -n "${group}" -a -n "${server}" -a -n "${server_port}" -a -n "${password}" -a -n "${encrypt_method}" ]; then
		echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/all_subscservers.txt
	else
		return 1
	fi
	
	# echo ------------
	# echo server: $server
	# echo server_port: $server_port
	# echo remarks: $remarks
	# echo encrypt_method: $encrypt_method
	# echo password: $password
	# echo plugin_prog: $plugin_prog
	# echo obfs_method: $obfs_method
	# echo obfs_host: $obfs_host
	# echo ------------
}

add_ss_nodes(){
	let NODE_INDEX+=1
	echo_date "SS节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
	dbus set ssconf_basic_name_${NODE_INDEX}=${remarks}
	dbus set ssconf_basic_group_${NODE_INDEX}=${group}_${GROUP_HASH:0:4}
	dbus set ssconf_basic_mode_${NODE_INDEX}=${ssr_subscribe_mode}
	dbus set ssconf_basic_server_${NODE_INDEX}=${server}
	dbus set ssconf_basic_port_${NODE_INDEX}=${server_port}
	dbus set ssconf_basic_method_${NODE_INDEX}=${encrypt_method}
	dbus set ssconf_basic_password_${NODE_INDEX}=${password}
	dbus set ssconf_basic_type_${NODE_INDEX}="0"
	if [ -n "${plugin_prog}" -a -n "${obfs_method}" -a -n "${obfs_host}" ];then
		# v2ray-plugin的机场没有，无法知晓订阅格式
		if [ "${plugin_prog}" == "obfs-local" ];then
			dbus set ssconf_basic_ss_obfs_${NODE_INDEX}=${obfs_method}
			dbus set ssconf_basic_ss_obfs_host_${NODE_INDEX}=${obfs_host}
			dbus set ssconf_basic_ss_v2ray_${NODE_INDEX}=0
		fi
	else
		dbus set ssconf_basic_ss_obfs_${NODE_INDEX}=0
		dbus set ssconf_basic_ss_v2ray_${NODE_INDEX}=0
	fi
	let addnum+=1
}

update_ss_nodes(){
	local FAILED_FLAG=$1
	local UPDATE_FLAG
	local DELETE_FLAG
	local SKIPDB_FLAG
	local INFO

	if [ "${FAILED_FLAG}" == "1" ]; then
		echo_date "ss订阅：检测到一个错误节点，跳过！"
		return 1
	fi
	
	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管
	
	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "SS节点：不添加【${remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "SS节点：不添加【${remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "SS节点：不添加【${remarks}】节点，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "SS节点：不添加【${remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "SS节点：不添加【${remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	else
		local UPDATE_FLAG=0
	fi
	
	# ------------------------------- 节点添加/修改逻辑 -------------------------------
	local isadded_server=$(cat /tmp/all_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/all_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_ss_nodes
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点域名地址，通过节点名称获取index
		local index_line_remark=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/all_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ss_nodes
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/all_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ss_nodes
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=2
				local index=$(cat /tmp/multi_server_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_server_${tmp_file}.txt
			fi
		fi
	fi

	# SKIPDB_FLAG不为空，说明本地找到对应节点，且拿到了节点的index
	if [ "${SKIPDB_FLAG}" == "1" -o "${SKIPDB_FLAG}" == "2" ]; then
		# 在本地的节点中找到该节点，但是该节点被用户定义定义的关键词过滤了，那么删除它
		local KEY_LOCAL_NAME=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo $KEY_LOCAL_NAME $KEY_LOCAL_SERVER | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo $KEY_LOCAL_NAME $KEY_LOCAL_SERVER | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		else
			local DELETE_FLAG=0
		fi

		if [ "${DELETE_FLAG}" == "1" ]; then
			# 删除此节点
			for item in ${PREFIX}
			do
				if [ -n "$(eval echo \$${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			# 在本地的订阅节点中找到该节点，检测下配置是否更改，如果更改，则更新配置
			local local_group="$(eval echo \$ssconf_basic_group_${index})"
			local local_mode="$(eval echo \$ssconf_basic_mode_${index})"
			local local_remark="$(eval echo \$ssconf_basic_name_${index})"
			local local_server="$(eval echo \$ssconf_basic_server_${index})"
			local local_server_port="$(eval echo \$ssconf_basic_port_${index})"
			local local_password="$(eval echo \$ssconf_basic_password_${index})"
			local local_encrypt_method="$(eval echo \$ssconf_basic_method_${index})"
			local local_ss_obfs="$(eval echo \$ssconf_basic_ss_obfs_${index})"
			local local_ss_obfs_host="$(eval echo \$ssconf_basic_ss_obfs_host_${index})"
			local local_ss_v2ray="$(eval echo \$ssconf_basic_ss_v2ray_${index})"
			local local_ss_v2ray_opts="$(eval echo \$ssconf_basic_ss_v2ray_opts_${index})"
			[ "${local_group}" != "${group}_${GROUP_HASH:0:4}" ] && dbus set ssconf_basic_group_${index}="${group}_${GROUP_HASH:0:4}" && INFO="${INFO}分组信息"
			[ "${local_mode}" != "${ssr_subscribe_mode}" ] && dbus set ssconf_basic_mode_${index}="${ssr_subscribe_mode}" && INFO="${INFO}模式"
			[ "${SKIPDB_FLAG}" == "2" ] && [ "${local_remark}" != "${remarks}" ] && dbus set ssconf_basic_name_${index}="${remarks}" && INFO="${INFO}名称 "
			[ "${SKIPDB_FLAG}" == "1" ] && [ "${local_server}" != "${server}" ] && dbus set ssconf_basic_server_${index}="${server}" && INFO="${INFO}服务器地址 "
			[ "${local_server_port}" != "${server_port}" ] && dbus set ssconf_basic_port_${index}="${server_port}" && INFO="${INFO}端口 "
			[ "${local_password}" != "${password}" ] && dbus set ssconf_basic_password_${index}="${password}" && INFO="${INFO}密码 "
			[ "${local_encrypt_method}" != "${encrypt_method}" ] && dbus set ssconf_basic_method_${index}="${encrypt_method}" && INFO="${INFO}加密 "
			[ "${local_ss_obfs}" != "${obfs_method}" -a -n "${obfs_method}" ] && dbus set ssconf_basic_ss_obfs_${index}="${obfs_method}" && INFO="${INFO}obfs "
			[ "${local_ss_obfs_host}" != "${obfs_host}" ] && dbus set ssconf_basic_ss_obfs_host_${index}="${obfs_host}" && INFO="${INFO}obfs-host "
			if [ -z "${obfs_method}" -o -z "${obfs_host}" ];then
				dbus set ssconf_basic_ss_obfs_${index}="0"
				dbus remove ssconf_basic_ss_obfs_host_${index}
			fi
			
			if [ -n "${INFO}" ]; then
				INFO=$(echo "${INFO}" | sed 's/[[:space:]]//g')
				echo_date "SS节点：更新【${remarks}】，原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "SS节点：【${remarks}】 参数未发生变化，跳过！"
			fi
		fi
	fi
	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo $group >> /tmp/sub_group_info.txt
}

get_ssr_node_info(){
	decode_link="$1"
	action="$2"
	unset server server_port protocol encrypt_method obfs password obfsparam_temp obfsparam protoparam_temp protoparam remarks_temp remarks group_temp group
	server=$(echo "${decode_link}" | awk -F':' '{print $1}' | sed 's/[[:space:]]//g')
	server_port=$(echo "${decode_link}" | awk -F':' '{print $2}')
	protocol=$(echo "${decode_link}" | awk -F':' '{print $3}')
	encrypt_method=$(echo "${decode_link}" |awk -F':' '{print $4}')
	obfs=$(echo "${decode_link}" | awk -F':' '{print $5}' | sed 's/_compatible//g')
	password=$(decode_url_link $(echo "${decode_link}" | awk -F':' '{print $6}' | awk -F'/' '{print $1}'))
	password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
	
	obfsparam_temp=$(echo "${decode_link}" | awk -F':' '{print $6}' | grep -Eo "obfsparam.+" | sed 's/obfsparam=//g' | awk -F'&' '{print $1}')
	[ -n "${obfsparam_temp}" ] && obfsparam=$(decode_url_link ${obfsparam_temp}) || obfsparam=''
	
	protoparam_temp=$(echo "${decode_link}" | awk -F':' '{print $6}' | grep -Eo "protoparam.+" | sed 's/protoparam=//g' | awk -F'&' '{print $1}')
	[ -n "${protoparam_temp}" ] && protoparam=$(decode_url_link ${protoparam_temp} | sed 's/_compatible//g' | sed 's/[[:space:]]//g') || protoparam=''
	
	remarks_temp=$(echo "${decode_link}" | awk -F':' '{print $6}' | grep -Eo "remarks.+" | sed 's/remarks=//g' | awk -F'&' '{print $1}')
	if [ "${action}" == "1" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(decode_url_link ${remarks_temp})
			#remarks=$(echo ${remarks}|urldecode)
		else
			remarks=""
		fi
	elif [ "$action" == "2" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(decode_url_link ${remarks_temp})
			#remarks=$(echo ${remarks}|urldecode)
		else
			remarks='AutoSuB'
		fi
	fi
	
	group_temp=$(echo "${decode_link}" | awk -F':' '{print $6}' | grep -Eo "group.+" | sed 's/group=//g' | awk -F'&' '{print $1}')
	if [ "${action}" == "1" ]; then
		[ -n "$group_temp" ] && group=$(decode_url_link $group_temp) || group=""
	elif [ "${action}" == "2" ]; then
		[ -n "$group_temp" ] && group=$(decode_url_link $group_temp) || group='AutoSuBGroup'
	fi

	[ -n "${group}" ] && group_base64=$(echo ${group}_${GROUP_HASH:0:4} | base64_encode | sed 's/ -//g')
	[ -n "${server}" ] && server_base64=$(echo $server | base64_encode | sed 's/ -//g')
	[ -n "${remarks}" ] && remark_base64=$(echo $remarks | base64_encode | sed 's/ -//g')
 
	if [ -n "${group}" -a -n "${server}" -a -n "${server_port}" -a -n "${password}" -a -n "${protocol}" -a -n "${obfs}" -a -n "${encrypt_method}" ]; then
		echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/all_subscservers.txt
	else
		return 1
	fi
	
	#for debug, please keep it here~
	# echo ------------
	# echo group: $group
	# echo remarks: $remarks
	# echo server: $server
	# echo server_port: $server_port
	# echo password: $password
	# echo encrypt_method: $encrypt_method
	# echo protocol: $protocol
	# echo protoparam: $protoparam
	# echo obfs: $obfs
	# echo obfsparam: $obfsparam
	# echo ------------
}

add_ssr_nodes(){
	let NODE_INDEX+=1
	echo_date "SSR节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
	dbus set ssconf_basic_name_${NODE_INDEX}=${remarks}
	dbus set ssconf_basic_group_${NODE_INDEX}=${group}_${GROUP_HASH:0:4}
	dbus set ssconf_basic_mode_${NODE_INDEX}=${ssr_subscribe_mode}
	dbus set ssconf_basic_server_${NODE_INDEX}=${server}
	dbus set ssconf_basic_port_${NODE_INDEX}=${server_port}
	dbus set ssconf_basic_rss_protocol_${NODE_INDEX}=${protocol}
	dbus set ssconf_basic_method_${NODE_INDEX}=${encrypt_method}
	dbus set ssconf_basic_rss_obfs_${NODE_INDEX}=${obfs}
	dbus set ssconf_basic_type_${NODE_INDEX}="1"
	dbus set ssconf_basic_password_${NODE_INDEX}=${password}
	[ -n "${protoparam}" ] && dbus set ssconf_basic_rss_protocol_param_${NODE_INDEX}=${protoparam}
	[ "${ssr_subscribe_obfspara}" == "0" ] && dbus remove ssconf_basic_rss_obfs_param_${NODE_INDEX}
	[ "${ssr_subscribe_obfspara}" == "1" ] && [ -n "${obfsparam}" ] && dbus set ssconf_basic_rss_obfs_param_${NODE_INDEX}="${obfsparam}"
	[ "${ssr_subscribe_obfspara}" == "2" ] && dbus set ssconf_basic_rss_obfs_param_${NODE_INDEX}="${ssr_subscribe_obfspara_val}"
	let addnum+=1
}

update_ssr_nodes(){
	local FAILED_FLAG=$1
	local UPDATE_FLAG
	local DELETE_FLAG
	local SKIPDB_FLAG
	local INFO

	if [ "${FAILED_FLAG}" == "1" ]; then
		echo_date "ssr订阅：检测到一个错误节点，跳过！"
		return 1
	fi
	
	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管
	
	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "SSR节点：不添加【${remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "SSR节点：不添加【${remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "SSR节点：不添加【${remarks}】节点，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "SSR节点：不添加【${remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "SSR节点：不添加【${remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	else
		local UPDATE_FLAG=0
	fi
	
	# ------------------------------- 节点添加/修改逻辑 -------------------------------
	local isadded_server=$(cat /tmp/all_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/all_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_ssr_nodes
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点域名地址，通过节点名称获取index
		local index_line_remark=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/all_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ssr_nodes
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/all_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ssr_nodes
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=2
				local index=$(cat /tmp/multi_server_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_server_${tmp_file}.txt
			fi
		fi
	fi

	# SKIPDB_FLAG不为空，说明本地找到对应节点，且拿到了节点的index
	if [ "${SKIPDB_FLAG}" == "1" -o "${SKIPDB_FLAG}" == "2" ]; then
		# 在本地的节点中找到该节点，但是该节点被用户定义定义的关键词过滤了，那么删除它
		local KEY_LOCAL_NAME=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERV=$(cat /tmp/all_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERV} | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERV} | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SSR节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		else
			local DELETE_FLAG=0
		fi

		if [ "${DELETE_FLAG}" == "1" ]; then
			# 删除此节点
			for item in $PREFIX
			do
				if [ -n "$(eval echo \$${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			# 在本地的订阅节点中找到该节点，检测下配置是否更改，如果更改，则更新配置
			local local_group="$(eval echo \$ssconf_basic_group_${index})"
			local local_mode="$(eval echo \$ssconf_basic_mode_${index})"
			local local_remark="$(eval echo \$ssconf_basic_name_${index})"
			local local_server="$(eval echo \$ssconf_basic_server_${index})"
			local local_server_port="$(eval echo \$ssconf_basic_port_${index})"
			local local_password="$(eval echo \$ssconf_basic_password_${index})"
			local local_encrypt_method="$(eval echo \$ssconf_basic_method_${index})"
			local local_protocol="$(eval echo \$ssconf_basic_rss_protocol_${index})"
			local local_protocol_param="$(eval echo \$ssconf_basic_rss_protocol_param_${index})"
			local local_obfs="$(eval echo \$ssconf_basic_rss_obfs_${index})"
			local local_obfsparam="$(eval echo \$ssconf_basic_rss_obfs_param_${index})"
			
			[ "${local_group}" != "${group}_${GROUP_HASH:0:4}" ] && dbus set ssconf_basic_group_${index}="${group}_${GROUP_HASH:0:4}" && INFO="${INFO}分组信息"
			[ "${local_mode}" != "${ssr_subscribe_mode}" ] && dbus set ssconf_basic_mode_${index}="${ssr_subscribe_mode}" && INFO="${INFO}模式"
			[ "${SKIPDB_FLAG}" == "2" ] && [ "${local_remark}" != "${remarks}" ] && dbus set ssconf_basic_name_${index}="${remarks}" && INFO="${INFO}名称 "
			[ "${SKIPDB_FLAG}" == "1" ] && [ "${local_server}" != "${server}" ] && dbus set ssconf_basic_server_${index}="${server}" && INFO="${INFO}服务器地址 "
			[ "${local_server_port}" != "${server_port}" ] && dbus set ssconf_basic_port_${index}="${server_port}" && INFO="${INFO}端口 "
			[ "${local_password}" != "${password}" ] && dbus set ssconf_basic_password_${index}="${password}" && INFO="${INFO}密码 "
			[ "${local_encrypt_method}" != "${encrypt_method}" ] && dbus set ssconf_basic_method_${index}="${encrypt_method}" && INFO="${INFO}加密 "
			[ "${local_protocol}" != "${protocol}" ] && dbus set ssconf_basic_rss_protocol_${index}="${protocol}" && INFO="${INFO}协议 "
			if [ -z "${protoparam}" ]; then
				[ -n "${local_protocol_param}" ] && dbus remove ssconf_basic_rss_protocol_param_${index} && INFO="${INFO}协议参数 "
			else
				[ "${local_protocol_param}" != "${protoparam}" ] && dbus set ssconf_basic_rss_protocol_param_${index}="${protoparam}" && INFO="${INFO}协议参数 "
			fi
			[ "${local_obfs}" != "${obfs}" ] && dbus set ssconf_basic_rss_obfs_${index}="${obfs}" && INFO="${INFO}混淆 "
			[ "${ssr_subscribe_obfspara}" == "0" ] && [ -n "${local_obfsparam}" ] dbus remove ssconf_basic_rss_obfs_param_${index} && INFO="${INFO}混淆参数 "
			[ "${ssr_subscribe_obfspara}" == "1" ] && {
				if [ -z "${obfsparam}" ]; then
					[ -n "${local_obfsparam}" ] && dbus remove ssconf_basic_rss_obfs_param_${index} && INFO="${INFO}混淆参数 "
				else
					[ "${local_obfsparam}" != "${obfsparam}" ] && dbus set ssconf_basic_rss_obfs_param_${index}="${obfsparam}" && INFO="${INFO}混淆参数 "
				fi
			}
			[ "${ssr_subscribe_obfspara}" == "2" ] && [ "${local_obfsparam}" != "${ssr_subscribe_obfspara_val}" ] && dbus set ssconf_basic_rss_obfs_param_${index}="${ssr_subscribe_obfspara_val}" && INFO="${INFO}混淆参数 "
			
			if [ -n "${INFO}" ]; then
				INFO=$(echo "$INFO" | sed 's/[[:space:]]//g')
				echo_date "SSR节点：更新【${remarks}】，原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "SSR节点：【${remarks}】 参数未发生变化，跳过！"
			fi
		fi
	fi

	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${group} >> /tmp/sub_group_info.txt
}

del_none_exist(){
	# 如果移除了一些订阅，那么订阅信息记录里也应该移除
	local MAX_INFO=$(dbus list ss_online_hash|cut -d "=" -f1|awk -F"_" '{print $NF}'|sort -n|tail -n1)
	[ -z "${MAX_INFO}" ] && MAX_INFO="0"
	local CUR_INFO=${valid_count}
	until [ "${CUR_INFO}" == "${MAX_INFO}" ]; do
		let CUR_INFO+=1
		dbus remove ss_online_hash_${CUR_INFO}
		dbus remove ss_online_group_${CUR_INFO}
	done
	
	# 如果移除订阅链接，那么相应的订阅节点应该被移除
	dbus list ss | grep ssconf_basic_group_ | cut -d "=" -f2 | sort -u | while read local_group; do
		local_group=$(echo ${local_group} | sed "s/'//g")
		store_group=$(dbus list ss_online_group_|awk -F"=" '{print $NF}')
		local MATCH=$(echo ${store_group} | grep -w ${local_group})
		if [ -z "$MATCH" ]; then
			echo_date "==================================================================="
			echo_date "【${local_group%_*}】 机场已经不再订阅，将进行删除..."
			confs_nu=$(export -p | grep ssconf_basic_group_ | grep -w ${local_group} | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
			for conf_nu in $confs_nu; do
				echo_date "移除节点：【$(eval echo \$ssconf_basic_name_${conf_nu})】!"
				for item in $PREFIX
				do
					if [ -n "$(eval echo \$${item}${conf_nu})" ]; then
						#echo dbus remove ${item}${conf_nu}
						dbus remove ${item}${conf_nu}
					fi
				done
				sync
			done
		fi
	done

	gen_all_local_servers
	# 如果订阅链接并未移除，但是一些节点机场删除了，那么本地也要进行删除
	# 通过本地节点和订阅节点对比，找出本地独有的节点[域名]对应的节点索引
	local DIFF_SERVERS=$(awk 'NR==FNR{a[$1]=$1} NR>FNR{if(a[$1] == ""){print $4}}' /tmp/all_subscservers.txt /tmp/all_localservers.txt | sed '/^$/d')
	# 通过本地节点和订阅节点对比，找出本地独有的节点[名称]对应的节点索引
	local DIFF_REMARKS=$(awk 'NR==FNR{a[$3]=$3} NR>FNR{if(a[$3] == ""){print $4}}' /tmp/all_subscservers.txt /tmp/all_localservers.txt | sed '/^$/d')
	# 获取两者都有的节点索引，即为需要删除的节点
	local DEL_INDEXS=$(echo $DIFF_SERVERS $DIFF_REMARKS | sed 's/[[:space:]]/\n/g' | sort | uniq -d)
	# 删除操作
	[ -n "$DEL_INDEXS" ] && echo_date "==================================================================="
	for DEL_INDEX in $DEL_INDEXS; do
		echo_date "SSR节点：删除【$(eval echo \$ssconf_basic_name_$DEL_INDEX)】，因为该节点在订阅服务器上已经不存在..."
		for item in $PREFIX; do
			if [ -n "$(eval echo \$${item}${DEL_INDEX})" ]; then
				dbus remove ${item}${DEL_INDEX}
			fi
		done
		let delnum+=1
	done
}

remove_node_gap(){
	# 虽然web上已经可以自动化无缝重排序了，但是考虑到有的用户设置了插件自动化，长期不进入web，而后台更新节点持续一段时间后，节点顺序还是会很乱，所以保留此功能
	SEQ=$(dbus list ss | grep "ssconf_basic" | grep _name_ | cut -d "_" -f 4 | cut -d "=" -f 1 | sort -n)
	NODES_NU=$(dbus list ss | grep "ssconf_basic" | grep _name_ | wc -l)
	if [ "${NODES_NU}" == "0" ]; then
		return
	fi
	MAX=$(dbus list ss | grep "ssconf_basic" | grep _name_ | cut -d "_" -f 4 | cut -d "=" -f 1 | sort -rn | head -n1)
	[ -z "${MAX}" ] && MAX="0"
	echo_date "最大节点序号：${MAX}"
	echo_date "共有节点数量：${NODES_NU}"
	if [ "${MAX}" != "${NODES_NU}" ]; then
		echo_date "节点排序需要调整!"
		local y=1
		for nu in $SEQ
		do
			if [ "${y}" == "${nu}" ]; then
				echo_date "节点$y不需要调整！"
			else
				echo_date "调整节点${nu}到节点${y}！"
				for item in $PREFIX
				do
					#dbus remove ${item}${conf_nu}
					if [ -n "$(eval echo \$${item}${nu})" ]; then
						dbus set ${item}${y}="$(eval echo \$${item}${nu})"
						dbus remove ${item}${nu}
					fi
				done
				if [ "${nu}" == "${ssconf_basic_node}" ]; then
					dbus set ssconf_basic_node=${y}
				fi
				if [ -n "${ss_basic_udp_node}" -a "${nu}" == "${ss_basic_udp_node}" ]; then
					dbus set ss_basic_udp_node=${y}
				fi				
			fi
			let y+=1
		done
	else
		echo_date "节点排序正确!"
	fi
}

gap_test(){
	unset ssconf_basic_name_8
	unset ssconf_basic_name_9
	unset ssconf_basic_name_11
	unset ssconf_basic_name_12
	unset ssconf_basic_name_33
	unset ssconf_basic_name_44
	unset ssconf_basic_name_47
	unset ssconf_basic_name_52
	
	SEQ=$(dbus list ss | grep "ssconf_basic" | grep _name_ | cut -d "_" -f 4 | cut -d "=" -f 1 | sort -n)
	SEQ_SUB=$(dbus list ss | grep "ssconf_basic" | grep _group_ | cut -d "_" -f 4 | cut -d "=" -f 1 | sort -n)
	MAX=$(dbus list ss | grep "ssconf_basic" | grep _name_ | cut -d "_" -f 4 | cut -d "=" -f 1 | sort -rn | head -n1)
	NODES_NU=$(dbus list ss | grep "ssconf_basic" | grep _name_ | wc -l)

	echo_date "节点排序情况：${SEQ}"
	echo_date "订阅排序情况：${SEQ_SUB}"
	echo_date "最大节点序号：${MAX}"
	echo_date "共有节点数量：${NODES_NU}"
	echo_date "共有间隔数量：$(($MAX - $NODES_NU))"
	echo_date "需要移除节点：$(($NODES_NU + 1)) - $MAX"

	local nu=$((${NODES_NU} + 1))
	while [ "${nu}" -le "${MAX}" ]; do
		for item in ${PREFIX}
		do
			if [ -n "$(eval echo \$${item}${nu})" ]; then
				dbus remove ${item}${nu}
			fi
		done
		let nu+=1
	done
}

get_fancyss_running_status(){
	local STATUS_1=$(dbus get ss_basic_enable 2>/dev/null)
	local STATUS_2=$(iptables --t nat -S|grep SHADOWSOCKS|grep -w "3333" 2>/dev/null)
	local STATUS_3=$(netstat -nlp|grep -w "3333"|grep -E "ss-redir|v2ray|koolgame" 2>/dev/null)
	local STATUS_4=$(netstat -nlp|grep -w "7913")
	# 当插件状态为开启，iptables状态正常，透明端口进程正常，DNS端口正常，DNS配置文件正常
	if [ "${STATUS_1}" == "1" -a -n "${STATUS_2}" -a -n "${STATUS_3}" -a -n "${STATUS_4}" -a -f "/jffs/configs/dnsmasq.d/wblist.conf" ];then
		echo 1
	fi
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||'
}

get_node_name(){
	local CURRENT=$(dbus get ssconf_basic_node)
	local NODE_NAME=$(dbus get ssconf_basic_name_$CURRENT)
	if [ -n "${NODE_NAME}" ];then
		echo "${NODE_NAME}"
	else
		echo ""
	fi
}

dnsmasq_rule(){
	# better way todo: resolve first and add ip to ipset:router mannuly
	local ACTION="$1"
	local DOMAIN="$2"
	local DNSF_PORT=7913
	local DOMAIN_FILE=/jffs/configs/dnsmasq.d/ss_domain.conf
	if [ "${ACTION}" == "add" ];then
		if [ ! -f ${DOMAIN_FILE} -o "$(grep -c ${DOMAIN} ${DOMAIN_FILE} 2>/dev/null)" != "2" ];then
			echo_date "添加域名：${DOMAIN} 到本机走代理名单..."
			rm -rf ${DOMAIN_FILE}
			echo "server=/${DOMAIN}/127.0.0.1#$DNSF_PORT" >>${DOMAIN_FILE}
			echo "ipset=/${DOMAIN}/router" >>${DOMAIN_FILE}
			sync
			service restart_dnsmasq >/dev/null 2>&1
		fi
	elif [ "${ACTION}" == "remove" ];then
		if [ -f ${DOMAIN_FILE} ];then
			rm -rf ${DOMAIN_FILE}
			sync
			service restart_dnsmasq >/dev/null 2>&1
		fi
	fi
}

download_by_curl(){
	echo_date "使用curl下载订阅，第一次尝试下载..."
	curl -4sSk --connect-timeout 6 "$1" > /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	sleep 1
	
	echo_date "使用curl下载订阅失败，第二次尝试下载..."
	curl -4sSk --connect-timeout 10 "$1" > /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	sleep 2

	echo_date "使用curl下载订阅失败，第三次尝试下载..."
	curl -4sSk --connect-timeout 12 "$1" > /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi	

	return 1
}

download_by_wget(){
	if [ -n $(echo $1 | grep -E "^https") ]; then
		local EXT_OPT="--no-check-certificate"
	else
		local EXT_OPT=""
	fi
	
	echo_date "使用wget下载订阅，第一次尝试下载..."
	wget -4 -t 1 -T 10 --dns-timeout=5 -q $EXT_OPT "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	sleep 1

	echo_date "使用wget下载订阅，第二次尝试下载..."
	wget -4 -t 1 -T 15 --dns-timeout=10 -q $EXT_OPT "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi	
	
	sleep 2

	echo_date "使用wget下载订阅，第三次尝试下载..."
	wget -4 -t 1 -T 20 --dns-timeout=15 -q $EXT_OPT "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	return 1
}

get_online_rule_now(){
	# 0. variable define
	local SUB_LINK="$1"

	# 1. link format
	local LINK_FORMAT=$(echo "${SUB_LINK}" | grep -E "^http://|^https://")
	if [ -z "${LINK_FORMAT}" ];then
		return 4
	fi

	# 2. get domain name of node subscribe link
	local DOMAIN_NAME="$(get_domain_name ${SUB_LINK})"
	if [ -z "${DOMAIN_NAME}" ];then
		return 5
	fi

	# 3 generate group hash for each sub link
	local GROUP_HASH=$(echo "${SUB_LINK}" | md5sum | awk '{print $1}')

	# 4. try to delete some file first
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	
	# 5. remove related files before download
	echo_date "下载订阅链接到本地临时文件，请稍等..."
	if [ "${ss_basic_online_links_goss}" == "1" ]; then
		if [ "$(get_fancyss_running_status)" == "1" ];then
			echo_date "使用当前$(get_type_name $ss_basic_type)节点：[$(get_node_name)]提供的网络下载..."
			dnsmasq_rule add "${DOMAIN_NAME}"
		else
			echo_date "当前$(get_type_name $ss_basic_type)节点工作异常，改用常规网络下载..."
			dnsmasq_rule remove
		fi
	else
		echo_date "使用常规网络下载..."
		dnsmasq_rule remove
	fi
	
	# 6. download by curl
	download_by_curl "${SUB_LINK}"

	#虽然为0但是还是要检测下是否下载到正确的内容
	if [ "$?" == "0" ]; then
		#订阅地址有跳转
		local blank=$(cat /tmp/ssr_subscribe_file.txt | grep -E " |Redirecting|301")
		if [ -n "$blank" -o -z "$(cat /tmp/ssr_subscribe_file.txt)" ]; then
			[ -n "$blank" ] && echo_date "订阅链接可能有跳转，尝试更换wget进行下载..."
			[ -z "$(cat /tmp/ssr_subscribe_file.txt)" ] && echo_date "下载内容为空，尝试更换wget进行下载..."
			rm /tmp/ssr_subscribe_file.txt
			download_by_wget "${SUB_LINK}"
		fi
		
		#下载为空...
		if [ -z "$(cat /tmp/ssr_subscribe_file.txt)" ]; then
			echo_date "下载内容为空..."
			return 3
		fi
		#产品信息错误
		local wrong1=$(cat /tmp/ssr_subscribe_file.txt | grep "{")
		local wrong2=$(cat /tmp/ssr_subscribe_file.txt | grep "<")
		if [ -n "$wrong1" -o -n "$wrong2" ]; then
			return 2
		fi
	else
		echo_date "使用curl下载订阅失败，尝试更换wget进行下载..."
		rm /tmp/ssr_subscribe_file.txt
		download_by_wget "${SUB_LINK}"

		#返回错误
		if [ "$?" != "0" ]; then
			echo_date "更换wget下载订阅上次失败！"
			return 1
		fi

		#下载为空...
		if [ -z "$(cat /tmp/ssr_subscribe_file.txt)" ]; then
			echo_date "下载内容为空..."
			return 3
		fi
		
		#产品信息错误
		local wrong1=$(cat /tmp/ssr_subscribe_file.txt | grep "{")
		local wrong2=$(cat /tmp/ssr_subscribe_file.txt | grep "<")
		if [ -n "$wrong1" -o -n "$wrong2" ]; then
			return 2
		fi
	fi

	if [ "$?" != "0" ]; then
		return 1
	fi
	
	# 删除上一个订阅留下的相关信息
	rm -rf /tmp/sub_group_info.txt
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	echo_date "下载订阅成功..."
	echo_date "开始解析节点信息..."

	# 解析订阅原始文本，第一次
	decode_url_link $(cat /tmp/ssr_subscribe_file.txt) > /tmp/ssr_subscribe_file_temp.txt

	# 一些机场使用的换行符是dos格式（\r\n\)，在路由Linux下会出问题！转换成unix格式
	if [ -n "$(which dos2unix)" ];then
		dos2unix -u /tmp/ssr_subscribe_file_temp.txt
	else
		tr -d '\r' < /tmp/ssr_subscribe_file_temp.txt > /tmp/ssr_subscribe_file_temp_0.txt
		mv /tmp/ssr_subscribe_file_temp_0.txt /tmp/ssr_subscribe_file_temp.txt
	fi
	
	echo "" >> /tmp/ssr_subscribe_file_temp.txt
	local NODE_NU_RAW=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -c "://")
	echo_date "初步解析成功！共获得${NODE_NU_RAW}个节点！"

	# 如果机场订阅解析后有MAX=xx字段存在，那么随机选取xx个节点
	maxnum=$(cat /tmp/ssr_subscribe_file_temp.txt | grep "MAX=" | awk -F"=" '{print $2}' | grep -Eo "[0-9]+")
	if [ -n "${maxnum}" ]; then
		echo_date "根据机场要求，从${NODE_NU_RAW}个节点中，随机选取${maxnum}个用于订阅！"
		cat /tmp/ssr_subscribe_file_temp.txt | sed '/MAX=/d' | shuf -n $maxnum > /tmp/ssr_subscribe_file_temp_1.txt
		mv /tmp/ssr_subscribe_file_temp_1.txt /tmp/ssr_subscribe_file_temp.txt
	fi
	
	# 检测 ss ssr vmess
	NODE_FORMAT1=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^ss://")
	NODE_FORMAT2=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^ssr://")
	NODE_FORMAT3=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^vmess://")
	NODE_FORMAT4=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^trojan://")
	if [ -z "${NODE_FORMAT1}" -a -z "${NODE_FORMAT2}" -a -z "${NODE_FORMAT3}" -a -z "${NODE_FORMAT4}" ];then
		echo_date "订阅中不包含任何ss/ssr/v2ray/trojan节点，退出！"
		return 1
	fi
	
	local NODE_NU_SS=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^ss://") || "0"
	local NODE_NU_SR=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^ssr://") || "0"
	local NODE_NU_V2=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^vmess://") || "0"
	local NODE_NU_TJ=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^trojan://") || "0"
	local NODE_NU_TT=$((${NODE_NU_SS} + ${NODE_NU_SR} + ${NODE_NU_V2}))
	if [ "${NODE_NU_TT}" -lt "${NODE_NU_RAW}" ];then
		echo_date "${NODE_NU_RAW}个节点中，一共检测到$NODE_NU_TT个支持节点！"
	fi
	echo_date "具体情况如下："
	echo_date "ss节点：${NODE_NU_SS}个"
	echo_date "ssr节点：${NODE_NU_SR}个"
	echo_date "vmess节点：${NODE_NU_V2}个"
	echo_date "trojan节点：${NODE_NU_TJ}个"
	echo_date "-------------------------------------------------------------------"
	while read node; do
		local node_type
		local node_type_ss=$(echo ${node} | grep -E "^ss://")
		local node_type_sr=$(echo ${node} | grep -E "^ssr://")
		local node_type_v2=$(echo ${node} | grep -E "^vmess://")
		local node_type_tj=$(echo ${node} | grep -E "^trojan://")
		# ss
		if [ -n "${node_type_ss}" ];then
			local urllink=$(echo "${node}" | sed 's/ss:\/\///g' )
			get_ss_node_info ${urllink} 1
			update_ss_nodes $?
		fi
		# ssr
		if [ -n "${node_type_sr}" ];then
			local urllink=$(echo ${node} | sed 's/ssr:\/\///g')
			decode_link=$(decode_url_link ${urllink})
			get_ssr_node_info ${decode_link} 1
			update_ssr_nodes $?
		fi
		# v2ray
		if [ -n "${node_type_v2}" ];then
			local urllink=$(echo ${node} | sed 's/vmess:\/\///g')
			local decode_link=$(decode_url_link ${urllink})
			local decode_link=$(echo ${decode_link} | jq -c .)
			if [ -n "${decode_link}" ]; then
				get_v2ray_remote_config "${decode_link}"
				if [ "$?" == "0" ];then
					update_v2ray_config
				else
					echo_date "v2ray订阅：检测到一个错误节点，已经跳过！"
				fi
			else
				echo_date "解析失败！！！"
			fi
		fi
		# trojan
		if [ -n "${node_type_tj}" ];then
			echo_date "检测到一个trojan节点，本插件目前不支持trojan节点订阅，跳过！"
		fi
	done < /tmp/ssr_subscribe_file_temp.txt

	# 单个订阅链接的订阅完成，储存对应订阅链接的group信息，一个机场的节点可能有多个group
	current_nodes_count=$(($NODE_NU_TT - $exclude))
	if [ "${current_nodes_count}" -ge "1" ];then
		let valid_count+=1
		group=$(cat /tmp/sub_group_info.txt | sort -u | sed 's/$/ + /g' | sed ':a;N;$!ba;s#\n##g' | sed 's/ + $//g')
		if [ -n "${group}" ]; then
			dbus set ss_online_group_$valid_count=${group}_${GROUP_HASH:0:4}
		else
			# 如果机场没有定义group，则用其订阅域名写入即可
			group=${DOMAIN_NAME}_${GROUP_HASH:0:4}
			dbus set ss_online_group_$valid_count=$DOMAIN_NAME
		fi
		dbus set ss_online_hash_${valid_count}=${GROUP_HASH}
	fi

	# INFO
	USER_ADD=$(($(export -p | grep ssconf_basic_ | grep _name_ | wc -l) - $(export -p | grep ssconf_basic_ | grep _group_ | wc -l))) || "0"
	ONLINE_GET=$(dbus list ssconf_basic_ | grep _group_ | wc -l) || "0"
	echo_date "-------------------------------------------------------------------"
	echo_date "本次更新订阅来源【${group}】，共有节点$NODE_NU_TT个，其中："
	echo_date "因关键词排除节点${exclude}个，新增节点${addnum}个，修改${updatenum}个，删除${delnum}个；"
	echo_date "现共有自添加SSR节点：$USER_ADD 个；"
	echo_date "现共有订阅节点：$ONLINE_GET 个；"
	echo_date "在线订阅列表更新完成!"
}

gen_all_local_servers(){
	rm -rf /tmp/all_localservers.txt
	local local_indexs=$(dbus list ss | grep ssconf_basic_ | grep _group_ | cut -d "_" -f4 |cut -d "=" -f1 | sort -n)
	if [ -n "$local_indexs" ]; then
		for local_index in $local_indexs
		do
			# server group_hash remark node_nu
			echo \
			$(eval echo \$ssconf_basic_server_$local_index | base64_encode) \
			$(eval echo \$ssconf_basic_group_$local_index | base64_encode) \
			$(eval echo \$ssconf_basic_name_$local_index | base64_encode) \
			$local_index \
			>> /tmp/all_localservers.txt
		done
	else
		touch /tmp/all_localservers.txt
	fi
}

start_online_update(){
	FAST=$1
	prepare

	if [ "${SEQ_NU}" == "0" -a -z "$(dbus get ss_online_links)" ];then
		echo_date "订阅地址输入框为空，请输入订阅链接后重试！"
		exit 1
	fi

	local online_url_nu=$(dbus get ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | wc -l)
	if [ "${SEQ_NU}" == "0" -a "${online_url_nu}" == "0" ];then
		echo_date "未发现任何有效的订阅地址，请检查你的订阅链接！"
		# dbus remove ss_online_links
		exit 1
	fi
	
	# 2.清理上次订阅可能遗留的文件
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	rm -rf /tmp/all_localservers.txt >/dev/null 2>&1
	rm -rf /tmp/all_subscservers.txt >/dev/null 2>&1
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1

	# 3. 先将本地订阅节点全部备份出来
	#if [ "${FAST}" == "1" ];then
	#	# 提取干净的节点配置
	#	echo_date "先备份所有节点信息"
	#	rm -rf /tmp/fancyss_nodes_backup.sh
	#	cat > /tmp/fancyss_nodes_backup.sh <<-EOF
	#		#!/bin/sh
	#		source /koolshare/scripts/base.sh
	#		#------------------------
	#		confs=\$(dbus list ssconf_basic_ | cut -d "=" -f1)
	#		for conf in \$confs
	#		do
	#		    dbus remove \$conf
	#		done
	#		usleep 300000
	#		#------------------------
	#	EOF
	#	local KEY="$(echo ${PREFIX} | sed 's/[[:space:]]/|/g')"
	#	export -p | \
	#	grep "ssconf_basic" | \
	#	awk -F"=" '{print $0"|"$1}' | \
	#	awk -F"_" '{print $NF"|"$0}' | \
	#	sort -t "|" -nk1,1 | \
	#	awk -F"|" '{print $2}'| \
	#	grep -E ${KEY} | \
	#	sed 's/^export/dbus set/g' | \
	#	sed "s/='/=\"/g" | \
	#	sed "s/'/\"/g" | \
	#	sed '/=""$/d' \
	#	>> /tmp/fancyss_nodes_backup.sh

	#	echo dbus set ss_basic_udp_node=\"${ss_basic_udp_node}\" >> /tmp/fancyss_nodes_backup.sh
	#	echo dbus set ssconf_basic_node=\"${ssconf_basic_node}\" >> /tmp/fancyss_nodes_backup.sh
	#	echo_date "备份完毕"

	#	# 移除全部的订阅节点
	#	remove_nus=$(export -p | grep ssconf_basic_ | grep _group_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
	#	if [ -z "${remove_nus}" ]; then
	#		return 1
	#	fi
	#	rm -rf /tmp/fancyss_nodes_delete.sh
	#	cat > /tmp/fancyss_nodes_delete.sh <<-EOF
	#		#!/bin/sh
	#		source /koolshare/scripts/base.sh
	#		#------------------------
	#	EOF
	#	
	#	echo_date "删除所有本地订阅节点！"
	#	for remove_nu in ${remove_nus}
	#	do
	#		for item in ${PREFIX}
	#		do
	#			echo dbus remove ${item}${remove_nu} >> /tmp/fancyss_nodes_delete.sh
	#		done
	#	done
	#	sh /tmp/fancyss_nodes_delete.sh
	#	echo_date "所有订阅节点信息已经成功删除！"

	#	# 重新获取index
	#	NODES_SEQ=$(dbus list | grep ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
	#	NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
	#	exit
	#fi

	# 3. 收集当前所有的订阅节点到临时文件，用于比对
	echo_date "收集本地订阅节点信息到临时文件"
	gen_all_local_servers

	# 4. 下载/解析订阅节点
	local z=0
	valid_count=0
	online_url_nu=$(dbus get ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | wc -l)
	until [ "${z}" == "${online_url_nu}" ]; do
		let z+=1
		url=$(dbus get ss_online_links | base64_decode | awk '{print $1}' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | sed -n "$z p")
		[ -z "${url}" ] && continue
		echo_date "==================================================================="
		echo_date "                服务器订阅程序(Shell by stones & sadog)"
		echo_date "==================================================================="
		echo_date "从 ${url} 获取订阅..."
		addnum=0
		updatenum=0
		delnum=0
		exclude=0
		
		echo_date "开始更新在线订阅列表..." 
		get_online_rule_now "${url}"
		case $? in
		0)
			continue
			;;
		2)
			echo_date "无法获取产品信息！请检查你的服务商是否更换了订阅链接！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		3)
			echo_date "该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		4|5)
			echo_date "订阅地址错误！检测到你输入的订阅地址并不是标准网址格式！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		1|*)
			echo_date "下载订阅失败，请检查你的网络..."
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			let DEL_SUBSCRIBE+=1
			sleep 2
			echo_date "退出订阅程序..."
			;;
		esac
	done
	
	# 去除订阅服务器上已经删除的节点
	del_none_exist

	# 节点重新排序
	remove_node_gap

	# 结束
	echo_date "-------------------------------------------------------------------"
	echo_date "一点点清理工作..."
	#rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	#rm -rf /tmp/all_localservers.txt >/dev/null 2>&1
	#rm -rf /tmp/all_subscservers.txt >/dev/null 2>&1
	#rm -rf /tmp/sub_group_info.txt >/dev/null 2>&1
	#rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
}

# 添加ss:// ssr:// vmess://离线节点
start_offline_update() {
	echo_date "==================================================================="
	usleep 100000
	echo_date "通过SS/SSR/v2ray链接添加节点..."
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers.txt >/dev/null 2>&1
	rm -rf /tmp/all_subscservers.txt >/dev/null 2>&1
	ssrlinks=$(echo $ss_base64_links | sed 's/$/\n/'|sed '/^$/d')
	for ssrlink in $ssrlinks
	do
		if [ -n "$ssrlink" ]; then
			if [ -n "$(echo -n "$ssrlink" | grep "ssr://")" ]; then
				echo_date "检测到SSR链接...开始尝试解析..."
				new_ssrlink=$(echo -n "$ssrlink" | sed 's/ssr:\/\///g')
				decode_ssrlink=$(decode_url_link $new_ssrlink)
				get_ssr_node_info $decode_ssrlink 2
				add_ssr_nodes_offline
			elif [ -n "$(echo -n "$ssrlink" | grep "vmess://")" ]; then
				echo_date "检测到vmess链接...开始尝试解析..."
				new_v2raylink=$(echo -n "$ssrlink" | sed 's/vmess:\/\///g')
				decode_v2raylink=$(decode_url_link $new_v2raylink)
				decode_v2raylink=$(echo $decode_v2raylink | jq -c .)
				get_v2ray_remote_config $decode_v2raylink
				add_v2ray_servers 1
			elif [ -n "$(echo -n "$ssrlink" | grep "ss://")" ]; then
				echo_date "检测到SS链接...开始尝试解析..."
				if [ -n "$(echo -n "$ssrlink" | grep "#")" ]; then
					new_sslink=$(echo -n "$ssrlink" | awk -F'#' '{print $1}' | sed 's/ss:\/\///g')
					remarks=$(echo -n "$ssrlink" | awk -F'#' '{print $2}')
				else
					new_sslink=$(echo -n "$ssrlink" | sed 's/ss:\/\///g')
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
	true > $LOG_FILE
	http_response "$1"
	remove_all_node | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
1)
	# 删除所有订阅节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
	remove_sub_node | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
2)
	# 保存订阅设置但是不订阅
	set_lock
	true > $LOG_FILE
	http_response "$1"
	local_groups=$(export -p | grep ssconf_basic_ | grep _group_ | cut -d "=" -f2 | sort -u | wc -l)
	online_group=$(echo $ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | wc -l)
	echo_date "保存订阅节点成功，现共有 $online_group 组订阅来源，当前节点列表内已经订阅了 $local_groups 组..." | tee -a $LOG_FILE
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ]; then
		if [ "$ss_basic_node_update_day" = "7" ]; then
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置自动更新订阅服务在每天 $ss_basic_node_update_hr 点。" | tee -a $LOG_FILE
		else
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * $ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置自动更新订阅服务在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。" | tee -a $LOG_FILE
		fi
	else
		echo_date "关闭自动更新订阅服务！" | tee -a $LOG_FILE
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
3)
	# 使用订阅链接订阅ssr/v2ray节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
	echo_date "开始订阅" | tee -a $LOG_FILE
	start_online_update | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
4)
	# 添加ss:// ssr:// vmess://离线节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
	start_offline_update | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
5)
	prepare
	;;
6)
	# 使用订阅链接订阅ssr/v2ray节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
	echo_date "开始快速订阅" | tee -a $LOG_FILE
	start_online_update 1 | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
esac
