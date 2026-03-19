#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
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
			FW_TYPE_NAME="koolcenter官改固件"
		else
			FW_TYPE_NAME="koolcenter梅林改版固件"
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
	PKG_ARCH=$(cat ${DIR}/.valid)
	ROT_ARCH=$(uname -m)
	KEL_VERS=$(uname -r)
	PKG_NAME=$(cat /tmp/shadowsocks/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_NAME=.+" | awk -F"=" '{print $2}' | sed 's/"//g')
	PKG_ARCH=$(cat /tmp/shadowsocks/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+" | awk -F"=" '{print $2}' | sed 's/"//g')
	PKG_TYPE=$(cat /tmp/shadowsocks/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+" | awk -F"=" '{print $2}' | sed 's/"//g')

	# fancyss_arm
	if [ "${PKG_ARCH}" == "arm" ]; then
		case "${LINUX_VER}" in
			"26")
				if [ "${ROT_ARCH}" == "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				else
					echo_date "架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"41"|"419")
				if [ "${ROT_ARCH}" == "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				elif [ "${ROT_ARCH}" == "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"		
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			"54")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			*)
				echo_date "内核：${KEL_VERS}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi
	
	# fancyss_hnd
	if [ "${PKG_ARCH}" = "hnd" ]; then
		case "${LINUX_VER}" in
			"41"|"419")
				if [ "${ROT_ARCH}" = "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				elif [ "${ROT_ARCH}" = "aarch64" ]; then
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
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			"54")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi

	# fancyss_hnd_v8
	if [ "${PKG_ARCH}" = "hnd_v8" ]; then
		case "${LINUX_VER}" in
			"41"|"419")
				if [ "${ROT_ARCH}" = "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！"
					echo_date "原因：无法在32位的路由器上使用64位程序的fancyss_${PKG_ARCH}_${PKG_TYPE}！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					echo_date "退出安装！"
					exit_install 1
				elif [ "${ROT_ARCH}" = "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			"54")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi

	# fancyss_qca
	if [ "${PKG_ARCH}" = "qca" ]; then
		case "${LINUX_VER}" in
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"41"|"419")
				if [ "${ROT_ARCH}" = "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				elif [ "${ROT_ARCH}" = "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"54")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"
						exit_install 1
						;;
				esac
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi

	# fancyss_mtk
	if [ "${PKG_ARCH}" == "mtk" ]; then
		case "${LINUX_VER}" in
			"54")
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"	
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"41"|"419")
				if [ "${ROT_ARCH}" == "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				elif [ "${ROT_ARCH}" == "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi

	# fancyss_ipq32
	if [ "${PKG_ARCH}" = "ipq32" ]; then
		case "${LINUX_VER}" in
			"54")
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
						;;
					"TUF_6500")
						echo_date "建议使用fancyss_ipq64_full或者fancyss_ipq64_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq64"
						exit_install 1
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"41"|"419")
				if [ "${ROT_ARCH}" = "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				elif [ "${ROT_ARCH}" = "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi

	# fancyss_ipq64
	if [ "${PKG_ARCH}" = "ipq64" ]; then
		case "${LINUX_VER}" in
			"54")
				case "${MODEL}" in
					"ZenWiFi_BD4")
						echo_date "建议使用fancyss_ipq32_full或者fancyss_ipq32_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_ipq32"
						exit_install 1
						;;
					"TUF_6500")
						echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_${PKG_ARCH}_${PKG_TYPE}！"
						;;
					"TX-AX6000"|"TUF-AX4200Q"|"RT-AX57_Go"|"GS7"|"ZenWiFi_BT8P"|"GS7_Air")
						echo_date "建议使用fancyss_mtk_full或者fancyss_mtk_lite！"		
						echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_mtk"
						exit_install 1
						;;
					*)
						echo_date "原因：暂不支持你的路由器型号：${MODEL}，请联系插件作者！"		
						exit_install 1
						;;
				esac
				;;
			"26")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
				exit_install 1
				;;
			"41"|"419")
				if [ "${ROT_ARCH}" = "armv7l" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				elif [ "${ROT_ARCH}" = "aarch64" ]; then
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
					echo_date "建议使用fancyss_hnd_v8_full或者fancyss_hnd_v8_lite！"
					echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
					exit_install 1
				else
					echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该架构！退出！"
					exit_install 1
				fi
				;;
			"44")
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
				echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
				echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
				exit_install 1
				;;
			*)
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_${PKG_ARCH}_${PKG_TYPE}不适用于该内核版本！"
				exit_install 1
				;;
		esac
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null|head -n1)
	local ROG_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "2071044")
	local TUF_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "D0982C")
	local WRT_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "4F5B5F")
	if [ -n "${TS_FLAG}" ];then
		UI_TYPE="TS"
	else
		if [ -n "${TUF_FLAG}" ];then
			UI_TYPE="TUF"
		fi
		if [ -n "${ROG_FLAG}" ];then
			UI_TYPE="ROG"
		fi
		if [ -n "${WRT_FLAG}" ];then
			UI_TYPE="ASUSWRT"
		fi
	fi
	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
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

full2lite(){
	# 当从full版本切换到lite版本的时候，需要将naive、tuic节点进行备份后，从节点列表里删除相应节点
	# 1. 将所有不支持的节点数据储存到备份文件
	local tmp_kv="/tmp/fancyss_kv.txt"
	local backup_dir="/koolshare/configs/fanyss"
	local backup_file="${backup_dir}/fancyss_kv.json"
	dbus list ssconf_basic_ | grep -E "_[0-9]+=" | sed '/^ssconf_basic_.\+_[0-9]\+=$/d' | sed 's/^ssconf_basic_//' >"${tmp_kv}"
	NODES_INFO=$(sed -n 's/type_\([0-9]\+=[67]\)/\1/p' "${tmp_kv}" | sort -n)
	if [ -z "${NODES_INFO}" ];then
		rm -rf "${tmp_kv}" "${backup_file}"
		return
	fi
	if [ -n "${NODES_INFO}" ];then
		mkdir -p "${backup_dir}"
		: > "${backup_file}"
		for NODE_INFO in ${NODES_INFO}
		do
			local NU=$(echo "${NODE_INFO}" | awk -F"=" '{print $1}')
			local TY=$(echo "${NODE_INFO}" | awk -F"=" '{print $2}')
			echo_date "备份并从节点列表里移除第$NU个$(__get_name_by_type ${TY})节点：【$(dbus get ssconf_basic_name_${NU})】"
			# 备份
			grep "_${NU}=" "${tmp_kv}" | sed "s/_${NU}=/\":\"/" | sed 's/^/"/;s/$/\"/;s/$/,/g;1 s/^/{/;$ s/,$/}/' | tr -d '\n' | sed 's/$/\n/' >>"${backup_file}"
			# 删除
			dbus list ssconf_basic_|grep "_${NU}="|sed -n 's/\(ssconf_basic_\w\+\)=.*/\1/p' |  while read key
			do
				dbus remove $key
			done
		done
		
		if [ -s "${backup_file}" ];then
			echo_date "📁lite版本不支持的节点成功备份到${backup_file}"
			rm -rf "${tmp_kv}"
		else
			rm -rf "${tmp_kv}" "${backup_file}"
		fi
	fi
}

lite2full(){
	if [ ! -f "/koolshare/configs/fanyss/fancyss_kv.json" ];then
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
	done < /koolshare/configs/fanyss/fancyss_kv.json
	chmod +x /tmp/${file_name}.sh
	sh /tmp/${file_name}.sh
	echo_date "节点恢复成功！"
	sync
	rm -rf /tmp/${file_name}.sh
	rm -rf /tmp/${file_name}.txt
	rm -rf /koolshare/configs/fanyss/fancyss_kv.json
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

check_device(){
	if [ ! -d "/data" ];then
		return "1"
	fi
	
	mkdir -p $1/rw_test 2>/dev/null
	sync
	if [ -d "$1/rw_test" ]; then
		echo "rwTest=OK" >"$1/rw_test/rw_test.txt"
		sync
		if [ -f "$1/rw_test/rw_test.txt" ]; then
			. "$1/rw_test/rw_test.txt"
			if [ "$rwTest" = "OK" ]; then
				rm -rf "$1/rw_test"
				return "0"
			else
				#echo_date "发生错误！你选择的磁盘目录：${1}没有通过文件读取测试！"
				return "1"
			fi
		else
			#echo_date "发生错误！你选择的磁盘目录：${1}没有通过文件写入测试！"
			return "1"
		fi
	else
		#echo_date "发生错误！你选择的磁盘目录：${1}没有通过文件夹写入测试！"
		return "1"
	fi
}

install_now(){
	# default value
	local PLVER=$(cat ${DIR}/ss/version)

	#local PKG_ARCH_OLD=$(cat /koolshare/webs/Module_shadowsocks.asp 2>/dev/null | grep -Eo "PKG_ARCH=.+" | awk -F"=" '{print $2}' |sed 's/"//g')
	#local PKG_TYPE_OLD=$(cat /koolshare/webs/Module_shadowsocks.asp 2>/dev/null | grep -Eo "PKG_TYPE=.+" | awk -F"=" '{print $2}' |sed 's/"//g')
	local TITLE_OLD=$(dbus get softcenter_module_shadowsocks_title)

	# print message
	local TITLE_NEW="科学上网 ${PKG_TYPE}"
	local DESCR="科学上网 ${PKG_TYPE} for AsusWRT/Merlin platform"
	echo_date "安装版本：${PKG_NAME}_${PKG_ARCH}_${PKG_TYPE}_${PLVER}"
	
	# stop first
	local ENABLE=$(dbus get ss_basic_enable)
	if [ "${ENABLE}" == "1" -a -f "/koolshare/ss/ssconfig.sh" ];then
		echo_date "安装前先关闭${TITLE_OLD}插件，保证文件更新成功！"
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
		OLD_TYPE=""
	fi

	# full → lite, backup nodes
	if [ "${PKG_TYPE}" == "lite" -a "${OLD_TYPE}" == "full" ];then
		echo_date "当前版本：full，即将安装：lite"
		full2lite
	fi
	
	# lite → full, restore nodes
	if [ "${PKG_TYPE}" == "full" -a "${OLD_TYPE}" == "lite" ];then
		# only restore backup node when upgrade fancyss from lite to full
		echo_date "当前版本：lite，即将安装：full"
		lite2full
	fi

	# check empty node
	check_empty_node

	# remove some file first
	echo_date "清理旧文件"
	rm -rf /koolshare/ss/*
	rm -rf /koolshare/scripts/ss_*
	rm -rf /koolshare/webs/Module_shadowsocks*
	rm -rf /koolshare/bin/rss-redir
	rm -rf /koolshare/bin/rss-tunnel
	rm -rf /koolshare/bin/rss-local
	rm -rf /koolshare/bin/obfs-local
	rm -rf /koolshare/bin/dns2socks
	rm -rf /koolshare/bin/kcptun
	rm -rf /koolshare/bin/chinadns-ng
	rm -rf /koolshare/bin/xray
	rm -rf /koolshare/bin/curl-fancyss
	rm -rf /koolshare/bin/hysteria2
	rm -rf /koolshare/bin/haveged
	rm -rf /koolshare/bin/naive
	rm -rf /koolshare/bin/ipt2socks
	rm -rf /koolshare/bin/dnsclient
	rm -rf /koolshare/bin/smartdns
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
	# optional file maybe exist should be removed, but no need remove on install/upgrade


	# optional file maybe exist should be removed, remove on install
	rm -rf /koolshare/bin/dig
	rm -rf /koolshare/bin/speederv1
	rm -rf /koolshare/bin/speederv2
	rm -rf /koolshare/bin/udp2raw
	rm -rf /koolshare/bin/tuic-client

	# some file may exist in /data
	if [ -d "/data" ];then
		rm -rf /data/xray >/dev/null 2>&1
		rm -rf /data/v2ray >/dev/null 2>&1
		rm -rf /data/hysteria2 >/dev/null 2>&1
		rm -rf /data/naive >/dev/null 2>&1
		rm -rf /data/sslocal >/dev/null 2>&1
		rm -rf /data/rss-local >/dev/null 2>&1
		rm -rf /data/rss-redir >/dev/null 2>&1
		# legacy since 3.3.6
		rm -rf /data/ss-local >/dev/null 2>&1
		rm -rf /data/ss-redir >/dev/null 2>&1
		rm -rf /data/ss-tunnel >/dev/null 2>&1
	fi
	
	# legacy files should be removed
	rm -rf /koolshare/bin/v2ray
	rm -rf /koolshare/bin/uredir
	rm -rf /koolshare/bin/dns-ecs-forcer
	rm -rf /koolshare/bin/dns2tcp
	rm -rf /koolshare/bin/sslocal
	rm -rf /koolshare/bin/httping
	rm -rf /koolshare/bin/v2ray-plugin
	rm -rf /koolshare/bin/trojan
	rm -rf /koolshare/bin/haproxy
	rm -rf /koolshare/bin/dohclient
	rm -rf /koolshare/bin/dohclient-cache
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
	rm -rf /koolshare/bin/ss-redir
	rm -rf /koolshare/bin/ss-tunnel
	rm -rf /koolshare/bin/ss-local
	rm -rf /koolshare/res/all.png
	rm -rf /koolshare/res/gfw.png
	rm -rf /koolshare/res/chn.png
	rm -rf /koolshare/res/game.png

	# these file maybe used by others plugin, do not remove
	# rm -rf /koolshare/bin/sponge >/dev/null 2>&1
	# rm -rf /koolshare/bin/jq
	# rm -rf /koolshare/bin/isutf8
	
	# small jffs router should remove more existing files
	if [ "${MODEL}" == "RT-AX56U_V2" -o "${MODEL}" == "RT-AX57" ];then
		rm -rf /jffs/syslog.log
		rm -rf /jffs/syslog.log-1
		rm -rf /jffs/wglist*
		rm -rf /jffs/.sys/diag_db/*
		# make a dummy
		rm -rf /jffs/uu.tar.gz*
		touch /jffs/uu.tar.gz
	elif [ "${MODEL}" == "ZenWiFi_BD4" ];then
		rm -rf /jffs/ahs
		rm -rf /jffs/asd
		rm -rf /jffs/syslog.log*
		rm -rf /jffs/curllst*
		rm -rf /jffs/wglist*
		rm -rf /jffs/asd.log
		rm -rf /jffs/hostapd.log
		rm -rf /jffs/webs_upgrade.log*
		rm -rf /jffs/.sys/diag_db/*
		rm -rf /jffs/uu.tar.gz*
	else
		rm -rf /jffs/uu.tar.gz*
	fi
	echo 1 > /proc/sys/vm/drop_caches
	sync

	# package modify

	# curl-fancyss is not needed when curl in system support proxy (102 official mod and merlin mod have proxy enabled)
	local CURL_PROXY_FLAG=$(curl -V|grep -Eo proxy)
	if [ -n "${CURL_PROXY_FLAG}" ];then
		rm -rf /tmp/shadowsocks/bin/curl-fancyss
		ln -sf $(which curl) /koolshare/bin/curl-fancyss
	fi

	# jq is included in official 102 stock firmware higher version(RT-BE86U)
	if [ -f /usr/bin/jq ];then
		rm -rf /tmp/shadowsocks/bin/jq
		if [ ! -L /koolshare/bin/jq ];then
			ln -sf /usr/bin/jq /koolshare/bin/jq
		fi
	fi
	
	# some file in package no need to install
	if [ -n "$(which socat)" ];then
		rm -rf /tmp/shadowsocks/bin/uredir
	fi
	
	if [ -f "/koolshrae/bin/websocketd" ];then
		rm -rf /tmp/shadowsocks/bin/websocketd
	fi

	# 将一些较大的二进制文件安装到/data分区，以节约jffs分区空间
	# 1. 卸载的时候记得删除/data分区内的二进制
	# 2. 打包的时候应该用/data分区内的二进制
	# 3. 更新二进制的时候应该检测/koolshare/bin下的是否为软连接，是的话应该更新真实位置的二进制
	check_device "/data"
	if [ "$?" == "0" ];then
		# 检测data分区剩余空间
		echo_date "检测/data分区剩余空间..."
		local SPACE_DATA_AVAL1=$(df | grep -w "/data" | awk '{print $4}')
		echo_date "/data分区剩余空间为：${SPACE_DATA_AVAL1}KB"
		local _BINS="xray v2ray hysteria2 naive sslocal rss-local rss-tunnel rss-redir"
		for _BIN in ${_BINS}
		do
			if [ -f "/tmp/shadowsocks/bin/${_BIN}" ];then
				local SPACE_DATA_AVAL1=$(df | grep -w "/data" | awk '{print $4}')
				local SPACE_DATA_AVAL2=$((${SPACE_DATA_AVAL1} - 256))
				local BIN_SIZE=$(du /tmp/shadowsocks/bin/${_BIN} | awk '{print $1}')
				if [ "${BIN_SIZE}" -lt "${SPACE_DATA_AVAL2}" ];then
					echo_date "将${_BIN}安装到/data分区..."
					mv /tmp/shadowsocks/bin/${_BIN} /data/
					chmod +x /data/${_BIN} 
					ln -sf /data/${_BIN} /koolshare/bin/${_BIN}
				fi
				sync
			fi
		done
	fi

	# 检测jffs储存空间是否足够
	echo_date "检测jffs分区剩余空间..."

	SPACE_AVAL=$(df | grep -w "/jffs" | awk '{print $4}')
	cd /tmp
	tar -cz -f /tmp/test_size.tar.gz shadowsocks/
	if [ -f "/tmp/test_size.tar.gz" ];then
		SPACE_NEED=$(du -s /tmp/test_size.tar.gz | awk '{print $1}')
		rm -rf /tmp/test_size.tar.gz
	else
		SPACE_NEED=$(du -s /tmp/shadowsocks | awk '{print $1}')
	fi
	if [ "${SPACE_AVAL}" -gt "${SPACE_NEED}" ];then
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
	local _LAYJS_MD5=$(md5sum /koolshare/res/layer/layer.js | awk '{print $1}')
	if [ -f "/koolshare/res/layer/layer.js" -a "${_LAYJS_MD5}" == "9d72838d6f33e45f058cc1fa00b7a5c7" ];then
		mv -f /tmp/shadowsocks/res/layer.js /koolshare/res/layer/
	else
		rm /tmp/shadowsocks/res/layer.js >/dev/null 2>&1
	fi
	cp -rf /tmp/shadowsocks/res/* /koolshare/res/
	sync

	# Permissions
	echo_date "为新安装文件赋予执行权限..."
	chmod 755 /koolshare/ss/rules/* >/dev/null 2>&1
	chmod 755 /koolshare/ss/* >/dev/null 2>&1
	chmod 755 /koolshare/scripts/ss* >/dev/null 2>&1
	chmod 755 /koolshare/bin/* >/dev/null 2>&1
	
	# kill some process before fancyss start
	ret_0=$(ps | grep "websocketd" | grep "/bin/sh")
	if [ -n "${ret_0}" ];then
		killall websocketd >/dev/null 2>&1
		sleep 1
		sync
	fi

	# start some process before fancyss start
	if [ -x "/koolshare/bin/websocketd" -a -f "/koolshare/ss/websocket" ];then
		if [ -z "$(pidof websocketd)" ];then
			run_bg websocketd --port=803 /koolshare/ss/websocket
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

	# default values
	eval $(dbus export ss)
	local PKG_TYPE=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')

	[ -z "${ss_basic_proxy_newb}" ] && dbus set ss_basic_proxy_newb=1
	[ -z "${ss_basic_proxy_ipv6}" ] && dbus set ss_basic_proxy_ipv6=0
	[ -z "${ss_basic_udpoff}" ] && dbus set ss_basic_udpoff=1
	[ -z "${ss_basic_udpall}" ] && dbus set ss_basic_udpall=0
	# 兼容，仅chatgpt删除掉了（3.4.13），ss_basic_udpoff和ss_basic_udpall必须有一个等于1
	if [ "${ss_basic_udpoff}" != "1" -a "${ss_basic_udpall}" != "1" ];then
		ss_basic_udpoff=1
		ss_basic_udpall=0
		dbus set ss_basic_udpoff=1
		dbus set ss_basic_udpall=0
	fi
	[ -z "${ss_basic_nonetcheck}" ] && dbus set ss_basic_nonetcheck=1
	[ -z "${ss_basic_notimecheck}" ] && dbus set ss_basic_notimecheck=1
	[ -z "${ss_basic_nocdnscheck}" ] && dbus set ss_basic_nocdnscheck=1
	[ -z "${ss_basic_nofdnscheck}" ] && dbus set ss_basic_nofdnscheck=1
	[ -z "${ss_basic_noruncheck}" ] && dbus set ss_basic_noruncheck=1
	
	[ -z "${ss_basic_chng_xact}" ] && dbus set ss_basic_chng_xact=0
	[ -z "${ss_basic_chng_xgt}" ] && dbus set ss_basic_chng_xgt=1
	[ -z "${ss_basic_chng_xmc}" ] && dbus set ss_basic_chng_xmc=0
	
	# others
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=2
	[ -z "$(dbus get ss_acl_default_udp)" ] && dbus set ss_acl_default_udp=0
	[ -z "$(dbus get ss_acl_default_quic)" ] && dbus set ss_acl_default_quic=1
	[ -z "$(dbus get ss_acl_default_ports)" ] && dbus set ss_acl_default_ports="22,80,443,8080,8443"
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	[ -z "$(dbus get ss_basic_furl)" ] && dbus set ss_basic_furl="http://www.google.com/generate_204"
	[ -z "$(dbus get ss_basic_curl)" ] && dbus set ss_basic_curl="http://connectivitycheck.platform.hicloud.com/generate_204"

	# 延迟测试列默认开启（批量测速由独立开关控制）
	if [ -z "${ss_basic_latency_val}" ]; then
		case "${PKG_ARCH}" in
		arm|hnd|ipq32)
			dbus set ss_basic_latency_val="0"
			;;
		*)
			dbus set ss_basic_latency_val="2"
			;;
		esac
	fi

	# 批量测速开关：低端设备默认关闭，高端设备默认开启
	if [ -z "${ss_basic_latency_batch}" ]; then
		if [ "${PKG_ARCH}" = "arm" -o "${PKG_ARCH}" = "hnd" -o "${PKG_ARCH}" = "ipq32" ]; then
			dbus set ss_basic_latency_batch="0"
		else
			local CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
			local MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
			if [ "${ROT_ARCH}" == "armv7l" ]; then
				dbus set ss_basic_latency_batch="0"
			elif [ "${ROT_ARCH}" == "aarch64" ]; then
				if [ "${CPU_CORES}" -le 2 -o "${MEM_MB}" -lt 768 ]; then
					dbus set ss_basic_latency_batch="0"
				else
					dbus set ss_basic_latency_batch="1"
				fi
			else
				dbus set ss_basic_latency_batch="0"
			fi
		fi
	fi

	# 因版本变化导致一些值没有了，更改一下
	if [ "${ss_basic_chng_china_2_tcp}" == "5" ];then
		dbus set ss_basic_chng_china_2_tcp="6"
	fi

	# 某些版本不含ss-rust，默认由xray运行ss协议
	if [ ! -x "/koolshare/bin/sslocal" ];then
		dbus set ss_basic_score=1
		ss_basic_score=1
	else
		dbus set ss_basic_score=0
		ss_basic_score=0
	fi

	# dbus value
	echo_date "设置插件安装参数..."
	dbus set ss_basic_version_local="${PLVER}"
	dbus set softcenter_module_${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_install="4"
	dbus set softcenter_module_${module}_name="${module}"
	dbus set softcenter_module_${module}_title="${TITLE_NEW}"
	dbus set softcenter_module_${module}_description="${DESCR}"
	
	# finish
	echo_date "${TITLE_NEW}插件安装安装成功！"

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
