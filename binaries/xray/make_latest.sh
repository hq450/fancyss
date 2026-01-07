#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p $DIR/.build_xray
base_dir=$DIR/.build_xray
cd ${base_dir}
GO_VERSION="1.25.5"
UPX_VERSION="5.0.2"
CODENAME="hq450@fancyss"
TRIM_MODE="${TRIM_MODE:-default}"   # default | trim_apps | fancyss_min
TARGET_TAG="${XRAY_TAG:-}"          # optional, e.g. v25.12.8

echo "-----------------------------------------------------------------"

# prepare golang
if [ ! -x ${base_dir}/go/bin/go ];then
	#[ ! -f "go${GO_VERSION}.linux-amd64.tar.gz" ] && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
	[ ! -f "go${GO_VERSION}.linux-amd64.tar.gz" ] && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C ${base_dir} -xzf go${GO_VERSION}.linux-amd64.tar.gz
fi
export PATH=${base_dir}/go/bin:$PATH
go version
echo "-----------------------------------------------------------------"

# get upx
if [ ! -x ${base_dir}/upx ];then
	[ ! -f "upx-${UPX_VERSION}-amd64_linux.tar.xz" ] && wget https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz
	tar xf upx-${UPX_VERSION}-amd64_linux.tar.xz
	cp ${base_dir}/upx-${UPX_VERSION}-amd64_linux/upx ${base_dir}/
fi
${base_dir}/upx -V
echo "-----------------------------------------------------------------"

# get Xray-core
if [ ! -d ${base_dir}/Xray-core ];then
	echo "Clone v2fly/Xray-core repo..."
	git clone https://github.com/XTLS/Xray-core.git
	cd ${base_dir}/Xray-core
	go mod download || true
else
	cd ${base_dir}/Xray-core
	git reset --hard && git clean -fdqx
	git checkout main
	git pull || echo "WARNING: git pull failed, continue with existing local repo state..."
fi

if [ -n "${TARGET_TAG}" ];then
	VERSIONTAG="${TARGET_TAG}"
else
	VERSIONTAG="$(git describe --abbrev=0 --tags)"
fi

OUTTAG="${VERSIONTAG}"
if [ "${TRIM_MODE}" != "default" ]; then
	OUTTAG="${VERSIONTAG}_${TRIM_MODE}"
fi

rm -rf "${base_dir:?}/${OUTTAG}"
mkdir -p "${base_dir:?}/${OUTTAG}"
rm -rf ${base_dir}/armv5
rm -rf ${base_dir}/armv7
rm -rf ${base_dir}/armv64
git checkout $VERSIONTAG

apply_trim_apps() {
	# Keep: log + inbound/outbound managers + all proxies + all transports.
	# Remove: stats/router/api/commander/observatory/metrics/reverse/dns/fakedns (unused by fancyss minimal usage).

	# Default commander and related command services
	sed -i '\|app/commander|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/log/command|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/proxyman/command|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/stats/command|d' ${base_dir}/Xray-core/main/distro/all/all.go

	# Developer preview services/features
	sed -i '\|app/observatory/command|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/observatory|d' ${base_dir}/Xray-core/main/distro/all/all.go

	# Other optional features
	sed -i '\|app/dns/fakedns|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/dns|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/metrics|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/policy|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/reverse|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/router|d' ${base_dir}/Xray-core/main/distro/all/all.go
	sed -i '\|app/stats|d' ${base_dir}/Xray-core/main/distro/all/all.go
}

apply_trim_fancyss_min() {
	# Purpose:
	# - Keep all inbound/outbound proxy protocols and all transports.
	# - Drop big "peripheral" features that are frequently unused on routers:
	#   commander/api commands, observatory, metrics, reverse, fakedns, and
	#   heavy config translators (dns/router/policy/stats/api...) under infra/conf.
	#
	# Notes:
	# - Xray core provides essential default features when missing:
	#   dns client / policy manager / router / stats. So we can omit these apps.
	# - We keep JSON config only to avoid linking YAML/TOML libs.

	# 1) Create a minimal distro with all proxies+transports, but fewer apps/commands.
	mkdir -p ${base_dir}/Xray-core/main/distro/fancyss_min
	cat >${base_dir}/Xray-core/main/distro/fancyss_min/all.go <<'EOF'
package fancyss_min

import (
	// Mandatory features.
	_ "github.com/xtls/xray-core/app/dispatcher"
	_ "github.com/xtls/xray-core/app/log"
	_ "github.com/xtls/xray-core/app/proxyman/inbound"
	_ "github.com/xtls/xray-core/app/proxyman/outbound"

	// Fix dependency cycle caused by core import in internet package
	_ "github.com/xtls/xray-core/transport/internet/tagged/taggedimpl"

	// Inbound and outbound proxies (keep all).
	_ "github.com/xtls/xray-core/proxy/blackhole"
	_ "github.com/xtls/xray-core/proxy/dns"
	_ "github.com/xtls/xray-core/proxy/dokodemo"
	_ "github.com/xtls/xray-core/proxy/freedom"
	_ "github.com/xtls/xray-core/proxy/http"
	_ "github.com/xtls/xray-core/proxy/shadowsocks"
	_ "github.com/xtls/xray-core/proxy/socks"
	_ "github.com/xtls/xray-core/proxy/trojan"
	_ "github.com/xtls/xray-core/proxy/vless/inbound"
	_ "github.com/xtls/xray-core/proxy/vless/outbound"
	_ "github.com/xtls/xray-core/proxy/vmess/inbound"
	_ "github.com/xtls/xray-core/proxy/vmess/outbound"
	_ "github.com/xtls/xray-core/proxy/wireguard"

	// Transports (keep all).
	_ "github.com/xtls/xray-core/transport/internet/grpc"
	_ "github.com/xtls/xray-core/transport/internet/httpupgrade"
	_ "github.com/xtls/xray-core/transport/internet/kcp"
	_ "github.com/xtls/xray-core/transport/internet/reality"
	_ "github.com/xtls/xray-core/transport/internet/splithttp"
	_ "github.com/xtls/xray-core/transport/internet/tcp"
	_ "github.com/xtls/xray-core/transport/internet/tls"
	_ "github.com/xtls/xray-core/transport/internet/udp"
	_ "github.com/xtls/xray-core/transport/internet/websocket"

	// Transport headers
	_ "github.com/xtls/xray-core/transport/internet/headers/http"
	_ "github.com/xtls/xray-core/transport/internet/headers/srtp"
	_ "github.com/xtls/xray-core/transport/internet/headers/tls"
	_ "github.com/xtls/xray-core/transport/internet/headers/utp"
	_ "github.com/xtls/xray-core/transport/internet/headers/wechat"
	_ "github.com/xtls/xray-core/transport/internet/headers/wireguard"

	// JSON config only (trim off YAML/TOML).
	_ "github.com/xtls/xray-core/main/json"
)
EOF

	# 2) Point main to our minimal distro.
	sed -i 's@_ \"github.com/xtls/xray-core/main/distro/all\"@_ \"github.com/xtls/xray-core/main/distro/fancyss_min\"@' \
		${base_dir}/Xray-core/main/main.go

	# 3) Trim infra/conf: exclude files that pull in large optional app modules.
	#    We'll rebuild a minimal Config (log + inbounds/outbounds) under build tag "fancyss_trim".
	add_build_tag() {
		local file="$1"
		local tag_line='//go:build !fancyss_trim'
		if ! head -n 1 "$file" | grep -q '^//go:build'; then
			sed -i "1s@^@${tag_line}\n\n@" "$file"
		fi
	}

	add_build_tag ${base_dir}/Xray-core/infra/conf/api.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/dns.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/fakedns.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/init.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/metrics.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/observatory.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/policy.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/reverse.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/router.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/router_strategy.go
	add_build_tag ${base_dir}/Xray-core/infra/conf/xray.go

	cat >${base_dir}/Xray-core/infra/conf/xray_fancyss_min.go <<'EOF'
//go:build fancyss_trim

package conf

	import (
		"context"
		"encoding/json"
		"strings"

		"github.com/xtls/xray-core/app/dispatcher"
		"github.com/xtls/xray-core/app/proxyman"
		"github.com/xtls/xray-core/common/errors"
		"github.com/xtls/xray-core/common/net"
		"github.com/xtls/xray-core/common/serial"
		core "github.com/xtls/xray-core/core"
		"github.com/xtls/xray-core/transport/internet"
	)

var (
	inboundConfigLoader = NewJSONConfigLoader(ConfigCreatorCache{
		"tunnel":        func() interface{} { return new(DokodemoConfig) },
		"dokodemo-door": func() interface{} { return new(DokodemoConfig) },
		"http":          func() interface{} { return new(HTTPServerConfig) },
		"shadowsocks":   func() interface{} { return new(ShadowsocksServerConfig) },
		"mixed":         func() interface{} { return new(SocksServerConfig) },
		"socks":         func() interface{} { return new(SocksServerConfig) },
		"vless":         func() interface{} { return new(VLessInboundConfig) },
		"vmess":         func() interface{} { return new(VMessInboundConfig) },
		"trojan":        func() interface{} { return new(TrojanServerConfig) },
		"wireguard":     func() interface{} { return &WireGuardConfig{IsClient: false} },
	}, "protocol", "settings")

	outboundConfigLoader = NewJSONConfigLoader(ConfigCreatorCache{
		"block":       func() interface{} { return new(BlackholeConfig) },
		"blackhole":   func() interface{} { return new(BlackholeConfig) },
		"loopback":    func() interface{} { return new(LoopbackConfig) },
		"direct":      func() interface{} { return new(FreedomConfig) },
		"freedom":     func() interface{} { return new(FreedomConfig) },
		"http":        func() interface{} { return new(HTTPClientConfig) },
		"shadowsocks": func() interface{} { return new(ShadowsocksClientConfig) },
		"socks":       func() interface{} { return new(SocksClientConfig) },
		"vless":       func() interface{} { return new(VLessOutboundConfig) },
		"vmess":       func() interface{} { return new(VMessOutboundConfig) },
		"trojan":      func() interface{} { return new(TrojanClientConfig) },
		"dns":         func() interface{} { return new(DNSOutboundConfig) },
		"wireguard":   func() interface{} { return &WireGuardConfig{IsClient: true} },
	}, "protocol", "settings")
)

type MuxConfig struct {
	Enabled         bool   `json:"enabled"`
	Concurrency     int16  `json:"concurrency"`
	XudpConcurrency int16  `json:"xudpConcurrency"`
	XudpProxyUDP443 string `json:"xudpProxyUDP443"`
}

func (m *MuxConfig) Build() (*proxyman.MultiplexingConfig, error) {
	switch m.XudpProxyUDP443 {
	case "":
		m.XudpProxyUDP443 = "reject"
	case "reject", "allow", "skip":
	default:
		return nil, errors.New(`unknown "xudpProxyUDP443": `, m.XudpProxyUDP443)
	}
	return &proxyman.MultiplexingConfig{
		Enabled:         m.Enabled,
		Concurrency:     int32(m.Concurrency),
		XudpConcurrency: int32(m.XudpConcurrency),
		XudpProxyUDP443: m.XudpProxyUDP443,
	}, nil
}

type InboundDetourConfig struct {
	Protocol       string           `json:"protocol"`
	PortList       *PortList        `json:"port"`
	ListenOn       *Address         `json:"listen"`
	Settings       *json.RawMessage `json:"settings"`
	Tag            string           `json:"tag"`
	StreamSetting  *StreamConfig    `json:"streamSettings"`
}

func (c *InboundDetourConfig) Build() (*core.InboundHandlerConfig, error) {
	receiverSettings := &proxyman.ReceiverConfig{}

	if c.ListenOn == nil {
		if c.PortList == nil {
			return nil, errors.New("Listen on AnyIP but no Port(s) set in InboundDetour.")
		}
		receiverSettings.PortList = c.PortList.Build()
	} else {
		receiverSettings.Listen = c.ListenOn.Build()
		if c.PortList == nil {
			return nil, errors.New("Listen on specific ip without port in InboundDetour.")
		}
		receiverSettings.PortList = c.PortList.Build()
	}

	if c.StreamSetting != nil {
		ss, err := c.StreamSetting.Build()
		if err != nil {
			return nil, errors.New("failed to build stream settings for inbound detour").Base(err)
		}
		receiverSettings.StreamSettings = ss
	}

	settings := []byte("{}")
	if c.Settings != nil {
		settings = ([]byte)(*c.Settings)
	}

	rawConfig, err := inboundConfigLoader.LoadWithID(settings, c.Protocol)
	if err != nil {
		return nil, errors.New("failed to load inbound detour config for protocol ", c.Protocol).Base(err)
	}
	ts, err := rawConfig.(Buildable).Build()
	if err != nil {
		return nil, errors.New("failed to build inbound handler for protocol ", c.Protocol).Base(err)
	}

	return &core.InboundHandlerConfig{
		Tag:              c.Tag,
		ReceiverSettings: serial.ToTypedMessage(receiverSettings),
		ProxySettings:    serial.ToTypedMessage(ts),
	}, nil
}

type OutboundDetourConfig struct {
	Protocol       string           `json:"protocol"`
	SendThrough    *string          `json:"sendThrough"`
	Tag            string           `json:"tag"`
	Settings       *json.RawMessage `json:"settings"`
	StreamSetting  *StreamConfig    `json:"streamSettings"`
	ProxySettings  *ProxyConfig     `json:"proxySettings"`
	MuxSettings    *MuxConfig       `json:"mux"`
	TargetStrategy string           `json:"targetStrategy"`
}

func (c *OutboundDetourConfig) checkChainProxyConfig() error {
	if c.StreamSetting == nil || c.ProxySettings == nil || c.StreamSetting.SocketSettings == nil {
		return nil
	}
	if len(c.ProxySettings.Tag) > 0 && len(c.StreamSetting.SocketSettings.DialerProxy) > 0 {
		return errors.New("proxySettings.tag is conflicted with sockopt.dialerProxy").AtWarning()
	}
	return nil
}

func (c *OutboundDetourConfig) Build() (*core.OutboundHandlerConfig, error) {
	senderSettings := &proxyman.SenderConfig{}
	switch strings.ToLower(c.TargetStrategy) {
	case "asis", "":
		senderSettings.TargetStrategy = internet.DomainStrategy_AS_IS
	case "useip":
		senderSettings.TargetStrategy = internet.DomainStrategy_USE_IP
	case "useipv4":
		senderSettings.TargetStrategy = internet.DomainStrategy_USE_IP4
	case "useipv6":
		senderSettings.TargetStrategy = internet.DomainStrategy_USE_IP6
	case "useipv4v6":
		senderSettings.TargetStrategy = internet.DomainStrategy_USE_IP46
	case "useipv6v4":
		senderSettings.TargetStrategy = internet.DomainStrategy_USE_IP64
	case "forceip":
		senderSettings.TargetStrategy = internet.DomainStrategy_FORCE_IP
	case "forceipv4":
		senderSettings.TargetStrategy = internet.DomainStrategy_FORCE_IP4
	case "forceipv6":
		senderSettings.TargetStrategy = internet.DomainStrategy_FORCE_IP6
	case "forceipv4v6":
		senderSettings.TargetStrategy = internet.DomainStrategy_FORCE_IP46
	case "forceipv6v4":
		senderSettings.TargetStrategy = internet.DomainStrategy_FORCE_IP64
	default:
		return nil, errors.New("unsupported target domain strategy: ", c.TargetStrategy)
	}
	if err := c.checkChainProxyConfig(); err != nil {
		return nil, err
	}

	if c.SendThrough != nil {
		address := ParseSendThough(c.SendThrough)
		if strings.Contains(*c.SendThrough, "/") {
			senderSettings.ViaCidr = strings.Split(*c.SendThrough, "/")[1]
		} else {
			if address.Family().IsDomain() {
				domain := address.Address.Domain()
				if domain != "origin" && domain != "srcip" {
					return nil, errors.New("unable to send through: " + address.String())
				}
			}
		}
		senderSettings.Via = address.Build()
	}

	if c.StreamSetting != nil {
		ss, err := c.StreamSetting.Build()
		if err != nil {
			return nil, errors.New("failed to build stream settings for outbound detour").Base(err)
		}
		senderSettings.StreamSettings = ss
	}

	if c.ProxySettings != nil {
		ps, err := c.ProxySettings.Build()
		if err != nil {
			return nil, errors.New("invalid outbound detour proxy settings").Base(err)
		}
		if ps.TransportLayerProxy {
			if senderSettings.StreamSettings != nil {
				if senderSettings.StreamSettings.SocketSettings != nil {
					senderSettings.StreamSettings.SocketSettings.DialerProxy = ps.Tag
				} else {
					senderSettings.StreamSettings.SocketSettings = &internet.SocketConfig{DialerProxy: ps.Tag}
				}
			} else {
				senderSettings.StreamSettings = &internet.StreamConfig{SocketSettings: &internet.SocketConfig{DialerProxy: ps.Tag}}
			}
			ps = nil
		}
		senderSettings.ProxySettings = ps
	}

	if c.MuxSettings != nil {
		ms, err := c.MuxSettings.Build()
		if err != nil {
			return nil, errors.New("failed to build Mux config").Base(err)
		}
		senderSettings.MultiplexSettings = ms
	}

	settings := []byte("{}")
	if c.Settings != nil {
		settings = ([]byte)(*c.Settings)
	}
	rawConfig, err := outboundConfigLoader.LoadWithID(settings, c.Protocol)
	if err != nil {
		return nil, errors.New("failed to load outbound detour config for protocol ", c.Protocol).Base(err)
	}
	ts, err := rawConfig.(Buildable).Build()
	if err != nil {
		return nil, errors.New("failed to build outbound handler for protocol ", c.Protocol).Base(err)
	}

	return &core.OutboundHandlerConfig{
		SenderSettings: serial.ToTypedMessage(senderSettings),
		Tag:            c.Tag,
		ProxySettings:  serial.ToTypedMessage(ts),
	}, nil
}

type Config struct {
	LogConfig       *LogConfig            `json:"log"`
	InboundConfigs  []InboundDetourConfig `json:"inbounds"`
	OutboundConfigs []OutboundDetourConfig `json:"outbounds"`
}

func (c *Config) Override(o *Config, fn string) {
	if o.LogConfig != nil {
		c.LogConfig = o.LogConfig
	}
	if len(o.InboundConfigs) > 0 {
		c.InboundConfigs = append(c.InboundConfigs, o.InboundConfigs...)
		for i := range o.InboundConfigs {
			errors.LogInfo(context.Background(), "[", fn, "] appended inbound with tag: ", o.InboundConfigs[i].Tag)
		}
	}
	if len(o.OutboundConfigs) > 0 {
		c.OutboundConfigs = append(c.OutboundConfigs, o.OutboundConfigs...)
		for i := range o.OutboundConfigs {
			errors.LogInfo(context.Background(), "[", fn, "] appended outbound with tag: ", o.OutboundConfigs[i].Tag)
		}
	}
}

func (c *Config) Build() (*core.Config, error) {
	if err := PostProcessConfigureFile(c); err != nil {
		return nil, errors.New("failed to post-process configuration file").Base(err)
	}

	config := &core.Config{
		App: []*serial.TypedMessage{
			serial.ToTypedMessage(&dispatcher.Config{}),
			serial.ToTypedMessage(&proxyman.InboundConfig{}),
			serial.ToTypedMessage(&proxyman.OutboundConfig{}),
		},
	}

	var logConfMsg *serial.TypedMessage
	if c.LogConfig != nil {
		logConfMsg = serial.ToTypedMessage(c.LogConfig.Build())
	} else {
		logConfMsg = serial.ToTypedMessage(DefaultLogConfig())
	}
	config.App = append([]*serial.TypedMessage{logConfMsg}, config.App...)

	for _, rawInboundConfig := range c.InboundConfigs {
		ic, err := rawInboundConfig.Build()
		if err != nil {
			return nil, errors.New("failed to build inbound config with tag ", rawInboundConfig.Tag).Base(err)
		}
		config.Inbound = append(config.Inbound, ic)
	}

	for _, rawOutboundConfig := range c.OutboundConfigs {
		oc, err := rawOutboundConfig.Build()
		if err != nil {
			return nil, errors.New("failed to build outbound config with tag ", rawOutboundConfig.Tag).Base(err)
		}
		config.Outbound = append(config.Outbound, oc)
	}

	return config, nil
}

func ParseSendThough(Addr *string) *Address {
	var addr Address
	addr.Address = net.ParseAddress(strings.Split(*Addr, "/")[0])
	return &addr
}
EOF

	# 4) Trim infra/conf/serial to avoid YAML/TOML dependencies.
	if [ -f "${base_dir}/Xray-core/infra/conf/serial/loader.go" ]; then
		if ! head -n 1 "${base_dir}/Xray-core/infra/conf/serial/loader.go" | grep -q '^//go:build'; then
			sed -i '1s@^@//go:build !fancyss_trim\n\n@' "${base_dir}/Xray-core/infra/conf/serial/loader.go"
		fi
	fi
	if [ -f "${base_dir}/Xray-core/infra/conf/serial/builder.go" ]; then
		if ! head -n 1 "${base_dir}/Xray-core/infra/conf/serial/builder.go" | grep -q '^//go:build'; then
			sed -i '1s@^@//go:build !fancyss_trim\n\n@' "${base_dir}/Xray-core/infra/conf/serial/builder.go"
		fi
	fi

	cat >${base_dir}/Xray-core/infra/conf/serial/loader_fancyss_min.go <<'EOF'
//go:build fancyss_trim

package serial

import (
	"bytes"
	"encoding/json"
	"io"

	"github.com/xtls/xray-core/common/errors"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf"
	json_reader "github.com/xtls/xray-core/infra/conf/json"
)

type offset struct {
	line int
	char int
}

func findOffset(b []byte, o int) *offset {
	if o >= len(b) || o < 0 {
		return nil
	}
	line := 1
	char := 0
	for i, x := range b {
		if i == o {
			break
		}
		if x == '\n' {
			line++
			char = 0
		} else {
			char++
		}
	}
	return &offset{line: line, char: char}
}

func DecodeJSONConfig(reader io.Reader) (*conf.Config, error) {
	jsonConfig := &conf.Config{}

	jsonContent := bytes.NewBuffer(make([]byte, 0, 10240))
	jsonReader := io.TeeReader(&json_reader.Reader{Reader: reader}, jsonContent)
	decoder := json.NewDecoder(jsonReader)

	if err := decoder.Decode(jsonConfig); err != nil {
		var pos *offset
		cause := errors.Cause(err)
		switch tErr := cause.(type) {
		case *json.SyntaxError:
			pos = findOffset(jsonContent.Bytes(), int(tErr.Offset))
		case *json.UnmarshalTypeError:
			pos = findOffset(jsonContent.Bytes(), int(tErr.Offset))
		}
		if pos != nil {
			return nil, errors.New("failed to read config file at line ", pos.line, " char ", pos.char).Base(err)
		}
		return nil, errors.New("failed to read config file").Base(err)
	}

	return jsonConfig, nil
}

func LoadJSONConfig(reader io.Reader) (*core.Config, error) {
	jsonConfig, err := DecodeJSONConfig(reader)
	if err != nil {
		return nil, err
	}
	pbConfig, err := jsonConfig.Build()
	if err != nil {
		return nil, errors.New("failed to parse json config").Base(err)
	}
	return pbConfig, nil
}
EOF

	cat >${base_dir}/Xray-core/infra/conf/serial/builder_fancyss_min.go <<'EOF'
//go:build fancyss_trim

package serial

import (
	"context"
	"io"

	"github.com/xtls/xray-core/common/errors"
	creflect "github.com/xtls/xray-core/common/reflect"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf"
	"github.com/xtls/xray-core/main/confloader"
)

type readerDecoder func(io.Reader) (*conf.Config, error)

var ReaderDecoderByFormat = make(map[string]readerDecoder)

func mergeConfigs(files []*core.ConfigSource) (*conf.Config, error) {
	cf := &conf.Config{}
	for i, file := range files {
		errors.LogInfo(context.Background(), "Reading config: ", file)
		r, err := confloader.LoadConfig(file.Name)
		if err != nil {
			return nil, errors.New("failed to read config: ", file).Base(err)
		}
		decoder, ok := ReaderDecoderByFormat[file.Format]
		if !ok {
			return nil, errors.New("unsupported config format: ", file.Format).AtError()
		}
		c, err := decoder(r)
		if err != nil {
			return nil, errors.New("failed to decode config: ", file).Base(err)
		}
		if i == 0 {
			*cf = *c
			continue
		}
		cf.Override(c, file.Name)
	}
	return cf, nil
}

func BuildConfig(files []*core.ConfigSource) (*core.Config, error) {
	config, err := mergeConfigs(files)
	if err != nil {
		return nil, err
	}
	return config.Build()
}

func MergeConfigFromFiles(files []*core.ConfigSource) (string, error) {
	c, err := mergeConfigs(files)
	if err != nil {
		return "", err
	}
	if j, ok := creflect.MarshalToJson(c, true); ok {
		return j, nil
	}
	return "", errors.New("marshal to json failed.").AtError()
}

func init() {
	ReaderDecoderByFormat["json"] = DecodeJSONConfig
	core.ConfigBuilderForFiles = BuildConfig
	core.ConfigMergedFormFiles = MergeConfigFromFiles
}
EOF
}

case "${TRIM_MODE}" in
	default)
		;;
	trim_apps)
		apply_trim_apps
		;;
	fancyss_min)
		apply_trim_fancyss_min
		;;
	*)
		echo "Unknown TRIM_MODE: ${TRIM_MODE} (expected: default|trim_apps|fancyss_min)" >&2
		exit 1
		;;
esac

# build xray
build_v2() {
	TMP=$(mktemp -d)
	BUILDNAME=$NOW
	case $1 in
		armv5)
			GOARM=5
			GOARCH=arm
			;;		
		armv7)
			GOARM=7
			GOARCH=arm
			;;
		arm64)
			GOARM=
			GOARCH=arm64
			;;
	esac
	cd ${base_dir}/Xray-core

	local VERSION=$(git describe --abbrev=0 --tags | sed 's/v//')

	LDFLAGS="-s -w -buildid="
	local GOTAGS=""
	if [ "${TRIM_MODE}" = "fancyss_min" ]; then
		GOTAGS="-tags fancyss_trim"
	fi

	echo "Compile xray $1 GOARM=${GOARM} GOARCH=${GOARCH}..."
	env CGO_ENABLED=0 GOOS=linux GOARM=$GOARM GOARCH=$GOARCH go build -v ${GOTAGS} -o "${TMP}/xray_${1}" -trimpath -ldflags "$LDFLAGS" ./main

	cp ${TMP}/xray_${1} ${base_dir}/${OUTTAG}/
	rm -rf ${TMP}
}

compress_binary(){
	echo "-----------------------------------------------------------------"
	ls -l ${base_dir}/${OUTTAG}/*
	echo "-----------------------------------------------------------------"
	${base_dir}/upx --lzma --ultra-brute ${base_dir}/${OUTTAG}/*

	${base_dir}/upx -t ${base_dir}/${OUTTAG}/*

	cd ${base_dir}/${OUTTAG}/
	md5sum * >md5sum.txt
	
	cd ${base_dir}
	rm -rf ../${OUTTAG}
	mv -f ${OUTTAG} ..

	echo -n "$OUTTAG" > latest_2_${TRIM_MODE}.txt
	if [ "${TRIM_MODE}" = "default" ] && [ -z "${TARGET_TAG}" ]; then
		echo -n "$OUTTAG" > latest_2.txt
	fi
}

build_v2 armv5
build_v2 armv7
build_v2 arm64
compress_binary
