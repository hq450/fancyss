#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh

LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME1=$(TZ=UTC-8 date -R "+%m-%d %H:%M:%S")
CURRENT=$(dbus get ssconf_basic_node)
CHK_INTER=$(dbus get ss_basic_interval)
COUNT=1
rm -rf /tmp/upload/test.txt

clean_f_log() {
	[ $(wc -l "$LOGFILE_F" | awk '{print $1}') -le "$LOG_MAX" ] && return
	local logdata=$(tail -n 500 "$LOGFILE_F")
	echo "$logdata" > $LOGFILE_F 2> /dev/null
	unset logdata
}

clean_c_log() {
	[ $(wc -l "$LOGFILE_C" | awk '{print $1}') -le "$LOG_MAX" ] && return
	local logdata=$(tail -n 500 "$LOGFILE_C")
	echo "$logdata" > $LOGFILE_C 2> /dev/null
	unset logdata
}

LOGM() {
	echo $1
	logger $1
}

_get_interval() {
	case "$CHK_INTER" in
	1)
		echo "0-1000"
		;;
	2)
		echo "2000-5000"
		;;
	3)
		echo "6000-13000"
		;;
	4)
		echo "14000-29000"
		;;
	5)
		echo "30000-61000"
		;;
	esac
}

failover_action(){
	FLAG=$1
	PING=$2
	if [ "$ss_failover_s4_1" == "0" ];then
		[ "$FLAG" == "1" ] && LOGM "$LOGTIME1 fancyss：检测到连续$ss_failover_s1个状态故障，关闭插件！"
		[ "$FLAG" == "2" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s2_1个状态中，故障次数超过$ss_failover_s2_2个，关闭插件！"
		[ "$FLAG" == "3" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s3_1个状态平均延迟:$PING超过$ss_failover_s3_2 ms，关闭插件！"
		dbus set ss_basic_enable="0"
		# 关闭
		dbus set ss_heart_beat="1"
		start-stop-daemon -S -q -b -x /koolshare/ss/ssconfig.sh -- stop
	elif [ "$ss_failover_s4_1" == "1" ];then
		[ "$FLAG" == "1" ] && LOGM "$LOGTIME1 fancyss：检测到连续$ss_failover_s1个状态故障，重启插件！"
		[ "$FLAG" == "2" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s2_1个状态中，故障次数超过$ss_failover_s2_2个，重启插件！"
		[ "$FLAG" == "3" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s3_1个状态平均延迟:$PING超过$ss_failover_s3_2 ms，重启插件！"
		# 重启
		start-stop-daemon -S -q -b -x /koolshare/ss/ssconfig.sh -- restart
	elif [ "$ss_failover_s4_1" == "2" ];then
		if [ "$ss_failover_s4_2" == "1" ];then
			[ "$FLAG" == "1" ] && LOGM "$LOGTIME1 fancyss：检测到连续$ss_failover_s1个状态故障，切换到备用节点：[$(dbus get ssconf_basic_name_$ss_failover_s4_3)]！同时把主节点降级为备用节点！"
			[ "$FLAG" == "2" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s2_1个状态中，故障次数超过$ss_failover_s2_2个，切换到备用节点：[$(dbus get ssconf_basic_name_$ss_failover_s4_3)]！同时把主节点降级为备用节点！"
			[ "$FLAG" == "3" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s3_1个状态平均延迟:$PING超过$ss_failover_s3_2 ms，切换到备用节点：[$(dbus get ssconf_basic_name_$ss_failover_s4_3)]！同时把主节点降级为备用节点！"
			# 切换
			dbus set ssconf_basic_node=$ss_failover_s4_3
			# 降级
			dbus set ss_failover_s4_3=$ssconf_basic_node
			# 重启
			dbus set ss_heart_beat="1"
			start-stop-daemon -S -q -b -x /koolshare/ss/ssconfig.sh -- restart
		elif [ "$ss_failover_s4_2" == "2" ];then
			NEXT_NODE=$(($ssconf_basic_node + 1))
			MAXT_NODE=$(dbus list ssconf_basic_|grep _name_ | cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)
			[ "$FLAG" == "1" ] && LOGM "$LOGTIME1 fancyss：检测到连续$ss_failover_s1个状态故障，切换到节点列表的下个节点：[$(dbus get ssconf_basic_name_$NEXT_NODE)]！"
			[ "$FLAG" == "2" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s2_1个状态中，故障次数超过$ss_failover_s2_2个，切换到节点列表的下个节点：[$(dbus get ssconf_basic_name_$NEXT_NODE)]！"
			[ "$FLAG" == "3" ] && LOGM "$LOGTIME1 fancyss：检测到最近$ss_failover_s3_1个状态平均延迟:$PING超过$ss_failover_s3_2 ms，切换到节点列表的下个节点：[$(dbus get ssconf_basic_name_$NEXT_NODE)]！"
			if [ "$MAXT_NODE" == "1" ];then
				LOGM "$LOGTIME1 fancyss：检测到你只有一个节点！无法切换到下一个节点！只好关闭插件了！"
				dbus set ss_basic_enable="0"
				start-stop-daemon -S -q -b -x /koolshare/ss/ssconfig.sh -- stop
			fi
			[ "$NEXT_NODE" -gt "$MAXT_NODE" ] && NEXT_NODE="1"
			# 切换
			dbus set ssconf_basic_node=$NEXT_NODE
			# 重启
			dbus set ss_heart_beat="1"
			start-stop-daemon -S -q -b -x /koolshare/ss/ssconfig.sh -- restart
		fi
	fi	
}

failover_check_1(){
	local LINES=$(($ss_failover_s1 + 3))
	local START_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$LINES" | grep "===")
	if [ -n "$START_MARK" ];then
		#echo "$LOGTIME1 fancyss：1-检测到前$LINES行刚提交，先不检测！"
		return
	fi
	
	local OK_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$ss_failover_s1" | grep -c "200 OK")
	if [ "$OK_MARK" == "0" ];then
		failover_action 1
	fi
}

failover_check_2(){
	local LINES=$(($ss_failover_s2_1 + 3))
	local START_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$LINES" | grep "===")
	if [ -n "$START_MARK" ];then
		#echo "$LOGTIME1 fancyss：2-检测到前$LINES行刚提交，先不检测！"
		return
	fi

	local OK_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$ss_failover_s2_1" | grep -vc "200 OK")
	if [ "$OK_MARK" -gt "$ss_failover_s2_2" ];then
		failover_action 2
	fi
}

failover_check_3(){
	local LINES=$(($ss_failover_s3_1 + 3))
	local START_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$LINES" | grep "===")
	if [ -n "$START_MARK" ];then
		#echo "$LOGTIME1 fancyss：3-检测到前$LINES行刚提交，先不检测！"
		return
	fi

	local OK_MARK=$(cat "$LOGFILE_F" | sed '/fancyss/d' | tail -n "$ss_failover_s3_1" | grep -E "200 OK"|sed 's/time=//g' | awk '{print $(NF-4)}' | awk '{sum+=$1} END {print sum/NR}' | awk '{printf "%.0f\n",$1}')
	#echo "$LOGTIME1 fancyss：前15次状态平均延迟：$OK_MARK ！"
	if [ "$OK_MARK" -gt "$ss_failover_s3_2" ];then
		failover_action 3 "$OK_MARK"
	fi
}

heath_check(){
	LOGTIME1=$(TZ=UTC-8 date -R "+%m-%d %H:%M:%S")
	
	[ "$ss_failover_enable" != "1" ] && return
	[ "$COUNT" -eq "2" ] && echo "$LOGTIME1 fancyss：跳过刚提交后的2个状态，从此处开始的状态用于故障检测"
	[ "$COUNT" -le "2" ] && return

	[ "$ss_failover_c1" == "1" ] && failover_check_1
	[ "$ss_failover_c2" == "1" ] && failover_check_2
	[ "$ss_failover_c3" == "1" ] && failover_check_3
}

main(){
	while : ; do
		# sleep 2s first in case of to early detection
		usleep 2000000
	
		# refresh dbus data in every loop
		eval $(dbus export ss_failover)
		LOG_MAX=$ss_failover_s5
		[ -z "$LOG_MAX" ] && LOG_MAX=2000
		
		# clean clog incase of log grow too big
		if [ -f "/tmp/upload/ssf_status.txt" ];then
			clean_f_log
			clean_c_log
		fi
		
		# exit loop when fancyss not enabled
		[ "`dbus get ss_basic_enable`" != "1" ] && exit
		
		if [ "`ps|grep ssconfig.sh|grep -v grep`" ] || [ "`ps|grep ss_v2ray.sh|grep -v grep`" ];then
			# wait until ssconfig.sh or ss_v2ray.sh finished running
			continue
		else
			# kill the last status script if exist
			killall curl >/dev/null 2>&1
			if [ -n "$(pidof ss_status.sh)" ];then
				kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
				echo $LOGTIME1 script run time out "[`dbus get ssconf_basic_name_$CURRENT`]" >> $LOGFILE_F
			fi
			# call ss_status.sh to get status, start-stop-daemon consume more cpu, use sh instead.
			# start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status.sh
			sh /koolshare/scripts/ss_status.sh "$COUNT"
		fi

		# do health check after result obtain
		heath_check >> $LOGFILE_F

		# conter
		let COUNT++
		
		# random sleep $(_get_interval) time
		local INTER=$(shuf -i $(_get_interval) -n 1)
		INTER=$(($INTER * 1000))
		#echo $LOGTIME1 $INTER >> /tmp/inter.txt
		usleep $INTER
	done
}

main
