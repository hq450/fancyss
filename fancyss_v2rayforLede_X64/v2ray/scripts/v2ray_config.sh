#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
source $KSROOT/bin/helper.sh
eval `dbus export v2ray_`
alias echo_date='echo ��$(date +%Y��%m��%d��\ %X)��:'
lan_ipaddr=`uci get network.lan.ipaddr`
LOCK_FILE=/var/lock/v2ray.lock
LOG_FILE=/tmp/upload/v2ray_log.txt
ISP_DNS1=`cat /tmp/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p`
ISP_DNS2=`cat /tmp/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 3p`
KP_ENABLE=`dbus get koolproxy_enable`
V2RAY_CONFIG_FILE_TMP="/tmp/v2ray_tmp.json"
V2RAY_CONFIG_FILE="/koolshare/v2ray/v2ray.json"
set_lock(){
    exec 1000>"$LOCK_FILE"
    flock -x 1000
}
unset_lock(){
    flock -u 1000
    rm -rf "$LOCK_FILE"
}
get_lan_cidr(){
    netmask=`uci get network.lan.netmask`
    local x=${netmask##*255.}
    set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
    x=${1%%$3*}
    suffix=$(( $2 + (${#x}/4) ))
    prefix=`uci get network.lan.ipaddr | cut -d "." -f1,2,3`
    echo $prefix.0/$suffix
}
create_dnsmasq_conf(){
    local CDN IFIP_DNS wanwhitedomain wanblackdomain IFIP_DNS1 IFIP_DNS2
    IFIP_DNS=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
    [ -n "$IFIP_DNS" ] && CDN="$ISP_DNS1" || CDN="114.114.114.114"
    [ "$v2ray_dns_china" == "2" ] && CDN="223.5.5.5"
    [ "$v2ray_dns_china" == "3" ] && CDN="223.6.6.6"
    [ "$v2ray_dns_china" == "4" ] && CDN="114.114.114.114"
    [ "$v2ray_dns_china" == "5" ] && CDN="114.114.115.115"
    [ "$v2ray_dns_china" == "6" ] && CDN="1.2.4.8"
    [ "$v2ray_dns_china" == "7" ] && CDN="210.2.4.8"
    [ "$v2ray_dns_china" == "8" ] && CDN="112.124.47.27"
    [ "$v2ray_dns_china" == "9" ] && CDN="114.215.126.16"
    [ "$v2ray_dns_china" == "10" ] && CDN="180.76.76.76"
    [ "$v2ray_dns_china" == "11" ] && CDN="119.29.29.29"
    [ "$v2ray_dns_china" == "12" ] && CDN="$v2ray_dns_china_user"
    # append china site
    [ ! -f /tmp/dnsmasq.d/v2raycdn.conf -a "$v2ray_dns_plan" == "2" ] && {
        echo_date ��������CDN�����Ż������ļ�
        cat $KSROOT/v2ray/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' > /tmp/dnsmasq.d/v2raycdn.conf
    }
    [ ! -f /tmp/dnsmasq.d/v2raygfw.conf -a "$v2ray_dns_plan" == "1" -o "$v2ray_acl_default_mode" == "1" ] && {
        echo_date ��������GFW�����Ż������ļ�
        #cat $KSROOT/v2ray/gfwlist.conf | awk '{print "server=/"$1"/127.0.0.1#7913\nipset=/"$1"/black_list"}' >> /tmp/dnsmasq.d/v2raygfw.conf
        ln -sf $KSROOT/v2ray/gfwlist.conf /tmp/dnsmasq.d/v2raygfw.conf
    }
    if [ -n "$v2ray_dnsmasq" ];then
        echo_date ����Զ���dnsmasq���õ�/tmp/dnsmasq.d/v2raycustom.conf
        echo "$v2ray_dnsmasq" | base64_decode | sort -u >> /tmp/dnsmasq.d/v2raycustom.conf
    fi
    [ ! -f "/tmp/dnsmasq.d/v2rayroute.conf" ] && {
        echo_date ����״̬�������Ż������ļ�
		cat > /tmp/dnsmasq.d/v2rayroute.conf <<-EOF
			#for router itself
			server=/.google.com.tw/127.0.0.1#7913
			ipset=/.google.com.tw/router
			server=/.google.com.ncr/127.0.0.1#7913
			ipset=/.google.com.ncr/router
			server=/.github.com/127.0.0.1#7913
			ipset=/.github.com/router
			server=/.github.io/127.0.0.1#7913
			ipset=/.github.io/router
			server=/.raw.githubusercontent.com/127.0.0.1#7913
			ipset=/.raw.githubusercontent.com/router
			server=/.apnic.net/127.0.0.1#7913
			ipset=/.apnic.net/router
			server=/.s3.amazonaws.com/127.0.0.1#7913
			ipset=/.s3.amazonaws.com/router
			server=/.openwrt.org/127.0.0.1#7913
			ipset=/.openwrt.org/router
		EOF
    }
    # append white domain list,not through ss
    wanwhitedomain=$(echo $v2ray_wan_white_domain | base64_decode)
    if [ -n "$v2ray_wan_white_domain" ];then
        echo_date Ӧ������������
        echo "#for white_domain" >> /tmp/dnsmasq.d/v2raywblist.conf
        for wan_white_domain in $wanwhitedomain
        do
            echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN/g" >> /tmp/dnsmasq.d/v2raywblist.conf
            echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/dnsmasq.d/v2raywblist.conf
        done
    fi
    # apple ��microsoft�����ߴ���
    echo "#for special site" >> /tmp/dnsmasq.d/v2raywblist.conf
    for wan_white_domain2 in "apple.com" "microsoft.com"
    do
        echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN/g" >> /tmp/dnsmasq.d/v2raywblist.conf
        echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/dnsmasq.d/v2raywblist.conf
    done
    
    # append black domain list,through ss
    wanblackdomain=$(echo $v2ray_wan_black_domain | base64_decode)
    if [ -n "$v2ray_wan_black_domain" ];then
        echo_date Ӧ������������
        echo "#for black_domain" >> /tmp/dnsmasq.d/v2raywblist.conf
        for wan_black_domain in $wanblackdomain
        do
            echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/dnsmasq.d/v2raywblist.conf
            echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >> /tmp/dnsmasq.d/v2raywblist.conf
        done
    fi
    
    if [ "$v2ray_dns_china" == "1" ];then
        IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
        IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
        [ -n "$IFIP_DNS1" ] && CDN1="$ISP_DNS1" || CDN1="114.114.114.114"
        [ -n "$IFIP_DNS2" ] && CDN2="$ISP_DNS2" || CDN2="114.114.115.115"
    fi
    
    echo "no-resolv" >> /tmp/dnsmasq.d/v2ray.conf
    if [ "$v2ray_dns_plan" == "1" ] || [ -z "$v2ray_dns_china" ];then
        if [ "$v2ray_dns_china" == "1" ];then
            echo_date DNS���������������ȣ�ʹ����Ӫ��DNS���Ƚ�������DNS.
            echo "all-servers" >> /tmp/dnsmasq.d/v2ray.conf
            echo "server=$CDN1" >> /tmp/dnsmasq.d/v2ray.conf
            echo "server=$CDN2" >> /tmp/dnsmasq.d/v2ray.conf
        else
            echo_date DNS���������������ȣ�ʹ���Զ���DNS��$CDN���н�������DNS.
            echo "server=$CDN" >> /tmp/dnsmasq.d/v2ray.conf
        fi
        elif [ "$v2ray_dns_plan" == "2" ];then
        echo_date DNS���������������ȣ����Ƚ�������DNS.
        echo "server=127.0.0.1#7913" >> /tmp/dnsmasq.d/v2ray.conf
    fi
}
restore_dnsmasq_conf(){
    if [ -n "`ls /tmp/dnsmasq.d/v2ray*.conf 2>/dev/null`" ];then
        echo_date ɾ�� v2ray ��ص����������ļ�.
        rm -rf /tmp/dnsmasq.d/v2ray*.conf
    fi
}
restore_start_file(){
    echo_date ���firewall����ص� v2ray ��������...
	uci -q batch <<-EOT
	  delete firewall.ks_v2ray
	  commit firewall
	EOT
}
kill_process(){
    if [ -n "`pidof v2ray`" ]; then
        echo_date �ر� v2ray ����...
        killall v2ray >/dev/null 2>&1
    fi
}
auto_start(){
    # nat start
    echo_date ���nat-start�����¼�...
	uci -q batch <<-EOT
	  delete firewall.ks_v2ray
	  set firewall.ks_v2ray=include
	  set firewall.ks_v2ray.type=script
	  set firewall.ks_v2ray.path=/koolshare/scripts/v2ray_nat.sh
	  set firewall.ks_v2ray.family=any
	  set firewall.ks_v2ray.reload=1
	  commit firewall
	EOT
    # auto start
    [ ! -L "/etc/rc.d/S99v2ray.sh" ] && ln -sf $KSROOT/init.d/S99v2ray.sh /etc/rc.d/S99v2ray.sh
}
get_function_switch() {
    case "$1" in
        0)
            echo "false"
        ;;
        1)
            echo "true"
        ;;
    esac
}
get_auth_status() {
    case "$1" in
        1)
            echo "noauth"
        ;;
        2)
            echo "password"
        ;;
    esac
}
close_in_five(){
    echo_date "�������5����Զ��رգ���"
    sleep 1
    echo_date 5
    sleep 1
    echo_date 4
    sleep 1
    echo_date 3
    sleep 1
    echo_date 2
    sleep 1
    echo_date 1
    sleep 1
    echo_date 0
    dbus set v2ray_basic_enable="0"
    stop_v2ray >/dev/null
    echo_date "ĳЩ�ϰ汾�̼��Ѿ��޷�ʹ���°����������������°�̼�ʹ�ã�"
    echo_date "����ѹرգ���"
    echo_date ------------------------- v2ray �ɹ��ر� -------------------------
    echo XU6J03M6
    http_response "233"
    unset_lock
    exit
}
get_dns_user(){
    if [ -n "$v2ray_dns_foreign_user" ];then
        if [ -n "`echo $v2ray_dns_foreign_user|grep :`" ];then
            echo $v2ray_dns_foreign_user | cut -d ":" -f1
        else
            echo $v2ray_dns_foreign_user
        fi
    else
        echo "8.8.8.8"
    fi
}
get_dns_port(){
    if [ "$v2ray_dns_foreign" == "4" ];then
        if [ -n "$v2ray_dns_foreign_user" ];then
            if [ -n "`echo $v2ray_dns_foreign_user|grep :`" ];then
                echo $v2ray_dns_foreign_user | cut -d ":" -f2
            else
                echo "53"
            fi
        else
            echo "53"
        fi
    else
        echo "53"
    fi
}
gen_v2ray_config(){
    local KDF server_tag server_config JSON_INFO TEMPLATE result resultstatus TEMSOCKS TEMHTTP TEMSS TEMAUTH
    [ "$v2ray_dns_foreign" == "1" ] && KDF="208.67.220.220"
    [ "$v2ray_dns_foreign" == "2" ] && KDF="8.8.8.8"
    [ "$v2ray_dns_foreign" == "3" ] && KDF="8.8.4.4"
    [ "$v2ray_dns_foreign" == "4" ] && KDF="$(get_dns_user)"
    rm -rf "$V2RAY_CONFIG_FILE_TMP"
    rm -rf "$V2RAY_CONFIG_FILE"
    if [ "$v2ray_basic_type" == "1" ]; then
        server_tag=$(dbus get "v2ray_server_tag_$v2ray_basic_server")
        server_config=$(dbus get "v2ray_server_config_$v2ray_basic_server")
    else
        server_tag=$(dbus get "v2ray_sub_tag_$v2ray_basic_server")
        server_config=$(dbus get "v2ray_sub_config_$v2ray_basic_server")
    fi
    echo_date ʹ�� $server_tag �����ļ�...
    
    echo $server_config | base64_decode > "$V2RAY_CONFIG_FILE_TMP"
    if [ "$v2ray_basic_sbmode" == "1" ]; then
        JSON_INFO=`cat "$V2RAY_CONFIG_FILE_TMP" | jq 'del (.inbound) | del (.inbounds) | del (.inboundDetour) | del (.log)'`
    else
        JSON_INFO=`cat "$V2RAY_CONFIG_FILE_TMP" | jq 'del (.inbound) | del (.inbounds) | del (.inboundDetour) | del (.log) | del (.routing)'`
    fi
    #OUTBOUND=`cat "$V2RAY_CONFIG_FILE_TMP" | jq .outbound`
    #INBOUND_TAG=`cat "$V2RAY_CONFIG_FILE_TMP" | jq '.inbound.tag'
    #INBOUND_DETOUR_TAG=`cat "$V2RAY_CONFIG_FILE_TMP" | jq '.inbound.tag'
    if [ "$v2ray_service_auth" == "2" ]; then
        TEMAUTH="{
            \"user\": \"$v2ray_service_username\",
            \"pass\": \"$v2ray_service_passwd\"
        }"
    else
        TEMAUTH=""
    fi
    if [ "$v2ray_basic_socks" == "1" ]; then
        echo_date ���������ؾ���������Զ���û����ӵ�socks5������������˿�1281
        TEMSOCKS="{
            \"tag\": \"socks5\",
            \"protocol\": \"socks\",
            \"port\": 1281,
            \"settings\": {
                \"auth\": \"$(get_auth_status $v2ray_service_auth)\",
                \"accounts\": [
                    $TEMAUTH
                ],
                \"userLevel\": 0,
                \"ip\": \"0.0.0.0\",
                \"udp\": true
            },
            \"sniffing\": {
                \"enabled\": $(get_function_switch $v2ray_basic_sniffing),
                \"destOverride\": [
                    \"http\",
                    \"tls\"
                ]
            }
        },"
    else
        TEMSOCKS=""
    fi
    if [ "$v2ray_basic_http" == "1" ]; then
        echo_date ���������ؾ���������Զ���û����ӵ�http������������˿�1282
        TEMHTTP="{
            \"tag\": \"http\",
            \"protocol\": \"http\",
            \"port\": 1282,
            \"settings\": {
                \"accounts\": [
                    $TEMAUTH
                ],
                \"timeout\": 0,
                \"userLevel\": 0,
                \"allowTransparent\": false
            },
            \"sniffing\": {
                \"enabled\": $(get_function_switch $v2ray_basic_sniffing),
                \"destOverride\": [
                    \"http\",
                    \"tls\"
                ]
            }
        },"
    else
        TEMHTTP=""
    fi
    if [ "$v2ray_basic_ss" == "1" ]; then
        echo_date ���������ؾ���������Զ���û����ӵ�shadowsocks������������˿�1283
        TEMSS="{
            \"tag\": \"shadowsocks\",
            \"protocol\": \"shadowsocks\",
            \"port\": 1283,
            \"settings\": {
                \"method\": \"$v2ray_service_ssmethod\",
                \"password\": \"$v2ray_service_sspasswd\",
                \"udp\": true,
                \"level\": 0,
                \"ota\": false
            }
        },"
    else
        TEMSS=""
    fi
    local TEMPLATE="{
        \"log\":{
            \"access\":\"/dev/null\",
            \"error\":\"/tmp/v2ray_log.log\",
            \"loglevel\":\"error\"
        },
        \"inbounds\": [
            {
                \"tag\": \"tproxy\",
                \"protocol\": \"dokodemo-door\",
                \"listen\": \"0.0.0.0\",
                \"port\": 1280,
                \"settings\": {
                    \"network\": \"tcp,udp\",
                    \"followRedirect\": true
                },
                \"sniffing\": {
                    \"enabled\": $(get_function_switch $v2ray_basic_sniffing),
                    \"destOverride\": [
                        \"http\",
                        \"tls\"
                    ]
                }
            },$TEMHTTP$TEMSOCKS$TEMSS
            {
                \"tag\": \"dns\",
                \"protocol\": \"dokodemo-door\",
                \"port\": 7913,
                \"settings\": {
                    \"address\": \"$KDF\",
                    \"port\": $(get_dns_port),
                    \"network\": \"udp\",
                    \"timeout\": 0,
                    \"followRedirect\": false
                }
            }
        ]
    }"
    echo_date ����V2Ray�����ļ�...
    #echo $TEMPLATE | jq --argjson args "$OUTBOUND" '. + {outbound: $args}' > "$V2RAY_CONFIG_FILE"
    echo $TEMPLATE | jq --argjson args "$JSON_INFO" '. + $args' > "$V2RAY_CONFIG_FILE"
    
    echo_date V2Ray�����ļ�д��ɹ���"$V2RAY_CONFIG_FILE"
    # ����û�json�ķ�����ip��ַ
    v2ray_protocal=`cat "$V2RAY_CONFIG_FILE" | jq -r 'outbound.protocol'`
    [ -z "$v2ray_protocal" -o "$v2ray_protocal" == "null" ] && v2ray_protocal=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbounds[0].protocol'`
    case $v2ray_protocal in
        vmess)
            v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbound.settings.vnext[0].address'`
        ;;
        socks)
            v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbound.settings.servers[0].address'`
        ;;
        shadowsocks)
            v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbound.settings.servers[0].address'`
        ;;
        *)
            v2ray_server=""
        ;;
    esac
    [ -z "$v2ray_server" -o "$v2ray_server" == "null" ] && {
        case $v2ray_protocal in
            vmess)
                v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbounds[0].settings.vnext[0].address'`
            ;;
            socks)
                v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbounds[0].settings.servers[0].address'`
            ;;
            shadowsocks)
                v2ray_server=`cat "$V2RAY_CONFIG_FILE" | jq -r '.outbounds[0].settings.servers[0].address'`
            ;;
            *)
                v2ray_server=""
            ;;
        esac
    }
    if [ -n "$v2ray_server" -a "$v2ray_server" != "null" ];then
        IFIP_VS=`echo $v2ray_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
        if [ -n "$IFIP_VS" ];then
            v2ray_basic_server_ip="$v2ray_server"
            echo_date "��⵽���json���õ�v2ray�������ǣ�$v2ray_server"
        else
            echo_date "��⵽���json���õ�v2ray��������$v2ray_server����ip��ʽ��"
            echo_date "���Խ���v2ray��������ip��ַ..."
            # ��������ַǿ����114��������������δ��ʼ���������½���ʧ��
            echo "server=/$v2ray_server/114.114.114.114" > /tmp/dnsmasq.d/v2ray_server.conf
            v2ray_server_ip=`nslookup "$v2ray_server" 114.114.114.114 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
            if [ "$?" == "0" ]; then
                v2ray_server_ip=`echo $v2ray_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
            else
                echo_date v2ray��������������ʧ�ܣ�
                echo_date ������resolveip��ʽ����...
                v2ray_server_ip=`resolveip -4 -t 2 $v2ray_server|awk 'NR==1{print}'`
                if [ "$?" == "0" ];then
                    v2ray_server_ip=`echo $v2ray_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
                fi
            fi
            if [ -n "$v2ray_server_ip" ];then
                echo_date "v2ray��������ip��ַ�����ɹ���$v2ray_server_ip"
                #echo "address=/$v2ray_server/$v2ray_server_ip" > /tmp/dnsmasq.d/v2ray_host.conf
                v2ray_basic_server_ip="$v2ray_server_ip"
            else
                echo_date "v2ray��������ip��ַ����ʧ��!������������У�������������v2ray�Լ����У�"
                echo_date "�����н�v2ray��������ip��ַ����IP/CIDR��������!"
                echo_date "Ϊ��ȷ��v2ray��������������������ip��ʽ��v2ray��������ַ��"
            fi
        fi
    else
        echo_date "û�м�⵽���v2ray��������ַ�������ȷ�������������ȷ��"
        echo_date "�����н�v2ray��������ip��ַ���롾IP/CIDR���������У���ȷ������ʹ��"
    fi
    echo_date ����V2Ray�����ļ�.....
    cd /koolshare/bin
    result=$(v2ray -test -config="$V2RAY_CONFIG_FILE_TMP" | grep "Configuration OK.")
    if [ -n "$result" ];then
        echo_date $result
        if [ -s "$V2RAY_CONFIG_FILE" ];then
            echo_date V2Ray�����ļ�ͨ������!!!
        else
            echo_date V2Ray�����ļ�ͨ�����ԣ����̼��汾���ͣ��޷���ȷ���������ļ��������������¹̼���
            close_in_five
        fi
    else
        #rm -rf "$V2RAY_CONFIG_FILE_TMP"
        #rm -rf "$V2RAY_CONFIG_FILE"
        echo_date V2Ray�����ļ�û��ͨ�����ԣ���������!!!
        resultstatus=$(v2ray -test -config="$V2RAY_CONFIG_FILE_TMP" | tail -n +3)
        echo_date ����ԭ��$resultstatus
        close_in_five
    fi
}
start_v2ray(){
    optimized_network
    gen_v2ray_config
    echo_date ���� v2ray ������...
    cd /koolshare/bin
    v2ray --config=/koolshare/v2ray/v2ray.json >/dev/null 2>&1 &
    
    local i=10
    until [ -n "$V2PID" ]
    do
        i=$(($i-1))
        V2PID=`pidof v2ray`
        if [ "$i" -lt 1 ];then
            echo_date "v2ray��������ʧ�ܣ�"
            close_in_five
        fi
        sleep 1
    done
    echo_date v2ray�����ɹ���pid��$V2PID
}
# =======================================================================================================
flush_nat(){
    local ip_nat_exist ip_mangle_exist chromecast_nu ip_rule_exist service_exist
    echo_date ����������Ѵ��ڵ�iptables���򣬷�ֹ�ظ����
    # flush rules and set if any
    ip_nat_exist=`iptables -t nat -L PREROUTING | grep -c V2RAY`
    ip_mangle_exist=`iptables -t mangle -L PREROUTING | grep -c V2RAY`
    if [ "$ip_nat_exist" -ne 0 ]; then
        for i in `seq $ip_nat_exist`
        do
            iptables -t nat -D OUTPUT -j V2RAY > /dev/null 2>&1
            iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1280 > /dev/null 2>&1
            iptables -t nat -D PREROUTING -p tcp -j V2RAY > /dev/null 2>&1
            echo_date ���NAT����
        done
    fi
    if [ "$ip_mangle_exist" -ne 0 ]; then
        for i in `seq $ip_mangle_exist`
        do
            iptables -t mangle -D PREROUTING -j V2RAY > /dev/null 2>&1
            echo_date ���Mangle����
        done
    fi
    sleep 1
    chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'|head -1`
    [ "$KP_ENABLE" == "1" ] || iptables -t nat -D PREROUTING $chromecast_nu > /dev/null 2>&1
    iptables -t nat -F V2RAY > /dev/null 2>&1 && iptables -t nat -X V2RAY > /dev/null 2>&1
    iptables -t mangle -F V2RAY > /dev/null 2>&1 && iptables -t mangle -X V2RAY > /dev/null 2>&1
    iptables -t mangle -F V2RAY_GFW > /dev/null 2>&1 && iptables -t mangle -X V2RAY_GFW > /dev/null 2>&1
    iptables -t mangle -F V2RAY_CHN > /dev/null 2>&1 && iptables -t mangle -X V2RAY_CHN > /dev/null 2>&1
    iptables -t mangle -F V2RAY_GAM > /dev/null 2>&1 && iptables -t mangle -X V2RAY_GAM> /dev/null 2>&1
    iptables -t mangle -F V2RAY_GLO > /dev/null 2>&1 && iptables -t mangle -X V2RAY_GLO > /dev/null 2>&1
    
    service_exist=`iptables -L zone_wan_input | grep -c "softcenter:v2ray"`
    if [ ! -z "$service_exist" ];then
        until [ "$service_exist" = 0 ]
        do
            relay_nu=`iptables -L zone_wan_input -v -n --line-numbers|grep "softcenter:v2ray"|awk '{print $1}'|head -1`
            iptables -D zone_wan_input $relay_nu >/dev/null 2>&1
            service_exist=`expr $service_exist - 1`
        done
    fi
    
    #flush_ipset
    echo_date ������Ѵ��ڵ�ipset��������ֹ�ظ����
    ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
    ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
    ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
    ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
    ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
    #remove_redundant_rule
    ip_rule_exist=`ip rule show | grep "fwmark 0x1/0x1 lookup 310" | grep -c 310`
    if [ ! -z "ip_rule_exist" ];then
        echo_date ����ظ���ip rule����.
        until [ "$ip_rule_exist" = "0" ]
        do
            #ip rule del fwmark 0x07 table 310
            ip rule del fwmark 0x07 table 310 pref 789
            ip_rule_exist=`expr $ip_rule_exist - 1`
        done
    fi
    # remove_route_table
    echo_date ɾ��ip route����.
    ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}
# creat ipset rules
creat_ipset(){
    echo_date ����ipset����
    ipset -! create white_list nethash && ipset flush white_list
    ipset -! create black_list nethash && ipset flush black_list
    ipset -! create gfwlist nethash && ipset flush gfwlist
    ipset -! create router nethash && ipset flush router
    ipset -! create chnroute nethash && ipset flush chnroute
    sed -e "s/^/add chnroute &/g" $KSROOT/v2ray/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}
add_white_black_ip(){
    # black ip/cidr
    local ip_tg
    ip_tg="67.198.55.0/24 91.108.4.0/22 91.108.12.0/22 91.108.56.0/22 91.108.8.0/22 93.119.240.0/20 109.239.140.0/24 149.154.0.0/16 149.154.160.0/20"
    for ip in $ip_tg
    do
        ipset -! add black_list $ip >/dev/null 2>&1
    done
    
    if [ ! -z $v2ray_wan_black_ip ];then
        v2ray_wan_black_ip=`dbus get v2ray_wan_black_ip|base64_decode|sed '/\#/d'`
        echo_date Ӧ��IP/CIDR������
        for ip in $v2ray_wan_black_ip
        do
            ipset -! add black_list $ip >/dev/null 2>&1
        done
    fi
    
    # white ip/cidr
    #ip1=$(nvram get wan0_ipaddr | cut -d"." -f1,2)
    [ ! -z "$v2ray_basic_server_ip" ] && SERVER_IP=$v2ray_basic_server_ip || SERVER_IP=""
    ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 $SERVER_IP 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 $ISP_DNS1 $ISP_DNS2"
    for ip in $ip_lan
    do
        ipset -! add white_list $ip >/dev/null 2>&1
    done
    
    if [ ! -z $v2ray_wan_white_ip ];then
        v2ray_wan_white_ip=`echo $v2ray_wan_white_ip|base64_decode|sed '/\#/d'`
        echo_date Ӧ��IP/CIDR������
        for ip in $v2ray_wan_white_ip
        do
            ipset -! add white_list $ip >/dev/null 2>&1
        done
    fi
}
get_action_chain() {
    case "$1" in
        0)
            echo "RETURN"
        ;;
        1)
            echo "V2RAY_GFW"
        ;;
        2)
            echo "V2RAY_CHN"
        ;;
        3)
            echo "V2RAY_GAM"
        ;;
        4)
            echo "V2RAY_GLO"
        ;;
    esac
}
get_mode_name() {
    case "$1" in
        0)
            echo "��ͨ������"
        ;;
        1)
            echo "gfwlistģʽ"
        ;;
        2)
            echo "��½������ģʽ"
        ;;
        3)
            echo "��Ϸģʽ"
        ;;
        4)
            echo "ȫ��ģʽ"
        ;;
    esac
}
factor(){
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo ""
    else
        echo "$2 $1"
    fi
}
get_jump_mode(){
    case "$1" in
        0)
            echo "j"
        ;;
        *)
            echo "g"
        ;;
    esac
}
lan_acess_control(){
    # lan access control
    local acl_nu ipaddr proxy_mode proxy_name mac
    acl_nu=`dbus list v2ray_acl_mode|sort -n -t "=" -k 2|cut -d "=" -f 1 | cut -d "_" -f 4`
    if [ -n "$acl_nu" ]; then
        for acl in $acl_nu
        do
            ipaddr=`dbus get v2ray_acl_ip_$acl`
            proxy_mode=`dbus get v2ray_acl_mode_$acl`
            proxy_name=`dbus get v2ray_acl_name_$acl`
            mac=`dbus get v2ray_acl_mac_$acl`
            [ -n "$ipaddr" ] && [ -z "$mac" ] && echo_date ����ACL���򣺡�$ipaddr��ģʽΪ��$(get_mode_name $proxy_mode)
            [ -z "$ipaddr" ] && [ -n "$mac" ] && echo_date ����ACL���򣺡�$mac��ģʽΪ��$(get_mode_name $proxy_mode)
            [ -n "$ipaddr" ] && [ -n "$mac" ] && echo_date ����ACL���򣺡�$ipaddr����$mac��ģʽΪ��$(get_mode_name $proxy_mode)
            # acl in v2ray
            iptables -t mangle -A V2RAY $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
        done
        echo_date ����ACL������������ģʽΪ��$(get_mode_name $v2ray_acl_default_mode)
    else
        #v2ray_acl_default_mode="1"
        echo_date ����ACL��������ģʽΪ��$(get_mode_name $v2ray_acl_default_mode)
    fi
}
apply_nat_rules(){
    local PR_INDEX KP_INDEX
    #----------------------BASIC RULES---------------------
    echo_date д��iptables����mangle����...
    # ����v2ray mangle rule
    iptables -t mangle -N V2RAY
    iptables -t mangle -A PREROUTING -j V2RAY
    # IP/cidr/������ ���������ƣ����ߴ��� for v2ray
    iptables -t mangle -A V2RAY -m set --match-set white_list dst -j RETURN
    # MARK 2019 for v2ray
    #iptables -t mangle -A V2RAY -m mark --mark 0x7e3 -j RETURN
    #-----------------------FOR GFWLIST---------------------
    # ����gfwlistģʽ
    iptables -t mangle -N V2RAY_GFW
    # IP/CIDR/������ ���������ƣ��ߴ���
    iptables -t mangle -A V2RAY_GFW -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
    iptables -t mangle -A V2RAY_GFW -p tcp -m set --match-set gfwlist dst -j TTL --ttl-set 188
    #-----------------------FOR CHNMODE---------------------
    # ������½������ģʽ
    iptables -t mangle -N V2RAY_CHN
    iptables -t mangle -A V2RAY_CHN -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
    if [ "$v2ray_bypass" == "2" ];then
        iptables -t mangle -A V2RAY_CHN -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
    else
        iptables -t mangle -A V2RAY_CHN -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
    fi
    #-----------------------FOR GLOABLE---------------------
    # ����ȫ��ģʽ
    iptables -t mangle -N V2RAY_GLO
    # ȫ��ģʽ����-ȫ�֣��ߴ���
    iptables -t mangle -A V2RAY_GLO -p tcp -j TTL --ttl-set 188
    
    #-----------------------FOR GAMEMODE---------------------
    # ������Ϸģʽ
    iptables -t mangle -N V2RAY_GAM
    iptables -t mangle -A V2RAY_GAM -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
    if [ "$v2ray_bypass" == "2" ];then
        iptables -t mangle -A V2RAY_GAM -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
    else
        iptables -t mangle -A V2RAY_GAM -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
    fi
    # ��ϷģʽUDP
    ip rule add fwmark 0x07 table 310 pref 789
    ip route add local 0.0.0.0/0 dev lo table 310
    iptables -t mangle -A V2RAY_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 1280 --tproxy-mark 0x07
    # cidr����������-chnroute���ߴ���
    if [ "$v2ray_bypass" == "2" ];then
        iptables -t mangle -A V2RAY_GAM -p udp -m geoip ! --destination-country CN -j TPROXY --on-port 1280 --tproxy-mark 0x07
    else
        iptables -t mangle -A V2RAY_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 1280 --tproxy-mark 0x07
    fi
    #-------------------------------------------------------
    # �����������������ߴ���/���������������ߴ���
    lan_acess_control
    # �����ʣ�������ض�����Ӧģʽ��nat���жԶ�Ӧ����ģʽ����
    iptables -t mangle -A V2RAY -j $(get_action_chain $v2ray_acl_default_mode)
    #-----------------------NAT�����-----------------------
    iptables -t nat -N V2RAY
    # MARK 2019 for v2ray
    #iptables -t nat -A V2RAY -p tcp -m mark --mark 0x7e3 -j RETURN
    iptables -t nat -A V2RAY -p tcp -m ttl --ttl-eq 188 -j REDIRECT --to 1280
    PR_INDEX=`iptables -t nat -L PREROUTING|tail -n +3|sed -n -e '/^prerouting_rule/='`
    [ -n "$PR_INDEX" ] && let RULE_INDEX=$PR_INDEX+1
    KP_INDEX=`iptables -t nat -L PREROUTING|tail -n +3|sed -n -e '/^KOOLPROXY/='`
    [ -n "$KP_INDEX" ] && let RULE_INDEX=$KP_INDEX+1
    #ȷ����ӵ�Ĭ�Ϲ���֮��
    iptables -t nat -I PREROUTING $RULE_INDEX -p tcp -j V2RAY
    #-----------------------FOR ROUTER״̬���---------------------
    # router itself
    if [ "$KP_ENABLE" == "1" -o "$v2ray_acl_default_mode" == "0" ]; then
        iptables -t nat -I OUTPUT -j V2RAY
    else
        echo_date ��ǰ����ǽ����Ϊ��KPģʽ������KP����Ҫ����V2ray!
    fi
    iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1280
    #-----------------------FOR ��������˿�Զ������---------------------
    [ "$v2ray_basic_forward" == "1" ] && {
        [ "$v2ray_basic_socks" == "1" ] && {
            iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1281 -m comment --comment "softcenter:v2ray" -j ACCEPT >/dev/null 2>&1
            iptables -I zone_wan_input 2 -p udp -m udp --dport 1281 -m comment --comment "softcenter:v2ray" -j ACCEPT >/dev/null 2>&1
        }
        [ "$v2ray_basic_http" == "1" ] && {
            iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1282 -m comment --comment "softcenter:v2ray" -j ACCEPT >/dev/null 2>&1
        }
        [ "$v2ray_basic_ss" == "1" ] && {
            iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1283 -m comment --comment "softcenter:v2ray" -j ACCEPT >/dev/null 2>&1
            iptables -I zone_wan_input 2 -p udp -m udp --dport 1283 -m comment --comment "softcenter:v2ray" -j ACCEPT >/dev/null 2>&1
        }
    }
}
chromecast(){
    local chromecast_nu is_right_lanip
    chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
    is_right_lanip=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53" |grep "$lan_ipaddr"`
    if [ "$v2ray_basic_dns_chromecast" == "1" ]; then
        if [ -z "$chromecast_nu" -o -z "$is_right_lanip" ]; then
            [ -z "$is_right_lanip" ] && iptables -t nat -D PREROUTING $chromecast_nu >/dev/null 2>&1
            iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
            echo_date ����chromecast���ܣ�DNS�ٳֹ��ܣ�
        else
            echo_date DNS�ٳֹ����Ѵ��ڣ�����~
        fi
    else
        echo_date DNS�ٳֹ������ò�����������~
    fi
}
optimized_network(){
    echo_date �Ż��������
    ulimit -HSn 102400
	cat > /tmp/net_optimized.conf <<-EOF
		fs.file-max = 51200
		net.core.rmem_max = 67108864
		net.core.wmem_max = 67108864
		net.core.rmem_default=65536
		net.core.wmem_default=65536
		net.core.netdev_max_backlog = 4096
		net.core.somaxconn = 4096
		net.ipv4.tcp_syncookies = 1
		net.ipv4.tcp_tw_reuse = 1
		net.ipv4.tcp_tw_recycle = 0
		net.ipv4.tcp_fin_timeout = 30
		net.ipv4.tcp_keepalive_time = 1200
		net.ipv4.ip_local_port_range = 10000 65000
		net.ipv4.tcp_max_syn_backlog = 4096
		net.ipv4.tcp_max_tw_buckets = 5000
		net.ipv4.tcp_fastopen = 3
		net.ipv4.tcp_rmem = 4096 87380 67108864
		net.ipv4.tcp_wmem = 4096 65536 67108864
		net.ipv4.tcp_mtu_probing = 1
	EOF
    sysctl -p /tmp/net_optimized.conf >/dev/null 2>&1
    rm -rf /tmp/net_optimized.conf
}
# =======================================================================================================
load_nat(){
    echo_date "����nat����!"
    #flush_nat
    creat_ipset
    add_white_black_ip
    apply_nat_rules
    chromecast
}
restart_dnsmasq(){
    # Restart dnsmasq
    echo_date ����dnsmasq����...
    /etc/init.d/dnsmasq restart >/dev/null 2>&1
}
write_numbers(){
    [ -z "$v2ray_basic_version" ] && v2ray_basic_version="$(v2ray -version|cut -d" " -f 2|sed -n 1p)"
    
    ipset_numbers=`cat $KSROOT/v2ray/gfwlist.conf | grep -c ipset`
    chnroute_numbers=`cat $KSROOT/v2ray/chnroute.txt | grep -c .`
    cdn_numbers=`cat $KSROOT/v2ray/cdn.txt | grep -c .`
    
    update_ipset=`cat $KSROOT/v2ray/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
    update_chnroute=`cat $KSROOT/v2ray/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
    update_cdn=`cat $KSROOT/v2ray/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
    dbus set v2ray_basic_gfw_status="$ipset_numbers ���������°汾�� $update_ipset "
    dbus set v2ray_basic_chn_status="$chnroute_numbers ���������°汾�� $update_chnroute "
    dbus set v2ray_basic_cdn_status="$cdn_numbers ���������°汾�� $update_cdn "
}
detect_ss(){
    SS_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/SHADOWSOCKS/='` 2>/dev/null
    if [ -n "$SS_NU" ];then
        echo_date ��⵽�㿪����SS������
        echo_date v2ray���ܺ�SS���ã���ر�SS�����ñ��������
        echo_date �˳� v2ray ����...
        dbus set v2ray_basic_enable=0
        close_in_five
    else
        echo_date v2ray��������������~
    fi
}
get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}
check_update_v2ray(){
    local lastver oldver
    echo_date ��ʼ��� v2ray ���°汾������
    if [ "$v2ray_basic_check_releases" == "0" ]; then
        lastver=$(wget --no-check-certificate --timeout=8 --tries=2 -qO- "https://github.com/v2fly/v2ray-core/tags"| grep "/v2fly/v2ray-core/releases/tag/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//')
    else
        lastver=$(get_latest_release "v2fly/v2ray-core")
    fi
    oldver="v$(v2ray -version|cut -d" " -f 2|sed -n 1p)"
    if [ -n "$lastver" ]; then
        echo_date ��ǰ�汾��$oldver
        echo_date ���°汾��$lastver
        if [ "$lastver" == "$oldver" ]; then
            echo_date ��ǰ�Ѿ������°汾��
            dbus set v2ray_basic_version=$lastver
            sleep 3
            echo XU6J03M6
        else
            echo_date "׼�����������°汾����ʼ����"
            wget --no-check-certificate --timeout=8 -a $LOG_FILE --tries=2 -O - "https://github.com/v2fly/v2ray-core/releases/download/${lastver}/v2ray-linux-64.zip" > /tmp/v2ray_update.zip
            #curl -r 0-100 -L - "https://github.com/v2fly/v2ray-core/releases/download/${lastver}/v2ray-linux-64.zip" -o /tmp/v2ray_update.zip
            if [ "$?" -eq 0 ] ; then
                echo_date "���°汾�����أ�׼����װ"
                kill_process
                [ -d "/tmp/v2ray_update" ] && rm -rf /tmp/v2ray_update
                mkdir -p /tmp/v2ray_update
                unzip /tmp/v2ray_update.zip -d /tmp/v2ray_update
                cp -rf /tmp/v2ray_update/v2ray $KSROOT/bin/v2ray
                cp -rf /tmp/v2ray_update/v2ctl $KSROOT/bin/v2ctl
                chmod a+x $KSROOT/bin/v2ray
                chmod a+x $KSROOT/bin/v2ctl
                rm -rf /tmp/v2ray_update
                rm -rf /tmp/v2ray_update.zip
                echo_date "���°汾�Ѱ�װ��׼���������"
                dbus set v2ray_basic_version=$lastver
                restart_v2ray
            else
                echo_date "���°汾����ʧ�ܣ��������絽github����ͨ�����ԣ�"
                dbus set v2ray_basic_version=$oldver
                sleep 3
                echo XU6J03M6
            fi
        fi
    else
        echo_date ���°汾�ż��ʧ�ܣ��������絽github����ͨ�����ԣ�
        sleep 3
        echo XU6J03M6
    fi
}
#=====================
update_rule(){
    url_back="https://koolshare.ngrok.wang/maintain_files"
    url_main="https://raw.githubusercontent.com/hq450/fancyss/master/rules/"
    # version dectet
    version_gfwlist1=$(cat $KSROOT/v2ray/version | sed -n 1p | sed 's/ /\n/g'| sed -n 1p)
    version_chnroute1=$(cat $KSROOT/v2ray/version | sed -n 2p | sed 's/ /\n/g'| sed -n 1p)
    version_cdn1=$(cat $KSROOT/v2ray/version | sed -n 4p | sed 's/ /\n/g'| sed -n 1p)
    version_Routing1=$(cat $KSROOT/v2ray/version | sed -n 5p | sed 's/ /\n/g'| sed -n 1p)
    version_WhiteList1=$(cat $KSROOT/v2ray/version | sed -n 6p | sed 's/ /\n/g'| sed -n 1p)
    echo_date ��ʼ����koolss������ȴ�...
    wget --no-check-certificate --timeout=8 -qO - $url_main/version1 > /tmp/version1
    if [ "$?" == "0" ]; then
        echo_date ��⵽���߰汾�ļ�������...
    else
        echo_date û�м�⵽���߰汾�G�������Ƿ���github�����⣬ȥ��½������ģʽ���԰ɣ�
        rm -rf /tmp/version1
        exit
    fi
    
    online_content=$(cat /tmp/version1)
    if [ -z "$online_content" ];then
        rm -rf /tmp/version1
    fi
    
    git_line1=$(cat /tmp/version1 | sed -n 1p)
    git_line2=$(cat /tmp/version1 | sed -n 2p)
    git_line4=$(cat /tmp/version1 | sed -n 4p)
    git_line5=$(cat /tmp/version1 | sed -n 5p)
    git_line6=$(cat /tmp/version1 | sed -n 6p)
    
    version_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| sed -n 1p)
    version_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| sed -n 1p)
    version_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| sed -n 1p)
    version_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| sed -n 1p)
    version_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| sed -n 1p)
    
    md5sum_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
    md5sum_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
    md5sum_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
    md5sum_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
    md5sum_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
    
    # update gfwlist
    if [ "$v2ray_basic_gfwlist_update" == "1" ] || [ -n "$1" ];then
        echo_date " ---------------------------------------------------------------------------------------"
        if [ ! -z "$version_gfwlist2" ];then
            if [ "$version_gfwlist1" != "$version_gfwlist2" ];then
                echo_date ��⵽�°汾gfwlist����ʼ����...
                echo_date ����gfwlist����ʱ�ļ�...
                wget --no-check-certificate --timeout=8 -qO - $url_main/gfwlist.conf > /tmp/gfwlist.conf
                md5sum_gfwlist1=$(md5sum /tmp/gfwlist.conf | sed 's/ /\n/g'| sed -n 1p)
                if [ "$md5sum_gfwlist1"x = "$md5sum_gfwlist2"x ];then
                    echo_date ������ɣ�У��ͨ��������ʱ�ļ����ǵ�ԭʼgfwlist�ļ�
                    mv /tmp/gfwlist.conf $KSROOT/v2ray/gfwlist.conf
                    sed -i "1s/.*/$git_line1/" $KSROOT/v2ray/version
                    reboot="1"
                    echo_date �����³ɹ������gfwlist�ղ��Ѿ����µ�������Ŷ~
                else
                    echo_date ������ɣ�����У��û��ͨ����
                fi
            else
                echo_date ��⵽gfwlist���ذ汾�ź����߰汾����ͬ���ǻ����¸�ë��!
            fi
        else
            echo_date gfwlist�ļ�����ʧ�ܣ�
        fi
    fi
    
    
    # update chnroute
    if [ "$v2ray_basic_chnroute_update" == "1" ] || [ -n "$1" ];then
        echo_date " ---------------------------------------------------------------------------------------"
        if [ ! -z "$version_chnroute2" ];then
            if [ "$version_chnroute1" != "$version_chnroute2" ];then
                echo_date ��⵽�°汾chnroute����ʼ����...
                echo_date ����chnroute����ʱ�ļ�...
                wget --no-check-certificate --timeout=8 -qO - $url_main/chnroute.txt > /tmp/chnroute.txt
                md5sum_chnroute1=$(md5sum /tmp/chnroute.txt | sed 's/ /\n/g'| sed -n 1p)
                if [ "$md5sum_chnroute1"x = "$md5sum_chnroute2"x ];then
                    echo_date ������ɣ�У��ͨ��������ʱ�ļ����ǵ�ԭʼchnroute�ļ�
                    mv /tmp/chnroute.txt $KSROOT/v2ray/chnroute.txt
                    sed -i "2s/.*/$git_line2/" $KSROOT/v2ray/version
                    reboot="1"
                    echo_date �����³ɹ������chnroute�ղ��Ѿ����µ�������Ŷ~
                else
                    echo_date md5sum ������ɣ�����У��û��ͨ����
                fi
            else
                echo_date ��⵽chnroute���ذ汾�ź����߰汾����ͬ���ǻ����¸�ë��!
            fi
        else
            echo_date chnroute�ļ�����ʧ�ܣ�
        fi
    fi
    
    # update cdn file
    if [ "$v2ray_basic_cdn_update" == "1" ] || [ -n "$1" ];then
        echo_date " ---------------------------------------------------------------------------------------"
        if [ ! -z "$version_cdn2" ];then
            if [ "$version_cdn1" != "$version_cdn2" ];then
                echo_date ��⵽�°汾cdn��������ʼ����...
                echo_date ����cdn��������ʱ�ļ�...
                wget --no-check-certificate --timeout=8 -qO - $url_main/cdn.txt > /tmp/cdn.txt
                md5sum_cdn1=$(md5sum /tmp/cdn.txt | sed 's/ /\n/g'| sed -n 1p)
                if [ "$md5sum_cdn1"x = "$md5sum_cdn2"x ];then
                    echo_date ������ɣ�У��ͨ��������ʱ�ļ����ǵ�ԭʼcdn�����ļ�
                    mv /tmp/cdn.txt $KSROOT/v2ray/cdn.txt
                    sed -i "4s/.*/$git_line4/" $KSROOT/v2ray/version
                    reboot="1"
                    echo_date �����³ɹ������cdn�����ղ��Ѿ����µ�������Ŷ~
                else
                    echo_date ������ɣ�����У��û��ͨ����
                fi
            else
                echo_date ��⵽cdn�������ذ汾�ź����߰汾����ͬ���ǻ����¸�ë��!
            fi
        else
            echo_date cdn�����ļ�����ʧ�ܣ�
        fi
    fi
    rm -rf /tmp/gfwlist.conf1
    rm -rf /tmp/chnroute.txt1
    rm -rf /tmp/cdn.txt1
    rm -rf /tmp/version1
    
    echo_date ������½���������ϣ�
    # write number
    ipset_numbers=`cat $KSROOT/v2ray/gfwlist.conf | grep -c ipset`
    chnroute_numbers=`cat $KSROOT/v2ray/chnroute.txt | grep -c .`
    cdn_numbers=`cat $KSROOT/v2ray/cdn.txt | grep -c .`
    
    update_ipset=`cat $KSROOT/v2ray/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
    update_chnroute=`cat $KSROOT/v2ray/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
    update_cdn=`cat $KSROOT/v2ray/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
    dbus set v2ray_basic_gfw_status="$ipset_numbers ���������°汾�� $update_ipset "
    dbus set v2ray_basic_chn_status="$chnroute_numbers ���������°汾�� $update_chnroute "
    dbus set v2ray_basic_cdn_status="$cdn_numbers ���������°汾�� $update_cdn "
    
    # reboot ss
    if [ "$reboot" == "1" ];then
        echo_date �Զ�����koolss����Ӧ���µĹ����ļ������Ժ�
        $KSROOT/scripts/v2ray_config.sh start
    fi
    echo =======================================================================================================
}
rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(date +%s%N)
    echo $(($num%$max+$min))
}
v2ray_watchdog_status(){
    local rnd newname
    /usr/bin/wget -4 --spider --quiet --tries=2 --timeout=3 www.google.com.tw
    [ "$?" == "0" ] || {
        /usr/bin/wget -4 --spider --quiet --tries=2 --timeout=3 www.baidu.com
        [ "$?" == "0" ] && {
            if [ "$v2ray_basic_watchdog_mod" == "1" ]; then
                restart_by_nat >/dev/null 2>&1
                echo_date ��V2ray�ػ�����⵽V2ray���ӳ������������ >> $LOG_FILE
            else
                if [ "$v2ray_basic_type" == "1" ]; then
                    rnd=$(rand 1 $v2ray_server_node_max)
                    dbus set v2ray_basic_server="$rnd"
                    newname=$(dbus get "v2ray_server_tag_$rnd")
                else
                    rnd=$(rand 1 $v2ray_sub_node_max)
                    dbus set v2ray_basic_server="$rnd"
                    newname=$(dbus get "v2ray_sub_tag_$rnd")
                fi
                restart_by_nat >/dev/null 2>&1
                echo_date ��V2ray�ػ�����⵽V2ray���ӳ�������л�����������$newname�� >> $LOG_FILE
            fi
        }
    }
}
set_v2ray_watchdog(){
    if [ "$v2ray_basic_watchdog" == "1" ]; then
        sed -i '/v2raywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
        echo "*/$v2ray_basic_watchdog_time * * * * /koolshare/scripts/v2ray_config.sh watchdog #v2raywatchdog#" >> /etc/crontabs/root
        echo_date "����V2ray�ػ��������$v2ray_basic_watchdog_time����"
        check_cron
    else
        sed -i '/v2raywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
        echo_date V2ray�ػ�δ����
    fi
}
set_v2ray_cron(){
    if [ "$v2ray_basic_cron" == "1" -a "$v2ray_basic_enable" == "1" ]; then
        sed -i '/v2raytimeswitch/d' /etc/crontabs/root >/dev/null 2>&1
        echo "$v2ray_basic_cron_enableminute $v2ray_basic_cron_enablehour * * * /koolshare/scripts/v2ray_config.sh #v2raytimeswitch#" >> /etc/crontabs/root
        echo "$v2ray_basic_cron_disableminute $v2ray_basic_cron_disablehour * * * /koolshare/scripts/v2ray_config.sh stop #v2raytimeswitch#" >> /etc/crontabs/root
        echo_date "������$v2ray_basic_cron_enablehour:$v2ray_basic_cron_enableminute�Զ�����V2ray��$v2ray_basic_cron_disablehour:$v2ray_basic_cron_disableminute�Զ��ر�V2ray"
    else
        sed -i '/v2raytimeswitch/d' /etc/crontabs/root >/dev/null 2>&1
        echo_date V2ray�Զ�����δ����
    fi
}
stop_v2ray_watchdog(){
    sed -i '/v2raywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
    echo_date �ر�V2ray�ػ�
}
check_cron(){
    local crontab
    crontab=`pidof crond`
    [ -z "$crontab" ] && /etc/init.d/cron start >/dev/null 2>&1
}
clean_server_list(){
    local locallist configlist
    locallist=$(($(dbus list v2ray_server_|cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
    [ $locallist -ge $v2ray_server_node_max ] && {
        configlist=`expr $v2ray_server_node_max + 1`
        for i in $(seq $configlist $locallist)
        do
            dbus remove v2ray_server_tag_$i
            dbus remove v2ray_server_config_$i
        done
    }
}
#=====================
restart_v2ray(){
    ONSTART=`ps -l|grep $PPID|grep -v grep|grep S99v2ray`
    echo_date ---------------------- LEDE �̼� v2ray -----------------------
    detect_ss
    # stop first
    restore_dnsmasq_conf
    [ -z "$ONSTART" ] && restart_dnsmasq
    flush_nat
    restore_start_file
    kill_process
    # start
    create_dnsmasq_conf
    auto_start
    start_v2ray
    load_nat
    restart_dnsmasq
    write_numbers
    set_v2ray_watchdog
    set_v2ray_cron
    echo_date ------------------------- v2ray ������� -------------------------
}
stop_v2ray(){
    echo_date ---------------------- LEDE �̼� v2ray -----------------------
    stop_v2ray_watchdog
    set_v2ray_cron
    restore_dnsmasq_conf
    restart_dnsmasq
    flush_nat
    restore_start_file
    kill_process
    echo_date ------------------------- v2ray �ɹ��ر� -------------------------
}
restart_by_nat(){
    detect_ss
    restore_dnsmasq_conf
    kill_process
    flush_nat
    load_nat
    start_v2ray
    create_dnsmasq_conf
    restart_dnsmasq
}
# used by rc.d
case $1 in
    start)
        set_lock
        if [ "$v2ray_basic_enable" == "1" ];then
            restart_v2ray
        else
            stop_v2ray
        fi
        unset_lock
    ;;
    stop)
        set_lock
        stop_v2ray
        unset_lock
    ;;
    config)
        gen_v2ray_config
    ;;
    watchdog)
        v2ray_watchdog_status
    ;;
    *)
        set_lock
        [ -z "$2" ] && restart_by_nat
        unset_lock
    ;;
esac
# used by httpdb
case $2 in
    1)
        if [ "$v2ray_basic_enable" == "1" ];then
            restart_v2ray > $LOG_FILE
        else
            stop_v2ray > $LOG_FILE
        fi
        echo XU6J03M6 >> $LOG_FILE
        http_response $1
    ;;
    2)
        # remove all v2ray config in skipd
        echo_date ���Թر� v2ray... > $LOG_FILE
        sh $KSROOT/scripts/v2ray_config.sh stop
        echo_date ��ʼ���� v2ray ����... >> $LOG_FILE
        confs=`dbus list v2ray | cut -d "=" -f 1 | grep -v "version"`
        for conf in $confs
        do
            echo_date �Ƴ�$conf >> $LOG_FILE
            dbus remove $conf
        done
        echo_date ����һЩĬ�ϲ���... >> $LOG_FILE
        dbus set v2ray_basic_enable="0"
        echo_date ��ɣ� >> $LOG_FILE
        http_response $1
    ;;
    3)
        #��������
        echo "" > $LOG_FILE
        mkdir -p $KSROOT/webs/files
        dbus list v2ray | grep -v "status" | grep -v "enable" | grep -v "version" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 i\\n' | sed '1 isource /koolshare/scripts/base.sh' |sed '1 i#!/bin/sh' > $KSROOT/webs/files/v2ray_conf_backup.sh
        http_response "$1"
        echo XU6J03M6 >> $LOG_FILE
    ;;
    4)
        #�ñ��ݵ�v2ray_conf_backup.sh ȥ�ָ�����
        echo_date "��ʼ�ָ�v2ray����..." > $LOG_FILE
        file_nu=`ls /tmp/upload/v2ray_conf_backup | wc -l`
        i=20
        until [ -n "$file_nu" ]
        do
            i=$(($i-1))
            if [ "$i" -lt 1 ];then
                echo_date "����û���ҵ��ָ��ļ�!"
                echo XU6J03M6
                exit
            fi
            sleep 1
            file_nu=`ls /tmp/upload/v2ray_conf_backup | wc -l`
        done
        format=`cat /tmp/upload/v2ray_conf_backup.sh |grep dbus`
        if [ -n "format" ];then
            echo_date "��⵽��ȷ��ʽ�������ļ���" >> $LOG_FILE
            cd /tmp/upload
            chmod +x v2ray_conf_backup.sh
            echo_date "�ָ���..." >> $LOG_FILE
            sh v2ray_conf_backup.sh
            sleep 1
            rm -rf /tmp/upload/v2ray_conf_backup.sh
            echo_date "�ָ���ϣ�" >> $LOG_FILE
        else
            echo_date "�����ļ���ʽ����" >> $LOG_FILE
        fi
        http_response "$1"
        echo XU6J03M6 >> $LOG_FILE
    ;;
    5)
        # ����v2ray������
        echo ======================================================================================================= > $LOG_FILE
        check_update_v2ray >> $LOG_FILE
        http_response "$1"
    ;;
    6)
        # ���¹���
        if [ "$1" == "cron" ];then
            echo ======================================================================================================= > $LOG_FILE
            echo_date "������¶�ʱ���¼ƻ�" >> $LOG_FILE
            update_rule >> $LOG_FILE
            echo XU6J03M6 >> $LOG_FILE
        else
            echo ======================================================================================================= > $LOG_FILE
            update_rule "$1" >> $LOG_FILE
            echo XU6J03M6 >> $LOG_FILE
            http_response "$1"
        fi
    ;;
    7)
        echo "" > $LOG_FILE
        sed -i '/v2raynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
        if [ "$v2ray_basic_rule_update" = "1" ];then
            [ "$v2ray_basic_gfwlist_update" == "1" ] && echo_date "����gfwlist�����Զ����£�" >> $LOG_FILE ||  echo_date "gfwlist�����Զ�����δ������" >> $LOG_FILE
            [ "$v2ray_basic_chnroute_update" == "1" ] && echo_date "����chnrotue�����Զ����£�" >> $LOG_FILE ||  echo_date "chnrotue�����Զ�����δ������" >> $LOG_FILE
            [ "$v2ray_basic_cdn_update" == "1" ] && echo_date "����cdn�����Զ����£�" >> $LOG_FILE ||  echo_date "cdn�����Զ�����δ������" >> $LOG_FILE
            if [ "$v2ray_basic_rule_update_day" = "7" ];then
                echo "0 $v2ray_basic_rule_update_hr * * * /koolshare/scripts/v2ray_config.sh cron 6 #v2raynodeupdate#" >> /etc/crontabs/root
                echo_date "���ö��ķ������Զ����¶��ķ�������ÿ�� $v2ray_basic_rule_update_hr �㡣" >> $LOG_FILE
            else
                echo "0 $v2ray_basic_rule_update_hr * * $v2ray_basic_rule_update_day /koolshare/scripts/ss_online_update.sh cron 6 #v2raynodeupdate#" >> /etc/crontabs/root
                echo_date "���ö��ķ������Զ����¶��ķ����������� $v2ray_basic_rule_update_day �� $v2ray_basic_rule_update_hr �㡣" >> $LOG_FILE
            fi
        else
            echo_date "�رչ���ʱ���¼ƻ�����" >> $LOG_FILE
        fi
        sleep 1
        http_response "$1"
        echo XU6J03M6 >> $LOG_FILE
    ;;
    8)
        # ���²��
        check_update_now > $LOG_FILE
        http_response "$1"
    ;;
    9)
        # ����������б�
        clean_server_list
        http_response "$1"
    ;;
    10)
        # ���¶����б�
        http_response "$1"
        echo XU6J03M6 >> $LOG_FILE
    ;;
esac