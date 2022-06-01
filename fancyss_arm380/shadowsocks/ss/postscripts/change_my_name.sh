#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

# 此脚本是一个示例，实际写法按照自己的方法来做
# 更改此脚本的名字，保证此脚本的名字格式是： P+数字+名字.sh
# 例如在/koolshare/ss/postscripts下放入两个脚本:P01V2ray.sh, P99Brook.sh
# SS插件运行后货自动按照数字从小到大顺序运行 P01V2ray.sh start, P99Brook.sh start
# SS插件关闭前会自动按照数字从大到小顺序运行 P99Brook.sh stop, P01V2ray.sh stop
#------------------------------------------
source /koolshare/scripts/base.sh
# 读取SS配置
eval `dbus export ss`
# 保持打印日志时间格式和ss插件一致
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
#------------------------------------------
start_v2ray(){
	echo_date ："启动v2ray"
	# do something here
}

stop_v2ray(){
	echo_date ："停止v2ray"
	# do something here
}
#------------------------------------------
case $1 in
start)
	start_v2ray
	;;
stop)
	stop_v2ray
	;;
esac
