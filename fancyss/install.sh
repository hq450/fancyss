#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=
FW_TYPE_NAME=
DIR=$(cd $(dirname $0); pwd)
module=${DIR##*/}
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')

run_bg(){
	env -i PATH=${PATH} "$@" >/dev/null 2>&1 &
}

get_model(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		MODEL="${ODMPID}"
	else
		MODEL="${PRODUCTID}"
	fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno|grep -E "_kool")
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			FW_TYPE_NAME="koolshare官改固件"
		else
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			FW_TYPE_NAME="梅林原版固件"
		else
			FW_TYPE_NAME="华硕官方固件"
		fi
	fi
}

platform_test(){
	# 带koolshare文件夹，有httpdb和skipdb的固件位支持固件
	if [ -d "/koolshare" -a -x "/koolshare/bin/httpdb" -a -x "/usr/bin/skipd" ];then
		echo_date "机型：${MODEL} ${FW_TYPE_NAME} 符合安装要求，开始安装插件！"
	else
		exit_install 1
	fi

	# 继续判断各个固件的内核和架构
	local PKG_ARCH=$(cat ${DIR}/.valid)
	local ROT_ARCH=$(uname -m)
	local KEL_VERS=$(uname -r)
	#local PKG_NAME=$(cat /tmp/shadowsocks/webs/Module_shadowsocks.asp | grep -Eo "pkg_name=.+"|grep -Eo "fancyss\w+")
	#local PKG_ARCH=$(echo ${pkg_name} | awk -F"_" '{print $2}')
	#local PKG_TYPE=$(echo ${pkg_name} | awk -F"_" '{print $3}')

	if [ ! -x "/tmp/shadowsocks/bin/v2ray" ];then
		PKG_TYPE="lite"
		PKG_NAME="fancyss_${PKG_ARCH}_lite"
	else
		PKG_TYPE="full"
		PKG_NAME="fancyss_${PKG_ARCH}_full"
	fi

	# fancyss_arm
	if [ "${PKG_ARCH}" == "arm" ];then
		if [ "${LINUX_VER}" == "26" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# ok
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
			else
				# maybe mipsel, RT-AC66U... 
				echo_date "架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U RT-AX56U_V2 TUF-AX3000 TUF-AX3000_V2 TUF-AX5400 TUF-AX5400_V2 XT8
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "44" ];then
			# RT-AX89X
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
		elif [ "${LINUX_VER}" == "54" ];then
			# mediatek TX-AX6000
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
			exit_install 1
		else
			# future model
			echo_date "内核：${KEL_VERS}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi
	
	# fancyss_hnd
	if [ "${PKG_ARCH}" == "hnd" ];then
		if [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U RT-AX56U_V2 TUF-AX3000 TUF-AX3000_V2 TUF-AX5400 TUF-AX5400_V2 XT8
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				# RT-AX86U, RT-AX88U
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				echo_date
				echo_date "----------------------------------------------------------------------"
				echo_date "你的机型是${ROT_ARCH}架构，当前使用的是32位版本的fancyss！"
				echo_date "建议使用64位的fancyss，如fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd_v8"
				echo_date "----------------------------------------------------------------------"
				echo_date
				echo_date "继续安装32位的fancyss_${PKG_ARCH}_${PKG_TYPE}！"
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "26" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
		elif [ "${LINUX_VER}" == "44" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
		elif [ "${LINUX_VER}" == "54" ];then
			# mediatek TX-AX6000
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_arm_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
			exit_install 1
		else
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi

	# fancyss_hnd_v8
	if [ "${PKG_ARCH}" == "hnd_v8" ];then
		if [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U RT-AX56U_V2 TUF-AX3000 TUF-AX3000_V2 TUF-AX5400 TUF-AX5400_V2 XT8
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！"
				echo_date "原因：无法在32位的路由器上使用64位程序的fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				echo_date "退出安装！"
				exit_install 1
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				# RT-AX86U, RT-AX88U
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "26" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
		elif [ "${LINUX_VER}" == "44" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
		elif [ "${LINUX_VER}" == "54" ];then
			# mediatek TX-AX6000
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_arm_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
			exit_install 1
		else
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi

	# fancyss_qca
	if [ "${PKG_ARCH}" == "qca" ];then
		if [ "${LINUX_VER}" == "44" ];then
			# RT-AX89X
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
		elif [ "${LINUX_VER}" == "26" ];then
			# RT-AC68U, RT-AC88U, RT-AC3100, RT-AC5300
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
			
		elif [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U RT-AX56U_V2 TUF-AX3000 TUF-AX3000_V2 TUF-AX5400 TUF-AX5400_V2 XT8
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				# RT-AC86U, RT-AX86U, RT-AX56U, GT-AX6000, XT12...
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "54" ];then
			# mediatek TX-AX6000
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
			exit_install 1
		else
			# no such model, yet.
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi

	# fancyss_mtk
	if [ "${PKG_ARCH}" == "mtk" ];then
		if [ "${LINUX_VER}" == "54" ];then
			# MTK,tx-ax6000 tuf-ax4200
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
		elif [ "${LINUX_VER}" == "26" ];then
			# RT-AC68U, RT-AC88U, RT-AC3100, RT-AC5300
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
			
		elif [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U RT-AX56U_V2 TUF-AX3000 TUF-AX3000_V2 TUF-AX5400 TUF-AX5400_V2 XT8
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				# RT-AC86U, RT-AX86U, RT-AX56U, GT-AX6000, XT12...
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
				exit_install 1
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "44" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
		else
			# no such model, yet.
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css 2>/dev/null|head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css 2>/dev/null|head -n1)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	if [ -n "${TS_FLAG}" ];then
		UI_TYPE="TS"
	fi

	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

exit_install(){
	local state=$1
	local PKG_ARCH=$(cat ${DIR}/.valid)
	case $state in
		1)
			echo_date "fancyss项目地址：https://github.com/hq450/fancyss"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

__get_name_by_type() {
	case "$1" in
	6)
		echo "Naïve"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
		;;
	esac
}

node2json(){
	# 当从full版本切换到lite版本的时候，需要将naive，tuic，hysteria2节点进行备份后，从节点列表里删除相应节点
	# 1. 将所有不支持的节点数据储存到备份文件
	dbus list ssconf_basic_ | grep -E "_[0-9]+=" | sed '/^ssconf_basic_.\+_[0-9]\+=$/d' | sed 's/^ssconf_basic_//' >/tmp/fanycss_kv.txt
	NODES_INFO=$(cat /tmp/fanycss_kv.txt | sed -n 's/type_\([0-9]\+=[678]\)/\1/p' | sort -n)
	if [ -n "${NODES_INFO}" ];then
		mkdir -p /koolshare/configs/fanyss
		for NODE_INFO in ${NODES_INFO}
		do
			local NU=$(echo "${NODE_INFO}" | awk -F"=" '{print $1}')
			local TY=$(echo "${NODE_INFO}" | awk -F"=" '{print $2}')
			echo_date "备份并从节点列表里移除第$NU个$(__get_name_by_type ${TY})节点：【$(dbus get ssconf_basic_name_${NU})】"
			# 备份
			cat /tmp/fanycss_kv.txt | grep "_${NU}=" | sed "s/_${NU}=/\":\"/" | sed 's/^/"/;s/$/\"/;s/$/,/g;1 s/^/{/;$ s/,$/}/' | tr -d '\n' | sed 's/$/\n/' >>/koolshare/configs/fanyss/fanycss_kv.json
			# 删除
			dbus list ssconf_basic_|grep "_${NU}="|sed -n 's/\(ssconf_basic_\w\+\)=.*/\1/p' |  while read key
			do
				dbus remove $key
			done
		done
		
		if [ -f "/koolshare/configs/fanyss/fanycss_kv.json" ];then
			echo_date "📁lite版本不支持的节点成功备份到/koolshare/configs/fanyss/fanycss_kv.json"
			rm -rf /tmp/fanycss_kv.txt
		fi
	fi
}

json2node(){
	if [ ! -f "/koolshare/configs/fanyss/fanycss_kv.json" ];then
		return
	fi
	
	echo_date "检测到上次安装fancyss lite备份的不支持节点，准备恢复！"
	local file_name=fancyss_nodes_restore
	cat > /tmp/${file_name}.sh <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		#------------------------
	EOF
	NODE_INDEX=$(dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -rn | sed -n '1p')
	[ -z "${NODE_INDEX}" ] && NODE_INDEX="0"
	local count=$(($NODE_INDEX + 1))
	while read nodes; do
		echo ${nodes} | sed 's/\",\"/\"\n\"/g;s/^{//;s/}$//' | sed 's/^\"/dbus set ssconf_basic_/g' | sed "s/\":/_${count}=/g" >>/tmp/${file_name}.sh
		let count+=1
	done < /koolshare/configs/fanyss/fanycss_kv.json
	chmod +x /tmp/${file_name}.sh
	sh /tmp/${file_name}.sh
	echo_date "节点恢复成功！"
	sync
	rm -rf /tmp/${file_name}.sh
	rm -rf /tmp/${file_name}.txt
	rm -rf /koolshare/configs/fanyss/fanycss_kv.json
}

check_empty_node(){
	# 从full版本切换为lite版本后，部分不支持节点将会被删除，比如naive，tuic，hysteria2节点
	# 如果安装lite版本的时候，full版本使用的是以上节点，则这些节点可能是空的，此时应该切换为下一个不为空的节点，或者关闭插件（没有可用节点的情况）
	local NODES_SEQ=$(dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -n)
	if [ -z "${NODES_SEQ}" ];then
		# 没有任何节点，可能是新安装插件，可能是full安装lite被删光了
		dbus set ss_basic_enable="0"
		ss_basic_enable="0"
		return 0
	fi
	
	local CURR_NODE=$(dbus get ssconf_basic_node)
	if [ -z "${CURR_NODE}" ];then
		# 有节点，但是没有没有选择节点
		dbus set ss_basic_enable="0"
		ss_basic_enable="0"
		return 0
	fi
	
	local NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
	local NODE_FIRST=$(echo ${NODES_SEQ} | awk '{print $1}')
	local CURR_TYPE=$(dbus get ssconf_basic_type_${CURR_NODE})
	if [ -z "${CURR_TYPE}" ];then
		# 有节点，选择了节点，但是节点是空的，此时选择最后一个节点作为默认节点
		echo_date "检测到当前节点为空，调整默认节点为节点列表内的第一个节点!"
		dbus set ssconf_basic_node=${NODE_FIRST}
		ssconf_basic_node=${NODE_FIRST}
		sync
	fi
}

install_now(){
	# default value
	local PLVER=$(cat ${DIR}/ss/version)

	# print message
	local TITLE="科学上网 ${PKG_TYPE}"
	local DESCR="科学上网 ${PKG_TYPE} for AsusWRT/Merlin platform"
	echo_date "安装版本：${PKG_NAME}_${PLVER}"
	# stop first
	local ENABLE=$(dbus get ss_basic_enable)
	if [ "${ENABLE}" == "1" -a -f "/koolshare/ss/ssconfig.sh" ];then
		echo_date "安装前先关闭${TITLE}插件，保证文件更新成功！"
		sh /koolshare/ss/ssconfig.sh stop >/dev/null 2>&1
	fi

	# backup some file first
	if [ -n "$(ls /koolshare/ss/postscripts/P*.sh 2>/dev/null)" ];then
		echo_date "备份触发脚本!"
		mkdir /tmp/ss_backup
		find /koolshare/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
	fi

	# check old version type
	if [ -f "/koolshare/webs/Module_shadowsocks.asp" ];then
		local IS_LITE=$(cat /koolshare/webs/Module_shadowsocks.asp | grep "lite")
		# 已经安装，此次为升级
		if [ -n "${IS_LITE}" ];then
			OLD_TYPE="lite"
		else
			OLD_TYPE="full"
		fi
	else
		# 没有安装，此次为全新安装
		OLD_TYPE=
	fi

	# full → lite, backup nodes
	if [ "${PKG_TYPE}" == "lite" -a "${OLD_TYPE}" == "full" ];then
		node2json
	fi
	
	# lite → full, restore nodes
	if [ "${PKG_TYPE}" == "full" -a "${OLD_TYPE}" == "lite" ];then
		# only restore backup node when upgrade fancyss from lite to full
		json2node
	fi

	# check empty node
	check_empty_node

	# remove some file first
	echo_date "清理旧文件"
	rm -rf /koolshare/ss/*
	rm -rf /koolshare/scripts/ss_*
	rm -rf /koolshare/webs/Module_shadowsocks*
	rm -rf /koolshare/bin/ss-redir
	rm -rf /koolshare/bin/ss-tunnel
	rm -rf /koolshare/bin/ss-local
	rm -rf /koolshare/bin/rss-redir
	rm -rf /koolshare/bin/rss-tunnel
	rm -rf /koolshare/bin/rss-local
	rm -rf /koolshare/bin/obfs-local
	rm -rf /koolshare/bin/haproxy
	rm -rf /koolshare/bin/dns2socks
	rm -rf /koolshare/bin/kcptun
	rm -rf /koolshare/bin/chinadns-ng
	rm -rf /koolshare/bin/smartdns
	rm -rf /koolshare/bin/speederv1
	rm -rf /koolshare/bin/speederv2
	rm -rf /koolshare/bin/udp2raw
	rm -rf /koolshare/bin/trojan
	rm -rf /koolshare/bin/tuic-client
	rm -rf /koolshare/bin/xray
	rm -rf /koolshare/bin/v2ray
	rm -rf /koolshare/bin/v2ray-plugin
	rm -rf /koolshare/bin/curl-fancyss
	rm -rf /koolshare/bin/hysteria2
	rm -rf /koolshare/bin/httping
	rm -rf /koolshare/bin/haveged
	rm -rf /koolshare/bin/naive
	rm -rf /koolshare/bin/ipt2socks
	rm -rf /koolshare/bin/dnsclient
	rm -rf /koolshare/bin/dohclient
	rm -rf /koolshare/bin/dohclient-cache
	rm -rf /koolshare/bin/dns2tcp
	rm -rf /koolshare/bin/dns-ecs-forcer
	rm -rf /koolshare/bin/uredir
	rm -rf /koolshare/res/icon-shadowsocks.png
	rm -rf /koolshare/res/arrow-down.gif
	rm -rf /koolshare/res/arrow-up.gif
	rm -rf /koolshare/res/ss-menu.js
	rm -rf /koolshare/res/qrcode.js
	rm -rf /koolshare/res/tablednd.js
	rm -rf /koolshare/res/shadowsocks.css
	rm -rf /koolshare/res/fancyss.css
	find /koolshare/init.d/ -name "*shadowsocks.sh" | xargs rm -rf
	find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf

	# optional file maybe exist should be removed, do not remove on install
	# rm -rf /koolshare/bin/sslocal
	rm -rf /koolshare/bin/dig

	# legacy files should be removed
	rm -rf /koolshare/bin/v2ctl
	rm -rf /koolshare/bin/dnsmasq
	rm -rf /koolshare/bin/Pcap_DNSProxy
	rm -rf /koolshare/bin/client_linux_arm*
	rm -rf /koolshare/bin/cdns
	rm -rf /koolshare/bin/chinadns
	rm -rf /koolshare/bin/chinadns1
	rm -rf /koolshare/bin/https_dns_proxy
	rm -rf /koolshare/bin/pdu
	rm -rf /koolshare/bin/koolgame
	rm -rf /koolshare/bin/dnscrypt-proxy
	rm -rf /koolshare/bin/resolveip
	rm -rf /koolshare/res/all.png
	rm -rf /koolshare/res/gfw.png
	rm -rf /koolshare/res/chn.png
	rm -rf /koolshare/res/game.png

	# these file maybe used by others plugin, do not remove
	# rm -rf /koolshare/bin/sponge >/dev/null 2>&1
	# rm -rf /koolshare/bin/jq >/dev/null 2>&1
	# rm -rf /koolshare/bin/isutf8

	# small jffs router should remove more existing files
	if [ "${MODEL}" == "RT-AX56U_V2" ];then
		rm -rf /jffs/syslog.log
		rm -rf /jffs/syslog.log-1
		rm -rf /jffs/wglist
	fi
	rm -rf /jffs/uu.tar.gz*
	echo 1 > /proc/sys/vm/drop_caches
	sync

	# some file in package no not need to install
	if [ -n "$(which socat)" ];then
		rm -rf /tmp/shadowsocks/bin/uredir
	fi
	if [ -f "/koolshrae/bin/websocketd" ];then
		rm -rf /tmp/shadowsocks/bin/websocketd
	fi

	# 检测储存空间是否足够
	echo_date "检测jffs分区剩余空间..."
	SPACE_AVAL=$(df | grep -w "/jffs" | awk '{print $4}')
	SPACE_NEED=$(du -s /tmp/shadowsocks | awk '{print $1}')
	if [ "$SPACE_AVAL" -gt "$SPACE_NEED" ];then
		echo_date "当前jffs分区剩余${SPACE_AVAL}KB, 插件安装大概需要${SPACE_NEED}KB，空间满足，继续安装！"
	else
		echo_date "当前jffs分区剩余${SPACE_AVAL}KB, 插件安装大概需要${SPACE_NEED}KB，空间不足！"
		echo_date "退出安装！"
		exit 1
	fi

	# isntall file
	echo_date "开始复制文件！"
	cd /tmp

	echo_date "复制相关二进制文件！此步时间可能较长！"
	cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/
	
	echo_date "复制相关的脚本文件！"
	cp -rf /tmp/shadowsocks/ss /koolshare/
	cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
	cp -rf /tmp/shadowsocks/install.sh /koolshare/scripts/ss_install.sh
	cp -rf /tmp/shadowsocks/uninstall.sh /koolshare/scripts/uninstall_shadowsocks.sh
	
	echo_date "复制相关的网页文件！"
	cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
	cp -rf /tmp/shadowsocks/res/* /koolshare/res/

	sync

	# Permissions
	echo_date "为新安装文件赋予执行权限..."
	chmod 755 /koolshare/ss/rules/* >/dev/null 2>&1
	chmod 755 /koolshare/ss/* >/dev/null 2>&1
	chmod 755 /koolshare/scripts/ss* >/dev/null 2>&1
	chmod 755 /koolshare/bin/* >/dev/null 2>&1

	# start some process before fancyss start
	if [ -x "/koolshare/bin/websocketd" -a -f "/koolshare/ss/websocket.sh" ];then
		if [ -z "$(pidof websocketd)" ];then
			run_bg websocketd --port=803 /bin/sh /koolshare/ss/websocket.sh
		fi
	fi
	
	# intall different UI
	set_skin

	# restore backup
	if [ -n "$(ls /tmp/ss_backup/P*.sh 2>/dev/null)" ];then
		echo_date "恢复触发脚本!"
		mkdir -p /koolshare/ss/postscripts
		find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /koolshare/ss/postscripts
	fi

	# soft links
	echo_date "创建一些二进制文件的软链接！"
	[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel
	[ ! -L "/koolshare/init.d/S99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/S99shadowsocks.sh
	[ ! -L "/koolshare/init.d/N99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/N99shadowsocks.sh
	[ ! -L "/koolshare/init.d/S99socks5.sh" ] && ln -sf /koolshare/scripts/ss_socks5.sh /koolshare/init.d/S99socks5.sh

	# default values
	eval $(dbus export ss)
	local PKG_TYPE=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	# 3.0.4：国内DNS默认使用运营商DNS
	[ -z "${ss_china_dns}" ] && dbus set ss_china_dns="1"
	# 3.0.4 从老版本升级到3.0.4，原部分方案需要切换到进阶方案，因为这些方案已经不存在
	if [ -z "${ss_basic_advdns}" -a -z "${ss_basic_olddns}" ];then
		# 全新安装的 3.0.4+，或者从3.0.3及其以下版本升级而来
		if [ -z "${ss_foreign_dns}" ];then
			# 全新安装的 3.0.4
			dbus set ss_basic_advdns="1"
			dbus set ss_basic_olddns="0"
		else
			# 从3.0.3及其以下版本升级而来
			# 因为一些dns选项已经不存在，所以更改一下
			if [ "${ss_foreign_dns}" == "2" -o "${ss_foreign_dns}" == "5" -o "${ss_foreign_dns}" == "10" -o "${ss_foreign_dns}" == "1" -o "${ss_foreign_dns}" == "6" ];then
				# 原chinands2、chinadns1、chinadns-ng、cdns、https_dns_proxy已经不存在, 更改为进阶DNS设定：chinadns-ng
				dbus set ss_basic_advdns="1"
				dbus set ss_basic_olddns="0"
			elif [ "${ss_foreign_dns}" == "4" -o "${ss_foreign_dns}" == "9" ];then
				if [ "${PKG_TYPE}" == "lite" ];then
					# ss-tunnel、SmartDNS方案在lite版本中不存在
					dbus set ss_basic_advdns="1"
					dbus set ss_basic_olddns="0"
				else
					# ss-tunnel、SmartDNS方案在full版本中存在
					dbus set ss_basic_advdns="0"
					dbus set ss_basic_olddns="1"
				fi
			else
				# dns2socks, v2ray/xray_dns, 直连这些在full和lite版中都在
				dbus set ss_basic_advdns="0"
				dbus set ss_basic_olddns="1"
			fi
		fi
	elif [ -z "${ss_basic_advdns}" -a -n "${ss_basic_olddns}" ];then
		# 不正确，ss_basic_advdns和ss_basic_olddns必须值相反
		[ "${ss_basic_olddns}" == "0" ] && dbus set ss_basic_advdns="1"
		[ "${ss_basic_olddns}" == "1" ] && dbus set ss_basic_advdns="0"
	elif [ -n "${ss_basic_advdns}" -a -z "${ss_basic_olddns}" ];then
		# 不正确，ss_basic_advdns和ss_basic_olddns必须值相反
		[ "${ss_basic_advdns}" == "0" ] && dbus set ss_basic_olddns="1"
		[ "${ss_basic_advdns}" == "1" ] && dbus set ss_basic_olddns="0"
	elif [ -n "${ss_basic_advdns}" -a -n "${ss_basic_olddns}" ];then
		if [ "${ss_basic_advdns}" == "${ss_basic_olddns}" ];then
			[ "${ss_basic_olddns}" == "0" ] && dbus set ss_basic_advdns="1"
			[ "${ss_basic_olddns}" == "1" ] && dbus set ss_basic_advdns="0"
		fi
	fi

	[ -z "${ss_basic_proxy_newb}" ] && dbus set ss_basic_proxy_newb=1
	[ -z "${ss_basic_udpoff}" ] && dbus set ss_basic_udpoff=0
	[ -z "${ss_basic_udpall}" ] && dbus set ss_basic_udpall=0
	[ -z "${ss_basic_udpgpt}" ] && dbus set ss_basic_udpgpt=1
	[ -z "${ss_basic_nonetcheck}" ] && dbus set ss_basic_nonetcheck=1
	[ -z "${ss_basic_notimecheck}" ] && dbus set ss_basic_notimecheck=1
	[ -z "${ss_basic_nocdnscheck}" ] && dbus set ss_basic_nocdnscheck=1
	[ -z "${ss_basic_nofdnscheck}" ] && dbus set ss_basic_nofdnscheck=1
	
	[ "${ss_disable_aaaa}" != "1" ] && dbus set ss_basic_chng_no_ipv6=1
	[ -z "${ss_basic_chng_xact}" ] && dbus set ss_basic_chng_xact=0
	[ -z "${ss_basic_chng_xgt}" ] && dbus set ss_basic_chng_xgt=1
	[ -z "${ss_basic_chng_xmc}" ] && dbus set ss_basic_chng_xmc=0
	
	# others
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=1
	[ -z "$(dbus get ss_acl_default_port)" ] && dbus set ss_acl_default_port=all
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	[ -z "$(dbus get ss_basic_wt_furl)" ] && dbus set ss_basic_wt_furl="http://www.google.com.tw"
	[ -z "$(dbus get ss_basic_wt_curl)" ] && dbus set ss_basic_wt_curl="http://www.baidu.com"
	[ -z "${ss_basic_latency_opt}" ] && dbus set ss_basic_latency_opt="2"

	# 因版本变化导致一些值没有了，更改一下
	if [ "${ss_basic_chng_china_2_tcp}" == "5" ];then
		dbus set ss_basic_chng_china_2_tcp="6"
	fi
	
	# lite
	if [ ! -x "/koolshare/bin/v2ray" ];then
		dbus set ss_basic_vcore=1
	else
		dbus set ss_basic_vcore=0
	fi
	if [ ! -x "/koolshare/bin/trojan" ];then
		dbus set ss_basic_tcore=1
	else
		dbus set ss_basic_tcore=0
		
	fi
	
	# dbus value
	echo_date "设置插件安装参数..."
	dbus set ss_basic_version_local="${PLVER}"
	dbus set softcenter_module_${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_install="4"
	dbus set softcenter_module_${module}_name="${module}"
	dbus set softcenter_module_${module}_title="${TITLE}"
	dbus set softcenter_module_${module}_description="${DESCR}"
	
	# finish
	echo_date "${TITLE}插件安装安装成功！"

	# restart
	if [ "${ENABLE}" == "1" -a -f "/koolshare/ss/ssconfig.sh" ];then
		echo_date 重启科学上网插件！
		sh /koolshare/ss/ssconfig.sh restart
	fi

	echo_date "更新完毕，请等待网页自动刷新！"
	
	exit_install
}

install(){
	get_model
	get_fw_type
	platform_test
	install_now
}

install
