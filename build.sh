#!/usr/bin/env bash

MODULE=shadowsocks
VERSION=$(cat ./fancyss/ss/version|sed -n 1p)
TITLE="科学上网"
DESCRIPTION="科学上网"
HOME_URL=Module_shadowsocks.asp
CURR_PATH="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

cp_rules(){
	cp -rf ${CURR_PATH}/rules/gfwlist.conf ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/chnroute.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/cdn.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/cdn_test.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/apple_china.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/google_china.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/rules.json.js ${CURR_PATH}/fancyss/ss/rules/rules.json.js
}

sync_binary(){
	BINS="v2ray v2ray-plugin xray ss_rust kcptun naive"
	for BIN in $BINS;
	do
		local VERSION_FLAG="latest.txt"
		if [ "${BIN}" == "v2ray" ];then
			local VERSION_FLAG="latest_v5.txt"
		fi

		if [ "${BIN}" == "xray" ];then
			local VERSION_FLAG="latest_2.txt"
		fi

		if [ "${BIN}" == "ss_rust" ];then
			local REAL_BIN="sslocal"
		else
			local REAL_BIN="${BIN}"
		fi
	
		local version=$(cat ${CURR_PATH}/binaries/${BIN}/${VERSION_FLAG})
		echo ">>> start to copy latest ${BIN}, version: ${version}"
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_arm64 ${CURR_PATH}/fancyss/bin-mtk/${REAL_BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_arm64 ${CURR_PATH}/fancyss/bin-hnd_v8/${REAL_BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv7 ${CURR_PATH}/fancyss/bin-hnd/${REAL_BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv7 ${CURR_PATH}/fancyss/bin-qca/${REAL_BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${REAL_BIN}_armv5 ${CURR_PATH}/fancyss/bin-arm/${REAL_BIN}
	done
}

gen_folder(){
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	cd ${CURR_PATH}
	rm -rf shadowsocks
	cp -rf fancyss shadowsocks

	# different platform	
	if [ "${platform}" == "hnd" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		mv ./shadowsocks/bin-hnd ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		rm -rf ./shadowsocks/bin/websocketd
		echo hnd > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "hnd_v8" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		mv ./shadowsocks/bin-hnd_v8 ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		echo hnd_v8 > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd_v8\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "qca" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-mtk
		mv ./shadowsocks/bin-qca ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		echo qca > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"qca\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "arm" ];then
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin/websocketd
		mv ./shadowsocks/bin-arm ./shadowsocks/bin
		echo arm > ./shadowsocks/.valid
		sed -i '/fancyss-hnd/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_mcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_tfo\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"arm\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "mtk" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		mv ./shadowsocks/bin-mtk ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		rm -rf ./shadowsocks/bin/README.md
		echo mtk > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"mtk\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi

	if [ "${release_type}" != "debug" ];then
		sed -i 's/PKG_EXTA=\"_debug\"/PKG_EXTA=\"\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${pkgtype}" == "lite" ];then
		sed -i 's/var PKG_TYPE=\"full\"/var PKG_TYPE=\"lite\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	
	if [ "${pkgtype}" == "full" ];then
		# remove marked comment
		# rm -rf ./shadowsocks/bin/sslocal
		sed -i 's/#@//g' ./shadowsocks/scripts/ss_proc_status.sh
		sed -i 's/#@//g' ./shadowsocks/scripts/ss_conf.sh
		echo ".show-btn5, .show-btn6{display: inline; !important}" >> ./shadowsocks/res/shadowsocks.css
	elif [ "${pkgtype}" == "lite" ];then
		# remove binaries
		rm -rf ./shadowsocks/bin/sslocal
		rm -rf ./shadowsocks/bin/v2ray
		rm -rf ./shadowsocks/bin/v2ray-plugin
		rm -rf ./shadowsocks/bin/kcptun
		rm -rf ./shadowsocks/bin/trojan
		rm -rf ./shadowsocks/bin/trojan
		rm -rf ./shadowsocks/bin/speederv1
		rm -rf ./shadowsocks/bin/speederv2
		rm -rf ./shadowsocks/bin/udp2raw
		rm -rf ./shadowsocks/bin/haproxy
		rm -rf ./shadowsocks/bin/smartdns
		rm -rf ./shadowsocks/bin/dohclient
		rm -rf ./shadowsocks/bin/dohclient-cache
		rm -rf ./shadowsocks/bin/naive
		rm -rf ./shadowsocks/bin/tuic-client
		rm -rf ./shadowsocks/bin/ipt2socks
		rm -rf ./shadowsocks/bin/haveged
		rm -rf ./shadowsocks/bin/hysteria2

		if [ "${platform}" == "hnd_v8" ];then
			rm -rf ./shadowsocks/bin/websocketd
		fi
		# remove scripts
		rm -rf ./shadowsocks/scripts/ss_lb_config.sh
		rm -rf ./shadowsocks/scripts/ss_v2ray.sh
		rm -rf ./shadowsocks/scripts/ss_rust_update.sh
		rm -rf ./shadowsocks/scripts/ss_socks5.sh
		rm -rf ./shadowsocks/scripts/ss_udp_status.sh
		# remove rules
		rm -rf ./shadowsocks/ss/rules/chn.acl
		rm -rf ./shadowsocks/ss/rules/gfwlist.acl
		rm -rf ./shadowsocks/ss/rules/cdns.json
		rm -rf ./shadowsocks/ss/rules/smartdns*.conf
		# remove pages
		rm -rf ./shadowsocks/webs/Module_shadowsocks_lb.asp
		rm -rf ./shadowsocks/webs/Module_shadowsocks_local.asp
		rm -rf ./shadowsocks/ss/dohclient
		# remove line
		sed -i '/fancyss-full/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss-full/d' ./shadowsocks/res/ss-menu.js
		sed -i '/fancyss-dns/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/naiveproxy/d' ./shadowsocks/res/ss-menu.js
		sed -i '/naiveproxy/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/tuic/d' ./shadowsocks/res/ss-menu.js
		# remove options from shadowsocks-rust: shadowsocks2022 encryption method
		sed -i 's/\,\s\"2022-blake3-aes-128-gcm\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"2022-blake3-aes-256-gcm\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"2022-blake3-chacha20-poly1305\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove lines bewteen matchs
		sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_naive_1/,/fancyss_naive_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_tuic_1/,/fancyss_tuic_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_hy2_1/,/fancyss_hy2_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove strings from page
		sed -i 's/\,\s\"naive_prot\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_prot\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_server\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_port\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_pass\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_json\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"tuic_json\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_vcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_tcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_rust\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_v2ray\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_v2ray_opts\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"use_kcp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_server\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_port\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_parameter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_method\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_encrypt\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_rcvwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_conn\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_extra\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_software\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_node\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_nu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_time\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_jitter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_report\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_drop\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_fec\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_timeout\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_report\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_jitter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_interval\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_drop\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_other\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rawmode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_ciphermode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_authmode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lowerlevel\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_other\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu_value\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_nocomp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_boost_enable\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_disable_filter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disableobscure\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disablechecksum\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_boost_enable\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_a\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_keeprule\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		# dns
		sed -i 's/\,\s\"ss_basic_chng_china_1_doh\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_chng_china_2_doh\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_chng_trust_1_opt_doh_val\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_chng_trust_2_opt_doh\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_smrt\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_sel_china\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_udp_china\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_udp_china_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_tcp_china\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_tcp_china_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_doh_china\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_sel_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_tcp_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_tcp_foreign_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_doh_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_cache_timeout\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_proxy\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_ecs_china\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_ecs_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_dohc_cache_reuse\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_s_resolver_doh\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \"负载均衡设置\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Socks5设置\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Module_shadowsocks_lb\.asp\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Module_shadowsocks_local\.asp\"//g' ./shadowsocks/res/ss-menu.js
		# hysteria2
		sed -i 's/\,\s\"ss_basic_hy2_up_speed\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_hy2_dl_speed\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_hy2_tfo_switch\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		# modify words
		# trojan 用xray运行，所以trojan多核心功能删除
		sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/八种客户端/五种客户端/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/科学上网工具/科学上网、游戏加速工具/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/14\.286/20/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\s\&\&\s\!\snaive_on//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/八种客户端/五种客户端/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./shadowsocks/res/ss-menu.js
		
		# add css
		echo ".show-btn5, .show-btn6{display: none; !important}" >> ./shadowsocks/res/shadowsocks.css
	fi

	if [ "${release_type}" == "release" ];then
		# 移除注释
		# remove match words: //fancyss-full //fancyss-full_1 //fancyss-full_2
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/res/ss-menu.js

		# remove match words: <!--fancyss-full-->
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./shadowsocks/res/ss-menu.js

		# remove line contain: <!--fancyss_full_1--> <!--fancyss_full_1-->
		sed -i 's/[ \t]*<!--fancyss_full_[1-2]-->//g' ./shadowsocks/webs/Module_shadowsocks.asp
		
		# remove line start of: //
		sed -i '/^[ \t]*\/\//d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/^[ \t]*\/\//d' ./shadowsocks/res/ss-menu.js

		# remove line <!-- ?? -->
		sed -i 's/<!--.*-->//g' ./shadowsocks/webs/Module_shadowsocks.asp

		# remove empty line
		sed -i '/^[[:space:]]*$/d' ./shadowsocks/webs/Module_shadowsocks.asp
	fi

	# when develop in other branch
	# master/fancyss_hnd
	# local CURRENT_BRANCH=$(git branch | head -n1 |awk '{print $2}')
	# if [ "${CURRENT_BRANCH}" != "master" ];then
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./shadowsocks/webs/Module_shadowsocks.asp
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./shadowsocks/res/ss-menu.js
	# fi
}

build_pkg() {
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	# different platform
	if [ ${release_type} == "release" ];then
		echo "打包：fancyss_${platform}_${pkgtype}.tar.gz"
		tar -zcf ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz shadowsocks >/dev/null
		md5value=$(md5sum ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz|tr " " "\n"|sed -n 1p)
		cat >>${CURR_PATH}/packages/version_tmp.json.js <<-EOF
			,"md5_${platform}_${pkgtype}":"${md5value}"
		EOF
	elif [ ${release_type} == "debug" ];then
		echo "打包：fancyss_${platform}_${pkgtype}_${release_type}.tar.gz"
		tar -zcf ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}_${release_type}.tar.gz shadowsocks >/dev/null
	fi
}

do_backup(){
	if [ "${CURR_PATH}/../fancyss_history_package" ];then
		local platform=$1
		local pkgtype=$2
		local release_type=$3
		if [ ${release_type} == "release" ];then
			cd ${CURR_PATH}
			HISTORY_DIR="${CURR_PATH}/../fancyss_history_package/fancyss_${platform}"
			mkdir -p ${HISTORY_DIR}
			# backup latested package after pack
			local backup_version=${VERSION}
			local backup_tar_md5=${md5value}
			
			echo "备份：fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
			cp ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz ${HISTORY_DIR}/fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz
			sed -i "/fancyss_${platform}_${pkgtype}_${backup_version}/d" ${HISTORY_DIR}/md5sum.txt
			if [ ! -f ${HISTORY_DIR}/md5sum.txt ];then
				touch ${HISTORY_DIR}/md5sum.txt
			fi
			echo ${backup_tar_md5} fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz >> ${HISTORY_DIR}/md5sum.txt
		fi
	fi
}

papare(){
	rm -f ${CURR_PATH}/packages/*
	cp_rules
	sync_binary
	cat >${CURR_PATH}/packages/version_tmp.json.js <<-EOF
	{
	"name":"fancyss"
	,"version":"${VERSION}"
	EOF
}

finish(){
	echo "}" >>${CURR_PATH}/packages/version_tmp.json.js
	cat ${CURR_PATH}/packages/version_tmp.json.js | jq '.' >${CURR_PATH}/packages/version.json.js
	rm -rf ${CURR_PATH}/packages/version_tmp.json.js
	echo "完成！生成的离线安装包在：${CURR_PATH}/packages"
}

pack(){
	gen_folder $1 $2 $3
	build_pkg $1 $2 $3
	if [ "$3" == "release" ];then
		do_backup  $1 $2 $3
	fi
	rm -rf ${CURR_PATH}/shadowsocks/
}

make(){
	papare
	# --- for release ---
	pack hnd full release
	pack hnd lite release
	pack hnd_v8 full release
	pack hnd_v8 lite release
	pack hnd lite release
	pack qca full release
	pack qca lite release
	pack arm full release
	pack arm lite release
	pack mtk full release
	pack mtk lite release
	# --- for debug ---
	pack hnd full debug
	pack hnd_v8 full debug
	pack qca full debug
	pack arm full debug
	pack mtk full debug
	finish
}

make
