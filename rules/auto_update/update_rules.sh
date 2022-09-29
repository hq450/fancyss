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


get_chnroute(){
	# chnroute.txt from misakaio

	# source-1：misakaio, 20220604: total 3403 subnets, 298382954 unique IPs
	wget -4 https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt -qO ${CURR_PATH}/chnroute_tmp.txt

	if [ ! -f "chnroute_tmp.txt" ]; then
		echo "chnroute download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute same md5!"
		return
	fi
	
	# 4. write json
	local SOURCE="misakaio"
	local URL="https://github.com/misakaio/chnroutes2/blob/master/chnroutes.txt"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' ${CURR_PATH}/chnroute_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute_tmp.txt ${RULE_PATH}/chnroute.txt
}

get_chnroute2(){
	# chnroute2.txt from ipip

	# source-2：ipip, 20220604: total 6182 subnets, 13240665434 unique IPs
	wget -4 https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset -qO ${CURR_PATH}/chnroute2_tmp.txt

	if [ ! -f "chnroute2_tmp.txt" ]; then
		echo "chnroute2 download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute2_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute2_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute2.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute2 same md5!"
		return
	fi
	
	# 4. write json
	local SOURCE="ipip"
	local URL="https://github.com/firehol/blocklist-ipsets/blob/master/ipip_country/ipip_country_cn.netset"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute2_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' ${CURR_PATH}/chnroute2_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute2.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute2.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute2.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute2.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute2.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute2.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute2_tmp.txt ${RULE_PATH}/chnroute2.txt
}

get_chnroute3(){
	# chnroute3.txt

	# source-3: mayaxcn, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt -qO ${CURR_PATH}/chnroute3_tmp.txt

	# source-4: clang, 20220604: total 8625 subnets, 343364510 unique IPs
	wget -4 https://ispip.clang.cn/all_cn.txt -qO ${CURR_PATH}/chnroute3_tmp.txt
	
	# source-5：apnic, 20220604: total 8625 subnets, 343364510 unique IPs
	# wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -qO ${CURR_PATH}/apnic.txt
	# cat apnic.txt| awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ${CURR_PATH}/chnroute3_tmp.txt
	# rm -rf ${CURR_PATH}/apnic.txt

	if [ ! -f "chnroute3_tmp.txt" ]; then
		echo "chnroute3 download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute3_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute3_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${RULE_PATH}/chnroute3.txt 2>/dev/null | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute3 same md5!"
		return
	fi
	
	# 4. write json
	local SOURCE="apnic"
	local URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
	local CURR_DATE=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
	local MD5_VALUE=${md5sum1}
	local LINE_COUN=$(cat ${CURR_PATH}/chnroute3_tmp.txt | wc -l)
	local IP_COUNT=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' ${CURR_PATH}/chnroute3_tmp.txt)
	jq --arg variable "${SOURCE}" '.chnroute3.source = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${URL}" '.chnroute3.url = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${CURR_DATE}" '.chnroute3.date = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${MD5_VALUE}" '.chnroute3.md5 = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${LINE_COUN}" '.chnroute3.count = $variable' ${RULE_FILE} | sponge ${RULE_FILE}
	jq --arg variable "${IP_COUNT}" '.chnroute3.count_ip = $variable' ${RULE_FILE} | sponge ${RULE_FILE}

	# 5. update file
	echo "update chnroute from ${SOURCE}, total ${LINE_COUN} subnets, ${IP_COUNT} unique IPs !"
	mv -f ${CURR_PATH}/chnroute3_tmp.txt ${RULE_PATH}/chnroute3.txt
}

get_cdn(){
	# cdn.txt

	# 1.download
	wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf -qO ${CURR_PATH}/accelerated-domains.china.conf
	wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf -qO ${CURR_PATH}/apple.china.conf
	wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf -qO ${CURR_PATH}/google.china.conf
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
	wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt -qO ${CURR_PATH}/cdn_test.txt

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
	rm -f ${CURR_PATH}/chnroute2_tmp.txt
	rm -f ${CURR_PATH}/chnroute3_tmp.txt
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

get_rules(){
	prepare
	get_gfwlist
	get_chnroute
	get_chnroute2
	get_chnroute3
	get_cdn
	get_apple
	get_google
	get_cdntest
	finish
}

get_rules
