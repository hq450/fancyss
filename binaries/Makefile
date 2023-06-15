.PHONY: all update_kcptun update_shadowsocks_rust update_v2ray update_xray update_naiveproxy

all: update_kcptun update_ss_rust update_v2ray update_xray update_naive

update_kcptun:
	kcptun/get_latest.sh

update_ss_rust:
	ss_rust/get_latest.sh

update_v2ray:
	v2ray/make_latest.sh

update_xray:
	xray/get_latest.sh

update_vray-plugin:
	vray-plugin/make_latest.sh

update_naive:
	naive/get_latest.sh