#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export v2ray`

confs=`dbus list v2ray|cut -d "=" -f1`

for conf in $confs
do
	dbus remove $conf
done

sleep 1
rm -rf $KSROOT/scripts/v2ray*
rm -rf $KSROOT/init.d/S99v2ray.sh
rm -rf $KSROOT/v2ray
rm -rf $KSROOT/bin/v2ray
rm -rf $KSROOT/bin/v2ctl
rm -rf $KSROOT/bin/smartdns
rm -rf $KSROOT/webs/Module_v2ray.asp
rm -rf $KSROOT/webs/res/icon-v2ray.png
rm -rf $KSROOT/webs/res/icon-v2ray-bg.png
rm -rf $KSROOT/scripts/uninstall_v2ray.sh

dbus remove softcenter_module_v2ray_home_url
dbus remove softcenter_module_v2ray_install
dbus remove softcenter_module_v2ray_md5
dbus remove softcenter_module_v2ray_version
dbus remove softcenter_module_v2ray_name
dbus remove softcenter_module_v2ray_description
