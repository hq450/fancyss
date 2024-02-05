#!/bin/sh
source /koolshare/scripts/base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}

cmd() {
	"$@" 2>&1
	# ${@%%[[:space:]]*} ${@#*[[:space:]]} 2>&1
	# start-stop-daemon -S -b -x ${@%%[[:space:]]*} -- ${@#*[[:space:]]}
	# start-stop-daemon -S -x ss_config.sh -- start
}

while read MSG;
do
	if [ "${MSG}" == "show_message" ]; then
		echo "成功连接到路由器，当前时间：$(date -R +%Y年%m月%d日\ %X)"
		echo "服务器：$SERVER_NAME"
		echo "客户端：$REMOTE_ADDR"
		echo "浏览器：$HTTP_USER_AGENT"
		echo "请点击下方按钮执行操作！"
	elif [ "${MSG}" == "reboot" ]; then
		echo "检测到你要执行路由器重启命令！拒绝！"
		exit
	elif [ "${MSG}" == "get_ssf_log" ]; then
		cat /tmp/upload/ssf_status.txt | /usr/bin/tr '\n' '@@'
	elif [ "${MSG}" == "get_real_log" ]; then
 		_log=$(cat /tmp/upload/ss_log.txt)
 		if [ -z "${_log}" ];then
			echo "开始获取日志！"
		else
			echo "${_log}"
 		fi
	else
 		cmd $MSG
 	fi
done
