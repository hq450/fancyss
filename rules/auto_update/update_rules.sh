#!/bin/bash
# CurrentDate=$(date +%Y-%m-%d)
CurrentDate=$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)
CURR_PATH="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
OBJECT_1='{}'

json_init(){
	OBJECT_2='{}'
}

json_add_string(){
	OBJECT_2=$(echo ${OBJECT_2} | jq --arg var "$2" '. + {'$1': $var}')
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
	local md5sum2=$(md5sum ${CURR_PATH}/../gfwlist.conf | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "gfwlist same md5!"
	else
		echo "update gfwlist!"
		mv -f ${CURR_PATH}/gfwlist_tmp.conf ${CURR_PATH}/../gfwlist.conf
	fi

	# 6. gen json
	local count=$(cat ${CURR_PATH}/../gfwlist.conf|grep -E "^server="|wc -l)
	json_init
	json_add_string name "gfwlist.conf"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${count}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"gfwlist"': $args}')

	# remove tmp files
	rm -f ${CURR_PATH}/gfwlist_tmp.conf
	rm -f ${CURR_PATH}/gfwlist_merge.conf
	rm -f ${CURR_PATH}/gfwlist_download.conf
}

get_chnroute(){
	# chnroute.txt

	# 1. download
	wget https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset -qO ${CURR_PATH}/chnroute_tmp.txt
	if [ ! -f "chnroute_tmp.txt" ]; then
		echo "chnroute download faild!"
		exit 1
	fi

	# 2. process
	sed -i '/^#/d' chnroute_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum ${CURR_PATH}/chnroute_tmp.txt | awk '{print $1}')
	local md5sum2=$(md5sum ${CURR_PATH}/../chnroute.txt | awk '{print $1}')
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "chnroute same md5!"
	else
		echo "update chnroute, total ${IPLINE} subnets, ${IPCOUN} unique IPs !"
		mv -f ${CURR_PATH}/chnroute_tmp.txt ${CURR_PATH}/../chnroute.txt
	fi
	IPLINE=$(cat ${CURR_PATH}/../chnroute.txt | wc -l)
	IPCOUN=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' ${CURR_PATH}/../chnroute.txt)

	# 3. gen json
	json_init
	json_add_string name "chnroute.txt"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${IPLINE}"
	json_add_string count_ip "${IPCOUN}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"chnroute"': $args}')

	# remove tmp files
	rm -f ${CURR_PATH}/chnroute_tmp.txt
}

get_cdn(){
	# cdn.txt

	# 1.download
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf -qO ${CURR_PATH}/accelerated-domains.china.conf
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf -qO ${CURR_PATH}/apple.china.conf
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf -qO ${CURR_PATH}/google.china.conf
	if [ ! -f "accelerated-domains.china.conf" -o ! -f "apple.china.conf" -o ! -f "google.china.conf" ]; then
		echo "cdn download faild!"
		exit 1
	fi
	
	# 2.merge
	cat accelerated-domains.china.conf apple.china.conf google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" >cdn_download.txt
	cat cdn_koolcenter.txt cdn_download.txt | sort -u >cdn_tmp.txt

	# 3. compare
	local md5sum1=$(md5sum cdn_tmp.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ../cdn.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn list same md5!"
	else
		echo "update cdn!"
		mv -f ${CURR_PATH}/cdn_tmp.txt ${CURR_PATH}/../cdn.txt
	fi
	local count=$(cat ${CURR_PATH}/../cdn.txt|wc -l)

	# 4. gen json
	json_init
	json_add_string name "cdn.txt"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${count}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"cdn_china"': $args}')
	
	# remove tmp files
	rm -f ${CURR_PATH}/cdn_tmp.txt
	rm -f ${CURR_PATH}/accelerated-domains.china.conf
	rm -f ${CURR_PATH}/cdn_download.txt
}

get_apple(){
	# 1. get domain
	cat ${CURR_PATH}/apple.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >${CURR_PATH}/apple_download.txt

	# compare
	local md5sum1=$(md5sum ${CURR_PATH}/apple_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${CURR_PATH}/../apple_china.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "apple china list same md5!"
	else
		echo "update apple china list!"
		mv -f ${CURR_PATH}/apple_download.txt ${CURR_PATH}/../apple_china.txt
	fi
	local count=$(cat ${CURR_PATH}/../apple_china.txt|wc -l)

	# 4. gen json
	json_init
	json_add_string name "apple_china.txt"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${count}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"apple_china"': $args}')

	# remove tmp files
	rm -f ${CURR_PATH}/apple.china.conf
	rm -f ${CURR_PATH}/apple_download.txt
}

get_google(){
	# 1. get domain
	cat google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" | sort -u >${CURR_PATH}/google_download.txt

	# compare
	local md5sum1=$(md5sum ${CURR_PATH}/google_download.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${CURR_PATH}/../google_china.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "google china list same md5!"
	else
		echo "update google china list!"
		mv -f ${CURR_PATH}/google_download.txt ${CURR_PATH}/../google_china.txt
	fi
	local count=$(cat ${CURR_PATH}/../google_china.txt|wc -l)

	# 4. gen json
	json_init
	json_add_string name "google_china.txt"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${count}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"google_china"': $args}')
	
	# remove tmp files
	rm -f ${CURR_PATH}/google.china.conf
	rm -f ${CURR_PATH}/google_download.txt
}

get_cdntest(){
	# 1. get domain
	wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt -qO ${CURR_PATH}/cdn_test.txt

	# compare
	local md5sum1=$(md5sum ${CURR_PATH}/cdn_test.txt | sed 's/ /\n/g' | sed -n 1p)
	local md5sum2=$(md5sum ${CURR_PATH}/../cdn_test.txt | sed 's/ /\n/g' | sed -n 1p)
	echo "---------------------------------"
	if [ "$md5sum1"x = "$md5sum2"x ]; then
		echo "cdn test list same md5!"
	else
		echo "update cdn test list!"
		mv -f ${CURR_PATH}/cdn_test.txt ${CURR_PATH}/../cdn_test.txt
	fi
	local count=$(cat ${CURR_PATH}/../cdn_test.txt|wc -l)

	# 4. gen json
	json_init
	json_add_string name "cdn_test.txt"
	json_add_string date "$(TZ=CST-8 date +%Y-%m-%d\ %H:%M)"
	json_add_string md5 "${md5sum1}"
	json_add_string count "${count}"
	OBJECT_1=$(echo ${OBJECT_1} | jq --argjson args "${OBJECT_2}" '. + {'"cdn_test"': $args}')
	
	# remove tmp files
	rm -f ${CURR_PATH}/cdn_test.txt
}


finish(){
	echo "---------------------------------"
	echo ${OBJECT_1} | jq '.' > ../rules.json.js
}

get_rules(){
	get_gfwlist
	get_chnroute
	get_cdn
	get_apple
	get_google
	get_cdntest
	finish
}

get_rules
