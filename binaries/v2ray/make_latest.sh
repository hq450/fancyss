#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p $DIR/.build_v2ray
base_dir=$DIR/.build_v2ray
cd ${base_dir}
GO_VERSION="1.25.5"
UPX_VERSION="5.0.2"
CODENAME="hq450@fancyss"
TRIM_MODE="${TRIM_MODE:-default}" # default | vmess_only | vmess_v4_min | vmess_v4_min_req
TARGET_TAG="${V2RAY_TAG:-}"       # optional, e.g. v5.42.0

echo "-----------------------------------------------------------------"

# prepare golang
if [ ! -x ${base_dir}/go/bin/go ];then
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

# get v2ray-core
if [ ! -d ${base_dir}/v2ray-core ];then
	echo "Clone v2fly/v2ray-core repo..."
	git clone https://github.com/v2fly/v2ray-core.git
	cd ${base_dir}/v2ray-core
	go mod download || true
else
	cd ${base_dir}/v2ray-core
	git reset --hard && git clean -fdqx
	git checkout master
	git pull || echo "WARNING: git pull failed, continue with existing local repo state..."
fi
if [ -n "${TARGET_TAG}" ];then
	VERSIONTAG="${TARGET_TAG}"
else
	VERSIONTAG="$(git describe --abbrev=0 --tags)"
fi

OUTTAG="${VERSIONTAG}"
if [ "${TRIM_MODE}" != "default" ];then
	OUTTAG="${VERSIONTAG}_${TRIM_MODE}"
fi

rm -rf "${base_dir:?}/${OUTTAG}"
mkdir -p "${base_dir:?}/${OUTTAG}"
rm -rf "${base_dir:?}/armv5" "${base_dir:?}/armv7" "${base_dir:?}/armv64"
git checkout "${VERSIONTAG}"

apply_trim_default() {
	# NOTE: this does not aim to be minimal, it only removes some optional features.
	# Default commander and all its services. This is an optional feature.
	sed -i '/v5\/app\/commander/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/log\/command/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/proxyman\/command/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/stats\/command/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	# remove some features from xray
	sed -i '/simplified/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/subscription/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	# Developer preview services
	sed -i '/v5\/app\/instman\/command/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/observatory\/command/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	# Developer preview features
	sed -i '/v5\/app\/instman/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/observatory/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/restfulapi/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/v5\/app\/tun/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	# Developer preview proxies
	sed -i '/vlite\/inbound/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/vlite\/outbound/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	sed -i '/shadowsocks2022/d' ${base_dir}/v2ray-core/main/distro/all/all.go
	# Geo loaders
	sed -i '/geodata/d' ${base_dir}/v2ray-core/main/distro/all/all.go
}

apply_trim_vmess_only() {
	# This is an aggressive trim mode for tiny routers:
	# - keep only log + inbound/outbound managers (+ dispatcher)
	# - keep only vmess outbound protocol
	# - keep only minimal transports (tcp/tls/ws/udp) and noop header
	# - keep only json config loader (no toml/yaml)

	# 1) minimal config loader (register json + auto only)
	mkdir -p ${base_dir}/v2ray-core/main/formats/fancyssjson
	cat >${base_dir}/v2ray-core/main/formats/fancyssjson/formats.go <<'EOF'
package fancyssjson

import (
	"errors"
	"io"
	"os"

	core "github.com/v2fly/v2ray-core/v5"
	"github.com/v2fly/v2ray-core/v5/common"
	"github.com/v2fly/v2ray-core/v5/common/cmdarg"
	"github.com/v2fly/v2ray-core/v5/infra/conf/serial"
)

func init() {
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatJSON},
		Extension: []string{".json", ".jsonc"},
		Loader:    loadJSON,
	}))
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatAuto},
		Extension: nil,
		Loader:    loadJSON,
	}))
}

func loadJSON(input interface{}) (*core.Config, error) {
	switch v := input.(type) {
	case cmdarg.Arg:
		return loadJSON(v.String())
	case []string:
		if len(v) != 1 {
			return nil, errors.New("multiple config files are not supported in fancyssjson loader")
		}
		return loadJSON(v[0])
	case string:
		f, err := os.Open(v)
		if err != nil {
			return nil, err
		}
		defer f.Close()
		return serial.LoadJSONConfig(f)
	case io.Reader:
		return serial.LoadJSONConfig(v)
	default:
		return nil, errors.New("unsupported config input type")
	}
}
EOF

	# 2) minimal distro package
	mkdir -p ${base_dir}/v2ray-core/main/distro/fancyss_min
	cat >${base_dir}/v2ray-core/main/distro/fancyss_min/all.go <<'EOF'
package fancyss_min

import (
	// Core mandatory features
	_ "github.com/v2fly/v2ray-core/v5/app/dispatcher"
	_ "github.com/v2fly/v2ray-core/v5/app/log"
	_ "github.com/v2fly/v2ray-core/v5/app/proxyman/inbound"
	_ "github.com/v2fly/v2ray-core/v5/app/proxyman/outbound"

	// Fix dependency cycle caused by core import in internet package
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tagged/taggedimpl"

	// Inbound / outbound proxies
	_ "github.com/v2fly/v2ray-core/v5/proxy/dokodemo"
	_ "github.com/v2fly/v2ray-core/v5/proxy/socks"
	_ "github.com/v2fly/v2ray-core/v5/proxy/vmess/outbound"

	// Transports (minimal)
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tcp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tls"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/udp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/websocket"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/noop"

	// JSON config loader (minimal)
	_ "github.com/v2fly/v2ray-core/v5/main/formats/fancyssjson"
)
EOF

	# 3) point main to our minimal distro
	sed -i 's@_ "github.com/v2fly/v2ray-core/v5/main/distro/all"@_ "github.com/v2fly/v2ray-core/v5/main/distro/fancyss_min"@' \
		${base_dir}/v2ray-core/main/main.go
}

apply_trim_vmess_v4_min() {
	local WITH_REQUEST="${1:-0}" # 0|1

	# This trim mode removes the heavy infra/conf/v4 JSON translator dependency by
	# parsing a subset of v4 JSON config directly into core.Config.
	#
	# Supported (intended for fancyss):
	# - inbound: socks + dokodemo-door
	# - outbound: vmess
	# - stream: tcp/ws/kcp/quic/h2/grpc (+ tls)
	#
	# Optional (WITH_REQUEST=1):
	# - stream: meek/mekya via v5-style streamSettings.transport + transportSettings

	local formats_pkg="fancyssv4min"
	if [ "${WITH_REQUEST}" = "1" ]; then
		formats_pkg="fancyssv4minreq"
	fi

	mkdir -p "${base_dir}/v2ray-core/main/formats/${formats_pkg}"
	if [ "${WITH_REQUEST}" = "1" ]; then
		cat >"${base_dir}/v2ray-core/main/formats/${formats_pkg}/formats.go" <<'EOF'
package fancyssv4minreq

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"os"
	"sort"
	"strings"

	proto "github.com/golang/protobuf/proto"
	"google.golang.org/protobuf/encoding/protojson"

	core "github.com/v2fly/v2ray-core/v5"
	"github.com/v2fly/v2ray-core/v5/app/dispatcher"
	applog "github.com/v2fly/v2ray-core/v5/app/log"
	"github.com/v2fly/v2ray-core/v5/app/proxyman"
	"github.com/v2fly/v2ray-core/v5/common"
	"github.com/v2fly/v2ray-core/v5/common/cmdarg"
	clog "github.com/v2fly/v2ray-core/v5/common/log"
	v2net "github.com/v2fly/v2ray-core/v5/common/net"
	"github.com/v2fly/v2ray-core/v5/common/protocol"
	cserial "github.com/v2fly/v2ray-core/v5/common/serial"
	"github.com/v2fly/v2ray-core/v5/proxy/dokodemo"
	"github.com/v2fly/v2ray-core/v5/proxy/socks"
	vmess "github.com/v2fly/v2ray-core/v5/proxy/vmess"
	vmessout "github.com/v2fly/v2ray-core/v5/proxy/vmess/outbound"
	"github.com/v2fly/v2ray-core/v5/transport/internet"
	httpheader "github.com/v2fly/v2ray-core/v5/transport/internet/headers/http"
	noop "github.com/v2fly/v2ray-core/v5/transport/internet/headers/noop"
	srtp "github.com/v2fly/v2ray-core/v5/transport/internet/headers/srtp"
	tlsheader "github.com/v2fly/v2ray-core/v5/transport/internet/headers/tls"
	utp "github.com/v2fly/v2ray-core/v5/transport/internet/headers/utp"
	wechat "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wechat"
	wireguard "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wireguard"
	"github.com/v2fly/v2ray-core/v5/transport/internet/http"
	"github.com/v2fly/v2ray-core/v5/transport/internet/kcp"
	"github.com/v2fly/v2ray-core/v5/transport/internet/quic"
	"github.com/v2fly/v2ray-core/v5/transport/internet/tcp"
	"github.com/v2fly/v2ray-core/v5/transport/internet/tls"
	"github.com/v2fly/v2ray-core/v5/transport/internet/websocket"

	grpc "github.com/v2fly/v2ray-core/v5/transport/internet/grpc"
	httpupgrade "github.com/v2fly/v2ray-core/v5/transport/internet/httpupgrade"

	meek "github.com/v2fly/v2ray-core/v5/transport/internet/request/stereotype/meek"
	mekya "github.com/v2fly/v2ray-core/v5/transport/internet/request/stereotype/mekya"
)

func init() {
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatJSON},
		Extension: []string{".json", ".jsonc"},
		Loader:    loadJSON,
	}))
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatAuto},
		Extension: nil,
		Loader:    loadJSON,
	}))
}

func loadJSON(input interface{}) (*core.Config, error) {
	switch v := input.(type) {
	case cmdarg.Arg:
		return loadJSON(v.String())
	case []string:
		if len(v) != 1 {
			return nil, errors.New("multiple config files are not supported in fancyssv4minreq loader")
		}
		return loadJSON(v[0])
	case string:
		b, err := os.ReadFile(v)
		if err != nil {
			return nil, err
		}
		return LoadConfigBytes(b)
	case io.Reader:
		b, err := io.ReadAll(v)
		if err != nil {
			return nil, err
		}
		return LoadConfigBytes(b)
	default:
		return nil, errors.New("unsupported config input type")
	}
}

type v4Config struct {
	Log       *v4LogConfig        `json:"log"`
	Inbounds  []v4InboundConfig   `json:"inbounds"`
	Outbounds []v4OutboundConfig  `json:"outbounds"`
	Inbound   *v4InboundConfig    `json:"inbound"`
	Outbound  *v4OutboundConfig   `json:"outbound"`
}

type v4LogConfig struct {
	Access   string `json:"access"`
	Error    string `json:"error"`
	Loglevel string `json:"loglevel"`
}

type v4InboundConfig struct {
	Port     int             `json:"port"`
	Listen   string          `json:"listen"`
	Protocol string          `json:"protocol"`
	Settings json.RawMessage `json:"settings"`
	Tag      string          `json:"tag"`
}

type v4OutboundConfig struct {
	Tag           string         `json:"tag"`
	Protocol      string         `json:"protocol"`
	Settings      json.RawMessage `json:"settings"`
	StreamSettings *v4StreamConfig `json:"streamSettings"`
	Mux           *v4MuxConfig   `json:"mux"`
}

type v4MuxConfig struct {
	Enabled     bool  `json:"enabled"`
	Concurrency int16 `json:"concurrency"`
}

type v4StreamConfig struct {
	Network      string          `json:"network"`
	Security     string          `json:"security"`
	TLSSettings  json.RawMessage `json:"tlsSettings"`
	TCPSettings  json.RawMessage `json:"tcpSettings"`
	KCPSettings  json.RawMessage `json:"kcpSettings"`
	WSSettings   json.RawMessage `json:"wsSettings"`
	HTTPSettings json.RawMessage `json:"httpSettings"`
	QUICSettings json.RawMessage `json:"quicSettings"`
	GRPCSettings json.RawMessage `json:"grpcSettings"`

	Transport         string          `json:"transport"`
	TransportSettings json.RawMessage `json:"transportSettings"`
	SecuritySettings  json.RawMessage `json:"securitySettings"`
}

type v4SocksInboundSettings struct {
	Auth       string `json:"auth"`
	UDP        bool   `json:"udp"`
	IP         string `json:"ip"`
	UDPEnabled bool   `json:"udpEnabled"`
	Address    string `json:"address"`
}

type v4DokodemoInboundSettings struct {
	Address        *string `json:"address"`
	Port           *uint32 `json:"port"`
	Network        string  `json:"network"`
	Timeout        uint32  `json:"timeout"`
	FollowRedirect bool    `json:"followRedirect"`
	UserLevel      uint32  `json:"userLevel"`
}

type v4VmessOutboundSettings struct {
	VNext []struct {
		Address string `json:"address"`
		Port    uint32 `json:"port"`
		Users   []struct {
			ID       string `json:"id"`
			AlterID  uint32 `json:"alterId"`
			Security string `json:"security"`
			Level    uint32 `json:"level"`
			Email    string `json:"email"`
		} `json:"users"`
	} `json:"vnext"`

	Address string `json:"address"`
	Port    uint32 `json:"port"`
	UUID    string `json:"uuid"`
}

type v4TLSSettings struct {
	AllowInsecure bool     `json:"allowInsecure"`
	ALPN          []string `json:"alpn"`
	ServerName    *string  `json:"serverName"`
}

type v4TCPSettings struct {
	Header struct {
		Type     string          `json:"type"`
		Request  v4HTTPRequest   `json:"request"`
		Response v4HTTPResponse  `json:"response"`
	} `json:"header"`
	AcceptProxyProtocol bool `json:"acceptProxyProtocol"`
}

type v4StringList []string

func (s *v4StringList) UnmarshalJSON(b []byte) error {
	b = bytes.TrimSpace(b)
	if len(b) == 0 || bytes.Equal(b, []byte("null")) {
		*s = nil
		return nil
	}
	if b[0] == '"' {
		var v string
		if err := json.Unmarshal(b, &v); err != nil {
			return err
		}
		*s = v4StringList{v}
		return nil
	}
	var arr []string
	if err := json.Unmarshal(b, &arr); err == nil {
		*s = v4StringList(arr)
		return nil
	}
	return errors.New("expected string or []string")
}

type v4HTTPRequest struct {
	Version string              `json:"version"`
	Method  string              `json:"method"`
	Path    v4StringList        `json:"path"`
	Headers map[string]v4StringList `json:"headers"`
}

type v4HTTPResponse struct {
	Version string              `json:"version"`
	Status  string              `json:"status"`
	Reason  string              `json:"reason"`
	Headers map[string]v4StringList `json:"headers"`
}

type v4KCPSettings struct {
	Mtu             *uint32         `json:"mtu"`
	Tti             *uint32         `json:"tti"`
	UpCap           *uint32         `json:"uplinkCapacity"`
	DownCap         *uint32         `json:"downlinkCapacity"`
	Congestion      *bool           `json:"congestion"`
	ReadBufferSize  *uint32         `json:"readBufferSize"`
	WriteBufferSize *uint32         `json:"writeBufferSize"`
	Header          json.RawMessage `json:"header"`
	Seed            *string         `json:"seed"`
}

type v4WSSettings struct {
	Path                string            `json:"path"`
	Headers             map[string]string `json:"headers"`
	AcceptProxyProtocol bool              `json:"acceptProxyProtocol"`
}

type v4HTTPSettings struct {
	Host v4StringList `json:"host"`
	Path string   `json:"path"`
}

type v4QUICSettings struct {
	Header   json.RawMessage `json:"header"`
	Security string          `json:"security"`
	Key      string          `json:"key"`
}

type v4GRPCSettings struct {
	ServiceName string `json:"serviceName"`
}

func LoadConfigBytes(raw []byte) (*core.Config, error) {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 {
		return nil, errors.New("empty config")
	}
	var c v4Config
	if err := json.Unmarshal(raw, &c); err != nil {
		return nil, err
	}

	inbounds := c.Inbounds
	outbounds := c.Outbounds
	if c.Inbound != nil {
		inbounds = append(inbounds, *c.Inbound)
	}
	if c.Outbound != nil {
		outbounds = append(outbounds, *c.Outbound)
	}

	cfg := &core.Config{}
	cfg.App = append(cfg.App,
		cserial.ToTypedMessage(&applog.Config{
			Error:  &applog.LogSpecification{Type: applog.LogType_None, Level: clog.Severity_Unknown},
			Access: &applog.LogSpecification{Type: applog.LogType_None, Level: clog.Severity_Unknown},
		}),
		cserial.ToTypedMessage(&dispatcher.Config{}),
		cserial.ToTypedMessage(&proxyman.InboundConfig{}),
		cserial.ToTypedMessage(&proxyman.OutboundConfig{}),
	)

	for _, ib := range inbounds {
		ic, err := buildInbound(ib)
		if err != nil {
			return nil, err
		}
		cfg.Inbound = append(cfg.Inbound, ic)
	}
	for _, ob := range outbounds {
		oc, err := buildOutbound(ob)
		if err != nil {
			return nil, err
		}
		cfg.Outbound = append(cfg.Outbound, oc)
	}
	return cfg, nil
}

func buildInbound(ib v4InboundConfig) (*core.InboundHandlerConfig, error) {
	if ib.Port <= 0 || ib.Port > 65535 {
		return nil, errors.New("invalid inbound port")
	}
	receiver := &proxyman.ReceiverConfig{
		PortRange: &v2net.PortRange{From: uint32(ib.Port), To: uint32(ib.Port)},
	}
	if ib.Listen != "" {
		receiver.Listen = v2net.NewIPOrDomain(v2net.ParseAddress(ib.Listen))
	}

	var proxyCfg proto.Message
	switch strings.ToLower(ib.Protocol) {
	case "socks":
		var s v4SocksInboundSettings
		_ = json.Unmarshal(ib.Settings, &s)
		udpEnabled := s.UDP || s.UDPEnabled
		ip := s.IP
		if ip == "" {
			ip = s.Address
		}
		if ip == "" {
			ip = "127.0.0.1"
		}
		authType := socks.AuthType_NO_AUTH
		if strings.EqualFold(s.Auth, "password") {
			authType = socks.AuthType_PASSWORD
		}
		proxyCfg = &socks.ServerConfig{
			AuthType:   authType,
			UdpEnabled: udpEnabled,
			Address:    v2net.NewIPOrDomain(v2net.ParseAddress(ip)),
		}
	case "dokodemo-door":
		var s v4DokodemoInboundSettings
		_ = json.Unmarshal(ib.Settings, &s)
		networks, err := parseNetworks(s.Network)
		if err != nil {
			return nil, err
		}
		dc := &dokodemo.Config{
			Networks:       networks,
			Timeout:        s.Timeout,
			FollowRedirect: s.FollowRedirect,
			UserLevel:      s.UserLevel,
		}
		if s.Address != nil {
			dc.Address = v2net.NewIPOrDomain(v2net.ParseAddress(*s.Address))
		}
		if s.Port != nil {
			dc.Port = *s.Port
		}
		proxyCfg = dc
	default:
		return nil, errors.New("unsupported inbound protocol: " + ib.Protocol)
	}

	return &core.InboundHandlerConfig{
		Tag:              ib.Tag,
		ReceiverSettings: cserial.ToTypedMessage(receiver),
		ProxySettings:    cserial.ToTypedMessage(proxyCfg),
	}, nil
}

func buildOutbound(ob v4OutboundConfig) (*core.OutboundHandlerConfig, error) {
	sender := &proxyman.SenderConfig{}
	if ob.StreamSettings != nil {
		ss, err := buildStream(*ob.StreamSettings)
		if err != nil {
			return nil, err
		}
		sender.StreamSettings = ss
	}
	if ob.Mux != nil && ob.Mux.Concurrency >= 0 {
		con := uint32(8)
		if ob.Mux.Concurrency > 0 {
			con = uint32(ob.Mux.Concurrency)
		}
		sender.MultiplexSettings = &proxyman.MultiplexingConfig{
			Enabled:     ob.Mux.Enabled,
			Concurrency: con,
		}
	}

	var proxyCfg proto.Message
	switch strings.ToLower(ob.Protocol) {
	case "vmess":
		var s v4VmessOutboundSettings
		_ = json.Unmarshal(ob.Settings, &s)
		servers := make([]*protocol.ServerEndpoint, 0, 4)
		if len(s.VNext) > 0 {
			for _, n := range s.VNext {
				users := make([]*protocol.User, 0, len(n.Users))
				for _, u := range n.Users {
					users = append(users, buildVmessUser(u.ID, u.AlterID, u.Security, u.Level, u.Email))
				}
				servers = append(servers, &protocol.ServerEndpoint{
					Address: v2net.NewIPOrDomain(v2net.ParseAddress(n.Address)),
					Port:    n.Port,
					User:    users,
				})
			}
		} else if s.Address != "" && s.Port > 0 && s.UUID != "" {
			servers = append(servers, &protocol.ServerEndpoint{
				Address: v2net.NewIPOrDomain(v2net.ParseAddress(s.Address)),
				Port:    s.Port,
				User:    []*protocol.User{buildVmessUser(s.UUID, 0, "auto", 0, "")},
			})
		} else {
			return nil, errors.New("vmess outbound missing settings")
		}
		proxyCfg = &vmessout.Config{Receiver: servers}
	default:
		return nil, errors.New("unsupported outbound protocol: " + ob.Protocol)
	}

	return &core.OutboundHandlerConfig{
		Tag:            ob.Tag,
		SenderSettings: cserial.ToTypedMessage(sender),
		ProxySettings:  cserial.ToTypedMessage(proxyCfg),
	}, nil
}

func buildVmessUser(id string, alterID uint32, security string, level uint32, email string) *protocol.User {
	return &protocol.User{
		Level: level,
		Email: email,
		Account: cserial.ToTypedMessage(&vmess.Account{
			Id:      id,
			AlterId: alterID,
			SecuritySettings: &protocol.SecurityConfig{
				Type: parseSecurityType(security),
			},
		}),
	}
}

func parseSecurityType(s string) protocol.SecurityType {
	switch strings.ToLower(s) {
	case "legacy":
		return protocol.SecurityType_LEGACY
	case "auto":
		return protocol.SecurityType_AUTO
	case "aes-128-gcm", "aes128_gcm":
		return protocol.SecurityType_AES128_GCM
	case "chacha20-poly1305", "chacha20_poly1305":
		return protocol.SecurityType_CHACHA20_POLY1305
	case "none":
		return protocol.SecurityType_NONE
	case "zero":
		return protocol.SecurityType_ZERO
	default:
		return protocol.SecurityType_AUTO
	}
}

func parseNetworks(s string) ([]v2net.Network, error) {
	if strings.TrimSpace(s) == "" {
		return []v2net.Network{v2net.Network_TCP, v2net.Network_UDP}, nil
	}
	parts := strings.Split(s, ",")
	out := make([]v2net.Network, 0, len(parts))
	for _, p := range parts {
		switch strings.ToLower(strings.TrimSpace(p)) {
		case "tcp":
			out = append(out, v2net.Network_TCP)
		case "udp":
			out = append(out, v2net.Network_UDP)
		default:
			return nil, errors.New("unknown network: " + p)
		}
	}
	return out, nil
}

func buildStream(s v4StreamConfig) (*internet.StreamConfig, error) {
	protocolName := "tcp"
	switch strings.ToLower(strings.TrimSpace(s.Network)) {
	case "", "tcp":
		protocolName = "tcp"
	case "ws", "websocket":
		protocolName = "websocket"
	case "kcp", "mkcp":
		protocolName = "mkcp"
	case "h2", "http":
		protocolName = "http"
	case "quic":
		protocolName = "quic"
	case "grpc", "gun":
		protocolName = "gun"
	case "httpupgrade":
		protocolName = "httpupgrade"
	case "meek", "mekya":
		if s.Transport != "" {
			protocolName = strings.ToLower(strings.TrimSpace(s.Transport))
		} else {
			protocolName = strings.ToLower(strings.TrimSpace(s.Network))
		}
	default:
		return nil, errors.New("unknown transport: " + s.Network)
	}
	if s.Transport != "" {
		protocolName = strings.ToLower(strings.TrimSpace(s.Transport))
	}

	cfg := &internet.StreamConfig{ProtocolName: protocolName}

	if strings.EqualFold(s.Security, "tls") {
		tlsMsg := &tls.Config{}
		if len(bytes.TrimSpace(s.TLSSettings)) > 0 && string(bytes.TrimSpace(s.TLSSettings)) != "null" {
			var ts v4TLSSettings
			_ = json.Unmarshal(s.TLSSettings, &ts)
			tlsMsg.AllowInsecure = ts.AllowInsecure
			if ts.ServerName != nil {
				tlsMsg.ServerName = *ts.ServerName
			}
			if len(ts.ALPN) > 0 {
				tlsMsg.NextProtocol = append([]string(nil), ts.ALPN...)
			}
		} else if len(bytes.TrimSpace(s.SecuritySettings)) > 0 && string(bytes.TrimSpace(s.SecuritySettings)) != "null" {
			_ = (protojson.UnmarshalOptions{DiscardUnknown: true}).Unmarshal(s.SecuritySettings, tlsMsg)
		}
		cfg.SecuritySettings = append(cfg.SecuritySettings, cserial.ToTypedMessage(tlsMsg))
		cfg.SecurityType = cserial.GetMessageType(tlsMsg)
	}

	switch protocolName {
	case "tcp":
		if len(bytes.TrimSpace(s.TCPSettings)) > 0 && string(bytes.TrimSpace(s.TCPSettings)) != "null" {
			m, err := buildTCP(s.TCPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "tcp", Settings: cserial.ToTypedMessage(m)})
		}
	case "websocket":
		if len(bytes.TrimSpace(s.WSSettings)) > 0 && string(bytes.TrimSpace(s.WSSettings)) != "null" {
			m, err := buildWS(s.WSSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "websocket", Settings: cserial.ToTypedMessage(m)})
		}
	case "mkcp":
		if len(bytes.TrimSpace(s.KCPSettings)) > 0 && string(bytes.TrimSpace(s.KCPSettings)) != "null" {
			m, err := buildKCP(s.KCPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "mkcp", Settings: cserial.ToTypedMessage(m)})
		}
	case "http":
		if len(bytes.TrimSpace(s.HTTPSettings)) > 0 && string(bytes.TrimSpace(s.HTTPSettings)) != "null" {
			m, err := buildH2(s.HTTPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "http", Settings: cserial.ToTypedMessage(m)})
		}
	case "quic":
		if len(bytes.TrimSpace(s.QUICSettings)) > 0 && string(bytes.TrimSpace(s.QUICSettings)) != "null" {
			m, err := buildQUIC(s.QUICSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "quic", Settings: cserial.ToTypedMessage(m)})
		}
	case "gun":
		if len(bytes.TrimSpace(s.GRPCSettings)) > 0 && string(bytes.TrimSpace(s.GRPCSettings)) != "null" {
			m, err := buildGRPC(s.GRPCSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "gun", Settings: cserial.ToTypedMessage(m)})
		}
	case "meek":
		if len(bytes.TrimSpace(s.TransportSettings)) == 0 || string(bytes.TrimSpace(s.TransportSettings)) == "null" {
			return nil, errors.New("meek requires streamSettings.transportSettings")
		}
		m := &meek.Config{}
		if err := (protojson.UnmarshalOptions{DiscardUnknown: true}).Unmarshal(s.TransportSettings, m); err != nil {
			return nil, err
		}
		cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "meek", Settings: cserial.ToTypedMessage(m)})
	case "mekya":
		if len(bytes.TrimSpace(s.TransportSettings)) == 0 || string(bytes.TrimSpace(s.TransportSettings)) == "null" {
			return nil, errors.New("mekya requires streamSettings.transportSettings")
		}
		m := &mekya.Config{}
		if err := (protojson.UnmarshalOptions{DiscardUnknown: true}).Unmarshal(s.TransportSettings, m); err != nil {
			return nil, err
		}
		cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "mekya", Settings: cserial.ToTypedMessage(m)})
	case "httpupgrade":
		// Prefer v5-style streamSettings.transportSettings.
		m := &httpupgrade.Config{}
		if len(bytes.TrimSpace(s.TransportSettings)) > 0 && string(bytes.TrimSpace(s.TransportSettings)) != "null" {
			if err := (protojson.UnmarshalOptions{DiscardUnknown: true}).Unmarshal(s.TransportSettings, m); err != nil {
				return nil, err
			}
		}
		cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "httpupgrade", Settings: cserial.ToTypedMessage(m)})
	}

	return cfg, nil
}

func buildTCP(raw json.RawMessage) (*tcp.Config, error) {
	var s v4TCPSettings
	if err := json.Unmarshal(raw, &s); err != nil {
		return nil, err
	}
	cfg := &tcp.Config{AcceptProxyProtocol: s.AcceptProxyProtocol}
	switch strings.ToLower(strings.TrimSpace(s.Header.Type)) {
	case "", "none":
		cfg.HeaderSettings = cserial.ToTypedMessage(&noop.ConnectionConfig{})
	case "http":
		h, err := buildHTTPHeader(s.Header.Request, s.Header.Response)
		if err != nil {
			return nil, err
		}
		cfg.HeaderSettings = cserial.ToTypedMessage(h)
	default:
		return nil, errors.New("unsupported tcp header type: " + s.Header.Type)
	}
	return cfg, nil
}

func buildHTTPHeader(req v4HTTPRequest, resp v4HTTPResponse) (*httpheader.Config, error) {
	cfg := &httpheader.Config{}
	if req.Version != "" || req.Method != "" || len(req.Path) > 0 || len(req.Headers) > 0 {
		r := &httpheader.RequestConfig{Uri: []string{"/"}}
		if req.Version != "" {
			r.Version = &httpheader.Version{Value: req.Version}
		}
		if req.Method != "" {
			r.Method = &httpheader.Method{Value: req.Method}
		}
		if len(req.Path) > 0 {
			r.Uri = append([]string(nil), req.Path...)
		}
		if len(req.Headers) > 0 {
			names := make([]string, 0, len(req.Headers))
			for k := range req.Headers {
				names = append(names, k)
			}
			sort.Strings(names)
			r.Header = make([]*httpheader.Header, 0, len(names))
			for _, name := range names {
				r.Header = append(r.Header, &httpheader.Header{Name: name, Value: append([]string(nil), req.Headers[name]...)})
			}
		}
		cfg.Request = r
	}
	if resp.Version != "" || resp.Status != "" || resp.Reason != "" || len(resp.Headers) > 0 {
		r := &httpheader.ResponseConfig{}
		if resp.Version != "" {
			r.Version = &httpheader.Version{Value: resp.Version}
		}
		if resp.Status != "" || resp.Reason != "" {
			r.Status = &httpheader.Status{Code: "200", Reason: "OK"}
			if resp.Status != "" {
				r.Status.Code = resp.Status
			}
			if resp.Reason != "" {
				r.Status.Reason = resp.Reason
			}
		}
		if len(resp.Headers) > 0 {
			names := make([]string, 0, len(resp.Headers))
			for k := range resp.Headers {
				names = append(names, k)
			}
			sort.Strings(names)
			r.Header = make([]*httpheader.Header, 0, len(names))
			for _, name := range names {
				r.Header = append(r.Header, &httpheader.Header{Name: name, Value: append([]string(nil), resp.Headers[name]...)})
			}
		}
		cfg.Response = r
	}
	return cfg, nil
}

func buildKCP(raw json.RawMessage) (*kcp.Config, error) {
	var s v4KCPSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &kcp.Config{}
	if s.Mtu != nil {
		cfg.Mtu = &kcp.MTU{Value: *s.Mtu}
	}
	if s.Tti != nil {
		cfg.Tti = &kcp.TTI{Value: *s.Tti}
	}
	if s.UpCap != nil {
		cfg.UplinkCapacity = &kcp.UplinkCapacity{Value: *s.UpCap}
	}
	if s.DownCap != nil {
		cfg.DownlinkCapacity = &kcp.DownlinkCapacity{Value: *s.DownCap}
	}
	if s.Congestion != nil {
		cfg.Congestion = *s.Congestion
	}
	if s.ReadBufferSize != nil {
		cfg.ReadBuffer = &kcp.ReadBuffer{Size: (*s.ReadBufferSize) * 1024 * 1024}
	}
	if s.WriteBufferSize != nil {
		cfg.WriteBuffer = &kcp.WriteBuffer{Size: (*s.WriteBufferSize) * 1024 * 1024}
	}
	if s.Seed != nil {
		cfg.Seed = &kcp.EncryptionSeed{Seed: *s.Seed}
	}
	if len(bytes.TrimSpace(s.Header)) > 0 && string(bytes.TrimSpace(s.Header)) != "null" {
		h, err := buildPacketHeader(s.Header)
		if err != nil {
			return nil, err
		}
		cfg.HeaderConfig = cserial.ToTypedMessage(h)
	}
	return cfg, nil
}

func buildWS(raw json.RawMessage) (*websocket.Config, error) {
	var s v4WSSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &websocket.Config{Path: s.Path, AcceptProxyProtocol: s.AcceptProxyProtocol}
	if len(s.Headers) > 0 {
		keys := make([]string, 0, len(s.Headers))
		for k := range s.Headers {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		cfg.Header = make([]*websocket.Header, 0, len(keys))
		for _, k := range keys {
			cfg.Header = append(cfg.Header, &websocket.Header{Key: k, Value: s.Headers[k]})
		}
	}
	return cfg, nil
}

func buildH2(raw json.RawMessage) (*http.Config, error) {
	var s v4HTTPSettings
	if err := json.Unmarshal(raw, &s); err != nil {
		return nil, err
	}
	return &http.Config{Host: append([]string(nil), s.Host...), Path: s.Path}, nil
}

func buildQUIC(raw json.RawMessage) (*quic.Config, error) {
	var s v4QUICSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &quic.Config{
		Key: s.Key,
		Security: &protocol.SecurityConfig{Type: parseSecurityType(s.Security)},
	}
	if len(bytes.TrimSpace(s.Header)) > 0 && string(bytes.TrimSpace(s.Header)) != "null" {
		h, err := buildPacketHeader(s.Header)
		if err != nil {
			return nil, err
		}
		cfg.Header = cserial.ToTypedMessage(h)
	}
	return cfg, nil
}

func buildGRPC(raw json.RawMessage) (*grpc.Config, error) {
	var s v4GRPCSettings
	_ = json.Unmarshal(raw, &s)
	return &grpc.Config{ServiceName: s.ServiceName}, nil
}

func buildPacketHeader(raw json.RawMessage) (proto.Message, error) {
	var t struct {
		Type string `json:"type"`
	}
	_ = json.Unmarshal(raw, &t)
	switch strings.ToLower(strings.TrimSpace(t.Type)) {
	case "", "none":
		return &noop.Config{}, nil
	case "srtp":
		return &srtp.Config{}, nil
	case "utp":
		return &utp.Config{}, nil
	case "wechat-video":
		return &wechat.VideoConfig{}, nil
	case "dtls":
		return &tlsheader.PacketConfig{}, nil
	case "wireguard":
		return &wireguard.WireguardConfig{}, nil
	default:
		return nil, errors.New("unsupported packet header type: " + t.Type)
	}
}
EOF
	else
		cat >"${base_dir}/v2ray-core/main/formats/${formats_pkg}/formats.go" <<'EOF'
package fancyssv4min

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"os"
	"sort"
	"strings"

	proto "github.com/golang/protobuf/proto"

	core "github.com/v2fly/v2ray-core/v5"
	"github.com/v2fly/v2ray-core/v5/app/dispatcher"
	applog "github.com/v2fly/v2ray-core/v5/app/log"
	"github.com/v2fly/v2ray-core/v5/app/proxyman"
	"github.com/v2fly/v2ray-core/v5/common"
	"github.com/v2fly/v2ray-core/v5/common/cmdarg"
	clog "github.com/v2fly/v2ray-core/v5/common/log"
	v2net "github.com/v2fly/v2ray-core/v5/common/net"
	"github.com/v2fly/v2ray-core/v5/common/protocol"
	cserial "github.com/v2fly/v2ray-core/v5/common/serial"
	"github.com/v2fly/v2ray-core/v5/proxy/dokodemo"
	"github.com/v2fly/v2ray-core/v5/proxy/socks"
	vmess "github.com/v2fly/v2ray-core/v5/proxy/vmess"
	vmessout "github.com/v2fly/v2ray-core/v5/proxy/vmess/outbound"
	"github.com/v2fly/v2ray-core/v5/transport/internet"
	httpheader "github.com/v2fly/v2ray-core/v5/transport/internet/headers/http"
	noop "github.com/v2fly/v2ray-core/v5/transport/internet/headers/noop"
	srtp "github.com/v2fly/v2ray-core/v5/transport/internet/headers/srtp"
	tlsheader "github.com/v2fly/v2ray-core/v5/transport/internet/headers/tls"
	utp "github.com/v2fly/v2ray-core/v5/transport/internet/headers/utp"
	wechat "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wechat"
	wireguard "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wireguard"
	"github.com/v2fly/v2ray-core/v5/transport/internet/http"
	"github.com/v2fly/v2ray-core/v5/transport/internet/kcp"
	"github.com/v2fly/v2ray-core/v5/transport/internet/quic"
	"github.com/v2fly/v2ray-core/v5/transport/internet/tcp"
	"github.com/v2fly/v2ray-core/v5/transport/internet/tls"
	"github.com/v2fly/v2ray-core/v5/transport/internet/websocket"

	grpc "github.com/v2fly/v2ray-core/v5/transport/internet/grpc"
	httpupgrade "github.com/v2fly/v2ray-core/v5/transport/internet/httpupgrade"
)

func init() {
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatJSON},
		Extension: []string{".json", ".jsonc"},
		Loader:    loadJSON,
	}))
	common.Must(core.RegisterConfigLoader(&core.ConfigFormat{
		Name:      []string{core.FormatAuto},
		Extension: nil,
		Loader:    loadJSON,
	}))
}

func loadJSON(input interface{}) (*core.Config, error) {
	switch v := input.(type) {
	case cmdarg.Arg:
		return loadJSON(v.String())
	case []string:
		if len(v) != 1 {
			return nil, errors.New("multiple config files are not supported in fancyssv4min loader")
		}
		return loadJSON(v[0])
	case string:
		b, err := os.ReadFile(v)
		if err != nil {
			return nil, err
		}
		return LoadConfigBytes(b)
	case io.Reader:
		b, err := io.ReadAll(v)
		if err != nil {
			return nil, err
		}
		return LoadConfigBytes(b)
	default:
		return nil, errors.New("unsupported config input type")
	}
}

type v4Config struct {
	Log       *v4LogConfig       `json:"log"`
	Inbounds  []v4InboundConfig  `json:"inbounds"`
	Outbounds []v4OutboundConfig `json:"outbounds"`
	Inbound   *v4InboundConfig   `json:"inbound"`
	Outbound  *v4OutboundConfig  `json:"outbound"`
}

type v4LogConfig struct {
	Access   string `json:"access"`
	Error    string `json:"error"`
	Loglevel string `json:"loglevel"`
}

type v4InboundConfig struct {
	Port     int             `json:"port"`
	Listen   string          `json:"listen"`
	Protocol string          `json:"protocol"`
	Settings json.RawMessage `json:"settings"`
	Tag      string          `json:"tag"`
}

type v4OutboundConfig struct {
	Tag           string          `json:"tag"`
	Protocol      string          `json:"protocol"`
	Settings      json.RawMessage `json:"settings"`
	StreamSettings *v4StreamConfig `json:"streamSettings"`
	Mux           *v4MuxConfig    `json:"mux"`
}

type v4MuxConfig struct {
	Enabled     bool  `json:"enabled"`
	Concurrency int16 `json:"concurrency"`
}

type v4StreamConfig struct {
	Network      string          `json:"network"`
	Security     string          `json:"security"`
	TLSSettings  json.RawMessage `json:"tlsSettings"`
	TCPSettings  json.RawMessage `json:"tcpSettings"`
	KCPSettings  json.RawMessage `json:"kcpSettings"`
	WSSettings   json.RawMessage `json:"wsSettings"`
	HTTPSettings json.RawMessage `json:"httpSettings"`
	QUICSettings json.RawMessage `json:"quicSettings"`
	GRPCSettings json.RawMessage `json:"grpcSettings"`
	HTTPUpgradeSettings json.RawMessage `json:"httpupgradeSettings"`

	// Optional v5-style transport (used by httpupgrade).
	Transport         string          `json:"transport"`
	TransportSettings json.RawMessage `json:"transportSettings"`
}

type v4SocksInboundSettings struct {
	Auth string `json:"auth"`
	UDP  bool   `json:"udp"`
	IP   string `json:"ip"`
}

type v4DokodemoInboundSettings struct {
	Address        *string `json:"address"`
	Port           *uint32 `json:"port"`
	Network        string  `json:"network"`
	Timeout        uint32  `json:"timeout"`
	FollowRedirect bool    `json:"followRedirect"`
	UserLevel      uint32  `json:"userLevel"`
}

type v4VmessOutboundSettings struct {
	VNext []struct {
		Address string `json:"address"`
		Port    uint32 `json:"port"`
		Users   []struct {
			ID       string `json:"id"`
			AlterID  uint32 `json:"alterId"`
			Security string `json:"security"`
			Level    uint32 `json:"level"`
			Email    string `json:"email"`
		} `json:"users"`
	} `json:"vnext"`
}

type v4TLSSettings struct {
	AllowInsecure bool     `json:"allowInsecure"`
	ALPN          []string `json:"alpn"`
	ServerName    *string  `json:"serverName"`
}

type v4TCPSettings struct {
	Header struct {
		Type     string         `json:"type"`
		Request  v4HTTPRequest  `json:"request"`
		Response v4HTTPResponse `json:"response"`
	} `json:"header"`
	AcceptProxyProtocol bool `json:"acceptProxyProtocol"`
}

type v4StringList []string

func (s *v4StringList) UnmarshalJSON(b []byte) error {
	b = bytes.TrimSpace(b)
	if len(b) == 0 || bytes.Equal(b, []byte("null")) {
		*s = nil
		return nil
	}
	if b[0] == '"' {
		var v string
		if err := json.Unmarshal(b, &v); err != nil {
			return err
		}
		*s = v4StringList{v}
		return nil
	}
	var arr []string
	if err := json.Unmarshal(b, &arr); err == nil {
		*s = v4StringList(arr)
		return nil
	}
	return errors.New("expected string or []string")
}

type v4HTTPRequest struct {
	Version string              `json:"version"`
	Method  string              `json:"method"`
	Path    v4StringList        `json:"path"`
	Headers map[string]v4StringList `json:"headers"`
}

type v4HTTPResponse struct {
	Version string              `json:"version"`
	Status  string              `json:"status"`
	Reason  string              `json:"reason"`
	Headers map[string]v4StringList `json:"headers"`
}

type v4KCPSettings struct {
	Mtu             *uint32         `json:"mtu"`
	Tti             *uint32         `json:"tti"`
	UpCap           *uint32         `json:"uplinkCapacity"`
	DownCap         *uint32         `json:"downlinkCapacity"`
	Congestion      *bool           `json:"congestion"`
	ReadBufferSize  *uint32         `json:"readBufferSize"`
	WriteBufferSize *uint32         `json:"writeBufferSize"`
	Header          json.RawMessage `json:"header"`
	Seed            *string         `json:"seed"`
}

type v4WSSettings struct {
	Path                string            `json:"path"`
	Headers             map[string]string `json:"headers"`
	AcceptProxyProtocol bool              `json:"acceptProxyProtocol"`
}

type v4HTTPSettings struct {
	Host v4StringList `json:"host"`
	Path string   `json:"path"`
}

type v4QUICSettings struct {
	Header   json.RawMessage `json:"header"`
	Security string          `json:"security"`
	Key      string          `json:"key"`
}

type v4GRPCSettings struct {
	ServiceName string `json:"serviceName"`
}

type v4HTTPUpgradeHeader struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

type v4HTTPUpgradeSettings struct {
	Path                string              `json:"path"`
	Host                string              `json:"host"`
	MaxEarlyData         int32               `json:"maxEarlyData"`
	EarlyDataHeaderName  string              `json:"earlyDataHeaderName"`
	Header              []v4HTTPUpgradeHeader `json:"header"`
}

func LoadConfigBytes(raw []byte) (*core.Config, error) {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 {
		return nil, errors.New("empty config")
	}
	var c v4Config
	if err := json.Unmarshal(raw, &c); err != nil {
		return nil, err
	}

	inbounds := c.Inbounds
	outbounds := c.Outbounds
	if c.Inbound != nil {
		inbounds = append(inbounds, *c.Inbound)
	}
	if c.Outbound != nil {
		outbounds = append(outbounds, *c.Outbound)
	}

	cfg := &core.Config{}
	cfg.App = append(cfg.App,
		cserial.ToTypedMessage(&applog.Config{
			Error:  &applog.LogSpecification{Type: applog.LogType_None, Level: clog.Severity_Unknown},
			Access: &applog.LogSpecification{Type: applog.LogType_None, Level: clog.Severity_Unknown},
		}),
		cserial.ToTypedMessage(&dispatcher.Config{}),
		cserial.ToTypedMessage(&proxyman.InboundConfig{}),
		cserial.ToTypedMessage(&proxyman.OutboundConfig{}),
	)

	for _, ib := range inbounds {
		ic, err := buildInbound(ib)
		if err != nil {
			return nil, err
		}
		cfg.Inbound = append(cfg.Inbound, ic)
	}
	for _, ob := range outbounds {
		oc, err := buildOutbound(ob)
		if err != nil {
			return nil, err
		}
		cfg.Outbound = append(cfg.Outbound, oc)
	}
	return cfg, nil
}

func buildInbound(ib v4InboundConfig) (*core.InboundHandlerConfig, error) {
	if ib.Port <= 0 || ib.Port > 65535 {
		return nil, errors.New("invalid inbound port")
	}
	receiver := &proxyman.ReceiverConfig{
		PortRange: &v2net.PortRange{From: uint32(ib.Port), To: uint32(ib.Port)},
	}
	if ib.Listen != "" {
		receiver.Listen = v2net.NewIPOrDomain(v2net.ParseAddress(ib.Listen))
	}

	var proxyCfg proto.Message
	switch strings.ToLower(ib.Protocol) {
	case "socks":
		var s v4SocksInboundSettings
		_ = json.Unmarshal(ib.Settings, &s)
		authType := socks.AuthType_NO_AUTH
		if strings.EqualFold(s.Auth, "password") {
			authType = socks.AuthType_PASSWORD
		}
		ip := s.IP
		if ip == "" {
			ip = "127.0.0.1"
		}
		proxyCfg = &socks.ServerConfig{
			AuthType:   authType,
			UdpEnabled: s.UDP,
			Address:    v2net.NewIPOrDomain(v2net.ParseAddress(ip)),
		}
	case "dokodemo-door":
		var s v4DokodemoInboundSettings
		_ = json.Unmarshal(ib.Settings, &s)
		networks, err := parseNetworks(s.Network)
		if err != nil {
			return nil, err
		}
		dc := &dokodemo.Config{
			Networks:       networks,
			Timeout:        s.Timeout,
			FollowRedirect: s.FollowRedirect,
			UserLevel:      s.UserLevel,
		}
		if s.Address != nil {
			dc.Address = v2net.NewIPOrDomain(v2net.ParseAddress(*s.Address))
		}
		if s.Port != nil {
			dc.Port = *s.Port
		}
		proxyCfg = dc
	default:
		return nil, errors.New("unsupported inbound protocol: " + ib.Protocol)
	}

	return &core.InboundHandlerConfig{
		Tag:              ib.Tag,
		ReceiverSettings: cserial.ToTypedMessage(receiver),
		ProxySettings:    cserial.ToTypedMessage(proxyCfg),
	}, nil
}

func buildOutbound(ob v4OutboundConfig) (*core.OutboundHandlerConfig, error) {
	sender := &proxyman.SenderConfig{}
	if ob.StreamSettings != nil {
		ss, err := buildStream(*ob.StreamSettings)
		if err != nil {
			return nil, err
		}
		sender.StreamSettings = ss
	}
	if ob.Mux != nil && ob.Mux.Concurrency >= 0 {
		con := uint32(8)
		if ob.Mux.Concurrency > 0 {
			con = uint32(ob.Mux.Concurrency)
		}
		sender.MultiplexSettings = &proxyman.MultiplexingConfig{
			Enabled:     ob.Mux.Enabled,
			Concurrency: con,
		}
	}

	var proxyCfg proto.Message
	switch strings.ToLower(ob.Protocol) {
	case "vmess":
		var s v4VmessOutboundSettings
		_ = json.Unmarshal(ob.Settings, &s)
		if len(s.VNext) == 0 {
			return nil, errors.New("vmess outbound missing vnext")
		}
		servers := make([]*protocol.ServerEndpoint, 0, len(s.VNext))
		for _, n := range s.VNext {
			users := make([]*protocol.User, 0, len(n.Users))
			for _, u := range n.Users {
				users = append(users, buildVmessUser(u.ID, u.AlterID, u.Security, u.Level, u.Email))
			}
			servers = append(servers, &protocol.ServerEndpoint{
				Address: v2net.NewIPOrDomain(v2net.ParseAddress(n.Address)),
				Port:    n.Port,
				User:    users,
			})
		}
		proxyCfg = &vmessout.Config{Receiver: servers}
	default:
		return nil, errors.New("unsupported outbound protocol: " + ob.Protocol)
	}

	return &core.OutboundHandlerConfig{
		Tag:            ob.Tag,
		SenderSettings: cserial.ToTypedMessage(sender),
		ProxySettings:  cserial.ToTypedMessage(proxyCfg),
	}, nil
}

func buildVmessUser(id string, alterID uint32, security string, level uint32, email string) *protocol.User {
	return &protocol.User{
		Level: level,
		Email: email,
		Account: cserial.ToTypedMessage(&vmess.Account{
			Id:      id,
			AlterId: alterID,
			SecuritySettings: &protocol.SecurityConfig{
				Type: parseSecurityType(security),
			},
		}),
	}
}

func parseSecurityType(s string) protocol.SecurityType {
	switch strings.ToLower(s) {
	case "legacy":
		return protocol.SecurityType_LEGACY
	case "auto":
		return protocol.SecurityType_AUTO
	case "aes-128-gcm", "aes128_gcm":
		return protocol.SecurityType_AES128_GCM
	case "chacha20-poly1305", "chacha20_poly1305":
		return protocol.SecurityType_CHACHA20_POLY1305
	case "none":
		return protocol.SecurityType_NONE
	case "zero":
		return protocol.SecurityType_ZERO
	default:
		return protocol.SecurityType_AUTO
	}
}

func parseNetworks(s string) ([]v2net.Network, error) {
	if strings.TrimSpace(s) == "" {
		return []v2net.Network{v2net.Network_TCP, v2net.Network_UDP}, nil
	}
	parts := strings.Split(s, ",")
	out := make([]v2net.Network, 0, len(parts))
	for _, p := range parts {
		switch strings.ToLower(strings.TrimSpace(p)) {
		case "tcp":
			out = append(out, v2net.Network_TCP)
		case "udp":
			out = append(out, v2net.Network_UDP)
		default:
			return nil, errors.New("unknown network: " + p)
		}
	}
	return out, nil
}

func buildStream(s v4StreamConfig) (*internet.StreamConfig, error) {
	protocolName := "tcp"
	switch strings.ToLower(strings.TrimSpace(s.Network)) {
	case "", "tcp":
		protocolName = "tcp"
	case "ws", "websocket":
		protocolName = "websocket"
	case "kcp", "mkcp":
		protocolName = "mkcp"
	case "h2", "http":
		protocolName = "http"
	case "quic":
		protocolName = "quic"
	case "grpc", "gun":
		protocolName = "gun"
	case "httpupgrade":
		protocolName = "httpupgrade"
	default:
		return nil, errors.New("unknown transport: " + s.Network)
	}

	if s.Transport != "" {
		protocolName = strings.ToLower(strings.TrimSpace(s.Transport))
	}

	cfg := &internet.StreamConfig{ProtocolName: protocolName}

	if strings.EqualFold(s.Security, "tls") {
		var ts v4TLSSettings
		_ = json.Unmarshal(s.TLSSettings, &ts)
		tlsMsg := &tls.Config{AllowInsecure: ts.AllowInsecure}
		if ts.ServerName != nil {
			tlsMsg.ServerName = *ts.ServerName
		}
		if len(ts.ALPN) > 0 {
			tlsMsg.NextProtocol = append([]string(nil), ts.ALPN...)
		}
		cfg.SecuritySettings = append(cfg.SecuritySettings, cserial.ToTypedMessage(tlsMsg))
		cfg.SecurityType = cserial.GetMessageType(tlsMsg)
	}

	switch protocolName {
	case "tcp":
		if len(bytes.TrimSpace(s.TCPSettings)) > 0 && string(bytes.TrimSpace(s.TCPSettings)) != "null" {
			m, err := buildTCP(s.TCPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "tcp", Settings: cserial.ToTypedMessage(m)})
		}
	case "websocket":
		if len(bytes.TrimSpace(s.WSSettings)) > 0 && string(bytes.TrimSpace(s.WSSettings)) != "null" {
			m, err := buildWS(s.WSSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "websocket", Settings: cserial.ToTypedMessage(m)})
		}
	case "mkcp":
		if len(bytes.TrimSpace(s.KCPSettings)) > 0 && string(bytes.TrimSpace(s.KCPSettings)) != "null" {
			m, err := buildKCP(s.KCPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "mkcp", Settings: cserial.ToTypedMessage(m)})
		}
	case "http":
		if len(bytes.TrimSpace(s.HTTPSettings)) > 0 && string(bytes.TrimSpace(s.HTTPSettings)) != "null" {
			m, err := buildH2(s.HTTPSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "http", Settings: cserial.ToTypedMessage(m)})
		}
	case "quic":
		if len(bytes.TrimSpace(s.QUICSettings)) > 0 && string(bytes.TrimSpace(s.QUICSettings)) != "null" {
			m, err := buildQUIC(s.QUICSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "quic", Settings: cserial.ToTypedMessage(m)})
		}
	case "gun":
		if len(bytes.TrimSpace(s.GRPCSettings)) > 0 && string(bytes.TrimSpace(s.GRPCSettings)) != "null" {
			m, err := buildGRPC(s.GRPCSettings)
			if err != nil {
				return nil, err
			}
			cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "gun", Settings: cserial.ToTypedMessage(m)})
		}
	case "httpupgrade":
		// Support both v4-style httpupgradeSettings and v5-style transportSettings.
		var raw json.RawMessage
		if len(bytes.TrimSpace(s.TransportSettings)) > 0 && string(bytes.TrimSpace(s.TransportSettings)) != "null" {
			raw = s.TransportSettings
		} else if len(bytes.TrimSpace(s.HTTPUpgradeSettings)) > 0 && string(bytes.TrimSpace(s.HTTPUpgradeSettings)) != "null" {
			raw = s.HTTPUpgradeSettings
		}

		var hs v4HTTPUpgradeSettings
		if len(raw) > 0 {
			_ = json.Unmarshal(raw, &hs)
		}
		msg := &httpupgrade.Config{
			Path:                hs.Path,
			Host:                hs.Host,
			MaxEarlyData:         hs.MaxEarlyData,
			EarlyDataHeaderName:  hs.EarlyDataHeaderName,
		}
		if len(hs.Header) > 0 {
			msg.Header = make([]*httpupgrade.Header, 0, len(hs.Header))
			for _, h := range hs.Header {
				msg.Header = append(msg.Header, &httpupgrade.Header{Key: h.Key, Value: h.Value})
			}
		}
		cfg.TransportSettings = append(cfg.TransportSettings, &internet.TransportConfig{ProtocolName: "httpupgrade", Settings: cserial.ToTypedMessage(msg)})
	}
	return cfg, nil
}

func buildTCP(raw json.RawMessage) (*tcp.Config, error) {
	var s v4TCPSettings
	if err := json.Unmarshal(raw, &s); err != nil {
		return nil, err
	}
	cfg := &tcp.Config{AcceptProxyProtocol: s.AcceptProxyProtocol}
	switch strings.ToLower(strings.TrimSpace(s.Header.Type)) {
	case "", "none":
		cfg.HeaderSettings = cserial.ToTypedMessage(&noop.ConnectionConfig{})
	case "http":
		h, err := buildHTTPHeader(s.Header.Request, s.Header.Response)
		if err != nil {
			return nil, err
		}
		cfg.HeaderSettings = cserial.ToTypedMessage(h)
	default:
		return nil, errors.New("unsupported tcp header type: " + s.Header.Type)
	}
	return cfg, nil
}

func buildHTTPHeader(req v4HTTPRequest, resp v4HTTPResponse) (*httpheader.Config, error) {
	cfg := &httpheader.Config{}
	if req.Version != "" || req.Method != "" || len(req.Path) > 0 || len(req.Headers) > 0 {
		r := &httpheader.RequestConfig{Uri: []string{"/"}}
		if req.Version != "" {
			r.Version = &httpheader.Version{Value: req.Version}
		}
		if req.Method != "" {
			r.Method = &httpheader.Method{Value: req.Method}
		}
		if len(req.Path) > 0 {
			r.Uri = append([]string(nil), req.Path...)
		}
		if len(req.Headers) > 0 {
			names := make([]string, 0, len(req.Headers))
			for k := range req.Headers {
				names = append(names, k)
			}
			sort.Strings(names)
			r.Header = make([]*httpheader.Header, 0, len(names))
			for _, name := range names {
				r.Header = append(r.Header, &httpheader.Header{Name: name, Value: append([]string(nil), req.Headers[name]...)})
			}
		}
		cfg.Request = r
	}
	if resp.Version != "" || resp.Status != "" || resp.Reason != "" || len(resp.Headers) > 0 {
		r := &httpheader.ResponseConfig{}
		if resp.Version != "" {
			r.Version = &httpheader.Version{Value: resp.Version}
		}
		if resp.Status != "" || resp.Reason != "" {
			r.Status = &httpheader.Status{Code: "200", Reason: "OK"}
			if resp.Status != "" {
				r.Status.Code = resp.Status
			}
			if resp.Reason != "" {
				r.Status.Reason = resp.Reason
			}
		}
		if len(resp.Headers) > 0 {
			names := make([]string, 0, len(resp.Headers))
			for k := range resp.Headers {
				names = append(names, k)
			}
			sort.Strings(names)
			r.Header = make([]*httpheader.Header, 0, len(names))
			for _, name := range names {
				r.Header = append(r.Header, &httpheader.Header{Name: name, Value: append([]string(nil), resp.Headers[name]...)})
			}
		}
		cfg.Response = r
	}
	return cfg, nil
}

func buildKCP(raw json.RawMessage) (*kcp.Config, error) {
	var s v4KCPSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &kcp.Config{}
	if s.Mtu != nil {
		cfg.Mtu = &kcp.MTU{Value: *s.Mtu}
	}
	if s.Tti != nil {
		cfg.Tti = &kcp.TTI{Value: *s.Tti}
	}
	if s.UpCap != nil {
		cfg.UplinkCapacity = &kcp.UplinkCapacity{Value: *s.UpCap}
	}
	if s.DownCap != nil {
		cfg.DownlinkCapacity = &kcp.DownlinkCapacity{Value: *s.DownCap}
	}
	if s.Congestion != nil {
		cfg.Congestion = *s.Congestion
	}
	if s.ReadBufferSize != nil {
		cfg.ReadBuffer = &kcp.ReadBuffer{Size: (*s.ReadBufferSize) * 1024 * 1024}
	}
	if s.WriteBufferSize != nil {
		cfg.WriteBuffer = &kcp.WriteBuffer{Size: (*s.WriteBufferSize) * 1024 * 1024}
	}
	if s.Seed != nil {
		cfg.Seed = &kcp.EncryptionSeed{Seed: *s.Seed}
	}
	if len(bytes.TrimSpace(s.Header)) > 0 && string(bytes.TrimSpace(s.Header)) != "null" {
		h, err := buildPacketHeader(s.Header)
		if err != nil {
			return nil, err
		}
		cfg.HeaderConfig = cserial.ToTypedMessage(h)
	}
	return cfg, nil
}

func buildWS(raw json.RawMessage) (*websocket.Config, error) {
	var s v4WSSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &websocket.Config{Path: s.Path, AcceptProxyProtocol: s.AcceptProxyProtocol}
	if len(s.Headers) > 0 {
		keys := make([]string, 0, len(s.Headers))
		for k := range s.Headers {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		cfg.Header = make([]*websocket.Header, 0, len(keys))
		for _, k := range keys {
			cfg.Header = append(cfg.Header, &websocket.Header{Key: k, Value: s.Headers[k]})
		}
	}
	return cfg, nil
}

func buildH2(raw json.RawMessage) (*http.Config, error) {
	var s v4HTTPSettings
	if err := json.Unmarshal(raw, &s); err != nil {
		return nil, err
	}
	return &http.Config{Host: append([]string(nil), s.Host...), Path: s.Path}, nil
}

func buildQUIC(raw json.RawMessage) (*quic.Config, error) {
	var s v4QUICSettings
	_ = json.Unmarshal(raw, &s)
	cfg := &quic.Config{
		Key: s.Key,
		Security: &protocol.SecurityConfig{Type: parseSecurityType(s.Security)},
	}
	if len(bytes.TrimSpace(s.Header)) > 0 && string(bytes.TrimSpace(s.Header)) != "null" {
		h, err := buildPacketHeader(s.Header)
		if err != nil {
			return nil, err
		}
		cfg.Header = cserial.ToTypedMessage(h)
	}
	return cfg, nil
}

func buildGRPC(raw json.RawMessage) (*grpc.Config, error) {
	var s v4GRPCSettings
	_ = json.Unmarshal(raw, &s)
	return &grpc.Config{ServiceName: s.ServiceName}, nil
}

func buildPacketHeader(raw json.RawMessage) (proto.Message, error) {
	var t struct {
		Type string `json:"type"`
	}
	_ = json.Unmarshal(raw, &t)
	switch strings.ToLower(strings.TrimSpace(t.Type)) {
	case "", "none":
		return &noop.Config{}, nil
	case "srtp":
		return &srtp.Config{}, nil
	case "utp":
		return &utp.Config{}, nil
	case "wechat-video":
		return &wechat.VideoConfig{}, nil
	case "dtls":
		return &tlsheader.PacketConfig{}, nil
	case "wireguard":
		return &wireguard.WireguardConfig{}, nil
	default:
		return nil, errors.New("unsupported packet header type: " + t.Type)
	}
}
EOF
	fi

	# Minimal distro package for this trim mode.
	mkdir -p "${base_dir}/v2ray-core/main/distro/fancyss_vmess_v4_min"
	cat >"${base_dir}/v2ray-core/main/distro/fancyss_vmess_v4_min/all.go" <<EOF
package fancyss_vmess_v4_min

import (
	// Core mandatory features
	_ "github.com/v2fly/v2ray-core/v5/app/dispatcher"
	_ "github.com/v2fly/v2ray-core/v5/app/log"
	_ "github.com/v2fly/v2ray-core/v5/app/proxyman/inbound"
	_ "github.com/v2fly/v2ray-core/v5/app/proxyman/outbound"

	// Fix dependency cycle caused by core import in internet package
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tagged/taggedimpl"

	// Inbound / outbound proxies
	_ "github.com/v2fly/v2ray-core/v5/proxy/dokodemo"
	_ "github.com/v2fly/v2ray-core/v5/proxy/socks"
	_ "github.com/v2fly/v2ray-core/v5/proxy/vmess/outbound"

	// Transports
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/grpc"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/http"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/httpupgrade"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/kcp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/quic"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tcp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/tls"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/udp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/websocket"

	// Transport headers (tcp/kcp/quic)
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/http"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/noop"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/srtp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/tls"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/utp"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wechat"
	_ "github.com/v2fly/v2ray-core/v5/transport/internet/headers/wireguard"

	// JSON config loader (v4-min subset)
	_ "github.com/v2fly/v2ray-core/v5/main/formats/${formats_pkg}"
)
EOF

	# Point main to our minimal distro.
	sed -i 's@_ "github.com/v2fly/v2ray-core/v5/main/distro/all"@_ "github.com/v2fly/v2ray-core/v5/main/distro/fancyss_vmess_v4_min"@' \
		${base_dir}/v2ray-core/main/main.go
}

case "${TRIM_MODE}" in
	default)
		apply_trim_default
		;;
	vmess_only)
		apply_trim_vmess_only
		;;
	vmess_v4_min)
		apply_trim_vmess_v4_min 0
		;;
	vmess_v4_min_req)
		apply_trim_vmess_v4_min 1
		;;
	*)
		echo "Unknown TRIM_MODE: ${TRIM_MODE} (expected: default|vmess_only|vmess_v4_min|vmess_v4_min_req)" >&2
		exit 1
		;;
esac

# build v2ray
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
	cd ${base_dir}/v2ray-core

	local VERSION=$(git describe --abbrev=0 --tags | sed 's/v//')

	LDFLAGS="-s -w -buildid= -X github.com/v2fly/v2ray-core/v5.codename=${CODENAME} -X github.com/v2fly/v2ray-core/v5.build=${BUILDNAME} -X github.com/v2fly/v2ray-core/v5.version=${VERSION}"

	echo "Compile v2ray $1 GOARM=${GOARM} GOARCH=${GOARCH}..."
	env CGO_ENABLED=0 GOARM=$GOARM GOARCH=$GOARCH go build -o "${TMP}/v2ray_${1}" -ldflags "$LDFLAGS" ./main

	cp ${TMP}/v2ray_${1} ${base_dir}/${OUTTAG}/
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
	rm -rf "../${OUTTAG}"
	mv -f "${OUTTAG}" ..

	# For custom trim modes, keep output in suffixed folder without changing the main latest pointer.
	echo -n "$OUTTAG" > "${DIR}/latest_v5_${TRIM_MODE}.txt"
	if [ "${TRIM_MODE}" = "default" ] && [ -z "${TARGET_TAG}" ]; then
		echo -n "$OUTTAG" > "${DIR}/latest_v5.txt"
	fi
}

build_v2 armv5
build_v2 armv7
build_v2 arm64
compress_binary
