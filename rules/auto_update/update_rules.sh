#!/bin/bash
CurrentDate=$(date +%Y-%m-%d)
# ======================================
# get gfwlist for shadowsocks ipset mode
./fwlist.py gfwlist_download.conf

grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" gfwlist_download.conf >gfwlist_download_tmp.conf

if [ -f "gfwlist_download.conf" ]; then
	cat gfwlist_download_tmp.conf gfwlist_koolshare.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >gfwlist_merge.conf
	cat gfwlist_download_tmp.conf gfwlist_koolshare.conf | sed "s/^/ipset=&\/./g" | sed "s/$/\/gfwlist/g" >>gfwlist_merge.conf
fi

sort -k 2 -t. -u gfwlist_merge.conf >gfwlist1.conf
rm gfwlist_merge.conf

# delete site below
sed -i '/m-team/d' "gfwlist1.conf"
sed -i '/windowsupdate/d' "gfwlist1.conf"
sed -i '/v2ex/d' "gfwlist1.conf"
sed -i '/apple\.com/d' "gfwlist1.conf"

md5sum1=$(md5sum gfwlist1.conf | sed 's/ /\n/g' | sed -n 1p)
md5sum2=$(md5sum ../gfwlist.conf | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum1"x = "$md5sum2"x ]; then
	echo gfwlist same md5!
else
	echo update gfwlist!
	cp -f gfwlist1.conf ../gfwlist.conf
	sed -i "1c $(date +%Y-%m-%d) # $md5sum1 gfwlist" ../version1
fi
echo =================
# ======================================
# get chnroute for shadowsocks chn and game mode

# Deprecated in 2019-8-1
# wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest > apnic.txt
# cat apnic.txt| awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute1.txt

# use ipip_country_cn ip database sync by https://github.com/firehol/blocklist-ipsets from ipip.net（source: https://cdn.ipip.net/17mon/country.zip）.
curl https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset | sed '/^#/d' >chnroute1.txt

md5sum3=$(md5sum chnroute1.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum4=$(md5sum ../chnroute.txt | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum3"x = "$md5sum4"x ]; then
	echo chnroute same md5!
else
	IPLINE=$(cat chnroute1.txt | wc -l)
	IPCOUN=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' chnroute1.txt)
	echo update chnroute, $IPLINE subnets, $IPCOUN unique IPs !
	cp -f chnroute1.txt ../chnroute.txt
	sed -i "2c $(date +%Y-%m-%d) # $md5sum3 chnroute" ../version1
fi
echo =================
# ======================================
# get cdn list for shadowsocks chn and game mode

wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf
wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf

cat accelerated-domains.china.conf apple.china.conf google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" >cdn_download.txt
cat cdn_koolshare.txt cdn_download.txt | sort -u >cdn1.txt

md5sum5=$(md5sum cdn1.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum6=$(md5sum ../cdn.txt | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum5"x = "$md5sum6"x ]; then
	echo cdn list same md5!
else
	echo update cdn!
	cp -f cdn1.txt ../cdn.txt
	sed -i "4c $(date +%Y-%m-%d) # $md5sum5 cdn" ../version1
fi
echo =================
# ======================================
# use apnic data
wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest >apnic.txt
cat apnic.txt | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >chnroute1.txt

echo -e "[Local Routing]\n## China mainland routing blocks\n## Sources: https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" >Routing.txt
echo -n "## Last update: " >>Routing.txt
echo $CurrentDate >>Routing.txt
echo -e "\n" >>Routing.txt

# IPv4
echo "## IPv4" >>Routing.txt
cat apnic.txt | grep ipv4 | grep CN | awk -F\| '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' >>Routing.txt
echo -e "\n" >>Routing.txt

# IPv6
echo "## IPv6" >>Routing.txt
cat apnic.txt | grep ipv6 | grep CN | awk -F\| '{printf("%s/%d\n", $4, $5)}' >>Routing.txt

[ ! -f "../Routing.txt" ] && cp Routing.txt ..

md5sum9=$(md5sum Routing.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum10=$(md5sum ../Routing.txt | sed 's/ /\n/g' | sed -n 1p)
echo =================
if [ "$md5sum9"x = "$md5sum10"x ]; then
	echo Routing same md5!
else
	echo update Routing!
	cp Routing.txt ..
	sed -i "5c $(date +%Y-%m-%d) # $md5sum9 Routing" ../version1
fi
echo =================
# ======================================
sed 's|/114.114.114.114$||' accelerated-domains.china.conf >WhiteList_tmp.txt
sed -i 's|\(\.\)|\\\1|g' WhiteList_tmp.txt
sed -i 's|server=/|.*\\\b|' WhiteList_tmp.txt
sed -i 's|b\(cn\)$|\.\1|' WhiteList_tmp.txt

echo '[Local Hosts]' >>WhiteList.txt
echo '## China mainland domains' >>WhiteList.txt
echo '## Get the latest database: https://github.com/xinhugo/Free-List/blob/master/WhiteList.txt' >>WhiteList.txt
echo '## Report an issue: https://github.com/xinhugo/Free-List/issues' >>WhiteList.txt
echo -e "## Last update: $CurrentDate\n" >>WhiteList.txt
cat WhiteList_tmp.txt >>WhiteList.txt

[ ! -f "../WhiteList.txt" ] && mv WhiteList_tmp.txt >>WhiteList.txt

md5sum7=$(md5sum WhiteList.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum8=$(md5sum ../WhiteList.txt | sed 's/ /\n/g' | sed -n 1p)
echo =================
if [ "$md5sum7"x = "$md5sum8"x ]; then
	echo WhiteList same md5!
else
	echo update WhiteList!
	cp -f WhiteList.txt ../WhiteList.txt
	sed -i "6c $(date +%Y-%m-%d) # $md5sum7 WhiteList" ../version1
fi
echo =================

# ======================================
echo -e "[Local Hosts]\n## China mainland domains\n## Source: https://github.com/felixonmars/dnsmasq-china-list" >WhiteList_new.txt
echo -n "## Last update: " >>WhiteList_new.txt
echo $CurrentDate >>WhiteList_new.txt
echo -e "\n" >>WhiteList_new.txt
sed -e "s|114.114.114.114$||" -e "s|^s|S|" accelerated-domains.china.conf >>WhiteList_new.txt

# Download domain data of Google in Mainland China part.
#curl -O https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf
sed -e "s|114.114.114.114$||" -e "s|^s|S|" google.china.conf >>WhiteList_new.txt

# Download domain data of Apple in Mainland China part.
#curl -O https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf
sed -e "s|114.114.114.114$||" -e "s|^s|S|" apple.china.conf >>WhiteList_new.txt

# ok
[ ! -f "../WhiteList_new.txt" ] && cp WhiteList_new.txt ..

md5sum11=$(md5sum WhiteList_new.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum12=$(md5sum ../WhiteList_new.txt | sed 's/ /\n/g' | sed -n 1p)
echo =================
if [ "$md5sum11"x = "$md5sum12"x ]; then
	echo WhiteList_new same md5!
else
	echo update WhiteList_new!
	cp WhiteList_new.txt ..
	sed -i "7c $(date +%Y-%m-%d) # $md5sum11 WhiteList_new" ../version1
fi
echo =================

# ======================================
# get cdn list for shadowsocks chn and game mode
cat apple.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > apple_download.txt
cat google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u > google_download.txt

md5sum13=$(md5sum apple_download.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum14=$(md5sum ../apple_china.txt | sed 's/ /\n/g' | sed -n 1p)

md5sum15=$(md5sum google_download.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum16=$(md5sum ../google_china.txt | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum13"x = "$md5sum14"x ]; then
	echo apple china list same md5!
else
	echo update apple china list!
	cp -f apple_download.txt ../apple_china.txt
	sed -i "8c $(date +%Y-%m-%d) # $md5sum13 apple_china" ../version1
fi
if [ "$md5sum15"x = "$md5sum16"x ]; then
	echo google china list same md5!
else
	echo update goole china list!
	cp -f google_download.txt ../google_china.txt
	sed -i "9c $(date +%Y-%m-%d) # $md5sum15 google_china" ../version1
fi
echo =================
# ======================================
rm google.china.conf
rm apple.china.conf
rm gfwlist1.conf gfwlist_download.conf gfwlist_download_tmp.conf chnroute1.txt
rm cdn1.txt accelerated-domains.china.conf cdn_download.txt apple_download.txt google_download.txt
rm WhiteList.txt WhiteList_tmp.txt apnic.txt WhiteList_new.txt Routing.txt
