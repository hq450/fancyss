#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export v2ray_`

mkdir -p $KSROOT/init.d
mkdir -p $KSROOT/v2ray
[ "$v2ray_basic_enable" == "1" ] && $KSROOT/scripts/v2ray_config.sh stop >/dev/null 2>&1

cp -rf /tmp/v2ray/bin/* $KSROOT/bin/
cp -rf /tmp/v2ray/init.d/* $KSROOT/init.d/
cp -rf /tmp/v2ray/v2ray/* $KSROOT/v2ray/
cp -rf /tmp/v2ray/scripts/* $KSROOT/scripts/
cp -rf /tmp/v2ray/webs/* $KSROOT/webs/
cp /tmp/v2ray/uninstall.sh $KSROOT/scripts/uninstall_v2ray.sh

chmod +x $KSROOT/scripts/v2ray_*
chmod +x $KSROOT/scripts/uninstall_v2ray.sh
chmod +x $KSROOT/bin/v2ray
chmod +x $KSROOT/bin/v2ctl

if [ -n "$v2ray_basic_config" ]; then
    dbus set v2ray_server_tag_1="节点1"
    dbus set v2ray_server_config_1="$v2ray_basic_config"
    dbus set v2ray_basic_server=1
    dbus set v2ray_basic_type=1
    dbus set v2ray_server_node_max=1
    dbus set v2ray_sub_node_max=0
    dbus remove v2ray_basic_config
fi

[ -z "$v2ray_server_tag_1" ] && dbus set v2ray_server_node_max=0
[ -z "$v2ray_sub_tag_1" ] && dbus set v2ray_sub_node_max=0

dbus set softcenter_module_v2ray_description=模块化的代理软件包
dbus set softcenter_module_v2ray_install=4
dbus set softcenter_module_v2ray_name=v2ray
dbus set softcenter_module_v2ray_title="V2Ray"
dbus set softcenter_module_v2ray_version=2020.11.18
dbus set v2ray_version=4.33

sleep 1
rm -rf $KSROOT/v2ray/gfw.txt
rm -rf $KSROOT/init.d/S98v2ray.sh
rm -rf /tmp/v2ray >/dev/null 2>&1

[ "$v2ray_basic_enable" == "1" ] && $KSROOT/scripts/v2ray_config.sh start >/dev/null 2>&1

exit 0
