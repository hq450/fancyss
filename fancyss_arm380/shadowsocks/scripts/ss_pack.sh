#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

rm -rf /tmp/shadowsocks*

echo "开始打包..."
echo "请等待一会儿..."

cd /tmp
mkdir shadowsocks
mkdir shadowsocks/bin
mkdir shadowsocks/scripts
mkdir shadowsocks/webs
mkdir shadowsocks/res

TARGET_FOLDER=/tmp/shadowsocks
cp /koolshare/scripts/ss_install.sh $TARGET_FOLDER/install.sh
cp /koolshare/scripts/uninstall_shadowsocks.sh $TARGET_FOLDER/uninstall.sh
cp /koolshare/scripts/ss_* $TARGET_FOLDER/scripts/
cp /koolshare/bin/ss-local $TARGET_FOLDER/bin/
cp /koolshare/bin/ss-redir $TARGET_FOLDER/bin/
cp /koolshare/bin/ss-tunnel $TARGET_FOLDER/bin/
cp /koolshare/bin/v2ray-plugin $TARGET_FOLDER/bin/
cp /koolshare/bin/rss-local $TARGET_FOLDER/bin/
cp /koolshare/bin/rss-redir $TARGET_FOLDER/bin/
cp /koolshare/bin/koolgame $TARGET_FOLDER/bin/
cp /koolshare/bin/pdu $TARGET_FOLDER/bin/
cp /koolshare/bin/dns2socks $TARGET_FOLDER/bin/
cp /koolshare/bin/cdns $TARGET_FOLDER/bin/
cp /koolshare/bin/chinadns $TARGET_FOLDER/bin/
cp /koolshare/bin/chinadns1 $TARGET_FOLDER/bin/
cp /koolshare/bin/resolveip $TARGET_FOLDER/bin/
cp /koolshare/bin/haproxy $TARGET_FOLDER/bin/
cp /koolshare/bin/client_linux_arm5 $TARGET_FOLDER/bin/
cp /koolshare/bin/base64_encode $TARGET_FOLDER/bin/
cp /koolshare/bin/koolbox $TARGET_FOLDER/bin/
cp /koolshare/bin/jq $TARGET_FOLDER/bin/
cp /koolshare/bin/speeder* $TARGET_FOLDER/bin/
cp /koolshare/bin/udp2raw $TARGET_FOLDER/bin/
cp /koolshare/bin/v2ray $TARGET_FOLDER/bin/
cp /koolshare/bin/v2ctl $TARGET_FOLDER/bin/
cp /koolshare/bin/haveged $TARGET_FOLDER/bin/
cp /koolshare/bin/https_dns_proxy $TARGET_FOLDER/bin/
cp /koolshare/bin/dnsmasq $TARGET_FOLDER/bin/
cp /koolshare/webs/Main_Ss_Content.asp $TARGET_FOLDER/webs/
cp /koolshare/webs/Main_Ss_LoadBlance.asp $TARGET_FOLDER/webs/
cp /koolshare/webs/Main_SsLocal_Content.asp $TARGET_FOLDER/webs/
cp /koolshare/res/icon-shadowsocks.png $TARGET_FOLDER/res/
cp /koolshare/res/ss-menu.js $TARGET_FOLDER/res/
cp /koolshare/res/all.png $TARGET_FOLDER/res/
cp /koolshare/res/gfw.png $TARGET_FOLDER/res/
cp /koolshare/res/chn.png $TARGET_FOLDER/res/
cp /koolshare/res/game.png $TARGET_FOLDER/res/
cp /koolshare/res/gameV2.png $TARGET_FOLDER/res/
cp /koolshare/res/shadowsocks.css $TARGET_FOLDER/res/
cp /koolshare/res/ss_proc_status.htm $TARGET_FOLDER/res/
cp /koolshare/res/ss_udp_status.htm $TARGET_FOLDER/res/
cp -rf /koolshare/res/layer $TARGET_FOLDER/res/
cp -r /koolshare/ss $TARGET_FOLDER/
rm -rf $TARGET_FOLDER/ss/*.json

tar -czv -f /tmp/shadowsocks.tar.gz shadowsocks/
rm -rf $TARGET_FOLDER
echo "打包完毕！"