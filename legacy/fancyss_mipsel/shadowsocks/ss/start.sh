#!/bin/sh
#--------------------------------------------------------------------------------------
# Variable definitions
eval `dbus export ss`
source /koolshare/scripts/base.sh
source helper.sh
ss_basic_password=`echo $ss_basic_password|base64_decode`
CONFIG_FILE=/koolshare/ss/ss.json
DNS_PORT=7913
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'
ISP_DNS=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
[ "$ss_dns_china" == "1" ] && [ ! -z "$ISP_DNS" ] && CDN="$ISP_DNS"
[ "$ss_dns_china" == "1" ] && [ -z "$ISP_DNS" ] && CDN="114.114.114.114"
[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
[ "$ss_dns_china" == "8" ] && CDN="112.124.47.27"
[ "$ss_dns_china" == "9" ] && CDN="114.215.126.16"
[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
[ "$ss_dns_china" == "12" ] && CDN="$ss_dns_china_user"

# try to resolv the ss server ip if it is domain...
resolv_server_ip(){
	IFIP=`echo $ss_basic_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	if [ -z "$IFIP" ];then
		echo_date 使用nslookup方式解析SS服务器的ip地址,解析dns：$ss_basic_dnslookup_server
		if [ "$ss_basic_dnslookup" == "1" ];then
			server_ip=`nslookup "$ss_basic_server" $ss_basic_dnslookup_server | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			if [ "$?" == "0" ]; then
				echo_date SS服务器的ip地址解析成功：$server_ip.
			else
				echo_date SS服务器域名解析失败！
				echo_date 尝试用resolveip方式解析...
				server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
				if [ "$?" == "0" ]; then
			    	echo_date SS服务器的ip地址解析成功：$server_ip.
				else
					echo_date 使用resolveip方式SS服务器域名解析失败！请更换nslookup解析方式的DNS地址后重试！
				fi
			fi
		else
			echo_date 使用resolveip方式解析SS服务器的ip地址.
			server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
		fi

		if [ ! -z "$server_ip" ];then
			ss_basic_server="$server_ip"
			dbus set ss_basic_server_ip="$server_ip"
			dbus set ss_basic_dns_success="1"
		else
			dbus remvoe ss_basic_server_ip
			echo_date SS服务器的ip地址解析失败，将由ss-redir自己解析.
			dbus set ss_basic_dns_success="0"
		fi
	else
		dbus set ss_basic_server_ip=$ss_basic_server
		echo_date 检测到你的SS服务器已经是IP格式：$ss_basic_server,跳过解析... 
		dbus set ss_basic_dns_success="1"
	fi
}
# create shadowsocks config file...
creat_ss_json(){
	if [ "$ss_basic_ss_obfs_host" != "" ];then
		if [ "$ss_basic_ss_obfs" == "http" ];then
			ARG_OBFS="obfs=http;obfs-host=$ss_basic_ss_obfs_host"
		elif [ "$ss_basic_ss_obfs" == "tls" ];then
			ARG_OBFS="obfs=tls;obfs-host=$ss_basic_ss_obfs_host"
		else
			ARG_OBFS=""
		fi
	else
		if [ "$ss_basic_ss_obfs" == "http" ];then
			ARG_OBFS="obfs=http"
		elif [ "$ss_basic_ss_obfs" == "tls" ];then
			ARG_OBFS="obfs=tls"
		else
			ARG_OBFS=""
		fi
	fi
	echo_date 创建SS配置文件到$CONFIG_FILE
	if [ "$ss_basic_use_rss" == "0" ];then
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_use_rss" == "1" ];then
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocol",
			    "protocol_param":"$ss_basic_rss_protocol_para",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_param",
			    "method":"$ss_basic_method"
			}
		EOF
	fi
}

start_sslocal(){
	echo_date ┣开启ss-local,为dns2socks提供socks5端口：23456
	if [ "$ss_basic_use_rss" == "1" ];then
		rss-local -b 0.0.0.0 -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
	elif  [ "$ss_basic_use_rss" == "0" ];then
		if [ "$ss_basic_ss_obfs" == "0" ];then
			ss-local -b 0.0.0.0 -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		else
			ss-local -b 0.0.0.0 -l 23456 -c $CONFIG_FILE -u --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/sslocal1.pid >/dev/null 2>&1
		fi
	fi
}

start_dns(){
	# Start DNS2SOCKS
	if [ "1" == "$ss_dns_foreign" ] || [ -z "$ss_dns_foreign" ]; then
		# start ss-local on port 23456
		start_sslocal
		echo_date 开启dns2socks，监听端口：23456
		dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNS_PORT > /dev/null 2>&1 &
	fi

	# Start ss-tunnel
	[ "$ss_sstunnel" == "1" ] && gs="208.67.220.220:53"
	[ "$ss_sstunnel" == "2" ] && gs="8.8.8.8:53"
	[ "$ss_sstunnel" == "3" ] && gs="8.8.4.4:53"
	[ "$ss_sstunnel" == "4" ] && gs="$ss_sstunnel_user"	
	if [ "2" == "$ss_dns_foreign" ];then
		if [ "$ss_basic_use_rss" == "1" ];then
			echo_date 开启ssr-tunnel...
			rss-tunnel -b 0.0.0.0 -c /koolshare/ss/ss.json -l $DNS_PORT -L "$gs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif  [ "$ss_basic_use_rss" == "0" ];then
			echo_date 开启ss-tunnel...
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$gs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			else
				ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$gs" -u --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		fi
	fi

	# Start dnscrypt-proxy
	if [ "3" == "$ss_dns_foreign" ];then
		echo_date 开启 dnscrypt-proxy，你选择了"$ss_opendns"节点.
		dnscrypt-proxy --local-address=127.0.0.1:$DNS_PORT --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R $ss_opendns >/dev/null 2>&1
	fi
	
	# Start pdnsd
	if [ "4" == "$ss_dns_foreign"  ]; then
		echo_date 开启 pdnsd，pdnsd进程可能会不稳定，请自己斟酌.
		echo_date 创建/koolshare/ss/pdnsd文件夹.
		mkdir -p /koolshare/ss/pdnsd
		if [ "$ss_pdnsd_method" == "1" ];then
			echo_date 创建pdnsd配置文件到/koolshare/ss/pdnsd/pdnsd.conf
			echo_date 你选择了-仅udp查询-，需要开启上游dns服务，以防止dns污染.
			cat > /koolshare/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="/koolshare/ss/pdnsd/";
					run_as="nobody";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=udp_only;
					min_ttl=$ss_pdnsd_server_cache_min;
					max_ttl=$ss_pdnsd_server_cache_max;
					timeout=10;
				}
				
				server {
					label= "RT-AC68U"; 
					ip = 127.0.0.1;
					port = 1099;
					root_server = on;   
					uptest = none;    
				}
				EOF
			if [ "$ss_pdnsd_udp_server" == "1" ];then
				echo_date 开启dns2socks作为pdnsd的上游服务器.
				start_sslocal
				dns2socks 127.0.0.1:23456 "$ss_pdnsd_udp_server_dns2socks" 127.0.0.1:1099 > /dev/null 2>&1 &
			elif [ "$ss_pdnsd_udp_server" == "2" ];then
				echo_date 开启dnscrypt-proxy作为pdnsd的上游服务器.
				dnscrypt-proxy --local-address=127.0.0.1:1099 --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R "$ss_pdnsd_udp_server_dnscrypt"
			elif [ "$ss_pdnsd_udp_server" == "3" ];then
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "1" ] && dns1="208.67.220.220:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "2" ] && dns1="8.8.8.8:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "3" ] && dns1="8.8.4.4:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "4" ] && dns1="$ss_pdnsd_udp_server_ss_tunnel_user"
				if [ "$ss_basic_use_rss" == "1" ];then
					echo_date 开启ssr-tunnel作为pdnsd的上游服务器.
					rss-tunnel -b 0.0.0.0 -c /koolshare/ss/ss.json -l 1099 -L "$dns1" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
				elif  [ "$ss_basic_use_rss" == "0" ];then
					echo_date 开启ss-tunnel作为pdnsd的上游服务器.
					if [ "$ss_basic_ss_obfs" == "0" ];then
						ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$dns1" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
					else
						ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$dns1" -u --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/sstunnel.pid >/dev/null 2>&1
					fi
				fi
			fi
		elif [ "$ss_pdnsd_method" == "2" ];then
			echo_date 创建pdnsd配置文件到/koolshare/ss/pdnsd/pdnsd.conf
			echo_date 你选择了-仅tcp查询-，使用"$ss_pdnsd_server_ip":"$ss_pdnsd_server_port"进行tcp查询.
			cat > /koolshare/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="/koolshare/ss/pdnsd/";
					run_as="nobody";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=tcp_only;
					min_ttl=$ss_pdnsd_server_cache_min;
					max_ttl=$ss_pdnsd_server_cache_max;
					timeout=10;
				}
				
				server {
					label= "RT-AC68U"; 
					ip = $ss_pdnsd_server_ip;
					port = $ss_pdnsd_server_port;
					root_server = on;   
					uptest = none;    
				}
				EOF
		fi
		
		chmod 644 /koolshare/ss/pdnsd/pdnsd.conf
		CACHEDIR=/koolshare/ss/pdnsd
		CACHE=/koolshare/ss/pdnsd/pdnsd.cache
		USER=nobody
		GROUP=nogroup
	
		if ! test -f "$CACHE"; then
			echo_date 创建pdnsd缓存文件.
			dd if=/dev/zero of=/koolshare/ss/pdnsd/pdnsd.cache bs=1 count=4 2> /dev/null
			chown -R $USER.$GROUP $CACHEDIR 2> /dev/null
		fi

		echo_date 启动pdnsd进程...
		pdnsd --daemon -c /koolshare/ss/pdnsd/pdnsd.conf -p /var/run/pdnsd.pid
	fi

	# Start chinadns
	if [ "5" == "$ss_dns_foreign" ];then
		echo_date ┏你选择了chinaDNS作为解析方案！
		[ "$ss_chinadns_china" == "1" ] && rcc="223.5.5.5"
		[ "$ss_chinadns_china" == "2" ] && rcc="223.6.6.6"
		[ "$ss_chinadns_china" == "3" ] && rcc="114.114.114.114"
		[ "$ss_chinadns_china" == "4" ] && rcc="114.114.115.115"
		[ "$ss_chinadns_china" == "5" ] && rcc="1.2.4.8"
		[ "$ss_chinadns_china" == "6" ] && rcc="210.2.4.8"
		[ "$ss_chinadns_china" == "7" ] && rcc="112.124.47.27"
		[ "$ss_chinadns_china" == "8" ] && rcc="114.215.126.16"
		[ "$ss_chinadns_china" == "9" ] && rcc="180.76.76.76"
		[ "$ss_chinadns_china" == "10" ] && rcc="119.29.29.29"
		[ "$ss_chinadns_china" == "11" ] && rcc="$ss_chinadns_china_user"

		if [ "$ss_chinadns_foreign_method" == "1" ];then
			[ "$ss_chinadns_foreign_dns2socks" == "1" ] && rcfd="208.67.220.220:53"
			[ "$ss_chinadns_foreign_dns2socks" == "2" ] && rcfd="8.8.8.8:53"
			[ "$ss_chinadns_foreign_dns2socks" == "3" ] && rcfd="8.8.4.4:53"
			[ "$ss_chinadns_foreign_dns2socks" == "4" ] && rcfd="$ss_chinadns_foreign_dns2socks_user"
			
			start_sslocal
			echo_date ┣开启dns2socks，作为chinaDNS上游国外dns，转发dns：$rcfd
			dns2socks 127.0.0.1:23456 "$rcfd" 127.0.0.1:1055 > /dev/null 2>&1 &
		elif [ "$ss_chinadns_foreign_method" == "2" ];then
			echo_date ┣开启 dnscrypt-proxy，作为chinaDNS上游国外dns，你选择了"$ss_chinadns_foreign_dnscrypt"节点.
			dnscrypt-proxy --local-address=127.0.0.1:1055 --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R $ss_chinadns_foreign_dnscrypt >/dev/null 2>&1
		elif [ "$ss_chinadns_foreign_method" == "3" ];then
			[ "$ss_chinadns_foreign_sstunnel" == "1" ] && rcfs="208.67.220.220:53"
			[ "$ss_chinadns_foreign_sstunnel" == "2" ] && rcfs="8.8.8.8:53"
			[ "$ss_chinadns_foreign_sstunnel" == "3" ] && rcfs="8.8.4.4:53"
			[ "$ss_chinadns_foreign_sstunnel" == "4" ] && rcfs="$ss_chinadns_foreign_sstunnel_user"
			if [ "$ss_basic_use_rss" == "1" ];then
				echo_date ┣开启ssr-tunnel，作为chinaDNS上游国外dns，转发dns：$rcfs
				rss-tunnel -b 127.0.0.1 -c /koolshare/ss/ss.json -l 1055 -L "$rcfs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			elif  [ "$ss_basic_use_rss" == "0" ];then
				echo_date ┣开启ss-tunnel，作为chinaDNS上游国外dns，转发dns：$rcfs
				if [ "$ss_basic_ss_obfs" == "0" ];then
					ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l 1055 -L "$rcfs" -u -f /var/run/sstunnel.pid
				else
					ss-tunnel -b 0.0.0.0 -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l 1055 -L "$rcfs" -u --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/sstunnel.pid >/dev/null 2>&1
				fi
			fi
		elif [ "$ss_chinadns_foreign_method" == "4" ];then
			echo_date ┣你选择了自定义chinadns国外dns！dns：$ss_chinadns_foreign_method_user
		fi
		echo_date ┗开启chinadns进程！
		chinadns -p $DNS_PORT -s "$rcc",127.0.0.1:1055 -m -d -c /koolshare/ss/rules/chnroute.txt  >/dev/null 2>&1 &
	fi
}
#--------------------------------------------------------------------------------------
load_cdn_site(){
	# append china site
	rm -rf /tmp/sscdn.conf


	if [ "$ss_dns_plan" == "2" ] && [ "$ss_dns_foreign" != "5" ] && [ "$ss_dns_foreign" != "6" ];then
		echo_date 生成cdn加速列表到/tmp/sscdn.conf，加速用的dns：$CDN
		echo "#for china site CDN acclerate" >> /tmp/sscdn.conf
		cat /koolshare/ss/rules/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/sscdn.conf
	fi

	# append user defined china site
	if [ ! -z "$ss_isp_website_web" ];then
		cdnsites=$(echo $ss_isp_website_web | base64_decode)
		echo_date 生成自定义cdn加速域名到/tmp/sscdn.conf
		echo "#for user defined china site CDN acclerate" >> /tmp/sscdn.conf
		for cdnsite in $cdnsites
		do
			echo "$cdnsite" | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" >> /tmp/sscdn.conf
		done
	fi
}

custom_dnsmasq(){
	rm -rf /tmp/custom.conf
	if [ ! -z "$ss_dnsmasq" ];then
		echo_date 添加自定义dnsmasq设置到/tmp/custom.conf
		echo "$ss_dnsmasq" | base64_decode | sort -u >> /tmp/custom.conf
	fi
}

append_white_black_conf(){
	# append white domain list, bypass ss
	rm -rf /tmp/wblist.conf
	# github need to go ss
	if [ "$ss_basic_mode" != "6" ];then
		echo "#for router itself" >> /tmp/wblist.conf
		echo "server=/.google.com.tw/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.google.com.tw/router" >> /tmp/wblist.conf
		echo "server=/.github.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.com/router" >> /tmp/wblist.conf
		echo "server=/.github.io/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.io/router" >> /tmp/wblist.conf
		echo "server=/.raw.githubusercontent.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.raw.githubusercontent.com/router" >> /tmp/wblist.conf
		echo "server=/.adblockplus.org/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.adblockplus.org/router" >> /tmp/wblist.conf
	fi
	# append white domain list,not through ss
	wanwhitedomain=$(echo $ss_wan_white_domain | base64_decode)
	if [ ! -z $ss_wan_white_domain ];then
		echo_date 应用域名白名单
		echo "#for white_domain" >> /tmp/wblist.conf
		for wan_white_domain in $wanwhitedomain
		do 
			echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/wblist.conf
			echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_ip/g" >> /tmp/wblist.conf
		done
	fi
	
	# apple 和microsoft不能走ss
	echo "#for special site" >> /tmp/wblist.conf
	for wan_white_domain2 in "apple.com" "microsoft.com"
	do 
		echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
		echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_ip/g" >> /tmp/wblist.conf
	done
	
	# append black domain list,through ss
	wanblackdomain=$(echo $ss_wan_black_domain | base64_decode)
	if [ ! -z $ss_wan_black_domain ];then
		echo_date 应用域名黑名单
		echo "#for black_domain" >> /tmp/wblist.conf
		for wan_black_domain in $wanblackdomain
		do 
			echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/wblist.conf
			echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_ip/g" >> /tmp/wblist.conf
		done
	fi
}

ln_conf(){
	# custom dnsmasq
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	if [ -f /tmp/custom.conf ];then
		#echo_date 创建域自定义dnsmasq配置文件软链接到/jffs/configs/dnsmasq.d/custom.conf
		ln -sf /tmp/custom.conf /jffs/configs/dnsmasq.d/custom.conf
	fi
	
	# custom dnsmasq
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	if [ -f /tmp/wblist.conf ];then
		#echo_date 创建域名黑/白名单软链接到/jffs/configs/dnsmasq.d/wblist.conf
		mv -f /tmp/wblist.conf /jffs/configs/dnsmasq.d/wblist.conf
	fi
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	if [ -f /tmp/sscdn.conf ];then
		#echo_date 创建cdn加速列表软链接/jffs/configs/dnsmasq.d/cdn.conf
		mv -f /tmp/sscdn.conf /jffs/configs/dnsmasq.d/cdn.conf
	fi

	gfw_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep 1`
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	if [ "$ss_basic_mode" == "1" ];then
		echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	elif [ "$ss_basic_mode" == "2" ] || [ "$ss_basic_mode" == "3" ];then
		if [ ! -f /jffs/configs/dnsmasq.d/gfwlist.conf ] && [ "$ss_dns_plan" == "1" ] || [ -n "$gfw_on" ];then
			echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
			ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
		fi
	fi

	#echo_date 创建dnsmasq.postconf软连接到/jffs/scripts/文件夹.
	rm -rf /jffs/scripts/dnsmasq.postconf
	ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq.postconf
}
	

#--------------------------------------------------------------------------------------
nat_auto_start(){
	mkdir -p /jffs/scripts
	# creating iptables rules to nat-start
	if [ ! -f /jffs/scripts/nat-start ]; then
	cat > /jffs/scripts/nat-start <<-EOF
		#!/bin/sh
		dbus fire onnatstart
		
		EOF
	fi
	
	writenat=$(cat /jffs/scripts/nat-start | grep "nat-start")
	if [ -z "$writenat" ];then
		echo_date 添加nat-start触发事件...用于ss的nat规则重启后或网络恢复后的加载.
		[ $ss_basic_sleep -ne 0 ] && \
		sed -i "2a sleep $ss_basic_sleep" /jffs/scripts/nat-start
		[ $ss_basic_sleep -ne 0 ] && \
		sed -i '3a sh /koolshare/ss/nat-start.sh start_all' /jffs/scripts/nat-start || \
		sed -i '2a sh /koolshare/ss/nat-start.sh start_all' /jffs/scripts/nat-start
		chmod +x /jffs/scripts/nat-start
	fi
}
#--------------------------------------------------------------------------------------
wan_auto_start(){
	# Add service to auto start
	if [ ! -f /jffs/scripts/wan-start ]; then
		cat > /jffs/scripts/wan-start <<-EOF
			#!/bin/sh
			dbus fire onwanstart
			
			EOF
	fi
	
	startss=$(cat /jffs/scripts/wan-start | grep "/koolshare/scripts/ss_config.sh")
	if [ -z "$startss" ];then
		echo_date 添加wan-start触发事件...用于ss的各种程序的开机启动，启动延迟$ss_basic_sleep
		[ $ss_basic_sleep -ne 0 ] && \
		sed -i "2a sleep $ss_basic_sleep" /jffs/scripts/wan-start
		[ $ss_basic_sleep -ne 0 ] && \
		sed -i '3a sh /koolshare/scripts/ss_config.sh' /jffs/scripts/wan-start || \
		sed -i '2a sh /koolshare/scripts/ss_config.sh' /jffs/scripts/wan-start
	fi
	chmod +x /jffs/scripts/wan-start
}

#=======================================================================================

start_ss_redir(){
	# Start ss-redir
	if [ "$ss_basic_use_rss" == "1" ];then
		echo_date 开启ssr-redir进程，用于透明代理.
		rss-redir -b 0.0.0.0 -c $CONFIG_FILE -f /var/run/shadowsocks.pid >/dev/null 2>&1
	elif  [ "$ss_basic_use_rss" == "0" ];then
		echo_date 开启ss-redir进程，用于透明代理.
		if [ "$ss_basic_ss_obfs" == "0" ];then
			ss-redir -b 0.0.0.0 -c $CONFIG_FILE -f /var/run/shadowsocks.pid >/dev/null 2>&1
		else
			ss-redir -b 0.0.0.0 -c $CONFIG_FILE --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/shadowsocks.pid >/dev/null 2>&1
		fi
	fi
}

write_cron_job(){
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date 添加ss规则定时更新任务，每天"$ss_basic_rule_update_time"自动检测更新规则.
		cru a ssupdate "0 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date ss规则定时更新任务未启用！
	fi
}

kill_cron_job(){
	jobexist=`cru l|grep ssupdate`
	if [ ! -z "$jobexist" ];then
		echo_date 删除ss规则定时更新任务.
		sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}


stop_dns(){
	dnscrypt=$(ps | grep "dnscrypt-proxy" | grep -v "grep")
	pdnsd=$(ps | grep "pdnsd" | grep -v "grep")
	chinadns=$(ps | grep "chinadns" | grep -v "grep")
	DNS2SOCK=$(ps | grep "dns2socks" | grep -v "grep")
	Pcap_DNSProxy=$(ps | grep "Pcap_DNSProxy" | grep -v "grep")
	PID_DNS_SH=$(ps |grep "/koolshare/ss/dns/dns.sh" | grep -v "grep" |awk '{print $1}')
	sstunnel=$(ps | grep "ss-tunnel" | grep -v "grep" | grep -vw "rss-tunnel")
	rsstunnel=$(ps | grep "rss-tunnel" | grep -v "grep" | grep -vw "ss-tunnel")
	# kill dnscrypt-proxy
	if [ ! -z "$dnscrypt" ]; then 
		echo_date 关闭dnscrypt-proxy进程...
		killall dnscrypt-proxy
	fi
	# kill ss-tunnel
	if [ ! -z "$sstunnel" ]; then 
		echo_date 关闭ss-tunnel进程...
		killall ss-tunnel >/dev/null 2>&1
	fi
	if [ ! -z "$rsstunnel" ]; then 
		echo_date 关闭rss-tunnel进程...
		killall rss-tunnel >/dev/null 2>&1
	fi
	# kill pdnsd
	if [ ! -z "$pdnsd" ]; then 
		echo_date 关闭pdnsd进程...
		killall pdnsd
	fi
	# kill chinadns
	if [ ! -z "$chinadns" ]; then 
		echo_date 关闭chinadns进程...
		killall chinadns
	fi
	# kill dns2socks
	if [ ! -z "$DNS2SOCK" ]; then 
		echo_date 关闭dns2socks进程...
		killall dns2socks
	fi
}

#---------------------------------------------------------------------------------------------------------

load_nat(){
	nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	i=120
	until [ -n "$nat_ready" ]
	do
	    i=$(($i-1))
	    if [ "$i" -lt 1 ];then
	        echo_date "错误：不能正确加载nat规则!"
	        sh /koolshare/ss/stop.sh stop_all
	        exit
	    fi
	    sleep 2
	done
	echo_date "加载nat规则!"
	sh /koolshare/ss/nat-start.sh start_all
}

restart_dnsmasq(){
	# Restart dnsmasq
	echo_date 重启dnsmasq服务...
	/sbin/service restart_dnsmasq >/dev/null 2>&1
}

remove_status(){
	nvram set ss_foreign_state=""
	nvram set ss_china_state=""
}

main_portal(){
	if [ "$ss_main_portal" == "1" ];then
		nvram set enable_ss=1
		nvram commit
	else
		nvram set enable_ss=0
		nvram commit
	fi
}

load_module(){
	xt=`lsmod | grep xt_set`
	OS=$(uname -r)
	if [ -f /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko ] && [ -z "$xt" ];then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
}

restart_addon(){
	#ss_basic_action=4
	echo_date ----------------------------- 重启附加功能 -----------------------------
	# for sleep walue in start up files
	old_sleep=`cat /jffs/scripts/nat-start | grep sleep | awk '{print $2}'`
	new_sleep="$ss_basic_sleep"
	if [ "$old_sleep" = "$new_sleep" ];then
		echo_date 开机延迟时间未改变，仍然是"$ss_basic_sleep"秒.
	else
		echo_date 设置"$ss_basic_sleep"秒开机延迟...
		# delete boot delay in nat-start and wan-start
		sed -i '/koolshare/d' /jffs/scripts/nat-start >/dev/null 2>&1
		sed -i '/sleep/d' /jffs/scripts/nat-start >/dev/null 2>&1
		sed -i '/koolshare/d' /jffs/scripts/wan-start >/dev/null 2>&1
		sed -i '/sleep/d' /jffs/scripts/wan-start >/dev/null 2>&1
		# re add delay in nat-start and wan-start
		nat_auto_start >/dev/null 2>&1
		wan_auto_start >/dev/null 2>&1
	fi
	
	#remove_status
	remove_status
	main_portal
	
	if [ "$ss_basic_dnslookup" == "1" ];then
		echo_date 设置使用nslookup方式解析SS服务器的ip地址.
	else
		echo_date 设置使用resolveip方式解析SS服务器的ip地址.
	fi
	echo_date -------------------------- 附加功能重启完毕！ ---------------------------
}


case $1 in
start_all)
	#ss_basic_action=1
	echo_date ------------------------- 梅林固件 shadowsocks --------------------------
	resolv_server_ip
	creat_ss_json
	#creat_dnsmasq_basic_conf
	load_cdn_site
	custom_dnsmasq
	append_white_black_conf && ln_conf
	nat_auto_start
	wan_auto_start
	write_cron_job
	start_dns
	start_ss_redir
	load_module
	load_nat
	restart_dnsmasq
	remove_status
	nvram set ss_mode=2
	nvram commit
	echo_date ------------------------- shadowsocks 启动完毕 -------------------------
	[ "$ss_basic_action" == "4" ] && restart_addon
	;;
*)
	echo "Usage: $0 (start_all)"
	exit 1
	;;
esac
