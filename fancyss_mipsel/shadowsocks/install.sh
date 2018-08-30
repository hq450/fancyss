#! /bin/sh

eval `dbus export ss`
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'

remove_conf(){
	ipset_value=`dbus list ss_ipset | cut -d "=" -f 1`
	redchn_value=`dbus list ss_redchn | cut -d "=" -f 1`
	overall_value=`dbus list ss_overall_ | cut -d "=" -f 1`
	for conf in $ipset_value $redchn_value $overall_value
	do
		echo 移除$conf
		dbus remove $conf
	done
}

remove_conf


# 关闭ss
mkdir -p /koolshare/ss
if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭ss，保证文件更新成功!
	sh /koolshare/ss/stop.sh stop_all
fi

#升级前先删除无关文件
echo_date 清理旧文件
rm -rf /koolshare/ss/*
rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Main_Ss*
rm -rf /koolshare/bin/ss-*
rm -rf /koolshare/bin/rss-*
rm -rf /koolshare/bin/obfs*
rm -rf /koolshare/bin/haproxy
rm -rf /koolshare/bin/redsocks2
rm -rf /koolshare/bin/pdnsd
rm -rf /koolshare/bin/dnscrypt-proxy
rm -rf /koolshare/bin/dns2socks
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/resolveip


echo_date 复制新文件！
cd /tmp

echo_date 复制相关二进制文件！
cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/
chmod 755 /koolshare/bin/*
[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel


if [ ! -L /koolshare/bin/base64_decode ];then
	ln -s /koolshare/bin/base64_encode /koolshare/bin/base64_decode
fi

echo_date 复制ss的脚本文件！
cp -rf /tmp/shadowsocks/ss/* /koolshare/ss/
cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
cp -rf /tmp/shadowsocks/init.d/* /koolshare/init.d/

echo_date 复制网页文件！
cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
cp -rf /tmp/shadowsocks/res/* /koolshare/res/

echo_date 移除安装包！
rm -rf /tmp/shadowsocks* >/dev/null 2>&1


# transform data in skipd when ss version below 3.0.0
curr_version=`dbus get ss_basic_version_local`
comp=`/usr/bin/versioncmp $curr_version 3.0.0`
if [ -n "$curr_version" ] && [ "$comp" == "1" ];then
	echo_date 从ss3.0.0版本开始，将对界面内textarea内的值和ss的密码进行base64加密，方便储存！
	echo_date 生成当前SS版本：$curr_version的配置文件到/jffs根目录！
	dbus list ss > /jffs/ss_conf_backup_$curr_version.txt
	echo_date 对部分ss数据进行base64加密数据！
	node_pass=`dbus list ssconf_basic_password |cut -d "=" -f 1|cut -d "_" -f4|sort -n`
	for node in $node_pass
	do
		dbus set ssconf_basic_password_$node=`dbus get ssconf_basic_password_$node|base64_encode`
	done
	dbus set ss_basic_password=`dbus get ss_basic_password|base64_encode`
	dbus set ss_basic_black_lan=`dbus get ss_basic_black_lan | base64_encode`
	dbus set ss_basic_white_lan=`dbus get ss_basic_white_lan | base64_encode`
	dbus set ss_ipset_black_domain_web=`dbus get ss_ipset_black_domain_web | base64_encode`
	dbus set ss_ipset_white_domain_web=`dbus get ss_ipset_white_domain_web | base64_encode`
	dbus set ss_ipset_dnsmasq=`dbus get ss_ipset_dnsmasq | base64_encode`
	dbus set ss_ipset_black_ip=`dbus get ss_ipset_black_ip | base64_encode`
	dbus set ss_redchn_isp_website_web=`dbus get ss_redchn_isp_website_web | base64_encode`
	dbus set ss_redchn_dnsmasq=`dbus get ss_redchn_dnsmasq | base64_encode`
	dbus set ss_redchn_wan_white_ip=`dbus get ss_redchn_wan_white_ip | base64_encode`
	dbus set ss_redchn_wan_white_domain=`dbus get ss_redchn_wan_white_domain | base64_encode`
	dbus set ss_redchn_wan_black_ip=`dbus get ss_redchn_wan_black_ip | base64_encode`
	dbus set ss_redchn_wan_black_domain=`dbus get ss_redchn_wan_black_domain | base64_encode`
fi

# 设置一些默认值
echo_date 设置一些默认值
[ -z "$ss_dns_china" ] && dbus set ss_dns_china=11
[ -z "$ss_dns_foreign" ] && dbus set ss_dns_foreign=1
[ -z "$ss_basic_ss_obfs" ] && dbus set ss_basic_ss_obfs=0
[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode"
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all
[ -z "$ss_dns_plan" ] && dbus set ss_dns_china=1
[ -z "$ss_dns_plan_chn" ] && dbus set ss_dns_china=2
[ -z "$ss_dns_plan_gfw" ] && dbus set ss_dns_china=1

echo_date 为新安装文件赋予执行权限...
chmod 755 /koolshare/ss/cru/*
chmod 755 /koolshare/ss/rules/*
chmod 755 /koolshare/ss/socks5/*
chmod 755 /koolshare/ss/*
chmod 755 /koolshare/scripts/ss*
chmod 755 /koolshare/bin/*

# add icon into softerware center
dbus set softcenter_module_shadowsocks_install=1
dbus set softcenter_module_shadowsocks_version=3.1.6
dbus set softcenter_module_shadowsocks_home_url=Main_Ss_Content.asp

new_version=`cat /koolshare/ss/version`
dbus set ss_basic_version_local=$new_version

sleep 2
echo_date 一点点清理工作...
rm -rf /tmp/shadowsocks* >/dev/null 2>&1
dbus set ss_basic_install_status="0"
echo_date 安装更新成功，你为什么这么屌？！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启ss！
	dbus set ss_basic_action=1
	. /koolshare/ss/ssconfig.sh restart
fi
echo_date 更新完毕，请等待网页自动刷新！
echo XU6J03M6
sleep 1
killall ssconfig.sh >/dev/null 2>&1
killall sh >/dev/null 2>&1
kill `pidof ssconfig.sh` >/dev/null 2>&1








