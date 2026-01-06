// chinadns-ng preset DNS server list (for web UI).
// Exposes:
// - const china_dnsData
// - const trust_dnsData
//
// Note: keep this file loadable via <script src="/res/dns_servers.json.js">.
const dns_servers_data = [{
	"阿里公共DNS": [
		{"addr": "223.5.5.5", "net": "ipv4", "type": 3},
		{"addr": "223.6.6.6", "net": "ipv4", "type": 3},
		{"addr": "2400:3200::1", "net": "ipv6", "type": 3},
		{"addr": "2400:3200:baba::1", "net": "ipv6", "type": 3},
		{"addr": "dns.alidns.com@223.5.5.5", "net": "ipv4", "type": 4},
		{"addr": "dns.alidns.com@223.6.6.6", "net": "ipv4", "type": 4},
		{"addr": "dns.alidns.com@2400:3200::1", "net": "ipv6", "type": 4},
		{"addr": "dns.alidns.com@2400:3200:baba::1", "net": "ipv6", "type": 4}
	],
	"DNSPod DNS": [
		{"addr": "119.29.29.29", "net": "ipv4", "type": 1},
		{"addr": "119.28.28.28", "net": "ipv4", "type": 3},
		{"addr": "2402:4e00::", "net": "ipv6", "type": 3},
		{"addr": "2402:4e00:1::", "net": "ipv6", "type": 3},
		{"addr": "dot.pub@120.53.53.53", "net": "ipv4", "type": 4},
		{"addr": "dot.pub@1.12.12.21", "net": "ipv4", "type": 4}
	],
	"114 DNS": [
		{"addr": "114.114.114.114", "net": "ipv4", "type": 3, "description": "纯净版"},
		{"addr": "114.114.114.115", "net": "ipv4", "type": 3, "description": "纯净版"},
		{"addr": "114.114.114.119", "net": "ipv6", "type": 3, "description": "安全版"},
		{"addr": "114.114.115.119", "net": "ipv6", "type": 3, "description": "安全版"},
		{"addr": "114.114.114.110", "net": "ipv6", "type": 3, "description": "家庭版"},
		{"addr": "114.114.115.110", "net": "ipv6", "type": 3, "description": "家庭版"}
	],
	"360安全DNS": [
		{"addr": "dot.360.cn@180.163.249.75", "net": "ipv4", "type": 4},
		{"addr": "dot.360.cn@106.63.24.74", "net": "ipv4", "type": 4},
		{"addr": "dot.360.cn@36.99.170.86", "net": "ipv4", "type": 4}
	],
	"OneDNS": [
		{"addr": "52.80.66.66", "net": "ipv4", "type": 3, "description": "拦截版"},
		{"addr": "117.50.22.22", "net": "ipv4", "type": 3, "description": "拦截版"},
		{"addr": "2400:7fc0:849e:200::4", "net": "ipv6", "type": 3, "description": "拦截版"},
		{"addr": "2400:7fc0:849e:200::4", "net": "ipv6", "type": 3, "description": "拦截版"},
		{"addr": "117.50.10.10", "net": "ipv4", "type": 3, "description": "纯净版"},
		{"addr": "52.80.52.52", "net": "ipv4", "type": 3, "description": "纯净版"},
		{"addr": "2400:7fc0:849e:200::8", "net": "ipv6", "type": 3, "description": "纯净版"},
		{"addr": "2404:c2c0:85d8:901::8", "net": "ipv6", "type": 3, "description": "纯净版"},
		{"addr": "117.50.60.30", "net": "ipv4", "type": 3, "description": "家庭版"},
		{"addr": "52.80.60.30", "net": "ipv4", "type": 3, "description": "家庭版"},
		{"addr": "dot.onedns.net@106.75.177.177", "net": "ipv4", "type": 4, "description": "拦截版"},
		{"addr": "dot.onedns.net@106.75.165.71", "net": "ipv4", "type": 4, "description": "纯净版"}
	],
	"CNNIC DNS": [
		{"addr": "1.2.4.8", "net": "ipv4", "type": 3},
		{"addr": "210.2.4.8", "net": "ipv4", "type": 3}
	],
	"百度DNS": [
		{"addr": "180.76.76.76", "net": "ipv4", "type": 3}
	],
	"字节跳动DNS": [
		{"addr": "180.184.1.1", "net": "ipv4", "type": 3},
		{"addr": "180.184.2.2", "net": "ipv4", "type": 3}
	],
	"教育网DNS": [
		{"addr": "159.226.8.6", "net": "ipv4", "type": 3, "description": "中国科技网"},
		{"addr": "159.226.8.7", "net": "ipv4", "type": 3, "description": "中国科技网"},
		{"addr": "2001:cc0::1", "net": "ipv6", "type": 3, "description": "中国科技网"},
		{"addr": "101.6.6.6", "net": "ipv4", "type": 3, "description": "清华大学TUNA协会"},
		{"addr": "2402:f000:1:416:101:6:6:6", "net": "ipv6", "type": 3, "description": "清华大学TUNA协会"},
		{"addr": "58.132.8.1", "net": "ipv4", "type": 1, "description": "北京"},
		{"addr": "101.7.8.9", "net": "ipv4", "type": 3, "description": "清华大学TUNA协会"}
	]
},
{
	"Google DNS": [
		{"addr": "8.8.8.8", "net": "ipv4", "type": 3},
		{"addr": "8.8.4.4", "net": "ipv4", "type": 3},
		{"addr": "2001:4860:4860::8888", "net": "ipv6", "type": 3},
		{"addr": "2001:4860:4860::8844", "net": "ipv6", "type": 3},
		{"addr": "dns.google.com@8.8.8.8", "net": "ipv4", "type": 4},
		{"addr": "dns.google.com@8.8.4.4", "net": "ipv4", "type": 4}
	],
	"Cloudflare DNS": [
		{"addr": "1.1.1.1", "net": "ipv4", "type": 3},
		{"addr": "1.0.0.1", "net": "ipv4", "type": 3},
		{"addr": "1.1.1.2", "net": "ipv4", "type": 3},
		{"addr": "1.0.0.2", "net": "ipv4", "type": 3},
		{"addr": "1.1.1.3", "net": "ipv4", "type": 3},
		{"addr": "1.0.0.3", "net": "ipv4", "type": 3},
		{"addr": "2606:4700:4700::1111", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1001", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1112", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1002", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1113", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1003", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1003", "net": "ipv6", "type": 3},
		{"addr": "2606:4700:4700::1003", "net": "ipv6", "type": 3},
		{"addr": "1dot1dot1dot1.cloudflare-dns.com@1.1.1.1", "net": "ipv4", "type": 4},
		{"addr": "1dot1dot1dot1.cloudflare-dns.com@1.0.0.1", "net": "ipv4", "type": 4},
		{"addr": "one.one.one.one@1.1.1.1", "net": "ipv4", "type": 4},
		{"addr": "one.one.one.one@1.0.0.1", "net": "ipv4", "type": 4},
		{"addr": "dns.cloudflare.com@104.16.132.229", "net": "ipv4", "type": 4},
		{"addr": "dns.cloudflare.com@104.16.133.229", "net": "ipv4", "type": 4},
		{"addr": "security.cloudflare-dns.com@1.1.1.2", "net": "ipv4", "description": "安全版", "type": 4},
		{"addr": "security.cloudflare-dns.com@1.0.0.2", "net": "ipv4", "description": "安全版", "type": 4},
		{"addr": "family.cloudflare-dns.com@1.1.1.3", "net": "ipv4", "description": "家庭版", "type": 4},
		{"addr": "family.cloudflare-dns.com@1.0.0.3", "net": "ipv4", "description": "家庭版", "type": 4}
	],
	"Quad9": [
		{"addr": "9.9.9.9", "net": "ipv4", "type": 3},
		{"addr": "149.112.112.112", "net": "ipv4", "type": 3},
		{"addr": "9.9.9.10", "net": "ipv4", "type": 3},
		{"addr": "149.112.112.10", "net": "ipv4", "type": 3},
		{"addr": "9.9.9.11", "net": "ipv4", "type": 3},
		{"addr": "149.112.112.11", "net": "ipv4", "type": 3},
		{"addr": "dns.quad9.net@149.112.112.112", "net": "ipv4", "type": 4},
		{"addr": "dns.quad9.net@9.9.9.9", "net": "ipv4", "type": 4},
		{"addr": "dns9.quad9.net@149.112.112.9", "net": "ipv4", "type": 4},
		{"addr": "dns9.quad9.net@9.9.9.9", "net": "ipv4", "type": 4}
	],
	"Cisco OpenDNS/Cisco Umbrella": [
		{"addr": "208.67.222.222", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "208.67.220.220", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "208.67.222.220", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "208.67.220.222", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "208.67.222.123", "description": "家庭盾版", "net": "ipv4", "type": 3},
		{"addr": "208.67.220.123", "description": "家庭盾版", "net": "ipv4", "type": 3},
		{"addr": "2620:119:35::35", "description": "基础版", "net": "ipv6", "type": 3},
		{"addr": "2620:119:53::53", "description": "基础版", "net": "ipv6", "type": 3},
		{"addr": "2620:119:35::123", "description": "家庭盾版", "net": "ipv6", "type": 3},
		{"addr": "2620:119:53::123", "description": "家庭盾版", "net": "ipv6", "type": 3},
		{"addr": "dns.opendns.com@208.67.220.220", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "dns.opendns.com@208.67.222.222", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "dns.umbrella.com@208.67.220.220", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "dns.umbrella.com@208.67.222.222", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "dns.sse.cisco.com@208.67.220.220", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "dns.sse.cisco.com@208.67.222.222", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "familyshield.opendns.com@208.67.222.123", "description": "家庭盾版", "net": "ipv4", "type": 4},
		{"addr": "familyshield.opendns.com@208.67.222.123", "description": "家庭盾版", "net": "ipv4", "type": 4}
	],
	"DNS.SB": [
		{"addr": "185.222.222.222", "net": "ipv4", "type": 3},
		{"addr": "45.11.45.11", "net": "ipv4", "type": 3},
		{"addr": "2a09::", "net": "ipv6", "type": 3},
		{"addr": "2a11::", "net": "ipv6", "type": 3},
		{"addr": "dot.sb@185.222.222.222", "net": "ipv4", "type": 4},
		{"addr": "dns.sb@185.222.222.222", "net": "ipv4", "type": 4}
	],
	"AdGuard": [
		{"addr": "94.140.14.14", "description": "拦截版", "net": "ipv4", "type": 3},
		{"addr": "94.140.15.15", "description": "拦截版", "net": "ipv4", "type": 3},
		{"addr": "94.140.14.140", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "94.140.14.141", "description": "基础版", "net": "ipv4", "type": 3},
		{"addr": "94.140.14.15", "description": "家庭版", "net": "ipv4", "type": 3},
		{"addr": "94.140.15.16", "description": "家庭版", "net": "ipv4", "type": 3},
		{"addr": "2a10:50c0::ad1:ff", "description": "拦截版", "net": "ipv6", "type": 3},
		{"addr": "2a10:50c0::ad2:ff", "description": "拦截版", "net": "ipv6", "type": 3},
		{"addr": "2a10:50c0::1:ff", "description": "基础版", "net": "ipv6", "type": 3},
		{"addr": "2a10:50c0::2:ff", "description": "基础版", "net": "ipv6", "type": 3},
		{"addr": "2a10:50c0::bad1:ff", "description": "家庭版", "net": "ipv6", "type": 3},
		{"addr": "2a10:50c0::bad2:ff", "description": "家庭版", "net": "ipv6", "type": 3},
		{"addr": "dns.adguard-dns.com@94.140.15.1", "description": "拦截版", "net": "ipv4", "type": 4},
		{"addr": "dns.adguard-dns.com@94.140.14.14", "description": "拦截版", "net": "ipv4", "type": 4},
		{"addr": "unfiltered.adguard-dns.com@94.140.14.141", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "unfiltered.adguard-dns.com@94.140.14.140", "description": "基础版", "net": "ipv4", "type": 4},
		{"addr": "family.adguard-dns.com@94.140.14.15", "description": "家庭版", "net": "ipv4", "type": 4},
		{"addr": "family.adguard-dns.com@94.140.15.16", "description": "家庭版", "net": "ipv4", "type": 4}
	],
	"Level 3 Parent DNS": [
		{"addr": "4.2.2.1", "net": "ipv4", "type": 3},
		{"addr": "4.2.2.2", "net": "ipv4", "type": 3},
		{"addr": "4.2.2.3", "net": "ipv4", "type": 3},
		{"addr": "4.2.2.4", "net": "ipv4", "type": 3},
		{"addr": "4.2.2.5", "net": "ipv4", "type": 3},
		{"addr": "4.2.2.6", "net": "ipv4", "type": 3}
	],
	"Freenom World DNS": [
		{"addr": "80.80.80.80", "net": "ipv4", "type": 3},
		{"addr": "80.80.81.81", "net": "ipv4", "type": 3}
	],
	"TWNIC DNS Quad 101": [
		{"addr": "101.101.101.101", "net": "ipv4", "type": 3},
		{"addr": "101.102.103.104", "net": "ipv4", "type": 3},
		{"addr": "2001:de4::101", "net": "ipv6", "type": 3},
		{"addr": "2001:de4::102", "net": "ipv6", "type": 3},
		{"addr": "dns.twnic.tw@101.101.101.101", "net": "ipv4", "type": 3}
	],
	"HiNet 中华电信 DNS": [
		{"addr": "168.95.1.1", "net": "ipv4", "type": 3},
		{"addr": "168.95.192.1", "net": "ipv4", "type": 3},
		{"addr": "2001:b000:168::1", "net": "ipv6", "type": 3},
		{"addr": "2001:b000:168::2", "net": "ipv6", "type": 3}
	]
}];

const china_dnsData = dns_servers_data[0];
const trust_dnsData = dns_servers_data[1];
