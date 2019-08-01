#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

remove_first(){
	confs2=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
	for conf in $confs2
	do
		echo_date 移除$conf
		dbus remove $conf
	done
}

upgrade_ss_conf(){
	nodes=`dbus list ssc|grep port|cut -d "=" -f1|cut -d "_" -f4|sort -n`
	for node in $nodes
	do
		if [ "`dbus get ssconf_basic_use_rss_$node`" == "1" ];then
			#ssr
			dbus remove ssconf_basic_ss_v2ray_plugin_$node
			dbus remove ssconf_basic_ss_v2ray_plugin_opts_$node
			dbus remove ssconf_basic_koolgame_udp_$node
		else
			if [ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ];then
				#koolgame
				dbus remove ssconf_basic_rss_protocol_$node
				dbus remove ssconf_basic_rss_protocol_param_$node
				dbus remove ssconf_basic_rss_obfs_$node
				dbus remove ssconf_basic_rss_obfs_param_$node
				dbus remove ssconf_basic_ss_v2ray_plugin_$node
				dbus remove ssconf_basic_ss_v2ray_plugin_opts_$node
			else
				#ss
				dbus remove ssconf_basic_rss_protocol_$node
				dbus remove ssconf_basic_rss_protocol_param_$node
				dbus remove ssconf_basic_rss_obfs_$node
				dbus remove ssconf_basic_rss_obfs_param_$node
				dbus remove ssconf_basic_koolgame_udp_$node
				[ -z "`dbus get ssconf_basic_ss_v2ray_plugin_$node`" ] && dbus set ssconf_basic_ss_v2ray_plugin_$node="0"
			fi
		fi
		dbus remove ssconf_basic_use_rss_$node
	done
	
	use_node=`dbus get ssconf_basic_node`
	[ -z "$use_node" ] && use_node="1"
	dbus remove ss_basic_server
	dbus remove ss_basic_mode
	dbus remove ss_basic_port
	dbus remove ss_basic_method
	dbus remove ss_basic_ss_v2ray_plugin
	dbus remove ss_basic_ss_v2ray_plugin_opts
	dbus remove ss_basic_rss_protocol
	dbus remove ss_basic_rss_protocol_param
	dbus remove ss_basic_rss_obfs
	dbus remove ss_basic_rss_obfs_param
	dbus remove ss_basic_koolgame_udp
	dbus remove ss_basic_use_rss
	dbus remove ss_basic_use_kcp
	sleep 1
	[ -n "`dbus get ssconf_basic_server_$node`" ] && dbus set ss_basic_server=`dbus get ssconf_basic_server_$node`
	[ -n "`dbus get ssconf_basic_mode_$node`" ] && dbus set ss_basic_mode=`dbus get ssconf_basic_mode_$node`
	[ -n "`dbus get ssconf_basic_port_$node`" ] && dbus set ss_basic_port=`dbus get ssconf_basic_port_$node`
	[ -n "`dbus get ssconf_basic_method_$node`" ] && dbus set ss_basic_method=`dbus get ssconf_basic_method_$node`
	[ -n "`dbus get ssconf_basic_ss_v2ray_plugin_$node`" ] && dbus set ss_basic_ss_v2ray_plugin=`dbus get ssconf_basic_ss_v2ray_plugin_$node`
	[ -n "`dbus get ssconf_basic_ss_v2ray_plugin_opts_$node`" ] && dbus set ss_basic_ss_v2ray_plugin_opts=`dbus get ssconf_basic_ss_v2ray_plugin_opts_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_$node`" ] && dbus set ss_basic_rss_protocol=`dbus get ssconf_basic_rss_protocol_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_param_$node`" ] && dbus set ss_basic_rss_protocol_param=`dbus get ssconf_basic_rss_protocol_param_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_$node`" ] && dbus set ss_basic_rss_obfs=`dbus get ssconf_basic_rss_obfs_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_param_$node`" ] && dbus set ss_basic_rss_obfs_param=`dbus get ssconf_basic_rss_obfs_param_$node`
	[ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_koolgame_udp_$node`
	[ -n "`dbus get ssconf_basic_use_kcp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_use_kcp_$node`
}

remove_first

confs=`cat /tmp/ss_conf_backup.txt`
format=`echo $confs|grep "{"`
if [ -z "$format" ];then
	echo_date 检测到ss备份文件...
	cat /tmp/ss_conf_backup.txt | grep -E "^ss"| sed '/webtest/d' | sed '/ssid_/d' | sed '/ssserver_/d' | sed '/ping/d' |sed '/ss_node_table/d' | sed '/_state_/d' |	sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 i\\n' | sed '1 isource /koolshare/scripts/base.sh' | sed '1 i#!/bin/sh' > /tmp/ss_conf_backup_tmp.sh
	echo_date 开始恢复配置...
	chmod +x /tmp/ss_conf_backup_tmp.sh
	sh /tmp/ss_conf_backup_tmp.sh
	sleep 2
	backup_version=`dbus get ss_basic_version_local`
	[  -z "$backup_version" ] && backup_version="3.6.5"
	comp=`versioncmp $backup_version 3.6.5`
	if [ "$comp" == "1" ];then
		echo_date 检测到备份文件来自低于3.6.5版本，开始对部分数据进行升级，以适应新版本！
		upgrade_ss_conf
	fi

	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
	echo_date 配置恢复成功！
else
	ss_formate=`echo $confs|grep "obfs"`
	if [ -z "$ss_formate" ];then

		echo_date 检测到ss json配置文件...
		servers=$(cat /tmp/ss_conf_backup.txt |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ss_conf_backup.txt |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ss_conf_backup.txt |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ss_conf_backup.txt |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ss_conf_backup.txt |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		
		# flush previous test value in the table
		echo_date 尝试移除旧的webtest结果...
		webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for line in $webtest
			do
				dbus remove "$line"
			done
		
		# flush previous ping value in the table
		echo_date 尝试移除旧的ping测试结果...
		pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for ping in $pings
			do
				dbus remove "$ping"
			done
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
		k=`expr $last_node + 1`
		else
		k=1
		fi
		min=1
		max=`cat /tmp/ss_conf_backup.txt |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	else
		echo_date 检测到ssr json配置文件...
		servers=$(cat /tmp/ss_conf_backup.txt |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ss_conf_backup.txt |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ss_conf_backup.txt |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ss_conf_backup.txt |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ss_conf_backup.txt |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		obfs=`cat /tmp/ss_conf_backup.txt |grep -w obfs|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		obfsparam=`cat /tmp/ss_conf_backup.txt |grep -w obfsparam|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		protocol=`cat /tmp/ss_conf_backup.txt |grep -w protocol|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|cut -d ":" -f 2`
		protocolparam=`cat /tmp/ss_conf_backup.txt |grep -w protocolparam|sed 's/"//g'|sed 's/,//g'|sed 's/\s//g'|sed 's/protocolparam://g'`
		
		# flush previous test value in the table
		echo_date 尝试移除旧的webtest结果...
		webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for line in $webtest
			do
				dbus remove "$line"
			done
		
		# flush previous ping value in the table
		echo_date 尝试移除旧的ping测试结果...
		pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
			for ping in $pings
			do
				dbus remove "$ping"
			done
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
		k=`expr $last_node + 1`
		else
		k=1
		fi
		min=1
		max=`cat /tmp/ss_conf_backup.txt |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			obf=`echo $obfs | awk "{print $"$min"}"`
			obfspara=`echo $obfsparam | awk "{print $"$min"}"`
			protoco=`echo $protocol | awk "{print $"$min"}"`
			protocolpara=`echo $protocolparam | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			echo_date $obf
			echo_date $obfspara
			echo_date $protoco
			echo_date $protocolpara
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_rss_obfs_"$k"="$obf"
			dbus set ssconf_basic_rss_obfs_param_"$k"="$obfspara"
			dbus set ssconf_basic_rss_protocol_"$k"="$protoco"
			dbus set ssconf_basic_rss_protocol_param_"$k"="$protocolpara"
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	fi
fi

echo_date 一点点清理工作...
sleep 1
rm -rf /tmp/ss_conf_*
echo_date 完成！