<title>koolss</title>
<content>
	<script type="text/javascript" src="/js/jquery.min.js"></script>
	<script type="text/javascript" src="/js/tomato.js"></script>
	<script type="text/javascript" src="/js/advancedtomato.js"></script>
	<script type="text/javascript" src="/layer/layer.js"></script>
	<style type="text/css">
		.box, #ss_tabs {
			min-width:1122px;
			max-width:1122px;
		}
		.c-checkbox {
			margin-left:-10px;
		}
		/*Switch Icon Start*/
		.switch_field{
			width: 65px;
		}
		.switch_container{
			width: 50px;
			height: 30px;
			border: 1px solid transparent;
			margin-left: 35px;
		}
		.switch_bar{
			width: 43px;
			height: 16px;
			background-color: #717171;
			margin:7px auto 0;
			border-radius: 10px;
		}
		.switch_circle{
			width: 26px;
			height: 26px;
			border-radius: 16px;
			background-color: #FFF;
			margin-top: -21px;
			box-shadow: 0px 1px 4px 1px #444;
		}
		/*Icon*/
		.switch_circle > div{
			width: 16px;
			height: 16px;
			position: absolute;
			margin: 5px 0 0 5px;
		}
		/*background color of bar while checked*/
		.switch:checked ~.switch_container > .switch_bar{
			background-color: #279FD9;
		}
	
		/*control icon style while checked*/
		.switch:checked ~.switch_container > .switch_bar + .switch_circle > div{
			background-image: url("data:image/svg+xml;charset=US-ASCII,%3C%3Fxml%20version%3D%221.0%22%20encoding%3D%22iso-8859-1%22%3F%3E%0A%3Csvg%20version%3D%221.1%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20x%3D%220px%22%20y%3D%220px%22%20viewBox%3D%220%200%2016.9%2016.9%22%20style%3D%22enable-background%3Anew%200%200%2016.9%2016.9%3B%22%20xml%3Aspace%3D%22preserve%22%3E%0A%3Cg%20style%3D%22fill%3A%23279FD9%22%3E%0A%09%3Cpolygon%20points%3D%226.8%2C14.9%200%2C8.8%202.2%2C6.4%206.6%2C10.5%2014.5%2C1.9%2016.8%2C3.9%20%09%22%2F%3E%0A%3C%2Fg%3E%0A%3C%2Fsvg%3E%0A");
			background-repeat: no-repeat;
		}
		.switch:checked ~.switch_container > .switch_circle{
			margin-left: 23px;
		}
		#table-row-panel a.delete-row, #table-row-panel a.move-down-row, #table-row-panel a.move-row, #table-row-panel a.move-up-row {
			float:left;
			font-size:10pt;
			text-align:center;
			padding:13px 15px;
			padding:6px 8px;
			margin-right:5px;
			line-height:1;
			color:#fff;
			background:#585858;
			z-index:1;
			-webkit-transition:background-color 80ms ease;
			transition:background-color 80ms ease
		}
		#table-row-panel a.delete-row:hover, #table-row-panel a.move-down-row:hover, #table-row-panel a.move-row:hover, #table-row-panel a.move-up-row:hover {
			z-index:10;
			background:#434343
		}
		#table-row-panel a.delete-row {
			background:#F76D6A
		}
		#table-row-panel a.delete-row:hover {
			background:#eb4d4a
		}
		#table-row-panel a.apply-row, #table-row-panel a.move-down-row, #table-row-panel a.move-row, #table-row-panel a.move-up-row {
			float:left;
			font-size:10pt;
			text-align:center;
			padding:13px 15px;
			padding:6px 8px;
			line-height:1;
			color:#fff;
			background:#585858;
			z-index:1;
			-webkit-transition:background-color 80ms ease;
			transition:background-color 80ms ease
		}
		#table-row-panel a.apply-row:hover, #table-row-panel a.move-down-row:hover, #table-row-panel a.move-row:hover, #table-row-panel a.move-up-row:hover {
			z-index:10;
			background:#434343
		}
		#table-row-panel a.apply-row {
			background:#99FF66
		}
		#table-row-panel a.apply-row:hover {
			background:#99FF00
		}
	
		table.line-table tr:nth-child(even) {
			background:rgba(0, 0, 0, 0.04)
		}	
		#ss_node-grid > tbody > tr.even.use,
		#ssr_node-grid > tbody > tr.even.use {
			background:rgba(128, 255, 255, 0.3)
		}
		#ss_node-grid > tbody > tr.odd.use,
		#ssr_node-grid > tbody > tr.odd.use {
			background:rgba(128, 255, 255, 0.3)
		}
		table.line-table tr:hover {
			background:#D7D7D7
		}
		table.line-table tr:hover .progress {
			background:#D7D7D7
		}
		#ss_link-grid,
		#online_link-grid{
		    table-layout:fixed;/* 只有定义了表格的布局算法为fixed，下面td的定义才能起作用。 */
		}
		#ss_link-grid td,
		#online_link-grid td{
		    width:100%;
		    word-break:keep-all;/* 不换行 */
		    white-space:nowrap;/* 不换行 */
		    overflow:hidden;/* 内容超出宽度时隐藏超出部分的内容 */
		    text-overflow:ellipsis;/* 当对象内文本溢出时显示省略标记(...) ；需与overflow:hidden;一起使用。*/
		}
		select:hover, input:hover{
			border: 1px solid #0099FF
		}
		.btn.sub-btn-tab {
			/*border-radius: 3px;*/
			color:#777777!important;
			background:#FAFAFA;
			box-shadow:none;
			-webkit-box-shadow:none;
			line-height:1.2;
			border:1px solid rgba(119, 119, 119, 0.41);;
			border-width:0px 0 2px 0px
		}

		.btn.sub-btn-tab.active, .btn.btn-tab:focus {
			/*background:rgba(44, 196, 68, 0.47);*/
			border:1px solid #f36c21;
			border-width:0px 0 2px 0px
		}
	</style>
	<script type="text/javascript">
		var dbus;
		var layout;
		init_layout();
		get_dbus_data();
		get_arp_list();
		var _responseLen;
		var noChange = 0;
		var x = 4;
		var node_ss;
		var node_ssr;
		var status_time = 1;
		var status_refresh_rate = parseInt(dbus["ss_basic_refreshrate"]);
		var option_mode = [['1', 'gfwlist模式'], ['2', '大陆白名单模式'], ['3', '游戏模式'], ['4', '全局模式']];
		var option_mode_name = ['', 'gfwlist模式', '大陆白名单模式', '游戏模式', '全局模式'];
		var option_acl_mode = [['0', '不通过SS'], ['1', 'gfwlist模式'], ['2', '大陆白名单模式'], ['3', '游戏模式'], ['4', '全局模式']];
		var option_acl_mode_name = ['不通过SS', 'gfwlist模式', '大陆白名单模式', '游戏模式', '全局模式'];
		var option_acl_port = [['80,443', '80,443'], ['22,80,443', '22,80,443'], ['all', '全部端口'],['0', '自定义']];
		var option_acl_port_name = ['80,443', '22,80,443', '全部端口', '自定义'];
		var option_method = [['none', 'none'],['rc4', 'rc4'], ['rc4-md5', 'rc4-md5'], ['rc4-md5-6', 'rc4-md5-6'], ['aes-128-gcm', 'aes-128-gcm'], ['aes-192-gcm', 'aes-192-gcm'], ['aes-256-gcm', 'aes-256-gcm'], ['aes-128-cfb', 'aes-128-cfb'], ['aes-192-cfb', 'aes-192-cfb'], ['aes-256-cfb', 'aes-256-cfb'], ['aes-128-ctr', 'aes-128-ctr'], ['aes-192-ctr', 'aes-192-ctr'], ['aes-256-ctr', 'aes-256-ctr'], ['camellia-128-cfb', 'camellia-128-cfb'], ['camellia-192-cfb', 'camellia-192-cfb'], ['camellia-256-cfb', 'camellia-256-cfb'], ['bf-cfb', 'bf-cfb'], ['cast5-cfb', 'cast5-cfb'], ['idea-cfb', 'idea-cfb'], ['rc2-cfb', 'rc2-cfb'], ['seed-cfb', 'seed-cfb'], ['salsa20', 'salsa20'], ['chacha20', 'chacha20'], ['chacha20-ietf', 'chacha20-ietf'], ['chacha20-ietf-poly1305', 'chacha20-ietf-poly1305'], ['xchacha20-ietf-poly1305', 'xchacha20-ietf-poly1305']];
		var option_mptcp = [['0', '关闭'],['1', '开启']];
		var option_ssr_protocal = [['origin','origin'],['verify_simple','verify_simple'],['verify_sha1','verify_sha1'],['auth_sha1','auth_sha1'],['auth_sha1_v2','auth_sha1_v2'],['auth_sha1_v4','auth_sha1_v4'],['auth_aes128_md5','auth_aes128_md5'],['auth_aes128_sha1','auth_aes128_sha1'],['auth_chain_a','auth_chain_a'],['auth_chain_b','auth_chain_b'],['auth_chain_c','auth_chain_c'],['auth_chain_d','auth_chain_d'],['auth_chain_e','auth_chain_e'],['auth_chain_f','auth_chain_f']];
		var option_ssr_obfs = [['plain','plain'],['http_simple','http_simple'],['http_post','http_post'],['tls1.2_ticket_auth','tls1.2_ticket_auth']];
		var option_dns_china = [['1', '运营商DNS【自动获取】'],  ['2', '阿里DNS1【223.5.5.5】'],  ['3', '阿里DNS2【223.6.6.6】'],  ['4', '114DNS1【114.114.114.114】'],  ['5', '114DNS1【114.114.115.115】'],  ['6', 'cnnic DNS【1.2.4.8】'],  ['7', 'cnnic DNS【210.2.4.8】'],  ['8', 'oneDNS1【112.124.47.27】'],  ['9', 'oneDNS2【114.215.126.16】'],  ['10', '百度DNS【180.76.76.76】'],  ['11', 'DNSpod DNS【119.29.29.29】'],  ['12', '自定义']];
		var option_dns_foreign = [['1', 'dns2socks'], ['2', 'ss-tunnel'], ['3', 'dnscrypt-proxy'], ['4', 'pdnsd'], ['5', 'ChinaDNS'], ['6', 'Pcap_DNSProxy'], ['7', 'cdns']];
		var option_opendns = [['adguard-dns-family-ns1', 'Adguard DNS Family Protection 1'], ['adguard-dns-family-ns2', 'Adguard DNS Family Protection 2'], ['adguard-dns-ns1', 'Adguard DNS 1'], ['adguard-dns-ns2', 'Adguard DNS 2'], ['bikinhappy-sg', 'BikinHappy Singapore'], ['bn-fr0', 'Babylon Network France 0'], ['bn-fr0-ipv6', 'Babylon Network France 0 (IPv6)'], ['bn-fr1', 'Babylon Network France 1'], ['bn-fr1-ipv6', 'Babylon Network France 1 (IPv6)'], ['bn-nl0', 'Babylon Network Netherlands 0'], ['bn-nl0-ipv6', 'Babylon Network Netherlands 0 (IPv6)'], ['cisco', 'Cisco OpenDNS'], ['cisco-familyshield', 'Cisco OpenDNS with FamilyShield'], ['cisco-ipv6', 'Cisco OpenDNS over IPv6'], ['cpunks-ru', 'Cypherpunks.ru'], ['cs-caeast', 'CS Canada east DNSCrypt server'], ['cs-cawest', 'CS Canada west DNSCrypt server'], ['cs-cfi', 'CS cryptofree France DNSCrypt server'], ['cs-cfii', 'CS secondary cryptofree France DNSCrypt server'], ['cs-ch', 'CS Switzerland DNSCrypt server'], ['cs-de', 'CS Frankfurt, DE DNSCrypt server'], ['cs-de3', 'CS Dusseldorf, DE DNSCrypt server'], ['cs-dk', 'CS Denmark DNSCrypt server'], ['cs-dk2', 'CS secondary Denmark DNSCrypt server'], ['cs-es', 'CS Spain DNSCrypt server'], ['cs-fi', 'CS Finland DNSCrypt server'], ['cs-fr', 'CS France DNSCrypt server'], ['cs-fr2', 'CS secondary France DNSCrypt server'], ['cs-lt', 'CS Lithuania DNSCrypt server'], ['cs-lv', 'CS Latvia DNSCrypt server'], ['cs-md', 'CS Moldova DNSCrypt server'], ['cs-nl', 'CS Netherlands DNSCrypt server'], ['cs-pl', 'CS Poland DNSCrypt server'], ['cs-pt', 'CS Portugal DNSCrypt server'], ['cs-ro', 'CS Romania DNSCrypt server'], ['cs-rome', 'CS Italy DNSCrypt server'], ['cs-uk', 'CS England DNSCrypt server'], ['cs-useast', 'CS New York City NY US DNSCrypt server'], ['cs-useast2', 'CS Washington DC US DNSCrypt server'], ['cs-usnorth', 'CS Chicago IL US DNSCrypt server'], ['cs-ussouth', 'CS Dallas TX US DNSCrypt server'], ['cs-ussouth2', 'CS Atlanta GA US DNSCrypt server'], ['cs-uswest', 'CS Seattle WA US DNSCrypt server'], ['cs-uswest3', 'CS secondary Las Vegas NV US DNSCrypt server'], ['cs-uswest5', 'CS Los Angeles CA US DNSCrypt server'], ['d0wn-at-ns1', 'D0wn Resolver Austria 01'], ['d0wn-cz-ns1', 'D0wn Resolver Czech Republic 01'], ['d0wn-de-ns1', 'D0wn Resolver Germany 01'], ['d0wn-de-ns1-ipv6', 'D0wn Resolver Germany 01 over IPv6'], ['d0wn-es-ns1', 'D0wn Resolver Spain 01'], ['d0wn-fr-ns1', 'D0wn Resolver France 01'], ['d0wn-fr-ns2', 'D0wn Resolver France 02'], ['d0wn-fr-ns2-ipv6', 'D0wn Resolver France 02 over IPv6'], ['d0wn-gr-ns1', 'D0wn Resolver Greece 01'], ['d0wn-id-ns1', 'D0wn Resolver Indonesia 01'], ['d0wn-is-ns1', 'D0wn Resolver Iceland 01'], ['d0wn-is-ns2', 'D0wn Resolver Iceland 02'], ['d0wn-it-ns1', 'D0wn Resolver Italy 01'], ['d0wn-lv-ns1', 'D0wn Resolver Latvia 01'], ['d0wn-lv-ns2', 'D0wn Resolver Latvia 02'], ['d0wn-lv-ns2-ipv6', 'D0wn Resolver Latvia 01 over IPv6'], ['d0wn-md-ns1', 'D0wn Resolver Moldova 01'], ['d0wn-md-ns1-ipv6', 'D0wn Resolver Moldova 01 over IPv6'], ['d0wn-mx-ns1', 'D0wn Resolver Mexico 01'], ['d0wn-nl-ns1', 'D0wn Resolver Netherlands 01'], ['d0wn-nl-ns1-ipv6', 'D0wn Resolver Netherlands 01 over IPv6'], ['d0wn-nl-ns2', 'D0wn Resolver Netherlands 02'], ['d0wn-nl-ns2-ipv6', 'D0wn Resolver Netherlands 02 over IPv6'], ['d0wn-nl-ns4', 'D0wn Resolver Netherlands 04'], ['d0wn-random-ns1', 'D0wn Resolver Moldova Random 01'], ['d0wn-random-ns1-ipv6', 'D0wn Resolver Moldova Random 01 over IPv6'], ['d0wn-random-ns2', 'D0wn Resolver Netherlands Random 02'], ['d0wn-random-ns2-ipv6', 'D0wn Resolver Netherlands Random 02 over IPv6'], ['d0wn-ru-ns1', 'D0wn Resolver Russia 01'], ['d0wn-se-ns1', 'D0wn Resolver Sweden 01'], ['d0wn-se-ns1-ipv6', 'D0wn Resolver Sweden 01 over IPv6'], ['d0wn-se-ns2', 'D0wn Resolver Sweden 02'], ['d0wn-sg-ns1', 'D0wn Resolver Singapore 01'], ['d0wn-sg-ns1-ipv6', 'D0wn Resolver Singapore 01 over IPv6'], ['d0wn-tz-ns1', 'D0wn Resolver Tanzania 01'], ['d0wn-tz-ns1-ipv6', 'D0wn Resolver Tanzania 01 over IPv6'], ['d0wn-us-ns1', 'D0wn Resolver United States of America 01'], ['d0wn-us-ns2', 'D0wn Resolver United States of America 02'], ['d0wn-us-ns4', 'D0wn Resolver United States of America 04'], ['d0wn-za-ns1', 'D0wn Resolver South Africa 01'], ['dnscrypt.ca-1', 'dnscrypt.ca Server 1'], ['dnscrypt.ca-2', 'dnscrypt.ca Server 2'], ['dnscrypt.eu-dk', 'DNSCrypt.eu Denmark'], ['dnscrypt.eu-dk-ipv6', 'DNSCrypt.eu Denmark over IPv6'], ['dnscrypt.eu-nl', 'DNSCrypt.eu Holland'], ['dnscrypt.nl-ns0', 'DNSCrypt.nl The Netherlands (NL)'], ['dnscrypt.nl-ns0-ipv6', 'DNSCrypt.nl The Netherlands (NL) over IPv6'], ['dnscrypt.org-fr', 'DNSCrypt.org France'], ['fvz-anyone', 'Primary OpenNIC Anycast DNS Resolver'], ['fvz-anytwo', 'Secondary OpenNIC Anycast DNS Resolver'], ['ipredator', 'Ipredator.se Server'], ['ns0.dnscrypt.is', 'ns0.dnscrypt.is in Reykjavk, Iceland'], ['okturtles', 'okTurtles'], ['opennic-tumabox', 'TumaBox'], ['opennic-tumabox-ipv6', 'TumaBox over IPv6'], ['securedns', 'SecureDNS'], ['securedns-ipv6', 'SecureDNS over IPv6'], ['soltysiak', 'Soltysiak'], ['soltysiak-ipv6', 'Soltysiak over IPv6'], ['ventricle.us', 'Anatomical DNS'], ['yandex', 'Yandex']];
		var option_status_inter = [['0', '不更新'], ['5', '5s'], ['10', '10s'], ['15', '15s'], ['30', '30s'], ['60', '60s']];
		var option_sleep = [['0', '0s'], ['5', '5s'], ['10', '10s'], ['15', '15s'], ['30', '30s'], ['60', '60s']];
		var option_ss_obfs = [['0','关闭'],['obfs-http','obfs-http'],['obfs-tls','obfs-tls'],['v2ray-http','v2ray-http'],['v2ray-tls','v2ray-tls'],['v2ray-tls-path','v2ray-tls-path'],['v2ray-quic','v2ray-quic']];
		var option_lb_policy = [['1', '负载均衡'], ['2', '主用节点'], ['3', '备用节点']];
		var option_lb_policy_name = ['', '负载均衡', '主用节点', '备用节点'];
		var ssbasic = ["mode", "server", "port", "password", "method", "ss_obfs", "ss_obfs_host" ];
		var ssrbasic = ["mode", "server", "port", "password", "method", "rss_protocal", "rss_protocal_para", "rss_obfs", "rss_obfs_para"];
		var ssconf = ["ssconf_basic_mode_", "ssconf_basic_name_", "ssconf_basic_server_", "ssconf_basic_port_", "ssconf_basic_password_", "ssconf_basic_method_", "ssconf_basic_ss_obfs_", "ssconf_basic_ss_obfs_host_" ];
		var ssrconf = ["ssrconf_basic_mode_", "ssrconf_basic_name_", "ssrconf_basic_server_", "ssrconf_basic_port_", "ssrconf_basic_password_", "ssrconf_basic_method_", "ssrconf_basic_rss_protocal_", "ssrconf_basic_rss_protocal_para_", "ssrconf_basic_rss_obfs_", "ssrconf_basic_rss_obfs_para_"];
		var option_kcp_mode = [['manual', 'manual'], ['normal', 'normal'], ['fast', 'fast'], ['fast2', 'fast2'], ['fast3', 'fast3']];
		var option_kcp_crypt =[['aes', 'aes'], ['aes-128', 'aes-128'], ['aes-192', 'aes-192'], ['salsa20', 'salsa20'], ['blowfish', 'blowfish'], ['twofish', 'twofish'], ['cast5', 'cast5'], ['3des', '3des'], ['tea', 'tea'], ['xtea', 'xtea'], ['xor', 'xor'], ['none', 'none']];
		var option_arp_list = [];
		var option_arp_local = [];
		var option_arp_web = [];
		var option_node_name = [];
		var option_node_addr = [];
		var wans =[];
		var wans2 = [];
		var ss_lb_nodes =[];
		var ssr_lb_nodes =[];
		var wans_value =[];
		var wans_name =[];
		var softcenter = 0;
		var option_day_time = [["7", "每天"], ["1", "周一"], ["2", "周二"], ["3", "周三"], ["4", "周四"], ["5", "周五"], ["6", "周六"], ["0", "周日"]];
		var option_hour_time = [];
		for(var i = 0; i < 24; i++){
			option_hour_time[i] = [i, i + "点"];
		}
		var select_style="min-width:182px;max-width:182px";
		var input_style="min-width:182px;max-width:182px";
		if (typeof btoa == "Function") {
			Base64 = {
				encode: function(e) {
					return btoa(e);
				},
				decode: function(e) {
					return atob(e);
				}
			};
		} else {
			Base64 = {
				_keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
				encode: function(e) {
					var t = "";
					var n, r, i, s, o, u, a;
					var f = 0;
					e = Base64._utf8_encode(e);
					while (f < e.length) {
						n = e.charCodeAt(f++);
						r = e.charCodeAt(f++);
						i = e.charCodeAt(f++);
						s = n >> 2;
						o = (n & 3) << 4 | r >> 4;
						u = (r & 15) << 2 | i >> 6;
						a = i & 63;
						if (isNaN(r)) {
							u = a = 64
						} else if (isNaN(i)) {
							a = 64
						}
						t = t + this._keyStr.charAt(s) + this._keyStr.charAt(o) + this._keyStr.charAt(u) + this._keyStr.charAt(a)
					}
					return t
				},
				decode: function(e) {
					var t = "";
					var n, r, i;
					var s, o, u, a;
					var f = 0;
					if (typeof(e) == "undefined"){
						return t = "";
					}
					e = e.replace(/[^A-Za-z0-9\+\/\=]/g, "");
					while (f < e.length) {
						s = this._keyStr.indexOf(e.charAt(f++));
						o = this._keyStr.indexOf(e.charAt(f++));
						u = this._keyStr.indexOf(e.charAt(f++));
						a = this._keyStr.indexOf(e.charAt(f++));
						n = s << 2 | o >> 4;
						r = (o & 15) << 4 | u >> 2;
						i = (u & 3) << 6 | a;
						t = t + String.fromCharCode(n);
						if (u != 64) {
							t = t + String.fromCharCode(r)
						}
						if (a != 64) {
							t = t + String.fromCharCode(i)
						}
					}
					t = Base64._utf8_decode(t);
					return t
				},
				_utf8_encode: function(e) {
					e = e.replace(/\r\n/g, "\n");
					var t = "";
					for (var n = 0; n < e.length; n++) {
						var r = e.charCodeAt(n);
						if (r < 128) {
							t += String.fromCharCode(r)
						} else if (r > 127 && r < 2048) {
							t += String.fromCharCode(r >> 6 | 192);
							t += String.fromCharCode(r & 63 | 128)
						} else {
							t += String.fromCharCode(r >> 12 | 224);
							t += String.fromCharCode(r >> 6 & 63 | 128);
							t += String.fromCharCode(r & 63 | 128)
						}
					}
					return t
				},
				_utf8_decode: function(e) {
					var t = "";
					var n = 0;
					var r = c1 = c2 = 0;
					while (n < e.length) {
						r = e.charCodeAt(n);
						if (r < 128) {
							t += String.fromCharCode(r);
							n++
						} else if (r > 191 && r < 224) {
							c2 = e.charCodeAt(n + 1);
							t += String.fromCharCode((r & 31) << 6 | c2 & 63);
							n += 2
						} else {
							c2 = e.charCodeAt(n + 1);
							c3 = e.charCodeAt(n + 2);
							t += String.fromCharCode((r & 15) << 12 | (c2 & 63) << 6 | c3 & 63);
							n += 3
						}
					}
					return t
				}
			}
		}
		function createFormFields(data, settings) {
			var id, id1, common, output, form = '';
			var s = $.extend({
					// Defaults
					'align': 'left',
					'grid': ['col-sm-3', 'col-sm-9']
				},
				settings);
			// Loop through array
			$.each(data,
				function(key, v) {
					if (!v) {
						form += '<br />';
						return;
					}
					if (v.ignore) return;
					form += '<fieldset' + ((v.rid) ? ' id="' + v.rid + '"' : '') + ((v.hidden) ? ' style="display: none;"' : '') + '>';
					if (v.help) {
						v.title += ' (<i data-toggle="tooltip" class="icon-info icon-normal" title="' + v.help + '"></i>)';
					}
					if (v.text) {
						if (v.title) {
							form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.title + '</label><div class="' + s.grid[1] + ' text-block">' + v.text + '</div></fieldset>';
						} else {
							form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.text + '</label></fieldset>';
						}
						return;
					}
					if (v.multi) multiornot = v.multi;
					else multiornot = [v];
					output = '';
					$.each(multiornot,
						function(key, f) {
							if ((f.type == 'radio') && (!f.id)) id = '_' + f.name + '_' + i;
							else id = (f.id ? f.id : ('_' + f.name));
							if (id1 == '') id1 = id;
							common = ' onchange="verifyFields(this, 1)" id="' + id + '"';
							if (f.size > 65) common += ' style="width: 100%; display: block;"';
							if (f.hidden) common += ' style="display:none;"'; //add by sadog
							if (f.attrib) common += ' ' + f.attrib;
							name = f.name ? (' name="' + f.name + '"') : '';
							// Prefix
							if (f.prefix) output += f.prefix;
							switch (f.type) {
								case 'checkbox':
									output += '<div class="checkbox c-checkbox"><label><input class="custom" type="checkbox"' + name + (f.value ? ' checked' : '') + ' onclick="verifyFields(this, 1)"' + common + '>\
		<span></span> ' + (f.suffix ? f.suffix : '') + '</label></div>';
									break;
								case 'radio':
									output += '<div class="radio c-radio"><label><input class="custom" type="radio"' + name + (f.value ? ' checked' : '') + ' onclick="verifyFields(this, 1)"' + common + '>\
		<span></span> ' + (f.suffix ? f.suffix : '') + '</label></div>';
									break;
								case 'password':
									if (f.peekaboo) {
										switch (get_config('web_pb', '1')) {
											case '0':
												f.type = 'text';
											case '2':
												f.peekaboo = 0;
												break;
										}
									}
									if (f.type == 'password') {
										common += ' autocomplete="off"';
										if (f.peekaboo) common += ' onfocus=\'peekaboo("' + id + '",1)\' onclick=\'this.removeAttribute(' + 'readonly' + ');\' readonly="true"';
									}
									// drop
								case 'text':
									output += '<input type="' + f.type + '"' + name + ' value="' + escapeHTML(UT(f.value)) + '" maxlength=' + f.maxlen + (f.size ? (' size=' + f.size) : '') + (f.style ? (' style=' + f.style) : '') + (f.onblur ? (' onblur=' + f.onblur) : '') + common + '>';
									break;
								case 'select':
									output += '<select' + name + (f.style ? (' style=' + f.style) : '') + common + '>';
									for (optsCount = 0; optsCount < f.options.length; ++optsCount) {
										a = f.options[optsCount];
										if (a.length == 1) a.push(a[0]);
										output += '<option value="' + a[0] + '"' + ((a[0] == f.value) ? ' selected' : '') + '>' + a[1] + '</option>';
									}
									output += '</select>';
									break;
								case 'textarea':
									output += '<textarea ' + (f.style ? (' style="' + f.style + '" ') : '') + name + common + (f.wrap ? (' wrap=' + f.wrap) : '') + '>' + escapeHTML(UT(f.value)) + '</textarea>';
									break;
								default:
									if (f.custom) output += f.custom;
									break;
							}
							if (f.suffix && (f.type != 'checkbox' && f.type != 'radio')) output += '<span class="help-block">' + f.suffix + '</span>';
						});
					if (id1 != '') form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '" for="' + id + '">' + v.title + '</label><div class="' + s.grid[1] + '">' + output;
					else form += '<label>' + v.title + '</label>';
					form += '</div></fieldset>';
				});
			return form;
		}
		//============================================
		var ss_node = new TomatoGrid();
		ss_node.dataToView = function(data) {
			return [ data[0], option_mode_name[data[1]], data[2] || "节点" + data.length, data[3], data[4], data[5], data[6], (data[7] == 0 ? "" : data[7]), data[8], data[9]];
		}
		ss_node.verifyFields = function( row, quiet ) {
			var f = fields.getAll( row );
			return v_port( f[4], quiet );
		}
		ss_node.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value   = '';
			f[ 1 ].selectedIndex   = '';
			f[ 2 ].value   = '';
			f[ 3 ].value   = '';
			f[ 4 ].value   = '';
			f[ 5 ].value   = '';
			f[ 6 ].selectedIndex   = '';
			f[ 7 ].selectedIndex   = '';
			f[ 8 ].value   = '';
			f[ 9 ].value   = '';
		}
		ss_node.sortCompare = function(a, b) {
			var obj = TGO(a);
			var col = obj.sortColumn;
			if(col == 0 || col == 4){ //add by sasdog
				var r = cmpText(parseInt(a.cells[col].innerHTML), parseInt(b.cells[col].innerHTML));
			}else{
				var r = cmpText(a.cells[col].innerHTML, b.cells[col].innerHTML);
			}
			return obj.sortAscending ? r : -r;
		}

		ss_node.rpMo = function(img, e) {
			var me;
			e = PR(e);
			me = TGO(e);
			if (me.moving == e) {
				me.moving = null;
				this.rpHide();
				return;
			}
			me.moving = e;
			img.style.border = "3px solid red";
		}
		ss_node.onClick = function(cell) {
			if (this.canEdit) {
				if (this.moving) {
					var p = this.moving.parentNode;
					var q = PR(cell);
					if (this.moving != q) {
						var v = this.moving.rowIndex > q.rowIndex;
						p.removeChild(this.moving);
						if (v) p.insertBefore(this.moving, q);
						else p.insertBefore(this.moving, q.nextSibling);
						this.recolor();
					}
					this.moving = null;
					this.rpHide();
					return;
				}
				this.edit(cell);
				$("#ss_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ss_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(10)").hide();
			}
		}
		ss_node.onDelete = function() {
			this.removeEditor();
			var del_ss_node = parseInt(this.source.cells[0].innerHTML);
			var cur_sel_node = parseInt(dbus["ss_basic_node"]);
			var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
			if (del_ss_node == cur_sel_node){
				alert("该节点正在使用！\n删除节点保存后帐号设置界面显示的节点会显示成下一个！\n删除后除非重新提交，之前的节点仍然在后台使用！");
			}
			if (del_ss_node == cur_kcp_node){
				alert("请注意，你删除的节点是KCP加速节点！\n删除后请注意设置KCP加速");
				dbus["ss_kcp_node"] = "";
			}
			elem.remove(this.source);
			this.source = null;
			this.disableNewEditor(false);
			dbus["ssconf_basic_node_max"] = this.tb.rows.length - 3 //addby sadog
			dbus["ssconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}
		ss_node.rpDel = function(e) {
			e = PR(e);
			var del_ss_node = parseInt(e.cells[0].innerHTML);
			var cur_sel_node = parseInt(dbus["ss_basic_node"]);
			var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
			if (del_ss_node == cur_sel_node){
				alert("该节点正在使用！\n不能被删除！\n需要删除，请关闭ss或者切换到其它节点删除！");
				return false;
			}
			if (del_ss_node == cur_kcp_node){
				alert("请注意，你删除的节点是KCP加速节点，删除后请注意设置KCP加速");
				dbus["ss_kcp_node"] = "";
			}
			TGO(e).moving = null;
			e.parentNode.removeChild(e);
			this.recolor();
			this.rpHide();
			dbus["ssconf_basic_node_max"] = this.tb.rows.length - 3 //addby sadog
			dbus["ssconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}
		ss_node.rpMouIn = function(evt) {
			var e, x, ofs, me, s, n;
			if ((evt = checkEvent(evt)) == null || evt.target.nodeName == 'A' || evt.target.nodeName == 'I') return;
			me = TGO(evt.target);
			if (me.isEditing()) return;
			if (me.moving) return;
			if (evt.target.id != 'table-row-panel') {
				me.rpHide();
			}
			e = document.createElement('div');
			e.tgo = me;
			e.ref = evt.target;
			e.setAttribute('id', 'table-row-panel');
			n = 0;
			s = '';
			if (me.canMove) {
				s = '<a class="move-up-row" href="#" onclick="this.parentNode.tgo.rpUp(this.parentNode.ref); return false;" title="上移"><i class="icon-chevron-up"></i></a> \
				<a class="move-down-row" href="#" onclick="this.parentNode.tgo.rpDn(this.parentNode.ref); return false;" title="下移"><i class="icon-chevron-down"></i></a> \
				<a class="move-row" href="#" onclick="this.parentNode.tgo.rpMo(this,this.parentNode.ref); return false;" title="移动"><i class="icon-move"></i></a> ';
				n += 3;
			}
			if (me.canDelete) {
				s += '<a class="delete-row" href="#" onclick="this.parentNode.tgo.rpDel(this.parentNode.ref); return false;" title="删除"><i class="icon-cancel"></i></a>';
				s += '<a class="apply-row" href="#" onclick="this.parentNode.tgo.rpApply(this.parentNode.ref); return false;" title="应用"><i class="icon-check"></i></a>';
				++n;
			}
			x = PR(evt.target);
			x = x.cells[x.cells.length - 1];
			ofs = elem.getOffset(x);
			n *= 18;
			e.innerHTML = s;
			this.appendChild(e);
		}
		ss_node.rpApply = function(e) {
			e = PR(e);
			var apply_ss_node = parseInt(e.cells[0].innerHTML);
			E("_ss_basic_node").value = apply_ss_node;
			if (confirm("确定要应用此节点?")) {
				auto_node_sel();
				verifyFields();
				save();
			} else {
				return false;
			}
		}
		ss_node.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor); 
			data[0] = String(parseInt(this.tb.rows[this.tb.rows.length - 3].cells[0].innerHTML) + 1 || 0 + 1); //addby sadog
			this.insertData(-1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
			dbus["ssconf_basic_node_max"] = this.tb.rows.length -3 //addby sadog
			dbus["ssconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}
		ss_node.insert = function(at, data, cells, escCells) {
			var e, i;
			if ((this.footer) && (at == -1)) at = this.footer.rowIndex;
			e = this._insert(at, cells, escCells);
			e.className = (e.rowIndex & 1) ? 'even' : 'odd';
			if ((parseInt(dbus["ss_basic_node"]) == parseInt(e.cells[0].innerHTML)) && dbus["ss_basic_enable"] == 1){
				e.className = (e.rowIndex & 1) ? 'even use' : 'odd use';
			}
			for (i = 0; i < e.cells.length; ++i) {
				e.cells[i].onclick = function() {
					return TGO(this).onClick(this);
				};
			}
			e._data = data;
			e.getRowData = function() {
				return this._data;
			}
			e.setRowData = function(data) {
				this._data = data;
			}
			if ((this.canMove) || (this.canEdit) || (this.canDelete)) {
				e.onmouseover = this.rpMouIn;
				e.onmouseout = this.rpMouOut;
				if (this.canEdit) e.title = '点击编辑';
				$(e).css('cursor', 'text');
			}
			return e;
		}
		ss_node.recolor = function() {
			var i, e, o;
			i = this.header ? this.header.rowIndex + 1 : 0;
			e = this.footer ? this.footer.rowIndex : this.tb.rows.length;
			for (; i < e; ++i) {
				o = this.tb.rows[i];
				o.className = (o.rowIndex & 1) ? 'even' : 'odd';
				if ((parseInt(dbus["ss_basic_node"]) == parseInt(o.cells[0].innerHTML)) && dbus["ss_basic_enable"] == 1){
					o.className = (o.rowIndex & 1) ? 'even use' : 'odd use';
				}
			}
		}
		ss_node.createEditor = function(which, rowIndex, source) {
			var values;
			if (which == 'edit') values = this.dataToFieldValues(source.getRowData());
			var row = this.tb.insertRow(rowIndex);
			row.className = 'editor';
			var common = ' onkeypress="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var common_b = ' onclick="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var vi = 0;
			for (var i = 0; i < this.editorFields.length; ++i) {
				var s = '';
				var ef = this.editorFields[i].multi;
				if (!ef) ef = [this.editorFields[i]];
				for (var j = 0; j < ef.length; ++j) {
					var f = ef[j];
					if (f.prefix) s += f.prefix;
					var attrib = ' class="fi' + (vi + 1) + ' ' + (f['class'] ? f['class'] : '') + '" ' + (f.attrib || '');
					var id = (this.tb ? ('_' + this.tb.id + '_' + (vi + 1)) : null);
					if (id) attrib += ' id="' + id + '"';
					switch (f.type) {
						case 'password':
							if (f.peekaboo) {
								switch (get_config('web_pb', '1')) {
									case '0':
										f.type = 'text';
									case '2':
										f.peekaboo = 0;
										break;
								}
							}
							attrib += ' autocomplete="off"';
							if (f.peekaboo && id) attrib += ' onfocus=\'peekaboo("' + id + '",1)\'';
							// drop
						case 'text':
							s += '<input type="' + f.type + '" maxlength=' + f.maxlen + common + attrib;
							if (which == 'edit') s += ' value="' + escapeHTML('' + values[vi]) + '">';
							else s += '>';
							break;
						case 'select':
							s += '<select' + common + attrib + '>';
							for (var k = 0; k < f.options.length; ++k) {
								a = f.options[k];
								if (which == 'edit') {
									s += '<option value="' + a[0] + '"' + ((a[0] == values[vi]) ? ' selected>' : '>') + a[1] + '</option>';
								} else {
									s += '<option value="' + a[0] + '">' + a[1] + '</option>';
								}
							}
							s += '</select>';
							break;
						case 'checkbox':
							s += '<div class="checkbox c-checkbox"><label><input type="checkbox"' + common + attrib;
							if ((which == 'edit') && (values[vi])) s += ' checked';
							s += '><span></span> </label></div>';
							break;
						case 'textarea':
							if (which == 'edit') {
								document.getElementById(f.proxy).value = values[vi];
							}
							break;
						default:
							s += f.custom.replace(/\$which\$/g, which);
					}
					if (f.suffix) s += f.suffix;
					++vi;
				}
				var c = row.insertCell(i);
				c.innerHTML = s;
				// Added verticalAlignment, this fixes the incorrect vertical positioning of inputs in the editorRow
				if (this.editorFields[i].vtop) {
					c.vAlign = 'top';
					c.style.verticalAlign = "top";
				}
			}
			return row;
		}
		ss_node.disableNewEditor = function(disable) {
			if (this.getDataCount() >= this.maxAdd) disable = true;
			if (this.newEditor) fields.disableAll(this.newEditor, disable);
			if (this.newControls) fields.disableAll(this.newControls, disable);
			$("#ss_node-grid > tbody > tr > td:nth-child(1)").show();
			$("#ss_node-grid > tbody > tr > td:nth-child(6)").hide();
			$("#ss_node-grid > tbody > tr > td:nth-child(9)").hide();
			$("#ss_node-grid > tbody > tr > td:nth-child(10)").show();
		}
		ss_node.setup = function() {
			this.init( 'ss_node-grid', 'move, sort', 500, [
				{ type: 'text', maxlen: 5 },
				{ type: 'select', options:option_mode,value:'' },
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50, size:4 },
				{ type: 'text', maxlen: 50 },
				{ type: 'select', options:option_method,value:''},
				{ type: 'select', options:option_ss_obfs,value:''},
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50 }
			] );
			this.headerSet( [ '序号',  '模式', '节点名称', '服务器地址', '端口', '密码', '加密方式', '混淆(AEAD)', '混淆主机名', 'ping' ] );
			for ( var i = 1; i <= dbus["ssconf_basic_node_max"]; i++){
				var t1 = [
					String(i),
					dbus["ssconf_basic_mode_" + i ],
					dbus["ssconf_basic_name_" + i ],
					dbus["ssconf_basic_server_" + i ],
					dbus["ssconf_basic_port_" + i ],
					dbus["ssconf_basic_password_" + i ],
					dbus["ssconf_basic_method_" + i ],
					dbus["ssconf_basic_ss_obfs_" + i ] || "关闭",
					dbus["ssconf_basic_ss_obfs_host_" + i ] || " ",
					" "
					]
				if ( t1.length == 10 ) this.insertData( -1, t1 );
			}
			this.showNewEditor();
			this.resetNewEditor();
			// hide edit td 1 12
			E('_ss_node-grid_1').style.display = "none";
			E('_ss_node-grid_10').style.display = "none";
			// add placeholder for input
			$("#ss_node-grid #_ssr_node-grid_3").attr("placeholder", "节点名")
			$("#ss_node-grid #_ssr_node-grid_4").attr("placeholder", "地址")
			$("#ss_node-grid #_ssr_node-grid_5").attr("placeholder", "端口")
			$("#ss_node-grid #_ssr_node-grid_6").attr("placeholder", "密码")
			$("#ss_node-grid #_ssr_node-grid_9").attr("placeholder", "混淆主机")
			// adjust width
			$("#ss_node-grid > tbody > tr > td:nth-child(5)").css("width", "100px");
			// hide some info less column
			if(dbus["ssconf_basic_node_max"]){
				$("#ss_node-grid > tbody > tr > td:nth-child(6)").hide();
				$("#ss_node-grid > tbody > tr > td:nth-child(9)").hide();
			}else{
				$("#ss_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ss_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(10)").hide();
			}

			// when adding node, make all usedfull colum visible
			$("#ss_node-grid > tbody > tr.editor").click(
				function() {
				$("#ss_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ss_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ss_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ss_node-grid > tbody > tr > td:nth-child(10)").hide();
			});
		}
		//============================================
		var ssr_node = new TomatoGrid();
		ssr_node.verifyFields = function( row, quiet ) {
			var f = fields.getAll( row );
			return v_port( f[4], quiet );
		}
		ssr_node.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value   = '';
			f[ 1 ].selectedIndex   = '';
			f[ 2 ].value   = '';
			f[ 3 ].value   = '';
			f[ 4 ].value   = '';
			f[ 5 ].value   = '';
			f[ 6 ].selectedIndex   = '';
			f[ 7 ].selectedIndex   = '';
			f[ 8 ].value   = '';
			f[ 9 ].selectedIndex   = '';
			f[ 10 ].value   = '';
			f[ 11 ].value   = '';
		}
		ssr_node.sortCompare = function(a, b) {
			var obj = TGO(a);
			var col = obj.sortColumn;
			if(col == 0 || col == 4){ //add by sasdog
				var r = cmpText(parseInt(a.cells[col].innerHTML), parseInt(b.cells[col].innerHTML));
			}else{
				var r = cmpText(a.cells[col].innerHTML, b.cells[col].innerHTML);
			}
			return obj.sortAscending ? r : -r;
		}
		ssr_node.rpMo = function(img, e) {
			var me;
			e = PR(e);
			me = TGO(e);
			if (me.moving == e) {
				me.moving = null;
				this.rpHide();
				return;
			}
			me.moving = e;
			img.style.border = "3px solid red";
		}
		ssr_node.onClick = function(cell) {
			if (this.canEdit) {
				if (this.moving) {
					var p = this.moving.parentNode;
					var q = PR(cell);
					if (this.moving != q) {
						var v = this.moving.rowIndex > q.rowIndex;
						p.removeChild(this.moving);
						if (v) p.insertBefore(this.moving, q);
						else p.insertBefore(this.moving, q.nextSibling);
						this.recolor();
					}
					this.moving = null;
					this.rpHide();
					return;
				}
				this.edit(cell);
				$("#ssr_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ssr_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(11)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(12)").hide();
			}
		}
		ssr_node.onDelete = function() {
			this.removeEditor();
			var del_ssr_node = parseInt(this.source.cells[0].innerHTML);
			var cur_sel_node = parseInt(dbus["ss_basic_node"]);
			var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
			if (del_ssr_node == (cur_sel_node - node_ss)){
				alert("该节点正在使用！\n删除节点保存后帐号设置界面显示的节点会显示成下一个！\n删除后除非重新提交，之前的节点仍然在后台使用！");
			}
			if (del_ssr_node == (cur_kcp_node - node_ss)){
				alert("请注意，你删除的节点是KCP加速节点！\n删除后请注意设置KCP加速");
				dbus["ss_kcp_node"] = "";
			}
			elem.remove(this.source);
			this.source = null;
			this.disableNewEditor(false);
			dbus["ssrconf_basic_node_max"] = this.tb.rows.length - 3 //addby sadog
			dbus["ssrconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}

		ssr_node.rpDel = function(e) {
			e = PR(e);
			var del_ssr_node = parseInt(e.cells[0].innerHTML);
			var cur_sel_node = parseInt(dbus["ss_basic_node"]);
			var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
			if (del_ssr_node == (cur_sel_node - node_ss)){
				alert("该节点正在使用！\n不能被删除！\n需要删除，请关闭ss或者切换到其它节点删除！");
				return false;
			}
			if (del_ssr_node == (cur_kcp_node - node_ss)){
				alert("请注意，你删除的节点是KCP加速节点，删除后请注意设置KCP加速");
				dbus["ss_kcp_node"] = "";
			}
			TGO(e).moving = null;
			e.parentNode.removeChild(e);
			this.recolor();
			this.rpHide();
			dbus["ssrconf_basic_node_max"] = this.tb.rows.length - 3 //addby sadog
			dbus["ssrconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}
		ssr_node.rpMouIn = function(evt) {
			var e, x, ofs, me, s, n;
			if ((evt = checkEvent(evt)) == null || evt.target.nodeName == 'A' || evt.target.nodeName == 'I') return;
			me = TGO(evt.target);
			if (me.isEditing()) return;
			if (me.moving) return;
			if (evt.target.id != 'table-row-panel') {
				me.rpHide();
			}
			e = document.createElement('div');
			e.tgo = me;
			e.ref = evt.target;
			e.setAttribute('id', 'table-row-panel');
			n = 0;
			s = '';
			if (me.canMove) {
				s = '<a class="move-up-row" href="#" onclick="this.parentNode.tgo.rpUp(this.parentNode.ref); return false;" title="上移"><i class="icon-chevron-up"></i></a> \
				<a class="move-down-row" href="#" onclick="this.parentNode.tgo.rpDn(this.parentNode.ref); return false;" title="下移"><i class="icon-chevron-down"></i></a> \
				<a class="move-row" href="#" onclick="this.parentNode.tgo.rpMo(this,this.parentNode.ref); return false;" title="移动"><i class="icon-move"></i></a> ';
				n += 3;
			}
			if (me.canDelete) {
				s += '<a class="delete-row" href="#" onclick="this.parentNode.tgo.rpDel(this.parentNode.ref); return false;" title="删除"><i class="icon-cancel"></i></a>';
				s += '<a class="apply-row" href="#" onclick="this.parentNode.tgo.rpApply(this.parentNode.ref); return false;" title="应用"><i class="icon-check"></i></a>';
				++n;
			}
			x = PR(evt.target);
			x = x.cells[x.cells.length - 1];
			ofs = elem.getOffset(x);
			n *= 18;
			e.innerHTML = s;
			this.appendChild(e);
			//setTimeout('$("#table-row-panel").remove();', 2000);
			//$("#table-row-panel").remove();
			//setTimeout('TGO(this).rpHide()', 2000);
		}
		//ssr_node.rpMouOut = function(e) {
		//	setTimeout('$("#table-row-panel").remove();', 2000);
		//}
		ssr_node.rpApply = function(e) {
			e = PR(e);
			var apply_ss_node = parseInt(e.cells[0].innerHTML);
			E("_ss_basic_node").value = apply_ss_node + node_ss;
			if (confirm("确定要应用此节点?")) {
				auto_node_sel();
				verifyFields();
				save();
			} else {
				return false;
			}
		}
		ssr_node.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor); 
			data[0] = String(parseInt(this.tb.rows[this.tb.rows.length - 3].cells[0].innerHTML) + 1 || 0 + 1); //addby sadog
			this.insertData(-1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
			dbus["ssrconf_basic_node_max"] = this.tb.rows.length -3 //addby sadog
			dbus["ssrconf_basic_max_node"] = parseInt(this.tb.rows[this.tb.rows.length -3].cells[0].innerHTML) //addby sadog
		}
		ssr_node.insert = function(at, data, cells, escCells) {
			var e, i;
			if ((this.footer) && (at == -1)) at = this.footer.rowIndex;
			e = this._insert(at, cells, escCells);
			e.className = (e.rowIndex & 1) ? 'even' : 'odd';
			if ((parseInt(dbus["ss_basic_node"]) == parseInt(e.cells[0].innerHTML) + node_ss) && dbus["ss_basic_enable"] == 1){
				e.className = (e.rowIndex & 1) ? 'even use' : 'odd use';
			}
			for (i = 0; i < e.cells.length; ++i) {
				e.cells[i].onclick = function() {
					return TGO(this).onClick(this);
				};
			}
			e._data = data;
			e.getRowData = function() {
				return this._data;
			}
			e.setRowData = function(data) {
				this._data = data;
			}
			if ((this.canMove) || (this.canEdit) || (this.canDelete)) {
				e.onmouseover = this.rpMouIn;
				e.onmouseout = this.rpMouOut;
				if (this.canEdit) e.title = '点击编辑';
				$(e).css('cursor', 'text');
			}
			return e;
		}
		ssr_node.recolor = function() {
			var i, e, o;
			i = this.header ? this.header.rowIndex + 1 : 0;
			e = this.footer ? this.footer.rowIndex : this.tb.rows.length;
			for (; i < e; ++i) {
				o = this.tb.rows[i];
				o.className = (o.rowIndex & 1) ? 'even' : 'odd';
				if ((parseInt(dbus["ss_basic_node"]) == parseInt(o.cells[0].innerHTML) + node_ss) && dbus["ss_basic_enable"] == 1){
					o.className = (o.rowIndex & 1) ? 'even use' : 'odd use';
				}
			}
		}
		ssr_node.createEditor = function(which, rowIndex, source) {
			var values;
			if (which == 'edit') values = this.dataToFieldValues(source.getRowData());
			var row = this.tb.insertRow(rowIndex);
			row.className = 'editor';
			var common = ' onkeypress="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var vi = 0;
			for (var i = 0; i < this.editorFields.length; ++i) {
				var s = '';
				var ef = this.editorFields[i].multi;
				if (!ef) ef = [this.editorFields[i]];
				for (var j = 0; j < ef.length; ++j) {
					var f = ef[j];
					if (f.prefix) s += f.prefix;
					var attrib = ' class="fi' + (vi + 1) + ' ' + (f['class'] ? f['class'] : '') + '" ' + (f.attrib || '');
					var id = (this.tb ? ('_' + this.tb.id + '_' + (vi + 1)) : null);
					if (id) attrib += ' id="' + id + '"';
					switch (f.type) {
						case 'password':
							if (f.peekaboo) {
								switch (get_config('web_pb', '1')) {
									case '0':
										f.type = 'text';
									case '2':
										f.peekaboo = 0;
										break;
								}
							}
							attrib += ' autocomplete="off"';
							if (f.peekaboo && id) attrib += ' onfocus=\'peekaboo("' + id + '",1)\'';
							// drop
						case 'text':
							s += '<input type="' + f.type + '" maxlength=' + f.maxlen + common + attrib;
							if (which == 'edit') s += ' value="' + escapeHTML('' + values[vi]) + '">';
							else s += '>';
							break;
						case 'select':
							s += '<select' + common + attrib + '>';
							for (var k = 0; k < f.options.length; ++k) {
								a = f.options[k];
								if (which == 'edit') {
									s += '<option value="' + a[0] + '"' + ((a[0] == values[vi]) ? ' selected>' : '>') + a[1] + '</option>';
								} else {
									s += '<option value="' + a[0] + '">' + a[1] + '</option>';
								}
							}
							s += '</select>';
							break;
						case 'checkbox':
							s += '<div class="checkbox c-checkbox"><label><input type="checkbox"' + common + attrib;
							if ((which == 'edit') && (values[vi])) s += ' checked';
							s += '><span></span> </label></div>';
							break;
						case 'textarea':
							if (which == 'edit') {
								document.getElementById(f.proxy).value = values[vi];
							}
							break;
						default:
							s += f.custom.replace(/\$which\$/g, which);
					}
					if (f.suffix) s += f.suffix;
					++vi;
				}
				var c = row.insertCell(i);
				c.innerHTML = s;
				// Added verticalAlignment, this fixes the incorrect vertical positioning of inputs in the editorRow
				if (this.editorFields[i].vtop) {
					c.vAlign = 'top';
					c.style.verticalAlign = "top";
				}
			}
			return row;
		}
		ssr_node.disableNewEditor = function(disable) {
			if (this.getDataCount() >= this.maxAdd) disable = true;
			if (this.newEditor) fields.disableAll(this.newEditor, disable);
			if (this.newControls) fields.disableAll(this.newControls, disable);
			$("#ssr_node-grid > tbody > tr > td:nth-child(1)").show();
			$("#ssr_node-grid > tbody > tr > td:nth-child(6)").hide();
			$("#ssr_node-grid > tbody > tr > td:nth-child(9)").hide();
			$("#ssr_node-grid > tbody > tr > td:nth-child(11)").hide();
			$("#ssr_node-grid > tbody > tr > td:nth-child(12)").show();
		}
		ssr_node.insertData = function(at, data, i) {
			return this.insert(at, data, this.dataToView(data, i), false);
		}
		ssr_node.dataToView = function(data, i) {
			//var option_mode_name = ['', 'GFW', 'CHN', 'GAME', 'GLOABLE'];
			return [ data[0], option_mode_name[data[1]], 
					dbus["ssrconf_basic_group_" + i ] ? "【" + dbus["ssrconf_basic_group_" + i ] + "】" + dbus["ssrconf_basic_name_" + i ] : dbus["ssrconf_basic_name_" + i ]||data[2],
					data[3], data[4], data[5], data[6], data[7], (data[8].length > 1 ? "******" : ""), data[9], data[10], data[11]];
		}
		ssr_node.setup = function() {
			this.init( 'ssr_node-grid', 'sort, move', 500, [
				{ type: 'text', maxlen: 5 },
				{ type: 'select',maxlen:20,options:option_mode,value:'' },
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50 },
				{ type: 'text', maxlen: 50 },
				{ type: 'select',maxlen:40,options:option_method,value:''},
				{ type: 'select',maxlen:40,options:option_ssr_protocal,value:''},
				{ type: 'text', maxlen: 50 },
				{ type: 'select',maxlen:40,options:option_ssr_obfs,value:''},
				{ type: 'text', maxlen: 512 },
				{ type: 'text', maxlen: 512 }
			] );
			this.headerSet( [ '序号', '模式', '节点名称', '服务器地址', '端口', '密码', '加密方式', '协议', '协议参数', '混淆', '混淆参数', 'ping' ] );
			for ( var i = 1; i <= dbus["ssrconf_basic_node_max"]; i++){
				var t2 = [
						String(i),
						dbus["ssrconf_basic_mode_" + i ], 
						dbus["ssrconf_basic_name_" + i ], 
						dbus["ssrconf_basic_server_" + i ], 
						dbus["ssrconf_basic_port_" + i ], 
						dbus["ssrconf_basic_password_" + i ], 
						dbus["ssrconf_basic_method_" + i ],
						dbus["ssrconf_basic_rss_protocal_" + i ],
						dbus["ssrconf_basic_rss_protocal_para_" + i ] || "",
						dbus["ssrconf_basic_rss_obfs_" + i ],
						dbus["ssrconf_basic_rss_obfs_para_" + i ] || "",
						" "
						]  
				if ( t2.length == 12 ) this.insertData( -1, t2, i );
			}
			this.showNewEditor();
			this.resetNewEditor();
			// hide edit td 1 12
			E('_ssr_node-grid_1').style.display = "none";
			E('_ssr_node-grid_12').style.display = "none";
			// add placeholder for input
			$("#ssr_node-grid #_ssr_node-grid_3").attr("placeholder", "节点名")
			$("#ssr_node-grid #_ssr_node-grid_4").attr("placeholder", "地址")
			$("#ssr_node-grid #_ssr_node-grid_5").attr("placeholder", "端口")
			$("#ssr_node-grid #_ssr_node-grid_6").attr("placeholder", "密码")
			$("#ssr_node-grid #_ssr_node-grid_9").attr("placeholder", "协议参数")
			$("#ssr_node-grid #_ssr_node-grid_11").attr("placeholder", "混淆参数")
			// adjust width
			$("#ssr_node-grid > tbody > tr > td:nth-child(5)").css("width", "100px");
			// hide some info less column
			if(dbus["ssrconf_basic_node_max"]){
				$("#ssr_node-grid > tbody > tr > td:nth-child(6)").hide();
				$("#ssr_node-grid > tbody > tr > td:nth-child(9)").hide();
				$("#ssr_node-grid > tbody > tr > td:nth-child(11)").hide();
			}else{
				$("#ssr_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ssr_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(11)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(12)").hide();
			}
			// when adding node, make all usedfull colum visible
			$("#ssr_node-grid > tbody > tr.editor").click(
				function() {
				$("#ssr_node-grid > tbody > tr.odd > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.even > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr.editor > td:nth-child(1)").hide();
				$("#ssr_node-grid > tbody > tr:nth-child(1) > td.header.co1").hide();
				$("#ssr_node-grid > tbody > tr > td:nth-child(6)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(9)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(11)").show();
				$("#ssr_node-grid > tbody > tr > td:nth-child(12)").hide();
			});
		}
		//============================================
		var lb = new TomatoGrid();

		lb.dataToView = function(data) {
			return [ data[0], data[1], data[2], data[3], data[4], data[5], data[6], option_lb_policy_name[data[7]] ];
		}
	
		lb.verifyFields = function( row, quiet ) {
			var f = fields.getAll( row );
			return v_iptaddr( f[2], quiet ) && v_port( f[3], quiet );
		}
		lb.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[0].value   = '';
			f[1].value   = '';
			f[2].value   = '';
			f[3].value   = '';
			f[4].selectedIndex   = '';
			f[5].value   = '';
			f[6].value   = '';
		}
		lb.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor);
			this.insertData(-1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
		}
		lb.rpDel = function(e) {
			if (this.tb.rows.length == 2){
				dbus["ss_lb_type"] = ""
			}
			//$("#_ss_lb_node").append("<option value='" + deleted_value + "'>" + deleted_name[1] + "</option>");
			e = PR(e);
			TGO(e).moving = null;
			e.parentNode.removeChild(e);
			this.recolor();
			this.rpHide();
		}
		lb.init = function(tb, options, maxAdd, editorFields) {
			if (tb) {
				this.tb = E(tb);
				this.tb.gridObj = this;
			} else {
				this.tb = null;
			}
			if (!options) options = '';
			this.header = null;
			this.footer = null;
			this.editor = null;
			this.canSort = options.indexOf('sort') != -1;
			this.canMove = options.indexOf('move') != -1;
			this.maxAdd = maxAdd || 500;
			this.canEdit = false; //modified by sadog
			this.canDelete = true; //modified by sadog
			this.editorFields = editorFields;
			this.sortColumn = -1;
			//this.sortAscending = true;
		}
		lb.setup = function(lb_node, lb_type) {
			//get_dbus_data();
			if ($("#lb-grid > tbody > tr > td.header.co1").length == 0){
				this.init( 'lb-grid' );
				this.headerSet( ['节点名称', '节点序号', '服务器地址', '端口', '加密方式', '多wan出口', '权重', '属性' ] );
			}
			//ss set up on click
			if (lb_type == 1){
				var html ='<select name="ssconf_basic_lb_dest_' + lb_node + '" onchange="verifyFields(this, 1)" id="_ssconf_basic_lb_dest_' + lb_node + '"></select>'
				var t = [
						"【SS】" + dbus["ssconf_basic_name_" + lb_node ], 
						lb_node, 
						dbus["ssconf_basic_server_" + lb_node ], 
						dbus["ssconf_basic_port_" + lb_node ], 
						dbus["ssconf_basic_method_" + lb_node ], 
						//dbus["ssconf_basic_lb_dest_" + lb_node ] || wans[0][0],
						html,
						dbus["ssconf_basic_lb_weight_" + lb_node ],
						dbus["ssconf_basic_lb_policy_" + lb_node ]
						]
				if ( t.length == 8 ) this.insertData( -1, t );
				for ( var j = 0; j < wans.length; ++j ) {
					$("#_ssconf_basic_lb_dest_" + lb_node).append("<option value='"  + wans[j][0] + "'>" + wans[j][1] + "</option>");
				}
				E("_ssconf_basic_lb_dest_" + lb_node).value = dbus["ssconf_basic_lb_dest_" + lb_node] || 0;
			//ssr set up on click
			}else if (lb_type == 2){
				var html ='<select name="ssrconf_basic_lb_dest_' + lb_node + '" onchange="verifyFields(this, 1)" id="_ssrconf_basic_lb_dest_' + lb_node + '"></select>'
				var t = [
						"【SSR】" + dbus["ssrconf_basic_name_" + lb_node ], 
						lb_node, 
						dbus["ssrconf_basic_server_" + lb_node ], 
						dbus["ssrconf_basic_port_" + lb_node ], 
						dbus["ssrconf_basic_method_" + lb_node ],
						//dbus["ssrconf_basic_lb_dest_" + lb_node ] || wans[0][0],
						html,
						dbus["ssrconf_basic_lb_weight_" + lb_node ],
						dbus["ssrconf_basic_lb_policy_" + lb_node ]
						]
				if ( t.length == 8 ) this.insertData( -1, t );
				for ( var j = 0; j < wans.length; ++j ) {
					$("#_ssrconf_basic_lb_dest_" + lb_node).append("<option value='"  + wans[j][0] + "'>" + wans[j][1] + "</option>");
				}
				E("_ssrconf_basic_lb_dest_" + lb_node).value = dbus["ssrconf_basic_lb_dest_" + lb_node] || 0;
			}else{
				//ss set up on pageload
				for ( var i = 1; i <= dbus["ssconf_basic_node_max"]; i++){
					var html ='<select name="ssconf_basic_lb_dest_' + i + '" onchange="verifyFields(this, 1)" id="_ssconf_basic_lb_dest_' + i + '"></select>'
					if (dbus["ssconf_basic_lb_enable_" + i ] == 1){
						var t = ["【SS】" + dbus["ssconf_basic_name_" + i ], 
								String(i),
								dbus["ssconf_basic_server_" + i ], 
								dbus["ssconf_basic_port_" + i ], 
								dbus["ssconf_basic_method_" + i ],
								//dbus["ssconf_basic_lb_dest_" + i ] || wans[0][0],
								html,
								dbus["ssconf_basic_lb_weight_" + i ] || "50",
								dbus["ssconf_basic_lb_policy_" + i ] || "1"
								]
						if ( t.length == 8 ) this.insertData( -1, t );
						ss_lb_nodes.push(i);
						dbus["ss_lb_type"] = 1;
					}
				}
				//ssr set up on pageload
				for ( var i = 1; i <= dbus["ssrconf_basic_node_max"]; i++){
					if (dbus["ssrconf_basic_lb_enable_" + i ] == 1){
						var html ='<select name="ssrconf_basic_lb_dest_' + i + '" onchange="verifyFields(this, 1)" id="_ssrconf_basic_lb_dest_' + i + '">'
						for ( var j = 0; j < wans.length; ++j ) {
							html +='<option value=' + wans[j][0] + '>' + wans[j][1] + '</option>'
						}
						html +='</select>'
						var t = ["【SSR】" + dbus["ssrconf_basic_name_" + i ], 
								String(i),
								dbus["ssrconf_basic_server_" + i ], 
								dbus["ssrconf_basic_port_" + i ], 
								dbus["ssrconf_basic_method_" + i ],
								html,
								dbus["ssrconf_basic_lb_weight_" + i ] || "50", 
								dbus["ssrconf_basic_lb_policy_" + i ] || "1"
								]
						if ( t.length == 8 ) this.insertData( -1, t );
						ssr_lb_nodes.push(i);
						dbus["ss_lb_type"] = 2;
					}
				}
			}
		}
		
		function add_lb_node(){
			lb_node_sel = E('_ss_lb_node').value || 1;
			if (dbus["ssrconf_basic_rss_protocal_" + (lb_node_sel - node_ss)]){ // using ssr
				if (!dbus["ss_lb_type"] || dbus["ss_lb_type"] == 2){
					dbus["ssrconf_basic_lb_enable_" + (lb_node_sel - node_ss) ] = "1";
					dbus["ssrconf_basic_lb_weight_" + (lb_node_sel - node_ss) ] = E("_ss_lb_weight").value;
					dbus["ssrconf_basic_lb_policy_" + (lb_node_sel - node_ss) ] = E("_ss_lb_policy").value;
					dbus["ssrconf_basic_lb_dest_" + (lb_node_sel - node_ss) ] = E("_ss_lb_dest").value;
					dbus["ss_lb_type"] = 2;
					lb_type=2;
					lb_node = String(lb_node_sel - node_ss);
				}else{
					alert("SS节点和SSR节点之间不能负载均衡！")
					return false;
				}
			}else{ //ss
				if (!dbus["ss_lb_type"] || dbus["ss_lb_type"] == 1){
					dbus["ssconf_basic_lb_enable_" + lb_node_sel ] = "1";
					dbus["ssconf_basic_lb_weight_" + lb_node_sel ] = E("_ss_lb_weight").value;
					dbus["ssconf_basic_lb_policy_" + lb_node_sel ] = E("_ss_lb_policy").value;
					dbus["ssconf_basic_lb_dest_" + lb_node_sel ] = E("_ss_lb_dest").value;
					dbus["ss_lb_type"] = 1;
					lb_type=1;
					lb_node=lb_node_sel;
				}else{
					alert("SS节点和SSR节点之间不能负载均衡！")
					return false;
				}
			}
			lb.setup(lb_node, lb_type);
			//$("#_ss_lb_node option[value='" + lb_node_sel +"']").remove();
			$("#_ss_lb_node").val(parseInt(lb_node_sel) + 1);
		}

		//============================================
		var ss_acl = new TomatoGrid();
			ss_acl.dataToView = function( data ) {
			var option_acl_port = [['80,443', '80,443'], ['22,80,443', '22,80,443'], ['all', 'all'], ['0', '自定义']];
			var option_acl_port_value = ['80,443', '22,80,443', 'all', '0'];
			var option_acl_port_name = ['80,443', '22,80,443', '全部端口', '自定义'];
			var a = option_acl_port_value.indexOf(data[4]);
			var b = option_acl_port_name[a]
			if (data[4] == 0){
				b = data[5]
			}
		
			if (data[0]){
				return [ "【" + data[0] + "】", data[1], data[2], option_acl_mode_name[data[3]], b, data[5] ];
			}else{
				if (data[1]){
					return [ "【" + data[1] + "】", data[1], data[2], option_acl_mode_name[data[3]], b, data[5] ];
				}else{
					if (data[2]){
						return [ "【" + data[2] + "】", data[1], data[2], option_acl_mode_name[data[3]], b, data[5] ];
					}
				}
			}
		}
		ss_acl.fieldValuesToData = function( row ) {
			var f = fields.getAll( row );
			if (f[0].value){
				return [ f[0].value, f[1].value, f[2].value, f[3].value, f[4].value, f[5].value ];
			}else{
				if (f[1].value){
					return [ f[1].value, f[1].value, f[2].value, f[3].value, f[4].value, f[5].value ];
				}else{
					if (f[2].value){
						return [ f[2].value, f[1].value, f[2].value, f[3].value, f[4].value, f[5].value ];
					}
				}
			}
		}
		ss_acl.dataToFieldValues = function (data) {
			return [data[0], data[1], data[2], data[3], data[4], data[5]];
		}
    	ss_acl.onChange = function(which, cell) {
    	    return this.verifyFields((which == 'new') ? this.newEditor: this.editor, true, cell);
    	}
		ss_acl.alter_txt = function() {
			if (this.tb.rows.length == "3"){
				$('#ss_acl_default_pannel > fieldset:nth-child(3) > div > span').html('除了设置的访问控制主机，其它剩余主机都将走此处设定的模式和端口。');
				$("#ss_acl_default_pannel > fieldset:nth-child(1) > label").html('默认模式 (全部主机)');
				$("#ss_acl_default_pannel > fieldset:nth-child(2) > label").html('目标端口 (全部主机)');
			}else{
				$('#ss_acl_default_pannel > fieldset:nth-child(3) > div > span').html('当前未设置访问控制主机，所有路由器下的主机都将走此处设定的模式和端口。');
				$("#ss_acl_default_pannel > fieldset:nth-child(1) > label").html('默认模式 (其余主机)');
				$("#ss_acl_default_pannel > fieldset:nth-child(2) > label").html('目标端口 (其余主机)');
			}
		}
		ss_acl.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor);
			this.insertData(1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
			this.alter_txt(); // added by sadog
		}
		ss_acl.rpDel = function(b) {
			b = PR(b);
			TGO(b).moving = null;
			b.parentNode.removeChild(b);
			this.recolor();
			this.rpHide()
			this.alter_txt(); // added by sadog
		}
		ss_acl.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value = '';
			f[ 1 ].value   = '';
			f[ 2 ].value   = '';
			f[ 3 ].value   = '1';
			f[ 4 ].value   = '80,443';
			f[ 5 ].value   = '';
		}

		ss_acl.createEditor = function(which, rowIndex, source) {
			var values;
			if (which == 'edit') values = this.dataToFieldValues(source.getRowData());
			var row = this.tb.insertRow(rowIndex);
			row.className = 'editor';
			var common = ' onkeypress="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var common_b = ' onclick="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var vi = 0;
			for (var i = 0; i < this.editorFields.length; ++i) {
				var s = '';
				var ef = this.editorFields[i].multi;
				if (!ef) ef = [this.editorFields[i]];
				for (var j = 0; j < ef.length; ++j) {
					var f = ef[j];
					if (f.prefix) s += f.prefix;
					var attrib = ' class="fi' + (vi + 1) + ' ' + (f['class'] ? f['class'] : '') + '" ' + (f.attrib || '');
					var id = (this.tb ? ('_' + this.tb.id + '_' + (vi + 1)) : null);
					if (id) attrib += ' id="' + id + '"';
					switch (f.type) {
						case 'password':
							if (f.peekaboo) {
								switch (get_config('web_pb', '1')) {
									case '0':
										f.type = 'text';
									case '2':
										f.peekaboo = 0;
										break;
								}
							}
							attrib += ' autocomplete="off"';
							if (f.peekaboo && id) attrib += ' onfocus=\'peekaboo("' + id + '",1)\'';
							// drop
						case 'text':
							s += '<input type="' + f.type + '" maxlength=' + f.maxlen + common + attrib;
							if (which == 'edit') s += ' value="' + escapeHTML('' + values[vi]) + '">';
							else s += '>';
							break;
						case 'select':
							s += '<select' + common + attrib + '>';
							for (var k = 0; k < f.options.length; ++k) {
								a = f.options[k];
								if (which == 'edit') {
									s += '<option value="' + a[0] + '"' + ((a[0] == values[vi]) ? ' selected>' : '>') + a[1] + '</option>';
								} else {
									s += '<option value="' + a[0] + '">' + a[1] + '</option>';
								}
							}
							s += '</select>';
							break;
						case 'checkbox':
							s += '<div class="checkbox c-checkbox"><label><input type="checkbox"' + common + attrib;
							if ((which == 'edit') && (values[vi])) s += ' checked';
							s += '><span></span> </label></div>';
							break;
						case 'textarea':
							if (which == 'edit') {
								document.getElementById(f.proxy).value = values[vi];
							}
							break;
						default:
							s += f.custom.replace(/\$which\$/g, which);
					}
					if (f.suffix) s += f.suffix;
					++vi;
				}
				var c = row.insertCell(i);
				c.innerHTML = s;
				// Added verticalAlignment, this fixes the incorrect vertical positioning of inputs in the editorRow
				if (this.editorFields[i].vtop) {
					c.vAlign = 'top';
					c.style.verticalAlign = "top";
				}
			}
			return row;
		}
		ss_acl.verifyFields = function( row, quiet,cell ) {
			var f = fields.getAll( row );
			// fill the ip and mac when chose the name
			if ( $(cell).attr("id") == "_ss_acl_pannel_1" ) {
				if (f[0].value){
					f[1].value = option_arp_list[f[0].selectedIndex][2];
					f[2].value = option_arp_list[f[0].selectedIndex][3];
				}
			}
			// fill the port when chose the mode
			if ( $(cell).attr("id") == "_ss_acl_pannel_4" ) {
				if (f[3].selectedIndex == 0){
					f[4].selectedIndex = 2;
				}else if(f[3].selectedIndex == 1){
					f[4].selectedIndex = 0;
				}else if(f[3].selectedIndex == 2){
					f[4].selectedIndex = 1;
				}else if(f[3].selectedIndex == 3){
					f[4].selectedIndex = 2;
				}else if(f[3].selectedIndex == 4){
					f[4].selectedIndex = 0;
				}
			}
			// user port
			if (f[4].selectedIndex == 3){
				$("#ss_acl_pannel > tbody > tr > td:nth-child(6)").show();
				$("#_ss_acl_pannel_6").show();
			}else{
				$("#ss_acl_pannel > tbody > tr > td:nth-child(6)").hide();
				$("#_ss_acl_pannel_6").hide();
			}
			// 当负载均衡开启，并且选择了负载均衡节点，禁用游戏模式和，隐藏kcp加速面板
			var s1 = E('_ss_lb_enable').checked;
			var s2 = E('_ss_basic_node').value == "0";
			if(s1 && s2){
				$("#_ss_acl_pannel_4 option[value=3]").hide();
			}else{
				$("#_ss_acl_pannel_4 option[value=3]").show();
			}
			//check if ip and mac column correct
			if (f[1].value && !f[2].value){
				return v_ip( f[1], quiet );
			}
			if (!f[1].value && f[2].value){
				return v_mac( f[2], quiet );
			}
			if (f[1].value && f[2].value){
				return v_ip( f[1], quiet ) || v_mac( f[2], quiet );
			}
		}

		ss_acl.setup = function() {
			this.init( 'ss_acl_pannel', '', 254, [
			{ type: 'select',maxlen:20,options:option_arp_list},
			{ type: 'text',maxlen:20},
			{ type: 'text',maxlen:20},
			{ type: 'select',maxlen:20,options:option_acl_mode},
			{ type: 'select',maxlen:20,options:option_acl_port},
			{ type: 'text',maxlen:20}
			] );
			this.headerSet( [ '主机别名', '主机IP地址', 'MAC地址', '访问控制' , '目标端口', '自定义端口' ] );
			if(dbus["ss_acl_node_max"]){
				for ( var i = 1; i <= dbus["ss_acl_node_max"]; i++){
					var t = [dbus["ss_acl_name_" + i ], 
							dbus["ss_acl_ip_" + i ]  || "",
							dbus["ss_acl_mac_" + i ]  || "",
							dbus["ss_acl_mode_" + i ],
							dbus["ss_acl_port_" + i ],
							dbus["ss_acl_port_user_" + i ]||""
							]
					if ( t.length == 6 ) this.insertData( -1, t );
				}
				$('#ss_acl_default_pannel > fieldset:nth-child(3) > div > span').html('除了设置的访问控制主机，其它剩余主机都将走此处设定的模式和端口。');
				$("#ss_acl_default_pannel > fieldset:nth-child(1) > label").html('默认模式 (其余主机)');
				$("#ss_acl_default_pannel > fieldset:nth-child(2) > label").html('目标端口 (其余主机)');
			}else{
				$('#ss_acl_default_pannel > fieldset:nth-child(3) > div > span').html('当前未设置访问控制主机，所有路由器下的主机都将走此处设定的模式和端口。');
				$("#ss_acl_default_pannel > fieldset:nth-child(1) > label").html('默认模式 (全部主机)');
				$("#ss_acl_default_pannel > fieldset:nth-child(2) > label").html('目标端口 (全部主机)');
			}
			
			this.recolor();
			this.showNewEditor();
			this.resetNewEditor();
			$("#_ss_acl_pannel_6").hide();
			$("#ss_acl_pannel > tbody > tr > td:nth-child(6)").hide();
			// 当负载均衡开启，并且选择了负载均衡节点，禁用游戏模式和，隐藏kcp加速面板
			var s1 = E('_ss_lb_enable').checked;
			var s2 = E('_ss_basic_node').value == "0";
			if(s1 && s2){
				$("#_ss_acl_pannel_4 option[value=3]").hide();
			}else{
				$("#_ss_acl_pannel_4 option[value=3]").show();
			}
		}
		ss_acl.disableNewEditor = function(disable) {
			if (this.getDataCount() >= this.maxAdd) disable = true;
			if (this.newEditor) fields.disableAll(this.newEditor, disable);
			if (this.newControls) fields.disableAll(this.newControls, disable);
			$("#ss_acl_pannel > tbody > tr > td:nth-child(6)").hide();
		}
		ss_acl.onClick = function(cell) {
			if (this.canEdit) {
				this.edit(cell);
			}
		}
		ss_acl.edit = function(cell) {
			var sr, er, e, c;
			if (this.isEditing()) return;
			sr = PR(cell);
			sr.style.display = 'none';
			elem.removeClass(sr, 'hover');
			this.source = sr;
			er = this.createEditor('edit', sr.rowIndex, sr);
			er.className = 'editor';
			this.editor = er;
			c = er.cells[cell.cellIndex || 0];
			e = c.getElementsByTagName('input');
			if ((e) && (e.length > 0)) {
				try { // IE quirk
					e[0].focus();
				} catch (ex) {}
			}
			this.controls = this.createControls('edit', sr.rowIndex);
			this.disableNewEditor(true);
			this.rpHide();
			this.verifyFields(this.editor, true);
		}
		// ===========================================
		var online_link = new TomatoGrid();
		online_link.dataToView = function(data) {
			return [ data[0]];
		}
		online_link.createEditor = function(which, rowIndex, source) {
			var values;
			if (which == 'edit') values = this.dataToFieldValues(source.getRowData());
			var row = this.tb.insertRow(rowIndex);
			row.className = 'editor';
			var common = ' onkeypress="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var vi = 0;
			for (var i = 0; i < this.editorFields.length; ++i) {
				var s = '';
				var ef = this.editorFields[i].multi;
				if (!ef) ef = [this.editorFields[i]];
				for (var j = 0; j < ef.length; ++j) {
					var f = ef[j];
					if (f.prefix) s += f.prefix;
					var attrib = ' class="fi' + (vi + 1) + ' ' + (f['class'] ? f['class'] : '') + '" ' + (f.attrib || '');
					var id = (this.tb ? ('_' + this.tb.id + '_' + (vi + 1)) : null);
					if (id) attrib += ' id="' + id + '"';
					switch (f.type) {
						case 'password':
							if (f.peekaboo) {
								switch (get_config('web_pb', '1')) {
									case '0':
										f.type = 'text';
									case '2':
										f.peekaboo = 0;
										break;
								}
							}
							attrib += ' autocomplete="off"';
							if (f.peekaboo && id) attrib += ' onfocus=\'peekaboo("' + id + '",1)\'';
							// drop
						case 'text':
							s += '<input style="max-width:89%" type="' + f.type + '" maxlength=' + f.maxlen + common + attrib;
							if (which == 'edit') s += ' value="' + escapeHTML('' + values[vi]) + '">';
							else s += '>';
							break;
						case 'select':
							s += '<select' + common + attrib + '>';
							for (var k = 0; k < f.options.length; ++k) {
								a = f.options[k];
								if (which == 'edit') {
									s += '<option value="' + a[0] + '"' + ((a[0] == values[vi]) ? ' selected>' : '>') + a[1] + '</option>';
								} else {
									s += '<option value="' + a[0] + '">' + a[1] + '</option>';
								}
							}
							s += '</select>';
							break;
						case 'checkbox':
							s += '<div class="checkbox c-checkbox"><label><input type="checkbox"' + common + attrib;
							if ((which == 'edit') && (values[vi])) s += ' checked';
							s += '><span></span> </label></div>';
							break;
						case 'textarea':
							if (which == 'edit') {
								document.getElementById(f.proxy).value = values[vi];
							}
							break;
						default:
							s += f.custom.replace(/\$which\$/g, which);
					}
					if (f.suffix) s += f.suffix;
					++vi;
				}
				var c = row.insertCell(i);
				c.innerHTML = s;
				// Added verticalAlignment, this fixes the incorrect vertical positioning of inputs in the editorRow
				if (this.editorFields[i].vtop) {
					c.vAlign = 'top';
					c.style.verticalAlign = "top";
				}
			}
			return row;
		}
		online_link.verifyFields = function( row, quiet ) {
			var f = fields.getAll( row );
			var f = fields.getAll( row );
			if(!f[0].value){
				alert("不能为空！");
				return false;
			}else{
				if(f[0].value.indexOf("http://") != -1 || f[0].value.indexOf("https://") != -1){
					return true;
				}else{
					alert("格式错误！请添加 http:// 或者 https:// 开头的订阅链接！");
					return false;
				}
			}
		}
		online_link.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value   = '';
		}
		online_link.createControls = function(which, rowIndex) {
			var r, c;
			r = this.tb.insertRow(rowIndex);
			r.className = 'controls';
			c = r.insertCell(0);
			c.colSpan = this.header.cells.length;
			if (which == 'edit') {
				c.innerHTML = '<button type="button" class="btn btn-danger" value="Delete" onclick="TGO(this).onDelete()">删除 <i class="icon-cancel"></i></button> ' + '<button type="button" class="btn" value="Cancel" onclick="TGO(this).onCancel()">取消 <i class="icon-disable"></i></button> ' + '<button type="button" class="btn btn-primary" value="OK" onclick="TGO(this).onOK()">确定 <i class="icon-check"></i></button>';
			} else {
				c.innerHTML = '<button type="button" class="btn btn-danger" value="Add" onclick="TGO(this).onAdd()">添加 <i class="icon-plus"></i></button>';
			}
			return r;
		}
		online_link.setup = function() {
			this.init( 'online_link-grid', '', 10, [
				{ type: 'text', maxlen: 1024 }
			] );
			this.headerSet( [ '订阅地址'] );
			for ( var i = 1; i <= 10; i++){
					var t1 = [dbus["ss_online_link_" + i ]];
					if ( t1[0] && t1.length == 1 ) this.insertData( -1, t1 );
			}
			this.showNewEditor();
			this.resetNewEditor();
			$("#online_link-grid > tbody > tr:nth-child(1)").hide();
			$("#online_link-grid > tbody > tr.controls").hide();
			$("#_online_link-grid_1").after('&nbsp;&nbsp;<button type="button" class="btn btn-danger" style="margin-top:-5px" value="Add" onclick="TGO(this).onAdd()">添加 <i class="icon-plus"></i></button>')
		}
		// ===========================================
		var ss_link = new TomatoGrid();
		ss_link.dataToView = function(data) {
			return [ data[0]];
		}
		ss_link.createEditor = function(which, rowIndex, source) {
			var values;
			if (which == 'edit') values = this.dataToFieldValues(source.getRowData());
			var row = this.tb.insertRow(rowIndex);
			row.className = 'editor';
			var common = ' onkeypress="return TGO(this).onKey(\'' + which + '\', event)" onchange="TGO(this).onChange(\'' + which + '\', this)"';
			var vi = 0;
			for (var i = 0; i < this.editorFields.length; ++i) {
				var s = '';
				var ef = this.editorFields[i].multi;
				if (!ef) ef = [this.editorFields[i]];
				for (var j = 0; j < ef.length; ++j) {
					var f = ef[j];
					if (f.prefix) s += f.prefix;
					var attrib = ' class="fi' + (vi + 1) + ' ' + (f['class'] ? f['class'] : '') + '" ' + (f.attrib || '');
					var id = (this.tb ? ('_' + this.tb.id + '_' + (vi + 1)) : null);
					if (id) attrib += ' id="' + id + '"';
					switch (f.type) {
						case 'password':
							if (f.peekaboo) {
								switch (get_config('web_pb', '1')) {
									case '0':
										f.type = 'text';
									case '2':
										f.peekaboo = 0;
										break;
								}
							}
							attrib += ' autocomplete="off"';
							if (f.peekaboo && id) attrib += ' onfocus=\'peekaboo("' + id + '",1)\'';
							// drop
						case 'text':
							s += '<input style="max-width:89%" type="' + f.type + '" maxlength=' + f.maxlen + common + attrib;
							if (which == 'edit') s += ' value="' + escapeHTML('' + values[vi]) + '">';
							else s += '>';
							break;
						case 'select':
							s += '<select' + common + attrib + '>';
							for (var k = 0; k < f.options.length; ++k) {
								a = f.options[k];
								if (which == 'edit') {
									s += '<option value="' + a[0] + '"' + ((a[0] == values[vi]) ? ' selected>' : '>') + a[1] + '</option>';
								} else {
									s += '<option value="' + a[0] + '">' + a[1] + '</option>';
								}
							}
							s += '</select>';
							break;
						case 'checkbox':
							s += '<div class="checkbox c-checkbox"><label><input type="checkbox"' + common + attrib;
							if ((which == 'edit') && (values[vi])) s += ' checked';
							s += '><span></span> </label></div>';
							break;
						case 'textarea':
							if (which == 'edit') {
								document.getElementById(f.proxy).value = values[vi];
							}
							break;
						default:
							s += f.custom.replace(/\$which\$/g, which);
					}
					if (f.suffix) s += f.suffix;
					++vi;
				}
				var c = row.insertCell(i);
				c.innerHTML = s;
				// Added verticalAlignment, this fixes the incorrect vertical positioning of inputs in the editorRow
				if (this.editorFields[i].vtop) {
					c.vAlign = 'top';
					c.style.verticalAlign = "top";
				}
			}
			return row;
		}
		ss_link.verifyFields = function( row, quiet ) {
			var f = fields.getAll( row );
			if(!f[0].value){
				alert("不能为空！");
				return false;
			}else{
				if(f[0].value.indexOf("ssr://") != -1 || f[0].value.indexOf("ss://") != -1){
					return true;
				}else{
					alert("格式错误！请添加ssr:// 或者 ss:// 开头的链接！");
					return false;
				}
			}
		}
		ss_link.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor);
			this.insertData(-1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
			E("save-add-link").disabled=false;
		}
		ss_link.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value   = '';
		}
		ss_link.createControls = function(which, rowIndex) {
			var r, c;
			r = this.tb.insertRow(rowIndex);
			r.className = 'controls';
			c = r.insertCell(0);
			c.colSpan = this.header.cells.length;
			if (which == 'edit') {
				c.innerHTML = '<button type="button" class="btn btn-danger" value="Delete" onclick="TGO(this).onDelete()">删除 <i class="icon-cancel"></i></button> ' + '<button type="button" class="btn" value="Cancel" onclick="TGO(this).onCancel()">取消 <i class="icon-disable"></i></button> ' + '<button type="button" class="btn btn-primary" value="OK" onclick="TGO(this).onOK()">确定 <i class="icon-check"></i></button>';
			} else {
				c.innerHTML = '<button type="button" class="btn btn-danger" value="Add" onclick="TGO(this).onAdd()">添加 <i class="icon-plus"></i></button>';
			}
			return r;
		}
		ss_link.setup = function() {
			this.init( 'ss_link-grid', '', 20, [
				{ type: 'text' }
			] );
			this.headerSet( [ '订阅地址'] );
			for ( var i = 1; i <= 20; i++){
				var t1 = [dbus["ss_base64_link_" + i ]];
				if ( t1[0] && t1.length == 1 ) this.insertData( -1, t1 );
			}
			this.showNewEditor();
			this.resetNewEditor();
			E("save-add-link").disabled=true;
			$("#ss_link-grid > tbody > tr:nth-child(1)").hide();
			$("#ss_link-grid > tbody > tr.controls").hide();
			$("#_ss_link-grid_1").after('&nbsp;&nbsp;<button type="button" class="btn btn-danger" style="margin-top:-5px" value="Add" onclick="TGO(this).onAdd()">添加 <i class="icon-plus"></i></button>')
		}
		//============================================
		function init_ss(){
			tabSelect('app1');
			ss_node.setup();
			ssr_node.setup();
			online_link.setup();
			ss_link.setup();
			get_wans_list();
			//get_wans_list2();
			auto_node_sel();
			verifyFields();
			hook_event();
			ping_node();
			setTimeout("get_run_status();", 1000);
		}
   		function ping_node(){
	   		$(window).scrollTop(25);
	   		E("ping_botton").disabled=true;
			if(softcenter == 1){
				return false;
			}
			if (!dbus["ssconf_basic_node_max"] && !dbus["ssrconf_basic_node_max"]){
				return false;
			}
			// refill
			var pings = document.getElementsByClassName('co4');
			for(var i = 0; i<pings.length; i++)	{
				if (pings[i].innerHTML.indexOf("\.") != -1){
					if (pings[i].parentNode.getElementsByClassName('co12').length == 1){ //ssr
						pings[i].parentNode.getElementsByClassName('co12')[0].innerHTML = "测试中..."
					}else{ //ss
						pings[i].parentNode.getElementsByClassName('co10')[0].innerHTML = "测试中..."
					}
				}
			}
			
			var dbus4 = {};
			dbus4["ss_basic_ping_method"] = E("_ss_basic_ping_method").value;
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "ss_ping.sh", "params":[], "fields": dbus4};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async:true,
				cache:false,
				data: JSON.stringify(postData),
				dataType: "json",
				success: function(response){
					var ps=eval(Base64.decode(response.result));
					for(var i = 0; i<ps.length; i++){
						var nu = parseInt(ps[i][0]) + 1;
						var type = ps[i][1];
						var ping = parseInt(ps[i][2]);
						var loss = ps[i][3];
						if (!ping){
							if(E("_ss_basic_ping_method").value == 1){
								test_result = '<font color="#990000">failed</font>';
							}else{
								test_result = '<font color="#990000">failed / ' + loss + '</font>';
							}
						}else{
							if(E("_ss_basic_ping_method").value == 1){
								$('#ss_node-grid > tbody > tr:nth-child(1) > td.header.co10').html("ping");
								$('#ssr_node-grid > tbody > tr:nth-child(1) > td.header.co12').html("ping");
								if (ping <= 50){
									test_result = '<font color="#1bbf35">' + parseFloat(ping).toPrecision(3) +'  ms</font>';
								}else if (ping > 50 && ping <= 100) {
									test_result = '<font color="#3399FF">' + parseFloat(ping).toPrecision(3) +'  ms</font>';
								}else{
									test_result = '<font color="#f36c21">' + parseFloat(ping).toPrecision(3) +'  ms</font>';
								}
							}else{
								$('#ss_node-grid > tbody > tr:nth-child(1) > td.header.co10').html("ping / 丢包");
								$('#ssr_node-grid > tbody > tr:nth-child(1) > td.header.co12').html("ping / 丢包");
								if (ping <= 50){
									test_result = '<font color="#1bbf35">' + parseFloat(ping).toPrecision(3) +'  ms / ' + loss + '</font>';
								}else if (ping > 50 && ping <= 100) {
									test_result = '<font color="#3399FF">' + parseFloat(ping).toPrecision(3) +'  ms / ' + loss + '</font>';
								}else{
									test_result = '<font color="#f36c21">' + parseFloat(ping).toPrecision(3) +'  ms / ' + loss + '</font>';
								}
							}
						}
						if (type == "ssr"){
							$('#ssr_node-grid > tbody > tr:nth-child(' + nu + ') > td.co12').html(test_result);
						}else if (type == "ss"){
							$('#ss_node-grid > tbody > tr:nth-child(' + nu + ') > td.co10').html(test_result);
						}
					}
	   				E("ping_botton").disabled=false;
				},
				error:function(){
				}
			});
		}

		function hook_event(){
			// when click log content, stop scrolling
			$("#_ss_basic_log").click(
				function() {
				x = 10000000;
				});
			$('#ss_status_pannel').on('click', function() {
				open111();
			});
		}

		function open111(){
			layer.open({
				type: 2,
				shade: .7,
				scrollbar: 0,
				title: '国内外分流信息',
				area: ['780px', '450px'],
				fixed: false, //不固定
				maxmin: true,
				shadeClose: 1,
				id: 'LAY_layuipro',
				btnAlign: 'c',
				content: ['https://ip.koolcenter.com/get-ip.html', 'no'],
			});
		}

		function join_node(){
			if (typeof(dbus["ssconf_basic_node_max"]) == "undefined" && typeof(dbus["ssrconf_basic_node_max"]) == "undefined"){
				node_ss = 1;
			}else if (typeof(dbus["ssconf_basic_node_max"]) == "undefined"){
				node_ss = 0;
			}else{
				node_ss = parseInt(dbus["ssconf_basic_node_max"]);
			}
			node_ssr = parseInt(dbus["ssrconf_basic_node_max"]) || 0;
			
			if (dbus["ss_lb_enable"] == 1){
				if (dbus["ss_lb_type"] == 1 && dbus["ss_lb_node_max"]){
					option_node_name[0] = ["0", "【SS】负载均衡"];
					option_node_addr[0] = ["0", "0"];
				}else if (dbus["ss_lb_type"] == 2 && dbus["ss_lb_node_max"]){
					option_node_name[0] = ["0", "【SSR】负载均衡"];
					option_node_addr[0] = ["0", "0"];
				}else{
					option_node_name[0] = ["0", "负载均衡(尚未定义节点)"];
					option_node_addr[0] = ["0", "0"];
				}
				
				for ( var i = 1; i <= node_ss; i++){
					option_node_name[i] = [ i, "【SS】" + dbus["ssconf_basic_name_" + i]];
					option_node_addr[i] = [ dbus["ssconf_basic_server_" + i], "【SS】" + dbus["ssconf_basic_name_" + i]];
				}
				for ( var i = node_ss + 1; i <= (node_ss + node_ssr); i++){
					option_node_name[i] = [ i, "【SSR】" + dbus["ssrconf_basic_name_" + ( i - node_ss)]];
					option_node_addr[i] = [ dbus["ssrconf_basic_server_" + ( i - node_ss)], "【SSR】" + dbus["ssrconf_basic_name_" + ( i - node_ss)]];
				}
				
			}else{
				for ( var i = 0; i < node_ss; i++){
					option_node_name[i] = [ ( i + 1), "【SS】" + dbus["ssconf_basic_name_" + ( i + 1)]];
					option_node_addr[i] = [ dbus["ssconf_basic_server_" + ( i + 1)], "【SS】" + dbus["ssconf_basic_name_" + ( i + 1)]];
				}
				for ( var i = node_ss; i < (node_ss + node_ssr); i++){
					option_node_name[i] = [ ( i + 1), "【SSR】" + dbus["ssrconf_basic_name_" + ( i + 1 - node_ss)]];
					option_node_addr[i] = [ dbus["ssrconf_basic_server_" + (i + 1 - node_ss)], "【SSR】" + dbus["ssrconf_basic_name_" + ( i + 1 - node_ss)]];
				}
			}
		}
		function get_dbus_data(){
			$.ajax({
			  	type: "GET",
			 	url: "/_api/ss",
			  	dataType: "json",
			  	async:false,
			 	success: function(data){
			 	 	dbus = data.result[0];
					$('#_ss_version').html( '<a style="margin-left:-4px" href="https://github.com/koolshare/ledesoft/blob/master/koolss/Changelog.txt" target="_blank"><font color="#0099FF">koolss for OpenWRT/LEDE  ' + (dbus["ss_version"]  || "") + '</font></a>' );
			  	}
			});
		}
		
		function get_run_status(){
			if (status_time > 999999){
				return false;
			}
			var id1 = parseInt(Math.random() * 100000000);
			var postData1 = {"id": id1, "method": "ss_status.sh", "params":[2], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				data: JSON.stringify(postData1),
				dataType: "json",
				success: function(response){
					var ss_status = response.result.split("@@");
					if(softcenter == 1){
						return false;
					}
					++status_time;
					if (response.result == '-2'){
						E("_ss_basic_status_foreign").innerHTML = "获取运行状态失败！";
						E("_ss_basic_status_china").innerHTML = "获取运行状态失败！";
						setTimeout("get_run_status();", (status_refresh_rate * 1000));
					}else{
						if(dbus["ss_basic_enable"] == "0"){
							E("_ss_basic_status_foreign").innerHTML = "国外链接 - 尚未提交，暂停获取状态！";
							E("_ss_basic_status_china").innerHTML = "国内链接 - 尚未提交，暂停获取状态！";
						}else{
							E("_ss_basic_status_foreign").innerHTML = ss_status[0];
							E("_ss_basic_status_china").innerHTML = ss_status[1];
							if (ss_status[2]){
								$("#_ss_basic_kcp_status").parent().show();
								$("#_ss_basic_kcp_status").html(ss_status[2])
								$("#ss_status_title").css("padding", "25.5px 10px");
							}else{
								$("#_ss_basic_kcp_status").parent().hide();
							}
							if (ss_status[3]){
								$("#_ss_basic_lb_status").parent().show();
								$("#_ss_basic_lb_status").html(ss_status[3])
								$("#ss_status_title").css("padding", "25.5px 10px");
							}else{
								$("#_ss_basic_lb_status").parent().hide();
							}
						}
						setTimeout("get_run_status();", (status_refresh_rate * 1000));
					}
				},
				error: function(){
					if(softcenter == 1){
						return false;
					}
					E("_ss_basic_status_foreign").innerHTML = "获取运行状态失败！";
					E("_ss_basic_status_china").innerHTML = "获取运行状态失败！";
					setTimeout("get_run_status();", (status_refresh_rate * 1000));
				}
			});
		}

		function mwan_set(){
			lb.setup();
			for ( var i = 0; i < wans.length; ++i ) {
				$("#_ss_mwan_ping_dst").append("<option value='"  + wans[i][0] + "'>" + wans[i][1] + "</option>");
				$("#_ss_mwan_china_dns_dst").append("<option value='"  + wans[i][0] + "'>" + wans[i][1] + "</option>");
				$("#_ss_mwan_vps_ip_dst").append("<option value='"  + wans[i][0] + "'>" + wans[i][1] + "</option>");
				$("#_ss_lb_dest").append("<option value='"  + wans[i][0] + "'>" + wans[i][1] + "</option>");
			}
			// fill the 3 input
			if(wans.length > 1){
				E("_ss_mwan_ping_dst").value = dbus["ss_mwan_ping_dst"] || "0";
				E("_ss_mwan_china_dns_dst").value = dbus["ss_mwan_china_dns_dst"] || "0";
				E("_ss_mwan_vps_ip_dst").value = dbus["ss_mwan_vps_ip_dst"] || "0";
				E("_ss_lb_dest").value = dbus["ss_lb_dst"] || "0";
			}else if (wans.length == 0){
				E("_ss_mwan_ping_dst").value = "0";
				E("_ss_mwan_china_dns_dst").value = "0";
				E("_ss_mwan_vps_ip_dst").value = "0";
				E("_ss_lb_dest").value = "0";
			}else{
				E("_ss_mwan_ping_dst").value = wans[0][0];
				E("_ss_mwan_china_dns_dst").value = wans[0][0];
				E("_ss_mwan_vps_ip_dst").value = wans[0][0];
				E("_ss_lb_dest").value = wans[0][0];
			}
			for ( var i = 0; i < wans.length; ++i ) {
				wans_value[i] = wans[i][0];
			}
			// now fill the dest in lb table
			if (dbus["ss_lb_type"] == "1"){
				if(ss_lb_nodes.length > 0){
					for ( var i = 0; i < ss_lb_nodes.length; ++i ) {
						if(wans.length > 1){
							var a = wans_value.indexOf(dbus["ssconf_basic_lb_dest_" + ss_lb_nodes[i]]);
							if(a != -1){
								$("#_ssconf_basic_lb_dest_" + ss_lb_nodes[i]).val(dbus["ssconf_basic_lb_dest_" + ss_lb_nodes[i]]);
							}else{
								// the user defined iface is offline
								$("#_ssconf_basic_lb_dest_" + ss_lb_nodes[i]).val("0");
							}
						}else if (wans.length == 0){
							$("#_ssconf_basic_lb_dest_" + ss_lb_nodes[i]).val("0");
						}else{
							$("#_ssconf_basic_lb_dest_" + ss_lb_nodes[i]).val(wans[0][0]);
						}
					}
				}
			}else{
				if(ssr_lb_nodes.length > 0){
					for ( var i = 0; i < ssr_lb_nodes.length; ++i ) {
						if(wans.length > 1){
							var a = wans_value.indexOf(dbus["ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]]);
							if(a != -1){
								$("#_ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]).val(dbus["ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]]);
							}else{
								// the user defined iface is offline
								$("#_ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]).val("0");
							}
						}else if (wans.length == 0){
							$("#_ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]).val("0");
						}else{
							$("#_ssrconf_basic_lb_dest_" + ssr_lb_nodes[i]).val(wans[0][0]);
						}
					}
				}
			}
		}
		function get_wans_list(){
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "ss_getwans.sh", "params":[], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async:true,
				cache:false,
				data: JSON.stringify(postData),
				dataType: "json",
				success: function(response){
					if (response.result != "-1"){
						wans = eval(Base64.decode(response.result));
						if(wans == null) wans=[]; else wans = wans.sort();
						if(wans.length > 1){
							wans.unshift(["0","不指定"]);
						}else if (wans.length == 0){
							wans = [["0","不指定"]];
						}
						console.log("当前接口信息(主用)：", wans);
						mwan_set()
					}
				},
				error:function(){
					get_wans_list2();
				},
				timeout:10000
			});
		}
		
		function get_wans_list2(){
			XHR.get('/cgi-bin/luci/admin/status/mwan/interface_status', null,
				function(x, mArray){
					if (mArray.wans){
						for ( var i = 0; i < mArray.wans.length; i++ ){
							if(mArray.wans[i].status == "online"){
								var wans2_temp = [];
								wans2_temp[0] = mArray.wans[i].ifname
								wans2_temp[1] = mArray.wans[i].name
								wans2.push(wans2_temp);
							}
						}
						wans2 = wans2.sort();
                        if(wans2.length > 1){
                            wans2.unshift(["0","不指定"]);
                        }else if (wans2.length == 0){
                            wans2 = [["0","不指定"]];
                        }
                        console.log("当前接口信息(备用)：", wans2);
                        wans = wans2;
                        mwan_set();
					}else{
						statusDiv.innerHTML = '<strong>没有找到 MWAN 接口</strong>';
						alert("没有找到任何可用的wan接口！\n 请检查你的网络接口设置！")
					}
				}
			);
		}
		
		function get_arp_list(){
			var id5 = parseInt(Math.random() * 100000000);
			var postData1 = {"id": id5, "method": "ss_getarp.sh", "params":[], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async:true,
				cache:false,
				data: JSON.stringify(postData1),
				dataType: "json",
				success: function(response){
					if (response.result != "-1"){
						var s2 = response.result.split( '>' );
						for ( var i = 0; i < s2.length; ++i ) {
							option_arp_local[i] = [s2[ i ].split( '<' )[0], "【" + s2[ i ].split( '<' )[0] + "】", s2[ i ].split( '<' )[1], s2[ i ].split( '<' )[2]];
						}
						var node_acl = parseInt(dbus["ss_acl_node_max"]) || 0;
						for ( var i = 0; i < node_acl; ++i ) {
							option_arp_web[i] = [dbus["ss_acl_name_" + (i + 1)], "【" + dbus["ss_acl_name_" + (i + 1)] + "】", dbus["ss_acl_ip_" + (i + 1)], dbus["ss_acl_mac_" + (i + 1)]];
						}			
						option_arp_list = unique_array(option_arp_local.concat( option_arp_web ));
						ss_acl.setup();
					}
				},
				error:function(){
					ss_acl.setup();
				},
				timeout:1000
			});
		}
		function unique_array(array){
			var r = [];
			for(var i = 0, l = array.length; i < l; i++) {
				for(var j = i + 1; j < l; j++)
				if (array[i][0] === array[j][0]) j = ++i;
					r.push(array[i]);
			}
			return r.sort();;
		}
		function auto_node_sel(){
			node_sel = E('_ss_basic_node').value || 1;
			if (node_sel == 0){
				// calculate lb node max and lastlb nu
				var node_line = [];
				var all_kcp_node = [];
				for (var field in dbus) {
					node_line = field.split("_");
					if (node_line[2]  == "lb" && node_line[3]  == "enable"){
						all_kcp_node.push(node_line[4]);
					}
				}
				if(all_kcp_node.length > 0){
					var last_lb_node = Math.max.apply(null, all_kcp_node);
					var ss_lb_node_max = all_kcp_node.length
				}else{
					var last_lb_node = "";
					var ss_lb_node_max = "";
				}
				//now apply value to main pannel
				if (dbus["ss_lb_enable"] == 1 && last_lb_node){
					if (dbus["ss_lb_type"] == 1){ //ss
						dbus["ss_basic_type"] = "0";
						E('_ss_basic_rss_protocal').value = ""
						E('_ss_basic_rss_protocal_para').value = ""
						E('_ss_basic_rss_obfs').value = ""
						E('_ss_basic_rss_obfs_para').value = ""
						for (var i = 0; i < ssbasic.length; i++) {
							if (typeof (dbus["ssconf_basic_" + ssbasic[i] + "_" + last_lb_node]) == "undefined"){
								E('_ss_basic_' + ssbasic[i] ).value = ""
							}else{
								E('_ss_basic_' + ssbasic[i] ).value = dbus["ssconf_basic_" + ssbasic[i] + "_" + last_lb_node] || "";
							}
						}
						elem.display(PR('_ss_basic_rss_protocal'), PR('_ss_basic_rss_protocal_para'), false);
						elem.display(PR('_ss_basic_rss_obfs'), PR('_ss_basic_rss_obfs_para'), false);
						var a = (E('_ss_basic_ss_obfs').value == '0');
						elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), !a);
						elem.display(PR('_ss_basic_mode'), true);
						E('_ss_basic_server').value = "127.0.0.1";
						E('_ss_basic_port').value = dbus["ss_lb_port"];
						E('_ss_basic_mode').value = dbus["ss_basic_mode"];
					}else if (dbus["ss_lb_type"] == 2){ //ssr					
						dbus["ss_basic_type"] = "1";
						for (var i = 0; i < ssrbasic.length; i++) {
							if (typeof (dbus["ssrconf_basic_" + ssrbasic[i] + "_" + last_lb_node]) == "undefined"){
								E('_ss_basic_' + ssrbasic[i] ).value = ""
							}else{
								E('_ss_basic_' + ssrbasic[i] ).value = dbus["ssrconf_basic_" + ssrbasic[i] + "_" + last_lb_node] || "";
							}
						}
						elem.display(PR('_ss_basic_rss_protocal'), true);
						elem.display(PR('_ss_basic_rss_protocal_para'), (E('_ss_basic_rss_protocal_para').value.length > 1));
						elem.display(PR('_ss_basic_rss_obfs'), PR('_ss_basic_rss_obfs_para'), true);
						elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), false);
						elem.display(PR('_ss_basic_mode'), true);
						E('_ss_basic_server').value = "127.0.0.1";
						E('_ss_basic_port').value = dbus["ss_lb_port"];
						E('_ss_basic_mode').value = dbus["ss_basic_mode"];
					}else{
						elem.display(PR('_ss_basic_rss_protocal'), PR('_ss_basic_rss_protocal_para'), false);
						elem.display(PR('_ss_basic_rss_obfs'), PR('_ss_basic_rss_obfs_para'), false);
						elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), false);
						elem.display(PR('_ss_basic_mode'), false);
						alert("尚未定义需要负载均衡的节点！");
						return false;
					}
				}else{
					elem.display(PR('_ss_basic_rss_protocal'), PR('_ss_basic_rss_protocal_para'), false);
					elem.display(PR('_ss_basic_rss_obfs'), PR('_ss_basic_rss_obfs_para'), false);
					elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), false);
					elem.display(PR('_ss_basic_mode'), false);
					alert("尚未定义需要负载均衡的节点！");
					return false;
				}
			}else{ //not lb
				if (dbus["ssrconf_basic_rss_protocal_" + (node_sel - node_ss)]){ // using ssr
					dbus["ss_basic_type"] = "1";
					for (var i = 0; i < ssrbasic.length; i++) {
						if (typeof (dbus["ssrconf_basic_" + ssrbasic[i] + "_" + (node_sel - node_ss)]) == "undefined"){
							E('_ss_basic_' + ssrbasic[i] ).value = ""
						}else{
							E('_ss_basic_' + ssrbasic[i] ).value = dbus["ssrconf_basic_" + ssrbasic[i] + "_" + (node_sel - node_ss)] || "";
						}
					}
					elem.display(PR('_ss_basic_rss_protocal'), true);
					elem.display(PR('_ss_basic_rss_protocal_para'), (E('_ss_basic_rss_protocal_para').value.length > 1));
					elem.display(PR('_ss_basic_rss_obfs_para'), (E('_ss_basic_rss_obfs_para').value.length > 1));
					elem.display(PR('_ss_basic_rss_obfs'), true);
					elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), false);
					elem.display(PR('_ss_basic_mode'), true);
				}else{ //using ss
					dbus["ss_basic_type"] = "0";
					E('_ss_basic_rss_protocal').value = ""
					E('_ss_basic_rss_protocal_para').value = ""
					E('_ss_basic_rss_obfs').value = ""
					E('_ss_basic_rss_obfs_para').value = ""
					for (var i = 0; i < ssbasic.length; i++) {
						if (typeof (dbus["ssconf_basic_" + ssbasic[i] + "_" + node_sel]) == "undefined"){
							E('_ss_basic_' + ssbasic[i] ).value = ""
						}else{
							E('_ss_basic_' + ssbasic[i] ).value = dbus["ssconf_basic_" + ssbasic[i] + "_" + node_sel];
						}
					}
					var s = E('_ss_basic_ss_obfs').value == 0;
					elem.display(PR('_ss_basic_rss_protocal'), PR('_ss_basic_rss_protocal_para'), false);
					elem.display(PR('_ss_basic_rss_obfs'), PR('_ss_basic_rss_obfs_para'), false);
					elem.display(PR('_ss_basic_ss_obfs'), PR('_ss_basic_ss_obfs_host'), !s);
					elem.display(PR('_ss_basic_mode'), true);
				}
			}
		}

		function verifyFields(r){
			// pannel1: when node changed, the main pannel element and other element should be changed, too.
			if ( $(r).attr("id") == "_ss_basic_node" ) {
				auto_node_sel();
			}
			// pannel1: when check/uncheck ss_switch
			var a  = E('_ss_basic_enable').checked;
			if ( $(r).attr("id") == "_ss_basic_enable" ) {
				if(a){
					elem.display('ss_status_pannel', a);
					elem.display('ss_tabs', a);
					if (!dbus["ssconf_basic_node_max"] && !dbus["ssrconf_basic_node_max"]){
						tabSelect('app2');
						//alert("还没有任何节点，请先在节点管理面板添加你的节点！");
					}else{
						tabSelect('app1');
					}
				}else{
					tabSelect('fuckapp');
				}
			}
			
			// ------------------------
			// pannel kcp: hide kcp panel when kcp not enable
			// hide load banlacing pannel when game mode enabled
			var t1 = E('_ss_kcp_enable').checked;
			var t2 = E("_ss_basic_mode").value == "3"
			// kcp开启或者游戏模式开启的时候，不显示负载均衡面板
			// 为了避免用户提前开好了负载均衡，再去切换游戏模式，再去选择负载均衡节点，同时需要把负载均衡节点给隐藏
			if(t1 || t2){
				$("#app5-tab").hide();
				$("#_ss_basic_node option[value=0]").hide()
			}else{
				$("#app5-tab").show();
				$("#_ss_basic_node option[value=0]").show()
			}
			// pannel kcp: hide kcp parameter panel when kcp not enable
			if ( $(r).attr("id") == "_ss_kcp_enable" ) {
				elem.display('ss_kcp_tab_2', t1);
			}
			// pannel lb: hide kcp pannel and game mode when lb enabled
			var s1 = E('_ss_lb_enable').checked;
			var s2 = E('_ss_basic_node').value == "0";
			// 当负载均衡开启，并且选择了负载均衡节点，禁用游戏模式和，隐藏kcp加速面板
			if(s1 && s2){
				$("#app6-tab").hide();
				$("#_ss_basic_mode option[value=3]").hide();
				$("#_ss_acl_default_mode option[value=3]").hide();
				$("#_ss_acl_pannel_4 option[value=3]").hide();
			}else{
				$("#app6-tab").show();
				$("#_ss_basic_mode option[value=3]").show();
				$("#_ss_acl_default_mode option[value=3]").show();
				$("#_ss_acl_pannel_4 option[value=3]").show();
			}

			// when change mode in acl tab, mode in pannel1 should also be changed
			if ( $(r).attr("id") == "_ss_acl_default_mode" ) {
				if (E("_ss_acl_default_mode").value != "0"){
					E("_ss_basic_mode").value = E("_ss_acl_default_mode").value;
				}
			}
			// pannel1: when change mode, the default acl mode should be also changed
			if (E("_ss_acl_default_mode").value != "0"){
				E("_ss_acl_default_mode").value = E("_ss_basic_mode").value;

			}
			// DNS
			var c  = E('_ss_dns_china').value == '12';
			var d1 = E('_ss_dns_foreign').value == '1'; // dns2socks
			var d2 = E('_ss_dns_foreign').value == '2'; // ss-tunnel
			var d3 = E('_ss_dns_foreign').value == '3'; // dnscrypt-proxy
			var d4 = E('_ss_dns_foreign').value == '4'; // pndsd
			var d5 = E('_ss_dns_foreign').value == '5'; // ChinaDNS
			var d6 = E('_ss_dns_foreign').value == '6'; // Pcap_DNSProxy
			var d7 = E('_ss_dns_foreign').value == '7'; // cdns
			var e1 = E('_ss_chinadns_method').value == '1'; // ChinaDNS origin
			var e2 = E('_ss_chinadns_method').value == '2'; // ChinaDNS ecs
			var f1 = E('_ss_pdnsd_method').value == '1'; // pndsd udp
			var f2 = E('_ss_pdnsd_method').value == '2'; // pndsd tcp
			elem.display('_ss_dns_china_user', c);
			elem.display('_ss_dns2socks_user', d1);
			elem.display('_ss_sstunnel_user', d2);
			elem.display('_ss_opendns', d3);
			elem.display('_ss_pdnsd_method', d4);
			elem.display('_ss_pdnsd_user', d4);
			elem.display('_ss_chinadns_method', d5);
			elem.display('_ss_chinadns_user', d5 && e1);
			elem.display(elem.parentElem('_ssdns_foreign_suffix', 'SPAN'), d1 || d2 || d3 || d4 || d5);
			elem.display(elem.parentElem('_ss_method_suffix', 'SPAN'), d4 || d5 && e1);
			if(d1){
				$("#_ss_dns_note").html('<a href="https://github.com/qiuzi/dns2socks" target="_blank">dns2socks</a>把DNS请求转发到socks5端口，利用SS服务器进行解析');
			}else if(d2){
				$("#_ss_dns_note").html('<a href="https://github.com/shadowsocks/shadowsocks-libev" target="_blank">ss-tunnel</a>把DNS请求通过udp转发到SS服务器进行解析');
			}else if(d4){
				if(f1){
					$("#_ss_dns_note").html('udp查询方式默认通过dns2socks转发到SS服务器进行解析');
				}else if(f2){
					$("#_ss_dns_note").html('tcp查询方式为直连到此处定义的国外DNS进行解析，请确保该DNS支持TCP解析');
				}
			}else if(d5){
				if(e1){
					$("#_ss_dns_note").html('<a href="https://github.com/shadowsocks/ChinaDNS" target="_blank">原版ChinaDNS</a>默认用dns2socks转发到SS服务器进行解析');
				}else if(e2){
					$("#_ss_dns_note").html('<a href="https://github.com/aa65535/ChinaDNS/issues/1" target="_blank">ECS版ChinaDNS</a>需要上游DNS服务器支持ECS，所以此处固定为直连谷歌DNS<br />如果你的网络到谷歌DNS丢包严重、不通或你的上级路由开了国外代理，请不要使用此方案');
				}
			}else if(d6){
				$("#_ss_dns_note").html('<a href="https://github.com/chengr28/Pcap_DNSProxy" target="_blank">Pcap_DNSProxy</a>是一个基于 WinPcap/LibPcap 用于过滤 DNS 投毒污染的工具');
			}else if(d7){
				$("#_ss_dns_note").html('<a href="https://github.com/semigodking/cdns" target="_blank">cdns</a>支持ECS，解析方式为直连国外支持ECS的DNS服务器（配置文件：/koolshare/ss/rule/cdns.json）<br />如果你的上级路由开了国外代理，请不要使用此方案');
			}else{
				$("#_ss_dns_note").html('');
			}

			// rule
			var l1  = E('_ss_basic_rule_update').value == '1';
			var l3  = E('_ss_basic_node_update').value == '1';
			elem.display('_ss_basic_rule_update_day', l1);
			elem.display('_ss_basic_rule_update_hr', l1);
			elem.display('_ss_basic_node_update_day', l3);
			elem.display('_ss_basic_node_update_hr', l3);
			elem.display(elem.parentElem('_ss_basic_gfwlist_update', 'DIV'), l1);
			elem.display('_ss_basic_gfwlist_update_txt', l1);
			elem.display(elem.parentElem('_ss_basic_chnroute_update', 'DIV'), l1);
			elem.display('_ss_basic_chnroute_update_txt', l1);
			elem.display(elem.parentElem('_ss_basic_cdn_update', 'DIV'), l1);
			elem.display('_ss_basic_cdn_update_txt', l1);
			elem.display(elem.parentElem('_ss_basic_pcap_update', 'DIV'), l1);
			elem.display('_ss_basic_pcap_update_txt', l1);

			// ss online update
			var p1 = E('_ssr_subscribe_obfspara').value == '1';
			var p2 = E('_ssr_subscribe_obfspara').value == '2';
			var q = E('_ss_acl_default_port').value == '0';
			elem.display('_ssr_subscribe_obfspara_text', p2);
			elem.display('_ssr_subscribe_obfspara_val', p2);
			elem.display('_ss_acl_default_port_user', q);
			
			calculate_max_node();
		}
		function calculate_max_node(){
			var all_names_ss = [];
			var all_names_ssr = [];
			var all_names_sslb = [];
			var all_names_ssrlb = [];
			var all_nodes_of_ss = [];
			var all_nodes_of_ssr = [];
			var all_nodes_of_sslb = [];
			var all_nodes_of_ssrlb = [];
			//--------------------------------------
			// count node in ss
			for (var field in dbus) {
				names_ss = field.split("ssconf_basic_port_");
				all_names_ss.push(names_ss)
			}
			
			for ( var i = 0; i < all_names_ss.length; i++){
				if (all_names_ss[i][0] == ""){
					all_nodes_of_ss.push(all_names_ss[i][1]);
				}
			}
			if(all_nodes_of_ss.length > 0){
				dbus["ssconf_basic_max_node"] = Math.max.apply(null, all_nodes_of_ss);
			}else{
				dbus["ssconf_basic_max_node"] = "";
			}
			dbus["ssconf_basic_node_max"] = all_nodes_of_ss.length;
			//--------------------------------------
			// count node in ssr
			for (var field in dbus) {
				names_ssr = field.split("ssrconf_basic_port_");
				all_names_ssr.push(names_ssr)
			}	
			
			for ( var i = 0; i < all_names_ssr.length; i++){
				if (all_names_ssr[i][0] == ""){
					all_nodes_of_ssr.push(all_names_ssr[i][1]);
				}
			}
			if(all_nodes_of_ssr.length > 0){
				dbus["ssrconf_basic_max_node"] = Math.max.apply(null, all_nodes_of_ssr);
			}else{
				dbus["ssrconf_basic_max_node"] = "";
			}
			dbus["ssrconf_basic_node_max"] = all_nodes_of_ssr.length;
		}
		
		function NodetabSelect(obj){
			if(obj == "ss"){
				$("#SubTabSS").addClass('active');
				$("#SubTabSSR").removeClass('active');
				$("#SubTabMange").removeClass('active');
				$("#ss_node_tab").show();
				$("#ssr_node_tab").hide();
				$("#ssr_ping_tab").hide();
				$("#ssr_node_subscribe").hide();
				$("#ss_link_add").hide();
				$("#save-node").show();
				$("#cancel-button").show();
			}else if(obj == "ssr"){
				$("#SubTabSS").removeClass('active');
				$("#SubTabSSR").addClass('active');
				$("#SubTabMange").removeClass('active');
				$("#ss_node_tab").hide();
				$("#ssr_node_tab").show();
				$("#ssr_ping_tab").hide();
				$("#ssr_node_subscribe").hide();
				$("#ss_link_add").hide();
				$("#save-node").show();
				$("#cancel-button").show();
			}else if(obj == "manage"){
				$("#SubTabSS").removeClass('active');
				$("#SubTabSSR").removeClass('active');
				$("#SubTabMange").addClass('active');
				$("#ss_node_tab").hide();
				$("#ssr_node_tab").hide();
				$("#ssr_ping_tab").show();
				$("#ssr_node_subscribe").show();
				$("#ss_link_add").show();
				$("#save-node").hide();
				$("#cancel-button").hide();
			}
		}

		function tabSelect(obj){
			var tableX = ['app1-tab', 'app2-tab', 'app3-tab', 'app4-tab', 'app5-tab', 'app6-tab','app7-tab','app8-tab','app9-tab','app10-tab','app11-tab'];
			var boxX = ['boxr1', 'boxr2', 'boxr3', 'boxr4', 'boxr5', 'boxr6', 'boxr7', 'boxr8', 'boxr9', 'boxr10', 'boxr11'];
			var appX = ['app1', 'app2', 'app3', 'app4', 'app5', 'app6', 'app7', 'app8', 'app9', 'app10', 'app11'];
			for (var i = 0; i < tableX.length; i++){
				if(obj == appX[i]){
					$('#'+tableX[i]).addClass('active');
					$('.'+boxX[i]).show();
				}else{
					$('#'+tableX[i]).removeClass('active');
					$('.'+boxX[i]).hide();
				}
			}
			// here defined pannel level element hide/show
			// show hide ss basic pannel when ss loaded
			if(obj =='app1'){ // 节点
				var b  = E('_ss_basic_enable').checked;
				elem.display('ss_status_pannel', b);
				elem.display('ss_tabs', b);
				elem.display('ss_basic_tab', b);
			}
			// show hide some button and pannel when cliec tab
			if(obj =='app2'){ // 节点
				elem.display('save-button', false);
				elem.display('cancel-button', true);
				elem.display('ss_kcp_tab_2', false);
				var cur_sel_node = parseInt(dbus["ss_basic_node"]);
				if(cur_sel_node >= node_ss){
					NodetabSelect('ssr');
				}else{
					NodetabSelect('ss');
				}
			}else if(obj=='app9' || obj=='app4'){ // 负载均衡
				elem.display('save-button', false);
				elem.display('cancel-button', false);
				elem.display('ss_kcp_tab_2', false);
			}else if(obj=='app5'){ // 负载均衡
				elem.display('save-button', false);
				elem.display('cancel-button', true);
				elem.display('ss_kcp_tab_2', false);
			}else if(obj=='app6'){ // kcp
				elem.display('save-button', false);
				elem.display('cancel-button', true);
				elem.display('ss_kcp_tab_2', false);
				var a = E('_ss_kcp_enable').checked;
				elem.display('ss_kcp_tab_2', a);
			}else if(obj=='app11'){ //日志
				elem.display('save-button', false);
				elem.display('cancel-button', false);
				elem.display('ss_kcp_tab_2', false);
				noChange=0;
				setTimeout("get_log();", 200);
			}else if(obj=='fuckapp'){
				elem.display('ss_status_pannel', false);
				elem.display('ss_tabs', false);
				elem.display('ss_basic_tab', false);
				elem.display('ss_node_tab', false);
				elem.display('ssr_node_tab', false);
				elem.display('ss_dns_tab', false);
				elem.display('ss_wblist_tab', false);
				elem.display('ss_rule_tab', false);
				elem.display('ss_acl_tab', false);
				elem.display('ss_acl_tab_readme', false);
				elem.display('ss_addon_tab', false);
				elem.display('ss_log_tab', false);
				elem.display('ss_lb_tab', false);
				elem.display('lb_list', false);
				elem.display('ss_lb_tab_readme', false);
				elem.display('ss_kcp_tab_readme', false);
				elem.display('ss_kcp_tab_1', false);
				elem.display('ss_kcp_tab_2', false);
				elem.display('save-button', true);
				elem.display('save-node', false);
				elem.display('save-lb', false);
				elem.display('save-kcp', false);
			}else{
				elem.display('save-button', true);
				elem.display('ss_kcp_tab_2', false);
				elem.display('cancel-button', true);
				noChange=2001;
			}
		}
		function showMsg(Outtype, title, msg){
			$('#'+Outtype).html('<h5>'+title+'</h5>'+msg+'<a class="close"><i class="icon-cancel"></i></a>');
			$('#'+Outtype).show();
		}
		function delete_online_node(){
			// ss: collect node data from ss pannel
			if (!confirm("确定要删除这些订阅?")) { return false; }
			$.ajax({
				type: "GET",
				url: "/_api/ssrconf",
				dataType: "json",
				async:true,
				success: function(data){
					tabSelect('app11');
					var skipd_ssr = data.result[0];
					var all_ssrconf = ["ssrconf_basic_mode_", "ssrconf_basic_name_", "ssrconf_basic_server_", "ssrconf_basic_port_", "ssrconf_basic_password_", "ssrconf_basic_method_", "ssrconf_basic_rss_protocal_", "ssrconf_basic_rss_protocal_para_", "ssrconf_basic_rss_obfs_", "ssrconf_basic_rss_obfs_para_", "ssrconf_basic_server_ip_", "ssrconf_basic_lb_enable_", "ssrconf_basic_lb_policy_", "ssrconf_basic_lb_weight_", "ssrconf_basic_lb_dest_", "ssrconf_basic_group_"];
					//== get current using ss/ssr node number==
					var cur_sel_node = parseInt(dbus["ss_basic_node"]);
					var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
					if (cur_sel_node <= node_ss){
						var ss_orig_nu = cur_sel_node
					}else{
						var ssr_orig_nu = cur_sel_node - node_ss
					}
					// flush all element
					var skipd_temp_ssr = jQuery.extend({}, skipd_ssr);
					for (var field in skipd_temp_ssr) {
						skipd_temp_ssr[field] = "";
					}
					// start
					var data = ssr_node.getAllData();
					if(data.length > 0){
						var j = 0
						for ( var i = 0; i < data.length; ++i ) {
							// write node
							var data_nu = data[i][0];
							// 所有不带group信息的 + 正在使用的 + 不需要删除的 保留
							if(!skipd_ssr["ssrconf_basic_group_" + data_nu] || ssr_orig_nu && ssr_orig_nu == data_nu || E('_ss_basic_online_node_del').value != "0" && skipd_ssr["ssrconf_basic_group_" + data_nu] != E('_ss_basic_online_node_del').value){
								console.log(data_nu);
								++j
								// write ss/kcp node
								if (parseInt(data_nu) == ssr_orig_nu){
									skipd_temp_ssr["ss_basic_node"] = j + node_ss;
								}
								if (parseInt(data_nu) == cur_kcp_node){
									skipd_temp_ssr["ss_kcp_node"] = j + node_ss;
								}
								// now write node data with no group info
								for ( var k = 0; k < all_ssrconf.length; ++k ) {
									var temp_val = skipd_ssr[all_ssrconf[k] + data_nu];
									if (temp_val){
										skipd_temp_ssr[all_ssrconf[k] + j] = temp_val;
									}
								}
								// alert when deleting node is under use
								// 删除全部订阅节点的时候，当删除的节点是正在使用的节点，需要提醒一下
								if (ssr_orig_nu == data_nu && E('_ss_basic_online_node_del').value == "0"){
									alert("正在使用的订阅节点不会删除,但其它的订阅节点会删除！");
								// 另外，如果删除的节点不是全部订阅节点，而是用户指定要删除的节点的时候，同样需要提醒
								}else if(ssr_orig_nu == data_nu && E('_ss_basic_online_node_del').value != "0" && skipd_ssr["ssrconf_basic_group_" + data_nu] == E('_ss_basic_online_node_del').value){
									alert("正在使用的订阅节点不会删除,但其它的订阅节点会删除！");
								}
							}
						}
						skipd_temp_ssr["ssrconf_basic_node_max"] = String(j);
						skipd_temp_ssr["ssrconf_basic_max_node"] = String(j);
					}else{
						skipd_temp_ssr["ssrconf_basic_node_max"] = "";
						skipd_temp_ssr["ssrconf_basic_max_node"] = "";
					}
					// 需要先把所有的(ss_online_link_1 - 10)和 (ss_online_group_1 - 10)全部转移到临时对象，且清空，以便数量变少，dbus可以删除对应数据
					// 所以当删除所有订阅节点的时候(E('_ss_basic_online_node_del').value != "0"),就只需要判断不删除所有订阅节点的情况了，因为这里已经清空一次
					var o = 1;
					for ( var n = 1; n <= 10; ++n ) {
						if(dbus["ss_online_group_" + n]){
							console.log("999")
							skipd_temp_ssr["ss_online_group_" + o] = "";
							skipd_temp_ssr["ss_online_link_" + o] = "";
							++o;
						}
					}
					console.log(skipd_temp_ssr);
					// 神保佑我下次不会改到这里
					var m = 1;
					for ( var l = 1; l <= 10; ++l ) {
						// 因为判断太多，所以分开写成两条 if 和 else if
						// dbus["ss_online_group_" + l] :首先，在dbus数据中，储存订阅链接(ss_online_link_1 - 10)的对应的group信息的值 (ss_online_group_1 - 10)里 dbus["ss_online_group_" + l]不为空的时候
						// E('_ss_basic_online_node_del').value != "0" :且要删除的节点不是全部订阅节点
						// dbus["ss_online_group_" + l] != E('_ss_basic_online_node_del').value :且这个dbus["ss_online_group_" + l]值不等于要删除的节点的时候，进行一次储存，储存到另外一个对象（skipd_temp_ssr）中
						if(dbus["ss_online_group_" + l] && E('_ss_basic_online_node_del').value && dbus["ss_online_group_" + l] != E('_ss_basic_online_node_del').value ){
							skipd_temp_ssr["ss_online_group_" + m] = dbus["ss_online_group_" + l];
							skipd_temp_ssr["ss_online_link_" + m] = dbus["ss_online_link_" + l];
							++m;
						// 但是这特么还不够，因为如果要删除的订阅节点是用户正在使用的节点是订阅节点的时候，这个时候对应的ss_online_group_和ss_online_link_不能删除
						// 所以，同样dbus["ss_online_group_" + l] 和 E('_ss_basic_online_node_del').value 都是true的情况下
						// 同时如果这个正在使用的ssr节点的group值不为空，且这个值还特么等于我要删除的订阅group信息，这个时候当然是不删除了
						// 直接把原来dbus里的值给搞过来，写到临时的对象里
						// 因为还有else的情况不需要定义，所以++m在前两个里进行
						// 我特么都不知道我下次是不是还能看得懂
						}else if(dbus["ss_online_group_" + l] && E('_ss_basic_online_node_del').value && skipd_ssr["ssrconf_basic_group_" + ssr_orig_nu] && skipd_ssr["ssrconf_basic_group_" + ssr_orig_nu] == E('_ss_basic_online_node_del').value){
							skipd_temp_ssr["ss_online_group_" + m] = dbus["ss_online_group_" + l];
							skipd_temp_ssr["ss_online_link_" + m] = dbus["ss_online_link_" + l];
							++m;
						}
					}
					
					console.log(skipd_temp_ssr);
					//==now post data==
					var id = parseInt(Math.random() * 100000000);
					var postData = {"id": id, "method": "ss_conf.sh", "params":["7"], "fields": skipd_temp_ssr };
					$.ajax({
						type: "POST",
						url: "/_api/",
						async: true,
						cache:false,
						data: JSON.stringify(postData),
						dataType: "json",
						success: function(response){
							if (response.result == id){
								setTimeout("window.location.reload()", 100);
							}else{
								showMsg("msg_error","删除失败","<b>删除节点数据失败！错误代码：" + response.result + "</b>");
								return false;
							}
						}
					});
				}
			});
		}
		
		function save_node(){
			status_time = 999999990;
			// ss: collect node data from ss pannel
			$.ajax({
				type: "GET",
				url: "/_api/ssconf,ssrconf",
				dataType: "json",
				async:true,
				success: function(datas){
					var all_ssconf_table = ["ssconf_basic_mode_", "ssconf_basic_name_", "ssconf_basic_server_", "ssconf_basic_port_", "ssconf_basic_password_", "ssconf_basic_method_", "ssconf_basic_ss_obfs_", "ssconf_basic_ss_obfs_host_" ];
					var all_ssconf_dbus = ["ssconf_basic_server_ip_", "ssconf_basic_lb_enable_", "ssconf_basic_lb_policy_", "ssconf_basic_lb_weight_", "ssconf_basic_lb_dest_" ];
					var all_ssrconf_table = ["ssrconf_basic_mode_", "ssrconf_basic_name_", "ssrconf_basic_server_", "ssrconf_basic_port_", "ssrconf_basic_password_", "ssrconf_basic_method_", "ssrconf_basic_rss_protocal_", "ssrconf_basic_rss_protocal_para_", "ssrconf_basic_rss_obfs_", "ssrconf_basic_rss_obfs_para_"];
					var all_ssrconf_dbus = ["ssrconf_basic_server_ip_", "ssrconf_basic_lb_enable_", "ssrconf_basic_lb_policy_", "ssrconf_basic_lb_weight_", "ssrconf_basic_lb_dest_", "ssrconf_basic_group_"];
					var skipd_ss = datas.result[0];
					var skipd_ssr = datas.result[1];
					//== get current using ss/ssr node number==
					var cur_sel_node = parseInt(dbus["ss_basic_node"]);
					var cur_kcp_node = parseInt(dbus["ss_kcp_node"]);
					if (cur_sel_node <= node_ss){
						var ss_orig_nu = cur_sel_node
					}else{
						var ssr_orig_nu = cur_sel_node - node_ss
					}
					//==ss: write all keeped node to tmp object==
					// flush all element
					var skipd_temp_ss = jQuery.extend({}, skipd_ss);
					for (var field in skipd_temp_ss) {
						skipd_temp_ss[field] = "";
					}
					// write element
					var data = ss_node.getAllData();
					if(data.length > 0){
						var j = 0
						for ( var i = 0; i < data.length; ++i ) {
							var keep_nu = data[i][0];
							++j;
							// write ss/kcp node
							if (parseInt(keep_nu) == ss_orig_nu){
								skipd_temp_ss["ss_basic_node"] = String(j);
							}
							if (parseInt(keep_nu) == cur_kcp_node){
								skipd_temp_ss["ss_kcp_node"] = String(j);
							}
							// write node
							for ( var k = 0; k < all_ssconf_table.length; ++k ) {
								var temp_val = data[i][k + 1];
								if (temp_val){
									skipd_temp_ss[all_ssconf_table[k] + j] = temp_val;
								}
							}
							for ( var o = 0; o < all_ssconf_dbus.length; ++o ) {
								var temp_val = skipd_ss[all_ssconf_dbus[o] + keep_nu];
								if (temp_val){
									skipd_temp_ss[all_ssconf_dbus[o] + j] = temp_val;
								}
							}
						}
						skipd_temp_ss["ssconf_basic_node_max"] = String(data.length);
						skipd_temp_ss["ssconf_basic_max_node"] = String(j);
					}else{
						skipd_temp_ss["ssconf_basic_node_max"] = "";
						skipd_temp_ss["ssconf_basic_max_node"] = "";
					}

					//==ssr: write all keeped node to tmp object==
					// flush all element in temp object
					var skipd_temp_ssr = jQuery.extend({}, skipd_ssr);
					
					for (var field in skipd_temp_ssr) {
						skipd_temp_ssr[field] = "";
					}
					// write element
					var data = ssr_node.getAllData();
					if(data.length > 0){
						var j = 0
						for ( var i = 0; i < data.length; ++i ) {
							var keep_nu = data[i][0];
							++j;
							// write ssr/kcp node
							if (parseInt(keep_nu) == ssr_orig_nu){
								skipd_temp_ssr["ss_basic_node"] = String(j + node_ss);
							}
							if (parseInt(keep_nu) == cur_kcp_node){
								skipd_temp_ssr["ss_kcp_node"] = String(j + node_ss);
							}
							for ( var k = 0; k < all_ssrconf_table.length; ++k ) {
								var temp_val = data[i][k + 1];
								if (temp_val){
									skipd_temp_ssr[all_ssrconf_table[k] + j] = temp_val
								}
							}
							for ( var o = 0; o < all_ssrconf_dbus.length; ++o ) {
								var temp_val = skipd_ssr[all_ssrconf_dbus[o] + keep_nu]
								if (temp_val){
									skipd_temp_ssr[all_ssrconf_dbus[o] + j] = temp_val
								}
							}
						}
						skipd_temp_ssr["ssrconf_basic_node_max"] = String(data.length);
						skipd_temp_ssr["ssrconf_basic_max_node"] = String(j);
					}else{
						skipd_temp_ssr["ssrconf_basic_node_max"] = "";
						skipd_temp_ssr["ssrconf_basic_max_node"] = "";
					}
					//==now post data==
					var skipd_temp = $.extend({}, skipd_temp_ss, skipd_temp_ssr);
					
					var id = parseInt(Math.random() * 100000000);
					var postData = {"id": id, "method": "ss_conf.sh", "params":[9], "fields": skipd_temp};
					showMsg("msg_warring","保存节点信息！","<b>等待后台运行完毕，请不要刷新本页面！</b>");
					$.ajax({
						url: "/_api/",
						type: "POST",
						async:true,
						cache:false,
						dataType: "json",
						data: JSON.stringify(postData),
						success: function(response){
							if (response.result == id){
								$('#msg_warring').hide();
								showMsg("msg_success","保存成功","<b>请稍候，页面将自动刷新...</b>");
								setTimeout("window.location.reload()", 100);
								//x = 4;
								//count_down_switch();
							}else{
								$('#msg_warring').hide();
								showMsg("msg_error","提交失败","<b>提交节点数据失败！错误代码：" + response.result + "</b>");
								return false;
							}
						},
						error: function(){
							showMsg("msg_error","失败","<b>当前系统存在异常查看系统日志！</b>");
						}
					});
				}
			});
		}
		
		function save(){
			status_time = 999999990;
			setTimeout("tabSelect('app11')", 500);
			E("_ss_basic_status_foreign").innerHTML = "国外链接 - 提交中...暂停获取状态！";
			E("_ss_basic_status_china").innerHTML = "国内链接 - 提交中...暂停获取状态！";
			E("_ss_basic_kcp_status").innerHTML = "KCP状态 - 提交中...暂停获取状态！";
			E("_ss_basic_lb_status").innerHTML = "负载均衡 - 提交中...暂停获取状态！";
			var paras_chk = ["enable", "gfwlist_update", "chnroute_update", "cdn_update", "pcap_update", "chromecast", "online_links_goss"];
			var paras_inp = ["ss_basic_node", "ss_basic_mode", "ss_basic_server", "ss_basic_port", "ss_basic_password", "ss_basic_method", "ss_basic_mptcp", "ss_basic_ss_obfs", "ss_basic_ss_obfs_host", "ss_basic_rss_protocal", "ss_basic_rss_protocal_para", "ss_basic_rss_obfs", "ss_basic_rss_obfs_para", "ss_dns_china", "ss_dns_china_user", "ss_dns_foreign", "ss_dns2socks_user", "ss_sstunnel_user", "ss_opendns", "ss_pdnsd_method", "ss_pdnsd_user", "ss_chinadns_method", "ss_chinadns_user", "ss_basic_rule_update", "ss_basic_rule_update_day", "ss_basic_rule_update_hr", "ss_basic_refreshrate", "ss_basic_bypass", "ss_acl_default_mode", "ss_acl_default_port", "ssr_subscribe_mode", "ssr_subscribe_obfspara", "ssr_subscribe_obfspara_val", "ss_mwan_ping_dst", "ss_mwan_china_dns_dst", "ss_mwan_vps_ip_dst", "ss_basic_node_update", "ss_basic_node_update_day", "ss_basic_node_update_hr"];
			// collect data from checkbox
			for (var i = 0; i < paras_chk.length; i++) {
				dbus["ss_basic_" + paras_chk[i]] = E('_ss_basic_' + paras_chk[i] ).checked ? '1':'0';
			}
			// data from other element
			for (var i = 0; i < paras_inp.length; i++) {
				if (typeof(E('_' + paras_inp[i] ).value) == "undefined"){
					dbus[paras_inp[i]] = "";
				}else{
					dbus[paras_inp[i]] = E('_' + paras_inp[i]).value;
				}
			}
			// data need base64 encode
			var paras_base64 = ["ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_isp_website_web", "ss_dnsmasq",];
			for (var i = 0; i < paras_base64.length; i++) {
				if (typeof(E('_' + paras_base64[i] ).value) == "undefined"){
					dbus[paras_base64[i]] = "";
				}else{
					dbus[paras_base64[i]] = Base64.encode(E('_' + paras_base64[i]).value);
				}
			}
			// collect node data under using from the main pannel incase of data change
			node_sel = E('_ss_basic_node').value || 1;
			if (node_sel != 0){
				if (dbus["ssrconf_basic_rss_protocal_" + (node_sel - node_ss)]){ // using ssr
					for ( var i = 0; i < ssrbasic.length; i++){
						if (typeof (E('_ss_basic_' + ssrbasic[i] ).value) == "undefined"){
							dbus["ssrconf_basic_" + ssrbasic[i] + "_" + (node_sel - node_ss) ] = ""
						}else{
							dbus["ssrconf_basic_" + ssrbasic[i] + "_" + (node_sel - node_ss) ] = E('_ss_basic_' + ssrbasic[i] ).value;
						}
					}
				}else{ //ss
					for ( var i = 0; i < ssbasic.length; i++){
						if (typeof (E('_ss_basic_' + ssbasic[i] ).value) == "undefined"){
							dbus["ssconf_basic_" + ssbasic[i] + "_" + node_sel ] = ""
						}else{
							dbus["ssconf_basic_" + ssbasic[i] + "_" + node_sel ] = E('_ss_basic_' + ssbasic[i] ).value;
						}
					}
					// define ss node max when no node
					if (typeof(dbus["ssconf_basic_node_max"]) == "undefined" && typeof(dbus["ssrconf_basic_node_max"]) == "undefined"){
						dbus["ssconf_basic_node_max"] = "1"
						dbus["ssconf_basic_name_1"] = "节点1"
					}
				}
			}
			// collect acl data from acl pannel
			var ss_acl_conf = ["ss_acl_name_", "ss_acl_ip_", "ss_acl_mac_", "ss_acl_mode_", "ss_acl_port_", "ss_acl_port_user_" ];
			// mark all acl data for delete first
			for ( var i = 1; i <= dbus["ss_acl_node_max"]; i++){
				for ( var j = 0; j < ss_acl_conf.length; ++j ) {
					dbus[ss_acl_conf[j] + i ] = ""
				}
			}
			var data4 = ss_acl.getAllData();
			if(data4.length > 0){
				for ( var i = 0; i < data4.length; ++i ) {
					for ( var j = 1; j < ss_acl_conf.length; ++j ) {
						//dbus[ss_acl_conf[0] + (i + 1)] = data4[i][0] || "未命名主机 - " + (i + 1);
						dbus[ss_acl_conf[0] + (i + 1)] = data4[i][0];
						dbus[ss_acl_conf[j] + (i + 1)] = data4[i][j];
					}
				}
				dbus["ss_acl_node_max"] = data4.length;
			}else{
				dbus["ss_acl_node_max"] = "";
			}
			// now post data
			var id3 = parseInt(Math.random() * 100000000);
			var postData3 = {"id": id3, "method": "ss_config.sh", "params":[1], "fields": dbus};
			showMsg("msg_warring","正在提交数据！","<b>等待后台运行完毕，请不要刷新本页面！</b>");
			$.ajax({
				url: "/_api/",
				type: "POST",
				async:true,
				cache:false,
				dataType: "json",
				data: JSON.stringify(postData3),
				success: function(response){
					if (response.result == id3){
						if(E('_ss_basic_enable').checked){
							// show script running status
							showMsg("msg_success","提交成功","<b>成功提交数据</b>");
							$('#msg_warring').hide();
							setTimeout("$('#msg_success').hide()", 500);
							x = 4;
							count_down_switch();
						}else{
							// when shut down ss finished, close the log tab
							$('#msg_warring').hide();
							showMsg("msg_success","提交成功","<b>koolss成功关闭！</b>");
							setTimeout("$('#msg_success').hide()", 4000);
							setTimeout("tabSelect('fuckapp')", 4000);
						}
					}else{
						$('#msg_warring').hide();
						showMsg("msg_error","提交失败","<b>提交数据失败！错误代码：" + response.result + "</b>");
					}
				},
				error: function(){
					showMsg("msg_error","失败","<b>当前系统存在异常查看系统日志！</b>");
					status_time = 1;
				}
			});
		}

		function save_lb(){
			status_time = 999999990;
			setTimeout("tabSelect('app11')", 500);
			var lb_chk = ["ss_lb_enable", "ss_lb_heartbeat"];
			var lb_inp = ["ss_lb_account", "ss_lb_password", "ss_lb_port", "ss_lb_up", "ss_lb_down", "ss_lb_interval" ];
			// collect data from checkbox
			for (var i = 0; i < lb_chk.length; i++) {
				dbus[lb_chk[i]] = E('_' + lb_chk[i] ).checked ? '1':'0';
			}
			// data from other element
			for (var i = 0; i < lb_inp.length; i++) {
				if (typeof(E('_' + lb_inp[i] ).value) == "undefined"){
					dbus[lb_inp[i]] = "";
				}else{
					dbus[lb_inp[i]] = E('_' + lb_inp[i]).value;
				}
			}
			// mark all lb value in node date for delete first
			for ( var i = 1; i <= dbus["ssconf_basic_max_node"]; i++){
				dbus["ssconf_basic_lb_enable_" + i ] = ""
				dbus["ssconf_basic_lb_policy_" + i ] = ""
				dbus["ssconf_basic_lb_weight_" + i ] = ""
				dbus["ssconf_basic_lb_dest_" + i ] = ""
			}
			for ( var i = 1; i <= dbus["ssrconf_basic_max_node"]; i++){
				dbus["ssrconf_basic_lb_enable_" + i ] = ""
				dbus["ssrconf_basic_lb_policy_" + i ] = ""
				dbus["ssrconf_basic_lb_weight_" + i ] = ""
				dbus["ssrconf_basic_lb_dest_" + i ] = ""
			}
			// now store lb value in node data
			if (dbus["ss_lb_type"] == "1"){
				var data = lb.getAllData();
				if(data.length > 0){
					for ( var i = 0; i < data.length; ++i ) {
						dbus["ssconf_basic_lb_enable_" + data[i][1] ] = 1;
						dbus["ssconf_basic_lb_policy_" + data[i][1] ] = data[i][7];
						dbus["ssconf_basic_lb_weight_" + data[i][1] ] = data[i][6];
						//dbus["ssconf_basic_lb_dest_" + data[i][1] ] = data[i][5];
						id = $(data[i][5]).attr("id");
						name = $(data[i][5]).attr("name");
						dbus[name] = $("#" + id).val();
					}
					dbus["ss_lb_node_max"] = data.length;
					dbus["ss_basic_type"] = 0;
				}else{
					dbus["ss_lb_node_max"] = "";
				}
			}else{
				var data = lb.getAllData();
				if(data.length > 0){
					for ( var i = 0; i < data.length; ++i ) {
						dbus["ssrconf_basic_lb_enable_" + data[i][1] ] = 1;
						dbus["ssrconf_basic_lb_policy_" + data[i][1] ] = data[i][7];
						dbus["ssrconf_basic_lb_weight_" + data[i][1] ] = data[i][6];
						//dbus["ssrconf_basic_lb_dest_" + data[i][1] ] = data[i][5];
						id = $(data[i][5]).attr("id");
						name = $(data[i][5]).attr("name");
						dbus[name] = $("#" + id).val();
					}
					dbus["ss_lb_node_max"] = data.length;
					dbus["ss_basic_type"] = 1;
				}else{
					dbus["ss_lb_node_max"] = "";
				}
			}
			// now post data
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "ss_config.sh", "params":[2], "fields": dbus};
			showMsg("msg_warring","保存节点信息！","<b>等待后台运行完毕，请不要刷新本页面！</b>");
			$.ajax({
				url: "/_api/",
				type: "POST",
				async:true,
				cache:false,
				dataType: "json",
				data: JSON.stringify(postData),
				success: function(response){
					if (response.result == id){
						if(E('_ss_basic_node').value == 0 && E('_ss_basic_enable').checked){
							save();
						}else{
							window.location.reload();
						}
					}else{
						$('#msg_warring').hide();
						showMsg("msg_error","提交失败","<b>提交节点数据失败！错误代码：" + response.result + "</b>");
					}
				},
				error: function(){
					showMsg("msg_error","失败","<b>当前系统存在异常查看系统日志！</b>");
				}
			});
		}
		function save_kcp(){
			if(!E('_ss_kcp_node').value){
				alert("请选择KCP服务器");
				return false;
			}
			status_time = 999999990;
			setTimeout("tabSelect('app11')", 500);
			var kcp_chk = ["ss_kcp_enable", "ss_kcp_compon"];
			var kcp_inp = ["ss_kcp_node", "ss_kcp_port", "ss_kcp_password", "ss_kcp_mode", "ss_kcp_crypt", "ss_kcp_mtu", "ss_kcp_sndwnd", "ss_kcp_rcvwnd", "ss_kcp_conn", "ss_kcp_config" ];
			// collect data from checkbox
			for (var i = 0; i < kcp_chk.length; i++) {
				dbus[kcp_chk[i]] = E('_' + kcp_chk[i] ).checked ? '1':'0';
			}
			// data from other element
			for (var i = 0; i < kcp_inp.length; i++) {
				if (!E('_' + kcp_inp[i] ).value){
					dbus[kcp_inp[i]] = "";
				}else{
					dbus[kcp_inp[i]] = E('_' + kcp_inp[i]).value;
				}
			}
			// store kcp_para
			var kcp_node_sel=E('_ss_kcp_node').value;
			if (dbus["ssrconf_basic_rss_protocal_" + (kcp_node_sel - node_ss)]){ //ssr
				dbus["ss_kcp_server"] = dbus["ssrconf_basic_server_" + (kcp_node_sel - node_ss)];
				if (dbus["ssrconf_basic_server_ip_" + (kcp_node_sel - node_ss)]){
					dbus["ss_kcp_server"] = dbus["ssrconf_basic_server_ip_" + (kcp_node_sel - node_ss)];
				}
			}else{ //ss
				dbus["ss_kcp_server"] = dbus["ssconf_basic_server_" + kcp_node_sel];
			}
			// now post data
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "ss_config.sh", "params":[2], "fields": dbus};
			showMsg("msg_warring","保存节点信息！","<b>等待后台运行完毕，请不要刷新本页面！</b>");
			$.ajax({
				url: "/_api/",
				type: "POST",
				async:true,
				cache:false,
				dataType: "json",
				data: JSON.stringify(postData),
				success: function(response){
					if (response.result == id){
						if(dbus["ss_basic_node"] == dbus["ss_kcp_node"] ){
							if(E('_ss_kcp_enable').checked){
								save();
							}else{
								window.location.reload();
							}
						}else{
							if(E('_ss_kcp_enable').checked){
								alert("成功保存了kcp设定！\n你还需要在帐号设置面板里切换到kcp加速的节点才能成功使用kcp！");
							}
							window.location.reload();
						}
					}else{
						$('#msg_warring').hide();
						showMsg("msg_error","提交失败","<b>提交kcp数据失败！错误代码：" + response.result + "</b>");
					}
				},
				error: function(){
					showMsg("msg_error","失败","<b>当前系统存在异常查看系统日志！</b>");
				}
			});
		}

		function get_log(){
			$.ajax({
				url: '/_temp/ss_log.txt',
				type: 'GET',
				dataType: 'html',
				async: true,
				cache:false,
				success: function(response) {
					var retArea = E("_ss_basic_log");
					if (response.search("XU6J03M6") != -1) {
						retArea.value = response.replace("XU6J03M6", " ");
						retArea.scrollTop = retArea.scrollHeight;
						return true;
					}
					if (_responseLen == response.length) {
						noChange++;
					} else {
						noChange = 0;
					}
					if (noChange > 8000) {
						//tabSelect("app1");
						return false;
					} else {
						setTimeout("get_log();", 100); //100 is radical but smooth!
					}
					retArea.value = response;
					retArea.scrollTop = retArea.scrollHeight;
					_responseLen = response.length;
				},
				error: function() {
					E("_ss_basic_log").value = "获取日志失败！";
				}
			});
		}
		function count_down_switch() {
			if (x == "0") {
				//tabSelect("app1");
				setTimeout("window.location.reload()", 500);
			}
			if (x < 0) {
				return false;
			}
				--x;
			setTimeout("count_down_switch();", 500);
		}
		function init_layout(){
			if(!cookie.get('ss_layout')){
				cookie.set('ss_layout', 1);
			}
			if (cookie.get('ss_layout') == '1') {
				$(".box, #ss_tabs").css("max-width", "1122px")
				$("#ss_layout_switch").attr("class", "narrow");
				$("#ss_layout_switch").html('<i class="icon-chevron-left"></i><i class="icon-chevron-right"></i>');
			}else{
				$(".box, #ss_tabs").css("max-width", "100%");
				$("#ss_layout_switch").attr("class", "wide");
				$("#ss_layout_switch").html('<i class="icon-chevron-right"></i><i class="icon-chevron-left"></i>');
			}
		}
		function switch_Width() {
			if($("#ss_layout_switch").hasClass("narrow")) {
				$("#ss_layout_switch").attr("class", "wide");
				$(".box, #ss_tabs").css("max-width", "100%");
				$("#ss_layout_switch").html('<i class="icon-chevron-right"></i><i class="icon-chevron-left"></i>');
				cookie.set('ss_layout', 0);
			} else {
				$("#ss_layout_switch").attr("class", "narrow");
				$(".box, #ss_tabs").css("max-width", "1122px");
				$("#ss_layout_switch").html('<i class="icon-chevron-left"></i><i class="icon-chevron-right"></i>');
				cookie.set('ss_layout', 1);
			}
		}
		function toggleVisibility(whichone) {
			if(E('sesdiv' + whichone).style.display=='') {
				E('sesdiv' + whichone).style.display='none';
				E('sesdiv' + whichone + 'showhide').innerHTML='<i class="icon-chevron-up"></i>';
				cookie.set('ss_' + whichone + '_vis', 0);
			} else {
				E('sesdiv' + whichone).style.display='';
				E('sesdiv' + whichone + 'showhide').innerHTML='<i class="icon-chevron-down"></i>';
				cookie.set('ss_' + whichone + '_vis', 1);
			}
		}
		function update_rules_now(arg){
			if (arg == 5){
				shellscript = 'ss_rule_update.sh';
			}
			var id6 = parseInt(Math.random() * 100000000);
			var postData = {"id": id6, "method": shellscript, "params":[], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				cache:false,
				data: JSON.stringify(postData),
				dataType: "json",
				success: function(response){
					if(response){
						setTimeout("window.location.reload()", 500);
						return true;
					}
				}
			});
			tabSelect("app11");
		}

		function manipulate_conf(script, arg){
			var dbus3 = {};
			if(arg == 1 || arg == 3 || arg == 5 || arg == 6 ){
				tabSelect("app11");
				dbus3 = [];
			}else if(arg == 2){
				tabSelect("app11");
				dbus3["ss_kcp_enable"] = "0";
				dbus3["ss_lb_enable"] = "0";
			}else if(arg == 4){
				dbus3 = [];
			}else if(arg == 'add'){
				tabSelect("app11");
				var data = ss_link.getAllData();
				if(data.length > 0){
					for ( var i = 0; i < 20; ++i ){
						if(data[i]){
							dbus3["ss_base64_link_" + (i + 1) ] = data[i][0];
						}else{
							dbus3["ss_base64_link_" + (i + 1) ] = "";
						}
					}
				}
			}else if(arg == 7 || arg == 8){
				tabSelect("app11");
				var data = online_link.getAllData();
				if(data.length > 0){
					for ( var i = 0; i < 10; ++i ){
						if(data[i]){
							dbus3["ss_online_link_" + (i + 1) ] = data[i][0];
						}else{
							dbus3["ss_online_link_" + (i + 1) ] = "";
							dbus3["ss_online_group_" + (i + 1) ] = "";
						}
					}
				}
				dbus3["ssr_subscribe_mode"] = E("_ssr_subscribe_mode").value;
				dbus3["ssr_subscribe_obfspara"] = E("_ssr_subscribe_obfspara").value;
				dbus3["ssr_subscribe_obfspara_val"] = E("_ssr_subscribe_obfspara_val").value;
				dbus3["ss_basic_node_update"] = E("_ss_basic_node_update").value;
				dbus3["ss_basic_node_update_day"] = E("_ss_basic_node_update_day").value;
				dbus3["ss_basic_node_update_hr"] = E("_ss_basic_node_update_hr").value;
				dbus3["ss_basic_online_links_goss"] = E("_ss_basic_online_links_goss").checked ? '1':'0';
				
			}else if(arg == 9){
				tabSelect("app11");
				dbus3["ss_mwan_ping_dst"] = E("_ss_mwan_ping_dst").value;
				dbus3["ss_mwan_china_dns_dst"] = E("_ss_mwan_china_dns_dst").value;
				dbus3["ss_mwan_vps_ip_dst"] = E("_ss_mwan_vps_ip_dst").value;
			}else if(arg == 10){
				dbus3["ss_basic_rule_update"] = E("_ss_basic_rule_update").value;
				dbus3["ss_basic_rule_update_day"] = E("_ss_basic_rule_update_day").value;
				dbus3["ss_basic_rule_update_hr"] = E("_ss_basic_rule_update_hr").value;
				dbus3["ss_basic_gfwlist_update"] = E("_ss_basic_gfwlist_update").checked ? '1':'0';
				dbus3["ss_basic_chnroute_update"] = E("_ss_basic_chnroute_update").checked ? '1':'0';
				dbus3["ss_basic_cdn_update"] = E("_ss_basic_cdn_update").checked ? '1':'0';
				dbus3["ss_basic_pcap_update"] = E("_ss_basic_pcap_update").checked ? '1':'0';
			}
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": script, "params":[arg], "fields": dbus3 };
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				cache:false,
				data: JSON.stringify(postData),
				dataType: "json",
				success: function(response){
					if (script == "ss_conf.sh"){
						if(arg == 1 || arg == 2 || arg == 3 || arg == 7 || arg == 8 || arg == 9 || arg == 10 || arg == 'add'){
							setTimeout("window.location.reload()", 200);
						}else if (arg == 5){
							setTimeout("window.location.reload()", 1000);
						}else if (arg == 4){
							var a = document.createElement('A');
							a.href = "/files/ss_conf_backup.sh";
							a.download = 'ss_conf_backup.sh';
							document.body.appendChild(a);
							a.click();
							document.body.removeChild(a);
						}else if (arg == 6){
							var b = document.createElement('A')
							b.href = "/files/koolss.tar.gz"
							b.download = 'koolss_' + dbus["ss_version"] + '.tar.gz'
							document.body.appendChild(b);
							b.click();
							document.body.removeChild(b);
							x=10;
							count_down_switch();
						}
					}else if(script == "ss_online_update.sh"){
						window.location.reload();
					}
				}
			});
		}
		function restore_conf(){
			var filename = $("#file").val();
			filename = filename.split('\\');
			filename = filename[filename.length-1];
			var filelast = filename.split('.');
			filelast = filelast[filelast.length-1];
			if(filelast !='sh'){
				alert('配置文件格式不正确！');
				return false;
			}
			var formData = new FormData();
			formData.append('ss_conf_backup.sh', $('#file')[0].files[0]);
			$('.popover').html('正在恢复，请稍后……');
			//changeButton(true);
			$.ajax({
				url: '/_upload',
				type: 'POST',
				async: true,
				cache:false,
				data: formData,
				processData: false,
				contentType: false,
				complete:function(res){
					if(res.status==200){
						manipulate_conf('ss_conf.sh', 5);
					}
				}
			});
		}
		
	</script>
	<div class="box" style="margin-top: 0px">
		<div class="heading">
			<span id="_ss_version"><font color="#1bbf35"></font></span>
			<a href="#soft-center.asp" class="btn" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;cursor: pointer">返回</a>
			<a id="ss_layout_switch" class="narrow" onclick="switch_Width();" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;cursor: pointer;"><i class="icon-chevron-right"></i><i class="icon-chevron-left"></i></a>
		</div>
		<div class="content">
			<div id="ss_switch_pannel" class="section">
				<fieldset>
					<label class="col-sm-3 control-left-label" for="_undefined">koolss开关</label>
						<div class="switch_field" style="display:table-cell;float: left;">
							<label for="_ss_basic_enable">
								<input type="checkbox" class="switch" name="ss_basic_enable" onclick="verifyFields(this, 1)" onchange="verifyFields(this, 1)" id="_ss_basic_enable" style="display: none;"/>
								<div class="switch_container" >
									<div class="switch_bar"></div>
									<div class="switch_circle transition_style">
										<div></div>
									</div>
								</div>
							</label>
						</div>
				</fieldset>
			</div>
			<script type="text/javascript">
				E("_ss_basic_enable").checked = dbus["ss_basic_enable"] == 1 ? true : false
			</script>
			<hr />
			<fieldset id="ss_status_pannel" style="cursor: pointer;" title="查询ip分流情况">
				<label class="col-sm-3 control-left-label" id="ss_status_title">koolss运行状态</label>
				<div class="col-sm-9">
					<font id="_ss_basic_status_foreign" name="ss_basic_status_foreign" color="#1bbf35">国外链接: waiting...</font>
				</div>
				<div class="col-sm-9" style="margin-top:2px">
					<font id="_ss_basic_status_china" name="ss_basic_status_china" color="#1bbf35">国内链接: waiting...</font>
				</div>
				<div class="col-sm-9" style="margin-top:2px;display:none;">
					<font id="_ss_basic_kcp_status" name="ss_basic_kcp_status" color="#1bbf35">KCP状态: waiting...</font>
				</div>
				<div class="col-sm-9" style="margin-top:2px;display:none;">
					<font id="_ss_basic_lb_status" name="ss_basic_lb_status" color="#1bbf35">负载均衡: waiting...</font>
				</div>
			</fieldset>
		</div>
	</div>
	<ul id="ss_tabs" class="nav nav-tabs">
		<li><a href="javascript:void(0);" onclick="tabSelect('app1');" id="app1-tab" class="active" style="width:102px"><i class="icon-system"></i> 帐号设置</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app2');" id="app2-tab" style="width:102px"><i class="icon-globe"></i> 节点管理</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app3');" id="app3-tab" style="width:102px"><i class="icon-tools"></i> DNS设定</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app4');" id="app4-tab" style="width:102px"><i class="icon-hammer" style="margin-left:-6px"></i> 多WAN设定</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app5');" id="app5-tab" style="width:102px"><i class="icon-cloud"></i> 负载均衡</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app6');" id="app6-tab" style="width:102px"><i class="icon-graphs"></i> KCP加速</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app7');" id="app7-tab" style="width:102px"><i class="icon-toggle-nav"></i> 黑白名单</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app8');" id="app8-tab" style="width:102px"><i class="icon-lock"></i> 访问控制</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app9');" id="app9-tab" style="width:102px"><i class="icon-cmd"></i> 规则管理</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app10');" id="app10-tab" style="width:102px"><i class="icon-wake"></i> 附加功能</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app11');" id="app11-tab" style="width:102px"><i class="icon-hourglass"></i> 查看日志</a></li>	
	</ul>
	<!-- ------------------ 账号设置 --------------------- -->
	<div class="box boxr1" id="ss_basic_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_basic_pannel" class="section"></div>
			<script type="text/javascript">
				join_node();
				if (!dbus["ssconf_basic_node_max"] && !dbus["ssrconf_basic_node_max"]){
					$('#ss_basic_pannel').forms([
						{ title: '节点选择', name:'ss_basic_node',type:'select',style:select_style,options:[['1', '节点1']], value: "1"}
					]);
				}else{
					if (dbus["ss_basic_double"] != 1){
						$('#ss_basic_pannel').forms([
							{ title: '节点选择', name:'ss_basic_node',type:'select',style:select_style,options:option_node_name, value: dbus.ss_basic_node || "1"}
						]);
					}else{
						$('#ss_basic_pannel').forms([
							{ title: '节点选择', multi: [
								{ title: '节点选择', name:'ss_basic_node',type:'select',style:select_style,options:option_node_name, value: dbus.ss_basic_node || "1", suffix: ' &nbsp;&nbsp;'},
								{ title: '节点选择', name:'ss_basic_node_1',type:'select',style:select_style,options:option_node_name, value: dbus.ss_basic_node || "1"}
							]},
						]);
					}
				}
				if (dbus["ss_basic_double"] != 1){
					$('#ss_basic_pannel').forms([
						{ title: '模式',  name:'ss_basic_mode',type:'select',style:select_style,options:option_mode,value: "" || "1" },
						{ title: '服务器地址', name:'ss_basic_server',type:'text',style:input_style,value:dbus.ss_basic_server,help: '尽管支持域名格式，但是仍然建议首先使用IP地址。' },
						{ title: '服务器端口', name:'ss_basic_port',type:'text',style:input_style,maxlen:5,value:"" },
						{ title: '密码', name:'ss_basic_password',type:'password',style:input_style,maxlen:64,value:"",help: '如果你的密码内有特殊字符，可能会导致密码参数不能正确的传给ss，导致启动后不能使用ss。',peekaboo: 1  },
						{ title: '加密方式', name:'ss_basic_method',type:'select',style:select_style,options:option_method,value: dbus.ss_basic_method || "aes-256-cfb" },
						{ title: 'MPTCP', name:'ss_basic_mptcp',type:'select',style:select_style,options:option_mptcp,value: dbus.ss_basic_mptcp || "0",help: '需要服务器支持。' },
						{ title: '混淆(AEAD)', name:'ss_basic_ss_obfs',type:'select',style:select_style,options:option_ss_obfs,value: dbus.ss_basic_ss_obfs || "0" },
						{ title: '混淆主机名', name:'ss_basic_ss_obfs_host',type:'text',style:input_style,value:dbus.ss_basic_ss_obfs_host || "" },
						{ title: '协议 (protocal)', name:'ss_basic_rss_protocal',type:'select',style:select_style,options:option_ssr_protocal,value: dbus.ss_basic_rss_protocal || "auth_sha1_v4" },
						{ title: '协议参数 (SSR特性)', name:'ss_basic_rss_protocal_para',type:'text',style:input_style,value:dbus.ss_basic_rss_protocal_para, help: '协议参数是SSR单端口多用户（端口复用）配置的必选项，如果你的SSR帐号没有启用端口复用，可以将此处留空。' },
						{ title: '混淆方式 (obfs)', name:'ss_basic_rss_obfs',type:'select',style:select_style,options:option_ssr_obfs,value:dbus.ss_basic_rss_obfs || "tls1.2_ticket_auth" },
						{ title: '混淆参数 (SSR特性)', name:'ss_basic_rss_obfs_para',type:'text',style:input_style,value: dbus.ss_basic_rss_obfs_para }
					]);
				}else{
					$('#ss_basic_pannel').forms([
						{ title: '模式', multi: [
							{ name:'ss_basic_mode',type:'select',style:select_style,options:option_mode,value: "" || "1", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_mode_1',type:'select',style:select_style,options:option_mode,value: "" || "1" }
						]},
						{ title: '服务器地址', multi: [
							{ name:'ss_basic_server',type:'text',style:input_style,value:dbus.ss_basic_server,help: '尽管支持域名格式，但是仍然建议首先使用IP地址。', suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_server_1',type:'text',style:input_style,value:dbus.ss_basic_server,help: '尽管支持域名格式，但是仍然建议首先使用IP地址。' }
						]},
						{ title: '服务器端口', multi: [
							{ name:'ss_basic_port',type:'text',style:input_style,maxlen:5,value:"", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_port_1',type:'text',style:input_style,maxlen:5,value:dbus.ss_basic_port }
						]},
						{ title: '密码', multi: [
							{ name:'ss_basic_password',type:'password',style:input_style,maxlen:64,value:"",help: '如果你的密码内有特殊字符，可能会导致密码参数不能正确的传给ss，导致启动后不能使用ss。',peekaboo: 1, suffix: ' &nbsp;&nbsp;'  },
							{ name:'ss_basic_password_1',type:'password',style:input_style,maxlen:64,value:dbus.ss_basic_password,help: '如果你的密码内有特殊字符，可能会导致密码参数不能正确的传给ss，导致启动后不能使用ss。',peekaboo: 1  }
						]},
						{ title: '加密方式', multi: [
							{ name:'ss_basic_method',type:'select',style:select_style,options:option_method,value: dbus.ss_basic_method || "aes-256-cfb", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_method_1',type:'select',style:select_style,options:option_method,value: dbus.ss_basic_method || "aes-256-cfb" }
						]},
						{ title: 'MPTCP', multi: [
							{ name:'ss_basic_mptcp',type:'select',style:select_style,options:option_mptcp,value: dbus.ss_basic_mptcp || "0", help: '需要服务器支持。', suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_mptcp_1',type:'select',style:select_style,options:option_mptcp,value: dbus.ss_basic_mptcp || "0" }
						]},
						{ title: '混淆(AEAD)', multi: [
							{ name:'ss_basic_ss_obfs',type:'select',style:select_style,options:option_ss_obfs,value: dbus.ss_basic_ss_obfs || "0", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_ss_obfs_1',type:'select',style:select_style,options:option_ss_obfs,value: dbus.ss_basic_ss_obfs || "0" }
						]},
						{ title: '混淆主机名', multi: [
							{ name:'ss_basic_ss_obfs_host',type:'text',style:input_style,value:dbus.ss_basic_ss_obfs_host || "", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_ss_obfs_host_1',type:'text',style:input_style,value:dbus.ss_basic_ss_obfs_host || "" }
						]},
						{ title: '协议 (protocal)', multi: [
							{ name:'ss_basic_rss_protocal',type:'select',style:select_style,options:option_ssr_protocal,value: dbus.ss_basic_rss_protocal || "auth_sha1_v4", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_rss_protocal_1',type:'select',style:select_style,options:option_ssr_protocal,value: dbus.ss_basic_rss_protocal || "auth_sha1_v4" }
						]},
						{ title: '协议参数 (SSR特性)', multi: [
							{ name:'ss_basic_rss_protocal_para',type:'text',style:input_style,value:dbus.ss_basic_rss_protocal_para, help: '协议参数是SSR单端口多用户（端口复用）配置的必选项，如果你的SSR帐号没有启用端口复用，可以将此处留空。', suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_rss_protocal_para_1',type:'text',style:input_style,value:dbus.ss_basic_rss_protocal_para, help: '协议参数是SSR单端口多用户（端口复用）配置的必选项，如果你的SSR帐号没有启用端口复用，可以将此处留空。' }
						]},
						{ title: '混淆方式 (obfs)', multi: [
							{ name:'ss_basic_rss_obfs',type:'select',style:select_style,options:option_ssr_obfs,value:dbus.ss_basic_rss_obfs || "tls1.2_ticket_auth", suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_rss_obfs_1',type:'select',style:select_style,options:option_ssr_obfs,value:dbus.ss_basic_rss_obfs || "tls1.2_ticket_auth" }
						]},
						{ title: '混淆参数 (SSR特性)', multi: [
							{ name:'ss_basic_rss_obfs_para',type:'text',style:input_style,value: dbus.ss_basic_rss_obfs_para, suffix: ' &nbsp;&nbsp;' },
							{ name:'ss_basic_rss_obfs_para_1',type:'text',style:input_style,value: dbus.ss_basic_rss_obfs_para }
						]},
					]);
				}
				var node_kcp=parseInt(dbus["ss_kcp_node"]);
				if (node_kcp && (dbus["ssconf_basic_max_node"] || dbus["ssrconf_basic_max_node"])){
					if (node_kcp <= node_ss + node_ssr){
					var node_html=$("#_ss_basic_node option[value='" + node_kcp +"']")[0].innerHTML;
						if (dbus["ss_kcp_enable"] == 1){
							if (node_html.indexOf("SSR") != -1){
								$("#_ss_basic_node option[value='" + node_kcp + "']").html(node_html.replace(/SSR/g, "KCP+SSR"));
							}else{
								$("#_ss_basic_node option[value='" + node_kcp + "']").html(node_html.replace(/SS/g, "KCP+SS"));
							}
						}
					}
 				}
			</script>
		</div>
	</div>
	<!-- ------------------ 节点管理 --------------------- -->
	<div id="tabs" class="btn-group boxr2">
		<a class="btn sub-btn-tab" style="width:102px;height:36px" href="javascript:void(0);" onclick="NodetabSelect('ss');" id="SubTabSS">SS节点 <i class="icon-tools"></i></a>
		<a class="btn sub-btn-tab" style="width:102px;height:36px" href="javascript:void(0);" onclick="NodetabSelect('ssr');" id="SubTabSSR">SSR节点 <i class="icon-tools"></i></a>
		<a class="btn sub-btn-tab" style="width:102px;height:36px" href="javascript:void(0);" onclick="NodetabSelect('manage');" id="SubTabMange">节点管理 <i class="icon-tools"></i></a>
	</div>
	<div class="box boxr2" id="ss_node_tab" style="margin-top: 15px;">
		<div class="heading">节点管理-SS节点</div>
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing=1 id="ss_node-grid">
				</table>
			</div>
		</div>
	</div>
	<div class="box boxr2" id="ssr_node_tab" style="margin-top: 15px;">
		<div class="heading">节点管理-SSR节点</div>
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing="1" id="ssr_node-grid">
				</table>
			</div>
		</div>
	</div>
	<div class="box boxr2" id="ssr_ping_tab" style="margin-top: 15px;">
		<div class="heading">ping测试</div>
		<div class="content">
			<div id="ss_ping_panel" class="tabContent">
				<script type="text/javascript">
					$('#ss_ping_panel').forms([
						{ title: '节点ping测试', multi: [
							{ name:'ss_basic_ping_method',type:'select',options:[["1", "ping 1次"], ["2", "10次ping平均 + 丢包率"], ["3", "20次ping平均 + 丢包率"] ], value: dbus.ss_basic_ping_method || "1", prefix:'ping测试方式：', suffix: ' &nbsp;&nbsp;'},
							//{ name:'ss_basic_ping_refresh',type:'select',options:[["1", "不显示（人工测试）"], ["0", "仅显示一次（不刷新）"], ["5", "5秒刷新一次"], ["15", "15秒刷新一次"], ["30", "30秒刷新一次"] ], value: dbus.ss_basic_ping_refresh || "0", prefix:'ping刷新间隔：', suffix: ' &nbsp;&nbsp;'},
							{ suffix: '<button id="ping_botton" onclick="ping_node();" class="btn btn-primary">手动测试ping <i class="icon-traffic"></i></button>' }
						]},
					]);
				</script>
			</div>
			<br><hr>
		</div>
	</div>
	<div class="box boxr2" id="ssr_node_subscribe" style="margin-top: 15px;">
		<div class="heading">SSR节点订阅</div>
		<div class="content">
			<div id="ssr_node_subscribe_pannel" class="section">
				<fieldset>
					<label class="col-sm-3 control-left-label">SSR节点订阅地址</label>
					<div class="col-sm-9">
						<table class="line-table" cellspacing=1 id="online_link-grid">
						</table>
					</div>
				</fieldset>
			</div>
			<script type="text/javascript">
				var group_del = [];
				group_del[0] = ["0", "删除全部订阅节点"]
				var j = 1;
				for ( var i = 1; i <= 10; i++){
					if(dbus["ss_online_group_" + i]){
						group_del[j] = [dbus["ss_online_group_" + i], dbus["ss_online_group_" + i]];
						j++;
					}
				}
				$('#ssr_node_subscribe_pannel').forms([
					{ title: '订阅节点模式设定',  name:'ssr_subscribe_mode',type:'select',options:option_mode,value:dbus.ssr_subscribe_mode || "2", suffix: '<lable id="_ssr_subscribe_mode_text">订阅后的服务器默认使用该模式。</lable>' },
					{ title: '订阅节点混淆参数设定', multi: [
						{ name: 'ssr_subscribe_obfspara',type:'select',options:[['0', '留空'], ['1', '使用订阅设定'], ['2', '自定义']], value: dbus.ssr_subscribe_obfspara || "2", suffix: ' &nbsp;&nbsp;' },
						{ name: 'ssr_subscribe_obfspara_val', type: 'text', value: dbus.ssr_subscribe_obfspara_val || "www.baidu.com", suffix: '<lable id="_ssr_subscribe_obfspara_text">有的订阅服务器不包含混淆参数，你可以在此处统一设定。</lable>' }
					]},
					{ title: '订阅时走SS网络', name:'ss_basic_online_links_goss',type:'checkbox',value: dbus.ss_basic_online_links_goss == 1 },  // ==1 means default close; !=0 means default open
					{ title: '节点订阅计划任务', multi: [
						{ name: 'ss_basic_node_update',type: 'select', options:[['0', '禁用'], ['1', '开启']], value: dbus.ss_basic_node_update || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_basic_node_update_day', type: 'select', options:option_day_time, value: dbus.ss_basic_node_update_day || "7",suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_basic_node_update_hr', type: 'select', options:option_hour_time, value: dbus.ss_basic_node_update_hr || "4",suffix: ' &nbsp;&nbsp;'}
					]},
					{ title: '删除订阅节点', multi: [
						{ name: 'ss_basic_online_node_del',type: 'select', options:group_del, value: dbus.ss_basic_online_node_del || "0", suffix: ' &nbsp;&nbsp;' },
						{ suffix: '<button id="_delete_online_node" onclick="delete_online_node(5);" class="btn">删除 <i class="icon-cancel"></i></button>' }
					]}
				]);
			</script>
			<!--<button type="button" value="Save" id="dele-subscribe-node" onclick="delete_online_node()" class="btn" style="float:right;">删除订阅节点 <i class="icon-cancel"></i></button>-->
			<button type="button" value="Save" id="save-subscribe-node" onclick="manipulate_conf('ss_online_update.sh', 7)" class="btn btn-primary" style="float:right;margin-right:20px;">手动更新订阅 <i class="icon-check"></i></button>
			<button type="button" value="Save" id="save-subscribe-node" onclick="manipulate_conf('ss_conf.sh', 8)" class="btn btn-primary" style="float:right;margin-right:20px;">保存订阅设置 <i class="icon-wrench"></i></button>
		</div>
	</div>
	<div class="box boxr2" id="ss_link_add" style="margin-top: 15px;">
		<div class="heading">通过SS/SSR链接添加服务器</div>
		<div class="content">
			<div id="ss_link_pannel" class="section">
				<fieldset>
					<label class="col-sm-3 control-left-label">SS/SSR链接</label>
					<div class="col-sm-9">
						<table class="line-table" cellspacing=1 id="ss_link-grid">
						</table>
					</div>
				</fieldset>
			</div>
			<button type="button" value="Save" id="save-add-link" onclick="manipulate_conf('ss_online_update.sh', 'add')" class="btn btn-primary" style="float:right;margin-right:0px;">解析并保存为节点 <i class="icon-check"></i></button>
		</div>
	</div>
	<button type="button" value="Save" id="save-node" onclick="save_node()" class="btn btn-primary boxr2">保存节点 <i class="icon-check"></i></button>
	<!-- ------------------ DNS设定 --------------------- -->
	<div class="box boxr3" id="ss_dns_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_dns_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_dns_pannel').forms([
					{ title: '选择国内DNS', multi: [
						{ name: 'ss_dns_china',type:'select', options:option_dns_china, value: dbus.ss_dns_china || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_dns_china_user', type: 'text', value: dbus.ss_dns_china_user }
					]},
					{ title: '选择国外DNS', multi: [
						{ name: 'ss_dns_foreign',type: 'select', options:option_dns_foreign, value: dbus.ss_dns_foreign || "1" },
						{ suffix: '<lable id="_ssdns_foreign_suffix">&nbsp;&nbsp;</lable>' },
						{ name: 'ss_chinadns_method',type: 'select',options:[['1', '原版'], ['2', 'ECS版']], value: dbus.ss_chinadns_method || "1" },
						{ name: 'ss_pdnsd_method',type: 'select',options:[['1', 'udp查询'], ['2', 'tcp查询']], value: dbus.ss_pdnsd_method || "1" },
						{ suffix: '<lable id="_ss_method_suffix">&nbsp;&nbsp;</lable>' },
						{ name: 'ss_dns2socks_user', type: 'text', value: dbus.ss_dns2socks_user || "8.8.8.8:53" },
						{ name: 'ss_sstunnel_user', type: 'text', value: dbus.ss_sstunnel_user || "8.8.8.8:53" },
						{ name: 'ss_opendns',type: 'select', options:option_opendns, value: dbus.ss_opendns || "cisco"},
						{ name: 'ss_chinadns_user', type: 'text', value: dbus.ss_chinadns_user || "8.8.8.8:53" },
						{ name: 'ss_pdnsd_user', type: 'text', value: dbus.ss_pdnsd_user || "8.8.8.8:53" },
						{ suffix: '<lable id="_ss_dns_note"></lable>' }
					]},
					{ title: 'chromecast支持 (接管局域网DNS解析)',  name:'ss_basic_chromecast',type:'checkbox', value: dbus.ss_basic_chromecast != 0, suffix: '<lable>此处强烈建议开启！</lable>' },
					{ title: '<b>自定义CDN加速名单</b></br></br><font color="#B2B2B2">强制用国内DNS解析的域名，一行一个，如：</br>koolshare.cn</br>baidu.com</font>', name: 'ss_isp_website_web', type: 'textarea', value: Base64.decode(dbus.ss_isp_website_web)||"",	style: 'width: 100%; height:150px;' },
					{ title: '<b>自定义dnsmasq</b></br></br><font color="#B2B2B2">一行一个，错误的格式会导致dnsmasq不能启动，格式：</br>address=/koolshare.cn/2.2.2.2</br>bogus-nxdomain=220.250.64.18</br>conf-file=/jffs/mydnsmasq.conf</font>', name: 'ss_dnsmasq', type: 'textarea', value: Base64.decode(dbus.ss_dnsmasq)||"", style: 'width: 100%; height:150px;' }
				]);
			</script>
		</div>
	</div>
	<!-- ------------------ 多WAN设定 --------------------- -->
	<div class="box boxr4" id="ss_mwan_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_mwan_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_mwan_pannel').forms([
					{ title: '节点ping测试出口', name:'ss_mwan_ping_dst',type:'select',options:[], value: dbus.ss_mwan_ping_dst},
					{ title: '国内DNS指定解析出口', name:'ss_mwan_china_dns_dst',type:'select',options:[], value: dbus.ss_mwan_china_dns_dst},
					{ title: 'SS服务器指定出口', name:'ss_mwan_vps_ip_dst',type:'select',options:[], value: dbus.ss_mwan_china_dns_dst}
				]);
			</script>
		</div>
	</div>
	<div id="ss_mwan_readme" class="box boxr4" style="margin-top: 0px;">
		<div class="heading">出口设定须知： <a class="pull-right" data-toggle="tooltip" title="Hide/Show Notes" href="javascript:toggleVisibility('mwan3');"><span id="sesdivmwan3showhide"><i class="icon-chevron-up"></i></span></a></div>
		<div class="section content" id="sesdivmwan3" style="display:none">
			<li>当你的LEDE配置了多个wan的时候，你可以通过本页面为一些ip地址设定指定的出口；</li>
			<li>你可以选择指定出口或者不指定，不指定出口的时候，将会由路由器本身随机选择出口；</li>
			<li>当启用了负载均衡后，SS服务器指定出口将会无效，但是你可以在负载均衡节点表格内指定每个负载均衡节点的出口；</li>
			<li>如果你指定了某个出口，在路由器使用期间某个接口离线后，将会由路由器本身随机选择出口，接口上线后将会恢复。</li>
		</div>
		<script>
			var cc;
			if(!cookie.get('ss_mwan3_vis')){
				cookie.set('ss_mwan3_vis', 1);
			}
			if (((cc = cookie.get('ss_mwan3_vis')) != null) && (cc == '1')) {
				toggleVisibility("mwan3");
			}
		</script>
	</div>	
	<button type="button" value="Save" id="dele-subscribe-node" onclick="manipulate_conf('ss_conf.sh', 9)" class="btn btn-primary boxr4">应用出口设定 <i class="icon-check"></i></button>
	<!-- ------------------ 负载均衡 --------------------- -->
	<div class="box boxr5" id="ss_lb_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content">
			<div id="ss_lb_panel" class="tabContent">
			<script type="text/javascript">
				$('#ss_lb_panel').forms([
					{ title: '负载均衡开关', name:'ss_lb_enable',type:'checkbox',  value: dbus.ss_lb_enable == 1 },  // ==1 means default close; !=0 means default open
					{ title: 'haproxy控制台', rid:'haproxy_console', text:'<a id="haproxy_console1" href="" target="_blank"></a>'},
					{ title: 'haproxy登录', multi: [
						{ name: 'ss_lb_account',type:'text', size: 4, value: dbus.ss_lb_account || "admin", prefix: '登录帐号：', suffix: ' &nbsp;&nbsp;' },
						{ name:'ss_lb_password',type:'password',size: 4,value:dbus.ss_lb_password, peekaboo: 1, prefix: '登录密码：',  }
					]},
					{ title: 'haproxy端口(用于ss监听)', name:'ss_lb_port',type:'text', maxlen:5, size: 2,value:dbus.ss_lb_port||"8118" },
					{ title: 'Haproxy故障检测心跳', multi: [
						{ name: 'ss_lb_heartbeat',type:'checkbox', value: dbus.ss_lb_heartbeat == 1, suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_lb_up', type: 'text', size: 1, value: dbus.ss_lb_up || "2", suffix: '<lable>次</lable>&nbsp;&nbsp;&nbsp;&nbsp;', prefix: '<span class="help-block"><lable>成功：</lable></span>' },
						{ name: 'ss_lb_down', type: 'text', size: 1, value: dbus.ss_lb_down || "3", suffix: '<lable>次</lable>&nbsp;&nbsp;&nbsp;&nbsp;', prefix: '<span class="help-block"><lable>失败：</lable></span>' },
						{ name: 'ss_lb_interval', type: 'text', size: 2, value: dbus.ss_lb_interval || "4000", suffix: '<lable>ms</lable>', prefix: '<span class="help-block"><lable>心跳间隔：</lable></span>' }
					]},
					{ title: '服务器添加', multi: [
						{ name: 'ss_lb_node',type:'select',style:select_style,options:option_node_name, value: dbus.ss_lb_node || "", suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_lb_weight', type: 'text', size: 1, value: dbus.ss_lb_weight || "50", suffix: ' &nbsp;&nbsp;', prefix: '<span class="help-block"><lable>权重：</lable></span>' },
						{ name: 'ss_lb_policy', type: 'select', options:option_lb_policy, value: dbus.ss_lb_policy || "1", suffix: ' &nbsp;&nbsp;',prefix: '<span class="help-block"><lable>属性：</lable></span>' },
						{ name: 'ss_lb_dest', type: 'select', options:[], suffix: ' &nbsp;&nbsp;',prefix: '<span class="help-block"><lable>出口：</lable></span>' },
						{ suffix: ' <button id="add_lbnode" onclick="add_lb_node();" class="btn btn-danger">添加<i class="icon-plus"></i></button>' }
					]}
				]);
				document.getElementById("haproxy_console1").href = "http://"+location.hostname+":1188";
				document.getElementById("haproxy_console1").innerHTML = "<i><u>http://"+location.hostname+":1188</i></u>";
				$("#_ss_lb_node option[value='0']").remove();
				$("#_ss_lb_node").val(1);
			</script>
			</div>
			<br><hr>
		</div>
	</div>
	<div class="box boxr5" id="lb_list" style="margin-top: 0px;">
		<div class="heading">负载均衡服务器列表</div>
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing=1 id="lb-grid">
				</table>
			</div>
			<br><hr>
		</div>
	</div>
	<div id="ss_lb_tab_readme" class="box boxr5">
		<div class="heading">负载均衡操作手册： <a class="pull-right" data-toggle="tooltip" title="Hide/Show Notes" href="javascript:toggleVisibility('lb');"><span id="sesdivlbshowhide"><i class="icon-chevron-up"></i></span></a></div>
		<div class="section content" id="sesdivlb" style="display:none">
			<li>在此页面可以设置多个ss或者ssr帐号负载均衡，同时具有故障转移、自动恢复的功能；</li>
			<li>注意：设置负载均衡的节点需要加密方式、密码、混淆等需要完全一致！SS、SSR之间不支持设置负载均衡；</li>
			<li>提交设置后会开启haproxy，并在ss节点配置中增加一个服务器IP为127.0.0.1，端口为负载均衡服务器端口的帐号；</li>
			<li>负载均衡模式下不支持udp转发：不能使用游戏模式，不能使用ss-tunnel作为国外dns方案;</li>
			<li>强烈建议需要负载均衡的ss节点使用ip格式，使用域名会使haproxy进程加载过慢！</li>
		</div>
		<script>
			var cc;
			if(!cookie.get('ss_lb_vis')){
				cookie.set('ss_lb_vis', 1);
			}
			if (((cc = cookie.get('ss_lb_vis')) != null) && (cc == '1')) {
				toggleVisibility("lb");
			}
		</script>
	</div>
	<button type="button" value="Save" id="save-lb" onclick="save_lb()" class="btn btn-primary boxr5">保存负载均衡设置 <i class="icon-check"></i></button>
	<!-- ------------------ KCP加速 --------------------- -->
	<div class="box boxr6" id="ss_kcp_tab_1" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content">
			<div id="ss_kcp_panel_1" class="tabContent">
			<script type="text/javascript">
				$('#ss_kcp_panel_1').forms([
					{ title: 'KCP加速开关', name:'ss_kcp_enable', type:'checkbox',  value: dbus.ss_kcp_enable == 1 },  // ==1 means default close; !=0 means default open
					{ title: '当前KCP版本', rid:'ss_kcp_version', text:'<font id="_ss_kcp_version" color="#1bbf35">20171201</font>'},
				]);
			</script>
			</div>
		</div>
	</div>
	<div class="box boxr6" id="ss_kcp_tab_2" style="margin-top: 0px;">
		<div class="heading">KCP服务器设置</div>
		<div class="content">
			<div id="ss_kcp_panel_2" class="tabContent">
			<script type="text/javascript">
				$('#ss_kcp_panel_2').forms([
					{ title: 'KCP加速的服务器地址', name: 'ss_kcp_node', type:'select', style:select_style, options:option_node_name, value: dbus.ss_kcp_node || "1" },
					{ title: '服务器端口', name:'ss_kcp_port',type:'text',style:input_style, maxlen:5, value:dbus.ss_kcp_port||"1099" },
					{ title: '服务器密码 (--key)', name:'ss_kcp_password',type:'password', maxlen:64, style:input_style,value:dbus.ss_kcp_password, peekaboo:1 },
					{ title: '速度模式 (--mode)', name:'ss_kcp_mode',type:'select', style:select_style, options:option_kcp_mode,value:dbus.ss_kcp_mode||"fast" },
					{ title: '加密方式 (--crypt)', name:'ss_kcp_crypt',type:'select', style:select_style, options:option_kcp_crypt,value:dbus.ss_kcp_crypt||"aes" },
					{ title: 'MTU (--mtu)', name:'ss_kcp_mtu',type:'text',style:input_style, maxlen:4, value:dbus.ss_kcp_mtu||"1350" },
					{ title: '发送窗口 (--sndwnd)', name:'ss_kcp_sndwnd',type:'text',style:input_style, maxlen:5, value:dbus.ss_kcp_sndwnd||"128" },
					{ title: '接收窗口 (--rcvwnd)', name:'ss_kcp_rcvwnd',type:'text',style:input_style, maxlen:5, value:dbus.ss_kcp_rcvwnd||"1024" },
					{ title: '链接数 (--conn)', name:'ss_kcp_conn',type:'text',style:input_style, maxlen:4, value:dbus.ss_kcp_conn||"1" },
					{ title: '关闭数据压缩 (--nocomp)', name:'ss_kcp_compon',type:'checkbox',style:input_style, maxlen:4, value:dbus.ss_kcp_compon == 1 },
					{ title: '其它配置项', name:'ss_kcp_config',type:'text',style:"width:85%", value:dbus.ss_kcp_config }
				]);
				
				E('_ss_kcp_config').placeholder = "请将速度模式为manual的参数和其它参数依次填写进来";
				document.getElementById("_ss_kcp_version").innerHTML = dbus["ss_kcp_version"] || "20171113";
				$("#_ss_kcp_node option[value='0']").remove();
			</script>
			</div>
			<br><hr>
		</div>
	</div>
	<div id="ss_kcp_tab_readme" class="box boxr6">
		<div class="heading">KCP加速使用说明： <a class="pull-right" data-toggle="tooltip" title="Hide/Show Notes" href="javascript:toggleVisibility('kcp');"><span id="sesdivkcpshowhide"><i class="icon-chevron-up"></i></span></a></div>
		<div class="section content" id="sesdivkcp" style="display:none">
			<li>正确填写kcp参数后，点击保存KCP设置，如果kcp节点和ss节点一致，会自动重启ss；如果不一致，仅仅保存配置，待在主面板选在kcp加速的节点后才能生效；</li>
			<li>kcp加速仅针对你在kcp加速页面选择的节点，如果在主面板切换到了其它节点，虽然此时kcp开关是启用状态，但是并不会启动kcp加速；</li>
			<li>因为kcp协议仅支持tcp转kcp，所以在使用ss-tunnel作为DNS解析的时候，ss-tunnel并不会走kcp协议，而是走正常udp直连；</li>
			<li>因为kcp加速只针对单个节点，所以kcp不能和负载均衡混用！kcp启用后负载均衡标签页会暂时隐藏，负载均衡启用后，kcp标签页会暂时隐藏;</li>
		</div>
		<script>
			var cc;
			if(!cookie.get('ss_kcp_vis')){
				cookie.set('ss_kcp_vis', 1);
			}
			if (((cc = cookie.get('ss_kcp_vis')) != null) && (cc == '1')) {
				toggleVisibility("kcp");
			}
		</script>
	</div>
	<button type="button" value="Save" id="save-kcp" onclick="save_kcp()" class="btn btn-primary boxr6">保存kcp设置 <i class="icon-check"></i></button>
	<!-- ------------------ 黑白名单--------------------- -->
	<div class="box boxr7" id="ss_wblist_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_wblist_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_wblist_pannel').forms([
					{ title: '<b>IP/CIDR白名单</b></br></br><font color="#B2B2B2">不走SS的外网ip/cidr地址，一行一个，例如：</br>2.2.2.2</br>3.3.0.0/16</font>', name: 'ss_wan_white_ip', type: 'textarea', value: Base64.decode(dbus.ss_wan_white_ip)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>域名白名单</b></br></br><font color="#B2B2B2">不走SS的域名，例如：</br>google.com</br>facebook.com</font>', name: 'ss_wan_white_domain', type: 'textarea', value: Base64.decode(dbus.ss_wan_white_domain)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>IP/CIDR黑名单</b></br></br><font color="#B2B2B2">强制走SS的外网ip/cidr地址，一行一个，例如：</br>4.4.4.4</br>5.0.0.0/8</font>', name: 'ss_wan_black_ip', type: 'textarea', value: Base64.decode(dbus.ss_wan_black_ip)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>域名黑名单</b></br></br><font color="#B2B2B2">强制走SS的域名,例如：</br>baidu.com</br>koolshare.cn</font>', name: 'ss_wan_black_domain', type: 'textarea', value: Base64.decode(dbus.ss_wan_black_domain)||"", style: 'width: 100%; height:150px;' }
				]);
			</script>
		</div>
	</div>
	<!-- ------------------ 访问控制 --------------------- -->
	<div class="box boxr8" id="ss_acl_tab" style="margin-top: 0px;">
		<div class="heading">访问控制主机</div>
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing=1 id="ss_acl_pannel"></table>
			</div>
			<br><hr>
		</div>
	</div>
	<div class="box boxr8" id="ss_acl_default_tab" style="margin-top: 0px;">
		<div class="heading">默认主机设置</div>
		<div class="content">
			<div id="ss_acl_default_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_acl_default_pannel').forms([
					{ title: '默认模式 (全部主机)', name: 'ss_acl_default_mode', type:'select', style:select_style, options:option_acl_mode, value: dbus.ss_acl_default_mode || "1"},
					{ title: '目标端口 (全部主机)', multi: [
						{ name:'ss_acl_default_port',type:'select',style:select_style, options:option_acl_port, maxlen:5, value:dbus.ss_acl_default_port||"all", suffix: ' &nbsp;&nbsp;' },
						{ name:'ss_acl_default_port_user',type:'text',style:input_style, maxlen:5, value:dbus.ss_acl_default_port_user }
					]},
					{ title: '', name: 'ss_acl_default_readme', suffix: ' 当前未设置访问控制主机，所有路由器下的主机都将走此处设定的模式和端口。'},
				]);
			</script>
		</div>
	</div>
	<div id="ss_acl_tab_readme" class="box boxr8">
		<div class="heading">访问控制操作手册： <a class="pull-right" data-toggle="tooltip" title="Hide/Show Notes" href="javascript:toggleVisibility('acl');"><span id="sesdivaclshowhide"><i class="icon-chevron-up"></i></span></a></div>
		<div class="section content" id="sesdivacl" style="display:none">
			<li><b>1：</b> 你可以在这里定义你需要的主机走SS的模式和端口，或者你可以什么都不做，使用默认规则，代表全部主机都默认走【默认主机设置】内的模式和端口；</li>
			<li><b>2：</b> 主机别名、主机IP地址、MAC地址已经在系统的arp列表里获取了，在LEDE路由下的设备均能被选择，选择后相应设备的ip和mac地址会自动填写；</li>
			<li><b>3：</b> 如果你需要的设备在列表里不能选择，可以不选择主机别名列表，然后填选好其他地方，添加后保存，插件会自动为你的这个设备分配一个名字；</li>
			<li><b>4：</b> 请按照格式填写ip和mac地址，ip和mac地址至少一个不能为空！</li>
			<li><b>5：</b> 插件为每个模式推荐了相应的端口，当你选择相应访问控制模式后，端口会自动变化，你也可以设定自定义端口，例如：22,80,443,222,333:555，错误的格式将导致问题！；</li>
			<li><b>6：</b> 当访问控制模式不为：不通过ss的时候，在【帐号设置】面板里更改模式，这里的默认规则模式会自动发生变化，否则不发生变化。</li>
		</div>
		<script>
			var cc;
			if(!cookie.get('ss_acl_vis')){
				cookie.set('ss_acl_vis', 1);
			}
			if (((cc = cookie.get('ss_acl_vis')) != null) && (cc == '1')) {
				toggleVisibility("acl");
			}
		</script>
	</div>
	<!-- ------------------ 规则管理 --------------------- -->
	<div class="box boxr9" id="ss_rule_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_rule_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_rule_pannel').forms([
					{ title: 'gfwlist域名数量', rid:'gfw_number_1', text:'<a id="gfw_number" href="https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf" target="_blank"></a>'},
					{ title: '大陆白名单IP段数量', rid:'chn_number_1', text:'<a id="chn_number" href="https://raw.githubusercontent.com/hq450/fancyss/master/rules/chnroute.txt" target="_blank"></a>'},
					{ title: '国内域名数量（cdn名单）', rid:'cdn_number_1', text:'<a id="cdn_number" href="https://raw.githubusercontent.com/hq450/fancyss/master/rules/cdn.txt" target="_blank"></a>'},
					{ title: 'Routing.txt（Pcap规则）', rid:'Routing_number_1', text:'<a id="Routing_number" href="https://raw.githubusercontent.com/hq450/fancyss/master/rules/Routing.txt" target="_blank"></a>'},
					{ title: 'WhiteList.txt（Pcap规则）', rid:'WhiteList_number_1', text:'<a id="WhiteList_number" href="https://raw.githubusercontent.com/hq450/fancyss/master/rules/WhiteList.txt" target="_blank"></a>'},
					{ title: 'koolss规则自动更新', multi: [
						{ name: 'ss_basic_rule_update',type: 'select', options:[['0', '禁用'], ['1', '开启']], value: dbus.ss_basic_rule_update || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_basic_rule_update_day', type: 'select', options:option_day_time, value: dbus.ss_basic_rule_update_day || "7",suffix: ' &nbsp;&nbsp;' },
						{ name: 'ss_basic_rule_update_hr', type: 'select', options:option_hour_time, value: dbus.ss_basic_rule_update_hr || "3",suffix: ' &nbsp;&nbsp;' },
						{ name:'ss_basic_gfwlist_update',type:'checkbox',value: dbus.ss_basic_gfwlist_update != 0, suffix: '<lable id="_ss_basic_gfwlist_update_txt">gfwlist</lable>&nbsp;&nbsp;' },
						{ name:'ss_basic_chnroute_update',type:'checkbox',value: dbus.ss_basic_chnroute_update != 0, suffix: '<lable id="_ss_basic_chnroute_update_txt">chnroute</lable>&nbsp;&nbsp;' },
						{ name:'ss_basic_cdn_update',type:'checkbox',value: dbus.ss_basic_cdn_update != 0, suffix: '<lable id="_ss_basic_cdn_update_txt">cdn_list</lable>&nbsp;&nbsp;' },
						{ name:'ss_basic_pcap_update',type:'checkbox',value: dbus.ss_basic_pcap_update != 0, suffix: '<lable id="_ss_basic_pcap_update_txt">pcap_list</lable>&nbsp;&nbsp;' },
						{ suffix: '<button id="_update_rules_now" onclick="update_rules_now(5);" class="btn btn-success">手动更新 <i class="icon-cloud"></i></button>' }
					]}
				]);
				$('#gfw_number').html(dbus.ss_gfw_status || "未初始化");
				$('#chn_number').html(dbus.ss_chn_status || "未初始化");
				$('#cdn_number').html(dbus.ss_cdn_status || "未初始化");
				$('#Routing_number').html(dbus.ss_pcap_routing || "未初始化");
				$('#WhiteList_number').html(dbus.ss_pcap_whitelist || "未初始化");
			</script>
		</div>
	</div>
	<button type="button" value="Save" id="save-subscribe-node" onclick="manipulate_conf('ss_conf.sh', 10)" class="btn btn-primary boxr9">保存本页设置 <i class="icon-check"></i></button>
	<!-- ------------------ 附加功能 --------------------- -->
	<div class="box boxr10" id="ss_addon_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_addon_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_addon_pannel').forms([
					{ title: '状态更新间隔', name:'ss_basic_refreshrate',type:'select',options:option_status_inter, value: dbus.ss_basic_refreshrate || "5"},
					{ title: '大陆白名单和游戏模式分流方式', name:'ss_basic_bypass',type:'select',options:[["1", "chnroute"],["2", "geoip"]], value: dbus.ss_basic_bypass || "5"},
					{ title: 'SS数据清除', suffix: '<button onclick="manipulate_conf(\'ss_conf.sh\', 1);" class="btn btn-success">清除所有SS数据</button>&nbsp;&nbsp;&nbsp;&nbsp;<button onclick="manipulate_conf(\'ss_conf.sh\', 2);" class="btn btn-success">清除SS节点数据</button>&nbsp;&nbsp;&nbsp;&nbsp;<button onclick="manipulate_conf(\'ss_conf.sh\', 3);" class="btn btn-success">清除访问控制数据</button>' },
					{ title: 'SS数据备份', suffix: '<button onclick="manipulate_conf(\'ss_conf.sh\', 4);" class="btn btn-download">备份所有SS数据</button>' },
					{ title: 'SS数据恢复', suffix: '<input type="file" id="file" size="50">&nbsp;&nbsp;<button id="upload1" type="button"  onclick="restore_conf();" class="btn btn-danger">上传并恢复 <i class="icon-cloud"></i></button>' },
					{ title: 'SS插件备份', suffix: '<button onclick="manipulate_conf(\'ss_conf.sh\', 6);" class="btn btn-download">打包SS插件</button>' }
				]);
			</script>
		</div>
	</div>
	<!-- ------------------ 查看日志 --------------------- -->
	<div class="box boxr11" id="ss_log_tab" style="margin-top: 0px;">
		<div id="ss_log_pannel" class="content">
			<div class="section content">
				<script type="text/javascript">
					y = Math.floor(docu.getViewSize().height * 0.55);
					s = 'height:' + ((y > 300) ? y : 300) + 'px;display:block';
					$('#ss_log_pannel').append('<textarea class="as-script" name="_ss_basic_log" id="_ss_basic_log" readonly wrap="off" style="max-width:100%; min-width: 100%; margin: 0; ' + s + '" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>');
				</script>
			</div>
		</div>
	</div>
	<!-- ------------------ 其它 --------------------- -->
	<div id="msg_warring" class="alert alert-warning icon" style="display:none;"></div>
	<div id="msg_success" class="alert alert-success icon" style="display:none;"></div>
	<div id="msg_error" class="alert alert-error icon" style="display:none;"></div>
	<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">提交 <i class="icon-check"></i></button>
	<button type="button" value="Cancel" id="cancel-button" onclick="javascript:reloadPage();" class="btn">取消 <i class="icon-cancel"></i></button>
	<script type="text/javascript">init_ss();</script>
</content>
