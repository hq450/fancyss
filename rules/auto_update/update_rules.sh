#!/bin/bash
CurrentDate=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
CURR_PATH="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
RULE_PATH=${CURR_PATH%\/*}
RULE_FILE=${RULE_PATH}/rules.json.js
OBJECT_1='{}'

prepare(){
	if ! type -p sponge &>/dev/null; then
	    printf '%s\n' "error: sponge is not installed, exiting..."
	    exit 1
	fi
	cd ${CURR_PATH}
}

get_gfwlist(){
	# gfwlist.conf

	# 1. download
	${CURR_PATH}/fwlist.py gfwlist_download.conf >/dev/null 2>&1
	if [ ! -f "gfwlist_download.conf" ]; then
		echo "gfwlist download faild!"
		exit 1
	fi

	# 2. merge
	cat ${CURR_PATH}/gfwlist_download.conf ${CURR_PATH}/gfwlist_fancyss.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >${CURR_PATH}/gfwlist_merge.conf
	cat ${CURR_PATH}/gfwlist_download.conf ${CURR_PATH}/gfwlist_fancyss.conf | grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/gfwlist/g" >>${CURR_PATH}/gfwlist_merge.conf

	# 3. sort
	sort -k 2 -t. -u ${CURR_PATH}/gfwlist_merge.conf >${CURR_PATH}/gfwlist_tmp.conf
	
	# 4. post filter: delete site below
	sed -i '/m-team/d' ${CURR_PATH}/gfwlist_tmp.conf
	sed -i '/windowsupdate/d' ${CURR_PATH}/gfwlist_tmp.conf
	sed -i '/v2ex/d' ${CURR_PATH}/gfwlist_tmp.conf
	sed -i '/apple\.com/d' ${CURR_PATH}/gfwlist_tmp.conf

	# 5. compare
	local md5sum1=$(md5sum ${CURR_PATH}/gfwlist_tmp.conf | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/gfwlist.conf | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "gfwlist same md5!"
		return
	fi

	# 6. update file
	echo "update gfwlist!"
	mv -f ${CURR_PATH}/gfwlist_tmp.conf ${RULE_PATH}/gfwlist.conf

	# 7. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/gfwlist.conf|grep -E "^server="|wc -l)
	jq --arg variable "${CURR_DATE}" '.gfwlist.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.gfwlist.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.gfwlist.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}

get_chnroute_misakaio(){
	# chnroute.txt from misakaio
	# 项目地址：https://github.com/misakaio/chnroutes2
	# 详情：This project uses BGP feed from various sources to provide more accurate and up-to-date CN routes.

	curl -4sk https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt >${CURR_PATH}/chnroute_misakaio_tmp.txt

	if [ ! -f "chnroute_misakaio_tmp.txt" ]; then
		echo "chnroute_misakaio download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_misakaio_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_misakaio_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_misakaio.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_misakaio.txt)
		echo "chnroute_misakaio same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="misakaio"
	local URL="https://github.com/misakaio/chnroutes2/blob/master/chnroutes.txt"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_misakaio_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_misakaio_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_misakaio.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_misakaio.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_misakaio.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_misakaio.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_misakaio.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_misakaio.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_misakaio_tmp.txt ${RULE_PATH}/chnroute_misakaio.txt
}

get_chnroute_cnisp(){
	# 项目地址：https://github.com/gaoyifan/china-operator-ip
	# 详情：依据中国网络运营商分类的IP地址库

	curl -4sk https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt >${CURR_PATH}/chnroute_cnisp_tmp.txt

	if [ ! -f "chnroute_cnisp_tmp.txt" ]; then
		echo "chnroute_cnisp download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_cnisp_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_cnisp_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_cnisp.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_cnisp.txt)
		echo "chnroute_cnisp same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="cnisp"
	local URL="https://github.com/gaoyifan/china-operator-ip"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_cnisp_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_cnisp_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_cnisp.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_cnisp.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_cnisp.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_cnisp.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_cnisp.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_cnisp.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_cnisp_tmp.txt ${RULE_PATH}/chnroute_cnisp.txt
}

get_chnroute_apnic(){
	# chnroute_apnic.txt

	curl -4sk http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ${CURR_PATH}/chnroute_apnic_tmp.txt
	
	if [ ! -f "chnroute_apnic_tmp.txt" ]; then
		echo "chnroute_apnic download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_apnic_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_apnic_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_apnic.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_apnic.txt)
		echo "chnroute_apnic same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="apnic"
	local URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_apnic_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_apnic_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_apnic.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_apnic.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_apnic.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_apnic.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_apnic.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_apnic.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_apnic_tmp.txt ${RULE_PATH}/chnroute_apnic.txt
}

get_chnroute_17mon(){
	# chnroute_17mon.txt from 17mon
	# 项目地址：https://github.com/17mon/china_ip_list
	# ip来源：IPList for China by IPIP.NET

	curl -4s https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt >${CURR_PATH}/chnroute_17mon_tmp.txt

	if [ ! -f "chnroute_17mon_tmp.txt" ]; then
		echo "chnroute_17mon download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_17mon_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_17mon_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_17mon.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_17mon.txt)
		echo "chnroute_17mon same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="17mon/ipip"
	local URL="https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_17mon_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_17mon_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_17mon.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_17mon.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_17mon.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_17mon.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_17mon.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_17mon.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_17mon_tmp.txt ${RULE_PATH}/chnroute_17mon.txt
}

get_chnroute_ipip(){
	# chnroute_ipip.txt from ipip
	# source: firehol/blocklist-ipsets

	curl -4sk https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset >${CURR_PATH}/chnroute_ipip_tmp.txt

	if [ ! -f "chnroute_ipip_tmp.txt" ]; then
		echo "chnroute_ipip download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_ipip_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_ipip_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_ipip.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_ipip.txt)
		echo "chnroute_ipip same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="ipip.net"
	local URL="https://github.com/firehol/blocklist-ipsets/blob/master/ipip_country/ipip_country_cn.netset"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_ipip_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_ipip_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_ipip.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_ipip.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_ipip.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_ipip.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_ipip.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_ipip.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_ipip_tmp.txt ${RULE_PATH}/chnroute_ipip.txt
}

get_chnroute_maxmind(){
	# chnroute_maxmind.txt from maxmind
	# source: firehol/blocklist-ipsets

	curl -4sk https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/geolite2_country/country_cn.netset >${CURR_PATH}/chnroute_maxmind_tmp.txt

	if [ ! -f "chnroute_maxmind_tmp.txt" ]; then
		echo "chnroute_maxmind download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_maxmind_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_maxmind_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute_maxmind.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute_maxmind.txt)
		echo "chnroute_maxmind same md5! total $_IP_COUNT ips!"
		return
	fi
	
	# 4. write json
	local SOURCE="maxmind/geolite2"
	local URL="https://github.com/firehol/blocklist-ipsets/blob/master/geolite2_country/country_cn.netset"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_maxmind_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_maxmind_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute_maxmind.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute_maxmind.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute_maxmind.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute_maxmind.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute_maxmind.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute_maxmind.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_maxmind_tmp.txt ${RULE_PATH}/chnroute_maxmind.txt
}

gen_chnroute_fancyss(){
	# 1. merge rules
	cat ${RULE_PATH}/chnroute_misakaio.txt ${RULE_PATH}/chnroute_cnisp.txt ${RULE_PATH}/chnroute_apnic.txt ${RULE_PATH}/chnroute_17mon.txt ${RULE_PATH}/chnroute_ipip.txt ${RULE_PATH}/chnroute_maxmind.txt | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | iprange >${CURR_PATH}/chnroute_tmp.txt

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_tmp.txt 2>/dev/null | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		local _IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${RULE_PATH}/chnroute.txt)
		echo "chnroute same md5! total $_IP_COUNT ips!"
		return
	fi

	# 3. write json
	local SOURCE="fancyss"
	local URL="https://github.com/hq450/fancyss/tree/3.0/rules"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {print sum}' ${CURR_PATH}/chnroute_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 4. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_tmp.txt ${RULE_PATH}/chnroute.txt
}

get_cdn(){
	# cdn.txt

	# 1.download
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf >${CURR_PATH}/accelerated-domains.china.conf
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf >${CURR_PATH}/apple.china.conf
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf >${CURR_PATH}/google.china.conf
	if [ ! -f "accelerated-domains.china.conf" -o ! -f "apple.china.conf" -o ! -f "google.china.conf" ]; then
		echo "cdn download faild!"
		exit 1
	fi
	
	# 2.merge
	cat accelerated-domains.china.conf apple.china.conf google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" >cdn_download.txt
	cat cdn_koolcenter.txt cdn_download.txt | sort -u >cdn_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum cdn_tmp.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../cdn.txt | sed 's/ /\n/g' 2>/dev/null | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn list same md5!"
		return
	fi
	
	# 4. update file
	echo "update cdn!"
	mv -f ${CURR_PATH}/cdn_tmp.txt ${RULE_PATH}/cdn.txt

	# 5. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/cdn.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.cdn_china.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.cdn_china.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.cdn_china.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}

get_apple(){
	# 1. get domain
	cat ${CURR_PATH}/apple.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >${CURR_PATH}/apple_download.txt

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/apple_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${RULE_PATH}/apple_china.txt 2>/dev/null | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "apple china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update apple china list!"
	mv -f ${CURR_PATH}/apple_download.txt ${RULE_PATH}/apple_china.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/apple_china.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.apple_china.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.apple_china.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.apple_china.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}	
}

get_google(){
	# 1. get domain
	cat google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >${CURR_PATH}/google_download.txt

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/google_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${RULE_PATH}/google_china.txt 2>/dev/null | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "google china list same md5!"
		return
	fi
	
	# 3. update file
	echo "update google china list!"
	mv -f ${CURR_PATH}/google_download.txt ${RULE_PATH}/google_china.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/google_china.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.google_china.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.google_china.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.google_china.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}

get_cdntest(){
	# 1. get domain
	curl -4sk https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt >${CURR_PATH}/cdn_test.txt

	# 2. compare
	local md5sum1=$(md5sum ${CURR_PATH}/cdn_test.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${RULE_PATH}/cdn_test.txt 2>/dev/null | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn test list same md5!"
		return
	fi
	
	# 3. update file
	echo "update cdn test list!"
	mv -f ${CURR_PATH}/cdn_test.txt ${RULE_PATH}/cdn_test.txt

	# 4. write json
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${RULE_PATH}/cdn_test.txt | wc -l)
	jq --arg variable "${CURR_DATE}" '.cdn_test.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.cdn_test.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.cdn_test.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
}


finish(){
	rm -f ${CURR_PATH}/gfwlist_tmp.conf
	rm -f ${CURR_PATH}/gfwlist_merge.conf
	rm -f ${CURR_PATH}/gfwlist_download.conf
	rm -f ${CURR_PATH}/chnroute_tmp.txt
	rm -f ${CURR_PATH}/chnroute_ipip_tmp.txt
	rm -f ${CURR_PATH}/chnroute_apnic_tmp.txt
	rm -f ${CURR_PATH}/chnroute_misakaio_tmp.txt
	rm -f ${CURR_PATH}/chnroute_17mon_tmp.txt
	rm -f ${CURR_PATH}/chnroute_maxmind_tmp.txt
	rm -f ${CURR_PATH}/chnroute_cnisp_tmp.txt
	rm -f ${CURR_PATH}/cdn_tmp.txt
	rm -f ${CURR_PATH}/accelerated-domains.china.conf
	rm -f ${CURR_PATH}/cdn_download.txt
	rm -f ${CURR_PATH}/apple.china.conf
	rm -f ${CURR_PATH}/apple_download.txt
	rm -f ${CURR_PATH}/google.china.conf
	rm -f ${CURR_PATH}/google_download.txt
	rm -f ${CURR_PATH}/cdn_test.txt
	rm -f ${CURR_PATH}/cdn_test.txt
	echo "---------------------------------"
}

clear_chnroute(){
	find ${RULE_PATH} -maxdepth 1 -name "*chnroute*"|xargs -I {} sh -c "echo \"\" > '{}'"
	echo "" >${RULE_PATH}/cdn.txt
	echo "" >${RULE_PATH}/gfwlist.conf
	echo "" >${RULE_PATH}/google_china.txt
	echo "" >${RULE_PATH}/apple_china.txt
	echo "" >${RULE_PATH}/cdn_test.txt
}

get_rules(){
	prepare
	get_gfwlist
	get_chnroute_misakaio
	get_chnroute_cnisp
	get_chnroute_apnic
	get_chnroute_17mon
	get_chnroute_ipip
	get_chnroute_maxmind
	gen_chnroute_fancyss
	get_cdn
	get_apple
	get_google
	get_cdntest
	finish
}

case $1 in
update)
	get_rules
	;;
clear)
	clear_chnroute
	;;
esac