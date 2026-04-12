.PHONY: all update_kcptun update_shadowsocks_rust update_v2ray update_xray update_naiveproxy update_ipt2socks update_tuic_client update_geotool update_xapi_tool update_sub_tool update_node_tool update_websocketd update_status_tool update_webtest_tool

all: update_kcptun update_ss_rust update_v2ray update_xray update_naive update_ipt2socks update_tuic_client update_geotool update_xapi_tool update_sub_tool update_node_tool update_websocketd update_status_tool update_webtest_tool

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

update_geotool:
	cd ../tool/geotool && rm -f dist/geotool-v$$(cat VERSION)-linux-armv5te dist/geotool-v$$(cat VERSION)-linux-armv7a dist/geotool-v$$(cat VERSION)-linux-armv7hf dist/geotool-v$$(cat VERSION)-linux-aarch64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv5te armv7a armv7hf aarch64
	mkdir -p geotool
	rm -f geotool/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv5te geotool/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv7a geotool/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv7hf geotool/geotool-v$$(cat ../tool/geotool/VERSION)-linux-aarch64 geotool/SHA256SUMS-v$$(cat ../tool/geotool/VERSION)
	cp -f ../tool/geotool/dist/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv5te geotool/
	cp -f ../tool/geotool/dist/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv7a geotool/
	cp -f ../tool/geotool/dist/geotool-v$$(cat ../tool/geotool/VERSION)-linux-armv7hf geotool/
	cp -f ../tool/geotool/dist/geotool-v$$(cat ../tool/geotool/VERSION)-linux-aarch64 geotool/
	cp -f ../tool/geotool/dist/SHA256SUMS-v$$(cat ../tool/geotool/VERSION) geotool/

update_xapi_tool:
	cd ../tool/xapi-tool && rm -f dist/xapi-tool-v$$(cat VERSION)-linux-armv7a dist/xapi-tool-v$$(cat VERSION)-linux-armv7hf dist/xapi-tool-v$$(cat VERSION)-linux-aarch64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv7a armv7hf aarch64
	mkdir -p xapi-tool
	rm -f xapi-tool/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-armv7a xapi-tool/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-armv7hf xapi-tool/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-aarch64 xapi-tool/SHA256SUMS-v$$(cat ../tool/xapi-tool/VERSION)
	cp -f ../tool/xapi-tool/dist/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-armv7a xapi-tool/
	cp -f ../tool/xapi-tool/dist/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-armv7hf xapi-tool/
	cp -f ../tool/xapi-tool/dist/xapi-tool-v$$(cat ../tool/xapi-tool/VERSION)-linux-aarch64 xapi-tool/
	cp -f ../tool/xapi-tool/dist/SHA256SUMS-v$$(cat ../tool/xapi-tool/VERSION) xapi-tool/

update_sub_tool:
	cd ../tool/sub-tool && bash scripts/build-release.sh x86_64 armv5te armv7a armv7hf aarch64
	mkdir -p sub-tool
	cp -f ../tool/sub-tool/dist/sub-tool-v$$(cat ../tool/sub-tool/VERSION)-linux-* sub-tool/
	cp -f ../tool/sub-tool/dist/SHA256SUMS-v$$(cat ../tool/sub-tool/VERSION) sub-tool/

update_node_tool:
	cd ../tool/node-tool && rm -f dist/node-tool-v$$(cat VERSION)-linux-armv5te dist/node-tool-v$$(cat VERSION)-linux-armv7a dist/node-tool-v$$(cat VERSION)-linux-armv7hf dist/node-tool-v$$(cat VERSION)-linux-aarch64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv5te armv7a armv7hf aarch64
	mkdir -p node-tool
	rm -f node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv5te node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7a node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7hf node-tool/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-aarch64 node-tool/SHA256SUMS-v$$(cat ../tool/node-tool/VERSION)
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv5te node-tool/
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7a node-tool/
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-armv7hf node-tool/
	cp -f ../tool/node-tool/dist/node-tool-v$$(cat ../tool/node-tool/VERSION)-linux-aarch64 node-tool/
	cp -f ../tool/node-tool/dist/SHA256SUMS-v$$(cat ../tool/node-tool/VERSION) node-tool/

update_websocketd:
	cd ../tool/ws-tool && rm -f dist/websocketd-v$$(cat VERSION)-linux-armv5te dist/websocketd-v$$(cat VERSION)-linux-armv7a dist/websocketd-v$$(cat VERSION)-linux-armv7hf dist/websocketd-v$$(cat VERSION)-linux-aarch64 dist/websocketd-v$$(cat VERSION)-linux-x86_64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv5te armv7a armv7hf aarch64 x86_64
	mkdir -p websocketd
	rm -f websocketd/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv5te websocketd/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv7a websocketd/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv7hf websocketd/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-aarch64 websocketd/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-x86_64 websocketd/SHA256SUMS-v$$(cat ../tool/ws-tool/VERSION)
	cp -f ../tool/ws-tool/dist/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv5te websocketd/
	cp -f ../tool/ws-tool/dist/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv7a websocketd/
	cp -f ../tool/ws-tool/dist/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-armv7hf websocketd/
	cp -f ../tool/ws-tool/dist/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-aarch64 websocketd/
	cp -f ../tool/ws-tool/dist/websocketd-v$$(cat ../tool/ws-tool/VERSION)-linux-x86_64 websocketd/
	cp -f ../tool/ws-tool/dist/SHA256SUMS-v$$(cat ../tool/ws-tool/VERSION) websocketd/

update_status_tool:
	cd ../tool/status-tool && rm -f dist/status-tool-v$$(cat VERSION)-linux-armv5te dist/status-tool-v$$(cat VERSION)-linux-armv7a dist/status-tool-v$$(cat VERSION)-linux-armv7hf dist/status-tool-v$$(cat VERSION)-linux-aarch64 dist/status-tool-v$$(cat VERSION)-linux-x86_64 dist/statusctl-v$$(cat VERSION)-linux-armv5te dist/statusctl-v$$(cat VERSION)-linux-armv7a dist/statusctl-v$$(cat VERSION)-linux-armv7hf dist/statusctl-v$$(cat VERSION)-linux-aarch64 dist/statusctl-v$$(cat VERSION)-linux-x86_64 dist/SHA256SUMS-v$$(cat VERSION) && bash scripts/build-release.sh armv5te armv7a armv7hf aarch64 x86_64
	mkdir -p status-tool
	rm -f status-tool/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv5te status-tool/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv7a status-tool/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv7hf status-tool/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-aarch64 status-tool/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-x86_64 status-tool/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv5te status-tool/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv7a status-tool/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv7hf status-tool/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-aarch64 status-tool/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-x86_64 status-tool/SHA256SUMS-v$$(cat ../tool/status-tool/VERSION)
	cp -f ../tool/status-tool/dist/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv5te status-tool/
	cp -f ../tool/status-tool/dist/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv7a status-tool/
	cp -f ../tool/status-tool/dist/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-armv7hf status-tool/
	cp -f ../tool/status-tool/dist/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-aarch64 status-tool/
	cp -f ../tool/status-tool/dist/status-tool-v$$(cat ../tool/status-tool/VERSION)-linux-x86_64 status-tool/
	cp -f ../tool/status-tool/dist/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv5te status-tool/
	cp -f ../tool/status-tool/dist/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv7a status-tool/
	cp -f ../tool/status-tool/dist/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-armv7hf status-tool/
	cp -f ../tool/status-tool/dist/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-aarch64 status-tool/
	cp -f ../tool/status-tool/dist/statusctl-v$$(cat ../tool/status-tool/VERSION)-linux-x86_64 status-tool/
	cp -f ../tool/status-tool/dist/SHA256SUMS-v$$(cat ../tool/status-tool/VERSION) status-tool/

update_webtest_tool:
	cd ../tool/webtest-tool && rm -f dist/webtest-tool-v$$(cat VERSION)-linux-armv5te dist/webtest-tool-v$$(cat VERSION)-linux-armv7a dist/webtest-tool-v$$(cat VERSION)-linux-armv7hf dist/webtest-tool-v$$(cat VERSION)-linux-aarch64 dist/webtest-tool-v$$(cat VERSION)-linux-x86_64 dist/webtestctl-v$$(cat VERSION)-linux-armv5te dist/webtestctl-v$$(cat VERSION)-linux-armv7a dist/webtestctl-v$$(cat VERSION)-linux-armv7hf dist/webtestctl-v$$(cat VERSION)-linux-aarch64 dist/webtestctl-v$$(cat VERSION)-linux-x86_64 && bash scripts/build-release.sh armv5te armv7a armv7hf aarch64 x86_64
	mkdir -p webtest-tool
	rm -f webtest-tool/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv5te webtest-tool/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7a webtest-tool/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7hf webtest-tool/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-aarch64 webtest-tool/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-x86_64 webtest-tool/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv5te webtest-tool/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7a webtest-tool/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7hf webtest-tool/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-aarch64 webtest-tool/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-x86_64
	cp -f ../tool/webtest-tool/dist/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv5te webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7a webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7hf webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-aarch64 webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtest-tool-v$$(cat ../tool/webtest-tool/VERSION)-linux-x86_64 webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv5te webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7a webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-armv7hf webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-aarch64 webtest-tool/
	cp -f ../tool/webtest-tool/dist/webtestctl-v$$(cat ../tool/webtest-tool/VERSION)-linux-x86_64 webtest-tool/
