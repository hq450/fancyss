#!/bin/sh
eval `dbus export shadowsocks`
eval `dbus export ss`
source /koolshare/scripts/base.sh
ss_basic_version_local=`cat /koolshare/ss/version`
dbus set ss_basic_version_local=$ss_basic_version_local
backup_url="http://mips.ngrok.wang:5000/shadowsocks/"
main_url="https://raw.githubusercontent.com/koolshare/koolshare.github.io/mips_softerware_center/shadowsocks"
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'
# creat dnsmasq.d folder
creat_folder(){
if [ ! -d /koolshare/configs/dnsmasq.d ];then
	mkdir /koolshare/configs/dnsmasq.d
fi
}

install_ss(){
	echo_date 开始解压压缩包...
	tar -zxf shadowsocks.tar.gz
	dbus set ss_basic_install_status="2"
	chmod a+x /tmp/shadowsocks/install.sh
	echo_date 开始安装更新文件...
	sh /tmp/shadowsocks/install.sh
}

# update ss
update_ss(){
	# ss_basic_install_status=	#
	# ss_basic_install_status=0	#
	# ss_basic_install_status=1	#正在下载更新......
	# ss_basic_install_status=2	#正在安装更新...
	# ss_basic_install_status=3	#安装更新成功，5秒后刷新本页！
	# ss_basic_install_status=4	#下载文件校验不一致！
	# ss_basic_install_status=5	#然而并没有更新！
	# ss_basic_install_status=6	#正在检查是否有更新~
	# ss_basic_install_status=7	#检测更新错误！
	# ss_basic_install_status=8	#更换更新服务器
	echo_date 更新过程中请不要做奇怪的事，不然可能导致问题！
	dbus set ss_basic_install_status="6"
	echo_date 开启SS检查更新：正在检测主服务器在线版本号...
	ss_basic_version_web1=`curl --connect-timeout 5 -s "$main_url"/version | sed -n 1p`
	if [ ! -z $ss_basic_version_web1 ];then
		echo_date 检测到主服务器在线版本号：$ss_basic_version_web1
		dbus set ss_basic_version_web=$ss_basic_version_web1
		if [ "$ss_basic_version_local" != "$ss_basic_version_web1" ];then
		echo_date 主服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 不同！
			dbus set ss_basic_install_status="1"
			cd /tmp
			md5_web1=`curl -s "$main_url"/version | sed -n 2p`
			echo_date 开启下载进程，从主服务器上下载更新包...
			wget --no-check-certificate --timeout=5 "$main_url"/shadowsocks.tar.gz
			md5sum_gz=`md5sum /tmp/shadowsocks.tar.gz | sed 's/ /\n/g'| sed -n 1p`
			if [ "$md5sum_gz" != "$md5_web1" ]; then
				echo_date 更新包md5校验不一致！估计是下载的时候出了什么状况，请等待一会儿再试...
				dbus set ss_basic_install_status="4"
				rm -rf /tmp/shadowsocks* >/dev/null 2>&1
				sleep 1
				echo_date 更换备用更新服务器1，请稍后...
				dbus set ss_basic_install_status="8"
				sleep 1
				update_ss2
			else
				echo_date 更新包md5校验一致！ 开始安装！...
				install_ss
			fi
		else
			echo_date 主服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 相同！
			dbus set ss_basic_install_status="5"
			sleep 1
			echo_date 那还更新个毛啊，关闭更新进程!
			dbus set ss_basic_install_status="0"
			exit
		fi
	else
		echo_date 没有检测到主服务器在线版本号,访问github服务器有点问题哦~
		dbus set ss_basic_install_status="7"
		sleep 2
		echo_date 更换备用更新服务器1，请稍后...
		dbus set ss_basic_install_status="8"
		sleep 1
		update_ss2
	fi
}


update_ss2(){
	# ss_basic_install_status=	#
	# ss_basic_install_status=0	#
	# ss_basic_install_status=1	#正在下载更新......
	# ss_basic_install_status=2	#正在安装更新...
	# ss_basic_install_status=3	#安装更新成功，5秒后刷新本页！
	# ss_basic_install_status=4	#下载文件校验不一致！
	# ss_basic_install_status=5	#然而并没有更新！
	# ss_basic_install_status=6	#正在检查是否有更新~
	# ss_basic_install_status=7	#检测更新错误1！
	# ss_basic_install_status=8	#更换奔涌更新服务器1
	# ss_basic_install_status=9	#检测更新错误2！

	dbus set ss_basic_install_status="6"
	echo_date 开启SS检查更新：正在检测备用服务器在线版本号...
	ss_basic_version_web2=`curl --connect-timeout 5 -s "$backup_url"/version | sed -n 1p`
	if [ ! -z $ss_basic_version_web2 ];then
	echo_date 检测到备用服务器在线版本号：$ss_basic_version_web1
		dbus set ss_basic_version_web=$ss_basic_version_web2
		if [ "$ss_basic_version_local" != "$ss_basic_version_web2" ];then
		echo_date 备用服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 不同！
			dbus set ss_basic_install_status="1"
			cd /tmp
			md5_web2=`curl -s "$backup_url"/version | sed -n 2p`
			echo_date 开启下载进程，从备用服务器上下载更新包...
			wget "$backup_url"/shadowsocks.tar.gz
			md5sum_gz=`md5sum /tmp/shadowsocks.tar.gz | sed 's/ /\n/g'| sed -n 1p`
			if [ "$md5sum_gz" != "$md5_web2" ]; then
				echo_date 更新包md5校验不一致！估计是下载的时候除了什么状况，请等待一会儿再试...
				dbus set ss_basic_install_status="4"
				rm -rf /tmp/shadowsocks* >/dev/null 2>&1
				sleep 2
				echo_date 然而只有这一台备用更更新服务器，请尝试离线手动安装...
				dbus set ss_basic_install_status="0"
				exit
			else
				echo_date 更新包md5校验一致！ 开始安装！...
				install_ss
			fi
		else
			echo_date 备用服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 相同！
			dbus set ss_basic_install_status="5"
			sleep 2
			echo_date 那还更新个毛啊，关闭更新进程!
			dbus set ss_basic_install_status="0"
			exit
		fi
	else
		echo_date 没有检测到备用服务器在线版本号,访问备用服务器有点问题哦，你网络很差欸~
		dbus set ss_basic_install_status="7"
		sleep 2
		echo_date 然而只有这一台备用更更新服务器，请尝试离线手动安装...
		dbus set ss_basic_install_status="0"
		exit
	fi
}

# Enable service by user choose
apply_ss(){
	sh /koolshare/ss/stop.sh stop_all
	sh /koolshare/scripts/ss_prestart.sh
	sh /koolshare/ss/start.sh start_all
	# if [ "1" == "$ss_basic_action" ]; then
	# 	sh /koolshare/ss/stop.sh stop_part
	# 	sh /koolshare/scripts/ss_prestart.sh
	# 	sh /koolshare/ss/start.sh start_all
	# elif [ "2" == "$ss_basic_action" ]; then
	# 	sh /koolshare/ss/start.sh restart_dns
	# elif [ "3" == "$ss_basic_action" ]; then
	# 	sh /koolshare/ss/start.sh restart_wb_list
	# elif [ "4" == "$ss_basic_action" ]; then
	# 	sh /koolshare/ss/start.sh restart_addon
	# fi
	# dbus set ss_basic_action="1"
}

disable_ss(){
	sh /koolshare/ss/stop.sh stop_all
	dbus set ss_basic_action="1"
}

# write number into nvram with no commit
write_numbers(){
	nvram set update_ipset="$(cat /koolshare/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_cdn="$(cat /koolshare/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set ipset_numbers=$(cat /koolshare/ss/rules/gfwlist.conf | grep -c ipset)
	nvram set chnroute_numbers=$(cat /koolshare/ss/rules/chnroute.txt | grep -c .)
	nvram set cdn_numbers=$(cat /koolshare/ss/rules/cdn.txt | grep -c .)
}

set_ulimit(){
	ulimit -n 16384
}

case $ACTION in
start)
	if [ "$ss_basic_enable" == "1" ];then
		creat_folder
		set_ulimit
		apply_ss
    	write_numbers
	else
		echo ss not enabled
	fi
	;;
stop | kill )
	disable_ss
	echo_date
	echo_date 你已经成功关闭shadowsocks服务~
	echo_date See you again!
	echo_date
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	;;
restart)
	#disable_ss
	creat_folder
	set_ulimit
	apply_ss
	write_numbers
	echo_date
	echo_date Enjoy surfing internet without "Great Fire Wall"!
	echo_date
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	dbus fire onssstart
	dbus set ss_basic_install_status="0"
	;;
update)
	update_ss
	;;
*)
	echo "Usage: $0 (start|stop|restart|kill|reconfigure)"
	exit 1
	;;
esac
