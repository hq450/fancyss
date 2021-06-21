#!/bin/sh

# shadowsocks script for qca-ipq806x platform router

# 此脚本是一个示例，实际写法按照自己的方法来做
# 更改此脚本的名字，保证此脚本的名字格式是： P+数字+名字.sh
# 例如在/koolshare/ss/postscripts下放入两个脚本:P01V2xxx.sh, P99Brook.sh
# SS插件运行后货自动按照数字从小到大顺序运行 P01xxx.sh start, P99Brook.sh start
# SS插件关闭前会自动按照数字从大到小顺序运行 P99Brook.sh stop, P01xxx.sh stop
#------------------------------------------
# 读取所有SS配置，1.6.0版本及其以后插件，请用此方法获取配置，以前的方法可能导致配置获取不全
source /koolshare/scripts/ss_base.sh
#------------------------------------------
start_xxx(){
	echo_date ："启动xxx"
	# do something here
}

stop_xxx(){
	echo_date ："停止xxx"
	# do something here
}
#------------------------------------------
case $1 in
start)
	start_xxx
	;;
stop)
	stop_xxx
	;;
esac
