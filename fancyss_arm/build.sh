#!/bin/sh

MODULE=shadowsocks
VERSION=`cat ./shadowsocks/ss/version|sed -n 1p`
TITLE=科学上网
DESCRIPTION=科学上网
HOME_URL=Main_Ss_Content.asp

cp_rules(){
	cp -rf ../rules/gfwlist.conf shadowsocks/ss/rules/
	cp -rf ../rules/chnroute.txt shadowsocks/ss/rules/
	cp -rf ../rules/cdn.txt shadowsocks/ss/rules/
	cp -rf ../rules/version1 shadowsocks/ss/rules/version
}

sync_v2ray_binary(){
	v2ray_version=`cat ../v2ray_binary/latest.txt`
	md5_latest=`md5sum ../v2ray_binary/$v2ray_version/v2ray | sed 's/ /\n/g'| sed -n 1p`
	md5_old=`md5sum shadowsocks/bin//v2ray | sed 's/ /\n/g'| sed -n 1p`
	if [ "$md5_latest"x != "$md5_old"x ]; then
		echo update v2ray binary！
		cp -rf ../v2ray_binary/$v2ray_version/v2ray shadowsocks/bin/
		cp -rf ../v2ray_binary/$v2ray_version/v2ctl shadowsocks/bin/
	fi
}

do_build() {
	if [ "$VERSION" = "" ]; then
		echo "version not found"
		exit 3
	fi
	
	rm -f ${MODULE}.tar.gz
	rm -f $MODULE/.DS_Store
	rm -f $MODULE/*/.DS_Store
	tar -zcvf ${MODULE}.tar.gz $MODULE
	md5value=`md5sum ${MODULE}.tar.gz|tr " " "\n"|sed -n 1p`
	cat > ./version <<-EOF
	$VERSION
	$md5value
	EOF
	cat version
	
	DATE=`date +%Y-%m-%d_%H:%M:%S`
	cat > ./config.json.js <<-EOF
	{
	"version":"$VERSION",
	"md5":"$md5value",
	"home_url":"$HOME_URL",
	"title":"$TITLE",
	"description":"$DESCRIPTION",
	"build_date":"$DATE"
	}
	EOF
}

do_backup(){
	# backup latested package after pack
	backup_version=`cat version | sed -n 1p`
	backup_tar_md5=`cat version | sed -n 2p`
	echo backup VERSION $backup_version
	cp ${MODULE}.tar.gz ./history/${MODULE}_$backup_version.tar.gz
	sed -i "/$backup_version/d" ./history/version
	echo $backup_tar_md5  ${MODULE}_$backup_version.tar.gz >> ./history/version
}


cp_rules
sync_v2ray_binary
do_build
do_backup
