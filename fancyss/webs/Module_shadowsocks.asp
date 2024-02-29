<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title id="ss_title">【科学上网】</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<link rel="stylesheet" type="text/css" href="/res/fancyss.css">
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/table/table.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/ss-menu.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/softcenter.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/tablednd.js"></script>
<script>
var PKG_NAME="fancyss"
var PKG_ARCH="unknown"
var PKG_TYPE="full"
var PKG_EXTA="_debug"
var pkg_name=PKG_NAME + "_" + PKG_ARCH + "_" + PKG_TYPE + PKG_EXTA
var db_ss = {};
var dbus = {};
var confs = {};
var dns_log = {};
var obj_node = {};
var node_max = 0;
var node_nu = 0;
var ss_nodes = [];
var nodeN = 15;
var trsH = 36;
var nodeH;
var nodeT=304;
var node_idx;
var sel_mode;
var edit_id;
var isMenuopen = 0;
var _responseLen;
var noChange = 0;
var noChange2 = 0;
var noChange_status = 0;
var noChange_dns = 0;
var poped = 0;
var submit_flag = "0";
var x = 5;
var save_flag = "";
var STATUS_FLAG;
var SMARTDNS_FLAG;
var refreshRate;
var ph_v2ray = "# 填入v2ray json配置，内容可以是标准的也可以是压缩的&#10;# 此处的配置可以支持v2ray运行更多协议，比如ss/vless/socks等xray支持的协议&#10;# 请保证你json内的outbound/outbounds部分配置正确！！！"
var ph_xray = "# 填入xray json配置，内容可以是标准的也可以是压缩的&#10;# 此处的配置可以支持xray运行更多协议，比如ss/vmess/trojan/socks等xray支持的协议&#10;# 请保证你json内的outbound/outbounds部分配置正确！！！"
var ph_tuic = "# 填入tuic client json配置，内容可以是标准的也可以是压缩的&#10;# 请保证你json内的relay部分的配置正确！！！" 	//fancyss-full
var option_modes = [["1", "gfwlist模式"], ["2", "大陆白名单模式"], ["3", "游戏模式"], ["5", "全局代理模式"], ["6", "回国模式"]];
var option_method = [ "none",  "rc4",  "rc4-md5",  "rc4-md5-6",  "aes-128-gcm",  "aes-192-gcm",  "aes-256-gcm",  "aes-128-cfb",  "aes-192-cfb",  "aes-256-cfb",  "aes-128-ctr",  "aes-192-ctr",  "aes-256-ctr",  "camellia-128-cfb",  "camellia-192-cfb",  "camellia-256-cfb",  "bf-cfb",  "cast5-cfb",  "idea-cfb",  "rc2-cfb",  "seed-cfb",  "salsa20",  "chacha20",  "chacha20-ietf",  "chacha20-ietf-poly1305",  "xchacha20-ietf-poly1305", "plain", "2022-blake3-aes-128-gcm", "2022-blake3-aes-256-gcm", "2022-blake3-chacha20-poly1305" ];
var option_protocals = [ "origin", "verify_simple", "verify_sha1", "auth_sha1", "auth_sha1_v2", "auth_sha1_v4", "auth_aes128_md5", "auth_aes128_sha1", "auth_chain_a", "auth_chain_b", "auth_chain_c", "auth_chain_d", "auth_chain_e", "auth_chain_f" ];
var option_obfs = ["plain", "http_simple", "http_post", "tls1.2_ticket_auth"];
var option_v2enc = [ ["auto", "自动[auto]"], ["none", "不加密[none]"], ["aes-128-cfb", "aes-128-cfb"], ["aes-128-gcm", "aes-128-gcm"], ["chacha20-poly1305", "chacha20-poly1305"], ["zero", "zero"]];
var option_headtcp = [["none", "不伪装"], ["http", "伪装http"]];
var option_headkcp = [["none", "不伪装"], ["srtp", "伪装视频通话(srtp)"], ["utp", "伪装BT下载(uTP)"], ["wechat-video", "伪装微信视频通话"], ["dtls", "dtls"], ["wireguard", "wireguard"]];
var option_headquic = [["none", "不伪装"], ["srtp", "伪装视频通话(srtp)"], ["utp", "伪装BT下载(uTP)"], ["wechat-video", "伪装微信视频通话"], ["dtls", "dtls"], ["wireguard", "wireguard"]];
var option_grpcmode = ["gun", "multi"];
var option_bol = [["0", "false"], ["1", "true"]];
var option_xflow = [["", "none"], ["xtls-rprx-vision", "xtls-rprx-vision"], ["xtls-rprx-origin", "xtls-rprx-origin"], ["xtls-rprx-origin-udp443", "xtls-rprx-origin-udp443"], ["xtls-rprx-direct", "xtls-rprx-direct"], ["xtls-rprx-direct-udp443", "xtls-rprx-direct-udp443"], ["xtls-rprx-splice", "xtls-rprx-splice"], ["xtls-rprx-splice-udp443", "xtls-rprx-splice-udp443"]];
//var option_xflow = ["", "xtls-rprx-vision", "xtls-rprx-origin", "xtls-rprx-origin-udp443", "xtls-rprx-direct", "xtls-rprx-direct-udp443", "xtls-rprx-splice", "xtls-rprx-splice-udp443"];
var option_fingerprint = ["chrome", "firefox", "safari", "ios", "android", "edge", "360", "qq", "random", "randomized", ""];
var option_naive_prot = ["https", "quic"];
var option_hy2_obfs = [["0", "停用"], ["1", "salamander"]];		//fancyss-full
var stop_scroll = 0;
var close_latency_flag = 0;
var stopFlag = 1;
const pattern=/[`~!@#$^&*()=|{}':;'\\\[\]\.<>\/?~！@#￥……&*（）——|{}%【】'；：""'。，、？\s]/g;
var time_wait;
var ws;
var ws_flag;
var wss_open;
var hostname = document.domain;
var mouse_status;
var ws_enable = 0;
if(PKG_ARCH == "hnd_v8"){
	if(PKG_TYPE == "full"){
		var ws_enable = 1;
	}
}
if(PKG_ARCH == "mtk" || PKG_ARCH == "qca"){
	var ws_enable = 1;
}
String.prototype.myReplace = function(f, e){
	var reg = new RegExp(f, "g"); 
	return this.replace(reg, e); 
}
function init() {
	show_menu(menu_hook);
	get_dbus_data();
	try_ws_connect();
}
function try_ws_connect(){
	if (ws_enable != 1){
		ws_flag = 0;
		return false;
	}
	if (window.location.protocol != "http:"){
		ws_flag = 0;
		return false;
	}
	ws_test = new WebSocket("ws://" + hostname + ":803/");
	ws_test.onopen = function() {
		ws_test.send("echo ws_ok");
	};
	ws_test.onerror = function(event) {
		ws_flag = 2;
		//console.log('ws_test failed!');
	};
	ws_test.onmessage = function(event) {
		ws_flag = 1;
		//console.log('ws_test message_ok!');
		ws_test.close();
	};
}
function refresh_dbss() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			generate_node_info();
		}
	});
}
function get_dbus_data() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		cache: false,
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			// basic conf to fill element
			conf2obj(db_ss);
			// generate node info (obj confs) for node table 
			generate_node_info();
			// generate options for node select
			refresh_options();
			// generate node table
			refresh_html();
			// fill node value
			ss_node_sel();
			// define click action
			toggle_func();
			// start to get fancyss staus
			get_ss_status();
			// try to get latest version of fancyss
			version_show();
			message_show();
			
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			console.log(XmlHttpRequest.responseText);
			alert("skipd数据读取错误，请格式化jffs分区后重新尝试！");
		}
		,timeout: 0
	});
}
function conf2obj(obj, action) {
	//console.log(obj);
	var _base64 = ["ss_basic_password", "ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links", "ss_basic_custom"];
	for (var field in obj) {
		var el = E(field);
		// do not fill
		if (field == "ss_base64_links") {
			continue;
		}
		// base64_decode then fill
		if (field == "ss_basic_naive_pass") {		//fancyss-full
			el.value = Base64.decode(obj[field]);	//fancyss-full
			continue;								//fancyss-full
		}											//fancyss-full
		// base64_decode then format json then fill
		if (field == "ss_basic_v2ray_json" || field == "ss_basic_xray_json") {
			el.value = do_js_beautify(Base64.decode(obj[field]));
			continue;
		}
		if (field == "ss_basic_tuic_json") {						//fancyss-full
			el.value = do_js_beautify(Base64.decode(obj[field]));	//fancyss-full
			continue;												//fancyss-full
		}															//fancyss-full
		if (el != null && el.getAttribute("type") == "checkbox") {
			el.checked = obj[field] == "1" ? true : false;
			continue;
		}
		if (el != null && el.getAttribute("type") == "radio") {
			el.checked = obj[field] == "1" ? true : false;
			continue;
		}
		if (el != null) {
			if(_base64.includes(field)){
				// base64_decode then fill
				el.value = Base64.decode(obj[field]);
			}else{
				// fill others
				el.value = obj[field];
			}
		}
	}
}
function ssconf_node2obj(node_sel) {
	obj_node = {};
	var p = "ssconf_basic";
	var params_tt_0 = ["ss_obfs", "ss_v2ray", "use_kcp", "v2ray_use_json", "v2ray_network_security_ai", "v2ray_mux_enable", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "xray_use_json", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_show", "hy2_ai", "hy2_tfo"];
	var params_tt_1 = ["type" ,"server", "mode", "port", "password", "method", "ss_obfs_host", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_json", "tuic_json", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni"];
	for (var i = 0; i < params_tt_0.length; i++) {
		obj_node["ss_basic_" + params_tt_0[i]] = db_ss[p + "_" + params_tt_0[i] + "_" + node_sel] || "0";
	}

	for (var i = 0; i < params_tt_1.length; i++) {
		obj_node["ss_basic_" + params_tt_1[i]] = db_ss[p + "_" + params_tt_1[i] + "_" + node_sel] || "";
	}
	obj_node["ssconf_basic_node"] = node_sel;
	return obj_node;
}
function ss_node_sel() {
	var node_sel = E("ssconf_basic_node").value;
	if (!node_sel){
		node_sel = node_max; 
	}
	if (node_sel > node_max){
		node_sel = node_max;
	}
	var obj = ssconf_node2obj(node_sel);
	conf2obj(obj, 1);
	verifyFields();
}
function refresh_options() {
	if (node_max == 0) return false;
	var option0 = $("#ssconf_basic_node");
	var option2 = $("#ss_basic_udp_node");
	var option3 = $("#ss_failover_s4_3");
	
	option0.find('option').remove().end();
	option2.find('option').remove().end();
	option3.find('option').remove().end();
	
	for (var field in confs) {
		var c = confs[field];
		if(c["type"] == "3" && c["v2ray_use_json"] == "1"){
			continue;
		}else if(c["type"] == "4" && c["xray_use_json"] == "1"){
			continue;
		}else{
			option2.append('<option value="' + field + '">' + c["name"] + '</option>');
		}
	}
	for (var field in confs) {
		option3.append('<option value="' + field + '">' + c["name"] + '</option>');
		var c = confs[field];
		if (c.group) {
			var real_group = c.group.split("_")[0];
			var group_tag = real_group + " - ";
		}else{
			var group_tag = "";
		}

		if (c.type == "0"){
			//ss
			option0.append($("<option>", {
				value: field,
				text: c.use_kcp == "1" ? "【SS+KCP】" + group_tag + c.name : "【SS】" + group_tag + c.name
			}));
		}
		else if(c.type == "1"){
			//ssr
			option0.append($("<option>", {
				value: field,
				text: c.use_kcp == "1" ? "【SSR+KCP】" + group_tag + c.name : "【SSR】" + group_tag + c.name
			}));
		}
		else if(c.type == "3"){
			//v2ray
			option0.append($("<option>", {
				value: field,
				text: c.use_kcp == "1" ? "【V2ray+KCP】" + group_tag + c.name : "【V2ray】" + group_tag + c.name
			}));
		}
		else if(c.type == "4"){
			//xray
			option0.append($("<option>", {
				value: field,
				text: c.use_kcp == "1" ? "【Xray+KCP】" + group_tag + c.name : "【Xray】" + group_tag + c.name
			}));
		}
		else if(c.type == "5"){
			//trojan
			option0.append($("<option>", {
				value: field,
				text: c.use_kcp == "1" ? "【trojan+KCP】" + group_tag + c.name : "【trojan】" + group_tag + c.name
			}));
		}
		else if(c.type == "6"){																								//fancyss-full							
			//naive
			option0.append($("<option>", {																					//fancyss-full
				value: field,																								//fancyss-full
				text: c.use_kcp == "1" ? "【Naïve+KCP】" + group_tag + c.name : "【Naïve】" + group_tag + c.name			//fancyss-full
			}));																											//fancyss-full
		}																													//fancyss-full
		else if(c.type == "7"){																								//fancyss-full
			//tuic																											//fancyss-full
			option0.append($("<option>", {																					//fancyss-full
				value: field,																								//fancyss-full
				text: c.use_kcp == "1" ? "【tuic+KCP】" + group_tag + c.name : "【tuic】" + group_tag + c.name				//fancyss-full
			}));																											//fancyss-full
		}																													//fancyss-full
		else if(c.type == "8"){																								//fancyss-full
			//hysteria2
			option0.append($("<option>", {																					//fancyss-full
				value: field,																								//fancyss-full
				text: c.use_kcp == "1" ? "【hysteria2+KCP】" + group_tag + c.name : "【hysteria2】" + group_tag + c.name	//fancyss-full
			}));																											//fancyss-full
		}																													//fancyss-full
	}
	option0.val(db_ss["ssconf_basic_node"]||"1");
	option2.val(db_ss["ss_basic_udp_node"]||"1");
	option3.val((db_ss["ss_failover_s4_3"])||"1");
	// refresh node dns resolv option
	if (db_ss["ss_basic_server_resolv"] <= "0"){
		var option_value = db_ss["ss_basic_lastru"];
		var option_text = $("#ss_basic_server_resolv").find('option[value=' + option_value + ']').text();
		$('#ss_basic_server_resolv option[value=' + option_value + ']').text(option_text + '✅');
	}else{
		var option_text = $("#ss_basic_server_resolv").find('option[value=' + db_ss["ss_basic_server_resolv"] + ']').text();
		$('#ss_basic_server_resolv option[value=' + db_ss["ss_basic_server_resolv"] + ']').text(option_text + '✅');
	}
	// 节点列表显示行数
	$("#ss_basic_row").find('option').remove().end();
	for (var i = 10; i <= 27; i++) {
		$("#ss_basic_row").append('<option value="' + i + '">' + i + '</option>');
	}
	E("ss_basic_row").value = db_ss["ss_basic_row"]||18;
}
function save() {
	var node_sel = E("ssconf_basic_node").value;
	submit_flag="1";
	dbus["ssconf_basic_node"] = node_sel;
	E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
	E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
	// key define
	var params_input = ["ss_failover_s1", "ss_failover_s2_1", "ss_failover_s2_2", "ss_failover_s3_1", "ss_failover_s3_2", "ss_failover_s4_1", "ss_failover_s4_2", "ss_failover_s4_3", "ss_failover_s5", "ss_basic_interval", "ss_basic_row", "ss_dns_plan", "ss_basic_chng_china_1_prot", "ss_basic_chng_china_1_udp", "ss_basic_chng_china_1_udp_user", "ss_basic_chng_china_1_tcp", "ss_basic_chng_china_1_tcp_user", "ss_basic_chng_china_1_doh", "ss_basic_chng_china_2_prot", "ss_basic_chng_china_2_udp", "ss_basic_chng_china_2_udp_user", "ss_basic_chng_china_2_tcp", "ss_basic_chng_china_2_tcp_user", "ss_basic_chng_china_2_doh", "ss_basic_chng_trust_1_opt", "ss_basic_chng_trust_1_opt", "ss_basic_chng_trust_1_opt_udp_val", "ss_basic_chng_trust_1_opt_udp_val_user", "ss_basic_chng_trust_1_opt_tcp_val", "ss_basic_chng_trust_1_opt_tcp_val_user", "ss_basic_chng_trust_1_opt_doh_val", "ss_basic_chng_trust_2_opt_doh", "ss_basic_chng_trust_2_opt", "ss_basic_chng_trust_2_opt_udp", "ss_basic_chng_trust_2_opt_tcp", "ss_basic_chng_repeat_times", "ss_china_dns", "ss_china_dns_user", "ss_basic_smrt", "ss_basic_dohc_sel_china", "ss_basic_dohc_udp_china", "ss_basic_dohc_udp_china_user", "ss_basic_dohc_tcp_china", "ss_basic_dohc_tcp_china_user", "ss_basic_dohc_doh_china", "ss_basic_dohc_sel_foreign", "ss_basic_dohc_tcp_foreign", "ss_basic_dohc_tcp_foreign_user", "ss_basic_dohc_doh_foreign", "ss_basic_dohc_cache_timeout", "ss_foreign_dns", "ss_dns2socks_user", "ss_sstunnel_user", "ss_direct_user", "ss_basic_kcp_lserver", "ss_basic_kcp_lport", "ss_basic_kcp_server", "ss_basic_kcp_port", "ss_basic_kcp_parameter", "ss_basic_rule_update", "ss_basic_rule_update_time", "ssr_subscribe_mode", "ss_basic_online_links_goss", "ss_basic_node_update", "ss_basic_node_update_day", "ss_basic_node_update_hr", "ss_basic_exclude", "ss_basic_include", "ss_acl_default_port", "ss_acl_default_mode", "ss_basic_kcp_method", "ss_basic_kcp_password", "ss_basic_kcp_mode", "ss_basic_kcp_encrypt", "ss_basic_kcp_mtu", "ss_basic_kcp_sndwnd", "ss_basic_kcp_rcvwnd", "ss_basic_kcp_conn", "ss_basic_kcp_extra", "ss_basic_udp_software", "ss_basic_udp_node", "ss_basic_udpv1_lserver", "ss_basic_udpv1_lport", "ss_basic_udpv1_rserver", "ss_basic_udpv1_rport", "ss_basic_udpv1_password", "ss_basic_udpv1_mode", "ss_basic_udpv1_duplicate_nu", "ss_basic_udpv1_duplicate_time", "ss_basic_udpv1_jitter", "ss_basic_udpv1_report", "ss_basic_udpv1_drop", "ss_basic_udpv2_lserver", "ss_basic_udpv2_lport", "ss_basic_udpv2_rserver", "ss_basic_udpv2_rport", "ss_basic_udpv2_password", "ss_basic_udpv2_fec", "ss_basic_udpv2_timeout", "ss_basic_udpv2_mode", "ss_basic_udpv2_report", "ss_basic_udpv2_mtu", "ss_basic_udpv2_jitter", "ss_basic_udpv2_interval", "ss_basic_udpv2_drop", "ss_basic_udpv2_other", "ss_basic_udp2raw_lserver", "ss_basic_udp2raw_lport", "ss_basic_udp2raw_rserver", "ss_basic_udp2raw_rport", "ss_basic_udp2raw_password", "ss_basic_udp2raw_rawmode", "ss_basic_udp2raw_ciphermode", "ss_basic_udp2raw_authmode", "ss_basic_udp2raw_lowerlevel", "ss_basic_udp2raw_other", "ss_basic_udp_upstream_mtu", "ss_basic_udp_upstream_mtu_value", "ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_time_hour", "ss_basic_time_min", "ss_basic_tri_reboot_time", "ss_basic_server_resolv", "ss_basic_server_resolv_user", "ss_basic_pingm", "ss_basic_wt_furl", "ss_basic_wt_curl", "ss_basic_lt_cru_opts", "ss_basic_lt_cru_time", "ss_basic_hy2_up_speed", "ss_basic_hy2_dl_speed", "ss_basic_hy2_tfo_switch"];
	var params_check = ["ss_failover_enable", "ss_failover_c1", "ss_failover_c2", "ss_failover_c3", "ss_adv_sub", "ss_basic_tablet", "ss_basic_noserver", "ss_basic_dragable", "ss_basic_qrcode", "ss_basic_enable", "ss_basic_gfwlist_update", "ss_basic_tfo", "ss_basic_tnd", "ss_basic_vcore", "ss_basic_tcore", "ss_basic_xguard", "ss_basic_rust", "ss_basic_tjai", "ss_basic_nonetcheck", "ss_basic_notimecheck", "ss_basic_nochnipcheck", "ss_basic_nofrnipcheck", "ss_basic_noruncheck", "ss_basic_nofdnscheck", "ss_basic_nocdnscheck", "ss_basic_olddns", "ss_basic_advdns", "ss_basic_chnroute_update", "ss_basic_cdn_update", "ss_basic_kcp_nocomp", "ss_basic_udp_boost_enable", "ss_basic_udpv1_disable_filter", "ss_basic_udpv2_disableobscure", "ss_basic_udpv2_disablechecksum", "ss_basic_udp2raw_boost_enable", "ss_basic_udp2raw_a", "ss_basic_udp2raw_keeprule", "ss_basic_dns_hijack", "ss_basic_chng_no_ipv6", "ss_basic_chng_act", "ss_basic_chng_gt", "ss_basic_chng_mc", "ss_basic_mcore", "ss_basic_dohc_proxy", "ss_basic_dohc_ecs_china", "ss_basic_dohc_ecs_foreign", "ss_basic_dohc_cache_reuse", "ss_basic_chng_china_1_enable", "ss_basic_chng_china_2_enable", "ss_basic_chng_china_1_ecs", "ss_basic_chng_trust_1_enable", "ss_basic_chng_trust_2_enable", "ss_basic_chng_china_2_ecs", "ss_basic_chng_trust_1_ecs", "ss_basic_chng_trust_2_ecs", "ss_basic_proxy_newb", "ss_basic_udpoff", "ss_basic_udpall", "ss_basic_udpgpt"];
	var params_base64 = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links", "ss_basic_custom"];
	var params_no_store = ["ss_base64_links"];
	//---------------------------------------------------------------
	// collect data from input
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			dbus[params_input[i]] = E(params_input[i]).value;
		}
	}
	dbus["ss_basic_exclude"] = E("ss_basic_exclude").value.replace(pattern,"") || "";
	dbus["ss_basic_include"] = E("ss_basic_include").value.replace(pattern,"") || "";
	// collect data from checkbox
	for (var i = 0; i < params_check.length; i++) {
		dbus[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	// data need base64 encode, format b with plain text
	for (var i = 0; i < params_base64.length; i++) {
		dbus[params_base64[i]] = Base64.encode(E(params_base64[i]).value);
	}
	// collect values in acl table
	if(E("ACL_table")){
		var tr = E("ACL_table").getElementsByTagName("tr");
		for (var i = 1; i < tr.length - 1; i++) {
			var rowid = tr[i].getAttribute("id").split("_")[2];
			dbus["ss_acl_name_" + rowid] = E("ss_acl_name_" + rowid).value;
			dbus["ss_acl_mode_" + rowid] = E("ss_acl_mode_" + rowid).value;
			dbus["ss_acl_port_" + rowid] = E("ss_acl_port_" + rowid).value;
		}
	}
	// node data: write node data under using from the main pannel incase of data change
	dbus["ssconf_basic_mode_" + node_sel] = E("ss_basic_mode").value;
	// ss
	if (db_ss["ssconf_basic_type_" + node_sel] =="0" ){
		var params_ssi_1 = ["mode", "server", "port", "method", "ss_obfs_host", "ss_v2ray_opts"];
		var params_ssi_2 = ["ss_obfs", "ss_v2ray"];
		var params_ssc_1 = ["use_kcp"]; //fancyss-full
		dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
		for (var i = 0; i < params_ssi_1.length; i++) {
			dbus["ssconf_basic_" + params_ssi_1[i] + "_" + node_sel] = E("ss_basic_" + params_ssi_1[i]).value;
		}
		for (var i = 0; i < params_ssi_2.length; i++) {
			if (E("ss_basic_" + params_ssi_2[i]).value != "0"){
				dbus["ssconf_basic_" + params_ssi_2[i] + "_" + node_sel] = E("ss_basic_" + params_ssi_2[i]).value;
			}else{
				if(db_ss["ssconf_basic_" + params_ssi_2[i] + "_" + node_sel]){
					dbus["ssconf_basic_" + params_ssi_2[i] + "_" + node_sel] = "";
				}
			}
		}
		for (var i = 0; i < params_ssc_1.length; i++) {																			 //fancyss-full
			dbus["ssconf_basic_" + params_ssc_1[i] + "_" + node_sel] = E("ss_basic_" + params_ssc_1[i]).checked ? '1' : '';		 //fancyss-full
		}																														 //fancyss-full
	}
	// ssr
	if (db_ss["ssconf_basic_type_" + node_sel] =="1" ){
		var params_sri_1 = ["mode", "server", "port", "method", "rss_obfs", "rss_protocol", "rss_obfs_param", "rss_protocol_param"];
		var params_src_1 = ["use_kcp"];																							 //fancyss-full
		dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
		for (var i = 0; i < params_sri_1.length; i++) {
			dbus["ssconf_basic_" + params_sri_1[i] + "_" + node_sel] = E("ss_basic_" + params_sri_1[i]).value;
		}
		for (var i = 0; i < params_src_1.length; i++) {																			 //fancyss-full
			if (E("ss_basic_" + params_src_1[i]).checked ? '1' : '0' != "0"){													 //fancyss-full
				dbus["ssconf_basic_" + params_src_1[i] + "_" + node_sel] = E("ss_basic_" + params_src_1[i]).checked ? '1' : '';	 //fancyss-full
			}																													 //fancyss-full
		}																														 //fancyss-full
	}
	//v2ray
	if (db_ss["ssconf_basic_type_" + node_sel] =="3" ){
		// for v2ray json, we need to encode json format
		if (E("ss_basic_v2ray_use_json").checked == true){
			var params_vr_more = ["server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http"];
			for (var i = 0; i < params_vr_more.length; i++) {
				dbus["ssconf_basic_" + params_vr_more[i] + "_" + node_sel] = "";
			}
			dbus["ssconf_basic_v2ray_use_json_" + node_sel] = "1";
			if(isJSON(E('ss_basic_v2ray_json').value)){
				if(E('ss_basic_v2ray_json').value.indexOf("outbound") != -1){
					dbus["ssconf_basic_v2ray_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
				}else{
					alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
					return false;
				}
			}else{
				alert("错误！检测到你输入的v2ray配置不是标准json格式！");
				return false;
			}
		}else{
			dbus["ssconf_basic_v2ray_json_" + node_sel] = "";
			dbus["ssconf_basic_v2ray_use_json_" + node_sel] = "0";
			dbus["ssconf_basic_server_" + node_sel] = E("ss_basic_server").value;
			dbus["ssconf_basic_port_" + node_sel] = E("ss_basic_port").value;
			dbus["ssconf_basic_v2ray_uuid_" + node_sel] = E("ss_basic_v2ray_uuid").value;
			dbus["ssconf_basic_v2ray_alterid_" + node_sel] = E("ss_basic_v2ray_alterid").value;
			dbus["ssconf_basic_v2ray_security_" + node_sel] = E("ss_basic_v2ray_security").value;
			dbus["ssconf_basic_v2ray_network_" + node_sel] = E("ss_basic_v2ray_network").value;
			if(E("ss_basic_v2ray_network").value == "tcp"){
				dbus["ssconf_basic_v2ray_headtype_tcp_" + node_sel] = E("ss_basic_v2ray_headtype_tcp").value;
				if(E("ss_basic_v2ray_headtype_tcp").value == "http"){
					dbus["ssconf_basic_v2ray_network_host_" + node_sel] = E("ss_basic_v2ray_network_host").value;
					dbus["ssconf_basic_v2ray_network_path_" + node_sel] = E("ss_basic_v2ray_network_path").value;
				}
			}
			if(E("ss_basic_v2ray_network").value == "kcp"){
				dbus["ssconf_basic_v2ray_headtype_kcp_" + node_sel] = E("ss_basic_v2ray_headtype_kcp").value;
				dbus["ssconf_basic_v2ray_kcp_seed_" + node_sel] = E("ss_basic_v2ray_kcp_seed").value;
			}
			if(E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2"){
				dbus["ssconf_basic_v2ray_network_host_" + node_sel] = E("ss_basic_v2ray_network_host").value;
				dbus["ssconf_basic_v2ray_network_path_" + node_sel] = E("ss_basic_v2ray_network_path").value;
			}
			if(E("ss_basic_v2ray_network").value == "quic"){
				dbus["ssconf_basic_v2ray_headtype_quic_" + node_sel] = E("ss_basic_v2ray_headtype_quic").value;
				dbus["ssconf_basic_v2ray_network_host_" + node_sel] = E("ss_basic_v2ray_network_host").value;
				dbus["ssconf_basic_v2ray_network_path_" + node_sel] = E("ss_basic_v2ray_network_path").value;
			}
			if(E("ss_basic_v2ray_network").value == "grpc"){
				dbus["ssconf_basic_v2ray_grpc_mode_" + node_sel] = E("ss_basic_v2ray_grpc_mode").value;
				dbus["ssconf_basic_v2ray_network_path_" + node_sel] = E("ss_basic_v2ray_network_path").value;
			}
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = E("ss_basic_v2ray_network_security").value;
			if(E("ss_basic_v2ray_network_security").value == "tls"){
				dbus["ssconf_basic_v2ray_network_security_ai_" + node_sel] = E("ss_basic_v2ray_network_security_ai").checked ? '1' : '';
				dbus["ssconf_basic_v2ray_network_security_alpn_h2_" + node_sel] = E("ss_basic_v2ray_network_security_alpn_h2").checked ? '1' : '';
				dbus["ssconf_basic_v2ray_network_security_alpn_http_" + node_sel] = E("ss_basic_v2ray_network_security_alpn_http").checked ? '1' : '';
				dbus["ssconf_basic_v2ray_network_security_sni_" + node_sel] = E("ss_basic_v2ray_network_security_sni").value;
			}else{
				dbus["ssconf_basic_v2ray_network_security_ai_" + node_sel] = "";
				dbus["ssconf_basic_v2ray_network_security_alpn_h2_" + node_sel] = "";
				dbus["ssconf_basic_v2ray_network_security_alpn_http_" + node_sel] = "";
				dbus["ssconf_basic_v2ray_network_security_sni_" + node_sel] = "";
			}
			dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = E("ss_basic_v2ray_mux_enable").checked ? '1' : '';
			if(E("ss_basic_v2ray_mux_enable").checked == false){
				dbus["ssconf_basic_v2ray_mux_concurrency_" + node_sel] = "";
			}else{
				dbus["ssconf_basic_v2ray_mux_concurrency_" + node_sel] = E("ss_basic_v2ray_mux_concurrency").value;
			}
		}
	}
	//xray
	if (db_ss["ssconf_basic_type_" + node_sel] =="4" ){
		// for xray json, we need to encode json format
		if (E("ss_basic_xray_use_json").checked == true){
			var params_xr_more = ["server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http"];
			for (var i = 0; i < params_xr_more.length; i++) {
				dbus["ssconf_basic_" + params_xr_more[i] + "_" + node_sel] = "";
			}
			dbus["ssconf_basic_xray_use_json_" + node_sel] = "1";
			if(isJSON(E('ss_basic_xray_json').value)){
				if(E('ss_basic_xray_json').value.indexOf("outbound") != -1){
					dbus["ssconf_basic_xray_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_xray_json').value));
				}else{
					alert("错误！你的json配置文件有误！请修复错误后重试！");
					return false;
				}
			}else{
				alert("错误！检测到你输入的xray配置不是标准json格式！");
				return false;
			}
		}else{
			dbus["ssconf_basic_xray_json_" + node_sel] = "";
			dbus["ssconf_basic_xray_use_json_" + node_sel] = "";
			dbus["ssconf_basic_server_" + node_sel] = E("ss_basic_server").value;
			dbus["ssconf_basic_port_" + node_sel] = E("ss_basic_port").value;
			dbus["ssconf_basic_xray_uuid_" + node_sel] = E("ss_basic_xray_uuid").value;
			dbus["ssconf_basic_xray_encryption_" + node_sel] = E("ss_basic_xray_encryption").value;
			dbus["ssconf_basic_xray_network_" + node_sel] = E("ss_basic_xray_network").value;
			if(E("ss_basic_xray_network").value == "tcp"){
				dbus["ssconf_basic_xray_headtype_tcp_" + node_sel] = E("ss_basic_xray_headtype_tcp").value;
				if(E("ss_basic_xray_headtype_tcp").value == "http"){
					dbus["ssconf_basic_xray_network_host_" + node_sel] = E("ss_basic_xray_network_host").value;
					dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
				}
			}
			if(E("ss_basic_xray_network").value == "kcp"){
				dbus["ssconf_basic_xray_headtype_kcp_" + node_sel] = E("ss_basic_xray_headtype_kcp").value;
				dbus["ssconf_basic_xray_kcp_seed_" + node_sel] = E("ss_basic_xray_kcp_seed").value;
			}
			if(E("ss_basic_xray_network").value == "ws" || E("ss_basic_xray_network").value == "h2"){
				dbus["ssconf_basic_xray_network_host_" + node_sel] = E("ss_basic_xray_network_host").value;
				dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
			}
			if(E("ss_basic_xray_network").value == "quic"){
				dbus["ssconf_basic_xray_headtype_quic_" + node_sel] = E("ss_basic_xray_headtype_quic").value;
				dbus["ssconf_basic_xray_network_host_" + node_sel] = E("ss_basic_xray_network_host").value;
				dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
			}
			if(E("ss_basic_xray_network").value == "grpc"){
				dbus["ssconf_basic_xray_grpc_mode_" + node_sel] = E("ss_basic_xray_grpc_mode").value;
				dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
			}
			dbus["ssconf_basic_xray_network_security_" + node_sel] = E("ss_basic_xray_network_security").value;
			dbus["ssconf_basic_xray_network_security_sni_" + node_sel] = E("ss_basic_xray_network_security_sni").value;
			if(E("ss_basic_xray_network_security").value == "tls" || E("ss_basic_xray_network_security").value == "xtls"){
				if(E("ss_basic_xray_network").value == "tcp"){
					dbus["ssconf_basic_xray_flow_" + node_sel] = E("ss_basic_xray_flow").value;
				}else{
					dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				}
				dbus["ssconf_basic_xray_network_security_ai_" + node_sel] = E("ss_basic_xray_network_security_ai").checked ? '1' : '';
				dbus["ssconf_basic_xray_network_security_alpn_h2_" + node_sel] = E("ss_basic_xray_network_security_alpn_h2").checked ? '1' : '';
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = E("ss_basic_xray_network_security_alpn_http").checked ? '1' : '';
				dbus["ssconf_basic_xray_fingerprint_" + node_sel] = E("ss_basic_xray_fingerprint").value;
			}else{
				dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_ai_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_h2_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = "";
			}
			if(E("ss_basic_xray_network_security").value == "reality"){
				dbus["ssconf_basic_xray_flow_" + node_sel] = E("ss_basic_xray_flow").value;
				dbus["ssconf_basic_xray_show_" + node_sel] = E("ss_basic_xray_show").checked ? '1' : '';
				dbus["ssconf_basic_xray_fingerprint_" + node_sel] = E("ss_basic_xray_fingerprint").value;
				dbus["ssconf_basic_xray_publickey_" + node_sel] = E("ss_basic_xray_publickey").value;
				dbus["ssconf_basic_xray_shortid_" + node_sel] = E("ss_basic_xray_shortid").value;
				dbus["ssconf_basic_xray_spiderx_" + node_sel] = E("ss_basic_xray_spiderx").value;
				if(E("ss_basic_xray_network").value == "grpc"){
					dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				}
			}
		}
	}
	// trojan
	if (db_ss["ssconf_basic_type_" + node_sel] =="5" ){
		var params_tj_1 = ["mode", "server", "port", "trojan_uuid", "trojan_sni"];
		dbus["ssconf_basic_trojan_ai_" + node_sel] = E("ss_basic_trojan_ai").checked ? '1' : '';
		dbus["ssconf_basic_trojan_tfo_" + node_sel] = E("ss_basic_trojan_tfo").checked ? '1' : '';
		for (var i = 0; i < params_tj_1.length; i++) {
			dbus["ssconf_basic_" + params_tj_1[i] + "_" + node_sel] = E("ss_basic_" + params_tj_1[i]).value;
		}
	}
	// fancyss_full_1
	// naive
	if (db_ss["ssconf_basic_type_" + node_sel] =="6" ){
		dbus["ssconf_basic_naive_pass_" + node_sel] = Base64.encode(E("ss_basic_naive_pass").value);
		var params_naive_1 = ["mode", "naive_prot", "naive_server", "naive_port", "naive_user"];
		for (var i = 0; i < params_naive_1.length; i++) {
			dbus["ssconf_basic_" + params_naive_1[i] + "_" + node_sel] = E("ss_basic_" + params_naive_1[i]).value;
		}
	}
	// tuic
	if (db_ss["ssconf_basic_type_" + node_sel] =="7" ){
		dbus["ssconf_basic_naive_pass_" + node_sel] = Base64.encode(E("ss_basic_naive_pass").value);
		var params_tuic_1 = ["mode"];
		for (var i = 0; i < params_tuic_1.length; i++) {
			dbus["ssconf_basic_" + params_tuic_1[i] + "_" + node_sel] = E("ss_basic_" + params_tuic_1[i]).value;
		}
		if(isJSON(E('ss_basic_tuic_json').value)){
			if(E('ss_basic_tuic_json').value.indexOf("relay") != -1){
				dbus["ssconf_basic_tuic_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_tuic_json').value));
			}else{
				alert("错误！你的json配置文件有误！请修复错误后重试！");
				return false;
			}
		}else{
			alert("错误！检测到你输入的xray配置不是标准json格式！");
			return false;
		}
	}
	// hysteria2
	if (db_ss["ssconf_basic_type_" + node_sel] =="8" ){
		var params_hy2_1 = ["mode", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni"];
		for (var i = 0; i < params_hy2_1.length; i++) {
			dbus["ssconf_basic_" + params_hy2_1[i] + "_" + node_sel] = E("ss_basic_" + params_hy2_1[i]).value;
		}
		dbus["ssconf_basic_hy2_ai_" + node_sel] = E("ss_basic_hy2_ai").checked ? '1' : '';
		dbus["ssconf_basic_hy2_tfo_" + node_sel] = E("ss_basic_hy2_tfo").checked ? '1' : '';
	}
	// fancyss_full_2
	// show different title when subscribe
	if(E("ss_basic_enable").checked){
		var sel_mode = E("ss_basic_mode").value;
		if (sel_mode == "1") {
			db_ss["ss_basic_action"] = "1";
		} else if (sel_mode == "2") {
			db_ss["ss_basic_action"] = "2";
		} else if (sel_mode == "3") {
			db_ss["ss_basic_action"] = "3";
		} else if (sel_mode == "5") {
			db_ss["ss_basic_action"] = "5";
		} else if (sel_mode == "6") {
			db_ss["ss_basic_action"] = "6";
		}
	}else{
		db_ss["ss_basic_action"] = "0";
	}
	//---------------------------------------------------------------
	var post_dbus = compfilter(db_ss, dbus);
	//console.log("post_dbus", post_dbus);

	if(dbus["ss_basic_enable"] == "1"){
		if(ws_flag == 1){
			//console.log("push_data_ws");
			push_data_ws("ss_config.sh", "start",  post_dbus);
		}else{
			//console.log("push_data_httpd");
			push_data("ss_config.sh", "start",  post_dbus);
		}
	}else{
		if(ws_flag == 1){
			push_data_ws("ss_config.sh", "stop",  post_dbus);
		}else{
			push_data("ss_config.sh", "stop",  post_dbus);
		}
	}
}
function push_data_ws(script, arg, obj, flag){
	// just push data, show log through ws
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": obj};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			if(response.result == id){
				// run command through ws
				ws = new WebSocket("ws://" + hostname + ":803/");
				ws.onopen = function() {
					//console.log('ws：成功建立websocket链接，开始获取启动日志...');
					ws.send(". " + script + " " + arg);
					showSSLoadingBar();
				};
				//ws.onclose = function() {
				//	console.log('ws： DISCONNECT');
				//};
				ws.onerror = function(event) {
					// fallback to httpd method
					//console.log('WS Error: ' + event.data);
					push_data(script, arg, obj, flag);
				};
				ws.onmessage = function(event) {
					if(event.data != "XU6J03M6"){
						E('log_content3').value += event.data + '\n';
					}else{
						E("ok_button").style.display = "";
						count_down_close();
						ws.close();
					}
					E("log_content3").scrollTop = E("log_content3").scrollHeight;
				};
			}
		}
	});
}
function push_data(script, arg, obj, flag){
	if (!flag) showSSLoadingBar();
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": script, "params":[arg], "fields": obj};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			if(response.result == id){
				if(flag && flag == "1"){
					refreshpage();
				}else if(flag && flag == "2"){
					//continue;
					//do nothing
				}else{
					get_realtime_log();
				}
			}
		}
	});
}
function verifyFields(r) {
	var node_sel = E("ssconf_basic_node").value;
	var ss_on = false;
	var ssr_on = false;
	var v2ray_on = false;
	var xray_on = false;
	var trojan_on = false;
	var naive_on = false;	//fancyss-full
	var tuic_on = false;	//fancyss-full
	var hy2_on = false;		//fancyss-full
	var node_type = db_ss["ssconf_basic_type_" + node_sel] || "0";
	if (node_type == "0") {
		// ss
		var ss_on = true;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = false;		//fancyss-full
	}
	else if (node_type == "1") {
		// ssr
		var ss_on = false;
		var ssr_on = true;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = false;		//fancyss-full
	}
	else if (node_type == "3") {
		// v2ray
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = true;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = false;		//fancyss-full
	}
	else if (node_type == "4") {
		// xray
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = true;
		var trojan_on = false;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = false;		//fancyss-full
	}
	else if (node_type == "5") {
		// trojan
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = true;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = false;
	}
	//fancyss_naive_1
	else if (node_type == "6") {
		// naive
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = true;
		var tuic_on = false;
		var hy2_on = false;
	}
	//fancyss_naive_2
	//fancyss_tuic_1
	else if (node_type == "7") {
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;
		var tuic_on = true;
		var hy2_on = false;
	}
	//fancyss_tuic_2
	//fancyss_hy2_1
	else if (node_type == "8") {
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;
		var tuic_on = false;
		var hy2_on = true;
	}
	//fancyss_hy2_2
	var v_json_on = E("ss_basic_v2ray_use_json").checked == true;
	var v_json_off = E("ss_basic_v2ray_use_json").checked == false;
	var v_http_on = E("ss_basic_v2ray_network").value == "tcp" && E("ss_basic_v2ray_headtype_tcp").value == "http";
	var v_host_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || E("ss_basic_v2ray_network").value == "quic" || v_http_on;
	var v_path_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || E("ss_basic_v2ray_network").value == "quic" || E("ss_basic_v2ray_network").value == "grpc" || v_http_on;
	var v_tls_on = E("ss_basic_v2ray_network_security").value == "tls";
	var v_grpc_on = E("ss_basic_v2ray_network").value == "grpc";
	var x_json_on = E("ss_basic_xray_use_json").checked == true;
	var x_json_off = E("ss_basic_xray_use_json").checked == false;
	var x_http_on = E("ss_basic_xray_network").value == "tcp" && E("ss_basic_xray_headtype_tcp").value == "http";
	var x_host_on = E("ss_basic_xray_network").value == "ws" || E("ss_basic_xray_network").value == "h2" || E("ss_basic_xray_network").value == "quic" || x_http_on;
	var x_path_on = E("ss_basic_xray_network").value == "ws" || E("ss_basic_xray_network").value == "h2" || E("ss_basic_xray_network").value == "quic" || E("ss_basic_xray_network").value == "grpc" || x_http_on;
	var x_tls_on = E("ss_basic_xray_network_security").value == "tls" || E("ss_basic_xray_network_security").value == "xtls";
	var x_xtls_on = E("ss_basic_xray_network_security").value == "xtls";
	var x_real_on = E("ss_basic_xray_network_security").value == "reality";
	var x_tcp_on = E("ss_basic_xray_network").value == "tcp";
	var x_grpc_on = E("ss_basic_xray_network").value == "grpc";
	//ss
	elem.display(elem.parentElem('ss_basic_ss_obfs', 'tr'), ss_on);
	elem.display(elem.parentElem('ss_basic_ss_obfs_host', 'tr'), (ss_on && E("ss_basic_ss_obfs").value != "0"));
	elem.display(elem.parentElem('ss_basic_ss_v2ray', 'tr'), ss_on);												//fancyss-full
	elem.display(elem.parentElem('ss_basic_ss_v2ray_opts', 'tr'), (ss_on && E("ss_basic_ss_v2ray").value != "0"));	//fancyss-full
	//ssr-libev
	elem.display(elem.parentElem('ss_basic_rss_protocol_param', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_protocol', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_obfs', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_obfs_param', 'tr'), ssr_on);
	//basic
	elem.display(elem.parentElem('ss_basic_server', 'tr'), ss_on || ssr_on || (v2ray_on && v_json_off) || (xray_on && x_json_off) || trojan_on);
	elem.display(elem.parentElem('ss_basic_port', 'tr'), ss_on || ssr_on || (v2ray_on && v_json_off) || (xray_on && x_json_off) || trojan_on);
	//elem.display(elem.parentElem('ss_basic_password', 'tr'), !v2ray_on && ! xray_on && ! trojan_on && ! naive_on);
	//elem.display(elem.parentElem('ss_basic_method', 'tr'), !v2ray_on && ! xray_on && ! trojan_on && ! naive_on);
	elem.display(elem.parentElem('ss_basic_password', 'tr'), ss_on || ssr_on);
	elem.display(elem.parentElem('ss_basic_method', 'tr'), ss_on || ssr_on);
	//v2ray
	elem.display(elem.parentElem('ss_basic_v2ray_use_json', 'tr'), v2ray_on);
	elem.display(elem.parentElem('ss_basic_v2ray_uuid', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_alterid', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_security', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_network', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_headtype_tcp', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_network").value == "tcp"));
	elem.display(elem.parentElem('ss_basic_v2ray_headtype_kcp', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_network").value == "kcp"));
	elem.display(elem.parentElem('ss_basic_v2ray_kcp_seed', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_network").value == "kcp"));
	elem.display(elem.parentElem('ss_basic_v2ray_headtype_quic', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_network").value == "quic"));
	elem.display(elem.parentElem('ss_basic_v2ray_grpc_mode', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_network").value == "grpc"));
	elem.display(elem.parentElem('ss_basic_v2ray_network_host', 'tr'), (v2ray_on && v_json_off && v_host_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_path', 'tr'), (v2ray_on && v_json_off && v_path_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_security', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_network_security_ai', 'tr'), (v2ray_on && v_json_off && v_tls_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_security_alpn_h2', 'tr'), (v2ray_on && v_json_off && v_tls_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_security_sni', 'tr'), (v2ray_on && v_json_off && v_tls_on));
	elem.display(elem.parentElem('ss_basic_v2ray_mux_enable', 'tr'), (v2ray_on && v_json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_mux_concurrency', 'tr'), (v2ray_on && v_json_off && E("ss_basic_v2ray_mux_enable").checked));
	elem.display(elem.parentElem('ss_basic_v2ray_json', 'tr'), (v2ray_on && v_json_on));
	elem.display('v2ray_binary_update_tr', v2ray_on);		//fancyss-full
	if(v_grpc_on){
		$('#ss_basic_v2ray_network_path_tr > th > a').html('* serviceName');
	}else{
		$('#ss_basic_v2ray_network_path_tr > th > a').html('* 路径 (path)');
	}
	//xray
	elem.display(elem.parentElem('ss_basic_xray_use_json', 'tr'), xray_on);
	elem.display(elem.parentElem('ss_basic_xray_uuid', 'tr'), (xray_on && x_json_off));
	elem.display(elem.parentElem('ss_basic_xray_encryption', 'tr'), (xray_on && x_json_off));
	elem.display(elem.parentElem('ss_basic_xray_flow', 'tr'), (xray_on && x_json_off && (x_tls_on && x_tcp_on || x_real_on && x_tcp_on)));
	elem.display(elem.parentElem('ss_basic_xray_network', 'tr'), (xray_on && x_json_off));
	elem.display(elem.parentElem('ss_basic_xray_headtype_tcp', 'tr'), (xray_on && x_json_off && E("ss_basic_xray_network").value == "tcp"));
	elem.display(elem.parentElem('ss_basic_xray_headtype_kcp', 'tr'), (xray_on && x_json_off && E("ss_basic_xray_network").value == "kcp"));
	elem.display(elem.parentElem('ss_basic_xray_kcp_seed', 'tr'), (xray_on && v_json_off && E("ss_basic_xray_network").value == "kcp"));
	elem.display(elem.parentElem('ss_basic_xray_headtype_quic', 'tr'), (xray_on && x_json_off && E("ss_basic_xray_network").value == "quic"));
	elem.display(elem.parentElem('ss_basic_xray_grpc_mode', 'tr'), (xray_on && x_json_off && x_grpc_on));
	elem.display(elem.parentElem('ss_basic_xray_network_host', 'tr'), (xray_on && x_json_off && x_host_on));
	elem.display(elem.parentElem('ss_basic_xray_network_path', 'tr'), (xray_on && x_json_off && x_path_on));
	elem.display(elem.parentElem('ss_basic_xray_network_security', 'tr'), (xray_on && x_json_off));
	elem.display(elem.parentElem('ss_basic_xray_network_security_ai', 'tr'), (xray_on && x_json_off && x_tls_on));
	elem.display(elem.parentElem('ss_basic_xray_network_security_alpn_h2', 'tr'), (xray_on && x_json_off && x_tls_on));
	elem.display(elem.parentElem('ss_basic_xray_network_security_sni', 'tr'), (xray_on && x_json_off && (x_tls_on || x_real_on)));
	elem.display(elem.parentElem('ss_basic_xray_fingerprint', 'tr'), (xray_on && x_json_off && (x_tls_on || x_real_on)));
	elem.display(elem.parentElem('ss_basic_xray_show', 'tr'), (xray_on && x_json_off && x_real_on));
	elem.display(elem.parentElem('ss_basic_xray_publickey', 'tr'), (xray_on && x_json_off && x_real_on));
	elem.display(elem.parentElem('ss_basic_xray_shortid', 'tr'), (xray_on && x_json_off && x_real_on));
	elem.display(elem.parentElem('ss_basic_xray_spiderx', 'tr'), (xray_on && x_json_off && x_real_on));
	elem.display(elem.parentElem('ss_basic_xray_json', 'tr'), (xray_on && x_json_on));
	elem.display('xray_binary_update_tr', xray_on);
	if(x_grpc_on){
		$('#ss_basic_xray_network_path_tr > th > a').html('* serviceName');
	}else{
		$('#ss_basic_xray_network_path_tr > th > a').html('* 路径 (path)');
	}
	//trojan
	elem.display(elem.parentElem('ss_basic_trojan_uuid', 'tr'), (trojan_on));
	elem.display(elem.parentElem('ss_basic_trojan_ai', 'tr'), (trojan_on));
	elem.display(elem.parentElem('ss_basic_trojan_sni', 'tr'), (trojan_on));
	elem.display(elem.parentElem('ss_basic_trojan_tfo', 'tr'), (trojan_on));
	//naive
	elem.display(elem.parentElem('ss_basic_naive_prot', 'tr'), (naive_on));		//fancyss-full
	elem.display(elem.parentElem('ss_basic_naive_server', 'tr'), (naive_on));	//fancyss-full
	elem.display(elem.parentElem('ss_basic_naive_port', 'tr'), (naive_on));		//fancyss-full
	elem.display(elem.parentElem('ss_basic_naive_user', 'tr'), (naive_on));		//fancyss-full
	elem.display(elem.parentElem('ss_basic_naive_pass', 'tr'), (naive_on));		//fancyss-full
	//tuic
	elem.display(elem.parentElem('ss_basic_tuic_json', 'tr'), tuic_on);			//fancyss-full
	//hy2
	elem.display(elem.parentElem('ss_basic_hy2_server', 'tr'), hy2_on);			//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_port', 'tr'), hy2_on);			//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_pass', 'tr'), hy2_on);			//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_up', 'tr'), hy2_on);				//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_dl', 'tr'), hy2_on);				//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_obfs', 'tr'), hy2_on);			//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_obfs_pass', 'tr'), hy2_on && E("ss_basic_hy2_obfs").value != "0");		//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_sni', 'tr'), hy2_on);			//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_ai', 'tr'), hy2_on);				//fancyss-full
	elem.display(elem.parentElem('ss_basic_hy2_tfo', 'tr'), hy2_on);			//fancyss-full
	if (E("ss_basic_tjai").checked == true){
		E("ss_basic_trojan_ai").disabled = true;
		E("ss_basic_trojan_ai_note").innerHTML = "已全局跳过证书验证";
	}
	if (save_flag == "shadowsocks") {
		showhide("ss_obfs_host_support", $("#ss_node_table_ss_obfs").val() != "0");
		showhide("ss_v2ray_opts_support", $("#ss_node_table_ss_v2ray").val() != "0");	//fancyss-full
	}
	if (save_flag == "v2ray") {
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			$(".v2ray_elem").hide();
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('v2ray_headtype_quic_tr').style.display = "none";
			E('v2ray_grpc_mode_tr').style.display = "none";
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_kcp_seed_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('v2ray_network_security_ai_tr').style.display = "none";
			E('v2ray_network_security_alpn_tr').style.display = "none";
			E('v2ray_network_security_sni_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			$(".v2ray_elem").show();
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('v2ray_headtype_quic_tr').style.display = "";
			E('v2ray_grpc_mode_tr').style.display = "";
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_kcp_seed_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "";
			E('v2ray_network_security_ai_tr').style.display = "none";
			E('v2ray_network_security_alpn_tr').style.display = "none";
			E('v2ray_network_security_sni_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var v_tcp_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var v_http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var v_host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || E("ss_node_table_v2ray_network").value == "quic" || v_http_on_2;
			var v_path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || E("ss_node_table_v2ray_network").value == "quic" || E("ss_node_table_v2ray_network").value == "grpc" || v_http_on_2;
			var v_tls_on_2 = E("ss_node_table_v2ray_network_security").value == "tls" || E("ss_node_table_v2ray_network_security").value == "xtls";
			showhide("v2ray_headtype_tcp_tr", v_tcp_on_2);
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_kcp_seed_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_headtype_quic_tr", (E("ss_node_table_v2ray_network").value == "quic"));
			showhide("v2ray_grpc_mode_tr", (E("ss_node_table_v2ray_network").value == "grpc"));
			showhide("v2ray_network_host_tr", v_host_on_2);
			showhide("v2ray_network_path_tr", v_path_on_2);
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
			showhide("v2ray_network_security_ai_tr", v_tls_on_2);
			showhide("v2ray_network_security_alpn_tr", v_tls_on_2);
			showhide("v2ray_network_security_sni_tr", v_tls_on_2);
		}
	}
	if (save_flag == "xray") {
		if(E("ss_node_table_xray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('xray_uuid_tr').style.display = "none";
			$(".xray_elem").hide();
			E('xray_encryption_tr').style.display = "none";
			E('xray_flow_tr').style.display = "none";
			E('xray_show_tr').style.display = "none";
			E('xray_publickey_tr').style.display = "none";
			E('xray_shortid_tr').style.display = "none";
			E('xray_spiderx_tr').style.display = "none";
			E('xray_network_tr').style.display = "none";
			E('xray_headtype_tcp_tr').style.display = "none";
			E('xray_headtype_kcp_tr').style.display = "none";
			E('xray_headtype_quic_tr').style.display = "none";
			E('xray_grpc_mode_tr').style.display = "none";
			E('xray_network_path_tr').style.display = "none";
			E('xray_network_host_tr').style.display = "none";
			E('xray_kcp_seed_tr').style.display = "none";
			E('xray_network_security_tr').style.display = "none";
			E('xray_network_security_ai_tr').style.display = "none";
			E('xray_network_security_alpn_tr').style.display = "none";
			E('xray_network_security_sni_tr').style.display = "none";
			E('xray_fingerprint_tr').style.display = "none";
			E('xray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('xray_uuid_tr').style.display = "";
			$(".xray_elem").show();
			E('xray_encryption_tr').style.display = "";
			E('xray_flow_tr').style.display = "";
			E('xray_show_tr').style.display = "";
			E('xray_publickey_tr').style.display = "";
			E('xray_shortid_tr').style.display = "";
			E('xray_spiderx_tr').style.display = "";
			E('xray_network_tr').style.display = "";
			E('xray_headtype_tcp_tr').style.display = "";
			E('xray_headtype_kcp_tr').style.display = "";
			E('xray_headtype_quic_tr').style.display = "";
			E('xray_grpc_mode_tr').style.display = "";
			E('xray_network_path_tr').style.display = "";
			E('xray_network_host_tr').style.display = "";
			E('xray_kcp_seed_tr').style.display = "none";
			E('xray_network_security_tr').style.display = "";
			E('xray_network_security_ai_tr').style.display = "";
			E('xray_network_security_alpn_tr').style.display = "";
			E('xray_network_security_sni_tr').style.display = "none";
			E('xray_fingerprint_tr').style.display = "none";
			E('xray_json_tr').style.display = "none";
			var x_http_on_2 = E("ss_node_table_xray_network").value == "tcp" && E("ss_node_table_xray_headtype_tcp").value == "http";
			var x_host_on_2 = E("ss_node_table_xray_network").value == "ws" || E("ss_node_table_xray_network").value == "h2" || E("ss_node_table_xray_network").value == "quic" || x_http_on_2;
			var x_path_on_2 = E("ss_node_table_xray_network").value == "ws" || E("ss_node_table_xray_network").value == "h2" || E("ss_node_table_xray_network").value == "quic" || E("ss_node_table_xray_network").value == "grpc" || x_http_on_2;
			var x_tls_on_2 = E("ss_node_table_xray_network_security").value == "tls" || E("ss_node_table_xray_network_security").value == "xtls";
			var x_xtls_on_2 = E("ss_node_table_xray_network_security").value == "xtls";
			var x_real_on_2 = E("ss_node_table_xray_network_security").value == "reality";
			var x_tcp_on_2 = E("ss_node_table_xray_network").value == "tcp"
			var x_grpc_on_2 = E("ss_node_table_xray_network").value == "grpc"
			showhide("xray_headtype_tcp_tr", x_tcp_on_2);
			showhide("xray_headtype_kcp_tr", (E("ss_node_table_xray_network").value == "kcp"));
			showhide("xray_kcp_seed_tr", (E("ss_node_table_xray_network").value == "kcp"));
			showhide("xray_headtype_quic_tr", (E("ss_node_table_xray_network").value == "quic"));
			showhide("xray_grpc_mode_tr", x_grpc_on_2);
			showhide("xray_network_host_tr", x_host_on_2);
			showhide("xray_network_path_tr", x_path_on_2);
			showhide("xray_json_tr", (E("ss_node_table_xray_use_json").checked));
			showhide("xray_network_security_ai_tr", x_tls_on_2);
			showhide("xray_network_security_alpn_tr", x_tls_on_2);
			showhide("xray_network_security_sni_tr", x_tls_on_2  || x_real_on_2);
			showhide("xray_fingerprint_tr", x_tls_on_2 || x_real_on_2);
			showhide("xray_flow_tr", x_tls_on_2 && x_tcp_on_2 || x_real_on_2 && x_tcp_on_2);
			showhide("xray_show_tr", x_real_on_2);
			showhide("xray_publickey_tr", x_real_on_2);
			showhide("xray_shortid_tr", x_real_on_2);
			showhide("xray_spiderx_tr", x_real_on_2);
			if(x_grpc_on_2){
				$('#xray_network_path_tr > th').html('* serviceName');
			}else{
				$('#xray_network_path_tr > th').html('* 路径 (path)');
			}
		}
	}
	//fancyss_hy2_1
	if (save_flag == "hysteria2") {
		showhide("hy2_obfs_pass_tr", $("#ss_node_table_hy2_obfs").val() != "0");
	}
	//fancyss_hy2_2
	//fancyss_full_1
	//kcp pannel
	var kcp_trs = ["ss_basic_kcp_password_tr", "ss_basic_kcp_mode_tr", "ss_basic_kcp_encrypt_tr", "ss_basic_kcp_mtu_tr", "ss_basic_kcp_sndwnd_tr", "ss_basic_kcp_rcvwnd_tr", "ss_basic_kcp_conn_tr", "ss_basic_kcp_nocomp_tr", "ss_basic_kcp_extra_tr"]
	if(E("ss_basic_kcp_method").value == "1"){
		E("ss_basic_kcp_parameter_tr").style.display = "none";
		for ( var i = 0; i < kcp_trs.length; i++){
			E(kcp_trs[i]).style.display = "";
		}
	}else{
		E("ss_basic_kcp_parameter_tr").style.display = "";
		for ( var i = 0; i < kcp_trs.length; i++){
			E(kcp_trs[i]).style.display = "none";
		}
	}
	//udp pannel
	if($('.sub-btn1').hasClass("active2")){
		$(".speeder").show();
		if (E("ss_basic_udp_software").value == "1"){
			$(".speederv1").show();
			$(".speederv2").hide();
			$(".udp2raw").hide();
		}
		if (E("ss_basic_udp_software").value == "2"){
			$(".speederv1").hide();
			$(".speederv2").show();
			$(".udp2raw").hide();
		}
	}else if($('.sub-btn2').hasClass("active2")){
		$(".udp2raw").show();
		$(".speeder").hide();
		$(".speederv1").hide();
		$(".speederv2").hide();
	}
	//fancyss_full_2
	// 插件重启功能
	var Ti = E("ss_reboot_check").value;
	var In = E("ss_basic_inter_pre").value;
	var items = ["re1", "re2", "re3", "re4", "re4_1", "re4_2", "re4_3", "re5"];
	for ( var i = 1; i < items.length; ++i ) $("." + items[i]).hide();
	if (Ti != "0") $(".re" + Ti).show();
	if (Ti == "4") $(".re4_" + In).show();
	// failover
	if(E("ss_failover_enable").checked){
		$("#interval_settings").show();
		$("#failover_settings_1").show();
		$("#failover_settings_2").show();
		$("#failover_settings_3").show();
	}else{
		$("#interval_settings").hide();
		$("#failover_settings_1").hide();
		$("#failover_settings_2").hide();
		$("#failover_settings_3").hide();
	}
	showhide("ss_failover_s4_2",  E("ss_failover_enable").checked && E("ss_failover_s4_1").value == "2");
	showhide("ss_failover_s4_3",  E("ss_failover_enable").checked && E("ss_failover_s4_1").value == "2" && E("ss_failover_s4_2").value == "1");
	// node sub pannel
	if(E("ss_adv_sub").checked == false){
		$("#ssr_subscribe_mode").parent().parent().hide();
		$("#ss_basic_online_links_goss").parent().parent().hide();
		$("#ss_basic_node_update").parent().parent().hide();
		$("#ss_basic_exclude").parent().parent().hide();
		$("#ss_basic_include").parent().parent().hide();
		$("#ss_basic_remove_node").hide();
		$("#ss_sub_save_only").hide();
	}else{
		$("#ssr_subscribe_mode").parent().parent().show();
		$("#ss_basic_online_links_goss").parent().parent().show();
		$("#ss_basic_node_update").parent().parent().show();
		$("#ss_basic_exclude").parent().parent().show();
		$("#ss_basic_include").parent().parent().show();
		$("#ss_basic_remove_node").show();
		$("#ss_sub_save_only").show();
	}
	// push on click
	var trid = $(r).attr("id")
	if ( trid == "ss_basic_qrcode" || trid == "ss_basic_dragable" || trid == "ss_basic_tablet" || trid == "ss_basic_noserver") {
		var dbus_post = {};
		dbus_post[trid] = E(trid).checked ? '1' : '0';
		push_data("dummy_script.sh", "", dbus_post, "1");
	}
	if ( $(r).attr("id") == "ss_adv_sub" ) {
		var dbus_post = {};
		dbus_post["ss_adv_sub"] = E("ss_adv_sub").checked ? '1' : '0';
		push_data("dummy_script.sh", "", dbus_post, "2");
	}
	refresh_acl_table();
}
function update_visibility() {
	var a = E("ss_basic_rule_update").value == "1";
	var b = E("ss_basic_node_update").value == "1";
	var d = E("ss_basic_udp_upstream_mtu").value == "1";			//fancyss-full
	var e = E("ss_china_dns").value == "12";
	var f = E("ss_foreign_dns").value;
	var g = E("ss_basic_tri_reboot_time").value;
	var h_0 = E("ss_basic_server_resolv").value;
	var j = E("ss_basic_chng_china_1_enable").checked;
	var j0 = E("ss_basic_chng_china_1_prot").value;
	var j1 = E("ss_basic_chng_china_1_udp").value == "96";
	var j2 = E("ss_basic_chng_china_1_tcp").value == "97";
	var j3 = E("ss_basic_chng_china_1_doh").value == "98";			//fancyss-full
	var j4 = E("ss_basic_chng_china_1_udp").value == "99";
	var j5 = E("ss_basic_chng_china_1_tcp").value == "99";
	var j6 = E("ss_basic_chng_china_1_udp").value;
	var k = E("ss_basic_chng_china_2_enable").checked;
	var k0 = E("ss_basic_chng_china_2_prot").value;
	var k1 = E("ss_basic_chng_china_2_udp").value == "96";
	var k2 = E("ss_basic_chng_china_2_tcp").value == "97";
	var k3 = E("ss_basic_chng_china_2_doh").value == "98";			//fancyss-full
	var k4 = E("ss_basic_chng_china_2_udp").value == "99";
	var k5 = E("ss_basic_chng_china_2_tcp").value == "99";
	var l = E("ss_basic_chng_trust_1_enable").checked;
	var l0 = E("ss_basic_chng_trust_1_opt").value;
	var l1 = E("ss_basic_chng_trust_1_opt_udp_val").value;
	var l2 = E("ss_basic_chng_trust_1_opt_tcp_val").value;
	var m = E("ss_basic_chng_trust_2_enable").checked;
	var m0 = E("ss_basic_chng_trust_2_opt").value;
	var m3 = E("ss_basic_chng_trust_2_opt_doh").value;				//fancyss-full
	var n = E("ss_basic_smrt").value;								//fancyss-full
	var n1 = E("ss_basic_smrt").value == "1";						//fancyss-full
	var n2 = E("ss_basic_smrt").value == "2";						//fancyss-full
	var n3 = E("ss_basic_smrt").value == "3";						//fancyss-full
	var o = E("ss_basic_dohc_sel_china").value;						//fancyss-full
	var p1 = E("ss_basic_dohc_udp_china").value == "99";			//fancyss-full
	var p2 = E("ss_basic_dohc_tcp_china").value == "99";			//fancyss-full
	var q = E("ss_basic_dohc_sel_foreign").value;					//fancyss-full
	var r = E("ss_basic_dohc_tcp_foreign").value == "99";			//fancyss-full
	showhide("ss_basic_rule_update_time", a);
	showhide("update_choose", a);
	showhide("ss_basic_node_update_day", b);
	showhide("ss_basic_node_update_hr", b);
	showhide("ss_basic_udp_upstream_mtu_value", d);											//fancyss-full
	showhide("ss_china_dns_user", e);
	showhide("ss_basic_server_resolv_user", h_0 == "99");
	showhide("ss_dns2socks_user", (f == "3"));
	showhide("ss_v2_note", (f == "7"));
	showhide("ss_doh_note", (f == "6"));													//fancyss-full
	showhide("ss_disable_aaaa", (f == "10"));
	showhide("ss_disable_aaaa_note", (f == "10"));
	showhide("ss_sstunnel_user", (f == "4"));												//fancyss-full
	showhide("ss_sstunnel_user_note", (f == "4"));											//fancyss-full
	showhide("ss_direct_user", (f == "8"));
	showhide("ss_basic_tri_reboot_time_note", (g != "0"));
	showhide("ss_basic_chng_china_1_prot", j);
	showhide("ss_basic_chng_china_1_ecs", j);
	showhide("ss_basic_chng_china_1_ecs_note", j);
	showhide("ss_basic_chng_china_1_udp", (j && j0 == "1"));
	showhide("ss_basic_chng_china_1_udp_user", (j && j0 == "1" && j4));
	showhide("ss_basic_chng_china_1_tcp", (j && j0 == "2"));
	showhide("ss_basic_chng_china_1_tcp_user", (j && j0 == "2" && j5));
	showhide("ss_basic_chng_china_1_doh", (j && j0 == "3"));								//fancyss-full
	showhide("dohclient_cache_manage_chn1", (j && j0 == "3" && !j3));						//fancyss-full
	showhide("edit_smartdns_conf_10", (j && j0 == "1" && j1));			//udp smartdns		//fancyss-full
	showhide("edit_smartdns_conf_11", (j && j0 == "2" && j2));			//tcp smartdns		//fancyss-full
	showhide("edit_smartdns_conf_12", (j && j0 == "3" && j3));			//doh smartdns		//fancyss-full
	var s = E("ss_basic_chng_no_ipv6").checked;
	showhide("ss_basic_chng_left", s);
	showhide("ss_basic_chng_xact", s);
	showhide("ss_basic_chng_xgt", s);
	showhide("ss_basic_chng_xmc", s);
	showhide("ss_basic_chng_act", s);
	showhide("ss_basic_chng_gt", s);
	showhide("ss_basic_chng_mc", s);
	showhide("ss_basic_chng_right", s);
	var t1 = E("ss_basic_lt_cru_opts").value == "1";
	var t2 = E("ss_basic_lt_cru_opts").value == "2";
	showhide("ss_basic_lt_cru_time", t1 || t2);
	if (j == true){
		if(j0 == "1" && j1){
			$("#ss_basic_chng_china_1_ecs").hide();
			$("#ss_basic_chng_china_1_ecs_note").hide();
		}
		if(j0 == "2" && j2){
			$("#ss_basic_chng_china_1_ecs").hide();
			$("#ss_basic_chng_china_1_ecs_note").hide();
		}
		if(j0 == "3" && j3){																//fancyss-full
			$("#ss_basic_chng_china_1_ecs").hide();											//fancyss-full
			$("#ss_basic_chng_china_1_ecs_note").hide();									//fancyss-full
		}																					//fancyss-full
	}
	showhide("ss_basic_chng_china_2_prot", k);
	showhide("ss_basic_chng_china_2_ecs", k);
	showhide("ss_basic_chng_china_2_ecs_note", k);
	showhide("ss_basic_chng_china_2_udp", (k && k0 == "1"));
	showhide("ss_basic_chng_china_2_udp_user", (k && k0 == "1" && k4));
	showhide("ss_basic_chng_china_2_tcp", (k && k0 == "2"));
	showhide("ss_basic_chng_china_2_tcp_user", (k && k0 == "2" && k5));		
	showhide("ss_basic_chng_china_2_doh", (k && k0 == "3"));								//fancyss-full
	showhide("dohclient_cache_manage_chn2", (k && k0 == "3" && !k3));						//fancyss-full
	showhide("edit_smartdns_conf_13", (k && k0 == "1" && k1));								//fancyss-full
	showhide("edit_smartdns_conf_14", (k && k0 == "2" && k2));								//fancyss-full
	showhide("edit_smartdns_conf_15", (k && k0 == "3" && k3));								//fancyss-full
	if (k == true){
		if(k0 == "1" && k1){
			$("#ss_basic_chng_china_2_ecs").hide();
			$("#ss_basic_chng_china_2_ecs_note").hide();
		}
		if(k0 == "2" && k2){
			$("#ss_basic_chng_china_2_ecs").hide();
			$("#ss_basic_chng_china_2_ecs_note").hide();
		}
		if(k0 == "3" && k3){																//fancyss-full
			$("#ss_basic_chng_china_2_ecs").hide();											//fancyss-full
			$("#ss_basic_chng_china_2_ecs_note").hide();									//fancyss-full
		}																					//fancyss-full
	}
	showhide("ss_basic_chng_trust_1_opt", l);
	showhide("ss_basic_chng_trust_1_ecs", l);
	showhide("ss_basic_chng_trust_1_ecs_note", l);
	showhide("ss_basic_chng_trust_1_opt_udp_val", (l && l0 == "1"));
	showhide("ss_basic_chng_trust_1_opt_udp_val_user", (l && l0 == "1" && l1 == "99"));
	showhide("ss_basic_chng_trust_1_opt_tcp_val", (l && l0 == "2"));
	showhide("ss_basic_chng_trust_1_opt_tcp_val_user", (l && l0 == "2" && l2 == "99"));
	showhide("ss_basic_chng_trust_1_opt_doh_val", (l && l0 == "3"));						//fancyss-full
	showhide("dohclient_cache_manage_frn1", (l && l0 == "3"));								//fancyss-full
	showhide("ss_basic_chng_trust_2_opt", m);
	showhide("ss_basic_chng_trust_2_ecs", m);
	showhide("ss_basic_chng_trust_2_ecs_note", m);
	showhide("ss_basic_chng_trust_2_opt_udp", (m && m0 == "1"));
	showhide("ss_basic_chng_trust_2_opt_tcp", (m && m0 == "2"));
	showhide("ss_basic_chng_trust_2_opt_doh", (m && m0 == "3"));							//fancyss-full
	showhide("edit_smartdns_conf_30", (m && m0 == "3" && m3 == "97"));						//fancyss-full
	showhide("dohclient_cache_manage_frn2", (m && m0 == "3" && m3 != "97"));				//fancyss-full
	//showhide("ss_basic_chng_direct_user_note", (m && (m0 == "3" || m0 == "4")));
	if (m == true){
		if( m0 == "3" && m3 == "97" ){
			$("#ss_basic_chng_trust_2_ecs").hide();
			$("#ss_basic_chng_trust_2_ecs_note").hide();
		}
	}
	showhide("edit_smartdns_conf_51", (n == "1"));					//fancyss-full
	showhide("edit_smartdns_conf_52", (n == "2"));					//fancyss-full
	showhide("edit_smartdns_conf_53", (n == "3"));					//fancyss-full
	showhide("edit_smartdns_conf_54", (n == "4"));					//fancyss-full
	showhide("edit_smartdns_conf_55", (n == "5"));					//fancyss-full
	showhide("edit_smartdns_conf_56", (n == "6"));					//fancyss-full
	showhide("edit_smartdns_conf_57", (n == "7"));					//fancyss-full
	showhide("edit_smartdns_conf_58", (n == "8"));					//fancyss-full
	showhide("edit_smartdns_conf_59", (n == "9"));					//fancyss-full
	showhide("ss_basic_dohc_udp_china", (o == "1"));				//fancyss-full
	showhide("ss_basic_dohc_tcp_china", (o == "2"));				//fancyss-full
	showhide("ss_basic_dohc_doh_china", (o == "3"));				//fancyss-full
	showhide("ss_basic_dohc_udp_china_user", (o == "1" && p1));		//fancyss-full
	showhide("ss_basic_dohc_tcp_china_user", (o == "2" && p2));		//fancyss-full
	showhide("ss_basic_dohc_tcp_foreign", (q == "2"));				//fancyss-full
	showhide("ss_basic_dohc_doh_foreign", (q == "3"));				//fancyss-full
	showhide("ss_basic_dohc_tcp_foreign_user", (q == "2" && r));	//fancyss-full
	if (E("ss_basic_advdns").checked == true){
		if (E("ss_dns_plan").value == "1"){							//fancyss-full
			$(".chng").show();
			$(".smrt").hide();										//fancyss-full							
			$(".dohc").hide();										//fancyss-full
		}else if(E("ss_dns_plan").value == "2"){					//fancyss-full
			$(".chng").hide();										//fancyss-full
			$(".smrt").show();										//fancyss-full
			$(".dohc").hide();										//fancyss-full
		}else if(E("ss_dns_plan").value == "3"){					//fancyss-full
			$(".chng").hide();										//fancyss-full
			$(".smrt").hide();										//fancyss-full
			$(".dohc").show();										//fancyss-full
		}															//fancyss-full
		$(".new_dns_main").show();
		$(".old_dns").hide();
	}else{
		$(".new_dns_main").hide();
		$(".new_dns").hide();
		$(".old_dns").show();
	}

	if(E("ss_basic_nochnipcheck").checked == true){
		// chng chn1
		E("ss_basic_chng_china_1_ecs").disabled = true;
		$('#ss_basic_chng_china_1_ecs').attr("title", "因国内出口ip检查功能被关闭，因此无法使用此功能！")
		$('#ss_basic_chng_china_1_ecs_note > font').attr("color", "#646464")
		// chng chn2
		E("ss_basic_chng_china_2_ecs").disabled = true;
		$('#ss_basic_chng_china_2_ecs').attr("title", "因国内出口ip检查功能被关闭，因此无法使用此功能！")
		$('#ss_basic_chng_china_2_ecs_note > font').attr("color", "#646464")		
		// dohclient main chn
		E("ss_basic_dohc_ecs_china").disabled = true;														//fancyss-full
		$('#ss_basic_dohc_ecs_china').attr("title", "因国内出口ip检查功能被关闭，因此无法使用此功能！")		//fancyss-full
		$('#ss_basic_dhoc_chn_ecs_note > font').attr("color", "#646464")									//fancyss-full
	}

	if(E("ss_basic_nofrnipcheck").checked == true){
		// chng chn1
		E("ss_basic_chng_trust_1_ecs").disabled = true;
		$('#ss_basic_chng_trust_1_ecs').attr("title", "因代理出口ip检查功能被关闭，因此无法使用此功能！")
		$('#ss_basic_chng_trust_1_ecs_note > font').attr("color", "#646464")
		// chng chn2
		E("ss_basic_chng_trust_2_ecs").disabled = true;
		$('#ss_basic_chng_trust_2_ecs').attr("title", "因代理出口ip检查功能被关闭，因此无法使用此功能！")
		$('#ss_basic_chng_trust_2_ecs_note > font').attr("color", "#646464")		
		// dohclient main chn
		E("ss_basic_dohc_ecs_foreign").disabled = true;														//fancyss-full
		$('#ss_basic_dohc_ecs_foreign').attr("title", "因代理出口ip检查功能被关闭，因此无法使用此功能！")	//fancyss-full
		$('#ss_basic_dhoc_frn_ecs_note > font').attr("color", "#646464")									//fancyss-full
	}
}

function Add_profile() { //点击节点页面内添加节点动作
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').show();
	tabclickhandler(0); //默认显示添加ss节点
	E("ss_node_table_name").value = "";
	E("ss_node_table_server").value = "";
	E("ss_node_table_port").value = "";
	E("ss_node_table_password").value = "";
	E("ss_node_table_method").value = "aes-256-cfb";
	E("ss_node_table_mode").value = "2";
	E("ss_node_table_ss_obfs").value = "0"
	E("ss_node_table_ss_obfs_host").value = "";
	E("ss_node_table_ss_v2ray").value = "0"				//fancyss-full
	E("ss_node_table_ss_v2ray_opts").value = "";		//fancyss-full
	E("ss_node_table_rss_protocol").value = "origin";
	E("ss_node_table_rss_protocol_param").value = "";
	E("ss_node_table_rss_obfs").value = "plain";
	E("ss_node_table_rss_obfs_param").value = "";
	E("ss_node_table_v2ray_uuid").value = "";
	E("ss_node_table_v2ray_alterid").value = "0";
	E("ss_node_table_v2ray_json").value = "";
	E("ss_node_table_xray_uuid").value = "";
	E("ss_node_table_xray_encryption").value = "none";
	E("ss_node_table_xray_json").value = "";
	E("ss_node_table_trojan_uuid").value = "";
	E("ss_node_table_trojan_ai").checked = false;
	E("ss_node_table_trojan_sni").value = "";
	E("ss_node_table_trojan_tfo").checked = false;
	E("ss_node_table_hy2_tfo").checked = false;			//fancyss-full
	E("ss_node_table_hy2_ai").checked = true;			//fancyss-full
	E("ssTitle").style.display = "";
	E("ssrTitle").style.display = "";
	E("v2rayTitle").style.display = "";
	E("xrayTitle").style.display = "";
	E("trojanTitle").style.display = "";
	E("naiveTitle").style.display = "";		//fancyss-full
	E("tuicTitle").style.display = "";		//fancyss-full
	E("hy2Title").style.display = "";		//fancyss-full
	E("add_node").style.display = "";
	E("edit_node").style.display = "none";
	E("continue_add").style.display = "";
	show_add_node_panel();
}
function show_add_node_panel(){
	// show add node pannel
	document.scrollingElement.scrollTop = 0;
	//$('html, body').css({overflow: 'hidden', height: '100%'});
	$("#add_fancyss_node").show();
	$(".contentM_qis").css("top", "0px");
	$("#cancel_Btn").css("margin-left", "160px");
	$('#add_fancyss_node_title').html("添加节点");
}
function cancel_add_node() {
	//点击添加节点面板上的返回
	$("#add_fancyss_node").hide();
	//$('html, body').css({overflow: 'auto', height: 'auto'});
	$("body").find(".fullScreen").show(function() { tableApi.removeElement("fullScreen"); });
}
function tabclickhandler(_type) {
	E('ssTitle').className = "vpnClientTitle_td_unclick";
	E('ssrTitle').className = "vpnClientTitle_td_unclick";
	E('v2rayTitle').className = "vpnClientTitle_td_unclick";
	E('xrayTitle').className = "vpnClientTitle_td_unclick";
	E('trojanTitle').className = "vpnClientTitle_td_unclick";
	E('naiveTitle').className = "vpnClientTitle_td_unclick";	//fancyss-full
	E('tuicTitle').className = "vpnClientTitle_td_unclick";		//fancyss-full
	E('hy2Title').className = "vpnClientTitle_td_unclick";		//fancyss-full
	if (_type == 0) {
		save_flag = "shadowsocks";
		E('ssTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none";		//fancyss-full
		E("naive_server_tr").style.display = "none";	//fancyss-full
		E("naive_port_tr").style.display = "none";		//fancyss-full
		E("naive_user_tr").style.display = "none";		//fancyss-full
		E("naive_pass_tr").style.display = "none";		//fancyss-full
		E('tuic_json_tr').style.display = "none";		//fancyss-full
		$(".hy2_elem").hide();							//fancyss-full
		showhide("ss_obfs_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_obfs_host_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_obfs").val() != "0"));
		showhide("ss_v2ray_support", ($("#ss_node_table_mode").val() != "3"));														//fancyss-full
		showhide("ss_v2ray_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray").val() != "0"));	//fancyss-full
	}
	else if (_type == 1) {
		save_flag = "shadowsocksR";
		E('ssrTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";		//fancyss-full
		E('ss_v2ray_opts_support').style.display = "none";	//fancyss-full
		E('ssr_protocol_tr').style.display = "";
		E('ssr_protocol_param_tr').style.display = "";
		E('ssr_obfs_tr').style.display = "";
		E('ssr_obfs_param_tr').style.display = "";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none";		//fancyss-full
		E("naive_server_tr").style.display = "none";	//fancyss-full
		E("naive_port_tr").style.display = "none";		//fancyss-full
		E("naive_user_tr").style.display = "none";		//fancyss-full
		E("naive_pass_tr").style.display = "none";		//fancyss-full
		E('tuic_json_tr').style.display = "none";		//fancyss-full
		$(".hy2_elem").hide();							//fancyss-full
	}
	else if (_type == 3) {
		save_flag = "v2ray";
		E('v2rayTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";		//fancyss-full
		E('ss_v2ray_opts_support').style.display = "none";	//fancyss-full
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "";
		$(".v2ray_elem").show();
		E('v2ray_alterid_tr').style.display = "";
		E('v2ray_security_tr').style.display = "";
		E('v2ray_network_tr').style.display = "";
		E('v2ray_headtype_tcp_tr').style.display = "";
		E('v2ray_headtype_kcp_tr').style.display = "";
		E('v2ray_headtype_quic_tr').style.display = "";
		E('v2ray_grpc_mode_tr').style.display = "";
		E('v2ray_network_path_tr').style.display = "";
		E('v2ray_network_host_tr').style.display = "";
		E('v2ray_kcp_seed_tr').style.display = "";
		E('v2ray_network_security_tr').style.display = "";
		E('v2ray_network_security_ai_tr').style.display = "";
		E('v2ray_network_security_alpn_tr').style.display = "";
		E('v2ray_network_security_sni_tr').style.display = "";
		E('v2ray_mux_enable_tr').style.display = "";
		E('v2ray_mux_concurrency_tr').style.display = "";
		E('v2ray_json_tr').style.display = "";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none";		//fancyss-full
		E("naive_server_tr").style.display = "none";	//fancyss-full
		E("naive_port_tr").style.display = "none";		//fancyss-full
		E("naive_user_tr").style.display = "none";		//fancyss-full
		E("naive_pass_tr").style.display = "none";		//fancyss-full
		E('tuic_json_tr').style.display = "none";		//fancyss-full
		$(".hy2_elem").hide();							//fancyss-full
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			$(".v2ray_elem").hide();
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('v2ray_headtype_quic_tr').style.display = "none";
			E('v2ray_grpc_mode_tr').style.display = "none";
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_kcp_seed_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('v2ray_network_security_ai_tr').style.display = "none";
			E('v2ray_network_security_alpn_tr').style.display = "none";
			E('v2ray_network_security_sni_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			$(".v2ray_elem").show();
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('v2ray_headtype_quic_tr').style.display = "";
			E('v2ray_grpc_mode_tr').style.display = "";
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_kcp_seed_tr').style.display = "";
			E('v2ray_network_security_tr').style.display = "";
			E('v2ray_network_security_ai_tr').style.display = "";
			E('v2ray_network_security_alpn_tr').style.display = "";
			E('v2ray_network_security_sni_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var v_tcp_on_2 = E("ss_node_table_v2ray_network").value == "tcp";
			var v_http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var v_host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || v_http_on_2;
			var v_path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2";
			var v_tls_on_2 = E("ss_node_table_v2ray_network_security").value == "tls";
			var v_grpc_on_2 = E("ss_node_table_v2ray_network").value == "grpc"
			showhide("v2ray_headtype_tcp_tr", v_tcp_on_2);
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_kcp_seed_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_headtype_quic_tr", (E("ss_node_table_v2ray_network").value == "quic"));
			showhide("v2ray_grpc_mode_tr", v_grpc_on_2);
			showhide("v2ray_network_host_tr", v_host_on_2);
			showhide("v2ray_network_path_tr", v_path_on_2);
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
			showhide("v2ray_network_security_ai_tr", v_tls_on_2);
			showhide("v2ray_network_security_alpn_tr", v_tls_on_2);
			showhide("v2ray_network_security_sni_tr", v_tls_on_2);
			if(v_grpc_on_2){
				$('#v2ray_network_path_tr > th').html('* serviceName');
			}else{
				$('#v2ray_network_path_tr > th').html('* 路径 (path)');
			}
		}
	}
	else if (_type == 4) {
		save_flag = "xray";
		E('xrayTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "";
		E('ss_name_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";		//fancyss-full
		E('ss_v2ray_opts_support').style.display = "none";	//fancyss-full
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "";
		$(".xray_elem").show();
		E('xray_encryption_tr').style.display = "";
		E('xray_flow_tr').style.display = "";
		E('xray_show_tr').style.display = "";
		E('xray_publickey_tr').style.display = "";
		E('xray_shortid_tr').style.display = "";
		E('xray_spiderx_tr').style.display = "";
		E('xray_network_tr').style.display = "";
		E('xray_headtype_tcp_tr').style.display = "";
		E('xray_headtype_kcp_tr').style.display = "";
		E('xray_headtype_quic_tr').style.display = "";
		E('xray_grpc_mode_tr').style.display = "";
		E('xray_network_path_tr').style.display = "";
		E('xray_network_host_tr').style.display = "";
		E('xray_kcp_seed_tr').style.display = "";
		E('xray_network_security_tr').style.display = "";
		E('xray_network_security_ai_tr').style.display = "";
		E('xray_network_security_alpn_tr').style.display = "";
		E('xray_network_security_sni_tr').style.display = "";
		E('xray_fingerprint_tr').style.display = "";
		E('xray_json_tr').style.display = "";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none"; 		//fancyss-full
		E("naive_server_tr").style.display = "none";	//fancyss-full
		E("naive_port_tr").style.display = "none";		//fancyss-full
		E("naive_user_tr").style.display = "none";		//fancyss-full
		E("naive_pass_tr").style.display = "none";		//fancyss-full
		E('tuic_json_tr').style.display = "none";		//fancyss-full
		$(".hy2_elem").hide();							//fancyss-full
		if(E("ss_node_table_xray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('xray_uuid_tr').style.display = "none";
			$(".xray_elem").hide();
			E('xray_encryption_tr').style.display = "none";
			E('xray_flow_tr').style.display = "none";
			E('xray_show_tr').style.display = "none";
			E('xray_publickey_tr').style.display = "none";
			E('xray_shortid_tr').style.display = "none";
			E('xray_spiderx_tr').style.display = "none";
			E('xray_network_tr').style.display = "none";
			E('xray_headtype_tcp_tr').style.display = "none";
			E('xray_headtype_kcp_tr').style.display = "none";
			E('xray_headtype_quic_tr').style.display = "none";
			E('xray_grpc_mode_tr').style.display = "none";
			E('xray_network_path_tr').style.display = "none";
			E('xray_network_host_tr').style.display = "none";
			E('xray_kcp_seed_tr').style.display = "none";
			E('xray_network_security_tr').style.display = "none";
			E('xray_network_security_ai_tr').style.display = "none";
			E('xray_network_security_alpn_tr').style.display = "none";
			E('xray_network_security_sni_tr').style.display = "none";
			E('xray_fingerprint_tr').style.display = "none";
			E('xray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('xray_uuid_tr').style.display = "";
			$(".xray_elem").show();
			E('xray_encryption_tr').style.display = "";
			E('xray_flow_tr').style.display = "";
			E('xray_show_tr').style.display = "";
			E('xray_publickey_tr').style.display = "";
			E('xray_shortid_tr').style.display = "";
			E('xray_spiderx_tr').style.display = "";
			E('xray_network_tr').style.display = "";
			E('xray_headtype_tcp_tr').style.display = "";
			E('xray_headtype_kcp_tr').style.display = "";
			E('xray_headtype_quic_tr').style.display = "";
			E('xray_grpc_mode_tr').style.display = "";
			E('xray_network_path_tr').style.display = "";
			E('xray_network_host_tr').style.display = "";
			E('xray_kcp_seed_tr').style.display = "";
			E('xray_network_security_tr').style.display = "";
			E('xray_network_security_ai_tr').style.display = "";
			E('xray_network_security_alpn_tr').style.display = "";
			E('xray_network_security_sni_tr').style.display = "";
			E('xray_json_tr').style.display = "none";
			var x_http_on_2 = E("ss_node_table_xray_network").value == "tcp" && E("ss_node_table_xray_headtype_tcp").value == "http";
			var x_host_on_2 = E("ss_node_table_xray_network").value == "ws" || E("ss_node_table_xray_network").value == "h2" || x_http_on_2;
			var x_path_on_2 = E("ss_node_table_xray_network").value == "ws" || E("ss_node_table_xray_network").value == "h2";
			var x_tls_on_2 = E("ss_node_table_xray_network_security").value == "tls" || E("ss_node_table_xray_network_security").value == "xtls";
			var x_xtls_on_2 = E("ss_node_table_xray_network_security").value == "xtls";
			var x_real_on_2 = E("ss_node_table_xray_network_security").value == "reality";
			var x_tcp_on_2 = E("ss_node_table_xray_network").value == "tcp";
			var x_grpc_on_2 = E("ss_node_table_xray_network").value == "grpc";
			showhide("xray_headtype_tcp_tr", x_tcp_on_2);
			showhide("xray_headtype_kcp_tr", (E("ss_node_table_xray_network").value == "kcp"));
			showhide("xray_kcp_seed_tr", (E("ss_node_table_xray_network").value == "kcp"));
			showhide("xray_headtype_quic_tr", (E("ss_node_table_xray_network").value == "quic"));
			showhide("xray_grpc_mode_tr", x_grpc_on_2);
			showhide("xray_network_host_tr", x_host_on_2);
			showhide("xray_network_path_tr", x_path_on_2);
			showhide("xray_json_tr", (E("ss_node_table_xray_use_json").checked));
			showhide("xray_network_security_ai_tr", x_tls_on_2);
			showhide("xray_network_security_alpn_tr", x_tls_on_2);
			showhide("xray_network_security_sni_tr", x_tls_on_2 || x_real_on_2);
			showhide("xray_fingerprint_tr", x_tls_on_2 || x_real_on_2);
			showhide("xray_flow_tr", x_xtls_on_2 && x_tcp_on_2 || x_real_on_2 && x_tcp_on_2);
			showhide("xray_show_tr", x_real_on_2);
			showhide("xray_publickey_tr", x_real_on_2);
			showhide("xray_shortid_tr", x_real_on_2);
			showhide("xray_spiderx_tr", x_real_on_2);
			if(x_grpc_on_2){
				$('#xray_network_path_tr > th').html('* serviceName');
			}else{
				$('#xray_network_path_tr > th').html('* 路径 (path)');
			}
		}
	}
	else if (_type == 5) {
		save_flag = "trojan";
		E('trojanTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";		//fancyss-full
		E('ss_v2ray_opts_support').style.display = "none";	//fancyss-full
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "";
		E('trojan_uuid_tr').style.display = "";
		E('trojan_sni_tr').style.display = "";
		E('trojan_tfo_tr').style.display = "";
		E("naive_prot_tr").style.display = "none";		//fancyss-full
		E("naive_server_tr").style.display = "none";	//fancyss-full
		E("naive_port_tr").style.display = "none";		//fancyss-full
		E("naive_user_tr").style.display = "none";		//fancyss-full
		E("naive_pass_tr").style.display = "none";		//fancyss-full
		E('tuic_json_tr').style.display = "none";		//fancyss-full
		$(".hy2_elem").hide();							//fancyss-full
	}
	//fancyss_naive_1
	else if (_type == 6) {
		save_flag = "naive";
		E('naiveTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "none";
		E('ss_port_support_tr').style.display = "none";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";
		E('ss_v2ray_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "";
		E("naive_server_tr").style.display = "";
		E("naive_port_tr").style.display = "";
		E("naive_user_tr").style.display = "";
		E("naive_pass_tr").style.display = "";
		E('tuic_json_tr').style.display = "none";
		$(".hy2_elem").hide();
	}
	//fancyss_naive_2
	//fancyss_tuic_1
	else if (_type == 7) {
		save_flag = "tuic";
		E('tuicTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "none";
		E('ss_port_support_tr').style.display = "none";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";
		E('ss_v2ray_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none";
		E("naive_server_tr").style.display = "none";
		E("naive_port_tr").style.display = "none";
		E("naive_user_tr").style.display = "none";
		E("naive_pass_tr").style.display = "none";		
		E('tuic_json_tr').style.display = "";
		$(".hy2_elem").hide();
	}
	//fancyss_tuic_2
	//fancyss_hy2_1
	else if (_type == 8) {
		save_flag = "hysteria2";
		E('hy2Title').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('xray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "none";
		E('ss_port_support_tr').style.display = "none";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";
		E('ss_v2ray_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		$(".v2ray_elem").hide();
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_headtype_quic_tr').style.display = "none";
		E('v2ray_grpc_mode_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_kcp_seed_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_network_security_ai_tr').style.display = "none";
		E('v2ray_network_security_alpn_tr').style.display = "none";
		E('v2ray_network_security_sni_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('xray_uuid_tr').style.display = "none";
		$(".xray_elem").hide();
		E('xray_encryption_tr').style.display = "none";
		E('xray_flow_tr').style.display = "none";
		E('xray_show_tr').style.display = "none";
		E('xray_publickey_tr').style.display = "none";
		E('xray_shortid_tr').style.display = "none";
		E('xray_spiderx_tr').style.display = "none";
		E('xray_network_tr').style.display = "none";
		E('xray_headtype_tcp_tr').style.display = "none";
		E('xray_headtype_kcp_tr').style.display = "none";
		E('xray_headtype_quic_tr').style.display = "none";
		E('xray_grpc_mode_tr').style.display = "none";
		E('xray_network_path_tr').style.display = "none";
		E('xray_network_host_tr').style.display = "none";
		E('xray_kcp_seed_tr').style.display = "none";
		E('xray_network_security_tr').style.display = "none";
		E('xray_network_security_ai_tr').style.display = "none";
		E('xray_network_security_alpn_tr').style.display = "none";
		E('xray_network_security_sni_tr').style.display = "none";
		E('xray_fingerprint_tr').style.display = "none";
		E('xray_json_tr').style.display = "none";
		E('trojan_ai_tr').style.display = "none";
		E('trojan_uuid_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_tfo_tr').style.display = "none";
		E("naive_prot_tr").style.display = "none";
		E("naive_server_tr").style.display = "none";
		E("naive_port_tr").style.display = "none";
		E("naive_user_tr").style.display = "none";
		E("naive_pass_tr").style.display = "none";		
		E('tuic_json_tr').style.display = "none";
		$(".hy2_elem").show();
		showhide("hy2_obfs_pass_tr", E("ss_node_table_hy2_obfs").value == "1");
	}
	//fancyss_hy2_2
	return save_flag;
}
function add_ss_node_conf(flag) {
	var ns = {};
	var p = "ssconf_basic";
	node_max += 1;

	if(!$.trim($('#ss_node_table_name').val())){
		alert("节点名不能为空！！");
		return false;
	}
	if (flag == 'shadowsocks') {
		var params1 = ["mode", "name", "server", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts"]; //ss
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + node_max] = $.trim($("#ss_node_table_" + params1[i]).val());
		}
		ns[p + "_password_" + node_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_max] = "0";
	} else if (flag == 'shadowsocksR') {
		var params2 = ["mode", "name", "server", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"]; //ssr
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + node_max] = $.trim($("#ss_node_table_" + params2[i]).val());
		}
		ns[p + "_password_" + node_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_max] = "1";
	} else if (flag == 'v2ray') {
		var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency"]; //for v2ray
		var params4_2 = ["v2ray_use_json", "v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http"];
		if (E("ss_node_table_v2ray_use_json").checked == true){
			ns[p + "_mode_" + node_max] = $.trim($("#ss_node_table_mode").val());
			ns[p + "_name_" + node_max] = $.trim($("#ss_node_table_name").val());
			ns[p + "_v2ray_use_json_" + node_max] = "1";
			if($("#ss_node_table_v2ray_json").val()){
				if(isJSON(E("ss_node_table_v2ray_json").value)){
					if(E("ss_node_table_v2ray_json").value.indexOf("outbound") != -1){
						ns[p + "_v2ray_json_" + node_max] = Base64.encode(pack_js(E("ss_node_table_v2ray_json").value));
					}else{
						alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
						return false;
					}
				}else{
					alert("错误！检测到你输入的v2ray配置不是标准json格式！");
					return false;
				}
			}else{
				alert("错误！你的json配置为空！");
				return false;
			}
		}else{
			for (var i = 0; i < params4_1.length; i++) {
				ns[p + "_" + params4_1[i] + "_" + node_max] = $.trim($("#ss_node_table_" + params4_1[i]).val());
			}
			for (var i = 0; i < params4_2.length; i++) {
				ns[p + "_" + params4_2[i] + "_" + node_max] = E("ss_node_table_" + params4_2[i]).checked ? "1" : "";
			}
		}
		ns[p + "_type_" + node_max] = "3";
	} else if (flag == 'xray') {
		var params5_1 = ["mode", "name", "server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx"]; //for xray
		var params5_2 = ["xray_use_json", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_show"];
		if (E("ss_node_table_xray_use_json").checked == true){
			ns[p + "_mode_" + node_max] = $.trim($("#ss_node_table_mode").val());
			ns[p + "_name_" + node_max] = $.trim($("#ss_node_table_name").val());
			ns[p + "_xray_use_json_" + node_max] = "1";
			if ($("#ss_node_table_xray_json").val()){
				if(isJSON(E('ss_node_table_xray_json').value)){
					if(E('ss_node_table_xray_json').value.indexOf("outbound") != -1){
						ns[p + "_xray_json_" + node_max] = Base64.encode(pack_js(E('ss_node_table_xray_json').value));
					}else{
						alert("错误！你的json配置文件有误！");
						return false;
					}
				}else{
					alert("错误！检测到你输入的xray配置不是标准json格式！");
					return false;
				}
			}else{
				alert("错误！你的json配置为空！");
				return false;
			}
		}else{
			for (var i = 0; i < params5_1.length; i++) {
				ns[p + "_" + params5_1[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params5_1[i]).val());
			}
			for (var i = 0; i < params5_2.length; i++) {
				ns[p + "_" + params5_2[i] + "_" + node_max] = E("ss_node_table_" + params5_2[i]).checked ? '1' : '';
			}
			ns[p + "_xray_prot_" + node_max] = "vless";
		}
		ns[p + "_type_" + node_max] = "4";
	} else if (flag == 'trojan') {
		var params6 = ["mode", "name", "server", "port", "trojan_uuid", "trojan_sni"]; //trojan
		for (var i = 0; i < params6.length; i++) {
			ns[p + "_" + params6[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params6[i]).val());
		}
		ns[p + "_trojan_ai_" + node_max] = E("ss_node_table_trojan_ai").checked ? '1' : '';
		ns[p + "_trojan_tfo_" + node_max] = E("ss_node_table_trojan_tfo").checked ? '1' : '';
		ns[p + "_type_" + node_max] = "5";
	}
	//fancyss_naive_1
	else if (flag == 'naive') {
		var params7 = ["mode", "name", "naive_prot", "naive_server", "naive_port", "naive_user"]; //naive
		for (var i = 0; i < params7.length; i++) {
			ns[p + "_" + params7[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params7[i]).val());
		}
		ns[p + "_naive_pass_" + node_max] = Base64.encode($.trim($("#ss_node_table_naive_pass").val()));
		ns[p + "_type_" + node_max] = "6";
	}
	//fancyss_naive_2
	//fancyss_tuic_1
	else if (flag == 'tuic') {
		ns[p + "_mode_" + node_max] = $.trim($("#ss_node_table_mode").val());
		ns[p + "_name_" + node_max] = $.trim($("#ss_node_table_name").val());
		if ($("#ss_node_table_tuic_json").val()){
			if(isJSON(E('ss_node_table_tuic_json').value)){
				if(E('ss_node_table_tuic_json').value.indexOf("relay") != -1){
					ns[p + "_tuic_json_" + node_max] = Base64.encode(pack_js(E('ss_node_table_tuic_json').value));
				}else{
					alert("错误！你的json配置文件有误！");
					return false;
				}
			}else{
				alert("错误！检测到你输入的tuic client配置不是标准json格式！");
				return false;
			}
		}else{
			alert("错误！你的json配置为空！");
			return false;
		}
		ns[p + "_type_" + node_max] = "7";
	}
	//fancyss_tuic_2
	//fancyss_hy2_1
	else if (flag == 'hysteria2') {
		var params8 = ["mode", "name", "hy2_server", "hy2_port", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_pass", "hy2_sni"]; //hy2
		for (var i = 0; i < params8.length; i++) {
			ns[p + "_" + params8[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params8[i]).val());
		}
		ns[p + "_hy2_ai_" + node_max] = E("ss_node_table_hy2_ai").checked ? '1' : '';
		ns[p + "_hy2_tfo_" + node_max] = E("ss_node_table_hy2_tfo").checked ? '1' : '';
		ns[p + "_type_" + node_max] = "8";
	}
	//fancyss_hy2_2
	//push data to add new node
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": ns };
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			refresh_table();
			E("ss_node_table_server").value = "";
			if ((E("continue_add_box").checked) == false) {
				E("ss_node_table_name").value = "";
				E("ss_node_table_port").value = "";
				E("ss_node_table_password").value = "";
				E("ss_node_table_method").value = "aes-256-cfb";
				E("ss_node_table_mode").value = "2";
				E("ss_node_table_ss_obfs").value = "0"
				E("ss_node_table_ss_obfs_host").value = "";
				E("ss_node_table_ss_v2ray").value = "0"			//fancyss-full
				E("ss_node_table_ss_v2ray_opts").value = "";	//fancyss-full
				E("ss_node_table_rss_protocol").value = "origin";
				E("ss_node_table_rss_protocol_param").value = "";
				E("ss_node_table_rss_obfs").value = "plain";
				E("ss_node_table_rss_obfs_param").value = "";
				E("ss_node_table_v2ray_uuid").value = "";
				E("ss_node_table_v2ray_alterid").value = "0";
				E("ss_node_table_v2ray_json").value = "";
				E("ss_node_table_xray_uuid").value = "";
				E("ss_node_table_xray_encryption").value = "none";
				E("ss_node_table_xray_json").value = "";
				E("ss_node_table_trojan_ai").checked = false;
				E("ss_node_table_trojan_uuid").value = "";
				E("ss_node_table_trojan_sni").value = "";
				E("ss_node_table_trojan_tfo").checked = false;
				E("ss_node_table_naive_prot").value = "https";	//fancyss-full
				E("ss_node_table_naive_server").value = "";		//fancyss-full
				E("ss_node_table_naive_port").value = "443";	//fancyss-full
				E("ss_node_table_naive_user").value = "";		//fancyss-full
				E("ss_node_table_naive_pass").value = "";		//fancyss-full
				E("ss_node_table_tuic_json").value = "";		//fancyss-full
				cancel_add_node();
			}
		}
	});
}
function remove_conf_table(o) {
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	if((parseInt(db_ss["ssconf_basic_node"]) == id) && db_ss["ss_basic_enable"] == "1"){
		alert("警告：这个节点正在运行，无法删除！")
		return false;
	}
	//console.log("删除第", id, "个节点！！！")
	var dbus_tmp = {};
	var perf = "ssconf_basic_"
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "use_lb", "ping", "lbmode", "weight", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "xray_uuid", "xray_alterid", "xray_prot", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_show", "xray_json", "tuic_json", "xray_use_json", "type", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_ai", "hy2_tfo"];
	var new_nodes = ss_nodes.concat()
	new_nodes.splice(new_nodes.indexOf(id), 1);
	//first: mark all node from ss_nodes data as empty
	for (var i = 0; i < ss_nodes.length; i++) {
		for (var j = 0; j < temp.length; j++) {
			dbus_tmp[perf + temp[j] + "_" + ss_nodes[i]] = "";
		}
	}
	//second: rewrite new node data in order
	for (var i = 0; i < new_nodes.length; i++) {
		for (var j = 0; j < temp.length; j++) {
			if(db_ss[perf + temp[j] + "_" + new_nodes[i]]){
				dbus_tmp[perf + temp[j] + "_" + (i + 1)] = db_ss[perf + temp[j] + "_" + new_nodes[i]];
			}else{
				dbus_tmp[perf + temp[j] + "_" + (i + 1)] = "";
			}
		}
	}
	//filer values
	var post_data = compfilter(db_ss, dbus_tmp);
	//console.log("post_data:", post_data);
	//post_data
	var id_1 = parseInt(Math.random() * 100000000);
	var postData = {"id": id_1, "method": "dummy_script.sh", "params":[], "fields": post_data };
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			$('#ss_node_list_table tr:nth-child(' + id + ')').remove();
			refresh_dbss();
			reorder_trs();
			refresh_options();
		}
	});
}
function edit_conf_table(o) {
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	edit_id = id;
	if((parseInt(db_ss["ssconf_basic_node"]) == id) && db_ss["ss_basic_enable"] == "1"){
		alert("提醒：这个节点正在运行！\n如果更改了其中的参数，需要重新点击【保存&应用】才能生效！")
	}
	var c = confs[id];
	var params1_base64 = ["password", "naive_pass"];
	var params1_check = ["v2ray_use_json", "v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "xray_use_json", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "trojan_ai", "xray_show", "hy2_ai", "hy2_tfo"];
	var params1_input = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "trojan_uuid", "trojan_sni", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni"];
	if(c["v2ray_json"]){
		E("ss_node_table_v2ray_json").value = do_js_beautify(Base64.decode(c["v2ray_json"]));
	}
	if(c["xray_json"]){
		E("ss_node_table_xray_json").value = do_js_beautify(Base64.decode(c["xray_json"]));
	}
	if(c["tuic_json"]){																				//fancyss-full
		E("ss_node_table_tuic_json").value = do_js_beautify(Base64.decode(c["tuic_json"]));			//fancyss-full
	}																								//fancyss-full
	for (var i = 0; i < params1_base64.length; i++) {
		if(c[params1_base64[i]]){
			E("ss_node_table_" + params1_base64[i]).value = Base64.decode(c[params1_base64[i]]);
		}
	}
	for (var i = 0; i < params1_check.length; i++) {
		if(c[params1_check[i]]){
			E("ss_node_table_" + params1_check[i]).checked = c[params1_check[i]] == "1";
		}else{
			E("ss_node_table_" + params1_check[i]).checked = false;
		}
	}
	for (var i = 0; i < params1_input.length; i++) {
		if(c[params1_input[i]]){
			E("ss_node_table_" + params1_input[i]).value = c[params1_input[i]];
		}
	}
	E("cancel_Btn").style.display = "";
	E("add_node").style.display = "none";
	E("edit_node").style.display = "";
	E("continue_add").style.display = "none";
	if (c["type"] == "0"){
		E("ssTitle").style.display = "";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";		//fancyss-full
		$("#ssTitle").html("编辑ss节点");
		tabclickhandler(0);		
	}
	else if(c["type"] == "1"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";		//fancyss-full
		$("#ssrTitle").html("编辑SSR节点");
		tabclickhandler(1);		
	}
	else if(c["type"] == "3"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";		//fancyss-full
		$("#v2rayTitle").html("编辑V2Ray账号");
		tabclickhandler(3);
	}
	else if(c["type"] == "4"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";		//fancyss-full
		$("#xrayTitle").html("编辑Xray账号");
		tabclickhandler(4);
	}
	else if(c["type"] == "5"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";		//fancyss-full
		$("#trojanTitle").html("编辑trojan账号");
		tabclickhandler(5);
	}
	//fancyss_naive_1
	else if(c["type"] == "6"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "";
		E("tuicTitle").style.display = "none";
		E("hy2Title").style.display = "none";
		$("#naiveTitle").html("编辑NaïveProxy账号");
		tabclickhandler(6);
	}
	//fancyss_naive_2
	//fancyss_tuic_1
	else if(c["type"] == "7"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";
		E("tuicTitle").style.display = "";
		E("hy2Title").style.display = "none";
		$("#naiveTitle").html("编辑tuic账号");
		tabclickhandler(7);
	}
	//fancyss_tuic_2
	//fancyss_hy2_1
	else if(c["type"] == "8"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("v2rayTitle").style.display = "none";
		E("xrayTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";
		E("tuicTitle").style.display = "none";
		E("hy2Title").style.display = "";
		$("#hy2Title").html("编辑hysteria2账号");
		tabclickhandler(8);
	}
	//fancyss_hy2_2
	show_add_node_panel();
	$("#cancel_Btn").css("margin-left", "10px");
	$('#add_fancyss_node_title').html("修改节点");
}
function edit_ss_node_conf(flag) {
	var ns = {};
	var p = "ssconf_basic";
	if (flag == 'shadowsocks') {
		var params1 = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts"];
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params1[i]).val();
		}
		ns[p + "_password_" + edit_id] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + edit_id] = "0";
	}
	else if (flag == 'shadowsocksR') {
		var params2 = ["name", "server", "mode", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"];
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params2[i]).val();
		}
		ns[p + "_password_" + edit_id] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + edit_id] = "1";
	}
	else if (flag == 'v2ray') {
		var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency"]; //for v2ray non json
		var params4_2 = ["v2ray_use_json", "v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http"];
		if (E("ss_node_table_v2ray_use_json").checked == true){
			ns[p + "_mode_" + edit_id] = $.trim($("#ss_node_table_mode").val());
			ns[p + "_name_" + edit_id] = $.trim($("#ss_node_table_name").val());
			ns[p + "_v2ray_use_json_" + edit_id] = "1";
			if($("#ss_node_table_v2ray_json").val()){
				if(isJSON(E("ss_node_table_v2ray_json").value)){
					if(E("ss_node_table_v2ray_json").value.indexOf("outbound") != -1){
						ns[p + "_v2ray_json_" + edit_id] = Base64.encode(pack_js(E("ss_node_table_v2ray_json").value));
					}else{
						alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
						return false;
					}
				}else{
					alert("错误！检测到你输入的v2ray配置不是标准json格式！");
					return false;
				}
			}else{
				alert("错误！你的json配置为空！");
				return false;
			}
		}else{
			for (var i = 0; i < params4_1.length; i++) {
				ns[p + "_" + params4_1[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params4_1[i]).val();
			}
			for (var i = 0; i < params4_2.length; i++) {
				ns[p + "_" + params4_2[i] + "_" + edit_id] = E("ss_node_table_" + params4_2[i]).checked ? "1" : "";
			}
		}
		ns[p + "_type_" + edit_id] = "3";
	}
	else if (flag == 'xray') {
		var params5_1 = ["mode", "name", "server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx"]; //for xray
		var params5_2 = ["xray_use_json", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_show"];
		if (E("ss_node_table_xray_use_json").checked == true){
			ns[p + "_mode_" + edit_id] = $.trim($("#ss_node_table_mode").val());
			ns[p + "_name_" + edit_id] = $.trim($("#ss_node_table_name").val());
			ns[p + "_xray_use_json_" + edit_id] = "1";
			if($("#ss_node_table_xray_json").val()){
				if(isJSON(E('ss_node_table_xray_json').value)){
					if(E('ss_node_table_xray_json').value.indexOf("outbound") != -1){
						ns[p + "_xray_json_" + edit_id] = Base64.encode(pack_js(E('ss_node_table_xray_json').value));
					}else{
						alert("错误！你的json配置文件有误！");
						return false;
					}
				}else{
					alert("错误！检测到你输入的xray配置不是标准json格式！");
					return false;
				}
			}else{
				alert("错误！你的json配置为空！");
				return false;
			}
		}else{
			for (var i = 0; i < params5_1.length; i++) {
				ns[p + "_" + params5_1[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params5_1[i]).val();
			}
			for (var i = 0; i < params5_2.length; i++) {
				ns[p + "_" + params5_2[i] + "_" + edit_id] = E("ss_node_table_" + params5_2[i]).checked ? "1" : "";
			}
		}
		ns[p + "_type_" + edit_id] = "4";
	}
	else if (flag == 'trojan') {
		var params6 = ["mode", "name", "server", "port", "trojan_uuid", "trojan_sni"]; //trojan
		for (var i = 0; i < params6.length; i++) {
			ns[p + "_" + params6[i] + "_" + edit_id] = $.trim($('#ss_node_table' + "_" + params6[i]).val());
		}
		ns[p + "_trojan_ai_" + edit_id] = E("ss_node_table_trojan_ai").checked ? "1" : "";
		ns[p + "_trojan_tfo_" + edit_id] = E("ss_node_table_trojan_tfo").checked ? "1" : "";
		ns[p + "_password_" + edit_id] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + edit_id] = "5";
	}
	//fancyss_naive_1
	else if (flag == 'naive') {
		var params7 = ["mode", "name", "naive_prot", "naive_server", "naive_port", "naive_user"]; //naive
		for (var i = 0; i < params7.length; i++) {
			ns[p + "_" + params7[i] + "_" + edit_id] = $.trim($('#ss_node_table' + "_" + params7[i]).val());
		}
		ns[p + "_naive_pass_" + edit_id] = Base64.encode($.trim($("#ss_node_table_naive_pass").val()));
		ns[p + "_type_" + edit_id] = "6";
	}
	//fancyss_naive_2
	//fancyss_tuic_1
	else if (flag == 'tuic') {
		ns[p + "_mode_" + edit_id] = $.trim($("#ss_node_table_mode").val());
		ns[p + "_name_" + edit_id] = $.trim($("#ss_node_table_name").val());
		if($("#ss_node_table_tuic_json").val()){
			if(isJSON(E('ss_node_table_tuic_json').value)){
				if(E('ss_node_table_tuic_json').value.indexOf("outbound") != -1){
					ns[p + "_tuic_json_" + edit_id] = Base64.encode(pack_js(E('ss_node_table_tuic_json').value));
				}else{
					alert("错误！你的json配置文件有误！");
					return false;
				}
			}else{
				alert("错误！检测到你输入的tuic client配置不是标准json格式！");
				return false;
			}
		}else{
			alert("错误！你的json配置为空！");
			return false;
		}
		ns[p + "_type_" + edit_id] = "7";
	}
	//fancyss_tuic_2
	//fancyss_hy2_1
	else if (flag == 'hysteria2') {
		var params8 = ["mode", "name", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni"]; //hy2
		for (var i = 0; i < params8.length; i++) {
			ns[p + "_" + params8[i] + "_" + edit_id] = $.trim($('#ss_node_table' + "_" + params8[i]).val());
		}
		ns[p + "_hy2_ai_" + edit_id] = E("ss_node_table_hy2_ai").checked ? "1" : "";
		ns[p + "_hy2_tfo_" + edit_id] = E("ss_node_table_hy2_tfo").checked ? "1" : "";
		ns[p + "_type_" + edit_id] = "8";
	}
	//fancyss_hy2_2
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": ns };
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			refresh_table();
			E("ss_node_table_name").value = "";
			E("ss_node_table_port").value = "";
			E("ss_node_table_server").value = "";
			E("ss_node_table_password").value = "";
			E("ss_node_table_method").value = "aes-256-cfb";
			E("ss_node_table_mode").value = "2";
			E("ss_node_table_ss_obfs").value = "0"
			E("ss_node_table_ss_obfs_host").value = "";
			E("ss_node_table_ss_v2ray").value = "0"			//fancyss-full
			E("ss_node_table_ss_v2ray_opts").value = "";	//fancyss-full
			E("ss_node_table_rss_protocol").value = "origin";
			E("ss_node_table_rss_protocol_param").value = "";
			E("ss_node_table_rss_obfs").value = "plain";
			E("ss_node_table_rss_obfs_param").value = "";
			E("ss_node_table_v2ray_uuid").value = "";
			E("ss_node_table_v2ray_alterid").value = "0";
			E("ss_node_table_v2ray_json").value = "";
			E("ss_node_table_xray_uuid").value = "";
			E("ss_node_table_xray_encryption").value = "0";
			E("ss_node_table_xray_json").value = "";
			E("ss_node_table_trojan_ai").checked = false;
			E("ss_node_table_trojan_uuid").value = "";
			E("ss_node_table_trojan_sni").value = "";
			E("ss_node_table_trojan_tfo").checked = false;
			E("ss_node_table_naive_prot").value = "https";	//fancyss-full
			E("ss_node_table_naive_server").value = "";		//fancyss-full
			E("ss_node_table_naive_port").value = "443";	//fancyss-full
			E("ss_node_table_naive_user").value = "";		//fancyss-full
			E("ss_node_table_naive_pass").value = "";		//fancyss-full
			E("ss_node_table_tuic_json").value = "";		//fancyss-full
			E("ss_node_table_hy2_server").value = "";		//fancyss-full
			E("ss_node_table_hy2_port").value = "";			//fancyss-full
			E("ss_node_table_hy2_pass").value = "";			//fancyss-full
			E("ss_node_table_hy2_tfo").value = "";			//fancyss-full
			E("ss_node_table_hy2_obfs").value = "0";		//fancyss-full
			E("ss_node_table_hy2_obfs_pass").value = "";	//fancyss-full
			E("ss_node_table_hy2_sni").value = "";			//fancyss-full
			E("ss_node_table_hy2_ai").checked = true;		//fancyss-full
			// refresh panel
			refresh_node_panel();
		}
	});
	cancel_add_node();
}
function refresh_node_panel() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			ss_node_sel();
		}
	});
}
function generate_node_info() {
	// 统计节点信息
	ss_nodes = [];
	for (var field in db_ss) {
		var arr = field.split("ssconf_basic_name_");
		if(arr[0] == ""){
			ss_nodes.push(arr[1]);
		}
	}
	ss_nodes = ss_nodes.sort(compare);
	node_nu = ss_nodes.length;
	node_max = ss_nodes.length > 0 ? Math.max.apply(null, ss_nodes) : 0;
	node_idx = $.inArray(db_ss["ssconf_basic_node"], ss_nodes) + 1;
	//console.log("节点排列情况:", ss_nodes);
	//console.log("共有节点数量:", node_nu, "个");
	//console.log("最大节点序号:", node_max);
	//console.log("当前节点位置:", node_idx);
	//console.log("正在使用节点:", parseInt(db_ss["ssconf_basic_node"])||"");

	// 没有节点的时候，弹出添加节点的layer层
	if (node_nu == 0 && poped == 0) pop_node_add();
	// 生成节点对象，用于节点表格、节点下拉表等的制作
	confs = {};
	var p = "ssconf_basic";
	for (var j = 0; j < ss_nodes.length; j++) {
		var idx = ss_nodes[j];
		var obj = {};
		//写入节点index
		obj["node"] = idx;
		//write node type
		if (typeof(db_ss["ssconf_basic_type_" + idx]) != "undefined"){
			obj["type"] = db_ss["ssconf_basic_type_" + idx];
		}
		//这些值统一处理
		var params = ["group", "name", "port", "method", "password", "mode", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "weight", "lbmode", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_show", "xray_json", "tuic_json", "xray_use_json", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_ai", "hy2_tfo"];
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + idx;
			if (typeof db_ss[ofield] == "undefined") {
				obj[params[i]] = '';
			}else{
				obj[params[i]] = db_ss[ofield];
			}
		}
		if(db_ss["ssconf_basic_xray_prot_" + idx] == "vmess"){
			obj["xray_prot"] = "vmess";
		}else{
			obj["xray_prot"] = "vless";
		}
		
		//兼容部分，这些值是空的话需要填为0
		var params_sp = ["use_kcp", "use_lb", "v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http"];
		for (var i = 0; i < params_sp.length; i++) {
			if (typeof db_ss[p + "_" + params_sp[i] + "_" + idx] == "undefined") {
				obj[params_sp[i]] = '0';
			} else {
				obj[params_sp[i]] = db_ss[p + "_" + params_sp[i] + "_" + idx];
			}
		}

		if (typeof db_ss[p + "_server_" + idx] != "undefined") {
			obj["server"] = db_ss[p + "_server_" + idx];
		}else{
			obj["server"] = '';
		}
		//fancyss_tuic_1
		if(db_ss[p + "_type_" + idx] ==  "7"){
			var json = JSON.parse(Base64.decode(db_ss[p + "_tuic_json_" + idx]));
			var server_addr = '';
			if("relay" in json){
				server_addr = json.relay.server;
			}
			obj["server"] = server_addr;
		}
		//fancyss_tuic_2
		if(db_ss[p + "_v2ray_use_json_" + idx] ==  "1"){
			//对v2ray json节点的处理
			var json = JSON.parse(Base64.decode(db_ss[p + "_v2ray_json_" + idx]));
			var server_addr = '';
			var server_prot = '';
			if("outbound" in json){
				if(isArray(json.outbound)){
					//array
					if(json.outbound[0].settings.servers){
						if(isArray(json.outbound[0].settings.servers)){
							server_addr = json.outbound[0].settings.servers[0].address;
						}
					}
					if(json.outbound[0].settings.vnext){
						if(isArray(json.outbound[0].settings.vnext)){
							server_addr = json.outbound[0].settings.vnext[0].address;
						}
					}
					server_prot = json.outbound[0].protocol;
				}else{
					//object
					if(json.outbound.settings.servers){
						if(isArray(json.outbound.settings.servers)){
							server_addr = json.outbound.settings.servers[0].address;
						}
					}
					if(json.outbound.settings.vnext){
						if(isArray(json.outbound.settings.vnext)){
							server_addr = json.outbound.settings.vnext[0].address;
						}
					}
					server_prot = json.outbound.protocol;
				}
			}

			if("outbounds" in json){
				if(isArray(json.outbounds)){
					//array
					if(json.outbounds[0].settings.servers){
						if(isArray(json.outbounds[0].settings.servers)){
							server_addr = json.outbounds[0].settings.servers[0].address;
						}
					}
					if(json.outbounds[0].settings.vnext){
						if(isArray(json.outbounds[0].settings.vnext)){
							server_addr = json.outbounds[0].settings.vnext[0].address;
						}
					}
					server_prot = json.outbounds[0].protocol;
				}else{
					//object
					if(json.outbounds.settings.servers){
						if(isArray(json.outbounds.settings.servers)){
							server_addr = json.outbounds.settings.servers[0].address;
						}
					}
					if(json.outbounds.settings.vnext){
						if(isArray(json.outbounds.settings.vnext)){
							server_addr = json.outbounds.settings.vnext[0].address;
						}
					}
					server_prot = json.outbounds.protocol;
				}
			}
			obj["server"] = server_addr;
			obj["protoc"] = server_prot;
		}
		if(db_ss[p + "_xray_use_json_" + idx] ==  "1"){
			//对xray json节点的处理
			var json = JSON.parse(Base64.decode(db_ss[p + "_xray_json_" + idx]));
			var server_addr = '';
			var server_prot = '';
			if("outbound" in json){
				if(isArray(json.outbound)){
					//array
					if(json.outbound[0].settings.servers){
						if(isArray(json.outbound[0].settings.servers)){
							server_addr = json.outbound[0].settings.servers[0].address;
						}
					}
					if(json.outbound[0].settings.vnext){
						if(isArray(json.outbound[0].settings.vnext)){
							server_addr = json.outbound[0].settings.vnext[0].address;
						}
					}
					server_prot = json.outbound[0].protocol;
				}else{
					//object
					if(json.outbound.settings.servers){
						if(isArray(json.outbound.settings.servers)){
							server_addr = json.outbound.settings.servers[0].address;
						}
					}
					if(json.outbound.settings.vnext){
						if(isArray(json.outbound.settings.vnext)){
							server_addr = json.outbound.settings.vnext[0].address;
						}
					}
					server_prot = json.outbound.protocol;
				}
			}

			if("outbounds" in json){
				if(isArray(json.outbounds)){
					//array
					if(json.outbounds[0].settings.servers){
						if(isArray(json.outbounds[0].settings.servers)){
							server_addr = json.outbounds[0].settings.servers[0].address;
						}
					}
					if(json.outbounds[0].settings.vnext){
						if(isArray(json.outbounds[0].settings.vnext)){
							server_addr = json.outbounds[0].settings.vnext[0].address;
						}
					}
					server_prot = json.outbounds[0].protocol;
				}else{
					//object
					if(json.outbounds.settings.servers){
						if(isArray(json.outbounds.settings.servers)){
							server_addr = json.outbounds.settings.servers[0].address;
						}
					}
					if(json.outbounds.settings.vnext){
						if(isArray(json.outbounds.settings.vnext)){
							server_addr = json.outbounds.settings.vnext[0].address;
						}
					}
					server_prot = json.outbounds.protocol;
				}
			}
			if(server_prot == "shadowsocks"){
				server_prot = "ss";
			}
			obj["server"] = server_addr;
			obj["protoc"] = server_prot;
		}
		//生成一个节点的所有信息到对应对象
		if (obj != null) {
			confs[idx] = obj;
		}
	}
	//console.log("所有节点信息：", confs);
}
function refresh_table() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		cache:false,
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			generate_node_info();
			refresh_options();
			refresh_html();
		}
	});
}
function refresh_html() {
	var pageH = parseInt(E("FormTitle").style.height.split("px")[0]);
	if(db_ss["ss_basic_row"]){
		nodeN = parseInt(db_ss["ss_basic_row"]);
	}
	if(node_nu < 15) nodeN = node_nu;
	var nodeL  = parseInt((pageH-nodeT)/trsH) - 3;
	nodeH = nodeN*trsH
	if (nodeN > nodeL){
		$("#ss_list_table").attr("style", "height:" + (nodeH + trsH) + "px");
	}else{
		$("#ss_list_table").removeAttr("style");
	}

	//console.log("页面整体高度：", pageH);
	//console.log("最大能显示行：", nodeL);
	//console.log("定义的显示行：", nodeN);
	//console.log("实际显示的行：", ss_nodes.length);
	//console.log("节点列表上界：", nodeT);
	//console.log("节点列表高度nodeH：", nodeH);

	// define col width in different situation
	var noserver = parseInt(E("ss_basic_noserver").checked ? "1":"0");
	if(node_nu && db_ss["ss_basic_latency_opt"] != "0"){
		//开启延迟测试
		if(noserver == "1"){
			//关闭server
			var width = ["", "5%", "54%", "0%", "14%", "12%", "10%", "5%", ];
		}else{
			//开启server
			var width = ["", "5%", "28%", "26%", "14%", "12%", "10%", "5%", ];
		}
	}else{
		//关闭延迟测试
		if(noserver == "1"){
			//关闭server
			var width = ["", "5%", "64%", "0%", "16%", "0%", "10%", "5%" ];
		}else{
			//开启server
			var width = ["", "5%", "36%", "30%", "14%", "0%", "10%", "5%" ];
		}
	}
	// make dynamic element
	var html = '';
	html += '<div class="nodeTable" style="height:' + trsH + 'px; margin: -1px 0px 0px 0px; width:750px;">'
	html += '<table width="750px" border="0" align="center" cellpadding="4" cellspacing="0" class="FormTable_table" style="margin:-1px 0px 0px 0px;">'
	html += '<tr height="' + trsH + 'px">'
	html += '<th style="width:' + width[1] + ';">序号</th>'
	html += '<th style="width:' + width[2] + ';cursor:pointer" onclick="hide_name();" title="点我隐藏节点名称信息!" >节点名称</th>'
	if(noserver != "1"){
		html += '<th style="width:' + width[3] + ';cursor:pointer" onclick="hide_server();" title="点我隐藏服务器信息!" >服务器地址</th>'
	}
	html += '<th style="width:' + width[4] + ';">类型</th>'
	if(node_nu && db_ss["ss_basic_latency_opt"] == "1"){
		html += '<th style="width:' + width[5] + ';" id="depay_th">ping/丢包</th>'
	}
	if(node_nu && db_ss["ss_basic_latency_opt"] == "2"){
		html += '<th style="width:' + width[5] + ';" id="depay_th">web落地延迟</th>'
	}
	html += '<th style="width:' + width[6] + ';">编辑</th>'
	html += '<th style="width:' + width[7] + ';">使用</th>'
	html += '</tr>'
	html += '</table>'
	html += '</div>'
	
	//html += '<div class="nodeTable" style="top: ' + nodeT + 'px; width: 750px; height: ' + nodeH + 'px; overflow: hidden; position: absolute;">'
	html += '<div class="nodeTable" style="width: 750px; height: ' + nodeH + 'px; overflow: hidden;">'
	html += '<div id="ss_node_list_table_main" style="width: 750px; height: ' + nodeH + 'px; overflow: hidden scroll; padding-right: 35px;">'
	html += '<table id="ss_node_list_table" style="margin:-1px 0px 0px 0px;" width="750px" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="list_table">'
	
	for (var i = 0; i < ss_nodes.length; i++) {
		var c = confs[ss_nodes[i]];
	//for (var field in confs) {
		//var c = confs[field];
		html += '<tr id="node_' + c["node"] + '">';
		//序号
		html +='<td style="width:' + width[1] + ';" id="node_order_' + (i + 1) + '" class="dragHandle">' + (i + 1) + '</td>';
		//节点名称
		//html += '<td style="width:' + width[2] + ';" class="dragHandle node_name" title="' + c["group"] + '&#10;' + c["name"] + '" id="ss_node_name_' + c["node"] + '" onMouseOver="show_info(this)">'
		html += '<td style="width:' + width[2] + ';" class="dragHandle node_name" title="' + c["group"] + '&#10;' + c["name"] + '" id="ss_node_name_' + c["node"] + '">'
		html += '<div class="shadow1" style="display: none;"></div>'
		html += '<div class="nickname">' + c["name"] + '</div>';
		html += '</td>';
		if(noserver != "1"){
			//server
			if(c["type"] == 6){																						//fancyss-full
				html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';	//fancyss-full
				html += '<div style="display: none;" class="shadow2"></div>';										//fancyss-full
				html += '<div class="server">' + c["naive_server"] + '</div>';										//fancyss-full
				html += '</td>';																					//fancyss-full
			}else if(c["type"] == 8){																				//fancyss-full
				html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';	//fancyss-full
				html += '<div style="display: none;" class="shadow2"></div>';										//fancyss-full
				html += '<div class="server">' + c["hy2_server"] + '</div>';										//fancyss-full
				html += '</td>';																					//fancyss-full
			}else{ 																									//fancyss-full
				if(E("ss_basic_qrcode").checked){
					html += '<td style="width:' + width[3] + ';cursor:pointer" class="node_server" id="server_' + c["node"] + '" title="' + c["server"] + '" onclick="makeQRcode(this)">';
				}else{
					html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';
				}
				html += '<div style="display: none;" class="shadow2"></div>';
				html += '<div class="server">' + c["server"] + '</div>';
				html += '</td>';
			}																										//fancyss-full
		}
		//节点类型
		html +='<td style="width:' + width[4] + ';">';
		switch(c["type"]) {
			case '0' :
				if(E("ss_basic_rust").checked){								//fancyss-full
					if(c["ss_obfs"] == "http" || c["ss_obfs"] == "tls"){	//fancyss-full
						html +='ss_rust-obfs';								//fancyss-full
					}else if(c["ss_v2ray"] == "1"){							//fancyss-full
						html +='ss_rust-v2ray';								//fancyss-full
					}else{													//fancyss-full
						html +='ss_rust';									//fancyss-full
					}														//fancyss-full
				}else{														//fancyss-full
					if(c["ss_obfs"] == "http" || c["ss_obfs"] == "tls"){
						html +='ss-libev+obfs';
					}else if(c["ss_v2ray"] == "1"){							//fancyss-full
						html +='ss-libev+v2ray';							//fancyss-full
					}else{
						html +='ss-libev';
					}
				}															//fancyss-full
				break;
			case '1' :
				html +='ssr';
				break;
			case '3' :
				if(E("ss_basic_vcore").checked){							//fancyss-full
					if(c["protoc"]){
						html +='xray-' + c["protoc"];
					}else{
						html +='xray-vmess';
					}
				}else{														//fancyss-full
					if(c["protoc"]){										//fancyss-full
						html +='v2ray-' + c["protoc"];						//fancyss-full
					}else{													//fancyss-full
						html +='v2ray-vmess';								//fancyss-full
					}														//fancyss-full
				}															//fancyss-full
				break;
			case '4' :
				if(c["protoc"]){
					html +='xray-' + c["protoc"];
				}else{
					html +='xray-' + c["xray_prot"];
				}
				break;
			case '5' :
				if(E("ss_basic_tcore").checked){							//fancyss-full
					html +='xray-trojan';
				}else{														//fancyss-full
					html +='trojan';										//fancyss-full
				}															//fancyss-full
				break;
			case '6' :														//fancyss-full
				html +='Naïve';												//fancyss-full
				break;														//fancyss-full
			case '7' :														//fancyss-full
				html +='tuic';												//fancyss-full
				break;														//fancyss-full
			case '8' :														//fancyss-full
				html +='hysteria2';											//fancyss-full
				break;														//fancyss-full
		}
		html +='</td>';
		//ping/丢包
		if(node_nu && (db_ss["ss_basic_latency_opt"] == "1" || db_ss["ss_basic_latency_opt"] == "2")){
			html += '<td style="width:' + width[5] + ';" id="ss_node_lt_' + c["node"] + '" class="latency"></td>';
		}
		//节点编辑
		html += '<td style="width:' + width[6] + ';">'
		html += '<input style="margin:-2px 0px -4px -2px;" id="dd_node_' + c["node"] + '" class="edit_btn" type="button" onclick="edit_conf_table(this);" value=""><input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="remove_conf_table(this);" value="">'
		html += '</td>';
		//节点应用
		html += '<td style="width:' + width[7] + ';">'
		html += '<div class="deactivate_icon" id="apply_ss_node_' + c["node"] + '" onclick="apply_this_ss_node(this);"></div>';
		html += '</td>';
		html += '</tr>';
	}
	html += '</table>'
	html += '</div>'
	html += '</div>'
	// botton region
	html += '<div align="center" class="nodeTable" id="node_button" style="width: 750px;margin-top:20px">'
	if(node_nu){
		html += '<input class="button_gen" id="dropdownbtn" type="button" value="延迟测试">'
		html += '<div class="dropdown" id="dropdown">'
		html += '<a onclick="test_latency_now(1)" href="javascript:void(0);"></lable>开始 ping 延迟测试<lable id="ss_ping_pts_show"></lable></a>'
		html += '<a onclick="test_latency_now(2)" href="javascript:void(0);"></lable>开始 web 延迟测试<lable id="ss_ping_wts_show"></lable></a>'
		html += '<a onclick="test_latency_now(0)" href="javascript:void(0);"></lable>关闭延迟测试功能</a>'
		html += '<a onclick="open_latency_sett()" href="javascript:void(0);"></lable>设置</a>'
		html += '</div>'
	}
	html += '<input style="margin-left:10px" id="add_ss_node" class="button_gen" onClick="Add_profile()" type="button" value="添加节点"/>'
	if(node_nu){
		html += '<input style="margin-left:10px" class="button_gen" type="button" onclick="save()" value="保存&应用">'
	}
	html += '<input id="reset_select" style="margin-left:10px; display:none" class="button_gen" onClick="select_default_node(1)" type="button" value="取消"/>'
	html += '</div>'
	// remove dynamic table
	$('.nodeTable').remove();
	// add dynamic table
	$('#ss_list_table').before(html);
	if(node_max != 0 && node_max != node_nu ){
		console.log("自动调整顺序！")
		save_new_order();
		//ss_node_sel();
	}
	// ask or not ask for ping
	if(db_ss["ss_basic_latency_opt"]){
		latency_test(db_ss["ss_basic_latency_opt"]);
	}
	// select default node
	select_default_node(2);
	// make row moveable
	if(E("ss_basic_dragable").checked){
		order_adjustment();
	}
	// dp
	if(node_nu){
		const dropdownBtn = E("dropdownbtn");
		const dropdownMenu = E("dropdown");
		// Toggle dropdown function
		const toggleDropdown = function () {
		  var lef = $('#dropdownbtn').offset().left;
		  var top = $('#dropdownbtn').offset().top;
		  var eleh = $("#dropdown").height();
		  $('#dropdown').offset({left: lef, top: (top - eleh)});
		  dropdownMenu.classList.toggle("show");
		};
		// Toggle dropdown open/close when dropdown button is clicked
		dropdownBtn.addEventListener("click", function (e) {
		  e.stopPropagation();
		  toggleDropdown();
		});
		// Close dropdown when dom element is clicked
		E("app").addEventListener("click", function () {
		  if (dropdownMenu.classList.contains("show")) {
		    toggleDropdown();
		  }
		});
	}
}
function hide_name(){
	//var sw = $(".node_name").width();
	var sw = $(".node_name")[0].clientWidth - 4;
	if($(".shadow1").css("display") == "block"){
		$(".nickname").show(300);
		$(".shadow1").hide(300);
	}else{
		$(".nickname").hide(300);
		$(".shadow1").show(300);
		$(".shadow1").css("width", sw)
	}
}
function hide_server(){
	//var sw = $(".node_server").width();
	var sw = $(".node_server")[0].clientWidth - 4;
	if($(".shadow2").css("display") == "block"){
		$(".server").show(300);
		$(".shadow2").hide(300);
	}else{
		$(".server").hide(300);
		$(".shadow2").show(300);
		$(".shadow2").css("width", sw)
	}
}
function order_adjustment(){
	$("#ss_node_list_table").tableDnD({
		dragHandle: ".dragHandle",
		onDragClass: "myDragClass",
		onDrop: function() {
			save_new_order();
		}
	});
	$("#ss_node_list_table tr").hover(function() {
		  $(this.cells[0]).addClass('showDragHandle');
		  $(this.cells[1]).addClass('showDragHandle');
	}, function() {
		  $(this.cells[0]).removeClass('showDragHandle');
		  $(this.cells[1]).removeClass('showDragHandle');
	});
}
function save_new_order(){
	getNowFormatDate();
	var table = E("ss_node_list_table");
	var tr = table.getElementsByTagName("tr");
	var dbus_tmp = {};
	var perf = "ssconf_basic_"
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "use_lb", "ping", "lbmode", "weight", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "xray_uuid", "xray_alterid", "xray_prot", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_network_security_sni", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx","xray_show", "xray_json", "tuic_json", "xray_use_json", "type", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_pass", "hy2_sni", "hy2_ai", "hy2_tfo"];
	//first: mark all node from ss_nodes data as empty
	for (var i = 0; i < tr.length; i++) {
		var rowid = tr[i].getAttribute("id").split("_")[1];
		for (var j = 0; j < temp.length; j++) {
			dbus_tmp[perf + temp[j] + "_" + rowid] = "";
		}
	}
	//second: write new data in order
	for (var i = 0; i < tr.length; i++) {
		//var rowid = tr[i].getAttribute("id").split("_")[1];
		var rowid = tr[i].getAttribute("id").split("_")[1];
		// 如果移动的节点是正在使用的，需要更改到新的位置
		if(db_ss["ssconf_basic_node"] == rowid){
			dbus_tmp["ssconf_basic_node"] = String(i+1);
		}
		// 如果移动的节点是备用节点的，需要更改到新的位置
		if(db_ss["ss_failover_s4_3"] && db_ss["ss_failover_s4_3"] == rowid){
			dbus_tmp["ss_failover_s4_3"] = String(i+1);
		}
		// 生成新的所有节点的信息
		for (var j = 0; j < temp.length; j++) {
			if(db_ss[perf + temp[j] + "_" + rowid]){
				dbus_tmp[perf + temp[j] + "_" + (i + 1)] = db_ss[perf + temp[j] + "_" + rowid];
			}else{
				dbus_tmp[perf + temp[j] + "_" + (i + 1)] = "";
			}
		}
	}
	var post_data = compfilter(db_ss, dbus_tmp);
	//console.log("post_data:", post_data);
	//post data
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": post_data };
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			refresh_dbss();
			reorder_trs();
			refresh_options();
			getNowFormatDate();
			ss_node_sel();
		}
	});
}
function reorder_trs(){
	var trs = $("#ss_node_list_table tr");
	for (var i = 0; i < trs.length; i++) {
		// 改写显示的顺序
		var new_nu = i + 1;
		//tr
		$('#ss_node_list_table tr:nth-child(' + new_nu + ')').attr("id", "node_" + new_nu);
		//$('#ss_node_list_table tr:nth-child(' + new_nu + ')').removeAttr("class");
		//$('#ss_node_list_table tr:nth-child(' + new_nu + ')').removeAttr("style");
		//序号
		$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(1)').attr("id", "node_order_" + new_nu);
		$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(1)').html(String(new_nu));
		//节点名称
		$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(2)').attr("id", "ss_node_name_" + new_nu);
		//服务器地址
		$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(3)').attr("id", "server_" + new_nu);
		//类型
		$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(4)').attr("id", "server_" + new_nu);
		if($('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(5)').attr("id") != undefined){
			//ping/丢包
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(5)').attr("id", "ss_node_lt_" + new_nu);
			//编辑节点
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(6) input:nth-child(1)').attr("id", "dd_node_" + new_nu);
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(6) input:nth-child(2)').attr("id", "td_node_" + new_nu);
			//应用节点
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(7) div').attr("id", "apply_ss_node_" + new_nu);
		}else{
			//编辑节点
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(5) input:nth-child(1)').attr("id", "dd_node_" + new_nu);
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(5) input:nth-child(2)').attr("id", "td_node_" + new_nu);
			//应用节点
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(6) div').attr("id", "apply_ss_node_" + new_nu);
		}
	}
	//console.log("更改顺序OK");
}
function select_default_node(o){
	var sel_node = E("ssconf_basic_node").value||"1";
	$(".activate_icon").addClass("deactivate_icon");
	$(".activate_icon").removeClass("activate_icon");
	if (sel_node != db_ss["ssconf_basic_node"]){
		E("reset_select").style.display = "";
	}else{
		E("reset_select").style.display = "none";
	}
	if(node_max == 0){
		E("reset_select").style.display = "none";
	}
	if(o == 1){
		//定义取消按钮点击行为
		if(db_ss["ss_basic_enable"] == "1"){
			//开启开关，节点选择为db_ss["ssconf_basic_node"]
			E("ss_basic_enable").checked = true;
			$("#apply_ss_node_" + db_ss["ssconf_basic_node"]).addClass("activate_icon");
			$("#apply_ss_node_" + db_ss["ssconf_basic_node"]).removeClass("deactivate_icon");
			if(node_idx && node_nu > nodeN){
				var rows2scroll = parseInt(((node_idx*trsH - nodeH*0.5)/trsH));
				E("ss_node_list_table_main").scrollTop = rows2scroll*trsH;
			}
		}else{
			//关闭开关，则清除节点的勾选
			E("ss_basic_enable").checked = false;
		}
		$("#reset_select").hide();
	}else if(o == 2){
		//定义点击总开关行为 + 表格加载完毕行为
		if(E("ss_basic_enable").checked){
			//用户点击开启了总开关，节点选择为db_ss["ssconf_basic_node"]，没有就默认选1
			$("#apply_ss_node_" + sel_node).addClass("activate_icon");
			$("#apply_ss_node_" + sel_node).removeClass("deactivate_icon");
			if(node_idx && node_nu > nodeN){
				var rows2scroll = parseInt(((node_idx*trsH - nodeH*0.5)/trsH));
				E("ss_node_list_table_main").scrollTop = rows2scroll*trsH;
			}
		}
	}else if(o == 3){
		//从其它标签切换到节点列表行为
		if(E("ss_basic_enable").checked){
			$("#apply_ss_node_" + sel_node).addClass("activate_icon");
			$("#apply_ss_node_" + sel_node).removeClass("deactivate_icon");
			node_idx_1 = $.inArray(E("ssconf_basic_node").value, ss_nodes) + 1;
			if(node_idx_1 && node_nu > nodeN){
				var rows2scroll = parseInt(((node_idx_1*trsH - nodeH*0.5)/trsH));
				E("ss_node_list_table_main").scrollTop = rows2scroll*trsH;
			}
		}
	}
}
function apply_this_ss_node(rowdata) {
	cancel_add_node();
	var enable_id = $(rowdata).attr("id");
	var enable_id = enable_id.split("_")[3];
	var $activateItem = $(rowdata);
	var flag = $activateItem.hasClass("activate_icon") ? "disconnect" : "connect";
	$(".activate_icon").addClass("deactivate_icon");
	$(".activate_icon").removeClass("activate_icon");
	if(flag == "disconnect") {
		$activateItem.addClass("deactivate_icon");
		$activateItem.removeClass("activate_icon");
		E("reset_select").style.display = ""
		E("ss_basic_enable").checked = false;
	}else {
		$activateItem.addClass("activate_icon");
		$activateItem.removeClass("deactivate_icon");
		dbus["ssconf_basic_node"] = enable_id;
		if(db_ss["ssconf_basic_node"] != enable_id){
			E("reset_select").style.display = ""
		}else{
			E("reset_select").style.display = "none"
		}
		E("ss_basic_enable").checked = true;
	}
	E("ssconf_basic_node").value = enable_id;
	ss_node_sel();
}
function makeQRcode(node){
	var id = $(node).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	var c = confs[id];
	if(c["type"] == "0"){
		if(c["ss_v2ray"] == "1"){																																																		//fancyss-full
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"])) + "@" + c["server"] + ":" + c["port"] + "/?plugin=" + encodeURIComponent("v2ray-plugin;" +c["ss_v2ray_opts"]) + "#" + c["name"];		//fancyss-full
		}else{																																																							//fancyss-full
			if(c["ss_obfs"] == "1"){
				var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"])) + "@" + c["server"] + ":" + c["port"] + "/?plugin=obfs-local%3Bobfs%3D" + c["ss_obfs"] + "%3Bobfs-host%3D" + c["ss_obfs_host"] + "#" + c["name"];
			}else{
				var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"]) + "@" + c["server"] + ":" + c["port"] + "#" + c["name"]);
			}
		}																																																								//fancyss-full
	}
	else if(c["type"] == "1"){
    	var base64pass = c["password"].replace(/=+/,"");
    	var base64obfsparm = Base64.encode(c["rss_obfs_param"]).replace(/=+/,"");
    	var base64protoparam = Base64.encode(c["rss_protocol_param"]).replace(/=+/,"");
    	var base64remark = Base64.encode(c["name"]).replace(/=+/,"");
    	var base64group = Base64.encode(c["group"]).replace(/=+/,"");
    	var config_ssr = c["server"] + ":" + c["port"] + ":" + c["rss_protocol"] + ":" + c["method"] + ":" + c["rss_obfs"] + ":" + base64pass + "/?obfsparam=" + base64obfsparm + "&protoparam=" + base64protoparam + "&remarks=" + base64remark + "&group=" + base64group;
    	var code = "ssr:\/\/" + Base64.encode(config_ssr).replace(/=+/,"").replace(/\+/,"-").replace(/\//,"_");
	}
	else if(c["type"] == "3"){
		if(c["v2ray_use_json"] == "1"){
			var code = 1;
		}else{
			var code = {};
			code.ps = c["name"];
			code.v = "2";
			code.add = c["server"];
			code.port = c["port"];
			code.id = c["v2ray_uuid"];
			code.aid = c["v2ray_alterid"];
			code.net = c["v2ray_network"];
			code.host = c["v2ray_network_host"];
			code.path = c["v2ray_network_path"];
			code.tls = c["v2ray_network_security"];
			if(c["v2ray_network"] == "tcp"){
				code.type = c["v2ray_headtype_tcp"];
			}else if(c["v2ray_network"] == "kcp"){
				code.type = c["v2ray_headtype_kcp"];
			}else if(c["v2ray_network"] == "quic"){
				code.type = c["v2ray_headtype_quic"];
			}
			code = "vmess:\/\/" + Base64.encode(JSON.stringify(code));
		}
	}
	else if(c["type"] == "4"){
		var code = 2;
	}
	else if(c["type"] == "5"){
		var code = 3;
	}
	else{
		var code = 4;
	}
	$("#qrtitle").html(c["name"]);
	$("#qrcode_show").css("top", "240px");

	showQRcode(code);
}
function showQRcode(data) {
	$("#qrcode").html("");
	if(data == 1){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">暂不支持v2ray json配置的二维码生成！</span>')
	}
	else if(data == 2){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">暂不支持xray节点的二维码生成！</span>')
	}
	else if(data == 3){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">暂不支持trojan节点的二维码生成！</span>')
	}
	else if(data == 4){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">错误！！节点类型位置！！<br />请检查你的节点！</span>')
	}
	else
	{
		require(['/res/qrcode.js'], function() {
			var qrcode = new QRCode(E("qrcode"), {
				text: data,
				width: 256,
				height: 256,
				colorDark : "#000000",
				colorLight : "#ffffff",
				correctLevel : QRCode.CorrectLevel.H
			});
		});
	}
	$("#qrcode_show").fadeIn(200);
}
function cleanCode(){
	$("#qrcode_show").fadeOut(300);
}
function open_latency_sett() {
	update_visibility();
	// show
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').show();
	document.scrollingElement.scrollTop = 0;
	E("latency_test_settings").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var elem_h = E("latency_test_settings").clientHeight;
	var elem_w = E("latency_test_settings").clientWidth;
	var elem_h_offset = (page_h - elem_h) / 2 - 90;
	var elem_w_offset = (page_w - elem_w) / 2 + 90;
	if(elem_h_offset < 0){
		elem_h_offset = 10;
	}
	$('#latency_test_settings').offset({top: elem_h_offset, left: elem_w_offset});
}
function leav_test_sett() {
	E("latency_test_settings").style.visibility = "hidden";
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
}
function save_latency_sett(){
	var dbus_post = {};
	var post_para = 0;
	dbus_post["ss_basic_pingm"] = E("ss_basic_pingm").value;
	dbus_post["ss_basic_wt_furl"] = E("ss_basic_wt_furl").value;
	dbus_post["ss_basic_wt_curl"] = E("ss_basic_wt_curl").value;
	dbus_post["ss_basic_lt_cru_opts"] = E("ss_basic_lt_cru_opts").value;
	dbus_post["ss_basic_lt_cru_time"] = E("ss_basic_lt_cru_time").value;
	var post_dbus = compfilter(db_ss, dbus_post);
	if(isObjectEmpty(post_dbus) == false){
		if(post_dbus.hasOwnProperty("ss_basic_wt_furl")){
			post_para += 1;
		}
		if(post_dbus.hasOwnProperty("ss_basic_wt_curl")){
			post_para += 2;
		}
		//console.log(post_para);
		//console.log(post_dbus);
		//now post
		var id = parseInt(Math.random() * 100000000);
		var postData = {"id": id, "method": "ss_ping.sh", "params":[post_para], "fields": post_dbus};
		$.ajax({
			type: "POST",
			cache:false,
			url: "/_api/",
			data: JSON.stringify(postData),
			dataType: "json",
			success: function(response) {
				if (response.result == id){
					leav_test_sett();
					refresh_dbss();
				}
			}
		});
	}else{
		leav_test_sett();
	}
}
function test_latency_now(test_flag) {
	var dbus_post = {};
	dbus_post["ss_basic_latency_opt"] = test_flag;
	if(test_flag == 0){
		var post_para = "close_latency_test";
	}else if(test_flag == 1){
		var post_para = "manual_ping";
	}else if(test_flag == 2){
		var post_para = "manual_webtest";
	}
	//now post
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_ping.sh", "params":[post_para], "fields": dbus_post};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if (response.result == id){
				$(".show-btn1").trigger("click");
				refresh_table();
				if(test_flag == 0){
					close_latency_flag=1;
					$("#ss_ping_pts_show").html("");
					$("#ss_ping_wts_show").html("");
					$("#dropdown").width(150);
				}
				if(test_flag == "1"){
					$(".latency").html("waiting...");
				}
				if(test_flag == "2"){
					$(".latency").html("waiting...");
				}
			}
		}
	});
}
function latency_test(action) {
	if(action == "0") return;
	//console.log("start latency test")
	
	if(action == "1"){
		var bash_para = "web_ping";
	}
	if(action == "2"){
		var bash_para = "web_webtest";
	}
	//now post
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_ping.sh", "params":[bash_para], "fields": ""};
	$.ajax({
		type: "POST",
		async: true,
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			//console.log(response.result)
			if(db_ss["ss_basic_latency_opt"] == "1"){
				$(".latency").html("waiting...");
			}else if(db_ss["ss_basic_latency_opt"] == "2"){
				$(".latency").html("waiting...");
			}
			get_latency_data(action);
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			$(".latency").html("失败!");
		},
		timeout: 60000
	});
}
function get_latency_data(action){
	if(close_latency_flag == 1) return false;
	if(action == "1"){
		var URL = '/_temp/ping.txt'
	}else if(action == "2"){
		var URL = '/_temp/webtest.txt'
	}
	$.ajax({
		url: URL,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			if(action == "1"){
				// getting ping results
				const lines = res.split('\n');
				const array = [];
				lines.forEach(line => {
					const parts = line.split('>').map(part => part.trim());
					const item = [parts[0], parts[1], parts[2]];
					array.push(item);
				});
				write_ping(array);
				const hasStop = array.some(subArray => subArray.includes('stop'));
				if(hasStop){
					//console.log("stop getting ping result!");
					$.ajax({
						type: "GET",
						url: "/_api/ss_basic_ping_ts",
						dataType: "json",
						async: false,
						success: function(data) {
							db_get = data.result[0];
							if(db_get["ss_basic_ping_ts"]){
								$("#ss_ping_pts_show").html("<em>【上次完成时间: " + db_get["ss_basic_ping_ts"] + "】</em>")
								$("#dropdown").width(370);
							}
						}
					});
				}else{
					//console.log("getting ping result...");
					setTimeout("get_latency_data(1);", 1000);
				}
			}else if(action == "2"){
				// getting webtest results
				const lines = res.split('\n');
				const array = [];
				lines.forEach(line => {
					const parts = line.split('>').map(part => part.trim());
					const item = [parts[0], parts[1]];
					array.push(item);
				});
				write_webtest(array);
				const hasStop = array.some(subArray => subArray.includes('stop'));
				if(hasStop){
					//console.log("stop getting webtest result!");
					$.ajax({
						type: "GET",
						url: "/_api/ss_basic_webtest_ts",
						dataType: "json",
						async: false,
						success: function(data) {
							db_get = data.result[0];
							if(db_get["ss_basic_webtest_ts"]){
								$("#ss_ping_wts_show").html("<em>【上次完成时间: " + db_get["ss_basic_webtest_ts"] + "】</em>")
								$("#dropdown").width(370);
							}
						}
					});
				}else{
					//console.log("getting webtest result...");
					setTimeout("get_latency_data(2);", 1000);
				}
			}
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			setTimeout("get_latency_data(" + action + ");", 1000);
		},
	});
}
function write_ping(ps){
	for(var i = 0; i<ps.length; i++){
		var nu = ps[i][0];
		var ping = parseFloat(ps[i][1]);
		if (nu == "stop"){
			console.log("stop flag detected!")
			continue;
		}
		var loss = ps[i][2];
		if (!ping){
			if(E("ss_basic_pingm").value == 1){
				test_result = '<font color="#FF0000">failed</font>';
			}else{
				if(loss == ""){
					test_result = '<font color="#FF0000">failed</font>';
				}else{
					test_result = '<font color="#FF0000">failed/' + loss + '</font>';
				}
			}
		}else{
			if(E("ss_basic_pingm").value == 1){
				$('#depay_th').html("ping");
				if (ping <= 50){
					test_result = '<font color="#1bbf35">' + ping.toPrecision(3) +'ms</font>';
				}else if (ping > 50 && ping <= 100) {
					test_result = '<font color="#3399FF">' + ping.toPrecision(3) +'ms</font>';
				}else{
					test_result = '<font color="#f36c21">' + ping.toPrecision(3) +'ms</font>';
				}
			}else{
				$('#depay_th').html("ping/丢包");
				if (ping <= 50){
					test_result = '<font color="#1bbf35">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
				}else if (ping > 50 && ping <= 100) {
					test_result = '<font color="#3399FF">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
				}else{
					test_result = '<font color="#f36c21">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
				}
			}
		}		
		if($('#ss_node_lt_' + nu)){
			$('#ss_node_lt_' + nu).html(test_result);
		}
	}
}
function write_webtest(ps){
	for(var i = 0; i<ps.length; i++){
		var nu = ps[i][0];
		var lag = ps[i][1];
		if($.isNumeric(lag)){
			if (lag <= 100){
				test_result = '<font color="#1bbf35">' + lag +' ms</font>';
			}else if (lag > 100 && lag <= 200) {
				test_result = '<font color="#3399FF">' + lag +' ms</font>';
			}else if (lag > 200 && lag <= 300) {
				test_result = '<font color="#f36c21">' + lag +' ms</font>';
			}else{
				test_result = '<font color="#FF0066">' + lag +' ms</font>';
			}
		}else{
			if(lag == "failed"){
				test_result = '<font color="#FF0000">failed!</font>';
			}else if(lag == "ns"){
				test_result = '<font color="#FF0000">不支持!</font>';
			}else{
				test_result = '<font color="#00FFCC">' + lag +'</font>'
			}
		}
		
		if($('#ss_node_lt_' + nu)){
			$('#ss_node_lt_' + nu).html(test_result);
		}
	}
}
function save_row(action) {
	var dbus_post = {};
	//设定要显示的节点列表行数
	dbus_post["ss_basic_row"] = E("ss_basic_row").value;
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": dbus_post};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if (response.result == id){
				$(".show-btn1").trigger("click");
				refresh_table();
			}
		}
	});
}
function download_route_file(arg) {
	var dbus_tmp={};
	if(arg == 2){
		db_ss["ss_basic_action"] = "11";
		showSSLoadingBar();
		setTimeout("get_realtime_log();", 600);
	}
	if(arg == 10){
		var dbus_tmp = dns_log;
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params":[arg], "fields": dbus_tmp };
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		cache:false,
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			if(response.result == id){
				if(arg == 1){
					var a = document.createElement('A');
					a.href = "_root/files/ssconf_backup.sh";
					a.download = 'ssconf_backup.sh';
					document.body.appendChild(a);
					a.click();
					document.body.removeChild(a);
				}
				else if(arg == 2){
					var b = document.createElement('A')
					b.href = "_root/files/" + pkg_name + "_" + db_ss["ss_basic_version_local"] + ".tar.gz"
					b.download = pkg_name + "_" + db_ss["ss_basic_version_local"] + ".tar.gz"
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}
				else if(arg == 6){
					var b = document.createElement('A')
					b.href = "_root/files/ssf_status.txt"
					b.download = 'ssf_status.txt'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}
				else if(arg == 7){
					var b = document.createElement('A')
					b.href = "_root/files/ssc_status.txt"
					b.download = 'ssc_status.txt'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}
				else if(arg == 10){
					var b = document.createElement('A')
					b.href = "_root/files/"+ dns_log["ss_basic_logname"] +".txt"
					b.download = dns_log["ss_basic_logname"] + '.txt'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}
				else if(arg == 11){
					var b = document.createElement('A')
					b.href = "_root/files/dns_dig_result.txt"
					b.download = 'dns_dig_result.txt'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}
			}
		}
	});
}
function upload_ss_backup() {
	db_ss["ss_basic_action"] = "9";
	var filename = $("#ss_file").val();
	filename = filename.split('\\');
	filename = filename[filename.length - 1];
	var filelast = filename.split('.');
	filelast = filelast[filelast.length - 1];
	if (filelast != "sh" && filelast != "json") {
		alert('备份文件格式不正确！');
		return false;
	}
	E('ss_file_info').style.display = "none";
	var formData = new FormData();
	if (filelast == 'sh'){
		formData.append("ssconf_backup.sh", $('#ss_file')[0].files[0]);
	}else if(filelast == 'json'){
		formData.append("ssconf_backup.json", $('#ss_file')[0].files[0]);
	}
	$.ajax({
		url: '/_upload',
		type: 'POST',
		cache: false,
		data: formData,
		processData: false,
		contentType: false,
		complete: function(res) {
			if (res.status == 200) {
				E('ss_file_info').style.display = "block";
				restore_ss_conf();
			}
		}
	});
}
function restore_ss_conf() {
	showSSLoadingBar();
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params": ["4"], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			get_realtime_log();
		}
	});
}
function remove_SS_node() {
	db_ss["ss_basic_action"] = "10";
	push_data("ss_conf.sh", "3",  "");
}
function restart_dnsmaq() {
	db_ss["ss_basic_action"] = "21";
	showSSLoadingBar();
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params": ["8"], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			get_realtime_log();
		}
	});
}
function remove_doh_cache() {
	db_ss["ss_basic_action"] = "24";
	showSSLoadingBar();
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params": ["9"], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			get_realtime_log();
		}
	});
}
function updatelist(arg) {
	var dbus_post = {};
	db_ss["ss_basic_action"] = "8";
	dbus_post["ss_basic_rule_update"] = E("ss_basic_rule_update").value;
	dbus_post["ss_basic_rule_update_time"] = E("ss_basic_rule_update_time").value;
	dbus_post["ss_basic_gfwlist_update"] = E("ss_basic_gfwlist_update").checked ? '1' : '0';
	dbus_post["ss_basic_chnroute_update"] = E("ss_basic_chnroute_update").checked ? '1' : '0';
	dbus_post["ss_basic_cdn_update"] = E("ss_basic_cdn_update").checked ? '1' : '0';
	push_data("ss_rule_update.sh", arg,  dbus_post);
}
function version_show() {
	if(!db_ss["ss_basic_version_local"]) db_ss["ss_basic_version_local"] = "0.0.0"
	$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(0);'><i>当前版本：" + db_ss['ss_basic_version_local'] + "</i></a>");
	$.ajax({
		url: 'https://raw.githubusercontent.com/hq450/fancyss/3.0/packages/version.json.js',
		type: 'GET',
		dataType: 'json',
		success: function(res) {
			if (typeof(res["version"]) != "undefined" && res["version"].length > 0) {
				if (versionCompare(res["version"], db_ss["ss_basic_version_local"])) {
					$("#updateBtn").html("<i>升级到：" + res.version + "</i>");
				}
			}
		}
	});
}
function message_show() {
	if (db_ss["ss_close_mesg"] == "0") return
	$.ajax({
		url: 'https://gist.githubusercontent.com/hq450/001dd0617a64e11a9492dcf9205a0e03/raw/fancyss_msg.json?_=' + new Date().getTime(),
		type: 'GET',
		dataType: 'json',
		cache: false,
		success: function(res) {
			var rand_1 = parseInt(Math.random() * 100)
			// 通知1，一般通知下更新日志，如果已经升级到最新版本，则不再显示更新日志
			if (res["msg_1"] && res["switch_1"]){
				if (rand_1 < res["switch_1"]){
					if (versionCompare(res["version"], db_ss["ss_basic_version_local"])) {
						$("#fixed_msg").append('<li id="msg_1" style="list-style: none;height:23px">' + res["msg_1"] + '</li>');
					}
				}
			}
			// 通知2，其它重要通知的时候使用
			if (res["msg_2"] && res["switch_2"]){
				if (rand_1 < res["switch_2"]){
					$("#fixed_msg").append('<li id="msg_2" style="list-style: none;height:23px">' + res["msg_2"] + '</li>');
				}
			}
			// 广告位，广告不能放太多，要优质，稍多的话限制显示数量，以滚动形式显示，免得太碍人眼
			var ads_count = 0;
			var rand_2 = parseInt(Math.random() * 100)
			for(var i = 3; i < 10; i++){
				if (res["msg_" + i] && res["switch_" + i]){
					if (rand_2 < res["switch_" + i]){
						$("#scroll_msg").append('<li id="msg_' + i + '" style="list-style: none;height:23px">' + res["msg_" + i] + '</li>');
						ads_count++;
					}
				}
			}
			// 如果只有两个广告，就全部显示，且不进行滚动
			//console.log(ads_count + "个广告！")
			if (ads_count == 0) return;
			if (ads_count <= 2){
				$("#scroll_msg").css("height", (ads_count * 23) + "px");
				return;
			}
			//超过两个广告，则广告显示高度为推送的高度
			if (res["scroll_line"]){
				$("#scroll_msg").css("height", (res["scroll_line"] * 23) + "px");
			}else{
				$("#scroll_msg").css("height", "23px");
			}
			//鼠标放上广告停止滚动
			$("#scroll_msg").on("mouseover", function() {
				stop_scroll = 1;
			});
			//鼠标移开恢复滚动
			$("#scroll_msg").on("mouseleave", function() {
				stop_scroll = 0;
			});
			//开始滚动，每个广告停留5s
			if (res["ads_time"]){
				setInterval("scroll_msg();", res["ads_time"]);
			}else{
				setInterval("scroll_msg();", 5000);
			}
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			console.log(XmlHttpRequest.responseText);
		}
	});
}
function scroll_msg() {
	if(stop_scroll == 0) {
		$('#scroll_msg').stop().animate({scrollTop: 23}, 500, 'swing', function() {
			$(this).find('li:last').after($('li:first', this));
		});
	}
}
function update_ss() {
	var dbus_post = {};
	db_ss["ss_basic_action"] = "7";
	push_data("ss_update.sh", "update",  dbus_post);
}

function tabSelect(w) {
	for (var i = 0; i <= 10; i++) {
		$('.show-btn' + i).removeClass('active');
		$('#tablet_' + i).hide();
	}
	$('.show-btn' + w).addClass('active');
	$('#tablet_' + w).show();	
}

function toggle_func() {
	$("#ss_basic_enable").click(
	function() {
		select_default_node(2);
		if (E("ss_basic_enable").checked) {
			if(node_max == 0){
				alert("你还没有任何节点，无法开启！");
				return false;
			}
			E("reset_select").style.display = db_ss["ss_basic_enable"] == "1" ? "none":"";
		}else{
			E("reset_select").style.display = db_ss["ss_basic_enable"] == "1" ? "":"none";
		}
	});
	$(".show-btn0").click(
		function() {
			tabSelect(0);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			//ss_node_sel();
			showhide("table_basic", (node_max != 0));
			change_select_width('#ssconf_basic_node');
			//E("ss_basic_hy2_server").style.width = Math.max(E("ss_basic_hy2_server").value.length, 21) + 'ch';	//fancyss-full
			//E("ss_basic_hy2_pass").style.width = Math.max(E("ss_basic_hy2_pass").value.length, 21) + 'ch';
			//E("ss_basic_hy2_sni").style.width = Math.max(E("ss_basic_hy2_sni").value.length, 21) + 'ch';
		});
	$(".show-btn1").click(
		function() {
			tabSelect(1);
			$('#apply_button').hide();
			$(".nodeTable").show();
			select_default_node(3);
		});
	$(".show-btn2").click(
		function() {
			tabSelect(2);
			$('#apply_button').show();
			$('#ss_failover_save').show();
			verifyFields();
		});
	$(".show-btn3").click(
		function() {
			tabSelect(3);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			change_select_width('#ss_china_dns', '0');
			change_select_width('#ss_foreign_dns', '0');
			change_select_width('#ss_basic_chng_china_1_udp', '1');
			change_select_width('#ss_basic_chng_china_1_tcp', '1');
			change_select_width('#ss_basic_chng_china_1_doh', '1');				//fancyss-full
			change_select_width('#ss_basic_chng_china_2_udp', '1');
			change_select_width('#ss_basic_chng_china_2_tcp', '1');
			change_select_width('#ss_basic_chng_china_2_doh', '1');				//fancyss-full
			//change_select_width('#ss_basic_chng_trust_1_opt');
			change_select_width('#ss_basic_chng_trust_1_opt_udp_val', '1');
			change_select_width('#ss_basic_chng_trust_1_opt_tcp_val', '1');
			change_select_width('#ss_basic_chng_trust_1_opt_doh_val', '1');		//fancyss-full
			//change_select_width('#ss_basic_chng_trust_2_opt');
			change_select_width('#ss_basic_chng_trust_2_opt_doh', '1');			//fancyss-full
			change_select_width('#ss_basic_smrt');								//fancyss-full
			change_select_width('#ss_basic_dohc_udp_china', '1');				//fancyss-full
			change_select_width('#ss_basic_dohc_tcp_china', '1');				//fancyss-full
			change_select_width('#ss_basic_dohc_doh_china', '1');				//fancyss-full
			change_select_width('#ss_basic_dohc_tcp_foreign', '1');				//fancyss-full
			change_select_width('#ss_basic_dohc_doh_foreign', '1');				//fancyss-full
			change_select_width('#ss_basic_dohc_cache_timeout', '0');			//fancyss-full
			change_select_width('#ss_basic_server_resolv');
			change_select_width('#ss_basic_dig_opt');
			update_visibility();
			autoTextarea(E("ss_dnsmasq"), 0, 500);
		});
	$(".show-btn4").click(
		function() {
			tabSelect(4);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			autoTextarea(E("ss_wan_white_ip"), 0, 400);
			autoTextarea(E("ss_wan_white_domain"), 0, 400);
			autoTextarea(E("ss_wan_black_ip"), 0, 400);
			autoTextarea(E("ss_wan_black_domain"), 0, 400);
		});
	//fancyss_full_1
	$(".show-btn5").click(
		function() {
			tabSelect(5);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			verifyFields();
			autoTextarea(E("ss_basic_kcp_parameter"), 0, 100);
		});
	$(".show-btn6").click(
		function() {
			tabSelect(6);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			update_visibility();
			verifyFields();
			get_udp_status();
		});
	//fancyss_full_2
	$(".show-btn7").click(
		function() {
			tabSelect(7);
			$('#apply_button').hide();
			$('#ss_failover_save').hide();
			update_visibility();
		});
	$(".show-btn8").click(
		function() {
			tabSelect(8);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			refresh_acl_table();
			//update_visibility();
		});
	$(".show-btn9").click(
		function() {
			tabSelect(9);
			$('#apply_button').show();
			$('#ss_failover_save').hide();
			update_visibility();
		});
	$(".show-btn10").click(
		function() {
			tabSelect(10);
			$('#apply_button').hide();
			$('#ss_failover_save').hide();
			get_log();
		});
	$("#log_content2").click(
		function() {
			x = -1;
		});
	$(".sub-btn1").click(
	function() {
		$('.sub-btn1').addClass('active2');
		$('.sub-btn2').removeClass('active2');
		verifyFields()
	});
	$(".sub-btn2").click(
	function() {
		$('.sub-btn1').removeClass('active2');
		$('.sub-btn2').addClass('active2');
		verifyFields()
	});
	var default_tab = parseInt(E("ss_basic_tablet").checked ? "1":"0");
	if (node_nu == 0 && poped == 0) {
		$(".show-btn1").trigger("click");
	}else{
		$(".show-btn" + default_tab).trigger("click");
	}
}

function change_select_width(o, p) {
	$(o).click(function(){
		var text = $(this).find('option:selected').text();
		var className = $(o).attr('class');
		var $aux = $('<select class="' + className + '">').append($('<option/>').text(text));
		$(this).after($aux);
		var aux_width=$aux.width();
		if(aux_width < 135 && p == "1"){
			aux_width = 135;
		}
		if(aux_width < 118 && p == "0"){
			aux_width = 118;
		}
		$(this).width(aux_width);
		$aux.remove();
	}).click();
}

function get_ss_status() {
	if (db_ss['ss_basic_enable'] != "1") {
		E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
		E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
		return false;
	}

	if(db_ss["ss_failover_enable"] == "1"){
		get_ss_status_back();
	}else{
		get_ss_status_front();
	}
}
function get_ss_status_front() {
	if (ws_enable != 1){
		get_ss_status_front_httpd();
		return false;
	}
	if (window.location.protocol != "http:"){
		get_ss_status_front_httpd();
		return false;
	}
	wss = new WebSocket("ws://" + hostname + ":803/");
	wss.onopen = function() {
		//console.log('成功建立websocket链接，开始获取后台状态1...');
		wss_open = 1;
		get_ss_status_front_websocket();
	};
	wss.onerror = function(event) {
		//console.log('WS Error 1: ' + event.data);
		wss_open = 0;
		get_ss_status_front_httpd();
	};
	wss.onclose = function() {
		//console.log('WS DISCONNECT');
		wss_open = 0;
		get_ss_status_front_httpd();
	};
	wss.onmessage = function(event) {
		// 运行状态
		var res = event.data;
		//console.log(res);
		if(res.indexOf("@@") != -1){
			var arr = res.split("@@");
			if (arr[0] == "" || arr[1] == "") {
				E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
				E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
			} else {
				E("ss_state2").innerHTML = arr[0];
				E("ss_state3").innerHTML = arr[1];
			}
		}else{
			E("ss_state2").innerHTML = "国外连接 - " + "Waiting ...";
			E("ss_state3").innerHTML = "国内连接 - " + "Waiting ...";
		}
	}
}

function get_ss_status_front_httpd() {
	if (submit_flag == "1") {
		//console.log("wait for 5s to get next status...")
		setTimeout("get_ss_status_front_httpd();", 5000);
		return false;
	}

	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_status.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		cache: false,
		data: JSON.stringify(postData),
		success: function(response) {
			var arr = response.result.split("@@");
			if (arr[0] == "" || arr[1] == "") {
				E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
				E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
			} else {
				E("ss_state2").innerHTML = arr[0];
				E("ss_state3").innerHTML = arr[1];
			}
		}
	});
	//refreshRate = Math.floor(Math.random() * 4000) + 4000;
	//1: 2-3s, 2:4-7s, 3:8-15s, 4:16-31s, 5:32-63s
	var time_plus = Math.pow("2", String(db_ss['ss_basic_interval']||"2")) * 1000;
	var time_base = time_plus - 1000;
	refreshRate = Math.floor(Math.random() * time_base) + time_plus ;
	setTimeout("get_ss_status_front_httpd();", refreshRate);
}
function get_ss_status_front_websocket() {
	if (submit_flag == "1") {
		//console.log("wait for 5s to get next status...")
		setTimeout("get_ss_status_front_websocket();", 5000);
		return false;
	}
	
	try {
		wss.send("sh /koolshare/scripts/ss_status.sh ws");
	} catch (ex) {
		console.log('Cannot send: ' + ex);
	}
	if (wss_open == "1"){
		var time_plus = Math.pow("2", String(db_ss['ss_basic_interval']||"2")) * 1000;
		var time_base = time_plus - 1000;
		refreshRate = Math.floor(Math.random() * time_base) + time_plus ;
		setTimeout("get_ss_status_front_websocket();", refreshRate);
	}
}
function get_ss_status_back() {
	if (E("ss_basic_interval").value == "1"){
		var time_wait = 3000;
	}else if(E("ss_basic_interval").value == "2"){
		var time_wait = 7000;
	}else if(E("ss_basic_interval").value == "3"){
		var time_wait = 15000;
	}else if(E("ss_basic_interval").value == "4"){
		var time_wait = 31000;
	}else if(E("ss_basic_interval").value == "5"){
		var time_wait = 63000;
	}
	//console.log("time_wait: ", time_wait);
	
	if (ws_enable != 1){
		get_ss_status_back_httpd();
		return false;
	}
	if (window.location.protocol != "http:"){
		get_ss_status_back_httpd();
		return false;
	}
	//wss = new WebSocket('ws://192.168.60.1:803/');
	wss = new WebSocket("ws://" + hostname + ":803/");
	wss.onopen = function() {
		//console.log('成功建立websocket链接，开始获取后台状态2...');
		wss_open = 1;
		get_ss_status_back_websocket();
	};
	wss.onerror = function(event) {
		//console.log('WS Error 2: ' + event.data);
		wss_open = 0;
		get_ss_status_back_httpd();
	};
	wss.onclose = function() {
		//console.log('WS DISCONNECT');
		wss_open = 0;
		get_ss_status_back_httpd();
	};
	wss.onmessage = function(event) {
		// 运行状态
		var res = event.data;
		//console.log(res);
		if(res.indexOf("@@") != -1){
			var arr = res.split("@@");
			if (arr[0] == "" || arr[1] == "") {
				E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
				E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
			} else {
				E("ss_state2").innerHTML = arr[0];
				E("ss_state3").innerHTML = arr[1];
			}
			if (arr[2] == "1") {
				var dbus_post = {};
				dbus_post["ss_heart_beat"] = "0";
				push_data("dummy_script.sh", "", dbus_post, "2");
				// require(['/res/layer/layer.js'], function(layer) {
				// 	layer.confirm('<li>科学上网插件页面需要刷新！</li><br /><li>由于故障转移功能已经在后台切换了节点，为了保证页面显示正确配置！需要刷新此页面！</li><br /><li>确定现在刷新吗？</li>', {
				// 		time: 3e4,
				// 		shade: 0.8
				// 	}, function(index) {
				// 		layer.close(index);
				// 		refreshpage();
				// 	}, function(index) {
				// 		layer.close(index);
				// 		return false;
				// 	});
				// });
			}
		}else{
			E("ss_state2").innerHTML = "国外连接 - " + "Waiting ...";
			E("ss_state3").innerHTML = "国内连接 - " + "Waiting ...";
		}
	};
}
function get_ss_status_back_websocket() {
	try {
		wss.send("cat /tmp/upload/ss_status.txt");
	} catch (ex) {
		console.log('Cannot send: ' + ex);
	}
	if (wss_open == "1"){
		setTimeout("get_ss_status_back_websocket();", 1000);
	}
}
function get_ss_status_back_httpd() {
	if (db_ss['ss_basic_enable'] != "1") {
		E("ss_state2").innerHTML = "国外连接 - " + "Waiting.....";
		E("ss_state3").innerHTML = "国内连接 - " + "Waiting.....";
		return false;
	}
	$.ajax({
		url: '/_temp/ss_status.txt?_=' + new Date().getTime(),
		type: 'GET',
		dataType: 'html',
		async: true,
		cache: false,
		success: function(response) {
			var res = response.trim();
			if(res.indexOf("@@") != -1){
				var arr = res.split("@@");
				if (arr[0] == "" || arr[1] == "") {
					E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
					E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
				} else {
					E("ss_state2").innerHTML = arr[0];
					E("ss_state3").innerHTML = arr[1];
				}
				if (arr[2] == "1") {
					var dbus_post = {};
					dbus_post["ss_heart_beat"] = "0";
					push_data("dummy_script.sh", "", dbus_post, "2");
					require(['/res/layer/layer.js'], function(layer) {
						layer.confirm('<li>科学上网插件页面需要刷新！</li><br /><li>由于故障转移功能已经在后台切换了节点，为了保证页面显示正确配置！需要刷新此页面！</li><br /><li>确定现在刷新吗？</li>', {
							time: 3e4,
							shade: 0.8
						}, function(index) {
							layer.close(index);
							refreshpage();
						}, function(index) {
							layer.close(index);
							return false;
						});
					});
				}
			}
		},
		error: function(xhr) {
			E("ss_state2").innerHTML = "国外连接 - " + "Waiting....";
			E("ss_state3").innerHTML = "国内连接 - " + "Waiting....";
		}
	});
	if (E("ss_basic_interval").value == "1"){
		var time_wait = 3000;
	}else if(E("ss_basic_interval").value == "2"){
		var time_wait = 7000;
	}else if(E("ss_basic_interval").value == "3"){
		var time_wait = 15000;
	}else if(E("ss_basic_interval").value == "4"){
		var time_wait = 31000;
	}else if(E("ss_basic_interval").value == "5"){
		var time_wait = 63000;
	}
	setTimeout("get_ss_status_back_httpd();", time_wait);
}
//fancyss_full_1
function get_udp_status(){
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_udp_status.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			E("udp_status").innerHTML = response.result;
			setTimeout("get_udp_status();", 10000);
		},
		error: function(){
			setTimeout("get_udp_status();", 2000);
		}
	});
}
//fancyss_full_2
function close_dns_status() {
	$("#dns_status_div").hide(200);
	STATUS_FLAG = 0;
}
function dns_test(s) {
	//STATUS_FLAG = 1;
	var dbus_commit={};
	if(s == 1){
		//cdn
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_cdn";
		var note1 = '1. 以下DNS解析测试的域名来自：<a href="https://github.com/felixonmars/dnsmasq-china-list" target="_blank"><em><u>https://github.com/felixonmars/dnsmasq-china-list</u></em></a> 的cdn-testlist.txt，并经过fancyss项目整理。';
		var note2 = '2. 解析结果和速度可能受节点、DNS方案、上游DNS缓存等因素影响，本测试也无法判断解析结果正确性！所以测试结果仅供参考！';
	}
	else if(s == 2){
		//apple china
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_cdn_apple";
		var note1 = '1. Apple China的域名清单来自：<a href="https://github.com/felixonmars/dnsmasq-china-list" target="_blank"><em><u>https://github.com/felixonmars/dnsmasq-china-list</u></em></a> 的apple.china.conf，并经过fancyss项目整理。';
		var note2 = '2. 理想情况下，Apple China域名清单应该尽可能多的解析到大陆IP地址！';
		var note3 = '3. 解析结果和速度可能受节点、DNS方案、上游DNS缓存等因素影响，本测试也无法判断解析结果正确性！所以测试结果仅供参考！';
	}
	else if(s == 3){
		//google china
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_cdn_google";
		var note1 = '1. Google China的域名清单来自：<a href="https://github.com/felixonmars/dnsmasq-china-list" target="_blank"><em><u>https://github.com/felixonmars/dnsmasq-china-list</u></em></a> 的google.china.conf，并经过fancyss项目整理。';
		var note2 = '2. 理想情况下，Google China域名清单应该尽可能多的解析到大陆IP地址！';
		var note3 = '3. 解析结果和速度可能受节点、DNS方案、上游DNS缓存等因素影响，本测试也无法判断解析结果正确性！所以测试结果仅供参考！';
	}
	else if(s == 4){
		//gfwlist
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_gfwlist";
		var note1 = '1. gfwlist的域名清单来自：<a href="https://github.com/hq450/fancyss/blob/3.0/rules/gfwlist.conf" target="_blank"><em><u>https://github.com/hq450/fancyss/blob/3.0/rules/gfwlist.conf</u></em></a>，收录了常见的被gfw屏蔽的域名。';
		var note2 = '2. 由于gfwlist清单较长，将每次随机选取100个域名进行测试！理想情况下，解析结果应该全部是海外IP地址，没有大陆IP地址！';
		var note3 = '3. 解析结果和速度可能受节点、DNS方案、上游DNS缓存等因素影响，本测试也无法判断解析结果正确性！所以测试结果仅供参考！';
	}
	else if(s == 5){
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_cdn_china";
		var note1 = '1. cdn china的域名清单来自：<a href="https://github.com/felixonmars/dnsmasq-china-list" target="_blank"><em><u>https://github.com/felixonmars/dnsmasq-china-list</u></em></a> 的accelerated-domains.china.conf，并经过fancyss项目整理。';
		var note2 = '2. 由于cdn china清单较长，将每次随机选取100个域名进行测试！由于cdn china收录的域名条件位解析结果或者NS服务器在国内，所以很多域名解析到国外是正常的！';
	}
	else if(s == 6){
		$("#log_dig").hide();
		$("#log_resv").show();
		var note1 = '1. 本测试需要用到dig程序，因程序体积较大，fancyss默认不包含此程序，点击测试的时候会自动尝试下载该程序。';
		var note2 = '1. 本测试仅针对DNS解析最终端，即本机dnsmasq 53端口的DNS服务器测试，每次测试前会自动清空dnsmasq缓存，以避免缓存影响。';
		var note3 = '2. 用dig进行测试可以方便的知道在本插件选定的DNS方案下，域名解析的ipv4结果，解析结果是否带ECS等';
		dbus_commit["ss_basic_dig_opt"] = E("ss_basic_dig_opt").value
	}
	if(note1){
		$("#dns_test_note_1").html('<i>&nbsp;&nbsp;' + note1 + '</i>');
	}
	if(note2){
		$("#dns_test_note_2").html('<i>&nbsp;&nbsp;' + note2 + '</i>');
	}
	if(note3){
		$("#dns_test_note_3").show('<i>&nbsp;&nbsp;' + note3 + '</i>');
	}
	$("#dns_status_div").fadeIn(500);
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_dns_test.sh", "params":[s], "fields": dbus_commit};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			get_dns_log(s);
		},
		error: function(){
			setTimeout("dns_test();", 2000);
		}
	});
}
function get_dns_log(s) {
	//if(STATUS_FLAG == 0) return;
	var retArea = E("log_content_dns");
	if(s == 1){
		var file = '/_temp/dns_cdn.txt';
	}
	else if(s == 2){
		var file = '/_temp/dns_cdn_apple.txt';
	}
	else if(s == 3){
		var file = '/_temp/dns_cdn_google.txt';
	}
	else if(s == 4){
		var file = '/_temp/dns_gfwlist.txt';
	}
	else if(s == 5){
		var file = '/_temp/dns_cdn_china.txt';
	}
	else if(s == 6){
		var file = '/_temp/dns_dig_result.txt';
	}
	$.ajax({
		url: file,
		type: 'GET',
		dataType: 'html',
		async: true,
		cache: false,
		success: function(response) {
			if(E("tablet_3").style.display == "none"){
				return false;
			}
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.myReplace("XU6J03M6", " ");
				retArea.scrollTop = retArea.scrollHeight;
				return true;
			}
			if (_responseLen == response.length) {
				noChange_dns++;
			} else {
				noChange_dns = 0;
			}
			if (noChange_dns > 20) {
				return false;
			} else {
				setTimeout('get_dns_log("' + s + '");', 500);
			}
			retArea.value = response.myReplace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		},
		error: function(xhr) {
			retArea.value = "暂无任何日志，获取日志失败！";
		}
	});
}
function close_ssf_status() {
	E("ssf_status_div").style.visibility = "hidden";
	$('html, body').css({overflow: 'auto', height: 'auto'});
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
	STATUS_FLAG = 0;
}
function close_ssc_status() {
	E("ssc_status_div").style.visibility = "hidden";
	$('html, body').css({overflow: 'auto', height: 'auto'});
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
	STATUS_FLAG = 0;
}
function lookup_status_log(s) {
	STATUS_FLAG = 1;
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').show();
	document.scrollingElement.scrollTop = 0;
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	if(s == 1){
		var elem_h = $("#ssf_status_div").height();
		var elem_w = $("#ssf_status_div").width();
		var elem_h_offset = (page_h - elem_h) / 2;
		var elem_w_offset = (page_w - elem_w) / 2 + 90;
		if(elem_h_offset < 0) elem_h_offset = 10;
		$("#ssf_test_url").html(E("ss_basic_wt_furl").value)
		E("ssf_status_div").style.visibility = "visible";
		$('#ssf_status_div').offset({top: elem_h_offset, left: elem_w_offset});
		get_status_log(1);
	}else{
		var elem_h = $("#ssc_status_div").height();
		var elem_w = $("#ssc_status_div").width();
		var elem_h_offset = (page_h - elem_h) / 2;
		var elem_w_offset = (page_w - elem_w) / 2 + 90;
		if(elem_h_offset < 0) elem_h_offset = 10;
		$("#ssc_test_url").html(E("ss_basic_wt_curl").value)
		E("ssc_status_div").style.visibility = "visible";
		$('#ssc_status_div').offset({top: elem_h_offset, left: elem_w_offset});
		get_status_log(2);
	}
	$('html, body').css({overflow: 'hidden', height: '100%'});
}
function get_status_log(s) {
	if(STATUS_FLAG == 0) return;
	
	if(s == 1){
		var file = '/_temp/ssf_status.txt';
		var retArea = E("log_content_f");
	}else{
		var file = '/_temp/ssc_status.txt';
		var retArea = E("log_content_c");
	}
	$.ajax({
		url: file,
		type: 'GET',
		dataType: 'html',
		async: true,
		cache:false,
		success: function(response) {
			if(E("tablet_2").style.display == "none"){
				return false;
			}
			if (_responseLen == response.length) {
				noChange_status++;
			} else {
				noChange_status = 0;
			}
			if (noChange_status > 10) {
				return false;
			} else {
				setTimeout('get_status_log("' + s + '");', 3123);
			}
			retArea.value = response;
			if(E("ss_failover_c4").checked == false && E("ss_failover_c5").checked == false){
				retArea.scrollTop = retArea.scrollHeight;
			}
			_responseLen = response.length;
		},
		error: function(xhr) {
			retArea.value = "暂无任何日志，获取日志失败！";
		}
	});
}
function get_log() {
	if (ws_flag != 1){
		get_log_httpd();
		return false;
	}
	wsl = new WebSocket("ws://" + hostname + ":803/");
	wsl.onopen = function() {
		//console.log('wsl：成功建立websocket链接，开始获取日志...');
		E('log_content1').value = "";
		wsl.send("cat /tmp/upload/ss_log.txt");
	};
	//wsl.onclose = function() {
	//	console.log('wsl： DISCONNECT');
	//};
	wsl.onerror = function(event) {
		//console.log('wsl： Error: ' + event.data);
		get_log_httpd();
	};
	wsl.onmessage = function(event) {
		if(event.data != "XU6J03M6"){
			E('log_content1').value += event.data + '\n';
		}else{
			E("log_content1").scrollTop = E("log_content1").scrollHeight;
			wsl.close();
		}
	};
}
function get_log_httpd() {
	$.ajax({
		url: '/_temp/ss_log.txt',
		type: 'GET',
		dataType: 'html',
		async: true,
		cache:false,
		success: function(response) {
			var retArea = E("log_content1");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.myReplace("XU6J03M6", " ");
				var pageH = parseInt(E("FormTitle").style.height.split("px")[0]); 
				if(pageH){
					autoTextarea(E("log_content1"), 0, (pageH - 308));
				}else{
					autoTextarea(E("log_content1"), 0, 980);
				}
				return true;
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 5) {
				return false;
			} else {
				setTimeout("get_log_httpd();", 100);
			}
			retArea.value = response;
			_responseLen = response.length;
			if(E("tablet_9").style.display == "none"){
				return false;
			}
		},
		error: function(xhr) {
			E("log_content1").value = "获取日志失败！";
		}
	});
}
function get_realtime_log() {
	$.ajax({
		url: '/_temp/ss_log.txt',
		type: 'GET',
		async: true,
		cache:false,
		dataType: 'text',
		success: function(response) {
			var retArea = E("log_content3");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.myReplace("XU6J03M6", " ");
				E("ok_button").style.display = "";
				retArea.scrollTop = retArea.scrollHeight;
				count_down_close();
				submit_flag="0";
				return true;
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 1000) {
				console.log("log time out!!")
				return false;
			} else {
				setTimeout("get_realtime_log();", 100);
			}
			retArea.value = response.myReplace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		},
		error: function() {
			setTimeout("get_realtime_log();", 500);
		}
	});
}
function count_down_close() {
	if (x == "0") {
		hideSSLoadingBar();
	}
	if (x < 0) {
		E("ok_button1").value = "手动关闭"
		return false;
	}
	E("ok_button1").value = "自动关闭（" + x + "）"
		--x;
	setTimeout("count_down_close();", 1000);
}
function reload_Soft_Center() {
	location.href = "/Module_Softcenter.asp";
}
function getACLConfigs() {
	var dict = {};
	acl_node_max = 0;
	for (var field in db_acl) {
		names = field.split("_");
		dict[names[names.length - 1]] = 'ok';
	}
	acl_confs = {};
	var p = "ss_acl";
	var params = ["ip", "port", "mode"];
	for (var field in dict) {
		var obj = {};
		if (typeof db_acl[p + "_name_" + field] == "undefined") {
			obj["name"] = db_acl[p + "_ip_" + field];
		} else {
			obj["name"] = db_acl[p + "_name_" + field];
		}
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + field;
			if (typeof db_acl[ofield] == "undefined") {
				obj = null;
				break;
			}
			obj[params[i]] = db_acl[ofield];
		}
		if (obj != null) {
			var node_a = parseInt(field);
			if (node_a > acl_node_max) {
				acl_node_max = node_a;
			}
			obj["acl_node"] = field;
			acl_confs[field] = obj;
		}
	}
	return acl_confs;
}
function addTr() {
	var acls = {};
	var p = "ss_acl";
	acl_node_max += 1;
	var params = ["ip", "name", "port", "mode"];
	for (var i = 0; i < params.length; i++) {
		acls[p + "_" + params[i] + "_" + acl_node_max] = $('#' + p + "_" + params[i]).val();
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": acls};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		error: function(xhr) {
			console.log("error in posting config of table");
		},
		success: function(response) {
			//confs = generate_node_info();
			refresh_acl_table();
			E("ss_acl_name").value = ""
			E("ss_acl_ip").value = ""
		}
	});
	aclid = 0;
}
function delTr(o) {
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ss_acl";
	id = ids[ids.length - 1];
	var acls = {};
	var params = ["ip", "name", "port", "mode"];
	for (var i = 0; i < params.length; i++) {
		acls[p + "_" + params[i] + "_" + id] = "";
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": acls};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			refresh_acl_table();
		}
	});
}
function refresh_acl_table(q) {
	$.ajax({
		type: "GET",
		url: "/_api/ss_acl",
		dataType: "json",
		async: false,
		success: function(data) {
			db_acl = data.result[0];
			refresh_acl_html();
			//write defaut rule mode when switching ss mode
			if (typeof db_acl["ss_acl_default_mode"] != "undefined") {
				if (E("ss_basic_mode").value == 1 && db_acl["ss_acl_default_mode"] == 1 || db_acl["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_acl["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 2 && db_acl["ss_acl_default_mode"] == 2 || db_acl["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_acl["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 3 && db_acl["ss_acl_default_mode"] == 3 || db_acl["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_acl["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 5 && db_acl["ss_acl_default_mode"] == 5 || db_acl["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_acl["ss_acl_default_mode"]);
				}
			}
			//write default rule port
			if (typeof db_acl["ss_acl_default_port"] != "undefined") {
				$('#ss_acl_default_port').val(db_acl["ss_acl_default_port"]);
			} else {
				$('#ss_acl_default_port').val("all");
			}
			//write dynamic table value
			for (var i = 1; i < acl_node_max + 1; i++) {
				$('#ss_acl_mode_' + i).val(db_acl["ss_acl_mode_" + i]);
				$('#ss_acl_port_' + i).val(db_acl["ss_acl_port_" + i]);
				$('#ss_acl_name_' + i).val(db_acl["ss_acl_name_" + i]);
			}
			//set default rule port to all when game mode enabled
			set_default_port();
			//after table generated and value filled, set default value for first line_image1
			$('#ss_acl_mode').val("1");
			$('#ss_acl_port').val("80,443");
		}
	});
}
function set_mode_1() {
	//set the first line of the table, if mode is gfwlist mode or game mode,set the port to all
	if ($('#ss_acl_mode').val() == 0 || $('#ss_acl_mode').val() == 3) {
		$("#ss_acl_port").val("all");
		E("ss_acl_port").readonly = "readonly";
		E("ss_acl_port").title = "不可更改，游戏模式下默认全端口";
	} else if ($('#ss_acl_mode').val() == 1) {
		$("#ss_acl_port").val("80,443");
		E("ss_acl_port").readonly = "readonly";
		E("ss_acl_port").title = "";
	} else if ($('#ss_acl_mode').val() == 2 || $('#ss_acl_mode').val() == 5) {
		$("#ss_acl_port").val("22,80,443");
		E("ss_acl_port").readonly = "";
		E("ss_acl_port").title = "";
	}
}
function set_mode_2(o) {
	var id2 = $(o).attr("id");
	var ids2 = id2.split("_");
	id2 = ids2[ids2.length - 1];
	if ($(o).val() == 0 || $(o).val() == 3) {
		$("#ss_acl_port_" + id2).val("all");
	} else if ($(o).val() == 1) {
		$("#ss_acl_port_" + id2).val("80,443");
	} else if ($(o).val() == 2) {
		$("#ss_acl_port_" + id2).val("22,80,443");
	}
}
function set_default_port() {
	if ($('#ss_acl_default_mode').val() == 3) {
		$("#ss_acl_default_port").val("all");
		E("ss_acl_default_port").readonly = "readonly";
		E("ss_acl_default_port").title = "不可更改，游戏模式下默认全端口";
	} else {
		E("ss_acl_default_port").readonly = "";
		E("ss_acl_default_port").title = "";
	}
}
function refresh_acl_html() {
	acl_confs = getACLConfigs();
	var n = 0;
	for (var i in acl_confs) {
		n++;
	}
	var code = '';
	// acl table th
	code += '<table width="100%" border="0" align="center" cellpadding="4" cellspacing="0" class="FormTable_table acl_lists" style="margin:-1px 0px 0px 0px;">'
	code += '<tr>'
	code += '<th width="23%">主机IP地址</th>'
	code += '<th width="23%">主机别名</th>'
	code += '<th width="23%">访问控制</th>'
	code += '<th width="23%">目标端口</th>'
	code += '<th width="8%">操作</th>'
	code += '</tr>'
	code += '</table>'
	// acl table input area
	code += '<table id="ACL_table" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" class="list_table acl_lists" style="margin:-1px 0px 0px 0px;">'
	code += '<tr>'
	// ip addr
	code += '<td width="23%">'
	code += '<input type="text" maxlength="15" class="input_ss_table" id="ss_acl_ip" align="left" style="float:left;width:110px;margin-left:16px;text-align:center" autocomplete="off" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off">'
	code += '<img id="pull_arrow" height="14px;" src="/res/arrow-down.gif" align="right" onclick="pullLANIPList(this);" title="<#select_IP#>">'
	code += '<div id="ClientList_Block" class="clientlist_dropdown" style="margin-left:2px;margin-top:25px;"></div>'
	code += '</td>'
	// name
	code += '<td width="23%">'
	code += '<input type="text" id="ss_acl_name" class="input_ss_table" maxlength="50" style="width:140px;text-align:center" placeholder="" />'
	code += '</td>'
	// mode
	code += '<td width="23%">'
	code += '<select id="ss_acl_mode" style="width:140px;margin:0px 0px 0px 2px;text-align:center;text-align-last:center;padding-left: 12px;" class="input_option" onchange="set_mode_1(this);">'
	code += '<option value="0">不通过代理</option>'
	code += '<option value="1">gfwlist模式</option>'
	code += '<option value="2">大陆白名单模式</option>'
	code += '<option value="3">游戏模式</option>'
	code += '<option value="5">全局代理模式</option>'
	code += '<option value="6">回国模式</option>'
	code += '</select>'
	code += '</td>'
	// port
	code += '<td width="23%">'
	code += '<select id="ss_acl_port" style="width:152px;margin:0px 0px 0px 2px;text-align-last:center;padding-left: 12px;" class="input_option">'
	code += '<option value="80,443">80,443</option>'
	code += '<option value="22,80,443">22,80,443</option>'
	code += '<option value="all">all</option>'
	code += '</select>'
	code += '</td>'
	// add/delete
	code += '<td width="8%">'
	code += '<input style="margin-left: 6px;margin: -2px 0px -4px -2px;" type="button" class="add_btn" onclick="addTr()" value="" />'
	code += '</td>'
	code += '</tr>'
	// acl table rule area
	for (var field in acl_confs) {
		var ac = acl_confs[field];
		code += '<tr id="acl_tr_' + ac["acl_node"] + '">';
		
		code += '<td width="23%">' + ac["ip"] + '</td>';
		
		code += '<td width="23%">';
		code += '<input type="text" placeholder="' + ac["acl_node"] + '号机" id="ss_acl_name_' + ac["acl_node"] + '" name="ss_acl_name_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		code += '</td>';
		
		code += '<td width="23%">';
		code += '<select id="ss_acl_mode_' + ac["acl_node"] + '" name="ss_acl_mode_' + ac["acl_node"] + '" style="width:140px;margin:0px 0px 0px 2px;" class="sel_option" onchange="set_mode_2(this);">';
		if ($("#ss_basic_mode").val() == 6) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="6">回国模式</option>';
		} else {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="1">gfwlist模式</option>';
			code += '<option value="2">大陆白名单模式</option>';
			code += '<option value="3">游戏模式</option>';
			code += '<option value="5">全局代理模式</option>';
			code += '<option value="6">回国模式</option>';
		}
		code += '</select>'
		code += '</td>';
		
		code += '<td width="23%">';
		if (ac["mode"] == 3) {
			code += '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，游戏模式下默认全端口" readonly = "readonly" />';
		} else if (ac["mode"] == 0) {
			code += '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，不通过SS下默认全端口" readonly = "readonly" />';
		} else {
			code += '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		}
		code += '</td>';
		
		code += '<td width="8%">';
		code += '<input style="margin: -2px 0px -4px -2px;" id="acl_node_' + ac["acl_node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
		code += '</td>';
		code += '</tr>';
	}
	code += '<tr>';
	if (n == 0) {
		code += '<td width="23%">所有主机</td>';
	} else {
		code += '<td width="23%">其它主机</td>';
	}
	code += '<td width="23%">默认规则</td>';
	ssmode = E("ss_basic_mode").value;
	if (n == 0) {
		if (ssmode == 0) {
			code += '<td width="23%">SS关闭</td>';
		} else if (ssmode == 1) {
			code += '<td width="23%">gfwlist模式</td>';
		} else if (ssmode == 2) {
			code += '<td width="23%">大陆白名单模式</td>';
		} else if (ssmode == 3) {
			code += '<td width="23%">游戏模式</td>';
		} else if (ssmode == 5) {
			code += '<td width="23%">全局模式</td>';
		} else if (ssmode == 6) {
			code += '<td width="23%">回国模式</td>';
		}
	} else {
		code += '<td width="23%">';
		code += '<select id="ss_acl_default_mode" style="width:140px;margin:0px 0px 0px 2px;" class="sel_option" onchange="set_default_port();">';
		if (ssmode == 0) {
			code += '<td>SS关闭</td>';
		} else if (ssmode == 1) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="1" selected>gfwlist模式</option>';
		} else if (ssmode == 2) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="2" selected>大陆白名单模式</option>';
		} else if (ssmode == 3) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="3" selected>游戏模式</option>';
		} else if (ssmode == 5) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="5" selected>全局代理模式</option>';
		} else if (ssmode == 6) {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="6" selected>回国模式</option>';
		}
		code += '</select>';
		code += '</td>';
	}
	code += '<td width="23%">';
	code += '<input type="text" id="ss_acl_default_port" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
	code += '</td>';
	code += '<td width="8%">';
	code += '</td>';
	code += '</tr>';
	code += '</table>';

	$(".acl_lists").remove();
	$('#ss_acl_table').append(code);
	
	showDropdownClientList('setClientIP', 'ip', 'all', 'ClientList_Block', 'pull_arrow', 'online');
}
function setClientIP(ip, name, mac) {
	E("ss_acl_ip").value = ip;
	E("ss_acl_name").value = name;
	hideClients_Block();
}
function pullLANIPList(obj) {
	var element = E('ClientList_Block');
	var isMenuopen = element.offsetWidth > 0 || element.offsetHeight > 0;
	if (isMenuopen == 0) {
		obj.src = "/res/arrow-top.gif"
		element.style.display = 'block';
	} else{
		hideClients_Block();
	}
}
function hideClients_Block() {
	E("pull_arrow").src = "/res/arrow-down.gif";
	E('ClientList_Block').style.display = 'none';
}
function close_proc_status() {
	$("#detail_status").fadeOut(200);
}
function get_proc_status() {
	$('#proc_status').val("请稍后，正在获取状态中...");
	$("#detail_status").fadeIn(500);
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_proc_status.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		cache: false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == id){
				write_proc_status();
			}
		}
	});
}
function write_proc_status() {
	$.ajax({
		url: '/_temp/ss_proc_status.txt',
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			$('#proc_status').val(res);
		}
	});
}
function get_online_nodes(action) {
	if (action == 0 || action == 1) {
		require(['/res/layer/layer.js'], function(layer) {
			layer.confirm('你确定要删除吗？', {
				shade: 0.8,
			}, function(index) {
				layer.close(index);
				save_online_nodes(action);
			}, function(index) {
				layer.close(index);
				return false;
			});
		});
	} else {
		save_online_nodes(action);
	}
}
function save_online_nodes(action) {
	db_ss["ss_basic_action"] = "13";
	var dbus_post = {};
	if (action == "4"){
		dbus_post["ss_base64_links"] = Base64.encode(encodeURIComponent(E("ss_base64_links").value));
	}
	if (action == "2"||action == "3"){
		dbus_post["ss_online_links"] = Base64.encode(E("ss_online_links").value);
		dbus_post["ssr_subscribe_mode"] = E("ssr_subscribe_mode").value;
		dbus_post["ss_basic_online_links_goss"] = E("ss_basic_online_links_goss").value;
		dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
		dbus_post["ss_basic_node_update_day"] = E("ss_basic_node_update_day").value;
		dbus_post["ss_basic_node_update_hr"] = E("ss_basic_node_update_hr").value;
		dbus_post["ss_basic_exclude"] = E("ss_basic_exclude").value.replace(pattern,"") || "";
		dbus_post["ss_basic_include"] = E("ss_basic_include").value.replace(pattern,"") || "";
		dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
		dbus_post["ss_basic_hy2_up_speed"] = E("ss_basic_hy2_up_speed").value;			//fancyss-full
		dbus_post["ss_basic_hy2_dl_speed"] = E("ss_basic_hy2_dl_speed").value;			//fancyss-full
		dbus_post["ss_basic_hy2_tfo_switch"] = E("ss_basic_hy2_tfo_switch").value;		//fancyss-full
	}

	if(ws_flag == 1){
		push_data_ws("ss_online_update.sh", action,  dbus_post);
	}else{
		push_data("ss_online_update.sh", action,  dbus_post);
	}
}
function v2ray_binary_update(){																												//fancyss-full
	var dbus_post = {};																														//fancyss-full
	db_ss["ss_basic_action"] = "15";																										//fancyss-full
	require(['/res/layer/layer.js'], function(layer) {																						//fancyss-full
		layer.confirm('<li>为了避免不必要的问题，请保证路由器和服务器上的v2ray版本一致！</li><br /><li>你确定要更新v2ray二进制吗？</li>', {	//fancyss-full
			shade: 0.8,																														//fancyss-full
		}, function(index) {																												//fancyss-full
			$("#log_content3").attr("rows", "20");																							//fancyss-full
			push_data("ss_v2ray.sh", 1, dbus_post);																							//fancyss-full
			layer.close(index);																												//fancyss-full
			return true;																													//fancyss-full
			//save_online_nodes(action);																									//fancyss-full
		}, function(index) {																												//fancyss-full
			layer.close(index);																												//fancyss-full
			return false;																													//fancyss-full
		});																																	//fancyss-full
	});																																		//fancyss-full
}																																			//fancyss-full
function xray_binary_update(){
	var dbus_post = {};
	db_ss["ss_basic_action"] = "15";
	note = "<li>v1.7.5：security支持TLS和XTLS，不支持REALITY，选此会将Xray二进制切换到此版本！</li>";
	note += "<li>v1.8.X：security支持TLS和REALITY，不支持XTLS，选此会将Xray二进制更新到1.8.x最新版本！</li>";
	note += "<li>切换/更新文件将从github上下载，请确保当前代理工作正常，不然将无法下载或下载及其缓慢！</li>";
	note += "<li>更多信息，请查看<a style='color:#22ab39;' href='https://github.com/XTLS/Xray-core/releases' target='_blank'>Xray releases页面</a>。</li>";
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 0,
			skin: 'layui-layer-lan',
			shade: 0.8,
			title: '请选择你需要的Xray版本！',
			time: 0,
			area: '670px',
			offset: '350px',
			btnAlign: 'c',
			maxmin: true,
			content: note,
			btn: ['v1.7.5', 'v1.8.x'],
			btn1: function() {
				push_data("ss_xray.sh", 1, dbus_post);
				layer.closeAll();
			},
			btn2: function() {
				push_data("ss_xray.sh", 2, dbus_post);
			}
		});
	});
}
function ssrust_binary_update(){																					//fancyss-full
	var dbus_post = {};																								//fancyss-full
	db_ss["ss_basic_action"] = "20";																				//fancyss-full
	require(['/res/layer/layer.js'], function(layer) {																//fancyss-full
		layer.confirm('<li>点击确定将开始shadowsocks-rust二进制下载，请确保你的路由器jffs空间容量足够！</li>', {	//fancyss-full
			shade: 0.8,																								//fancyss-full
		}, function(index) {																						//fancyss-full
			$("#log_content3").attr("rows", "20");																	//fancyss-full
			push_data("ss_rust_update.sh", 1, dbus_post);															//fancyss-full
			layer.close(index);																						//fancyss-full
			return true;																							//fancyss-full
			//save_online_nodes(action);																			//fancyss-full
		}, function(index) {																						//fancyss-full
			layer.close(index);																						//fancyss-full
			return false;																							//fancyss-full
		});																											//fancyss-full
	});																												//fancyss-full
}																													//fancyss-full
function set_cron(action) {
	var dbus_post = {};
	if(action == 1){
		//设定定时重启
		db_ss["ss_basic_action"] = "16";
		var cron_params1 = ["ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_custom", "ss_basic_time_hour", "ss_basic_time_min"];
		for (var i = 0; i < cron_params1.length; i++) {
			dbus_post[cron_params1[i]] = E(cron_params1[i]).value;
		}
		
		if (!E("ss_basic_custom").value) {
			dbus_post["ss_basic_custom"] = "";
		} else {
			dbus_post["ss_basic_custom"] = Base64.encode(E("ss_basic_custom").value);
		}
	}else if(action == 2){
		//设定触发重启
		db_ss["ss_basic_action"] = "17";
		var cron_params2 = ["ss_basic_tri_reboot_time"]; //for ss
		for (var i = 0; i < cron_params2.length; i++) {
			dbus_post[cron_params2[i]] = E(cron_params2[i]).value;
		}
	}
	push_data("ss_reboot_job.sh", action, dbus_post);
}
function save_failover() {
	var dbus_post = {};
		db_ss["ss_basic_action"] = "19";
	var fov_inp = ["ss_failover_s1", "ss_failover_s2_1", "ss_failover_s2_2", "ss_failover_s3_1", "ss_failover_s3_2", "ss_failover_s4_1", "ss_failover_s4_2", "ss_failover_s4_3", "ss_failover_s5", "ss_basic_interval"];
	var fov_chk = ["ss_failover_enable", "ss_failover_c1", "ss_failover_c2", "ss_failover_c3"];
	for (var i = 0; i < fov_inp.length; i++) {
		dbus_post[fov_inp[i]] = E(fov_inp[i]).value;
	}
	for (var i = 0; i < fov_chk.length; i++) {
		dbus_post[fov_chk[i]] = E(fov_chk[i]).checked ? '1' : '0';
	}
	push_data("ss_status_reset.sh", "", dbus_post);
}
function get_smartdns_conf(o) {
	console.log("o: ", o);
	var s = String(o);
	var p = s.split("")[0];
	var q = Number(s.split("")[1]);
	var r = q + 5;
	if(o == "10"){
		arg = "edit_smartdns_conf_china_udp";
		var name = 'smartdns_chng_china_udp';
		SMARTDNS_FLAG = '10';
	}
	if(o == "11"){
		arg = "edit_smartdns_conf_china_tcp";
		var name = 'smartdns_chng_china_tcp';
		SMARTDNS_FLAG = '11';
	}
	if(o == "12"){
		arg = "edit_smartdns_conf_china_doh";
		var name = 'smartdns_chng_china_doh';
		SMARTDNS_FLAG = '12';
	}
	if(p == "2"){
		arg = "edit_smartdns_conf_proxy_" + r;
		var name = 'smartdns_chng_proxy_' + r;
		SMARTDNS_FLAG = s;
	}
	if(o == "30"){
		arg = "edit_smartdns_conf_direct";
		var name = 'smartdns_chng_direct';
		SMARTDNS_FLAG = '30';
	}
	if(p == "5"){
		arg = "edit_smartdns_smrt_" + q;
		var name = 'smartdns_smrt_' + q;
		SMARTDNS_FLAG = s;
	}
	console.log(p);
	console.log(arg);
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params":[arg], "fields": dbus };
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			$.ajax({
				url: '/_temp/' + name + '.conf',
				type: 'GET',
				cache:false,
				dataType: 'text',
				success: function(res) {
					console.log(res);
					$('#smartdns_chnd_conf').val(res);
					if (response.result == '11111111'){
						E("smartdns_conf_note").innerHTML = "<i>当前为自定义smartdns配置，配置文件：</i><em>/koolshare/ss/rules/" + name + "_user.conf</em>";
						E("smartdns_conf_area").innerHTML = "SmartDns配置文件（当前为自定义配置）"
					}
					if (response.result == '22222222'){
						E("smartdns_conf_note").innerHTML = "<i>当前为默认smartdns配置，配置文件：</i><em>/koolshare/ss/rules/" + name + ".conf</em>";
						E("smartdns_conf_area").innerHTML = "SmartDns配置文件（当前为默认配置）"
					}
				}
			});
		}
	});
}
function close_smartdns_conf(){
	$("#smartdns_settings").fadeOut(200);
}
function save_smartdns_conf(){
	db_ss["ss_basic_action"] = "22";
	var s = String(SMARTDNS_FLAG);
	var p = s.split("")[0];
	var q = Number(s.split("")[1]);
	var r = q + 5;
	if(SMARTDNS_FLAG == '10'){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_conf_china_udp",  dbus);
	}
	if(SMARTDNS_FLAG == '11'){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_conf_china_tcp",  dbus);
	}
	if(SMARTDNS_FLAG == '12'){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_conf_china_doh",  dbus);
	}
	if(p == "1"){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_conf_proxy_" + r,  dbus);
	}
	if(SMARTDNS_FLAG == '30'){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_conf_direct",  dbus);
	}
	if(SMARTDNS_FLAG == '40'){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_resolver_doh",  dbus);
	}
	if(p == "5"){
		dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
		push_data("ss_conf.sh", "save_smartdns_smrt_" + q,  dbus);
	}
}
function reset_smartdns_conf(){
	db_ss["ss_basic_action"] = "23";
	var s = String(SMARTDNS_FLAG);
	var p = s.split("")[0];
	var q = Number(s.split("")[1]);
	var r = q + 5;
	if(SMARTDNS_FLAG == '10'){
		push_data("ss_conf.sh", "reset_smartdns_conf_china_udp",  dbus);
	}
	if(SMARTDNS_FLAG == '11'){
		push_data("ss_conf.sh", "reset_smartdns_conf_china_tcp",  dbus);
	}
	if(SMARTDNS_FLAG == '12'){
		push_data("ss_conf.sh", "reset_smartdns_conf_china_doh",  dbus);
	}
	if(p == "2"){
		push_data("ss_conf.sh", "reset_smartdns_conf_proxy_" + r,  dbus);
	}
	if(SMARTDNS_FLAG == '30'){
		push_data("ss_conf.sh", "reset_smartdns_conf_direct",  dbus);
	}
	if(SMARTDNS_FLAG == '40'){
		push_data("ss_conf.sh", "reset_smartdns_resolver_doh",  dbus);
	}
	if(p == "5"){
		push_data("ss_conf.sh", "reset_smartdns_smrt_" + q,  dbus);
	}
}
</script>
</head>
<body id="app" skin='<% nvram_get("sc_skin"); %>' onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 200;" >
	<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
		<tr>
			<td height="100">
			<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
			<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
			<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;overflow:hidden">
				<textarea cols="50" rows="30" wrap="on" readonly="readonly" id="log_content3" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:3px;padding-right:22px;overflow-x:hidden"></textarea>
			</div>
			<div id="ok_button" class="apply_gen" style="background: #000;display: none;">
				<input id="ok_button1" class="button_gen" type="button" onclick="hideSSLoadingBar()" value="确定">
			</div>
			</td>
		</tr>
	</table>
	</div>
	<!--============================this is the popup area for latency settings========================================-->
	<div id="latency_test_settings" class="fancyss_qis pop_div_bg">
		<table class="QISform_wireless" border="0" align="center" cellpadding="5" cellspacing="0">
			<tr>
				<td>
					<div class="user_title">节点延迟测试设置</div>
					<div id="latency_test_settings_div">
						<table id="table_test" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
							<script type="text/javascript">
								var pingm = [["1", "1次/节点"], ["2", "5次/节点"], ["3", "10次/节点"], ["4", "20次/节点"]];
								var furl = [
											  "http://www.google.com/generate_204",
											  "http://www.gstatic.com/generate_204",
											  "http://developer.google.cn/generate_204",
											  "http://connectivitycheck.gstatic.com/generate_204",
											  "http://edge.microsoft.com/captiveportal/generate_204",
											  "http://cp.cloudflare.com",
											  "http://captive.apple.com",
											  "http://www.google.com",
											  "http://www.google.com.hk",
											  "http://www.google.com.tw"
											 ];
								var curl = [
											  "http://www.baidu.com",
											  "http://www.sina.com",
											  "http://www.weibo.com",
											  "http://connectivitycheck.platform.hicloud.com/generate_204",
											  "http://wifi.vivo.com.cn/generate_204",
											  "http://www.apple.com/library/test/success.html",
											  "http://connect.rom.miui.com/generate_204",
											  "http://www.msftconnecttest.com/connecttest.txt"
											 ];
								var lt_cru = [
											["0", "关闭定时测试"],
											["1", "定时测试web延迟"]
										   ]
								var lt_time = [["15", "每隔15分钟"], ["20", "每隔20分钟"], ["25", "每隔25分钟"], ["30", "每隔30分钟"]];
								$('#table_test').forms([
									{ title: '延迟测试设置', thead:'1'},
									{ title: 'ping延迟测试次数', id:'ss_basic_pingm', type:'select', style:'width:auto', options:pingm, value:''},
									{ title: '<a onmouseover="mOver(this, 147)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">web延迟测试域名 - 国外</a>', id:'ss_basic_wt_furl', type:'select', style:'width:auto', options:furl, value:''},
									{ title: '<a onmouseover="mOver(this, 148)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">web延迟测试域名 - 国内</a>', id:'ss_basic_wt_curl', type:'select', style:'width:auto', options:curl, value:''},
									{ title: '定时测试节点延迟', multi: [
										{id:'ss_basic_lt_cru_opts', type:'select', style:'width:auto', func:'u', options:lt_cru, value:'0'},
										{id:'ss_basic_lt_cru_time', type:'select', style:'width:auto', options:lt_time, value:'0'},
									]},
								]);
							</script>
						</table>
					</div>
				</td>
			</tr>
		</table>
		<span style="margin-left:30px">【ping延迟测试】和【web延迟测试】在节点列表里只能展示一个，关于两者的优缺点请见<a onmouseover="mOver(this, 146)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);"><font color="#ffcc00">[详细说明]</font></a>。<br/></span>
		<span style="margin-left:30px">【web延迟测试】中设置的国外域名，同样会用于插件顶部[插件运行状态]中的国外链接延迟测试</span>
		<div style="padding-top:10px;padding-bottom:10px;width:100%;text-align:center;">
			<input id="save_latency_sett" class="button_gen" type="button" onclick="save_latency_sett();" value="保存">
			<input id="leav_test_sett" class="button_gen" type="button" onclick="leav_test_sett();" value="返回">
		</div>
	</div>
	<!--===================================Ending of zerotier latency settings===========================================-->
	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top">
				<div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<div>
								<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
									<tr>
										<td bgcolor="#4D595D" colspan="3" valign="top">
											<div>&nbsp;</div>
											<div id="title_name" class="formfonttitle"></div>
											<script type="text/javascript">
												var MODEL = '<% nvram_get("odmpid"); %>' || '<% nvram_get("productid"); %>';
												var FANCYSS_TITLE=" - " + pkg_name;
												$("#title_name").html(MODEL + " 科学上网插件" + FANCYSS_TITLE);
												$("#ss_title").html(MODEL + " - fancyss");
											</script>										
											<div style="float:right; width:15px; height:25px;margin-top:-20px">
												<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
											</div>
											<div style="margin:10px 0 0 5px;" class="splitLine"></div>
											<div class="SimpleNote" id="head_illustrate">
												<ul id="fixed_msg" style="padding:0;margin:0;line-height:1.8;">
													<li id="msg_0" style="list-style: none;height:23px">
														📌 本插件是支持<a href="https://github.com/shadowsocks/shadowsocks-libev" target="_blank"><em><u>SS</u></em></a>
														、<a href="https://github.com/shadowsocksrr/shadowsocksr-libev" target="_blank"><em><u>SSR</u></em></a>
														、<a href="https://github.com/v2ray/v2ray-core" target="_blank"><em><u>V2ray</u></em></a>
														、<a href="https://github.com/XTLS/xray-core" target="_blank"><em><u>Xray</u></em></a>
														、<a href="https://github.com/trojan-gfw/trojan" target="_blank"><em><u>Trojan</u></em></a>
														、<a href="https://github.com/klzgrad/naiveproxy" target="_blank"><em><u>NaïveProxy</u></em></a>	<!--fancyss-full-->
														、<a href="https://github.com/EAimTY/tuic" target="_blank"><em><u>tuic</u></em></a>    				<!--fancyss-full-->
														、<a href="https://github.com/apernet/hysteria" target="_blank"><em><u>Hysteria2</u></em></a>    	<!--fancyss-full-->
														八种客户端的科学上网工具。
														<a href="https://t.me/joinchat/AAAAAEC7pgV9vPdPcJ4dJw" target="_blank"><em>Telegram交流群</em></a>
													</li>
												</ul>
												<ul id="scroll_msg" style="padding:0;margin:0;line-height:1.8;overflow: hidden;">
												</ul>
											</div>
											<!-- this is the popup area for process status -->
											<div id="detail_status" class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;">
												<div class="user_title">【科学上网】状态检测</div>
												<div style="margin-left:15px"><i>&nbsp;&nbsp;详细状态检测可以让你了解插件相关二进制和iptables的运行状况，用以排除一些使用中的问题。</i></div>
												<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden">
													<textarea cols="63" rows="36" wrap="off" id="proc_status" style="line-height:1.45;width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input class="button_gen" type="button" onclick="close_proc_status();" value="返回主界面">
												</div>
											</div>
											<!-- this is the popup area for foreign status -->
											<div id="ssf_status_div" class="content_status_ext" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;margin-left:0px;width:748px;">
												<div class="user_title">国外历史状态 - <lable id="ssf_test_url"></lable></div>
												<div style="margin-left:15px"><i>&nbsp;&nbsp;此功能仅在开启故障转移时生效。</i></div>
												<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden;">
													<textarea cols="63" rows="36" wrap="off" id="log_content_f" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:10px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input class="button_gen" type="button" onclick="download_route_file(6);" value="下载日志">
													<input class="button_gen" type="button" onclick="close_ssf_status();" value="返回主界面">
													<input style="margin-left:10px" type="checkbox" id="ss_failover_c4">
													<lable>&nbsp;暂停日志刷新</lable>
												</div>
											</div>
											<!-- this is the popup area for china status -->
											<div id="ssc_status_div" class="content_status_ext" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;margin-left:0px;width:748px;">
												<div class="user_title">国内历史状态 - <lable id="ssc_test_url"></lable></div>
												<div style="margin-left:15px"><i>&nbsp;&nbsp;此功能仅在开启故障转移时生效。</i></div>
												<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden;">
													<textarea cols="63" rows="36" wrap="off" id="log_content_c" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:10px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input class="button_gen" type="button" onclick="download_route_file(7);" value="下载日志">
													<input class="button_gen" type="button" onclick="close_ssc_status();" value="返回主界面">
													<input style="margin-left:10px" type="checkbox" id="ss_failover_c5">
												</div>
											</div>
											<!-- this is the popup area for china status -->
											<div id="dns_status_div" class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: -140px;margin-left:0px;width:748px;">
												<div class="user_title">DNS解析测试</div>
												<div style="margin-left:15px" id="dns_test_note_1"></div>
												<div style="margin-left:15px" id="dns_test_note_2"></div>
												<div style="margin-left:15px" id="dns_test_note_3"></div>
												<div style="margin: 10px 10px 10px 10px;width:98%;outline: 1px solid #727272;text-align:center;overflow:hidden;">
													<textarea cols="63" rows="40" wrap="off" id="log_content_dns" style="line-height: 140%;width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input id="log_dig" class="button_gen" style="display:none;" type="button" onclick="download_route_file(10);" value="下载日志">
													<input id="log_resv" class="button_gen" style="display:none;" type="button" onclick="download_route_file(11);" value="下载日志">
													<input class="button_gen" type="button" onclick="close_dns_status();" value="返回主界面">
													<input style="margin-left:10px" type="checkbox" id="ss_failover_c5">
												</div>
											</div>
											<!-- this is the popup area for QRcode -->
											<div id="qrcode_show" class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: 90px;margin-left:197px;width:356px;height:356px;background: #fff;">
												<div style="text-align: center;margin-top:10px"><span id="qrtitle" style="font-size:16px;color:#000;"></span></div>
												<div id="qrcode" style="margin: 10px 50px 10px 50px;width:256px;height:256px;text-align:center;overflow:hidden">
												</div>
												<div style="margin-top:15px;padding-bottom:10px;width:100%;text-align:center;">
													<input class="button_gen" type="button" onclick="cleanCode();" value="返回">
												</div>
											</div>
											<!-- this is the popup area for smartdns rules -->
											<div id="smartdns_settings" class="smartdns_pop" style="box-shadow: 3px 3px 10px #000;margin-top: -65px;position: absolute;-webkit-border-radius: 5px;-moz-border-radius: 5px;border-radius:10px;z-index: 10;background-color:#2B373B;margin-left: -215px;top: 240px;width:980px;return height:auto;box-shadow: 3px 3px 10px #000;background: rgba(0,0,0,0.85);display:none;">
												<div class="user_title" id="smartdns_conf_area">SmartDns配置文件</div>
												<div style="margin-left:15px" id="smartdns_conf_note"></div>
												<div id="user_tr" style="margin: 10px 10px 10px 10px;width:98%;text-align:center;">
													<textarea class="smartdns_textarea" cols="63" rows="30" wrap="off" id="smartdns_chnd_conf" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input id="edit_node_1" class="button_gen" type="button" onclick="save_smartdns_conf();" value="保存配置">	
													<input id="edit_node_2" class="button_gen" type="button" onclick="reset_smartdns_conf();" value="恢复默认配置">	
													<input id="edit_node_3" class="button_gen" type="button" onclick="close_smartdns_conf();" value="返回主界面">
												</div>
											</div>
											<!-- end of the popouparea -->
											<div id="ss_switch_show" style="margin:-1px 0px 0px 0px;">
												<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="ss_switch_table">
													<thead>
													<tr>
														<td colspan="2">开关</td>
													</tr>
													</thead>
													<tr>
													<th id="ss_switch">科学上网开关</th>
														<td colspan="2">
															<div class="switch_field" style="display:table-cell;float: left;">
																<label for="ss_basic_enable">
																	<input id="ss_basic_enable" class="switch" type="checkbox" style="display: none;">
																	<div class="switch_container" >
																		<div class="switch_bar"></div>
																		<div class="switch_circle transition_style">
																			<div></div>
																		</div>
																	</div>
																</label>
															</div>
															<div id="update_button" style="display:table-cell;float: left;position: absolute;margin-left:70px;padding: 5.5px 0px;">
																<a id="updateBtn" type="button" class="ss_btn" style="cursor:pointer" onclick="update_ss()">检查并更新</a>
															</div>
															<div id="ss_version_show" style="display:table-cell;float: left;position: absolute;margin-left:170px;padding: 5.5px 0px;">
																<a><i>当前版本：</i></a>
															</div>
															<div style="display:table-cell;float: left;margin-left:270px;position: absolute;padding: 5.5px 0px;">
																<a type="button" class="ss_btn" target="_blank" href="https://github.com/hq450/fancyss/blob/3.0/Changelog.txt">更新日志</a>
															</div>
															<div style="display:table-cell;float: left;margin-left:350px;position: absolute;padding: 5.5px 0px;">
																<a type="button" class="ss_btn" href="javascript:void(0);" onclick="pop_help()">插件帮助</a>
															</div>
														</td>
													</tr>
													<tr id="ss_state">
														<th>插件运行状态</th>
														<td>
															<div style="display:table-cell;float: left;margin-left:0px;">
																<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(0)">
																	<span id="ss_state2">国外连接 - Waiting...</span>
																	<br/>
																	<span id="ss_state3">国内连接 - Waiting...</span>
																</a>
															</div>
															<div style="display:table-cell;float: left;margin-left:270px;position: absolute;padding: 10.5px 0px;">
																<!--<a type="button" class="ss_btn" style="cursor:pointer" onclick="pop_111(3)" href="javascript:void(0);">分流检测</a>-->
																<a type="button" class="ss_btn" target="https://ip.skk.moe/" href="https://ip.skk.moe/">分流检测</a>
															</div>
															<div style="display:table-cell;float: left;margin-left:350px;position: absolute;padding: 10.5px 0px;">
																<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_proc_status()" href="javascript:void(0);">详细状态</a>
															</div>
														</td>
													</tr>
												</table>
											</div>
											<div id="tablets">
												<table style="margin:10px 0px 0px 0px;border-collapse:collapse" width="100%" height="37px">
													<tr>
														<td cellpadding="0" cellspacing="0" style="padding:0" border="1" bordercolor="#222">
															<input id="show_btn0" class="show-btn0" style="cursor:pointer" type="button" value="帐号设置" />
															<input id="show_btn1" class="show-btn1" style="cursor:pointer" type="button" value="节点管理" />
															<input id="show_btn2" class="show-btn2" style="cursor:pointer" type="button" value="故障转移" />
															<input id="show_btn3" class="show-btn3" style="cursor:pointer" type="button" value="DNS设定" />
															<input id="show_btn4" class="show-btn4" style="cursor:pointer" type="button" value="黑白名单" />
															<input id="show_btn5" class="show-btn5" style="cursor:pointer" type="button" value="KCP加速" />		<!--fancyss-full-->
															<input id="show_btn6" class="show-btn6" style="cursor:pointer" type="button" value="UDP加速"/>		<!--fancyss-full-->
															<input id="show_btn7" class="show-btn7" style="cursor:pointer" type="button" value="更新管理" />
															<input id="show_btn8" class="show-btn8" style="cursor:pointer" type="button" value="访问控制" />
															<input id="show_btn9" class="show-btn9" style="cursor:pointer" type="button" value="附加功能" />
															<input id="show_btn10" class="show-btn10" style="cursor:pointer" type="button" value="查看日志" />
														</td>
													</tr>
												</table>
											</div>
											<div id="add_fancyss_node" class="contentM_qis pop_div_bg">
												<table class="QISform_wireless" border="0" align="center" cellpadding="5" cellspacing="0">
													<tr style="height:32px;">
														<td>
															<div id="add_fancyss_node_title" class="user_title">添加节点</div>
															<div>
																<table width="100%" border="0" align="left" cellpadding="0" cellspacing="0" class="vpnClientTitle">
																	<tr>
														  			<td width="12.5%" align="center" id="ssTitle" onclick="tabclickhandler(0);">SS节点</td>
														  			<td width="12.5%" align="center" id="ssrTitle" onclick="tabclickhandler(1);">SSR节点</td>
														  			<td width="12.5%" align="center" id="v2rayTitle" onclick="tabclickhandler(3);">V2Ray节点</td>
														  			<td width="12.5%" align="center" id="xrayTitle" onclick="tabclickhandler(4);">Xray节点</td>
														  			<td width="12.5%" align="center" id="trojanTitle" onclick="tabclickhandler(5);">Trojan节点</td>
														  			<td width="12.5%" align="center" id="naiveTitle" onclick="tabclickhandler(6);">Naïve节点</td>		<!--fancyss-full-->
														  			<td width="12.5%" align="center" id="tuicTitle" onclick="tabclickhandler(7);">tuic节点</td>		<!--fancyss-full-->
														  			<td width="12.5%" align="center" id="hy2Title" onclick="tabclickhandler(8);">hysteria2节点</td>	<!--fancyss-full-->
																	</tr>
																</table>
															</div>
														</td>
													</tr>
													<tr>
														<td>
															<div>
															<table id="table_add_nodes" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
																<script type="text/javascript">
																	$('#table_add_nodes').forms([
																		// common
																		{ title: '使用模式', id:'ss_node_table_mode', type:'select', func:'v', options:option_modes, style:'width:412px;', value: "2"},
																		{ title: '使用json配置', rid:'v2ray_use_json_tr', id:'ss_node_table_v2ray_use_json', type:'checkbox', func:'v', help:'27', value:false},
																		{ title: '使用json配置', rid:'xray_use_json_tr', id:'ss_node_table_xray_use_json', type:'checkbox', func:'v', help:'25', value:false},
																		{ title: '节点别名', rid:'ss_name_support_tr', id:'ss_node_table_name', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '服务器地址', rid:'ss_server_support_tr', id:'ss_node_table_server', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '服务器端口', rid:'ss_port_support_tr', id:'ss_node_table_port', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '密码', rid:'ss_passwd_support_tr', id:'ss_node_table_password', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '加密方式', rid:'ss_method_support_tr', id:'ss_node_table_method', type:'select', options:option_method, style:'width:412px', value: "aes-256-cfb"},
																		// ss
																		{ title: '混淆 (obfs)', rid:'ss_obfs_support', id:'ss_node_table_ss_obfs', type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], style:'width:412px', value: "0"},
																		{ title: '混淆主机名 (obfs-host)', rid:'ss_obfs_host_support', id:'ss_node_table_ss_obfs_host', type:'text', maxlen:'300', style:'width:400px', ph:'bing.com'},
																		{ title: 'v2ray-plugin', rid:'ss_v2ray_support', id:'ss_node_table_ss_v2ray', type:'select', func:'v', options:[["0", "关闭"], ["1", "开启"]], style:'width:412px', value: "0"},		//fancyss-full
																		{ title: 'v2ray-plugin参数', rid:'ss_v2ray_opts_support', id:'ss_node_table_ss_v2ray_opts', type:'text', maxlen:'300', style:'width:400px', ph:'tls;host=example.com;path=/'},			//fancyss-full
																		// ssr
																		{ title: '协议 (protocol)', rid:'ssr_protocol_tr', id:'ss_node_table_rss_protocol', type:'select', func:'v', options:option_protocals, style:'width:412px', value: "0"},
																		{ title: '协议参数 (protocol_param)', rid:'ssr_protocol_param_tr', id:'ss_node_table_rss_protocol_param', type:'text', maxlen:'300', style:'width:400px', ph:'id:password'},
																		{ title: '混淆 (obfs)', rid:'ssr_obfs_tr', id:'ss_node_table_rss_obfs', type:'select', func:'v', options:option_obfs, style:'width:412px', value: "0"},
																		{ title: '混淆参数 (obfs_param)', rid:'ssr_obfs_param_tr', id:'ss_node_table_rss_obfs_param', type:'text', maxlen:'300', style:'width:400px', ph:'bing.com'},
																		// v2ray
																		{ title: '<em>服务器配置</em>（以下配置使用vmess作为传出协议，其它传出协议请使用json配置）', class:'v2ray_elem', th:'2'},
																		{ title: '用户id (id)', rid:'v2ray_uuid_tr', id:'ss_node_table_v2ray_uuid', type:'text', maxlen:'300', hint:'49', style:'width:400px'},
																		{ title: '额外ID (Alterld)', rid:'v2ray_alterid_tr', id:'ss_node_table_v2ray_alterid', type:'text', maxlen:'300', style:'width:400px', value: "0"},
																		{ title: '加密方式 (security)', rid:'v2ray_security_tr', id:'ss_node_table_v2ray_security', type:'select', options:option_v2enc, style:'width:412px', value: "auto"},
																		{ title: '<em>底层传输方式</em>', class:'v2ray_elem', th:'2'},
																		{ title: '传输协议 (network)', rid:'v2ray_network_tr', id:'ss_node_table_v2ray_network', type:'select', func:'v', options:["tcp", "kcp", "ws", "h2", "quic", "grpc"], style:'width:412px', value: "tcp"},
																		{ title: '* tcp伪装类型 (type)', rid:'v2ray_headtype_tcp_tr', id:'ss_node_table_v2ray_headtype_tcp', type:'select', func:'v', options:option_headtcp, style:'width:412px', value: "none"},
																		{ title: '* kcp伪装类型 (type)', rid:'v2ray_headtype_kcp_tr', id:'ss_node_table_v2ray_headtype_kcp', type:'select', func:'v', options:option_headkcp, style:'width:412px', value: "none"},
																		{ title: '* quic伪装类型 (type)', rid:'v2ray_headtype_quic_tr', id:'ss_node_table_v2ray_headtype_quic', type:'select', options:option_headquic, value: "none"},
																		{ title: '* grpc模式', rid:'v2ray_grpc_mode_tr', id:'ss_node_table_v2ray_grpc_mode', type:'select', options:option_grpcmode, value: ""},
																		{ title: '* 伪装域名 (host)', rid:'v2ray_network_host_tr', id:'ss_node_table_v2ray_network_host', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '* 路径 (path)', rid:'v2ray_network_path_tr', id:'ss_node_table_v2ray_network_path', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '* kcp seed', rid:'v2ray_kcp_seed_tr', id:'ss_node_table_v2ray_kcp_seed', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '底层传输安全', rid:'v2ray_network_security_tr', id:'ss_node_table_v2ray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"]], style:'width:412px', value: "none"},
																		{ title: '* 跳过证书验证 (AllowInsecure)', rid:'v2ray_network_security_ai_tr', id:'ss_node_table_v2ray_network_security_ai', type:'checkbox', hint:'56', value: "false"},
																		{ title: '* alpn', rid:'v2ray_network_security_alpn_tr', multi: [
																			{ suffix: '<input type="checkbox" id="ss_node_table_v2ray_network_security_alpn_h2">h2' },
																			{ suffix: '<input type="checkbox" id="ss_node_table_v2ray_network_security_alpn_http">http/1.1' },
																		]},
																		{ title: 'SNI', rid:'v2ray_network_security_sni_tr', id:'ss_node_table_v2ray_network_security_sni', type:'text'},
																		{ title: '多路复用 (Mux)', rid:'v2ray_mux_enable_tr', id:'ss_node_table_v2ray_mux_enable', type:'checkbox', func:'v', value: false},
																		{ title: '* Mux并发连接数', rid:'v2ray_mux_concurrency_tr', id:'ss_node_table_v2ray_mux_concurrency', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: 'v2ray json', rid:'v2ray_json_tr', id:'ss_node_table_v2ray_json', type:'textarea', rows:'32', ph:ph_v2ray, style:'width:400px'},
																		// xray
																		{ title: '<em>服务器配置</em>（以下配置使用vless作为传出协议，其它传出协议请使用json配置）', class:'xray_elem', th:'2'},
																		{ title: '用户id (id)', rid:'xray_uuid_tr', id:'ss_node_table_xray_uuid', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '加密 (encryption)', rid:'xray_encryption_tr', id:'ss_node_table_xray_encryption', type:'text', hint:'55', maxlen:'300', style:'width:400px', value: "none"},
																		{ title: 'flow (流控模式，没有请留空)', rid:'xray_flow_tr', id:'ss_node_table_xray_flow', type:'select', options:option_xflow, style:'width:412px', value: ""},
																		{ title: '<em>底层传输方式</em>', class:'xray_elem', th:'2'},
																		{ title: '传输协议 (network)', rid:'xray_network_tr', id:'ss_node_table_xray_network', type:'select', func:'v', options:["tcp", "kcp", "ws", "h2", "quic", "grpc"], style:'width:412px', value: "tcp"},
																		{ title: '* tcp伪装类型 (type)', rid:'xray_headtype_tcp_tr', id:'ss_node_table_xray_headtype_tcp', type:'select', hint:'36', func:'v', options:option_headtcp, style:'width:412px', value: "none"},
																		{ title: '* 伪装类型 (type)', rid:'xray_headtype_kcp_tr', id:'ss_node_table_xray_headtype_kcp', type:'select', func:'v', options:option_headkcp, style:'width:412px', value: "none"},
																		{ title: '* quic伪装类型 (type)', rid:'xray_headtype_quic_tr', id:'ss_node_table_xray_headtype_quic', type:'select', options:option_headquic, value: "none"},
																		{ title: '* grpc模式', rid:'xray_grpc_mode_tr', id:'ss_node_table_xray_grpc_mode', type:'select', options:option_grpcmode, value: "multi"},
																		{ title: '* 伪装域名 (host)', rid:'xray_network_host_tr', id:'ss_node_table_xray_network_host', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '* 路径 (path)', rid:'xray_network_path_tr', id:'ss_node_table_xray_network_path', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '* kcp seed', rid:'xray_kcp_seed_tr', id:'ss_node_table_xray_kcp_seed', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '底层传输安全', rid:'xray_network_security_tr', id:'ss_node_table_xray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"], ["xtls", "xtls"], ["reality", "reality"]], style:'width:412px', value: "none"},
																		{ title: '* 跳过证书验证 (AllowInsecure)', rid:'xray_network_security_ai_tr', id:'ss_node_table_xray_network_security_ai', type:'checkbox', hint:'56', value: "false"},
																		{ title: '* alpn', rid:'xray_network_security_alpn_tr', multi: [
																			{ suffix: '<input type="checkbox" id="ss_node_table_xray_network_security_alpn_h2">h2' },
																			{ suffix: '<input type="checkbox" id="ss_node_table_xray_network_security_alpn_http">http/1.1' },
																		]},
																		{ title: '* show', rid:'xray_show_tr', id:'ss_node_table_xray_show', type:'checkbox', value:false},
																		{ title: '* fingerprint', rid:'xray_fingerprint_tr', id:'ss_node_table_xray_fingerprint', type:'select', options:option_fingerprint, value: ""},
																		{ title: '* SNI', rid:'xray_network_security_sni_tr', id:'ss_node_table_xray_network_security_sni', type:'text'},
																		{ title: '* publicKey', rid:'xray_publickey_tr', id:'ss_node_table_xray_publickey', maxlen:'300', style:'width:400px', type:'text'},
																		{ title: '* shortId', rid:'xray_shortid_tr', id:'ss_node_table_xray_shortid', type:'text'},
																		{ title: '* spiderX', rid:'xray_spiderx_tr', id:'ss_node_table_xray_spiderx', type:'text'},
																		{ title: 'xray json', rid:'xray_json_tr', id:'ss_node_table_xray_json', type:'textarea', rows:'32', ph:ph_xray, style:'width:400px'},
																		// trojan
																		{ title: 'trojan 密码', rid:'trojan_uuid_tr', id:'ss_node_table_trojan_uuid', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '跳过证书验证 (AllowInsecure)', rid:'trojan_ai_tr', id:'ss_node_table_trojan_ai', type:'checkbox', value: "false"},
																		{ title: 'SNI', rid:'trojan_sni_tr', id:'ss_node_table_trojan_sni', type:'text'},
																		{ title: 'tcp fast open', rid:'trojan_tfo_tr', id:'ss_node_table_trojan_tfo', type:'checkbox', value: "false"},
																		// naive
																		{ title: 'NaïveProxy 协议', rid:'naive_prot_tr', id:'ss_node_table_naive_prot', type:'select', func:'v', options:option_naive_prot, maxlen:'300', style:'width:412px', value: "https"},		//fancyss-full
																		{ title: 'NaïveProxy 服务器', rid:'naive_server_tr', id:'ss_node_table_naive_server', type:'text', maxlen:'300', style:'width:400px'},														//fancyss-full
																		{ title: 'NaïveProxy 端口', rid:'naive_port_tr', id:'ss_node_table_naive_port', type:'text', maxlen:'300', style:'width:400px', value: "443"},												//fancyss-full
																		{ title: 'NaïveProxy 账户', rid:'naive_user_tr', id:'ss_node_table_naive_user', type:'text', maxlen:'300', style:'width:400px'},															//fancyss-full
																		{ title: 'NaïveProxy 密码', rid:'naive_pass_tr', id:'ss_node_table_naive_pass', type:'text', maxlen:'300', style:'width:400px'},															//fancyss-full
																		// tuic
																		{ title: 'tuic client json', rid:'tuic_json_tr', id:'ss_node_table_tuic_json', type:'textarea', rows:'18', ph:ph_tuic, style:'width:400px'},												//fancyss-full
																		// hy2
																		{ title: '服务器', rid:'hy2_server_tr', id:'ss_node_table_hy2_server', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},															//fancyss-full
																		{ title: '端口', rid:'hy2_port_tr', id:'ss_node_table_hy2_port', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: "443"},													//fancyss-full
																		{ title: '认证密码', rid:'hy2_pass_tr', id:'ss_node_table_hy2_pass', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},															//fancyss-full
																		{ title: '最大上行（Mbps）', rid:'hy2_up_tr', id:'ss_node_table_hy2_up', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: ""},											//fancyss-full
																		{ title: '最大下行（Mbps）', rid:'hy2_dl_tr', id:'ss_node_table_hy2_dl', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: ""},											//fancyss-full
																		{ title: 'tcp fast open', rid:'hy2_tfo_tr', id:'ss_node_table_hy2_tfo', type:'checkbox', class:'hy2_elem', value: "false"},																				//fancyss-full
																		{ title: '混淆类型', rid:'hy2_obfs_tr', id:'ss_node_table_hy2_obfs', type:'select', class:'hy2_elem', func:'v', options:option_hy2_obfs, maxlen:'300', style:'width:412px', value: "0"},			//fancyss-full
																		{ title: '混淆密码', rid:'hy2_obfs_pass_tr', id:'ss_node_table_hy2_obfs_pass', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},													//fancyss-full
																		{ title: 'SNI（域名）', rid:'hy2_sni_tr', id:'ss_node_table_hy2_sni', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},															//fancyss-full
																		{ title: '允许不安全', rid:'hy2_ai_tr', id:'ss_node_table_hy2_ai', type:'checkbox', class:'hy2_elem', value: "false"},																				//fancyss-full
																	]);
																</script>
																</table>
															</div>
														</td>
													</tr>
												</table>
												<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
													<input class="button_gen" style="margin-left: 160px;" type="button" onclick="cancel_add_node();" id="cancel_Btn" value="返回">
													<input id="add_node" class="button_gen" type="button" onclick="add_ss_node_conf(save_flag);" value="添加">
													<input id="edit_node" style="display: none;" class="button_gen" type="button" onclick="edit_ss_node_conf(save_flag);" value="修改">
													<a id="continue_add" style="display: none;margin-left: 20px;"><input id="continue_add_box" type="checkbox"  />连续添加</a>
												</div>
											</div>
											<div id="tablet_0" style="display: none;">
												<table id="table_basic" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														$('#table_basic').forms([
															// commom
															{ title: '节点选择', id:'ssconf_basic_node', type:'select', func:'onchange="ss_node_sel();"', style:'width:auto;min-width:164px;max-width:450px;', options:[], value: "1"},
															{ title: '模式', id:'ss_basic_mode', type:'select', func:'v', hint:'1', options:option_modes, value: "1"},
															{ title: '使用json配置', id:'ss_basic_v2ray_use_json', type:'checkbox', func:'v', hint:'27'},
															{ title: '使用json配置', id:'ss_basic_xray_use_json', type:'checkbox', func:'v', hint:'27'},
															{ title: '服务器地址', id:'ss_basic_server', type:'text', maxlen:'100'},
															{ title: '服务器端口', id:'ss_basic_port', type:'text', maxlen:'100'},
															{ title: '密码', id:'ss_basic_password', type:'password', maxlen:'100', peekaboo:'1'},
															{ title: '加密方式', id:'ss_basic_method', type:'select', func:'v', options:option_method},
															// ss
															{ title: '混淆 (obfs)', id:'ss_basic_ss_obfs', type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], value: "0"},
															{ title: '混淆主机名 (obfs_host)', id:'ss_basic_ss_obfs_host', type:'text', maxlen:'100', ph:'bing.com'},
															{ title: 'v2ray-plugin', id:'ss_basic_ss_v2ray', type:'select', hint: '7', func:'v', options:[["0", "关闭"], ["1", "打开"]], value: "0"},				//fancyss-full
															{ title: 'v2ray-plugin参数', id:'ss_basic_ss_v2ray_opts', type:'text', maxlen:'300', ph:'tls;host=yourhost.com;path=/;'},								//fancyss-full
															// ssr
															{ title: '协议 (protocol)', id:'ss_basic_rss_protocol', type:'select', func:'v', options:option_protocals},
															{ title: '协议参数 (protocol_param)', id:'ss_basic_rss_protocol_param', type:'password', hint:'54', maxlen:'100', ph:'id:password', peekaboo:'1'},
															{ title: '混淆 (obfs)', id:'ss_basic_rss_obfs', type:'select', func:'v', options:option_obfs},
															{ title: '混淆参数 (obfs_param)', id:'ss_basic_rss_obfs_param', type:'text', hint:'11', maxlen:'300', ph:'cloudflare.com;bing.com'},
															// v2ray
															{ title: '用户id (id)', id:'ss_basic_v2ray_uuid', type:'password', hint:'49', maxlen:'300', style:'width:300px;', peekaboo:'1'},
															{ title: '额外ID (Alterld)', id:'ss_basic_v2ray_alterid', type:'text', hint:'48', maxlen:'50'},
															{ title: '加密方式 (security)', id:'ss_basic_v2ray_security', type:'select', hint:'47', options:option_v2enc},
															{ title: '传输协议 (network)', id:'ss_basic_v2ray_network', type:'select', func:'v', hint:'35', options:["tcp", "kcp", "ws", "h2", "quic", "grpc"]},
															{ title: '* tcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_tcp', type:'select', func:'v', hint:'36', options:option_headtcp},
															{ title: '* kcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_kcp', type:'select', func:'v', hint:'37', options:option_headkcp},
															{ title: '* quic伪装类型 (type)', id:'ss_basic_v2ray_headtype_quic', type:'select', options:option_headquic},
															{ title: '* grpc模式', id:'ss_basic_v2ray_grpc_mode', type:'select', options:option_grpcmode},
															{ title: '* 伪装域名 (host)', id:'ss_basic_v2ray_network_host', type:'text', hint:'28', maxlen:'300', ph:'没有请留空'},
															{ title: '* 路径 (path)', rid:'ss_basic_v2ray_network_path_tr', id:'ss_basic_v2ray_network_path', type:'text', hint:'29', maxlen:'300', ph:'没有请留空'},
															{ title: '* kcp seed', id:'ss_basic_v2ray_kcp_seed', type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '底层传输安全', id:'ss_basic_v2ray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"]]},
															{ title: '* 跳过证书验证 (AllowInsecure)', id:'ss_basic_v2ray_network_security_ai', type:'checkbox', hint:'56'},
															{ title: '* alpn', id:'ss_basic_v2ray_network_security_alpn', multi: [
																{ suffix: '<input type="checkbox" id="ss_basic_v2ray_network_security_alpn_h2">h2' },
																{ suffix: '<input type="checkbox" id="ss_basic_v2ray_network_security_alpn_http">http/1.1' },
															]},
															{ title: '* SNI', id:'ss_basic_v2ray_network_security_sni', type:'text'},
															{ title: '多路复用 (Mux)', id:'ss_basic_v2ray_mux_enable', type:'checkbox', func:'v', hint:'31'},
															{ title: 'Mux并发连接数', id:'ss_basic_v2ray_mux_concurrency', type:'text', hint:'32', maxlen:'300'},
															{ title: 'v2ray json', id:'ss_basic_v2ray_json', type:'textarea', rows:'36', ph:ph_v2ray},
															// xray
															{ title: '用户id (id)', id:'ss_basic_xray_uuid', type:'password', hint:'49', maxlen:'300', style:'width:300px;', peekaboo:'1'},
															{ title: '加密 (encryption)', id:'ss_basic_xray_encryption', type:'text', hint:'55', maxlen:'50'},
															{ title: 'flow (流控模式，没有请留空)', id:'ss_basic_xray_flow', type:'select', options:option_xflow},
															{ title: '传输协议 (network)', id:'ss_basic_xray_network', type:'select', func:'v', hint:'35', options:["tcp", "kcp", "ws", "h2", "quic", "grpc"]},
															{ title: '* tcp伪装类型 (type)', id:'ss_basic_xray_headtype_tcp', type:'select', func:'v', hint:'36', options:option_headtcp},
															{ title: '* kcp伪装类型 (type)', id:'ss_basic_xray_headtype_kcp', type:'select', func:'v', hint:'37', options:option_headkcp},
															{ title: '* quic伪装类型 (type)', id:'ss_basic_xray_headtype_quic', type:'select', options:option_headquic},
															{ title: '* grpc模式', id:'ss_basic_xray_grpc_mode', type:'select', options:option_grpcmode},
															{ title: '* 伪装域名 (host)', id:'ss_basic_xray_network_host', type:'text', hint:'28', maxlen:'300', ph:'没有请留空'},
															{ title: '* 路径 (path)', rid:'ss_basic_xray_network_path_tr', id:'ss_basic_xray_network_path', type:'text', hint:'29', maxlen:'300', ph:'没有请留空'},
															{ title: '* kcp seed', id:'ss_basic_xray_kcp_seed', type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '底层传输安全', id:'ss_basic_xray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"], ["xtls", "xtls"], ["reality", "reality"]]},
															{ title: '* 跳过证书验证 (AllowInsecure)', id:'ss_basic_xray_network_security_ai', type:'checkbox', hint:'56'},
															{ title: '* alpn', id:'ss_basic_xray_network_security_alpn', multi: [
																{ suffix: '<input type="checkbox" id="ss_basic_xray_network_security_alpn_h2">h2' },
																{ suffix: '<input type="checkbox" id="ss_basic_xray_network_security_alpn_http">http/1.1' },
															]},
															{ title: '* show', id:'ss_basic_xray_show', type:'checkbox'},
															{ title: '* fingerprint', id:'ss_basic_xray_fingerprint', type:'select', options:option_fingerprint},
															{ title: '* SNI', id:'ss_basic_xray_network_security_sni', type:'text', ph:'realitySettings中的serverName'},
															{ title: '* publickey', id:'ss_basic_xray_publickey', type:'password', maxlen:'300', style:'width:320px;', ph:'填写公钥', peekaboo:'1'},
															{ title: '* shortId', id:'ss_basic_xray_shortid', type:'text', ph:'没有请留空'},
															{ title: '* spiderX', id:'ss_basic_xray_spiderx', type:'text', ph:'没有请留空'},
															{ title: 'xray json', id:'ss_basic_xray_json', type:'textarea', rows:'36', ph:ph_xray},
															{ title: '其它', rid:'v2ray_binary_update_tr', prefix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="v2ray_binary_update(2)">更新v2ray程序</a>'},	//fancyss-full
															{ title: '其它', rid:'xray_binary_update_tr', prefix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="xray_binary_update(2)">更新/切换xray程序</a>'},
															//trojan
															{ title: 'trojan 密码', id:'ss_basic_trojan_uuid', type:'password', maxlen:'300', style:'width:280px;', peekaboo:'1'},
															{ title: '跳过证书验证 (AllowInsecure)', id:'ss_basic_trojan_ai_tr', multi: [
																{ suffix: '<input type="checkbox" id="ss_basic_trojan_ai">' },
																{ suffix:'<lable id="ss_basic_trojan_ai_note"></lable>' },
															]},
															{ title: 'SNI', id:'ss_basic_trojan_sni', type:'text'},
															{ title: 'tcp fast open', id:'ss_basic_trojan_tfo', type:'checkbox'},
															// naive
															{ title: 'NaïveProxy 协议', id:'ss_basic_naive_prot', type:'select', func:'v', options:option_naive_prot, maxlen:'300', value: "https"},								//fancyss-full
															{ title: 'NaïveProxy 服务器', id:'ss_basic_naive_server', type:'text', maxlen:'300'},																					//fancyss-full
															{ title: 'NaïveProxy 端口', id:'ss_basic_naive_port', type:'text', maxlen:'300', value: "443"},																			//fancyss-full
															{ title: 'NaïveProxy 账户', id:'ss_basic_naive_user', type:'text', maxlen:'300'},																						//fancyss-full
															{ title: 'NaïveProxy 密码', id:'ss_basic_naive_pass', type:'text', maxlen:'300'},																						//fancyss-full
															//tuic
															{ title: 'tuic json', id:'ss_basic_tuic_json', type:'textarea', rows:'18', ph:ph_tuic},																					//fancyss-full
															//hysteria2
															{ title: '服务器', id:'ss_basic_hy2_server', type:'text', maxlen:'300'},																								//fancyss-full
															{ title: '端口', id:'ss_basic_hy2_port', type:'text', maxlen:'300'},																									//fancyss-full
															{ title: '认证密码', id:'ss_basic_hy2_pass', type:'text', maxlen:'300'},																								//fancyss-full
															{ title: '最大上行（Mbps）', id:'ss_basic_hy2_up', type:'text', maxlen:'300'},																							//fancyss-full
															{ title: '最大下行（Mbps）', id:'ss_basic_hy2_dl', type:'text', maxlen:'300'},																							//fancyss-full
															{ title: 'tcp fast open', id:'ss_basic_hy2_tfo', type:'checkbox'},																										//fancyss-full
															{ title: '混淆类型', id:'ss_basic_hy2_obfs', type:'select', func:'v', options:option_hy2_obfs, maxlen:'300', value: "0"},												//fancyss-full
															{ title: '混淆密码', id:'ss_basic_hy2_obfs_pass', type:'text', maxlen:'300'},																							//fancyss-full
															{ title: 'SNI（域名）', id:'ss_basic_hy2_sni', type:'text'},																											//fancyss-full
															{ title: '允许不安全', id:'ss_basic_hy2_ai', type:'checkbox'},																											//fancyss-full
														]);
													</script>
												</table>
											</div>
											<div id="tablet_1" style="display: none;">
												<div id="ss_list_table"></div>
											</div>
											<div id="tablet_2" style="display: none;">
												<table id="table_failover" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
													<script type="text/javascript">
														var fa1 = ["2", "3", "4", "5"];
														var fa2_1 = ["10", "15", "20"];
														var fa2_2 = ["2", "3", "4", "5", "6", "7", "8"];
														var fa3_1 = ["10", "15", "20"];
														var fa3_2 = ["100", "150", "200", "250", "300", "350", "400", "450", "500", "1000"];
														var fa4_1 = [["0", "关闭插件"], ["1", "重启插件"], ["2", "切换到"]];
														var fa4_2 = [["1", "备用节点"], ["2", "下个节点"], ["3", "web延迟最低的节点"]];
														var fa5 = [["1", "2s - 3s"], ["2", "4s - 7s"], ["3", "8s - 15s"], ["4", "16s - 31s"], ["5", "32s - 63s"]];
														$('#table_failover').forms([
															{ title: '故障转移开关', id:'ss_failover_enable',type:'checkbox', func:'v', value:false},
															{ title: '故障转移设置', rid:'failover_settings_1', multi: [
																{ suffix:'<div style="margin-top: 5px;">' },
																{ id:'ss_failover_c1', type:'checkbox', value:false },
																{ suffix:'<lable>👉&nbsp;国外连续发生&nbsp;</lable>' },
																{ id:'ss_failover_s1', type:'select', style:'width:auto', options:fa1, value:'3'},
																{ suffix:'<lable>&nbsp;次故障；<br /></lable>' },
																{ suffix:'</div>' },
																//line3
																{ suffix:'<div style="margin-top: 5px;">' },
																{ id:'ss_failover_c2', type:'checkbox', value:false },
																{ suffix:'<lable>👉&nbsp;最近&nbsp;</lable>' },
																{ id:'ss_failover_s2_1', type:'select', style:'width:auto', options:fa2_1, value:'15'},
																{ suffix:'<lable>&nbsp;次国外状态检测中，故障次数超过&nbsp;</lable>' },
																{ id:'ss_failover_s2_2', type:'select', style:'width:auto', options:fa2_2, value:'4'},
																{ suffix:'<lable>&nbsp;次；<br /></lable>' },
																{ suffix:'</div>' },
																//line4
																{ suffix:'<div style="margin-top: 5px;">' },
																{ id:'ss_failover_c3', type:'checkbox', value:false },
																{ suffix:'<lable>👉&nbsp;最近&nbsp;</lable>' },
																{ id:'ss_failover_s3_1', type:'select', style:'width:auto', options:fa3_1, value:'20'},
																{ suffix:'<lable>&nbsp;次国外状态检测中，平均延迟超过&nbsp;</lable>' },
																{ id:'ss_failover_s3_2', type:'select', style:'width:auto', options:fa3_2, value:'500'},
																{ suffix:'<lable>ms<br /></lable>' },
																{ suffix:'</div>' },
																//line5
																{ suffix:'<div style="margin-top: 5px;">' },
																{ suffix:'<lable>&nbsp;以上有一个条件满足，则&nbsp;</lable>' },
																{ id:'ss_failover_s4_1', type:'select', style:'width:auto', func:'v', options:fa4_1, value:'2'},
																{ id:'ss_failover_s4_2', type:'select', style:'width:auto', func:'v', options:fa4_2, value:'2'},
																{ id:'ss_failover_s4_3', type:'select', style:'width:170px', func:'v', options:[]},
																{ suffix:'</div>' },
															]},
															{ title: '状态检测时间间隔', rid:'interval_settings', multi: [
																{ id:'ss_basic_interval', type:'select', style:'width:auto',options:fa5, value:'2'},
																{ suffix:'<small>&nbsp;默认：4 - 7s</small>' },
															]},
															{ title: '历史记录保存数量', rid:'failover_settings_2', multi: [
																{ suffix:'<lable>最多保留&nbsp;</lable>' },
																{ id:'ss_failover_s5', type:'select', style:'width:auto',options:["1000", "2000", "3000", "4000"], value:'2000'},
																{ suffix:'<lable>&nbsp;行日志&nbsp;</lable>' },
															]},
															{ title: '查看历史状态', rid:'failover_settings_3', multi: [
																{ suffix:'<a type="button" id="look_logf" class="ss_btn" style="cursor:pointer" onclick="lookup_status_log(1)">国外状态历史</a>&nbsp;' },
																{ suffix:'<a type="button" id="look_logc" class="ss_btn" style="cursor:pointer" onclick="lookup_status_log(2)">国内状态历史</a>' },
															]},
														]);
													</script>
												</table>
											</div>
											<div id="tablet_3" style="display: none;">
												<table id="table_dns" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var isp_dns_raw='<% nvram_get("wan0_dns"); %>';
														var isp_dns_1=isp_dns_raw.split(" ")[0];
														var isp_dns_2=isp_dns_raw.split(" ")[1];
														validator.ipv4_addr(isp_dns_1)
														var option_dnsp = [
																		   ["1", "chinadns-ng"]
																		  ,["2", "smartdns"]			//fancyss-full
																		  ,["3", "dohclient"]			//fancyss-full
																		  ];
	
														// 进阶DNS方案1 chinadns-ng国内:协议选择
														option_dnsngc_prot = [
																			  ["1", "udp"]
																			 ,["2", "tcp"]
																			 ,["3", "DoH"]				//fancyss-full
																			];
														// 进阶DNS方案1 chinadns-ng国内dns:udp 
														var option_dnsngc_udp = [];
														if(isp_dns_1 && isp_dns_2){
															option_dnsngc_udp.push(["group", "运营商DNS"]);
															option_dnsngc_udp.push(["1", "⚪" + isp_dns_1]);
															option_dnsngc_udp.push(["2", "⚪" + isp_dns_2]);
														}else if(isp_dns_1 && !isp_dns_2){
															option_dnsngc_udp.push(["group", "运营商DNS"]);
															option_dnsngc_udp.push(["1", isp_dns_1]);
														}
														option_dnsngc_udp.push(["group", "阿里公共DNS"]);
														option_dnsngc_udp.push(["3", "🟠223.5.5.5"]);
														option_dnsngc_udp.push(["4", "🟠223.6.6.6"]);
														option_dnsngc_udp.push(["group", "DNSPod DNS"]);
														option_dnsngc_udp.push(["5", "🟠119.29.29.29"]);
														option_dnsngc_udp.push(["6", "🟠119.28.28.28"]);
														option_dnsngc_udp.push(["group", "114 DNS"]);
														option_dnsngc_udp.push(["7", "⚫114.114.114.114"]);
														option_dnsngc_udp.push(["8", "⚫114.114.115.115"]);
														option_dnsngc_udp.push(["group", "OneDNS"]);
														option_dnsngc_udp.push(["9", "🟠117.50.11.11（拦截版）"]);
														option_dnsngc_udp.push(["10", "🟠52.80.66.66（拦截版）"]);
														option_dnsngc_udp.push(["11", "🟠117.50.10.10（纯净版）"]);
														option_dnsngc_udp.push(["12", "🟠52.80.52.52（纯净版）"]);
														option_dnsngc_udp.push(["13", "🟠117.50.60.30（家庭版）"]);
														option_dnsngc_udp.push(["14", "🟠52.80.60.30（家庭版）"]);
														option_dnsngc_udp.push(["group", "360安全DNS"]);
														option_dnsngc_udp.push(["15", "🟠101.226.4.6（电信/铁通/移动）"]);
														option_dnsngc_udp.push(["16", "🟠218.30.118.6（电信/铁通/移动）"]);
														option_dnsngc_udp.push(["17", "🟠123.125.81.6（联通）"]);
														option_dnsngc_udp.push(["18", "🟠140.207.198.6（联通）"]);
														option_dnsngc_udp.push(["group", "cnnic DNS"]);
														option_dnsngc_udp.push(["19", "⚫1.2.4.8"]);
														option_dnsngc_udp.push(["20", "⚫210.2.4.8"]);
														option_dnsngc_udp.push(["group", "百度DNS"]);
														option_dnsngc_udp.push(["21", "🟠180.76.76.76"]);
														option_dnsngc_udp.push(["group", "教育网DNS"]);
														option_dnsngc_udp.push(["22", "🟠101.6.6.6:5353（清华大学）"]);
														option_dnsngc_udp.push(["23", "⚫58.132.8.1（北京）"]);
														option_dnsngc_udp.push(["24", "⚫101.7.8.9（北京）"]);
														option_dnsngc_udp.push(["group", "SmartDNS"]);				//fancyss-full
														option_dnsngc_udp.push(["96", "⚫SmartDNS (UDP)"]);		//fancyss-full
														option_dnsngc_udp.push(["group", "自定义DNS"]);
														option_dnsngc_udp.push(["99", "⚪自定义DNS (UDP)"]);
														// 进阶DNS方案1 chinadns-ng国内tcp | 进阶DNS方案3 dohclient 国内 tcp
														option_dnsngc_tcp = [
																			 ["group", "阿里公共DNS"],
																			 ["3", "🟠223.5.5.5"],
																			 ["4", "🟠223.6.6.6"],
																			 ["group", "DNSPod DNS"],
																			 //["5", "🟠119.29.29.29"],
																			 ["6", "🟠119.28.28.28"],
																			 ["group", "114 DNS"],
																			 ["7", "⚫114.114.114.114"],
																			 ["8", "⚫114.114.115.115"],
																			 ["group", "OneDNS"],
																			 ["10", "🟠52.80.66.66（拦截版）"],
																			 ["12", "🟠52.80.52.52（纯净版）"],
																			 ["group", "360安全DNS"],
																			 ["16", "🟠218.30.118.6（电信/铁通/移动）"],
																			 ["17", "🟠123.125.81.6（联通）"],
																			 ["18", "🟠140.207.198.6（联通）"],
																			 ["group", "教育网DNS"],
																			 ["22", "🟠101.6.6.6:5353（清华大学）"],
																			 ["group", "SmartDNS"],				//fancyss-full
																			 ["97", "⚫SmartDNS (tcp)"],		//fancyss-full
																			 ["group", "自定义DNS"],
																			 ["99", "⚪自定义DNS (tcp)"]
																			 ];
														option_dnsngc_doh = [									//fancyss-full
																			 ["group", "dohclient"],			//fancyss-full
																			 ["1", "🟠阿里公共DNS"],			//fancyss-full
																			 ["2", "🟠DNSPod公共DNS"],			//fancyss-full
																			 ["3", "🟠360安全DNS"],				//fancyss-full
																			 ["group", "SmartDNS"],				//fancyss-full
																			 ["98", "⚫多上游DoH服务器"]		//fancyss-full
																			 ];									//fancyss-full
														var option_dnsngf_1_opt = [
																				   ["1", "udp"]
																			 	  ,["2", "tcp"]
																				  ,["3", "DoH"]					//fancyss-full
																			 ];
														var option_dnsngf_1_val_udp = [
																			 		   ["group", "Google DNS"],
																					   ["1", "🟠8.8.8.8"],
																					   ["2", "🟠8.8.4.4"],
																			 		   ["group", "Cloudflare DNS"],
																					   ["3", "⚫1.1.1.1"],
																					   ["4", "⚫1.0.0.1"],
																			 		   ["group", "Quad9"],
																					   ["5", "🟠9.9.9.11"],
																					   ["6", "🟠149.112.112.11"],
																			 		   ["group", "OpenDNS"],
																					   ["7", "⚫208.67.222.222"],
																					   ["8", "⚫208.67.220.220"],
																			 		   ["group", "DNS.SB"],
																					   ["9", "⚫185.222.222.222"],
																					   ["10", "⚫45.11.45.11"],
																			 		   ["group", "AdGuard"],
																					   ["11", "🟡94.140.14.14"],
																					   ["12", "🟡94.140.15.15"],
																			 		   ["group", "quad101"],
																					   ["13", "🟠101.101.101.101"],
																					   ["14", "🟠101.102.103.104"],
																			 		   ["group", "自定义DNS"],
																					   ["99", "⚪自定义DNS（udp）"]
																				  	  ];
														var option_dnsngf_1_val_tcp = [
																			 		   ["group", "Google DNS"],
																					   ["1", "🟠8.8.8.8"],
																					   ["2", "🟠8.8.4.4"],
																			 		   ["group", "Cloudflare DNS"],
																					   ["3", "⚫1.1.1.1"],
																					   ["4", "⚫1.0.0.1"],
																			 		   ["group", "Quad9"],
																					   ["5", "🟠9.9.9.11"],
																					   ["6", "🟠149.112.112.11"],
																			 		   ["group", "OpenDNS"],
																					   ["7", "⚫208.67.222.222"],
																					   ["8", "⚫208.67.220.220"],
																			 		   ["group", "DNS.SB"],
																					   ["9", "⚫185.222.222.222"],
																					   ["10", "⚫45.11.45.11"],
																			 		   ["group", "AdGuard"],
																					   ["11", "🟡94.140.14.14"],
																					   ["12", "🟡94.140.15.15"],
																			 		   ["group", "quad101"],
																					   ["13", "🟠101.101.101.101"],
																					   ["14", "🟠101.102.103.104"],
																			 		   ["group", "自定义DNS"],
																					   ["99", "⚪自定义DNS（tcp）"]
																				  	  ];
														var option_dnsngf_1_val_doh = [										//fancyss-full
																		   			   ["11", "⚫Cloudflare"],				//fancyss-full
																		   			   ["12", "🟠Google"],					//fancyss-full
																		   			   ["13", "🟠quad9"],					//fancyss-full
																		   			   ["14", "🟡AdGuard"],					//fancyss-full
																		   			   ["15", "🟠Quad 101"],				//fancyss-full
																		   			   ["16", "⚫OpenDNS"],					//fancyss-full
																		   			   ["17", "⚫DNS.SB"],					//fancyss-full
																		   			   ["18", "⚫cleanbrowsing"],			//fancyss-full
																		  		       ["23", "⚫nextdns"],					//fancyss-full
																					  ];									//fancyss-full
														var option_dnsngf_2_val = [											//fancyss-full
																			 	   ["group", "国外直连组 (dohclient)"],		//fancyss-full
																		  		   ["11", "⚫Cloudflare"],					//fancyss-full
																		  		   ["16", "⚫OpenDNS"],						//fancyss-full
																		  		   ["17", "⚫DNS.SB"],						//fancyss-full
																		   		   ["18", "⚫cleanbrowsing"],				//fancyss-full
																		  		   ["19", "⚫he.net"],						//fancyss-full
																		  		   ["20", "⚫PureDNS"],						//fancyss-full
																		  		   ["21", "⚫dnslow"],						//fancyss-full
																		  		   ["22", "🟠dnswarden"],					//fancyss-full
																		  		   ["24", "⚫bebasid"],						//fancyss-full
																		  		   ["25", "🟠AT&T "],						//fancyss-full
																			 	   ["group", "国内直连组 (dohclient)"],		//fancyss-full
																		  		   ["1", "🟠阿里公共DNS"],					//fancyss-full
																		  		   ["2", "🟠DNSPod公共DNS"],				//fancyss-full
																		  		   ["3", "🟠360安全DNS"],					//fancyss-full
																			 	   ["group", "其它 (SmartDNS)"],			//fancyss-full
																		  		   ["97", "⚫SmartDNS"],					//fancyss-full
																		  		  ];										//fancyss-full
														// 进阶DNS方案1 chinadns-ng国外dns-2
														var option_dnsngf_2_opt = [
																			  	   ["1", "udp"]
																			  	  ,["2", "tcp"]
																			  	  ,["3", "DoH"]								//fancyss-full
																				  ];
														// 进阶DNS方案2 smartdns
														var option_smrt = [													//fancyss-full
																		   ["1", "1：国内：运营商DNS；国外：代理"],			//fancyss-full
																		   ["2", "2：国内：运营商DNS，国外：直连"],			//fancyss-full
																		   ["3", "3：国内：运营商DNS，国外：代理 + 直连"],	//fancyss-full
																		   ["4", "4：国内：多上游DNS，国外：代理"],			//fancyss-full
																		   ["5", "5：国内：多上游DNS，国外：直连"],			//fancyss-full
																		   ["6", "6：国内：多上游DNS，国外：代理 + 直连"],	//fancyss-full
																		   ["7", "7：自定义配置1"],							//fancyss-full
																		   ["8", "8：自定义配置2"],							//fancyss-full
																		   ["9", "9：自定义配置3"]							//fancyss-full
																		  ];												//fancyss-full
														// 进阶DNS方案3 dohclient 国内 doh/udp
														option_protc_sel_chn = [											//fancyss-full
																			  ["1", "udp"],									//fancyss-full
																			  ["2", "tcp"],									//fancyss-full
																			  ["3", "DoH"]									//fancyss-full
																			 ];												//fancyss-full
														option_protc_sel_frn = [											//fancyss-full
																			  ["2", "tcp"],									//fancyss-full
																			  ["3", "DoH"]									//fancyss-full
																			 ];												//fancyss-full
														// 进阶DNS方案3 dohclient 国内udp
														var option_dohc_udp_china = [];										//fancyss-full
														if(isp_dns_1 && isp_dns_2){											//fancyss-full
															option_dohc_udp_china.push(["group", "运营商DNS"]);				//fancyss-full
															option_dohc_udp_china.push(["1", "⚪" + isp_dns_1]);			//fancyss-full
															option_dohc_udp_china.push(["2", "⚪" + isp_dns_2]);			//fancyss-full
														}else if(isp_dns_1 && !isp_dns_2){									//fancyss-full
															option_dohc_udp_china.push(["group", "运营商DNS"]);				//fancyss-full
															option_dohc_udp_china.push(["1", "⚪" + isp_dns_1]);			//fancyss-full
														}																	//fancyss-full
														option_dohc_udp_china.push(["group", "阿里公共DNS"]);				//fancyss-full
														option_dohc_udp_china.push(["3", "🟠223.5.5.5"]);					//fancyss-full
														option_dohc_udp_china.push(["4", "🟠223.6.6.6"]);					//fancyss-full
														option_dohc_udp_china.push(["group", "DNSPod DNS"]);				//fancyss-full
														option_dohc_udp_china.push(["5", "🟠119.29.29.29"]);				//fancyss-full
														option_dohc_udp_china.push(["6", "🟠119.28.28.28"]);				//fancyss-full
														option_dohc_udp_china.push(["group", "114 DNS"]);					//fancyss-full
														option_dohc_udp_china.push(["7", "⚫114.114.114.114"]);				//fancyss-full
														option_dohc_udp_china.push(["8", "⚫114.114.115.115"]);				//fancyss-full
														option_dohc_udp_china.push(["group", "OneDNS"]);					//fancyss-full
														option_dohc_udp_china.push(["9", "🟠117.50.11.11（拦截版）"]);			//fancyss-full
														option_dohc_udp_china.push(["10", "🟠52.80.66.66（拦截版）"]);			//fancyss-full
														option_dohc_udp_china.push(["11", "🟠117.50.10.10（纯净版）"]);			//fancyss-full
														option_dohc_udp_china.push(["12", "🟠52.80.52.52（纯净版）"]);			//fancyss-full
														option_dohc_udp_china.push(["13", "🟠117.50.60.30（家庭版）"]);			//fancyss-full
														option_dohc_udp_china.push(["14", "🟠52.80.60.30（家庭版）"]);			//fancyss-full
														option_dohc_udp_china.push(["group", "360安全DNS"]);					//fancyss-full
														option_dohc_udp_china.push(["15", "🟠101.226.4.6（电信/铁通/移动）"]);	//fancyss-full
														option_dohc_udp_china.push(["16", "🟠218.30.118.6（电信/铁通/移动）"]);	//fancyss-full
														option_dohc_udp_china.push(["17", "🟠123.125.81.6（联通）"]);			//fancyss-full
														option_dohc_udp_china.push(["18", "🟠140.207.198.6（联通）"]);			//fancyss-full
														option_dohc_udp_china.push(["group", "cnnic DNS"]);						//fancyss-full
														option_dohc_udp_china.push(["19", "⚫1.2.4.8"]);						//fancyss-full
														option_dohc_udp_china.push(["20", "⚫210.2.4.8"]);						//fancyss-full
														option_dohc_udp_china.push(["group", "百度DNS"]);						//fancyss-full
														option_dohc_udp_china.push(["21", "🟠180.76.76.76"]);					//fancyss-full
														option_dohc_udp_china.push(["group", "教育网DNS"]);						//fancyss-full
														option_dohc_udp_china.push(["22", "🟠101.6.6.6:5353（清华大学）"]);		//fancyss-full
														option_dohc_udp_china.push(["23", "⚫58.132.8.1（北京）"]);				//fancyss-full
														option_dohc_udp_china.push(["24", "⚫101.7.8.9（北京）"]);				//fancyss-full
														option_dohc_udp_china.push(["group", "自定义DNS"]);						//fancyss-full
														option_dohc_udp_china.push(["99", "⚪自定义DNS (udp)"]);				//fancyss-full
														option_dohc_tcp_china = [												//fancyss-full
																				 ["group", "阿里公共DNS"],						//fancyss-full
																				 ["3", "🟠223.5.5.5"],							//fancyss-full
																				 ["4", "🟠223.6.6.6"],							//fancyss-full
																				 ["group", "DNSPod DNS"],						//fancyss-full
																				 ["5", "🟠119.29.29.29"],						//fancyss-full
																				 ["6", "🟠119.28.28.28"],						//fancyss-full
																				 ["group", "114 DNS"],							//fancyss-full
																				 ["7", "⚫114.114.114.114"],					//fancyss-full
																				 ["8", "⚫114.114.115.115"],					//fancyss-full
																				 ["group", "OneDNS"],							//fancyss-full
																				 ["10", "🟠52.80.66.66（拦截版）"],				//fancyss-full
																				 ["12", "🟠52.80.52.52（纯净版）"],				//fancyss-full
																				 ["group", "360安全DNS"],						//fancyss-full
																				 ["16", "🟠218.30.118.6（电信/铁通/移动）"],	//fancyss-full
																				 ["17", "🟠123.125.81.6（联通）"],				//fancyss-full
																				 ["18", "🟠140.207.198.6（联通）"],				//fancyss-full
																				 ["group", "教育网DNS"],						//fancyss-full
																				 ["22", "🟠101.6.6.6:5353（清华大学）"],		//fancyss-full
																				 ["group", "自定义DNS"],						//fancyss-full
																				 ["99", "⚪自定义DNS (tcp)"]					//fancyss-full
																				];												//fancyss-full
														// 进阶DNS方案3 dohclient 国内 doh
														option_dohc_doh_china = [												//fancyss-full
																				 ["1", "🟠阿里公共DNS"],						//fancyss-full
																				 ["2", "🟠DNSPod公共DNS"],						//fancyss-full
																				 ["3", "🟠360安全DNS"]							//fancyss-full
																				];												//fancyss-full
														// 进阶DNS方案3 dohclient 国外 tcp
														var option_dohc_tcp_foreign = [											//fancyss-full
																		   ["1", "Cloudflare [1.1.1.1]"],						//fancyss-full
																		   ["2", "Cloudflare [1.0.0.1]"],						//fancyss-full
																		   ["3", "Google [8.8.8.8]"],							//fancyss-full
																		   ["4", "Google [8.8.4.4]"],							//fancyss-full
																		   ["5", "quad9 [9.9.9.9]"],							//fancyss-full
																		   ["6", "OpenDNS [208.67.222.222]"],					//fancyss-full
																		   ["7", "OpenDNS [208.67.220.220]"],					//fancyss-full
																		   ["8", "DNS.SB [185.222.222.222]"],					//fancyss-full
																		   ["9", "DNS.SB [45.11.45.11]"],						//fancyss-full
																		   ["10", "quad101 [101.101.101.101]"],					//fancyss-full
																		   ["11", "quad101 [101.102.103.104]"],					//fancyss-full
																		   ["12", "AdGuard [94.140.14.14]"],					//fancyss-full
																		   ["13", "AdGuard [94.140.15.15]"],					//fancyss-full
																		   ["99", "自定义DNS(tcp)"]								//fancyss-full
																		  ];													//fancyss-full
														// 进阶DNS方案3 dohclient 国外 doh
														var option_dohcf = [													//fancyss-full
																		   ["11", "⚫Cloudflare"],								//fancyss-full
																		   ["12", "🟠Google"],									//fancyss-full
																		   ["13", "🟠quad9"],									//fancyss-full
																		   ["14", "🟡AdGuard"],									//fancyss-full
																		   ["15", "🟠Quad 101"],								//fancyss-full
																		   ["16", "⚫OpenDNS"],									//fancyss-full
																		   ["17", "⚫DNS.SB"]									//fancyss-full
																		  ];													//fancyss-full
														var option_cache_timeout = [["0", "从不过期"], ["1", "根据ttl"], ["1800", "半小时"], ["3600", "一小时"], ["7200", "两小时"], ["43200", "12小时"], ["86400", "24小时"]];  //fancyss-full
														// 基础DNS方案：中国dns
														var option_chndns = [];
														if(isp_dns_1 && isp_dns_2){
															option_chndns.push(["group", "运营商DNS"]);
															option_chndns.push(["1", isp_dns_1]);
															option_chndns.push(["2", isp_dns_2]);
														}else if(isp_dns_1 && !isp_dns_2){
															option_chndns.push(["group", "运营商DNS"]);
															option_chndns.push(["1", isp_dns_1]);
														}
														option_chndns.push(["group", "阿里公共DNS"]);
														option_chndns.push(["3", "223.5.5.5"]);
														option_chndns.push(["4", "223.6.6.6"]);
														option_chndns.push(["group", "DNSPod DNS"]);
														option_chndns.push(["5", "119.29.29.29"]);
														option_chndns.push(["6", "119.28.28.28"]);
														option_chndns.push(["group", "114 DNS"]);
														option_chndns.push(["7", "114.114.114.114"]);
														option_chndns.push(["8", "114.114.115.115"]);
														option_chndns.push(["group", "OneDNS"]);
														option_chndns.push(["9", "117.50.11.11（拦截版）"]);
														option_chndns.push(["10", "52.80.66.66（拦截版）"]);
														option_chndns.push(["11", "117.50.10.10（纯净版）"]);
														option_chndns.push(["12", "52.80.52.52（纯净版）"]);
														option_chndns.push(["13", "117.50.60.30（家庭版）"]);
														option_chndns.push(["14", "52.80.60.30（家庭版）"]);
														option_chndns.push(["group", "360安全DNS"]);
														option_chndns.push(["15", "101.226.4.6（电信/铁通/移动）"]);
														option_chndns.push(["16", "218.30.118.6（电信/铁通/移动）"]);
														option_chndns.push(["17", "123.125.81.6（联通）"]);
														option_chndns.push(["18", "140.207.198.6（联通）"]);
														option_chndns.push(["group", "cnnic DNS"]);
														option_chndns.push(["19", "1.2.4.8"]);
														option_chndns.push(["20", "210.2.4.8"]);
														option_chndns.push(["group", "百度DNS"]);
														option_chndns.push(["21", "180.76.76.76"]);
														option_chndns.push(["group", "教育网DNS"]);
														option_chndns.push(["22", "101.6.6.6:5353（清华大学）"]);
														option_chndns.push(["23", "58.132.8.1（北京）"]);
														option_chndns.push(["24", "101.7.8.9（北京）"]);
														option_chndns.push(["group", "SmartDNS"]);										//fancyss-full
														option_chndns.push(["98", "SmartDNS (UDP)"]);									//fancyss-full
														option_chndns.push(["group", "自定义DNS"]);
														option_chndns.push(["99", "自定义DNS (UDP)"]);
														// 基础DNS方案：外国dns
														var option_dnsf = [["3", "🚀 dns2socks"],
																		   ["4", "🚀 ss-tunnel"],										//fancyss-full
																		   ["7", "🚀 v2ray/xray_dns"],
																		   ["9", "🌏 smartdns"],										//fancyss-full
																		   ["8", "🌏 直连（udp）"]
																		  ];
														// 节点域名解析DNS方案： udp选项
														var option_resv = [
																			   ["group", "自动选取"],
																			   ["-1", "自动选取模式（国内组）"],
																			   ["-2", "自动选取模式（仅国组）"],
																			   ["0", "自动选取模式（国内组 + 国外组）"],
																			   ["group", "国内DNS"],
																			   ["1", "阿里DNS【223.5.5.5】"],
																			   ["2", "DNSPod DNS【119.29.29.29】"],
																			   ["3", "114DNS【114.114.114.114】"],
																			   ["4", "OneDNS【52.80.66.66】"],
																			   ["5", "360安全DNS 电信/铁通/移动【218.30.118.6】"],
																			   ["6", "360安全DNS 联通【123.125.81.6】"],
																			   ["7", "清华大学TUNA DNS【101.6.6.6:5353】"],
																			   ["8", "百度DNS【180.76.76.76】"],
																			   ["group", "国外DNS"],
																			   ["11", "Google DNS【8.8.8.8】"],
																			   ["12", "CloudFlare DNS【1.1.1.1】"],
																			   ["13", "Quad9 Secured【9.9.9.11】"],
																			   ["14", "OpenDNS【208.67.222.222】"],
																			   ["15", "DNS.SB【185.222.222.222】"],
																			   ["16", "AdGuard【94.140.14.14】"],
																			   ["17", "Quad101【101.101.101.101】"],
																			   ["18", "CleanBrowsing【185.228.168.9】"],
																			   ["group", "自定义DNS"],
																			   ["99", "自定义DNS (udp)"],
																			  ];
														var option_dig = [
																		  ["group", "国内域名"],
																		  ["www.baidu.com", "www.baidu.com"],
																		  ["www.sina.com.cn", "www.sina.com.cn"],
																		  ["www.sohu.com", "www.sohu.com"],
																		  ["www.163.com", "www.163.com"],
																		  ["www.qq.com", "www.qq.com"],
																		  ["www.taobao.com", "www.taobao.com"],
																		  ["www.jd.com", "www.jd.com"],
																		  ["www.bilibili.com", "www.bilibili.com"],
																		  ["www.bing.com", "www.bing.com"],
																		  ["group", "国外域名"],
																		  ["www.google.com", "www.google.com"],
																		  ["www.google.com.hk", "www.google.com.hk"],
																		  ["www.youtube.com", "www.youtube.com"],
																		  ["www.facebook.com", "www.facebook.com"],
																		  ["www.twitter.com", "www.twitter.com"],
																		  ["www.wikipedia.org", "www.wikipedia.org"],
																		  ["www.instagram.com", "www.instagram.com"],
																		  ["www.netflix.com", "www.netflix.com"],
																		  ["www.reddit.com", "www.reddit.com"],
																		  ["www.github.com", "www.github.com"],
																		 ];
														var ph1 = "需端口号如：8.8.8.8:53"
														var ph2 = "需端口号如：8.8.8.8#53"
														var ph3 = "# 填入自定义的dnsmasq设置，一行一个&#10;# 例如hosts设置：&#10;address=/weibo.com/2.2.2.2&#10;# 防DNS劫持设置：&#10;bogus-nxdomain=220.250.64.18"
														$('#table_dns').forms([
															{ title: '<em>DNS方案设置</em>', thtd:1 , multi: [
																{ id:'ss_basic_olddns', name:'ss_basic_advdns', func:'u', hint:'26', type:'radio', suffix: '<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(136)"><font color="#ffcc00">基础</font></a>', value: 0},
																{ id:'ss_basic_advdns', name:'ss_basic_advdns', func:'u', hint:'26', type:'radio', suffix: '<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(137)"><font color="#ffcc00">进阶</font></a>', value: 1},
															]},
															{ title: '选择DNS主方案', class:'new_dns_main', multi: [
																{ id: 'ss_dns_plan', type:'select', func:'u', options:option_dnsp, style:'width:209px;', value:'1'},
															]},
															// new_dns: chinadns-ng
															{ title: '&nbsp;&nbsp;*选择中国DNS-1 <em>(直连) 🌏</em>', hint:'133', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_china_1_enable', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_china_1_prot', type:'select', func:'u', options:option_dnsngc_prot, style:'width:50px;', value:'1'},
																{ id: 'ss_basic_chng_china_1_udp', type:'select', func:'u', options:option_dnsngc_udp, style:'width:auto;', value:'1'},
																{ id: 'ss_basic_chng_china_1_udp_user', type: 'text', style:'width:120px;', ph:'114.114.114.114', value:'114.114.114.114' },
																{ id: 'ss_basic_chng_china_1_tcp', type:'select', func:'u', options:option_dnsngc_tcp, style:'width:200px;', value:'1'},
																{ id: 'ss_basic_chng_china_1_tcp_user', type: 'text', style:'width:120px;', ph:'114.114.114.114', value:'114.114.114.114' },
																{ id: 'ss_basic_chng_china_1_doh', type:'select', func:'u', options:option_dnsngc_doh, style:'width:200px;', value:'1'},																					//fancyss-full
																{ suffix:'&nbsp;&nbsp;'},
																{ suffix:'<a type="button" id="edit_smartdns_conf_10" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(10)">编辑smartdns配置</a>'},														//fancyss-full
																{ suffix:'<a type="button" id="edit_smartdns_conf_11" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(11)">编辑smartdns配置</a>'},														//fancyss-full
																{ suffix:'<a type="button" id="edit_smartdns_conf_12" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(12)">编辑smartdns配置</a>'},														//fancyss-full
																{ prefix: '<a id="ss_basic_chng_china_1_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(130)"><font color="#ffcc00">&nbsp;<u>ECS</u></font></a>', id: 'ss_basic_chng_china_1_ecs', type: 'checkbox', value:true },
																{ suffix: '<a type="button" id="dohclient_cache_manage_chn1" class="ss_btn" style="cursor:pointer" target="_blank" href="http://' + '<% nvram_get("lan_ipaddr"); %>' + ':2051">缓存管理</a>' },				//fancyss-full
															]},
															{ title: '&nbsp;&nbsp;*选择中国DNS-2 <em>(直连) 🌏</em>', hint:'133', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_china_2_enable', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_china_2_prot', type:'select', func:'u', options:option_dnsngc_prot, style:'width:50px;', value:'2'},
																{ id: 'ss_basic_chng_china_2_udp', type:'select', func:'u', options:option_dnsngc_udp, style:'width:200px;', value:'5'},
																{ id: 'ss_basic_chng_china_2_udp_user', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_2_tcp', type:'select', func:'u', options:option_dnsngc_tcp, style:'width:200px;', value:'5'},
																{ id: 'ss_basic_chng_china_2_tcp_user', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_2_doh', type:'select', func:'u', options:option_dnsngc_doh, style:'width:200px;', value:'1'},																					//fancyss-full
																{ suffix:'&nbsp;&nbsp;'},
																{ suffix:'<a type="button" id="edit_smartdns_conf_13" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(10)">编辑smartdns配置</a>'},														//fancyss-full
																{ suffix:'<a type="button" id="edit_smartdns_conf_14" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(11)">编辑smartdns配置</a>'},														//fancyss-full
																{ suffix:'<a type="button" id="edit_smartdns_conf_15" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(12)">编辑smartdns配置</a>'},														//fancyss-full
																{ prefix: '<a id="ss_basic_chng_china_2_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(130)"><font color="#ffcc00">&nbsp;<u>ECS</u></font></a>', id: 'ss_basic_chng_china_2_ecs', type: 'checkbox', value:true },
																{ suffix: '<a type="button" id="dohclient_cache_manage_chn2" class="ss_btn" style="cursor:pointer" target="_blank" href="http://' + '<% nvram_get("lan_ipaddr"); %>' + ':2052">缓存管理</a>' },				//fancyss-full
															]},
															{ title: '&nbsp;&nbsp;*选择可信DNS-1 <font color="#FF0066">(代理) 🚀</font>', hint:'134', class:'new_dns chng', rid:'dns_plan_foreign_1', multi: [
																{ id: 'ss_basic_chng_trust_1_enable', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_trust_1_opt', type:'select', func:'u', options:option_dnsngf_1_opt, style:'width:50px;', value:'2'},
																{ id: 'ss_basic_chng_trust_1_opt_udp_val', type:'select', func:'u', options:option_dnsngf_1_val_udp, style:'width:auto;', value:'1'},
																{ id: 'ss_basic_chng_trust_1_opt_udp_val_user', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_1_opt_tcp_val', type:'select', func:'u', options:option_dnsngf_1_val_tcp, style:'width:auto;', value:'1'},
																{ id: 'ss_basic_chng_trust_1_opt_tcp_val_user', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_1_opt_doh_val', type:'select', func:'u', options:option_dnsngf_1_val_doh, style:'width:auto;', value:'12'},																		//fancyss-full
																{ suffix: '&nbsp;&nbsp;'},
																{ prefix: '<a id="ss_basic_chng_trust_1_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(131)"><font color="#ffcc00">&nbsp;<u>ECS</u></font></a>', id: 'ss_basic_chng_trust_1_ecs', type: 'checkbox', value:true },
																{ suffix: '<a type="button" id="dohclient_cache_manage_frn1" class="ss_btn" style="cursor:pointer" target="_blank" href="http://' + '<% nvram_get("lan_ipaddr"); %>' + ':2055">缓存管理</a>' },				//fancyss-full
															]},
															{ title: '&nbsp;&nbsp;*选择可信DNS-2 <em>(直连) 🌏</em>', class:'new_dns chng', hint:'135', rid:'dns_plan_foreign_2', multi: [
																{ id: 'ss_basic_chng_trust_2_enable', type:'checkbox', func:'u', value:false},
																{ id: 'ss_basic_chng_trust_2_opt', type:'select', func:'u', options:option_dnsngf_2_opt, style:'width:50px;', value:'0'},
																{ id: 'ss_basic_chng_trust_2_opt_udp', type: 'text', style:'width:120px;', value:'208.67.222.222:5353', ph:ph2 },
																{ id: 'ss_basic_chng_trust_2_opt_tcp', type: 'text', style:'width:120px;', value:'208.67.222.222:5353', ph:ph2 },
																{ id: 'ss_basic_chng_trust_2_opt_doh', type:'select', func:'u', options:option_dnsngf_2_val, style:'width:auto;', value:'2'},																				//fancyss-full
																{ suffix: '&nbsp;&nbsp;'},
																{ suffix: '<a type="button" id="edit_smartdns_conf_30" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(30)">编辑smartdns配置</a>'},														//fancyss-full
																{ prefix: '<a id="ss_basic_chng_trust_2_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(132)"><font color="#ffcc00">&nbsp;<u>ECS</u></font></a>', id: 'ss_basic_chng_trust_2_ecs', type: 'checkbox', value:true },
																{ suffix: '<a type="button" id="dohclient_cache_manage_frn2" class="ss_btn" style="cursor:pointer" target="_blank" href="http://' + '<% nvram_get("lan_ipaddr"); %>' + ':2056">缓存管理</a>' },				//fancyss-full
																//{ suffix: '<span id="ss_basic_chng_direct_user_note"><br />⚠️直连情况下可能存在DNS污染，请自行解决！</span>'},
															]},	
															//{ title: '&nbsp;&nbsp;*丢弃AAAA记录（--no-ipv6）', class:'new_dns chng', id:'ss_basic_chng_no_ipv6', type:'checkbox', value:true},
															{ title: '&nbsp;&nbsp;*丢弃AAAA记录（--no-ipv6）', class:'new_dns chng', hint:'145', id:'ss_basic_chng_x', multi: [
																{ id:'ss_basic_chng_no_ipv6', type:'checkbox', func:'u', value: true},
																{ suffix: '<a id="ss_basic_chng_left">&nbsp;&nbsp;&nbsp;&nbsp;【</a>' },
																{ id:'ss_basic_chng_act', name:'ss_basic_chng_x', type:'radio', suffix: '<a id="ss_basic_chng_xact" class="hintstyle" href="javascript:void(0);" onclick="openssHint(145)"><font color="#ffcc00">act</font></a>&nbsp;&nbsp;', value: 0},
																{ id:'ss_basic_chng_gt', name:'ss_basic_chng_x', type:'radio', suffix: '<a id="ss_basic_chng_xgt" class="hintstyle" href="javascript:void(0);" onclick="openssHint(145)"><font color="#ffcc00">gt</font></a>&nbsp;&nbsp;', value: 1},
																{ id:'ss_basic_chng_mc', name:'ss_basic_chng_x', type:'radio', suffix: '<a id="ss_basic_chng_xmc" class="hintstyle" href="javascript:void(0);" onclick="openssHint(145)"><font color="#ffcc00">mt</font></a>', value: 0},
																{ suffix: '<a id="ss_basic_chng_right">&nbsp;&nbsp;】</a>' },
															]},
															
															{ title: '&nbsp;&nbsp;*发送重复DNS查询包（--repeat-times）', class:'new_dns chng', id:'ss_basic_chng_repeat_times', type:'text', value: '2'},
															// new_dns: smartdns
															{ title: '&nbsp;&nbsp;*选择smartdns配置', class:'new_dns smrt', multi: [																						//fancyss-full
																{ id: 'ss_basic_smrt', type:'select', func:'u', options:option_smrt, style:'width:260px;', value:'1'},														//fancyss-full
																{ suffix: '&nbsp;&nbsp;'},																																	//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_51" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(51)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_52" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(52)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_53" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(53)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_54" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(54)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_55" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(55)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_56" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(56)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_57" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(57)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_58" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(58)">编辑smartdns配置</a>'},		//fancyss-full
																{ suffix: '<a type="button" id="edit_smartdns_conf_59" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf(59)">编辑smartdns配置</a>'},		//fancyss-full
															]},																																								//fancyss-full
															// new_dns: dohclient
															{ title: '&nbsp;&nbsp;*选择国内DNS', class:'new_dns dohc', hint:'122', multi: [																																					//fancyss-full
																{ id: 'ss_basic_dohc_sel_china', type:'select', func:'u', options:option_protc_sel_chn, style:'width:50px;', value:'3'},																									//fancyss-full
																{ id: 'ss_basic_dohc_udp_china', type:'select', func:'u', options:option_dnsngc_udp, style:'width:190px;', value:'3'},																										//fancyss-full
																{ id: 'ss_basic_dohc_udp_china_user', type: 'text', style:'width:110px;', ph:'114.114.114.114' },																															//fancyss-full
																{ id: 'ss_basic_dohc_tcp_china', type:'select', func:'u', options:option_dohc_tcp_china, style:'width:190px;', value:'1'},																									//fancyss-full
																{ id: 'ss_basic_dohc_tcp_china_user', type: 'text', style:'width:110px;', ph:'114.114.114.114' },																															//fancyss-full
																{ id: 'ss_basic_dohc_doh_china', type:'select', func:'u', options:option_dohc_doh_china, style:'width:190px;', value:'1'},																									//fancyss-full
																{ prefix: '&nbsp;<a id="ss_basic_dhoc_chn_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(123)"><font color="#ffcc00"><u>ECS</u></font></a>', id: 'ss_basic_dohc_ecs_china', type: 'checkbox', value:true },						//fancyss-full
															]},																																																								//fancyss-full
															{ title: '&nbsp;&nbsp;*选择国外DNS', class:'new_dns dohc', hint:'124', multi: [																																					//fancyss-full
																{ id: 'ss_basic_dohc_sel_foreign', type:'select', func:'u', options:option_protc_sel_frn, style:'width:50px;', value:'3'},																									//fancyss-full
																{ id: 'ss_basic_dohc_tcp_foreign', type:'select', func:'u', options:option_dohc_tcp_foreign, style:'width:190px;', value:'3'},																								//fancyss-full
																{ id: 'ss_basic_dohc_tcp_foreign_user', type: 'text', style:'width:110px;', ph:'8.8.8.8' },																																	//fancyss-full
																{ id: 'ss_basic_dohc_doh_foreign', type:'select', func:'u', options:option_dohcf, style:'width:190px;', value:'12'},																											//fancyss-full
																{ prefix: '&nbsp;<a id="ss_basic_dhoc_frn_ecs_note" class="hintstyle" href="javascript:void(0);" onclick="openssHint(125)"><font color="#ffcc00"><u>ECS</u></font></a>', id: 'ss_basic_dohc_ecs_foreign', type: 'checkbox', value:true },					//fancyss-full
																{ prefix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(126)"><font color="#ffcc00"><u>Proxy</u></font></a>', id: 'ss_basic_dohc_proxy', type: 'checkbox', value:true },						//fancyss-full
															]},																																																								//fancyss-full
															{ title: '&nbsp;&nbsp;*缓存管理', class:'new_dns dohc', multi: [																																								//fancyss-full
																{ prefix: '&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(127)"><font color="#ffcc00"><u>缓存时长</u>：</font></a>' },																		//fancyss-full
																{ id: 'ss_basic_dohc_cache_timeout', type:'select', func:'u', options:option_cache_timeout, style:'width:100px;', value:'1'},																								//fancyss-full
																{ suffix: '&nbsp;&nbsp;<a type="button" id="dohclient_cache_manage_dohc" class="ss_btn" style="cursor:pointer" target="_blank" href="http://' + '<% nvram_get("lan_ipaddr"); %>' + ':7913">缓存管理</a>' },					//fancyss-full
																{ suffix: '&nbsp;&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="remove_doh_cache(1)">清空缓存</a>&nbsp;&nbsp;'},																						//fancyss-full
																{ prefix: '&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(128)"><font color="#ffcc00"><u>缓存持久化</u></font></a>', id: 'ss_basic_dohc_cache_reuse', type: 'checkbox', value:false },		//fancyss-full
															]},																																																								//fancyss-full
															// old_dns	
															{ title: '选择中国DNS', class:'old_dns', multi: [
																{ id: 'ss_china_dns', type:'select', func:'u', options:option_chndns, style:'width:auto;', value:'3'},
																{ id: 'ss_china_dns_user', type: 'text', ph:'114.114.114.114' }
															]},
															{ title: '选择外国DNS（🌏直连 | 🚀代理） ', class:'old_dns', hint:'26', rid:'dns_plan_foreign', multi: [
																{ id: 'ss_foreign_dns', type:'select', func:'u', options:option_dnsf, style:'width:auto;'},
																{ id: 'ss_dns2socks_user', type: 'text', style: 'width:auto;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_sstunnel_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },					//fancyss-full
																{ id: 'ss_direct_user', type: 'text', value:'8.8.8.8#53', ph:ph2 },
																{ prefix: '<span id="ss_sstunnel_user_note">&nbsp;&nbsp;仅SS/SSR模式下可用</span>'},	//fancyss-full
																{ suffix: '<span id="ss_disable_aaaa_note">丢弃AAAA记录</span>', id: 'ss_disable_aaaa', type: 'checkbox', value:true },
																{ suffix: '<span id="ss_doh_note">&nbsp;&nbsp;DNS over HTTPS (DoH)，<a href="https://cloudflare-dns.com/zh-Hans/" target="_blank"><em>cloudflare服务</em></a>，拒绝一切污染~</span>' },  //fancyss-full
																{ suffix: '<span id="ss_v2_note"></span>' },
															]},
															{ title: '<em>其它DNS相关设置</em>', th:'2'},
															{ title: 'DNS重定向', id:'ss_basic_dns_hijack', type:'checkbox', hint:'106', value:true},
															{ title: 'DNS解析测试', rid: 'ss_dns_test', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(1)">测试cdn</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(2)">测试apple china</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(3)">测试google china</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(4)">测试gfwlist</a>&nbsp;&nbsp;'},
																//{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(5)">测试cdn-china</a>&nbsp;&nbsp;'},
															]},
															{ title: 'DNS解析测试(dig)', rid: 'ss_dig_test', multi: [
																{ id: 'ss_basic_dig_opt', type:'select', func:'u', options:option_dig, style:'width:240px;', value:'1'},
																{ suffix: '&nbsp;&nbsp;' },
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(6)">dig</a>&nbsp;&nbsp;'},
															]},
															{ title: '重启dnsmasq', rid: 'ss_dnsmasq_restart', multi: [	
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="restart_dnsmaq()">重启dnsmasq</a>'},
															]},	
															// server dns resolver
															{ title: '节点域名解析DNS方案', hint:'107', multi: [
																{ id: 'ss_basic_server_resolv', type:'select', func:'u', options:option_resv, style:'width:160px;', value:'-1'},
																{ id: 'ss_basic_server_resolv_user', type: 'text', style:'width:145px;', ph:'176.103.130.130:5353', value:'176.103.130.130:5353'},
															]},
															{ title: '自定义dnsmasq', id:'ss_dnsmasq', type:'textarea', hint:'34', rows:'12', ph:ph3},
														]);
														var curr_host = window.location.hostname;												//fancyss-full
														$("#dohclient_cache_manage_chn1").attr("href", "http://" + curr_host + ":2051");		//fancyss-full
														$("#dohclient_cache_manage_chn2").attr("href", "http://" + curr_host + ":2052");		//fancyss-full
														$("#dohclient_cache_manage_frn1").attr("href", "http://" + curr_host + ":2055");		//fancyss-full
														$("#dohclient_cache_manage_frn2").attr("href", "http://" + curr_host + ":2056");		//fancyss-full
														$("#dohclient_cache_manage_dohc").attr("href", "http://" + curr_host + ":7913");		//fancyss-full
													</script>
												</table>
											</div>
											<div id="tablet_4" style="display: none;">
												<table id="table_wblist" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var ph1 = "# 填入不需要走代理的外网ip地址，一行一个，格式（IP/CIDR）如下&#10;2.2.2.2&#10;3.3.3.3&#10;4.4.4.4/24";
														var ph2 = "# 填入不需要走代理的域名，一行一个，格式如下：&#10;google.com&#10;facebook.com&#10;# 需要清空电脑DNS缓存，才能立即看到效果。";
														var ph3 = "# 填入需要强制走代理的外网ip地址，一行一个，格式（IP/CIDR）如下：&#10;5.5.5.5&#10;6.6.6.6&#10;7.7.7.7/8";
														var ph4 = "# 填入需要强制走代理的域名，一行一个，格式如下：&#10;baidu.com&#10;taobao.com&#10;# 需要清空电脑DNS缓存，才能立即看到效果。";
														$('#table_wblist').forms([
															{ title: 'IP/CIDR白名单<br><br><font color="#ffcc00">添加不需要走代理的外网ip地址</font>', id:'ss_wan_white_ip', type:'textarea', hint:'38', rows:'7', ph:ph1},
															{ title: '域名白名单<br><br><font color="#ffcc00">添加不需要走代理的域名</font>', id:'ss_wan_white_domain', type:'textarea', hint:'39', rows:'7', ph:ph2},
															{ title: 'IP/CIDR黑名单<br><br><font color="#ffcc00">添加需要强制走代理的外网ip地址</font>', id:'ss_wan_black_ip', type:'textarea', hint:'40', rows:'7', ph:ph3},
															{ title: '域名黑名单<br><br><font color="#ffcc00">添加需要强制走代理的域名</font>', id:'ss_wan_black_domain', type:'textarea', hint:'41', rows:'7', ph:ph4},
														]);
													</script>
												</table>
											</div>
											<!--fancyss_full_1-->
											<div id="tablet_5" style="display: none;">
												<table id="table_kcp" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var option_kcpm = [ "manual", "normal", "fast", "fast2", "fast3" ];
														var option_kcpe = [ "aes", "aes-128", "aes-192", "salsa20", "blowfish", "twofish", "cast5", "3des", "tea", "xtea", "xor", "none"];
														var ph1 = "请将速度模式为manual的参数和其它参数依次填写进来";
														var ph2 = "# 填入你的kcptun运行参数，每个参数用空格隔开，格式如下：&#10;--crypt salsa20 --key mjy211 --sndwnd 1024 --rcvwnd 1024 --mtu 1300 --nocomp --mode fast2";
														$('#table_kcp').forms([
															{ title: 'KCP加速开关', id:'ss_basic_use_kcp', type:'checkbox', func:'v', value:false},
															{ title: 'KCP参数配置方式', id:'ss_basic_kcp_method', type:'select', func:'v', options:[["1", "选择模式"], ["2", "输入模式"]], value:'2'},
															{ title: 'kcp本地监听地址：端口 （-l）', multi: [
																{ id: 'ss_basic_kcp_lserver', type: 'text', maxlen:'200', style:'width:120px;', attrib:'readonly', value:'0.0.0.0'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_kcp_lport', type: 'text', maxlen:'200', style:'width:44px;', attrib:'readonly', value:'1091'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(90)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: 'kcp服务器地址：端口 （-r）', multi: [
																{ id: 'ss_basic_kcp_server', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_kcp_port', type: 'text', maxlen:'200', style:'width:44px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(91)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '密码 (--key)', rid:'ss_basic_kcp_password_tr', id:'ss_basic_kcp_password', type:'password', maxlen:'200', peekaboo:'1'},
															{ title: '速度模式 (--mode)', rid:'ss_basic_kcp_mode_tr', id:'ss_basic_kcp_mode', type:'select', options:option_kcpm, value:'fast2'},
															{ title: '加密方式 (--crypt)', rid:'ss_basic_kcp_encrypt_tr', id:'ss_basic_kcp_encrypt', type:'select', options:option_kcpe, value:'aes-192'},
															{ title: 'MTU (--mtu)', rid:'ss_basic_kcp_mtu_tr', id:'ss_basic_kcp_mtu', type:'text', maxlen:'200'},
															{ title: '发送窗口 (--sndwnd)', rid:'ss_basic_kcp_sndwnd_tr', id:'ss_basic_kcp_sndwnd', type:'text', maxlen:'200'},
															{ title: '接收窗口 (--rcvwnd)', rid:'ss_basic_kcp_rcvwnd_tr', id:'ss_basic_kcp_rcvwnd', type:'text', maxlen:'200'},
															{ title: '链接数 (--conn)', rid:'ss_basic_kcp_conn_tr', id:'ss_basic_kcp_conn', type:'text', maxlen:'200'},
															{ title: '关闭数据压缩 (--nocomp)', rid:'ss_basic_kcp_nocomp_tr', id:'ss_basic_kcp_nocomp', type:'checkbox', value:false},
															{ title: '其它配置项', rid:'ss_basic_kcp_extra_tr', id:'ss_basic_kcp_extra', type:'text', maxlen:'200', style:'width:95%', ph:ph1},
															{ title: 'KCP参数', rid:'ss_basic_kcp_parameter_tr', id:'ss_basic_kcp_parameter', type:'textarea', rows:'4', ph:ph2},
														]);
													</script>
												</table>
											</div>
											<div id="tablet_6" style="display: none;">
												<table id="table_udp_main" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														$('#table_udp_main').forms([
															{ title: '加速节点选择', multi: [
																{ id: 'ss_basic_udp_node', type: 'select', options:[]},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(97)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '设置ss/ssr-redir MTU', multi: [
																{ id: 'ss_basic_udp_upstream_mtu', type: 'select', func:'u', options:[["0", "不设定"], ["1", "手动指定"]]},
																{ id: 'ss_basic_udp_upstream_mtu_value', type: 'text', value:'1200', style:'width:40px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(98)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '帮助信息', multi: [
																{ suffix: '<ul><li>你可以只开启UDPspeeder加速udp，或者只开启UDP2raw将udp转为tcp；</li>' },
																{ suffix: '<li>你也可以将UDPspeeder和UDP2raw都开启，并配置它们串联工作；</li><li>帮助文档：' },
																{ suffix: '<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.v1.md"><em><u>UDPspeederV1</u></em></a>&nbsp;&nbsp;' },
																{ suffix: '<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.md"><em><u>UDPspeederV2</u></em></a>&nbsp;&nbsp;' },
																{ suffix: '<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/README.zh-cn.md"><em><u>udp2raw-tunnel</u></em></a>' },
																{ suffix: '</li></ul>' },
															]},
															{ title: 'UDPspeeder运行状态', suffix: '<span id="udp_status">获取中...</span>'},
														]);
													</script>
												</table>
												<div id="sub_tablets">
													<table style="margin:10px 0px 0px 0px;border-collapse:collapse" width="100%" height="37px">
														<tr width="235px">
															<td colspan="4" cellpadding="0" cellspacing="0" style="padding:0" border="1" bordercolor="#000">
																<input id="sub_btn1" class="sub-btn1 active2" style="cursor:pointer" type="button" value="UDPspeeder" />
																<input id="sub_btn2" class="sub-btn2" style="cursor:pointer" type="button" value="UDP2raw-tunnel" />
															</td>
														</tr>
													</table>
												</div>
												<table id="table_udp" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														$('#table_udp').forms([
															//speeder
															{ title: '<em>UDPspeeder 设置</em>', th:'2', class:'speeder'},
															{ title: 'UDPspeeder开关', id:'ss_basic_udp_boost_enable', type:'checkbox', class:'speeder', value:false},
															{ title: 'UDPspeeder版本', class:'speeder', multi: [
																{ id: 'ss_basic_udp_software', type: 'select', func:'v', style:'width:132px', options:[["1", "UDPspeederV1"], ["2", "UDPspeederV2"]]},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(104)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															//speederv1
															{ title: '<em>UDPspeederV1 参数设置</em>', th:'2', class:'speederv1'},
															{ title: '* 本地监听地址：端口 （-l）', class:'speederv1', multi: [
																{ id: 'ss_basic_udpv1_lserver', type: 'text', maxlen:'200', style:'width:120px;', attrib:'readonly', value:'0.0.0.0'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udpv1_lport', type: 'text', maxlen:'200', style:'width:44px;', attrib:'readonly', value:'1092'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(99)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 服务器地址：端口 （-r）', class:'speederv1', multi: [
																{ id: 'ss_basic_udpv1_rserver', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udpv1_rport', type: 'text', maxlen:'200', style:'width:44px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(100)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 密码 (--key)', id:'ss_basic_udpv1_password', type:'password', maxlen:'200', class:'speederv1', style:'width:120px', peekaboo:'1'},
															{ title: '以下为包发送选项，两端设置可以不同, 只影响本地包发送。', th:'2', class:'speederv1'},
															{ title: '* 冗余包数量 （-d）', id:'ss_basic_udpv1_duplicate_nu', type:'text', style:'width:120px', class:'speederv1', maxlen:'200', suffix:'&nbsp;<a>默认0，留空则使用默认值。</a>'},
															{ title: '* 冗余包发送延迟 （-t）', id:'ss_basic_udpv1_duplicate_time', type:'text', style:'width:120px', class:'speederv1', maxlen:'200', suffix:'&nbsp;<a>默认值20（2ms），留空则使用默认值</a>'},
															{ title: '* 原始数据抖动延迟 （-j）', id:'ss_basic_udpv1_jitter', type:'text', style:'width:120px', class:'speederv1', maxlen:'200', suffix:'&nbsp;<a>默认0，留空则使用默认值</a>'},
															{ title: '* 数据发送和接受报告 （--report）', id:'ss_basic_udpv1_report', type:'text', style:'width:120px', class:'speederv1', maxlen:'200', suffix:'&nbsp;<a>单位：s，留空则不使用。</a>'},
															{ title: '* 随机丢包 （--random-drop）', id:'ss_basic_udpv1_drop', type:'text', style:'width:120px', class:'speederv1', maxlen:'200', suffix:'&nbsp;<a>单位：0.01%，留空则不使用。</a>'},
															{ title: '以下为包接收选项，两端设置可以不同，只影响本地包接受。', th:'2', class:'speederv1'},
															{ title: '* 关闭重复包过滤器 （--disable-filter）', id:'ss_basic_udpv1_disable_filter', type:'checkbox', class:'speederv1', value:false},
															//speederv2
															{ title: '<em>UDPspeederV2 参数设置</em>', th:'2', class:'speederv2'},
															{ title: '* 本地监听地址：端口 （-l）', class:'speederv2', multi: [
																{ id: 'ss_basic_udpv2_lserver', type: 'text', maxlen:'200', style:'width:120px;', attrib:'readonly', value:'0.0.0.0'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udpv2_lport', type: 'text', maxlen:'200', style:'width:44px;', attrib:'readonly', value:'1092'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(99)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 服务器地址：端口 （-r）', class:'speederv2', multi: [
																{ id: 'ss_basic_udpv2_rserver', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udpv2_rport', type: 'text', maxlen:'200', style:'width:44px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(100)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 密码 (--key)', id:'ss_basic_udpv2_password', type:'password', maxlen:'200', class:'speederv2', style:'width:120px', peekaboo:'1'},
															{ title: '以下为包发送选项，两端设置可以不同, 只影响本地包发送。', th:'2', class:'speederv2'},
															{ title: '* fec参数 （-f）', class:'speederv2', multi: [
																{ id: 'ss_basic_udpv2_fec', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;<a>必填，x:y，每x个包额外发送y个包。</a>' },
																{ suffix: '&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/wiki/%E4%BD%BF%E7%94%A8%E7%BB%8F%E9%AA%8C">fec使用经验</a>' },
															]},
															{ title: '* timeout参数 （--timeout）', id:'ss_basic_udpv2_timeout', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>单位：ms，默认8，留空则使用默认值。</a>'},
															{ title: '* mode参数 （--mode）', id:'ss_basic_udpv2_mode', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>默认0，留空则使用默认值。</a>'},
															{ title: '* 数据发送和接受报告 （--report）', id:'ss_basic_udpv2_report', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>单位：s，留空则不使用。</a>'},
															{ title: '* mtu参数 （--mtu）', id:'ss_basic_udpv2_mtu', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>默认1250，留空则使用默认值。</a>'},
															{ title: '* 原始数据抖动延迟 （-j,--jitter）', id:'ss_basic_udpv2_jitter', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>单位：ms，默认0，留空则使用默认值。</a>'},
															{ title: '* 时间窗口 （-i,--interval）', id:'ss_basic_udpv2_interval', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>单位：ms，默认0，留空则使用默认值。</a>'},
															{ title: '* 随机丢包 （--random-drop）', id:'ss_basic_udpv2_drop', type:'text', style:'width:120px', class:'speederv2', maxlen:'200', suffix:'&nbsp;<a>单位：0.01%，默认0，留空则使用默认值。</a>'},
															{ title: '以下服务器和客户端设置必须一致！', th:'2', class:'speederv2'},
															{ title: '* 关闭数据包随机填充（--disable-obscure）', id:'ss_basic_udpv2_disableobscure', type:'checkbox', class:'speederv2', value:false, suffix:'&nbsp;<a>关闭可节省一点带宽和cpu。</a>'},
															{ title: '* 关闭数据包验证（--disable-checksum）', id:'ss_basic_udpv2_disablechecksum', type:'checkbox', class:'speederv2', value:false, suffix:'&nbsp;<a>关闭可节省一点带宽和cpu。</a>'},
															{ title: '其它参数', th:'2', class:'speederv2'},
															{ title: '* 其它参数', id:'ss_basic_udpv2_other', type:'text', style:'width:95%', class:'speederv2', maxlen:'200', suffix:'<br />&nbsp;<a>其它高级参数，请手动输入，如 -q1 等。</a>'},
															//udp2raw
															{ title: '<em>UDP2raw 设置</em>', th:'2', class:'udp2raw'},
															{ title: 'UDP2raw开关', id:'ss_basic_udp2raw_boost_enable', type:'checkbox', class:'udp2raw', value:false},
															{ title: '<em>UDP2raw 参数设置</em>', th:'2', class:'udp2raw'},
															{ title: '* 本地监听地址：端口 （-l）', class:'udp2raw', multi: [
																{ id: 'ss_basic_udp2raw_lserver', type: 'text', maxlen:'200', style:'width:120px;', attrib:'readonly', value:'0.0.0.0'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udp2raw_lport', type: 'text', maxlen:'200', style:'width:44px;', attrib:'readonly', value:'1093'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(101)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 服务器地址：端口 （-r）', class:'udp2raw', multi: [
																{ id: 'ss_basic_udp2raw_rserver', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;:&nbsp;' },
																{ id: 'ss_basic_udp2raw_rport', type: 'text', maxlen:'200', style:'width:44px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(102)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 密码 (--key)', id:'ss_basic_udp2raw_password', type:'password', maxlen:'200', class:'udp2raw', style:'width:120px', peekaboo:'1'},
															{ title: '* 模式（--raw-mode）', id:'ss_basic_udp2raw_rawmode', type:'select', style:'width:132px', class:'udp2raw', options:["faketcp", "udp", "icmp"], value:'faketcp', suffix:'&nbsp;<a>默认:faketcp</a>'},
															{ title: '* 加密模式 （--cipher-mode）', id:'ss_basic_udp2raw_ciphermode', type:'select', style:'width:132px', class:'udp2raw', options:["aes128cbc", "aes128cfb", "xor", "none"], value:'aes128cbc', suffix:'&nbsp;<a>默认:aes128cbc</a>'},
															{ title: '* 校验模式 （--auth-mode）', id:'ss_basic_udp2raw_authmode', type:'select', style:'width:132px', class:'udp2raw', options:["md5", "hmac_sha1", "crc32", "icmp", "simple", "none"], value:'md5', suffix:'&nbsp;<a>默认:md5</a>'},
															{ title: '* 自动添加/删除iptables（-a,--auto-rule）', id:'ss_basic_udp2raw_a', type:'checkbox', class:'udp2raw', value:true, suffix:'<a>建议请勾选此选项</a>'},
															{ title: '* 定期检查iptables（--keep-rule）', id:'ss_basic_udp2raw_keeprule', type:'checkbox', class:'udp2raw', value:true, suffix:'<a>建议请勾选此选项</a>'},
															{ title: '* 绕过本地iptables（--lower-level）', class:'udp2raw', multi: [
																{ id: 'ss_basic_udp2raw_lowerlevel', type: 'text', maxlen:'200', style:'width:120px;'},
																{ suffix: '&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(103)"><font color="#ffcc00"><u>帮助</u></font></a>' },
															]},
															{ title: '* 其它参数', id:'ss_basic_udp2raw_other', type:'text', style:'width:95%', class:'udp2raw', maxlen:'200', suffix:'<br />&nbsp;<a>其它未列出来的参数，请手动输入，如 --force-sock-buf --seq-mode 1 等。</a>'},
														]);
													</script>
												</table>
											</div>
											<!--fancyss_full_2-->
											<div id="tablet_7" style="display: none;">
												<table id="table_rules" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
													<script type="text/javascript">
														var option_ruleu = [];
														for (var i = 0; i < 24; i++){
															var _tmp = [];
															_i = i < 10 ? String("0" + i) : String(i)
															_tmp[0] = i;
															_tmp[1] = _i + ":00时";
															option_ruleu.push(_tmp);
														}
														function addCommas(nStr) {
															nStr += '';
															var x = nStr.split('.');
															var x1 = x[0];
															var x2 = x.length > 1 ? '.' + x[1] : '';
															var rgx = /(\d+)(\d{3})/;
															while (rgx.test(x1)) {
															    x1 = x1.replace(rgx, '$1' + ',' + '$2');
															}
															return x1 + x2;
														}
														//var ipsn='<% nvram_get("chnroute_ips"); %>'
														var gfwl = addCommas('<% nvram_get("ipset_numbers"); %>');
														var chnl = addCommas('<% nvram_get("chnroute_numbers"); %>');
														var chnn = addCommas('<% nvram_get("chnroute_ips"); %>');
														var cdnn = addCommas('<% nvram_get("cdn_numbers"); %>');
														$('#table_rules').forms([
															{ title: 'gfwlist域名数量', multi: [
																{ suffix: '<em>'+ gfwl +'</em>&nbsp;条，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules/gfwlist.conf" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_ipset"); %></i></a>' },
															]},
															{ title: '大陆白名单IP段数量', multi: [
																{ suffix: '<em>'+ chnl +'</em>&nbsp;行，包含 <em>' + chnn + '</em>&nbsp;个ip地址，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules/chnroute.txt" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_chnroute"); %></i></a>' },
															]},
															{ title: '国内域名数量（cdn名单）', multi: [
																{ suffix: '<em>'+ cdnn +'</em>&nbsp;条，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules/cdn.txt" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_cdn"); %></i></a>' },
															]},
															{ title: '规则定时更新任务', hint:'44', multi: [
																{ id:'ss_basic_rule_update', type:'select', func:'u', style:'width:auto', options:[["0", "禁用"], ["1", "开启"]], value:'0'},
																{ id:'ss_basic_rule_update_time', type:'select', style:'width:auto', options:option_ruleu, value:'4'},
																{ suffix: '<a id="update_choose">' },
																{ suffix: '<input type="checkbox" id="ss_basic_gfwlist_update" title="选择此项应用gfwlist.conf自动更新">gfwlist' },
																{ suffix: '<input type="checkbox" id="ss_basic_chnroute_update" title="选择此项应用chnroute.txt自动更新">chnroute' },
																{ suffix: '<input type="checkbox" id="ss_basic_cdn_update" title="选择此项应用cdn.txt自动更新">cdn</a>' },
																{ suffix: '&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(1)">保存设置</a>' },
															]},
															{ title: '规则手动更新', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(2)">立即更新规则</a>'},
															]},
															{ title: '二进制更新', multi: [
																{ suffix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="v2ray_binary_update(2)">更新v2ray程序</a>&nbsp;'},//fancyss-full
																{ suffix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="xray_binary_update(2)">更新/切换xray程序</a>&nbsp;'},
																{ suffix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="ssrust_binary_update(2)">更新ss-rust程序</a>'},//fancyss-full
															]},
														]);
													</script>
												</table>
												<table id="table_subscribe" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var option_noded = [["7", "每天"], ["1", "周一"], ["2", "周二"], ["3", "周三"], ["4", "周四"], ["5", "周五"], ["6", "周六"], ["6", "周日"]];
														var option_hy2_tfo = [["0", "强制关闭"], ["1", "强制开启"], ["2", "根据订阅"]];							//fancyss-full
														var option_nodeh = [];
														for (var i = 0; i < 24; i++){
															var _tmp = [];
															_i = String(i)
															_tmp[0] = _i;
															_tmp[1] = _i + "点";
															option_nodeh.push(_tmp);
														}
														var ph1 = "此处填入你的机场订阅链接，通常是http://或https://开头的链接，多个链接可以分行填写！&#10;也可以增加非http开头的行作为注释，或使用空行或者符号线作为分割，订阅脚本仅会提取http://或https://开头的链接用以订阅，示例：&#10;-------------------------------------------------&#10;🚀xx机场 ssr&#10;https://abcd.airport.com/xxx&#10;&#10;🛩️yy机场 ss&#10;https://xyza.com/xxx&#10;-------------------------------------------------&#10;填写完成后点击下面的【保存并订阅】按钮开始订阅！";
														var ph2 = "多个关键词用英文逗号分隔，如：测试,过期,剩余,曼谷,M247,D01,硅谷";
														var ph3 = "多个关键词用英文逗号分隔，如：香港,深圳,NF,BGP";
														$('#table_subscribe').forms([
															{ title: '节点订阅设置', thead:'1'},
															{ title: '订阅地址管理<br><br><font color="#ffcc00">支持SS/SSR/V2ray/Xray/Trojan</font>', id:'ss_online_links', type:'textarea', hint:'116', rows:'12', ph:ph1},
															{ title: '订阅节点模式设定', id:'ssr_subscribe_mode', type:'select', style:'width:auto', options:option_modes, value:'2'},
															{ title: 'hysteria2订阅设置', multi: [																//fancyss-full
																{ suffix: '上行速度:' },																		//fancyss-full
																{ id: 'ss_basic_hy2_up_speed', type: 'text', maxlen:'200', style:'width:30px;', value:''},		//fancyss-full
																{ suffix: 'Mbps，&nbsp;&nbsp;' },																//fancyss-full
																{ suffix: '下行速度:' },																		//fancyss-full
																{ id: 'ss_basic_hy2_dl_speed', type: 'text', maxlen:'200', style:'width:30px;', value:''},		//fancyss-full
																{ suffix: 'Mbps，&nbsp;&nbsp;' },																//fancyss-full
																{ suffix: 'tcp fast open:' },																	//fancyss-full
																{ id:'ss_basic_hy2_tfo_switch', type:'select', style:'width:auto', options:option_hy2_tfo, value:'2'}, //fancyss-full
															]},																									//fancyss-full
															{ title: '下载订阅时走ss/ssr/v2ray/v2ray代理网络', id:'ss_basic_online_links_goss', type:'select', style:'width:auto', options:[["0", "不走代理"], ["1", "走代理"]], value:'0'},
															{ title: '订阅计划任务', multi: [
																{ id:'ss_basic_node_update', type:'select', style:'width:auto', func:'u', options:[["0", "禁用"], ["1", "开启"]], value:'0'},
																{ id:'ss_basic_node_update_day', type:'select', style:'width:auto', options:option_noded, value:'6'},
																{ id:'ss_basic_node_update_hr', type:'select', style:'width:auto', options:option_nodeh, value:'3'},
															]},
															{ title: '[排除]关键词（含关键词的节点不会添加）', rid:'ss_basic_exclude_tr', id:'ss_basic_exclude', type:'text', hint:'110', maxlen:'300', style:'width:95%', ph:ph2},
															{ title: '[包括]关键词（含关键词的节点才会添加）', rid:'ss_basic_include_tr', id:'ss_basic_include', type:'text', hint:'111', maxlen:'300', style:'width:95%', ph:ph3},
															{ title: '删除节点', rid: 'ss_basic_remove_node', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(0)">删除全部节点</a>'},
																{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(1)">删除全部订阅节点</a>'},
															]},
															{ title: '保存配置', rid: 'ss_sub_save_only', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(2)">仅保存设置</a>'},
															]},
															{ title: '节点订阅', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(3)">保存并订阅</a>'},
																{ prefix: '&nbsp;&nbsp;订阅高级设定', id: 'ss_adv_sub', type: 'checkbox', value:false, func:'v' },
															]}
														]);
													</script>
												</table>
												<table id="table_link" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var ph1 = "填入以ss://或者ssr://或者vmess://或者vless://开头的链接，多个链接请分行填写";
														$('#table_subscribe').forms([
															{ title: '通过ss/ssr/vmess/vless链接添加节点', thead:'1'},
															{ title: 'ss/ssr/vmess/vless链接', id:'ss_base64_links', type:'textarea', hint:117, rows:'11', ph:ph1},
															{ title: '操作', suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(4)">解析并保存为节点</a>'},
														]);
													</script>
												</table>
											</div>
											<div id="tablet_8" style="display: none;">
												<div id="ss_acl_table"></div>
												<div id="ACL_note" style="margin:10px 0 0 5px">
													<div><i>1&nbsp;&nbsp;默认状态下，所有局域网的主机都会走当前节点的模式（主模式），相当于即不启用局域网访问控制。</i></div>
													<div><i>2&nbsp;&nbsp;当你设置默认规则为不通过代理，添加了主机走大陆白名单模式，则只有添加的主机才会走代理(大陆白名单模式)。</i></div>
													<div><i>3&nbsp;&nbsp;当你设置默认规则为正在使用节点的模式，除了添加的主机才会走相应的模式，未添加的主机会走默认规则的模式。</i></div>
													<div><i>4&nbsp;&nbsp;如果为使用的节点配置了KCP协议，或者负载均衡，因为它们不支持udp，所以不能控制主机走游戏模式。</i></div>
													<div><i>5&nbsp;&nbsp;如果需要自定义端口范围，适用英文逗号和冒号，参考格式：80,443,5566:6677,7777:8888</i></div>
												</div>
											</div>
											<div id="tablet_9" style="display: none;">
												<table id="table_addons" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
													<script type="text/javascript">
														var title1 = "填写说明：&#13;此处填写1-23之间任意小时&#13;小时间用逗号间隔，如：&#13;当天的8点、10点、15点则填入：8,10,15"
														var option_rebc = [["0", "关闭"], ["1", "每天"], ["2", "每周"], ["3", "每月"], ["4", "每隔"], ["5", "自定义"]];
														var option_rebw = [["1", "一"], ["2", "二"], ["3", "三"], ["4", "四"], ["5", "五"], ["6", "六"], ["7", "日"]];
														var option_rebd = [];
														for (var i = 1; i < 32; i++){
															var _tmp = [];
															_i = String(i)
															_tmp[0] = _i;
															_tmp[1] = _i + "日";
															option_rebd.push(_tmp);
														}
														var option_rebim = ["1", "5", "10", "15", "20", "25", "30"];
														var option_rebih = [];
														for (var i = 1; i < 13; i++) option_rebih.push(String(i));
														var option_rebid = [];
														for (var i = 1; i < 31; i++) option_rebid.push(String(i));
														var option_rebip = [["1", "分钟"], ["2", "小时"], ["3", "天"]];
														var option_rebh = [];
														for (var i = 0; i < 24; i++){
															var _tmp = [];
															_i = String(i)
															_tmp[0] = _i;
															_tmp[1] = _i + "时";
															option_rebh.push(_tmp);
														}
														var option_rebm = [];
														for (var i = 0; i < 61; i++){
															var _tmp = [];
															_i = String(i)
															_tmp[0] = _i;
															_tmp[1] = _i + "分";
															option_rebm.push(_tmp);
														}
														var option_trit = [["0", "关闭"], ["2", "每隔2分钟"], ["5", "每隔5分钟"], ["10", "每隔10分钟"], ["15", "每隔15分钟"], ["20", "每隔20分钟"], ["25", "每隔25分钟"], ["30", "每隔30分钟"]];
														var pingm = [["1", "1次/节点"], ["2", "5次/节点"], ["3", "10次/节点"], ["4", "20次/节点"]];
														var weburl = ["developer.google.cn/generate_204", "connectivitycheck.gstatic.com/generate_204", "www.gstatic.com/generate_204"];
														$('#table_addons').forms([
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">备份/恢复</td></tr>'},
															{ title: '导出fancyss配置', hint:'24', multi: [
																{ suffix:'<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_route_file(1);" value="导出配置">'},
																{ suffix:'&nbsp;<input type="button" class="ss_btn" style="cursor:pointer;" onclick="remove_SS_node();" value="清空配置">'},
																{ suffix:'&nbsp;<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_route_file(2);" value="打包插件">'},
															]},
															{ title: '恢复fancyss配置', hint:'24', multi: [
																{ suffix:'<input style="color:#FFCC00;*color:#000;width: 200px;" id="ss_file" type="file" name="file"/>'},
																{ suffix:'<img id="loadingicon" style="margin-left:5px;margin-right:5px;display:none;" src="/images/InternetScan.gif"/>'},
																{ suffix:'<span id="ss_file_info" style="display:none;">完成</span>'},
																{ suffix:'<input type="button" class="ss_btn" style="cursor:pointer;" onclick="upload_ss_backup();" value="恢复配置"/>'},
															]},											
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">定时任务</td></tr>'},
															{ title: '插件定时重启设定', multi: [
																{ id:'ss_reboot_check', type:'select', style:'width:auto', func:'v', options:option_rebc, value:'0'},
																{ id:'ss_basic_week', type:'select', style:'width:auto', css:'re2', options:option_rebw, value:'1'},
																{ id:'ss_basic_day', type:'select', style:'width:auto', css:'re3', options:option_rebd, value:'1'},
																{ id:'ss_basic_inter_min', type:'select', style:'width:auto', css:'re4_1', options:option_rebim, value:'1'},
																{ id:'ss_basic_inter_hour', type:'select', style:'width:auto', css:'re4_2', options:option_rebih, value:'1'},
																{ id:'ss_basic_inter_day', type:'select', style:'width:auto', css:'re4_3', options:option_rebid, value:'1'},
																{ id:'ss_basic_inter_pre', type:'select', style:'width:auto', func:'v', css:'re4', options:option_rebip, value:'1'},
																{ id:'ss_basic_custom', type:'text', style:'width:150px', css:'re5', ph:'8,10,15', title:title1},
																{ suffix:'<span class="re5">&nbsp;小时</span>'},
																{ id:'ss_basic_time_hour', type:'select', style:'width:auto', css:'re1 re2 re3 re4_3', options:option_rebh, value:'0'},
																{ id:'ss_basic_time_min', type:'select', style:'width:auto', css:'re1 re2 re3 re4_3 re5', options:option_rebm, value:'0'},
																{ suffix:'&nbsp;<span class="re1 re2 re3 re4 re5">重启插件</span>'},
																{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(1)">保存设置</a>'},
															]},
															{ title: '插件触发重启设定', multi: [
																{ id:'ss_basic_tri_reboot_time', type:'select', style:'width:auto', hint:'109', func:'u', options:option_trit, value:'0'},
																{ suffix:'<span id="ss_basic_tri_reboot_time_note">&nbsp;解析服务器IP，如果发生变更，则重启插件！</span>'},
																{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(2)">保存设置</a>'},
															]},
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">节点列表</td></tr>'},
															{ title: '节点列表最大显示行数', id:'ss_basic_row', type:'select', func:'onchange="save_row();"', style:'width:auto', options:[]},
															{ title: '开启生成二维码功能', id:'ss_basic_qrcode', func:'v', type:'checkbox', value:true},
															{ title: '开启节点排序功能', id:'ss_basic_dragable', func:'v', type:'checkbox', value:true},
															{ title: '节点管理页面设为默认标签页', id:'ss_basic_tablet', func:'v', type:'checkbox', value:false},
															{ title: '节点管理页面隐藏服务器地址', id:'ss_basic_noserver', func:'v', type:'checkbox', value:false},
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">代理行为</td></tr>'},
															{ title: 'New Bing模式', id:'ss_basic_proxy_newb', hint:'149', type:'checkbox', value:true},
															{ title: 'udp代理控制', hint:'150', thtd:1 , multi: [
																{ id:'ss_basic_udpoff', name:'ss_basic_udp_proxy', func:'u', type:'radio', suffix: '<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(151)"><font color="#ffcc00">关闭</font></a>', value: 0},
																{ id:'ss_basic_udpall', name:'ss_basic_udp_proxy', func:'u', type:'radio', suffix: '<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(152)"><font color="#ffcc00">开启</font></a>', value: 1},
																{ id:'ss_basic_udpgpt', name:'ss_basic_udp_proxy', func:'u', type:'radio', suffix: '<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(153)"><font color="#ffcc00">仅chatgpt</font></a>', value: 2},
															]},
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">性能优化</td></tr>'},
															{ title: 'ss/ssr/trojan开启多核心支持', id:'ss_basic_mcore', hint:'108', type:'checkbox', value:true},								//fancyss-hnd
															{ title: 'ss/v2ray/xray开启tcp fast open', id:'ss_basic_tfo', type:'checkbox', value:false},										//fancyss-hnd
															{ title: 'ss协议开启TCP_NODELAY', id:'ss_basic_tnd', type:'checkbox', value:false},
															{ title: '用Xray核心运行V2ray节点', id:'ss_basic_vcore', hint:'114', type:'checkbox', value:false},									//fancyss-full
															{ title: '用Xray核心运行trojan节点', id:'ss_basic_tcore', hint:'119', type:'checkbox', value:false},								//fancyss-full
															{ title: 'Xray启用进程守护', id:'ss_basic_xguard', hint:'115', type:'checkbox', value:false},
															{ title: '用shadowsocks-rust替代shadowsocks-libev', hint:'118', multi: [															//fancyss-full
																{ id:'ss_basic_rust', type:'checkbox', value:false},																									//fancyss-full
																{ suffix: '&nbsp;&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="ssrust_binary_update(2)">下载 shadowsocks-rust 二进制</a>'}		//fancyss-full
															]}, 																																						//fancyss-full
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">其它</td></tr>'},
															{ title: '所有trojan节点强制允许不安全', id:'ss_basic_tjai', hint:'120', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过网络可用性检测', id:'ss_basic_nonetcheck', hint:'138', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过时间一致性检测', id:'ss_basic_notimecheck', hint:'139', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过国内DNS可用性检测', id:'ss_basic_nocdnscheck', hint:'140', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过可信DNS可用性检测', id:'ss_basic_nofdnscheck', hint:'141', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过国内出口ip检测', id:'ss_basic_nochnipcheck', hint:'142', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过代理出口ip检测', id:'ss_basic_nofrnipcheck', hint:'143', type:'checkbox', value:false},
															{ title: '插件开启时 - 跳过程序启动检测', id:'ss_basic_noruncheck', hint:'144', type:'checkbox', value:false},
														]);
													</script>
												</table>
											</div>
											<div id="tablet_10" style="display: none;">
												<div id="log_content" style="overflow:hidden;">
													<textarea cols="63" rows="36" wrap="on" readonly="readonly" id="log_content1" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
											</div>
											<div class="apply_gen" id="loading_icon">
												<img id="loadingIcon" style="display:none;" src="/images/InternetScan.gif">
											</div>
											<div id="apply_button" class="apply_gen">
												<input class="button_gen" type="button" onclick="save()" value="保存&应用">
												<input style="margin-left:10px" id="ss_failover_save" class="button_gen" onclick="save_failover()" type="button" value="保存本页设置">
											</div>
										</td>
									</tr>
								</table>
							</div>
						</td>
					</tr>
				</table>
			</td>
			<td width="10" align="center" valign="top"></td>
		</tr>
	</table>
	<div id="footer"></div>
</body>
</html>
