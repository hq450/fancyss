.PHONY: all update_kcptun update_shadowsocks_rust update_v2ray update_xray update_naiveproxy update_ipt2socks update_tuic_client

all: update_kcptun update_ss_rust update_v2ray update_xray update_naive update_ipt2socks update_tuic_client

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

update_ipt2socks:
	ipt2socks/get_latest.sh

update_tuic_client:
	tuic-client/get_latest.sh
