.PHONY: all update_kcptun update_shadowsocks_rust update_v2ray update_xray update_naiveproxy update_ipt2socks update_tuic_client update_sub_tool update_node_tool

all: update_kcptun update_ss_rust update_v2ray update_xray update_naive update_ipt2socks update_tuic_client update_sub_tool update_node_tool

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

update_sub_tool:
	cd ../tool/sub-tool && bash scripts/build-release.sh x86_64 armv5te armv7a armv7hf aarch64
	mkdir -p sub-tool
	cp -f ../tool/sub-tool/dist/sub-tool-v$$(cat ../tool/sub-tool/VERSION)-linux-* sub-tool/
	cp -f ../tool/sub-tool/dist/SHA256SUMS-v$$(cat ../tool/sub-tool/VERSION) sub-tool/

update_node_tool:
	cd ../tool/node-tool && rm -f dist/node-tool-v$$(cat VERSION)-linux-armv5te dist/node-tool-v$$(cat VERSION)-linux-armv7a dist/node-tool-v$$(cat VERSION)-linux-aarch64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv5te armv7a aarch64
	mkdir -p node-tool
	rm -f node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv5te node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7a node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-aarch64 node-tool/SHA256SUMS-v$$(cat ../tool/node-tool/VERSION)
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv5te node-tool/
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7a node-tool/
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-aarch64 node-tool/
	cp -f ../tool/node-tool/dist/SHA256SUMS-v$$(cat ../tool/node-tool/VERSION) node-tool/
