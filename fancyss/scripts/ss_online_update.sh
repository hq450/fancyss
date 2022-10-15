#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh

LOCK_FILE=/var/lock/online_update.lock
LOG_FILE=/tmp/upload/ss_log.txt
CONFIG_FILE=/koolshare/ss/ss.json
BACKUP_FILE_TMP=/tmp/ss_conf_tmp.sh
BACKUP_FILE=/tmp/ss_conf.sh
KEY_WORDS_1=$(echo $ss_basic_exclude | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_2=$(echo $ss_basic_include | sed 's/,$//g' | sed 's/,/|/g')
NODES_SEQ=$(dbus list ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
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
				ssconf_basic_ss_v2ray_
				ssconf_basic_ss_v2ray_opts_
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
				ssconf_basic_v2ray_kcp_seed
				ssconf_basic_v2ray_headtype_quic_
				ssconf_basic_v2ray_grpc_mode_
				ssconf_basic_v2ray_network_path_
				ssconf_basic_v2ray_network_host_
				ssconf_basic_v2ray_network_security_
				ssconf_basic_v2ray_network_security_ai_
				ssconf_basic_v2ray_network_security_alpn_h2_
				ssconf_basic_v2ray_network_security_alpn_http_
				ssconf_basic_v2ray_network_security_sni_
				ssconf_basic_v2ray_mux_enable_
				ssconf_basic_v2ray_mux_concurrency_
				ssconf_basic_v2ray_json_
				ssconf_basic_xray_use_json_
				ssconf_basic_xray_uuid_
				ssconf_basic_xray_encryption_
				ssconf_basic_xray_flow_
				ssconf_basic_xray_network_
				ssconf_basic_xray_headtype_tcp_
				ssconf_basic_xray_headtype_kcp_
				ssconf_basic_xray_kcp_seed
				ssconf_basic_xray_headtype_quic_
				ssconf_basic_xray_grpc_mode_
				ssconf_basic_xray_network_path_
				ssconf_basic_xray_network_host_
				ssconf_basic_xray_network_security_
				ssconf_basic_xray_network_security_ai_
				ssconf_basic_xray_network_security_alpn_h2_
				ssconf_basic_xray_network_security_alpn_http_
				ssconf_basic_xray_network_security_sni_
				ssconf_basic_xray_json_
				ssconf_basic_trojan_ai_
				ssconf_basic_trojan_uuid_
				ssconf_basic_trojan_sni_
				ssconf_basic_trojan_tfo_
				ssconf_basic_naive_prot_
				ssconf_basic_naive_server_
				ssconf_basic_naive_port_
				ssconf_basic_naive_user_
				ssconf_basic_naive_pass_
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

dbus_cset(){
	# set value after compare different
	#local _local_value=$(eval echo \$$1)
	local _local_value=$(dbus get $1)
	local _onlin_value=$2

	# 本地和在线参数均为空，返回
	if [ -z "${_local_value}" -a -z "${_onlin_value}" ];then
		return 0
	fi
	# 有本地参数，在线参数空，删除本地参数
	if [ -n "${_local_value}" -a -z "${_onlin_value}" ];then
		dbus remove $1
		return 1
	fi
	# 在线参数和本地参数不一样，更新本地参数
	if [ "${_local_value}" != "${_onlin_value}" ];then
		dbus set $1=$2
		return 1
	fi
	return 0
}

dbus_dset(){
	# set key when value exist, delete when empty
	if [ -n "$2" ];then
		dbus set $1=$2
	else
		dbus remove $1
	fi
}

dbus_eset(){
	# set key when value exist
	if [ -n "$2" ];then
		dbus set $1=$2
	fi
}

unset_lock(){
	flock -u 233
	rm -rf "${LOCK_FILE}"
}

get_type_name() {
	case "$1" in
		0)
			echo "ss"
		;;
		1)
			echo "ssr"
		;;
		2)
			echo "koolgame"
		;;
		3)
			echo "V2ray"
		;;
		3)
			echo "xray"
		;;
	esac
}

remove_node_info(){
	# remove group name
	for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
	do
		dbus remove ${conf1}
	done

	# remove group hash
	for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
	do
		dbus remove ${conf2}
	done
}

# 清除已有的所有节点配置
remove_all_node(){
	echo_date "删除所有节点信息！"
	confs=$(dbus list ssconf_basic_ | cut -d "=" -f1 | awk '{print $NF}')
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
	remove_nus=$(dbus list ssconf_basic_ | grep _group_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
	if [ -z "${remove_nus}" ]; then
		echo_date "节点列表内不存在任何订阅来源节点，退出！"
		return 1
	fi
	for remove_nu in ${remove_nus}
	do
		echo_date "移除第$remove_nu节点：【$(dbus get ssconf_basic_name_${remove_nu})】"
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
	local KEY_NU=$(dbus list ssconf_basic | cut -d "=" -f1 | sed '/^$/d' | wc -l)
	local VAL_NU=$(dbus list ssconf_basic | cut -d "=" -f2 | sed '/^$/d' | wc -l)
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
		dbus list ssconf_basic_name_ | awk -F"=" '{print $1}' | awk -F"_" '{print $NF}' | sort -n | while read nu
		do
			for item in $PREFIX; do
				#{
					local tmp=$(dbus get ${item}${nu})
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
	local flag=$2
	local len=${#link}
	local mod4=$(($len%4))
	local var="===="
	[ "$mod4" -gt "0" ] && local link=${link}${var:${mod4}}
	local decode_info=$(echo -n "${link}" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null)
	# 如果解析出乱码，返回空值，避免skipd中写入乱码valye导致错误！
	echo "${decode_info}" | isutf8 >/dev/null
	if [ "$?" != "0" ];then
		echo ""
		return 1
	fi
	# 如果解析出多行结果，返回空值，避免skipd中写入多行value导致错误！
	local is_multi=$(echo "${decode_info}" | wc -l)
	if [ "${is_multi}" != "1" -a -z "${flag}" ];then
		echo ""
		return 2
	fi
	# 返回解析结果
	echo -n "${decode_info}"
	return 0
}

get_ss_node(){
	local urllink="$1"
	local action="$2"
	unset remarks server_raw_1 server_raw_2 server_tmp server_port_tmp server server_port encrypt_info decrypt_info encrypt_method password plugin_support obfs_para plugin_prog obfs_method obfs_host group
	
	remarks=$(echo "${urllink}" | awk -F"#" '{print $NF}' | urldecode | sed 's/^[[:space:]]//g')
	echo "${remarks}" | isutf8 -q
	if [ "$?" != "0" ];then
		echo_date "当前节点名中存在特殊字符，节点添加后可能出现乱码！"
	fi
	
	server_raw_1=$(echo "${urllink}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
	if [ -n "${server_raw_1}" ];then
		server_tmp=$(echo "${server_raw_1}" | awk -F':' '{print $1}')
		server_port_tmp=$(echo "${server_raw_1}" | awk -F':' '{print $2}')
	fi
	encrypt_info=$(echo "${urllink}" | sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g'|cut -d "|" -f1)
	decrypt_info=$(decode_url_link $(echo "$encrypt_info"))
	server_raw_2=$(echo "${decrypt_info}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
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
	plugin_support=$(echo "${urllink}"|grep -Eo "plugin=")
	# ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNToxMjM@1.1.1.1:8388/?plugin=obfs-local%3bobfs%3dhttp%3bobfs-host%3dwww.bing.com#test_obfs-local
	# ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNToxMjM@1.1.1.1:8388/?plugin=v2ray-plugin;tls;host:mydomain.me#test
	if [ -n "${plugin_support}" ];then
		obfs_para=$(echo "${urllink}" | sed -n 's/.\+plugin=\(\)/\1/p'|sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g' | awk -F'|' '{print $1}'| urldecode)
		plugin_prog=$(echo "${obfs_para}" | awk -F';' '{print $1}')
		if [ "${plugin_prog}" == "obfs-local" -o "${plugin_prog}" == "simple-obfs" ];then
			ss_obfs=$(echo "${obfs_para}" | awk -F';' '{print $2}'| awk -F'=' '{print $2}')
			ss_obfs_host=$(echo "${obfs_para}" | awk -F';' '{print $3}'| awk -F'=' '{print $2}')
			ss_v2ray=""
			ss_v2_opts=""
		elif [ "${plugin_prog}" == "v2ray-plugin" ];then
			ss_obfs=""
			ss_obfs_host=""
			ss_v2ray="1"
			ss_v2_opts=$(echo "${obfs_para}" | sed 's/v2ray-plugin;//g')
		fi
	else
		ss_obfs=""
		ss_obfs_host=""
		ss_v2ray=""
		ss_v2_opts=""
	fi

	# ss订阅规范不一，目前我没有见到机场有给group信息，那么直接用订阅链接域名好了
	if [ "${action}" == "1" ];then
		# 在线订阅，group从订阅链接里拿
		ss_group=${DOMAIN_NAME}
		ss_group_hash="${ss_group}_${SUB_LINK_HASH:0:4}"
	fi
	if [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		ss_group=""
		ss_group_hash""
	fi

	#echo ------------
	#echo remarks: ${remarks}
	#echo server: ${server}
	#echo server_port: ${server_port}
	#echo encrypt_method: ${encrypt_method}
	#echo password: ${password}
	#echo plugin_prog: ${plugin_prog}
	#echo ss_obfs: ${ss_obfs}
	#echo ss_obfs_host: ${ss_obfs_host}
	#echo ss_v2ray: ${ss_v2ray}
	#echo ss_v2_opts: ${ss_v2_opts}
	#echo ------------

	if [ "${action}" == "1" ];then
		if [ -n "${ss_group}" -a -n "${server}" -a -n "${remarks}" -a -n "${server_port}" -a -n "${password}" -a -n "${encrypt_method}" ]; then
			# 记录有效节点
			server_base64=$(echo ${server} | base64_encode | sed 's/ -//g')
			group_base64=$(echo ${ss_group_hash} | base64_encode | sed 's/ -//g')
			remark_base64=$(echo ${remarks} | base64_encode | sed 's/ -//g')
			echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/cur_subscservers.txt
		else
			# 丢弃无效节点
			return 1
		fi
	fi
	
	if [ "${action}" == "2" ];then
		if [ -n "${server}" -a -n "${remarks}" -a -n "${server_port}" -a -n "${password}" -a -n "${encrypt_method}" ]; then
			# 保留有效节点
			return 0
		else
			# 丢弃无效节点
			return 1
		fi
	fi
}

add_ss_node(){
	local flag="$1"
	if [ "${flag}" == "1" ]; then
		echo_date "SS节点：检测到一个错误节点，跳过！"
		return 1
	fi
	let NODE_INDEX+=1
	echo_date "SS节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
	dbus_eset ssconf_basic_name_${NODE_INDEX} "${remarks}"
	dbus_eset ssconf_basic_mode_${NODE_INDEX} "${ssr_subscribe_mode}"
	dbus_eset ssconf_basic_server_${NODE_INDEX} "${server}"
	dbus_eset ssconf_basic_port_${NODE_INDEX} "${server_port}"
	dbus_eset ssconf_basic_method_${NODE_INDEX} "${encrypt_method}"
	dbus_eset ssconf_basic_password_${NODE_INDEX} "${password}"
	dbus_eset ssconf_basic_type_${NODE_INDEX} "0"
	dbus_eset ssconf_basic_group_${NODE_INDEX} "${ss_group_hash}"
	dbus_eset ssconf_basic_ss_obfs_${NODE_INDEX} "${ss_obfs}"
	dbus_eset ssconf_basic_ss_obfs_host_${NODE_INDEX} "${ss_obfs_host}"
	dbus_eset ssconf_basic_ss_v2ray_${NODE_INDEX} "${ss_v2ray}"
	dbus_eset ssconf_basic_ss_v2ray_opts_${NODE_INDEX} "${v2_plugin_opts}"
	let addnum+=1
}

update_ss_node(){
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
	local isadded_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_ss_node
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点名以外的参数，如节点域名！通过节点名称获取index
		local index_line_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ss_node
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点地址以外的参数，如名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ss_node
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
		local KEY_LOCAL_NAME=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "SS节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "SS节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SS节点：移除本地【${remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "SS节点：移除本地【${remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "SS节点：移除本地【${remarks}】节点，因为不匹配[包括]关键词"
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
				if [ -n "$(dbus get ${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			dbus_cset "ssconf_basic_group_${index}" "${ss_group_hash}"
			[ "$?" == "1" ] && INFO="${INFO}分组信息 "

			dbus_cset "ssconf_basic_mode_${index}" "${ssr_subscribe_mode}"
			[ "$?" == "1" ] && INFO="${INFO}模式 "

			if [ "${SKIPDB_FLAG}" == "2" ];then
				dbus_cset "ssconf_basic_name_${index}" "${remarks}"
				[ "$?" == "1" ] && INFO="${INFO}节点名 "
			fi

			if [ "${SKIPDB_FLAG}" == "1" ];then
				dbus_cset "ssconf_basic_server_${index}" "${server}"
				[ "$?" == "1" ] && INFO="${INFO}节点地址 "
			fi

			dbus_cset "ssconf_basic_port_${index}" "${server_port}"
			[ "$?" == "1" ] && INFO="${INFO}端口 "

			dbus_cset "ssconf_basic_password_${index}" "${password}"
			[ "$?" == "1" ] && INFO="${INFO}密码 "

			dbus_cset "ssconf_basic_method_${index}" "${encrypt_method}"
			[ "$?" == "1" ] && INFO="${INFO}加密 "

			dbus_cset "ssconf_basic_ss_obfs_${index}" "${ss_obfs}"
			[ "$?" == "1" ] && INFO="${INFO}obfs "

			dbus_cset "ssconf_basic_ss_obfs_host_${index}" "${ss_obfs_host}"
			[ "$?" == "1" ] && INFO="${INFO}obfs-host "

			dbus_cset "ssconf_basic_ss_v2ray_${index}" "${ss_v2ray}"
			[ "$?" == "1" ] && INFO="${INFO}v2ray-plugin选项 "

			dbus_cset "ssconf_basic_ss_v2_opts_${index}" "${ss_v2_opts}"
			[ "$?" == "1" ] && INFO="${INFO}v2ray-plugin参数 "			

			if [ -n "${INFO}" ]; then
				INFO=$(echo "${INFO}" | sed 's/[[:space:]]$//' | sed 's/[[:space:]]/+/g')
				echo_date "SS节点：【${remarks}】更新！原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "SS节点：【${remarks}】参数未发生变化，跳过！"
			fi
		fi
	fi
	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${ss_group} >> /tmp/sub_group_info.txt
}

get_ssr_node(){
	local urllink="$1"
	local action="$2"
	unset decrypt_info server server_port protocol encrypt_method obfs password obfsparam_temp obfsparam protoparam_temp protoparam remarks_temp remarks group_temp group
	
	local decrypt_info=$(decode_url_link ${urllink})
	server=$(echo "${decrypt_info}" | awk -F':' '{print $1}' | sed 's/[[:space:]]//g')
	server_port=$(echo "${decrypt_info}" | awk -F':' '{print $2}')
	encrypt_method=$(echo "${decrypt_info}" |awk -F':' '{print $4}')
	password=$(decode_url_link $(echo "${decrypt_info}" | awk -F':' '{print $6}' | awk -F'/' '{print $1}'))
	password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
	
	protocol=$(echo "${decrypt_info}" | awk -F':' '{print $3}')
	protoparam_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "protoparam.+" | sed 's/protoparam=//g' | awk -F'&' '{print $1}')
	if [ -n "${protoparam_temp}" ];then
		protoparam=$(decode_url_link ${protoparam_temp} | sed 's/_compatible//g' | sed 's/[[:space:]]//g')
	else
		protoparam=""
	fi
	
	obfs=$(echo "${decrypt_info}" | awk -F':' '{print $5}' | sed 's/_compatible//g')
	if [ "${ssr_subscribe_obfspara}" == "0" ];then
			obfsparam=""
	elif [ "${ssr_subscribe_obfspara}" == "1" ];then
		obfsparam_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "obfsparam.+" | sed 's/obfsparam=//g' | awk -F'&' '{print $1}')
		if [ -n "${obfsparam_temp}" ];then
			obfsparam=$(decode_url_link ${obfsparam_temp})
		else
			obfsparam=""
		fi
	elif [ "${ssr_subscribe_obfspara}" == "2" ];then
		obfsparam="${ssr_subscribe_obfspara_val}"
	fi
	remarks_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "remarks.+" | sed 's/remarks=//g' | awk -F'&' '{print $1}')
	# 在线订阅必须要remarks信息
	if [ "${action}" == "1" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(decode_url_link ${remarks_temp})
		else
			remarks=""
		fi
	fi
	# 离线订阅自动添加一个remarks信息
	if [ "${action}" == "2" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(decode_url_link ${remarks_temp})
		else
			remarks="${server}"
		fi
	fi
	group_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "group.+" | sed 's/group=//g' | awk -F'&' '{print $1}')
	if [ "${action}" == "1" ]; then
		# 在线订阅，group从订阅链接里拿
		if [ -n "${group_temp}" ];then
			ssr_group=$(decode_url_link $group_temp)
		else
			ssr_group=${DOMAIN_NAME}
		fi
		ssr_group_hash="${ssr_group}_${SUB_LINK_HASH:0:4}"
	fi

	if [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		ssr_group=""
		ssr_group_hash=""
	fi
	
	# for debug, please keep it here~
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

	if [ "${action}" == "1" ];then
		if [ -n "${ssr_group}" -a -n "${server}" -a -n "${remarks}" -a -n "${server_port}" -a -n "${password}" -a -n "${protocol}" -a -n "${obfs}" -a -n "${encrypt_method}" ]; then
			# 记录有效节点
			server_base64=$(echo $server | base64_encode | sed 's/ -//g')
			group_base64=$(echo ${ssr_group_hash} | base64_encode | sed 's/ -//g')
			remark_base64=$(echo $remarks | base64_encode | sed 's/ -//g')
			echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/cur_subscservers.txt
		else
			# 丢弃无效节点
			return 1
		fi
	fi

	if [ "${action}" == "2" ];then
		if [ -n "${server}" -a -n "${remarks}" -a -n "${server_port}" -a -n "${password}" -a -n "${protocol}" -a -n "${obfs}" -a -n "${encrypt_method}" ]; then
			# 保留有效节点
			return 0
		else
			# 丢弃无效节点
			return 1
		fi
	fi
}

add_ssr_node(){
	local flag="$1"
	if [ "${flag}" == "1" ]; then
		echo_date "SSR节点：检测到一个错误节点，跳过！"
		return 1
	fi
	let NODE_INDEX+=1
	echo_date "SSR节点：新增加【$remarks】到节点列表第 ${NODE_INDEX} 位。"
	dbus_eset ssconf_basic_group_${NODE_INDEX} "${ssr_group_hash}"
	dbus_eset ssconf_basic_type_${NODE_INDEX} "1"
	dbus_eset ssconf_basic_mode_${NODE_INDEX} "${ssr_subscribe_mode}"
	dbus_eset ssconf_basic_name_${NODE_INDEX} "${remarks}"
	dbus_eset ssconf_basic_server_${NODE_INDEX} "${server}"
	dbus_eset ssconf_basic_port_${NODE_INDEX} "${server_port}"
	dbus_eset ssconf_basic_password_${NODE_INDEX} "${password}"
	dbus_eset ssconf_basic_method_${NODE_INDEX} "${encrypt_method}"
	dbus_eset ssconf_basic_rss_protocol_${NODE_INDEX} "${protocol}"
	dbus_eset ssconf_basic_rss_protocol_param_${NODE_INDEX} "${protoparam}"
	dbus_eset ssconf_basic_rss_obfs_${NODE_INDEX} "${obfs}"
	dbus_eset ssconf_basic_rss_obfs_param_${NODE_INDEX} "${obfsparam}"
	let addnum+=1
}

update_ssr_node(){
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
	local isadded_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_ssr_node
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点名以外的参数，如节点域名！通过节点名称获取index
		local index_line_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ssr_node
				fi
			else
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点地址以外的参数，如名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_ssr_node
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
		local KEY_LOCAL_NAME=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERV=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

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
			for item in ${PREFIX}
			do
				if [ -n "$(dbus get ${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			# 在本地的订阅节点中找到该节点，检测下配置是否更改，如果更改，则更新配置
			dbus_cset "ssconf_basic_group_${index}" "${ssr_group}_${SUB_LINK_HASH:0:4}"
			[ "$?" == "1" ] && INFO="${INFO}分组信息 "
			
			dbus_cset "ssconf_basic_mode_${index}" "${ssr_subscribe_mode}"
			[ "$?" == "1" ] && INFO="${INFO}模式 "

			if [ "${SKIPDB_FLAG}" == "2" ];then
				dbus_cset "ssconf_basic_name_${index}" "${remarks}"
				[ "$?" == "1" ] && INFO="${INFO}节点名 "
			fi

			if [ "${SKIPDB_FLAG}" == "1" ];then
				dbus_cset "ssconf_basic_server_${index}" "${server}"
				[ "$?" == "1" ] && INFO="${INFO}节点地址 "
			fi
			
			dbus_cset "ssconf_basic_port_${index}" "${server_port}"
			[ "$?" == "1" ] && INFO="${INFO}端口 "

			dbus_cset "ssconf_basic_password_${index}" "${password}"
			[ "$?" == "1" ] && INFO="${INFO}密码 "

			dbus_cset "ssconf_basic_method_${index}" "${encrypt_method}"
			[ "$?" == "1" ] && INFO="${INFO}加密 "

			dbus_cset "ssconf_basic_rss_protocol_${index}" "${protocol}"
			[ "$?" == "1" ] && INFO="${INFO}协议 "

			dbus_cset "ssconf_basic_rss_protocol_param_${index}" "${protoparam}"
			[ "$?" == "1" ] && INFO="${INFO}协议参数 "
			
			dbus_cset "ssconf_basic_rss_obfs_${index}" "${obfs}"
			[ "$?" == "1" ] && INFO="${INFO}混淆 "

			dbus_cset "ssconf_basic_rss_obfs_param_${index}" "${obfsparam}"
			[ "$?" == "1" ] && INFO="${INFO}混淆参数 "
			
			if [ -n "${INFO}" ]; then
				INFO=$(echo "$INFO" | sed 's/[[:space:]]$//' | sed 's/[[:space:]]/+/g')
				echo_date "SSR节点：【${remarks}】更新！原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "SSR节点：【${remarks}】参数未发生变化，跳过！"
			fi
		fi
	fi

	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${ssr_group} >> /tmp/sub_group_info.txt
}

get_vmess_node(){
	local urllink="$1"
	local action="$2"
	unset v2ray_ps_tmp v2ray_remark_tmp v2ray_ps v2ray_add v2ray_port v2ray_id v2ray_aid v2ray_scy v2ray_net v2ray_type_tmp v2ray_type
	unset v2ray_headerType_tmp v2ray_headtype_tcp v2ray_headtype_kcp v2ray_headtype_quic v2ray_grpc_mode v2ray_tls_tmp v2ray_tls v2ray_kcp_seed
	unset v2ray_ai_tmp v2ray_ai v2ray_alpn v2ray_alpn_h2_tmp v2ray_alpn_http_tmp v2ray_alpn_h2 v2ray_alpn_http v2ray_sni v2ray_v v2ray_host v2ray_path v2ray_group v2ray_group_hash
	local decrypt_info=$(decode_url_link ${urllink} flag | jq -c .)
	
	# node name, could be ps/remark in sub json，必须项
	v2ray_ps_tmp=$(echo "${decrypt_info}" | jq -r .ps | sed 's/[[:space:]]//g')
	if [ "${v2ray_ps_tmp}" == "null" -o -z "${v2ray_ps_tmp}" ];then
		v2ray_ps_tmp=""
	fi
	v2ray_remark_tmp=$(echo "${decrypt_info}" | jq -r .remark | sed 's/[[:space:]]//g')
	if [ "${v2ray_remark_tmp}" == "null" -o -z "${v2ray_remark_tmp}" ];then
		v2ray_remark_tmp=""
	fi
	if [ -z "${v2ray_ps_tmp}" -a -z "${v2ray_remark_tmp}" ];then
		v2ray_ps=""
	elif [ -z "${v2ray_ps_tmp}" -a -n "${v2ray_remark_tmp}" ];then
		v2ray_ps=${v2ray_ps_tmp}
	elif [ -n "${v2ray_ps_tmp}" -a -z "${v2ray_remark_tmp}" ];then
		v2ray_ps=${v2ray_ps_tmp}
	elif [ -n "${v2ray_ps_tmp}" -a -n "${v2ray_remark_tmp}" ];then
		v2ray_ps=${v2ray_ps_tmp}
	fi
	
	# node server addr，必须项
	v2ray_add=$(echo "${decrypt_info}" | jq -r .add | sed 's/[[:space:]]//g')
	if [ "${v2ray_add}" == "null" -o -z "${v2ray_add}" ];then
		v2ray_add=""
	fi
	
	# node server port，必须项
	v2ray_port=$(echo "${decrypt_info}" | jq -r .port | sed 's/[[:space:]]//g')
	if [ "${v2ray_port}" == "null" -o -z "${v2ray_port}" ];then
		v2ray_port=""
	fi
	
	# node uuid，必须项
	v2ray_id=$(echo "${decrypt_info}" | jq -r .id | sed 's/[[:space:]]//g')
	if [ "${v2ray_id}" == "null" -o -z "${v2ray_id}" ];then
		v2ray_id=""
	fi
	
	# alterid，必须项，如果为空则填0好了
	v2ray_aid=$(echo "${decrypt_info}" | jq -r .aid | sed 's/[[:space:]]//g')
	if [ "${v2ray_aid}" == "null" -o -z "${v2ray_aid}" ];then
		v2ray_aid="0"
	fi

	# 加密方式 (security)，v2ray必须字段，订阅中机场很多不提供该值，设为auto就好了
	v2ray_scy=$(echo "${decrypt_info}" | jq -r .scy)
	if [ "${v2ray_scy}" == "null" -o -z "${v2ray_scy}" ];then
		v2ray_scy="auto"
	fi

	# 传输协议: tcp kcp ws h2 quic grpc
	v2ray_net=$(echo "${decrypt_info}" | jq -r .net)
	if [ "${v2ray_net}" == "null" -o -z "${v2ray_net}" ];then
		v2ray_net=""
	fi
	
	# 伪装类型，在tcp kcp quic中使用，grpc mode借用此字段，ws和h2中不使用
	v2ray_type_tmp=$(echo "${decrypt_info}" | jq -r .type)
	if [ "${v2ray_type_tmp}" == "null" -o -z "${v2ray_type_tmp}" ];then
		v2ray_type_tmp=""
	fi
	v2ray_headerType_tmp=$(echo "${decrypt_info}" | jq -r .headerType)
	if [ "${v2ray_headerType_tmp}" == "null" -o -z "${v2ray_headerType_tmp}" ];then
		v2ray_headerType_tmp=""
	fi
	if [ -z "${v2ray_type_tmp}" -a -z "${v2ray_headerType_tmp}" ];then
		v2ray_type=""
	elif [ -z "${v2ray_type_tmp}" -a -n "${v2ray_headerType_tmp}" ];then
		v2ray_type=${v2ray_headerType_tmp}
	elif [ -n "${v2ray_type_tmp}" -a -z "${v2ray_headerType_tmp}" ];then
		v2ray_type=${v2ray_type_tmp}
	elif [ -n "${v2ray_type_tmp}" -a -n "${v2ray_headerType_tmp}" ];then
		v2ray_type=${v2ray_type_tmp}
	fi
	case ${v2ray_net} in
	tcp)
		# tcp协议设置【tcp伪装类型 (type)】
		v2ray_headtype_tcp=${v2ray_type}
		v2ray_headtype_kcp=""
		v2ray_headtype_quic=""
		v2ray_grpc_mode=""
		if [ -z "${v2ray_headtype_tcp}" ];then
			v2ray_headtype_tcp="none"
		fi
		;;
	kcp)
		# kcp协议设置【kcp伪装类型 (type)】
		v2ray_headtype_tcp=""
		v2ray_headtype_kcp=${v2ray_type}
		v2ray_headtype_quic=""
		v2ray_grpc_mode=""
		if [ -z "${v2ray_headtype_kcp}" ];then
			v2ray_headtype_kcp="none"
		fi
		;;
	ws|h2)
		# ws/h2协议设置【伪装域名 (host))】
		v2ray_headtype_tcp=""
		v2ray_headtype_kcp=""
		v2ray_headtype_quic=""
		v2ray_grpc_mode=""
		;;
	quic)
		# quic协议设置【quic伪装类型 (type)】
		v2ray_headtype_tcp=""
		v2ray_headtype_kcp=""
		v2ray_headtype_quic=${v2ray_type}
		v2ray_grpc_mode=""
		if [ -z "${v2ray_headtype_quic}" ];then
			v2ray_headtype_quic="none"
		fi
		;;
	grpc)
		# grpc协议设置【grpc模式】
		v2ray_headtype_tcp=""
		v2ray_headtype_kcp=""
		v2ray_headtype_quic=""
		v2ray_grpc_mode=${v2ray_type}
		if [ -z "${v2ray_grpc_mode}" ];then
			v2ray_grpc_mode="gun"
		fi
		;;
	esac

	# 底层传输安全：none, tls
	v2ray_tls_tmp=$(echo "${decrypt_info}" | jq -r .tls)
	if [ "${v2ray_tls_tmp}" == "tls" ];then
		v2ray_tls="tls"

		# 跳过证书验证 (AllowInsecure)，此处在底层传输安全（network_security）为tls时使用
		v2ray_ai_tmp=$(echo "${decrypt_info}" | jq -r .verify_cert)
		if [ "${v2ray_ai_tmp}" == "true" ];then
			v2ray_ai=""
		else
			v2ray_ai="1"
		fi

		# alpn: h2; http/1.1; h2,http/1.1，此处在底层传输安全（network_security）为tls时使用
		v2ray_alpn=$(echo "${decrypt_info}" | jq -r .alpn)
		v2ray_alpn_h2_tmp=$(echo "${v2ray_alpn}" | grep "h2")
		v2ray_alpn_http_tmp=$(echo "${v2ray_alpn}" | grep "http/1.1")
		if [ -n "${v2ray_alpn_h2_tmp}" ];then
			v2ray_alpn_h2="1"
		else
			v2ray_alpn_h2=""
		fi
		if [ -n "${v2ray_alpn_http_tmp}" ];then
			v2ray_alpn_http="1"
		else
			v2ray_alpn_http=""
		fi

		# SNI, 如果空则用host替代，如果host空则空，此处在底层传输安全（network_security）为tls时使用
		v2ray_sni=$(echo "${decrypt_info}" | jq -r .sni)
		if [ "${v2ray_sni}" == "null" -o -z "${v2ray_sni}" ];then
			v2ray_sni=""
		fi
	else
		v2ray_tls="none"
		v2ray_ai=""
		v2ray_alpn_h2=""
		v2ray_alpn_http=""
		v2ray_sni=""
	fi

	# sub version, 1 or 2
	v2ray_v=$(echo "${decrypt_info}" | jq -r .v)
	if [ "${v2ray_v}" == "null" -o -z "${v2ray_v}" ];then
		v2ray_v=""
	fi

	# v2ray host & path
	v2ray_host=$(echo "${decrypt_info}" | jq -r .host)
	v2ray_path=$(echo "${decrypt_info}" | jq -r .path)
	if [ "${v2ray_host}" == "null" -o -z "${v2ray_host}" ];then 
		v2ray_host=""
	fi
	if [ "${v2ray_path}" == "null" -o -z "${v2ray_path}" ];then 
		v2ray_path=""
	fi

	# host is not needed in kcp and grpc
	if [ "${v2ray_net}" == "kcp" -o "${v2ray_net}" == "grpc" ];then 
		v2ray_host=""
	fi

	if [ "${v2ray_net}" == "kcp" ];then 
		v2ray_kcp_seed=${v2ray_path}
	fi
	
	# 根据订阅版本不同，来设置host path
	if [ "${v2ray_v}" != "2" -a "${v2ray_net}" == "ws" -a -n "${v2ray_host}" ]; then
		format_ws=$(echo ${v2ray_host} | grep -E ";")
		if [ -n "${format_ws}" ]; then
			v2ray_host=$(echo ${v2ray_host} | cut -d ";" -f1)
			v2ray_path=$(echo ${v2ray_host} | cut -d ";" -f2)
		else
			v2ray_host=""
			v2ray_path=${v2ray_host}
		fi
	fi

	if [ "${action}" == "1" ];then
		v2ray_group=${DOMAIN_NAME}
		v2ray_group_hash="${v2ray_group}_${SUB_LINK_HASH:0:4}"
	fi
	if [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		v2ray_group=""
		v2ray_group_hash=""
	fi
	
	# for debug
	# echo ------------------
	# echo v2ray_v: ${v2ray_v}
	# echo v2ray_ps: ${v2ray_ps}
	# echo v2ray_add: ${v2ray_add}
	# echo v2ray_port: ${v2ray_port}
	# echo v2ray_id: ${v2ray_id}
	# echo v2ray_net: ${v2ray_net}
	# echo v2ray_type: ${v2ray_type}
	# echo v2ray_scy: ${v2ray_scy}
	# echo v2ray_host: ${v2ray_host}
	# echo v2ray_path: ${v2ray_path}
	# echo v2ray_tls: ${v2ray_tls}
	# echo ------------------
	
	if [ "${action}" == "1" ];then
		# group是从订阅链接来的，以下其它值是必须有的
		if [ -n "${v2ray_group}" -a -n "${v2ray_ps}" -a -n "${v2ray_add}" -a -n "${v2ray_port}" -a -n "${v2ray_id}" -a -n "${v2ray_aid}" -a -n "${v2ray_net}" ];then
			server_base64=$(echo ${v2ray_add} | base64_encode | sed 's/ -//g')
			group_base64=$(echo ${v2ray_group_hash} | base64_encode | sed 's/ -//g')
			remark_base64=$(echo ${v2ray_ps} | base64_encode | sed 's/ -//g')
			echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/cur_subscservers.txt
		else
			return 1
		fi
	fi

	if [ "${action}" == "2" ];then
		if [ -n "${v2ray_ps}" -a -n "${v2ray_add}" -a -n "${v2ray_port}" -a -n "${v2ray_id}" -a -n "${v2ray_aid}" -a -n "${v2ray_net}" ];then
			# 保留有效节点
			return 0
		else
			# 丢弃无效节点
			return 1
		fi
	fi
}

add_vmess_node(){
	local flag="$1"
	if [ "${flag}" == "1" ]; then
		echo_date "v2ray节点：检测到一个错误节点，跳过！"
		exit 1
	fi
	let NODE_INDEX+=1
	echo_date "v2ray节点：新增加【${v2ray_ps}】到节点列表第 ${NODE_INDEX} 位。"
	dbus_eset ssconf_basic_type_${NODE_INDEX} "3"
	dbus_eset ssconf_basic_v2ray_use_json_${NODE_INDEX}
	dbus_eset ssconf_basic_group_${NODE_INDEX} "${v2ray_group_hash}"
	dbus_eset ssconf_basic_mode_${NODE_INDEX} "${ssr_subscribe_mode}"
	dbus_eset ssconf_basic_name_${NODE_INDEX} "${v2ray_ps}"
	dbus_eset ssconf_basic_server_${NODE_INDEX} "${v2ray_add}"
	dbus_eset ssconf_basic_port_${NODE_INDEX} "${v2ray_port}"
	dbus_eset ssconf_basic_v2ray_uuid_${NODE_INDEX} "${v2ray_id}"
	dbus_eset ssconf_basic_v2ray_alterid_${NODE_INDEX} "${v2ray_aid}"
	dbus_eset ssconf_basic_v2ray_network_${NODE_INDEX} "${v2ray_net}"
	dbus_eset ssconf_basic_v2ray_security_${NODE_INDEX} "${v2ray_scy}"
	dbus_eset ssconf_basic_v2ray_headtype_tcp_${NODE_INDEX} "${v2ray_headtype_tcp}"
	dbus_eset ssconf_basic_v2ray_headtype_kcp_${NODE_INDEX} "${v2ray_headtype_kcp}"
	dbus_eset ssconf_basic_v2ray_headtype_quic_${NODE_INDEX} "${v2ray_headtype_quic}"
	dbus_eset ssconf_basic_v2ray_grpc_mode_${NODE_INDEX} "${v2ray_grpc_mode}"
	dbus_eset ssconf_basic_v2ray_network_security_${NODE_INDEX} "${v2ray_tls}"
	dbus_eset ssconf_basic_v2ray_network_security_ai_${NODE_INDEX} "${v2ray_ai}"
	dbus_eset ssconf_basic_v2ray_network_security_alpn_h2_${NODE_INDEX} "${v2ray_alpn_h2}"
	dbus_eset ssconf_basic_v2ray_network_security_alpn_http_${NODE_INDEX} "${v2ray_alpn_http}"
	dbus_eset ssconf_basic_v2ray_network_security_sni_${NODE_INDEX} "${v2ray_sni}"
	dbus_eset ssconf_basic_v2ray_network_host_${NODE_INDEX} "${v2ray_host}"
	dbus_eset ssconf_basic_v2ray_network_path_${NODE_INDEX} "${v2ray_path}"
	dbus_eset ssconf_basic_v2ray_kcp_seed_${NODE_INDEX} "${v2ray_kcp_seed}"
	dbus_eset ssconf_basic_v2ray_mux_enable_${NODE_INDEX}
	let addnum+=1
}

update_vmess_node(){
	local FAILED_FLAG=$1
	local UPDATE_FLAG
	local DELETE_FLAG
	local SKIPDB_FLAG
	local INFO

	if [ "${FAILED_FLAG}" == "1" ]; then
		echo_date "v2ray订阅：检测到一个错误节点，跳过！"
		return 1
	fi

	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管

	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${v2ray_ps} ${v2ray_add} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${v2ray_ps} ${v2ray_add} | grep -Eo "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "v2ray节点：不添加【${v2ray_ps}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "v2ray节点：不添加【${v2ray_ps}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "v2ray节点：不添加【${v2ray_ps}】节点，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "v2ray节点：不添加【${v2ray_ps}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "v2ray节点：不添加【${v2ray_ps}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	else
		local UPDATE_FLAG=0
	fi

	# ------------------------------- 节点添加/修改逻辑 -------------------------------
	local isadded_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_vmess_node
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点名以外的参数，如节点域名！通过节点名称获取index
		local index_line_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_vmess_node
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点地址以外的参数，如名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_vmess_node
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
		local KEY_LOCAL_NAME=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
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
				if [ -n "$(dbus get ${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			dbus_cset "ssconf_basic_group_${index}" "${v2ray_group_hash}"
			[ "$?" == "1" ] && INFO="${INFO}分组信息 "
				
			dbus_cset "ssconf_basic_mode_${index}" "${ssr_subscribe_mode}"
			[ "$?" == "1" ] && INFO="${INFO}模式 "
			
			dbus_cset "ssconf_basic_name_${index}" "${v2ray_ps}"
			[ "$?" == "1" ] && INFO="${INFO}节点名 "
			
			dbus_cset "ssconf_basic_server_${index}" "${v2ray_add}"
			[ "$?" == "1" ] && INFO="${INFO}节点地址 "
			
			dbus_cset "ssconf_basic_port_${index}" "${v2ray_port}"
			[ "$?" == "1" ] && INFO="${INFO}端口 "
			
			dbus_cset "ssconf_basic_v2ray_uuid_${index}" "${v2ray_id}"
			[ "$?" == "1" ] && INFO="${INFO}用户id "

			dbus_cset "ssconf_basic_v2ray_alterid_${index}" "${v2ray_aid}"
			[ "$?" == "1" ] && INFO="${INFO}额外id "

			dbus_cset "ssconf_basic_v2ray_security_${index}" "${v2ray_scy}"
			[ "$?" == "1" ] && INFO="${INFO}加密方式 "	
			
			dbus_cset "ssconf_basic_v2ray_network_${index}" "${v2ray_net}"
			[ "$?" == "1" ] && INFO="${INFO}传输协议 "
			
			dbus_cset "ssconf_basic_v2ray_headtype_tcp_${index}" "${v2ray_headtype_tcp}"
			[ "$?" == "1" ] && INFO="${INFO}tcp http伪装类型 "

			dbus_cset "ssconf_basic_v2ray_headtype_kcp_${index}" "${v2ray_headtype_kcp}"
			[ "$?" == "1" ] && INFO="${INFO}kcp伪装类型 "

			dbus_cset "ssconf_basic_v2ray_headtype_quic_${index}" "${v2ray_headtype_quic}"
			[ "$?" == "1" ] && INFO="${INFO}quic伪装类型 "

			dbus_cset "ssconf_basic_v2ray_grpc_mode_${index}" "${v2ray_grpc_mode}"
			[ "$?" == "1" ] && INFO="${INFO}quic伪装类型 "
			
			dbus_cset "ssconf_basic_v2ray_network_host_${index}" "${v2ray_host}"
			[ "$?" == "1" ] && INFO="${INFO}伪装域名 "
			
			dbus_cset "ssconf_basic_v2ray_network_path_${index}" "${v2ray_path}"
			[ "$?" == "1" ] && INFO="${INFO}路径 "

			dbus_cset "ssconf_basic_v2ray_kcp_seed_${index}" "${v2ray_kcp_seed}"
			[ "$?" == "1" ] && INFO="${INFO}路径 "

			dbus_cset "ssconf_basic_v2ray_network_security_${index}" "${v2ray_tls}"
			[ "$?" == "1" ] && INFO="${INFO}底层传输安全 "

			dbus_cset "ssconf_basic_v2ray_network_security_ai_${index}" "${v2ray_ai}"
			[ "$?" == "1" ] && INFO="${INFO}证书验证 "

			dbus_cset "ssconf_basic_v2ray_network_security_alpn_h2_${index}" "${v2ray_alpn_h2}"
			[ "$?" == "1" ] && INFO="alpn:h2 "

			dbus_cset "ssconf_basic_v2ray_network_security_alpn_ht_${index}" "${v2ray_alpn_http}"
			[ "$?" == "1" ] && INFO="alpn:http/1.1 "

			dbus_cset "ssconf_basic_v2ray_network_security_sni_${index}" "${v2ray_sni}"
			[ "$?" == "1" ] && INFO="${INFO}SNI "

			if [ -n "${INFO}" ]; then
				INFO=$(echo "$INFO" | sed 's/[[:space:]]$//' | sed 's/[[:space:]]/+/g')
				echo_date "v2ray节点：【${v2ray_ps}】更新！原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "v2ray节点：【${v2ray_ps}】参数未发生变化，跳过！"
			fi
		fi
	fi
	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${v2ray_group} >> /tmp/sub_group_info.txt
}

get_vless_node(){
	local decode_link="$1"
	local action="$2"
	unset x_server_raw x_server x_server_port x_remarks x_uuid x_host x_path x_encryption x_type
	unset x_headerType x_headtype_tcp x_headtype_kcp x_headtype_quic x_grpc_modex_security_tmp x_security
	unset x_alpn x_alpn_h2_tmp x_alpn_http_tmp x_alpn_h2 x_alpn_http x_sni x_flow x_group x_group_hash x_kcp_seed

	x_server_raw=$(echo "${decode_link}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
	x_server=$(echo "${x_server_raw}" | awk -F':' '{print $1}')
	x_server_port=$(echo "${x_server_raw}" | awk -F':' '{print $2}')

	echo "${decode_link}"|grep -Eqo "#"
	if [ "$?" != "0" ];then
		x_remarks=${x_server}
	else
		x_remarks=$(echo "${decode_link}" | awk -F"#" '{print $NF}' | urldecode)
	fi
	
	x_uuid=$(echo "${decode_link}" | awk -F"@" '{print $1}')
	x_host=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "host" | awk -F"=" '{print $2}')
	x_path=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "path" | awk -F"=" '{print $2}' | urldecode)
	x_encryption=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "encryption" | awk -F"=" '{print $2}')
	if [ -z "{x_encryption}" ];then
		x_encryption="none"
	fi
	x_type=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "type" | grep -v "header" | awk -F"=" '{print $2}')
	if [ -z "${x_type}" ];then
		x_type="tcp"
	fi
	x_headerType=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "headerType" | awk -F"=" '{print $2}')
	case ${x_type} in
	tcp)
		# tcp协议设置【tcp伪装类型 (type)】
		x_headtype_tcp=${x_headerType}
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=""
		if [ -z "${x_headtype_tcp}" ];then
			x_headtype_tcp="none"
		fi
		;;
	kcp)
		# kcp协议设置【kcp伪装类型 (type)】
		x_headtype_tcp=""
		x_headtype_kcp=${x_headerType}
		x_headtype_quic=""
		x_grpc_mode=""
		if [ -z "${x_headtype_kcp}" ];then
			x_headtype_kcp="none"
		fi
		;;
	ws|h2)
		# ws/h2协议设置【伪装域名 (host))】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=""
		;;
	quic)
		# quic协议设置【quic伪装类型 (type)】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=${x_headerType}
		x_grpc_mode=""
		if [ -z "${x_headtype_quic}" ];then
			x_headtype_quic="none"
		fi
		;;
	grpc)
		# grpc协议设置【grpc模式】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=${x_headerType}
		if [ -z "${x_grpc_mode}" ];then
			x_grpc_mode="gun"
		fi
		;;
	esac

	# host is not needed in kcp and grpc
	if [ "${x_type}" == "kcp" -o "${x_type}" == "grpc" ];then 
		x_host=""
	fi

	if [ "${x_type}" == "kcp" ];then 
		x_kcp_seed=${x_path}
	fi

	# 底层传输安全：none, tls, xtls
	x_security_tmp=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "security" | awk -F"=" '{print $2}')
	if [ "${x_security_tmp}" == "tls" -o "${x_security_tmp}" == "xtls" ];then
		x_security="${x_security_tmp}"

		# alpn: h2; http/1.1; h2,http/1.1，此处在底层传输安全（network_security）为tls时使用
		x_alpn=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "alpn" | awk -F"=" '{print $2}' | urldecode)
		x_alpn_h2_tmp=$(echo "${x_alpn}" | grep "h2")
		x_alpn_http_tmp=$(echo "${x_alpn}" | grep "http/1.1")
		if [ -n "${x_alpn_h2_tmp}" ];then
			x_alpn_h2="1"
		else
			x_alpn_h2=""
		fi
		if [ -n "${x_alpn_http_tmp}" ];then
			x_alpn_http="1"
		else
			x_alpn_http=""
		fi

		# SNI, 如果空则用host替代，如果host空则空，此处在底层传输安全（network_security）为tls时使用
		x_sni=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "sni" | awk -F"=" '{print $2}')
		x_flow=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "flow" | awk -F"=" '{print $2}')
	else
		x_security="none"
		x_alpn_h2=""
		x_alpn_http=""
		x_sni=""
		x_flow=""
	fi
	
	[ -z "${x_encryption}" ] && x_encryption="none"

	if [ "${action}" == "1" ];then
		x_group=${DOMAIN_NAME}
		x_group_hash="${x_group}_${SUB_LINK_HASH:0:4}"
	fi
	if [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		x_group=""
		x_group_hash=""
	fi
	
	# # for debug, please keep it here
	# echo ------------
	# echo group: ${x_group}
	# echo remarks: ${x_remarks}
	# echo x_server_raw: ${x_server_raw}
	# echo server: ${x_server}
	# echo server_port: ${x_server_port}
	# echo uuid: ${x_uuid}
	# echo encryption: ${x_encryption}
	# echo type: ${x_type}
	# echo security: ${x_security}
	# echo host: ${x_host}
	# echo sni: ${x_sni}
	# echo path: ${x_path}
	# echo headerType: ${x_headerType}
	# echo x_headtype_tcp: ${x_headtype_tcp}
	# echo x_headtype_kcp: ${x_headtype_kcp}
	# echo x_headtype_quic: ${x_headtype_quic}
	# echo x_grpc_mode: ${x_grpc_mode}
	# echo flow: ${x_flow}
	# echo alpn: ${x_alpn}
	# echo ------------
	
	if [ "${action}" == "1" ];then
		if [ -n "${x_group}" -a -n "${x_server}" -a -n "${x_remarks}" -a -n "${x_server_port}" -a -n "${x_uuid}" -a -n "${x_encryption}" -a -n "${x_type}" ]; then
			server_base64=$(echo ${x_server} | base64_encode | sed 's/ -//g')
			group_base64=$(echo ${x_group_hash} | base64_encode | sed 's/ -//g')
			remark_base64=$(echo ${x_remarks} | base64_encode | sed 's/ -//g')
			echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/cur_subscservers.txt
		else
			return 1
		fi
	fi
	if [ "${action}" == "2" ];then
		if [ -n "${x_server}" -a -n "${x_remarks}" -a -n "${x_server_port}" -a -n "${x_uuid}" -a -n "${x_encryption}" -a -n "${x_type}" ]; then
			# 保留有效节点
			return 0
		else
			# 丢弃无效节点
			return 1
		fi
	fi
}

add_vless_node(){
	local flag="$1"
	if [ "${flag}" == "1" ]; then
		echo_date "xray节点：检测到一个错误节点，跳过！"
		exit 1
	fi
	let NODE_INDEX+=1
	echo_date "xray节点：新增加【${x_remarks}】到节点列表第 ${NODE_INDEX} 位。"
	dbus_eset ssconf_basic_type_${NODE_INDEX} "4"
	dbus_eset ssconf_basic_xray_use_json_${NODE_INDEX}
	dbus_eset ssconf_basic_mode_${NODE_INDEX} "${ssr_subscribe_mode}"
	dbus_eset ssconf_basic_name_${NODE_INDEX} "${x_remarks}"
	dbus_eset ssconf_basic_server_${NODE_INDEX} "${x_server}"
	dbus_eset ssconf_basic_port_${NODE_INDEX} "${x_server_port}"
	dbus_eset ssconf_basic_xray_uuid_${NODE_INDEX} "${x_uuid}"
	dbus_eset ssconf_basic_xray_encryption_${NODE_INDEX} "${x_encryption}"
	dbus_eset ssconf_basic_xray_network_${NODE_INDEX} "${x_type}"
	dbus_eset ssconf_basic_xray_headtype_tcp_${NODE_INDEX} "${x_headtype_tcp}"
	dbus_eset ssconf_basic_xray_headtype_kcp_${NODE_INDEX} "${x_headtype_kcp}"
	dbus_eset ssconf_basic_xray_headtype_quic_${NODE_INDEX} "${x_headtype_quic}"
	dbus_eset ssconf_basic_xray_grpc_mode_${NODE_INDEX} "${x_grpc_mode}"
	dbus_eset ssconf_basic_xray_network_host_${NODE_INDEX} "${x_host}"
	dbus_eset ssconf_basic_xray_network_path_${NODE_INDEX} "${x_path}"
	dbus_eset ssconf_basic_xray_kcp_seed_${NODE_INDEX} "${x_kcp_seed}"
	dbus_eset ssconf_basic_xray_network_security_${NODE_INDEX} "${x_security}"
	# 允许不安全，订阅中不提供此字段，默认不设置
	dbus_eset ssconf_basic_xray_network_security_ai_${NODE_INDEX}
	dbus_eset ssconf_basic_xray_network_security_alpn_h2_${NODE_INDEX} "${x_alpn_h2}"
	dbus_eset ssconf_basic_xray_network_security_alpn_http_${NODE_INDEX} "${x_alpn_http}"
	dbus_eset ssconf_basic_xray_network_security_sni_${NODE_INDEX} "${x_sni}"
	dbus_eset ssconf_basic_xray_flow_${NODE_INDEX} "${x_flow}"
	dbus_eset ssconf_basic_group_${NODE_INDEX} "${x_group_hash}"
	let addnum+=1
}

update_vless_node(){
	local FAILED_FLAG=$1
	local UPDATE_FLAG
	local DELETE_FLAG
	local SKIPDB_FLAG
	local INFO

	if [ "${FAILED_FLAG}" == "1" ]; then
		echo_date "xray订阅：检测到一个错误节点，跳过！"
		return 1
	fi

	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管

	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${x_remarks} ${x_server} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${x_remarks} ${x_server} | grep -Eo "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "xray节点：不添加【${x_remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "xray节点：不添加【${x_remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "xray节点：不添加【${x_remarks}】节点，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "xray节点：不添加【${x_remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "xray节点：不添加【${x_remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	else
		local UPDATE_FLAG=0
	fi

	# ------------------------------- 节点添加/修改逻辑 -------------------------------
	local isadded_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_vless_node
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点名以外的参数，如节点域名！通过节点名称获取index
		local index_line_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_vless_node
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点地址以外的参数，如名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_vless_node
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
		local KEY_LOCAL_NAME=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "xray节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
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
				if [ -n "$(dbus get ${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			dbus_cset "ssconf_basic_group_${index}" "${x_group_hash}"
			[ "$?" == "1" ] && INFO="${INFO}分组信息 "
				
			dbus_cset "ssconf_basic_mode_${index}" "${ssr_subscribe_mode}"
			[ "$?" == "1" ] && INFO="${INFO}模式 "
			
			if [ "${SKIPDB_FLAG}" == "2" ];then
				dbus_cset "ssconf_basic_name_${index}" "${x_remarks}"
				[ "$?" == "1" ] && INFO="${INFO}节点名 "
			fi
			
			if [ "${SKIPDB_FLAG}" == "1" ];then
				dbus_cset "ssconf_basic_server_${index}" "${x_server}"
				[ "$?" == "1" ] && INFO="${INFO}节点地址 "
			fi
			
			dbus_cset "ssconf_basic_port_${index}" "${x_server_port}"
			[ "$?" == "1" ] && INFO="${INFO}端口 "
			
			dbus_cset "ssconf_basic_xray_uuid_${index}" "${x_uuid}"
			[ "$?" == "1" ] && INFO="${INFO}用户id "

			dbus_cset "ssconf_basic_xray_encryption_${index}" "${x_encryption}"
			[ "$?" == "1" ] && INFO="${INFO}加密 "	
			
			dbus_cset "ssconf_basic_xray_network_${index}" "${x_type}"
			[ "$?" == "1" ] && INFO="${INFO}传输协议 "
			
			dbus_cset "ssconf_basic_xray_headtype_tcp_${index}" "${x_headtype_tcp}"
			[ "$?" == "1" ] && INFO="${INFO}伪装类型 "
			
			dbus_cset "ssconf_basic_xray_network_host_${index}" "${x_host}"
			[ "$?" == "1" ] && INFO="${INFO}伪装域名 "
			
			dbus_cset "ssconf_basic_xray_network_path_${index}" "${x_path}"
			[ "$?" == "1" ] && INFO="${INFO}路径 "

			dbus_cset "ssconf_basic_xray_kcp_seed_${index}" "${x_kcp_seed}"
			[ "$?" == "1" ] && INFO="${INFO}路径 "

			dbus_cset "ssconf_basic_xray_network_security_${index}" "${x_security}"
			[ "$?" == "1" ] && INFO="${INFO}底层传输安全 "

			#dbus_cset "ssconf_basic_xray_network_security_ai_${index}" "${x_ai}"
			#[ "$?" == "1" ] && INFO="${INFO}证书验证 "

			dbus_cset "ssconf_basic_xray_network_security_alpn_h2_${index}" "${x_alpn_h2}"
			[ "$?" == "1" ] && INFO="alpn:h2 "

			dbus_cset "ssconf_basic_xray_network_security_alpn_ht_${index}" "${x_alpn_http}"
			[ "$?" == "1" ] && INFO="alpn:http/1.1 "

			dbus_cset "ssconf_basic_xray_network_security_sni_${index}" "${x_sni}"
			[ "$?" == "1" ] && INFO="${INFO}证书验证 "

			if [ -n "${INFO}" ]; then
				INFO=$(echo "${INFO}" | sed 's/[[:space:]]$//' | sed 's/[[:space:]]/ + /g')
				echo_date "xray节点：【${x_remarks}】更新！原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "xray节点：【${x_remarks}】参数未发生变化，跳过！"
			fi
		fi
	fi
	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${x_group} >> /tmp/sub_group_info.txt
}

get_trojan_node(){
	local decode_link="$1"
	local action="$2"
	unset t_server t_server_port t_remarks t_uuid t_ai t_tfo t_sni_tmp t_peer_tmp t_sni t_group t_group_hash
	
	t_server=$(echo "${decode_link}" | sed 's/@/ /g;s/:/ /g;s/?/ /g;s/#/ /g' | awk '{print $2}')
	t_server_port=$(echo "${decode_link}" | sed 's/@/ /g;s/:/ /g;s/?/ /g;s/#/ /g' | awk '{print $3}')

	echo "${decode_link}" | grep -Eqo "#"
	if [ "$?" != "0" ];then
		t_remarks=${t_server}
	else
		t_remarks=$(echo "${decode_link}" | awk -F"#" '{print $NF}' | urldecode)
	fi

	t_uuid=$(echo "${decode_link}" | awk -F"@" '{print $1}')
	t_ai=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "allowInsecure" | awk -F"=" '{print $2}')
	t_tfo=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "tfo" | awk -F"=" '{print $2}')
	t_sni_tmp=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "sni" | awk -F"=" '{print $2}')
	t_peer_tmp=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "peer" | awk -F"=" '{print $2}')
	if [ -n "${t_sni_tmp}" ];then
		t_sni=${t_sni_tmp}
	else
		if [ -n "${t_peer_tmp}" ];then
			t_sni=${t_peer_tmp}
		fi
	fi

	if [ "${action}" == "1" ];then
		t_group=${DOMAIN_NAME}
		t_group_hash="${t_group}_${SUB_LINK_HASH:0:4}"
	fi
	if [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		t_group=""
		t_group_hash=""
	fi
	
	# for debug, please keep it here
	# echo ------------
	# echo group: ${t_group}
	# echo remarks: ${t_remarks}
	# echo server: ${t_server}
	# echo port: ${t_server_port}
	# echo password: ${t_uuid}
	# echo allowInsecure: ${t_ai}
	# echo SNI: ${t_sni}
	# echo TFO: ${t_tfo}
	# echo ------------	

	if [ "${action}" == "1" ];then
		if [ -n "${t_group}" -a -n "${t_server}" -a -n "${t_remarks}" -a -n "${t_server_port}" -a -n "${t_uuid}" ]; then
			server_base64=$(echo ${t_server} | base64_encode | sed 's/ -//g')
			group_base64=$(echo ${t_group_hash} | base64_encode | sed 's/ -//g')
			remark_base64=$(echo ${t_remarks} | base64_encode | sed 's/ -//g')
			echo ${server_base64} ${group_base64} ${remark_base64} >> /tmp/cur_subscservers.txt
		else
			return 1
		fi
	fi
	if [ "${action}" == "2" ];then
		if [ -n "${t_server}" -a -n "${t_remarks}" -a -n "${t_server_port}" -a -n "${t_uuid}" ]; then
			# 保留有效节点
			return 0
		else
			# 丢弃无效节点
			return 1
		fi
	fi
}

add_trojan_node(){
	local flag="$1"
	if [ "${flag}" == "1" ]; then
		echo_date "trojan节点：检测到一个错误节点，跳过！"
		exit 1
	fi
	let NODE_INDEX+=1
	echo_date "trojan节点：新增加【${t_remarks}】到节点列表第 ${NODE_INDEX} 位。"
	dbus_eset ssconf_basic_type_${NODE_INDEX} "5"
	dbus_eset ssconf_basic_mode_${NODE_INDEX} "${ssr_subscribe_mode}"
	dbus_eset ssconf_basic_name_${NODE_INDEX} "${t_remarks}"
	dbus_eset ssconf_basic_server_${NODE_INDEX} "${t_server}"
	dbus_eset ssconf_basic_port_${NODE_INDEX} "${t_server_port}"
	dbus_eset ssconf_basic_trojan_uuid_${NODE_INDEX} "${t_uuid}"
	dbus_eset ssconf_basic_trojan_ai_${NODE_INDEX} "${t_ai}"
	dbus_eset ssconf_basic_trojan_sni_${NODE_INDEX} "${t_sni}"
	dbus_eset ssconf_basic_trojan_tfo_${NODE_INDEX} "${t_tfo}"
	dbus_eset ssconf_basic_group_${NODE_INDEX} "${t_group_hash}"
	let addnum+=1
}


update_trojan_node(){
	local FAILED_FLAG=$1
	local UPDATE_FLAG
	local DELETE_FLAG
	local SKIPDB_FLAG
	local INFO

	if [ "${FAILED_FLAG}" == "1" ]; then
		echo_date "xray订阅：检测到一个错误节点，跳过！"
		return 1
	fi

	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管

	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${t_remarks} ${t_server} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${t_remarks} ${t_server} | grep -Eo "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "trojan节点：不添加【${t_remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "trojan节点：不添加【${t_remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "trojan节点：不添加【${t_remarks}】节点，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "trojan节点：不添加【${t_remarks}】节点，因为匹配了[排除]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "trojan节点：不添加【${t_remarks}】节点，因为不匹配[包括]关键词"
			let exclude+=1 
			local UPDATE_FLAG=2
		else
			local UPDATE_FLAG=0
		fi
	else
		local UPDATE_FLAG=0
	fi

	# ------------------------------- 节点添加/修改逻辑 -------------------------------
	local isadded_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $1}' | grep -wc ${server_base64} | head -n1)
	local isadded_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | awk '{print $3}' | grep -wc ${remark_base64} | head -n1)
	if [ "${isadded_server}" == "0" -a "${isadded_remark}" == "0" ]; then
		#地址匹配：no，名称匹配：no；说明是本地没有的新节点，添加它！
		if [ "${UPDATE_FLAG}" == "0" ]; then
			add_trojan_node
		fi
	elif [ "${isadded_server}" == "0" -a "${isadded_remark}" != "0" ]; then
		#地址匹配：no，名称匹配：yes；说明可能是机场更改了节点名以外的参数，如节点域名！通过节点名称获取index
		local index_line_remark=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_remark}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}')
			local SKIPDB_FLAG=1
		else
			# 如果有些机场有名称重复的节点（垃圾机场！），把同名节点序号写进文件-1后依次去取节点号
			local tmp_file=$(echo ${remark_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_remark_${tmp_file}.txt ]; then
				# 节点名称的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（节点名称相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${remark_base64} | awk '{print $4}' > /tmp/multi_remark_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_remark_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同名称节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_trojan_node
				fi
			else
				# add SKIPDB_FLAG
				local SKIPDB_FLAG=1
				local index=$(cat /tmp/multi_remark_${tmp_file}.txt | sed -n '1p')
				sed -i '1d' /tmp/multi_remark_${tmp_file}.txt
			fi
		fi
	else
		# 地址匹配：yes，名称匹配：yes/no；说明可能是机场更改了节点地址以外的参数，如名字或其它参数，通过节点名称获取index
		local index_line_server=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' | wc -l)
		if [ "${index_line_server}" == "1" ]; then
			local index=$(cat /tmp/cur_localservers.txt| grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}')
			local SKIPDB_FLAG=2
		else
			# 如果有些机场有域名重复的节点，如一些用于流量提示和过期日期提醒的假节点，把同名节点序号写进文件-2后依次去取节点号
			local tmp_file=$(echo ${server_base64} | sed 's/\=//g')
			if [ ! -f /tmp/multi_server_${tmp_file}.txt ]; then
				# 节点的base64值，去掉"="后，作为文件名写入/tmp，后面遇到该节点（server值相同的节点）就能从里面取值啦
				cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${server_base64} | awk '{print $4}' > /tmp/multi_server_${tmp_file}.txt
			fi
			
			if [ "$(cat /tmp/multi_server_${tmp_file}.txt | wc -l)" == "0" ]; then
				# 取值已经拿完了，不能删除该文件，但是还有新的同server节点出现，那么就直接添加该节点
				if [ "${UPDATE_FLAG}" == "0" ]; then
					add_trojan_node
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
		local KEY_LOCAL_NAME=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $3}' | base64 -d)
		local KEY_LOCAL_SERVER=$(cat /tmp/cur_localservers.txt | grep ${group_base64} | grep -w ${index} | awk '{print $1}'| base64 -d)

		[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_3=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_1}")
		[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_4=$(echo ${KEY_LOCAL_NAME} ${KEY_LOCAL_SERVER} | grep -Eo "${KEY_WORDS_2}")

		if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" ]; then
				echo_date "trojan节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -z "${KEY_MATCH_4}" ]; then
				echo_date "trojan节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
				local DELETE_FLAG=1
			else
				local DELETE_FLAG=0
			fi
		elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
			if [ -n "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "trojan节点：移除本地【${x_remarks}】节点，因为匹配了[排除+包括]关键词"
				local DELETE_FLAG=1
			elif [ -n "${KEY_MATCH_3}" -a -n "${KEY_MATCH_4}" ]; then
				echo_date "trojan节点：移除本地【${x_remarks}】节点，因为匹配了[排除]关键词"
				local DELETE_FLAG=1
			elif  [ -z "${KEY_MATCH_3}" -a -z "${KEY_MATCH_4}" ]; then
				echo_date "trojan节点：移除本地【${x_remarks}】节点，因为不匹配[包括]关键词"
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
				if [ -n "$(dbus get ${item}${index})" ]; then
					dbus remove ${item}${index}
				fi
			done
			let delnum+=1
		else
			dbus_cset "ssconf_basic_group_${index}" "${t_group_hash}"
			[ "$?" == "1" ] && INFO="${INFO}分组信息 "
				
			dbus_cset "ssconf_basic_mode_${index}" "${ssr_subscribe_mode}"
			[ "$?" == "1" ] && INFO="${INFO}模式 "
			
			if [ "${SKIPDB_FLAG}" == "2" ];then
				dbus_cset "ssconf_basic_name_${index}" "${t_remarks}"
				[ "$?" == "1" ] && INFO="${INFO}节点名 "
			fi
			
			if [ "${SKIPDB_FLAG}" == "1" ];then
				dbus_cset "ssconf_basic_server_${index}" "${t_server}"
				[ "$?" == "1" ] && INFO="${INFO}节点地址 "
			fi
			
			dbus_cset "ssconf_basic_port_${index}" "${t_server_port}"
			[ "$?" == "1" ] && INFO="${INFO}端口 "
			
			dbus_cset "ssconf_basic_trojan_uuid_${index}" "${t_uuid}"
			[ "$?" == "1" ] && INFO="${INFO}密码 "

			dbus_cset "ssconf_basic_trojan_ai_${index}" "${t_ai}"
			[ "$?" == "1" ] && INFO="${INFO}证书验证 "

			dbus_cset "ssconf_basic_trojan_sni_${index}" "${t_sni}"
			[ "$?" == "1" ] && INFO="${INFO}SNI "

			dbus_cset "ssconf_basic_trojan_tfo_${index}" "${t_tfo}"
			[ "$?" == "1" ] && INFO="${INFO}tfo "

			if [ -n "${INFO}" ]; then
				INFO=$(echo "${INFO}" | sed 's/[[:space:]]$//' | sed 's/[[:space:]]/ + /g')
				echo_date "trojan节点：【${t_remarks}】更新！原因：节点的【${INFO}】发生了更改！"
				let updatenum+=1
			else
				echo_date "trojan节点：【${t_remarks}】参数未发生变化，跳过！"
			fi
		fi
	fi
	# 添加/更改完成一个节点后，将该节点的group信息写入到文件备用
	echo ${t_group} >> /tmp/sub_group_info.txt
	
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
	
	echo_date "检查本地节点排序情况..."
	echo_date "最大节点序号：${MAX}"
	echo_date "共有节点数量：${NODES_NU}"
	if [ "${MAX}" != "${NODES_NU}" ]; then
		echo_date "节点排序需要调整!"
		local y=1
		for nu in ${SEQ}
		do
			if [ "${y}" == "${nu}" ]; then
				echo_date "节点$y不需要调整！"
			else
				echo_date "调整节点${nu}到节点${y}！"
				for item in ${PREFIX}
				do
					#dbus remove ${item}${conf_nu}
					if [ -n "$(dbus get ${item}${nu})" ]; then
						dbus set ${item}${y}="$(dbus get ${item}${nu})"
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
		sync
		source /koolshare/scripts/ss_base.sh
		NODES_SEQ=$(dbus list ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
		NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
	else
		echo_date "节点排序正确!"
	fi
}

get_fancyss_running_status(){
	local STATUS_1=$(dbus get ss_basic_enable 2>/dev/null)
	local STATUS_2=$(iptables --t nat -S|grep SHADOWSOCKS|grep -w "3333" 2>/dev/null)
	local STATUS_3=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -E "ss-redir|sslocal|v2ray|koolgame|xray")
	local STATUS_4=$(netstat -nlp 2>/dev/null|grep -w "7913")
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
	wget -4 -t 1 -T 10 --dns-timeout=5 -q ${EXT_OPT} "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	sleep 1

	echo_date "使用wget下载订阅，第二次尝试下载..."
	wget -4 -t 1 -T 15 --dns-timeout=10 -q ${EXT_OPT} "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi	
	
	sleep 2

	echo_date "使用wget下载订阅，第三次尝试下载..."
	wget -4 -t 1 -T 20 --dns-timeout=15 -q ${EXT_OPT} "$1" -O /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ]; then
		return 0
	fi

	return 1
}

download_by_aria2(){
	echo_date "使用aria2c下载订阅..."
	rm -rf /tmp/ssr_subscribe_file.txt
	/koolshare/aria2/aria2c --check-certificate=false --quiet=true -d /tmp -o ssr_subscribe_file.txt $1
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

	# 3 generate sublink hash for each sub link
	local SUB_LINK_HASH=$(echo "${SUB_LINK}" | md5sum | awk '{print $1}')
	if [ -f "/tmp/fancyss_sublinks.txt" ];then
		local IS_ADD=$(cat /tmp/fancyss_sublinks.txt | grep -Eo ${SUB_LINK_HASH})
		if [ -n "${IS_ADD}" ];then
			echo_date "检测到重复的订阅链接！不订阅该链接！请检查你的订阅地址栏填写情况！"
			return 6
		fi
	fi
	echo ${SUB_LINK_HASH} >>/tmp/fancyss_sublinks.txt

	# 4. try to delete some file left by last sublink subscribe
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	rm -rf /tmp/sub_group_info.txt
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	rm -rf /tmp/cur_localservers.txt
	rm -rf /tmp/cur_subscservers.txt

	# 5. generate all node info for this sub link: use to campare
	local cur_nodes_indexs=$(dbus list ssconf_basic_group_  | awk -F"_|=" '{print $4"|"$NF}'| grep -w "${SUB_LINK_HASH:0:4}" | awk -F"|" '{print $1}' | sort -n)
	if [ -n "${cur_nodes_indexs}" ]; then
		for cur_nodes_index in ${cur_nodes_indexs}
		do
			# server SUB_LINK_HASH remark node_nu
			echo \
			$(dbus get ssconf_basic_server_${cur_nodes_index} | base64_encode) \
			$(dbus get ssconf_basic_group_${cur_nodes_index} | base64_encode) \
			$(dbus get ssconf_basic_name_${cur_nodes_index} | base64_encode) \
			${cur_nodes_index} \
			>> /tmp/cur_localservers.txt
		done
	else
		touch /tmp/cur_localservers.txt
	fi

	# 6. subscribe go through proxy or not
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
	
	# 7. download sublink
	download_by_curl "${SUB_LINK}"
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
			echo_date "更换wget下载订阅失败！"
			if [ -x "/koolshare/aria2/aria2c" ];then
				download_by_aria2 "${SUB_LINK}"
			fi
			if [ "$?" != "0" ]; then
				echo_date "使用aria2c下载订阅失败..."
				return 1
			fi
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
		if [ -x "/koolshare/aria2/aria2c" ];then
			download_by_aria2
		fi
	fi
	
	if [ "$?" != "0" ]; then
		return 1
	fi
	
	echo_date "下载订阅成功..."
	echo_date "开始解析节点信息..."

	# 8. 解析订阅原始文本
	decode_url_link $(cat /tmp/ssr_subscribe_file.txt) flag > /tmp/ssr_subscribe_file_temp.txt
	if [ "$?" == "1" ]; then
		echo_date "解析错误！原因：解析后检测到乱码！请检查你的订阅地址！"
	fi

	# 9. 一些机场使用的换行符是dos格式（\r\n\)，在路由Linux下会出问题！转换成unix格式
	if [ -n "$(which dos2unix)" ];then
		dos2unix -u /tmp/ssr_subscribe_file_temp.txt
	else
		tr -d '\r' < /tmp/ssr_subscribe_file_temp.txt > /tmp/ssr_subscribe_file_temp_0.txt
		mv /tmp/ssr_subscribe_file_temp_0.txt /tmp/ssr_subscribe_file_temp.txt
	fi
	echo "" >> /tmp/ssr_subscribe_file_temp.txt
	local NODE_NU_RAW=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -c "://")
	echo_date "初步解析成功！共获得${NODE_NU_RAW}个节点！"

	# 10. 如果机场订阅解析后有MAX=xx字段存在，那么随机选取xx个节点
	maxnum=$(cat /tmp/ssr_subscribe_file_temp.txt | grep "MAX=" | awk -F"=" '{print $2}' | grep -Eo "[0-9]+")
	if [ -n "${maxnum}" ]; then
		echo_date "根据机场要求，从${NODE_NU_RAW}个节点中，随机选取${maxnum}个用于订阅！"
		cat /tmp/ssr_subscribe_file_temp.txt | sed '/MAX=/d' | shuf -n ${maxnum} > /tmp/ssr_subscribe_file_temp_1.txt
		mv /tmp/ssr_subscribe_file_temp_1.txt /tmp/ssr_subscribe_file_temp.txt
	fi
	
	# 11. 检测 ss ssr vmess
	NODE_FORMAT1=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^ss://")
	NODE_FORMAT2=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^ssr://")
	NODE_FORMAT3=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^vmess://")
	NODE_FORMAT4=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^vless://")
	NODE_FORMAT5=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -E "^trojan://")
	if [ -z "${NODE_FORMAT1}" -a -z "${NODE_FORMAT2}" -a -z "${NODE_FORMAT3}" -a -z "${NODE_FORMAT4}" -a -z "${NODE_FORMAT5}" ];then
		echo_date "订阅中不包含任何ss/ssr/vmess/vless/trojan节点，退出！"
		return 1
	fi
	
	local NODE_NU_SS=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^ss://") || "0"
	local NODE_NU_SR=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^ssr://") || "0"
	local NODE_NU_VM=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^vmess://") || "0"
	local NODE_NU_VL=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^vless://") || "0"
	local NODE_NU_TJ=$(cat /tmp/ssr_subscribe_file_temp.txt | grep -Ec "^trojan://") || "0"
	local NODE_NU_TT=$((${NODE_NU_SS} + ${NODE_NU_SR} + ${NODE_NU_VM} + ${NODE_NU_VL}))
	if [ "${NODE_NU_TT}" -lt "${NODE_NU_RAW}" ];then
		echo_date "${NODE_NU_RAW}个节点中，一共检测到${NODE_NU_TT}个支持节点！"
	fi
	echo_date "具体情况如下："
	[ "${NODE_NU_SS}" -gt "0" ] && echo_date "ss节点：${NODE_NU_SS}个"
	[ "${NODE_NU_SR}" -gt "0" ] && echo_date "ssr节点：${NODE_NU_SR}个"
	[ "${NODE_NU_VM}" -gt "0" ] && echo_date "vmess节点：${NODE_NU_VM}个"
	[ "${NODE_NU_VL}" -gt "0" ] && echo_date "vless节点：${NODE_NU_VL}个"
	[ "${NODE_NU_TJ}" -gt "0" ] && echo_date "trojan节点：${NODE_NU_TJ}个"
	echo_date "-------------------------------------------------------------------"

	# 12. 开始解析并写入节点
	while read node; do
		local node_type_ss=$(echo ${node} | grep -E "^ss://")
		local node_type_sr=$(echo ${node} | grep -E "^ssr://")
		local node_type_vm=$(echo ${node} | grep -E "^vmess://")
		local node_type_vl=$(echo ${node} | grep -E "^vless://")
		local node_type_tj=$(echo ${node} | grep -E "^trojan://")
		# ss online
		if [ -n "${node_type_ss}" ];then
			local urllink=$(echo "${node}" | sed 's/ss:\/\///g' )
			get_ss_node ${urllink} 1
			update_ss_node $?
		fi
		# ssr online
		if [ -n "${node_type_sr}" ];then
			local urllink=$(echo ${node} | sed 's/ssr:\/\///g')
			get_ssr_node ${urllink} 1
			update_ssr_node $?
		fi
		# vmess online
		if [ -n "${node_type_vm}" ];then
			local urllink=$(echo ${node} | sed 's/vmess:\/\///g')
			get_vmess_node ${urllink} 1
			update_vmess_node $?
		fi
		# vless online
		if [ -n "${node_type_vl}" ];then
			local urllink=$(echo "${node}" | sed 's/vless:\/\///g' )
			get_vless_node ${urllink} 1
			update_vless_node $?
		fi
		# trojan
		if [ -n "${node_type_tj}" ];then
			local urllink=$(echo "${node}" | sed 's/trojan:\/\///g' )
			get_trojan_node ${urllink} 1
			update_trojan_node $?
		fi
	done < /tmp/ssr_subscribe_file_temp.txt

	# 13. 如果订阅链接并未移除，但是一些节点机场删除了，那么本地也要进行删除
	# 通过本地节点和订阅节点对比，找出本地独有的节点[域名]对应的节点索引
	local DIFF_SERVERS=$(awk 'NR==FNR{a[$1]=$1} NR>FNR{if(a[$1] == ""){print $4}}' /tmp/cur_subscservers.txt /tmp/cur_localservers.txt | sed '/^$/d')
	# 通过本地节点和订阅节点对比，找出本地独有的节点[名称]对应的节点索引
	local DIFF_REMARKS=$(awk 'NR==FNR{a[$3]=$3} NR>FNR{if(a[$3] == ""){print $4}}' /tmp/cur_subscservers.txt /tmp/cur_localservers.txt | sed '/^$/d')
	# 获取两者都有的节点索引，即为需要删除的节点
	local DEL_INDEXS=$(echo ${DIFF_SERVERS} ${DIFF_REMARKS} | sed 's/[[:space:]]/\n/g' | sort | uniq -d)
	# 删除操作
	if [ -n "${DEL_INDEXS}" ];then
		#echo_date "-------------------------------------------------------------------"
		for DEL_INDEX in ${DEL_INDEXS}; do
			echo_date "删除【$(dbus get ssconf_basic_name_${DEL_INDEX})】，因为该节点在订阅服务器上已经不存在..."
			for item in ${PREFIX}; do
				if [ -n "$(dbus get ${item}${DEL_INDEX})" ];then
					dbus remove ${item}${DEL_INDEX}
				fi
			done
			let delnum+=1
		done
	fi
	
	# 13. 储存对应订阅链接的group信息，一个机场的节点可能有多个group
	local final_group=$(cat /tmp/sub_group_info.txt | sort -u | sed 's/$/ + /g' | sed ':a;N;$!ba;s#\n##g' | sed 's/ + $//g')
	if [ -n "${final_group}" ]; then
		dbus set ss_online_group_${sub_count}=${final_group}_${SUB_LINK_HASH:0:4}
	else
		# 如果机场没有定义group，则用其订阅域名写入即可
		final_group=${DOMAIN_NAME}_${SUB_LINK_HASH:0:4}
		dbus set ss_online_group_${sub_count}=${final_group}
	fi
	dbus set ss_online_hash_${sub_count}=${SUB_LINK_HASH}

	# 14. print INFO
	USER_ADD=$(($(dbus list ssconf_basic_ | grep _name_ | wc -l) - $(dbus list ssconf_basic_ | grep _group_ | wc -l))) || "0"
	ONLINE_GET=$(dbus list ssconf_basic_ | grep _group_ | wc -l) || "0"
	echo_date "-------------------------------------------------------------------"
	echo_date "本次更新订阅来源【${final_group%_*}】，共有节点${NODE_NU_TT}个，其中："
	echo_date "因关键词排除节点${exclude}个，新增节点${addnum}个，修改${updatenum}个，删除${delnum}个；"
	echo_date "现共有自添加SSR节点：${USER_ADD} 个；"
	echo_date "现共有订阅节点：${ONLINE_GET} 个；"
	echo_date "在线订阅列表更新完成!"
}

start_online_update(){
	echo_date "==================================================================="
	echo_date "                服务器订阅程序(Shell by stones & sadog)"
	echo_date "==================================================================="
	echo_date "开始订阅！"
	FAST=$1
	prepare

	# detect input
	if [ "${SEQ_NU}" == "0" -a -z "$(dbus get ss_online_links)" ];then
		echo_date "订阅地址输入框为空，请输入订阅链接后重试！"
		exit 1
	fi
	local online_url_nu=$(dbus get ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | wc -l)
	if [ "${SEQ_NU}" == "0" -a "${online_url_nu}" == "0" ];then
		echo_date "未发现任何有效的订阅地址，请检查你的订阅链接！"
		exit 1
	fi
	
	# 2.清理上次订阅可能遗留的文件
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	rm -rf /tmp/cur_localservers.txt >/dev/null 2>&1
	rm -rf /tmp/cur_subscservers.txt >/dev/null 2>&1
	rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	rm -rf /tmp/fancyss_sublinks.txt
	rm -rf /tmp/online_url_md5.txt

	# 3. before subscribe online node, we need to detect if any sublink deleted
	# 将每个订阅链接生成hash并储存在文件里
	local online_sub_urls=$(dbus get ss_online_links | base64_decode | awk '{print $1}' | sed '/^$/d' | sed '/^#/d' | grep -E "^http")
	for online_sub_url in ${online_sub_urls}
	do
		local online_url_md5=$(echo ${online_sub_url} | md5sum | awk '{print $1}')
		echo ${online_url_md5} >> /tmp/online_url_md5.txt
	done
	# 4. 将本地储存的hash与每个订阅链接的hash对比，如果本地hash对比不上，则删除节点
	local local_url_nu_hashs=$(dbus list ss | grep ss_online_hash | awk -F"_|=" '{print $4"_"$NF}')
	if [ -n "${local_url_nu_hashs}" ];then
		for local_url_nu_hash in ${local_url_nu_hashs}
		do
			local local_url_nu=${local_url_nu_hash%_*}
			local local_url_ha=${local_url_nu_hash#*_}
			local match_hash=$(cat /tmp/online_url_md5.txt | grep -Eo "${local_url_ha}")
			local current_group=$(dbus get ss_online_group_${local_url_nu})
			local current_group=${current_group%_*}
			if [ -n "${match_hash}" ];then
				echo_date "检测到【${current_group}】上次已经订阅，继续检测更新!"
				local IS_SERVER=$(dbus list ssconf_basic_ | grep "${local_url_ha:0:4}")
				if [ -z "${IS_SERVER}" ];then
					echo_date "检测到【${current_group}】订阅在本地没有任何节点！可能是上次订阅失败造成的，继续！"
				fi
			else
				# remove node
				echo_date "检测到【${current_group}】机场已经不再订阅！尝试删除该订阅的节点！"
				local del_nus=$(dbus list "ssconf_basic_group_" | awk -F"_|=" '{print $4"|"$NF}'| grep "${local_url_ha:0:4}" | awk -F"|" '{print $1}' | sort -n)
				for del_nu in ${del_nus}; do
					echo_date "移除节点：【$(dbus get ssconf_basic_name_${del_nu})】!"
					for item in ${PREFIX}
					do
						if [ -n "$(dbus get ${item}${del_nu})" ]; then
							dbus remove ${item}${del_nu}
						fi
					done
					sync
				done

				# remove group info
				# remove_node_info

				# make order right
				remove_node_gap
			fi
		done
	else
		echo_date "检测到旧版本插件的订阅！先移除所有本地订阅节点，重新订阅！"
		remove_sub_node
		sync
		source /koolshare/scripts/ss_base.sh
		NODES_SEQ=$(dbus list ssconf_basic_ | grep _name_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -n)
		NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
		echo_date "重新开始订阅！"
	fi

	#remove_node_info

	# 4. 下载/解析订阅节点
	local sub_count=0
	online_url_nu=$(dbus get ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | wc -l)
	until [ "${sub_count}" == "${online_url_nu}" ]; do
		let sub_count+=1
		url=$(dbus get ss_online_links | base64_decode | awk '{print $1}' | sed '/^$/d' | sed '/^#/d' | grep -E "^http" | sed -n "$sub_count p")
		[ -z "${url}" ] && continue
		echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
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
			echo_date "退出订阅程序..."
			;;
		3)
			echo_date "该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			echo_date "退出订阅程序..."
			;;
		4|5)
			echo_date "订阅地址错误！检测到你输入的订阅地址并不是标准网址格式！"
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			echo_date "退出订阅程序..."
			;;
		1)
			echo_date "下载订阅失败，请检查你的网络..."
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			echo_date "退出订阅程序..."
			;;
		*)
			rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
			echo_date "退出订阅程序..."
			;;
		esac
	done
	echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
	
	# 5. 节点重新排序
	remove_node_gap

	# 结束
	echo_date "-------------------------------------------------------------------"
	echo_date "一点点清理工作..."
	#rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	#rm -rf /tmp/cur_localservers.txt >/dev/null 2>&1
	#rm -rf /tmp/cur_subscservers.txt >/dev/null 2>&1
	#rm -rf /tmp/sub_group_info.txt >/dev/null 2>&1
	#rm -rf /tmp/multi_*.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
}

# 添加ss:// ssr:// vmess:// vless://离线节点
start_offline_update() {
	echo_date "==================================================================="
	usleep 100000
	echo_date "通过ss/ssr/vmess/vless链接添加节点..."
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/cur_localservers.txt >/dev/null 2>&1
	rm -rf /tmp/cur_subscservers.txt >/dev/null 2>&1
	local nodes=$(echo ${ss_base64_links} | base64 -d | urldecode)
	for node in $nodes
	do
		local node_type_ss=$(echo ${node} | grep -E "^ss://")
		local node_type_sr=$(echo ${node} | grep -E "^ssr://")
		local node_type_vm=$(echo ${node} | grep -E "^vmess://")
		local node_type_vl=$(echo ${node} | grep -E "^vless://")
		local node_type_tj=$(echo ${node} | grep -E "^trojan://")
		# ss offline
		if [ -n "${node_type_ss}" ];then
			local urllink=$(echo "${node}" | sed 's/ss:\/\///g' )
			get_ss_node "${urllink}" 2
			add_ss_node $?
		fi
		# ssr offline
		if [ -n "${node_type_sr}" ];then
			local urllink=$(echo "${node}" | sed 's/ssr:\/\///g' )
			get_ssr_node ${urllink} 2
			add_ssr_node $?
		fi
		# vmess offline
		if [ -n "${node_type_vm}" ];then
			local urllink=$(echo "${node}" | sed 's/vmess:\/\///g' )
			get_vmess_node ${urllink} 2
			add_vmess_node $?
		fi
		# vless offline
		if [ -n "${node_type_vl}" ];then
			local urllink=$(echo "${node}" | sed 's/vless:\/\///g' )
			echo_date "检测到vless链接...开始尝试解析..."
			get_vless_node ${urllink} 2
			add_vless_node $?
		fi
		# trojan offline
		if [ -n "${node_type_tj}" ];then
			local urllink=$(echo "${node}" | sed 's/trojan:\/\///g' )
			echo_date "检测到trojan链接...开始尝试解析..."
			get_trojan_node ${urllink} 2
			add_trojan_node $?
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
	local_groups=$(dbus list ssconf_basic_ | grep _group_ | cut -d "=" -f2 | sort -u | wc -l)
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
	# 使用订阅链接订阅ss/ssr/V2ray节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
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
	# 使用订阅链接订阅ss/ssr/V2ray节点
	set_lock
	true > $LOG_FILE
	http_response "$1"
	echo_date "开始快速订阅" | tee -a $LOG_FILE
	start_online_update 1 | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
esac
