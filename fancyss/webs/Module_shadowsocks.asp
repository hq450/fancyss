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
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/layer/layer.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/table/table.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/ss-menu.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/dns_servers.json.js"></script>
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
var refreshRate;
var ph_v2ray = "# 填入v2ray json配置，内容可以是标准的也可以是压缩的&#10;# 此处的配置可以支持v2ray运行更多协议，比如ss/vless/socks等xray支持的协议&#10;# 请保证你json内的outbound/outbounds部分配置正确！！！"
var ph_xray = "# 填入xray json配置，内容可以是标准的也可以是压缩的&#10;# 此处的配置可以支持xray运行更多协议，比如ss/vmess/trojan/socks等xray支持的协议&#10;# 请保证你json内的outbound/outbounds部分配置正确！！！"
var ph_tuic = "# 填入tuic client json配置，内容可以是标准的也可以是压缩的&#10;# 请保证你json内的relay部分的配置正确！！！" 	//fancyss-full
var option_modes = [["1", "gfw黑名单模式"], ["2", "大陆白名单模式"], ["3", "游戏模式"], ["5", "全局代理模式"]];
var option_method = [ "none",  "rc4",  "rc4-md5",  "rc4-md5-6",  "aes-128-gcm",  "aes-192-gcm",  "aes-256-gcm",  "aes-128-cfb",  "aes-192-cfb",  "aes-256-cfb",  "aes-128-ctr",  "aes-192-ctr",  "aes-256-ctr",  "camellia-128-cfb",  "camellia-192-cfb",  "camellia-256-cfb",  "bf-cfb",  "cast5-cfb",  "idea-cfb",  "rc2-cfb",  "seed-cfb",  "salsa20",  "chacha20",  "chacha20-ietf",  "chacha20-ietf-poly1305",  "xchacha20-ietf-poly1305", "plain", "2022-blake3-aes-128-gcm", "2022-blake3-aes-256-gcm", "2022-blake3-chacha20-poly1305" ];
var option_protocals = [ "origin", "verify_simple", "verify_sha1", "auth_sha1", "auth_sha1_v2", "auth_sha1_v4", "auth_aes128_md5", "auth_aes128_sha1", "auth_chain_a", "auth_chain_b", "auth_chain_c", "auth_chain_d", "auth_chain_e", "auth_chain_f" ];
var option_obfs = ["plain", "http_simple", "http_post", "tls1.2_ticket_auth"];
var option_v2enc = [ ["auto", "自动[auto]"], ["none", "不加密[none]"], ["aes-128-cfb", "aes-128-cfb"], ["aes-128-gcm", "aes-128-gcm"], ["chacha20-poly1305", "chacha20-poly1305"], ["zero", "zero"]];
var option_headtcp = [["none", "不伪装"], ["http", "伪装http"]];
var option_headkcp = [["none", "不伪装"], ["srtp", "伪装视频通话(srtp)"], ["utp", "伪装BT下载(uTP)"], ["wechat-video", "伪装微信视频通话"], ["dtls", "dtls"], ["wireguard", "wireguard"]];
var option_headquic = [["none", "不伪装"], ["srtp", "伪装视频通话(srtp)"], ["utp", "伪装BT下载(uTP)"], ["wechat-video", "伪装微信视频通话"], ["dtls", "dtls"], ["wireguard", "wireguard"]];
var option_grpcmode = ["gun", "multi"];
var option_xhttpmode = ["auto", "packet-up", "stream-up", "stream-one"];
var option_bol = [["0", "false"], ["1", "true"]];
var option_xflow = [["", "none"], ["xtls-rprx-vision", "xtls-rprx-vision"], ["xtls-rprx-origin", "xtls-rprx-origin"], ["xtls-rprx-origin-udp443", "xtls-rprx-origin-udp443"], ["xtls-rprx-direct", "xtls-rprx-direct"], ["xtls-rprx-direct-udp443", "xtls-rprx-direct-udp443"], ["xtls-rprx-splice", "xtls-rprx-splice"], ["xtls-rprx-splice-udp443", "xtls-rprx-splice-udp443"]];
var option_fingerprint = ["chrome", "firefox", "safari", "ios", "android", "edge", "360", "qq", "random", "randomized", ""];
var option_naive_prot = ["https", "quic"];						//fancyss-full
var option_hy2_obfs = [["0", "停用"], ["1", "salamander"]];
var option_hy2_cg = ["reno", "bbr", "brutal", "force-brutal"];
var stop_scroll = 0;
var close_latency_flag = 0;
var stopFlag = 1;
const pattern=/[`~!@#$^&*()=|{}':;'\\\[\]\.<>\/?~！@#￥……&*（）——|{}%【】'；：""'。，、？\s]/g;
var time_wait;
var ws;
var ws_flag;
var wss_open;
var wss;
var hostname = document.domain;
var lan_ipaddr = '<% nvram_get("lan_ipaddr"); %>';
var mouse_status;
var ads_url_1
var ws_enable = 0;
var node_form_defaults = null;
var single_test_wait = {};
var single_test_running = false;
var single_test_node = null;
var batch_test_running = false;
if(PKG_ARCH == "hnd"){
	if(PKG_TYPE == "full"){
		var ws_enable = 1;
	}
}
if(PKG_ARCH == "mtk" || PKG_ARCH == "qca" || PKG_ARCH == "hnd_v8" || PKG_ARCH == "ipq64"){
	var ws_enable = 1;
}
String.prototype.myReplace = function(f, e){
	var reg = new RegExp(f, "g"); 
	return this.replace(reg, e); 
}
function init() {
	show_menu(menu_hook);
	get_dbus_data(function() {
		try_ws_connect();
	});
}
function try_ws_connect(){
	if (ws_enable != 1){
		ws_flag = 0;
		if (wss){
			try {
				wss.close();
			} catch (e) {}
			wss = null;
		}
		get_ss_status(false);
		return false;
	}
	if (window.location.protocol != "http:"){
		ws_flag = 0;
		if (wss){
			try {
				wss.close();
			} catch (e) {}
			wss = null;
		}
		get_ss_status(false);
		return false;
	}
	if (hostname != lan_ipaddr){
		ws_flag = 0;
		if (wss){
			try {
				wss.close();
			} catch (e) {}
			wss = null;
		}
		get_ss_status(false);
		return false;
	}
	wss = new WebSocket("ws://" + hostname + ":803/");
	var ws_test_done = false;
	var ws_test_timer = setTimeout(function() {
		if (ws_test_done){
			return;
		}
		ws_test_done = true;
		ws_flag = 3;
		wss_open = 0;
		try {
			wss.close();
		} catch (e) {}
		wss = null;
		get_ss_status(false);
	}, 1000);
	wss.onopen = function() {
		if (ws_test_done){
			return;
		}
		wss.send("echo ws_ok");
	};
	wss.onerror = function(event) {
		if (ws_test_done){
			return;
		}
		ws_test_done = true;
		clearTimeout(ws_test_timer);
		ws_flag = 2;
		wss_open = 0;
		//console.log('ws_test failed!');
		try {
			wss.close();
		} catch (e) {}
		wss = null;
		get_ss_status(false);
	};
	wss.onmessage = function(event) {
		if (ws_test_done){
			return;
		}
		ws_test_done = true;
		clearTimeout(ws_test_timer);
		ws_flag = 1;
		wss_open = 1;
		//console.log('ws_test message_ok!');
		get_ss_status(true);
	};
}
function refresh_dbss(cb) {
	return $.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		success: function(data) {
			db_ss = data.result[0];
			normalize_latency_val();
			generate_node_info();
			if (typeof cb === "function") {
				cb();
			}
		},
		error: function() {
			if (typeof cb === "function") {
				cb();
			}
		}
	});
}
function get_dbus_data(cb) {
	return $.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		cache: false,
		success: function(data) {
			db_ss = data.result[0];
			normalize_latency_val();
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
			// try to get latest version of fancyss
			version_show();
			message_show();
			if (!node_form_defaults) {
				capture_node_form_defaults();
			}
			if (typeof cb === "function") {
				cb(true);
			}
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			console.log(XmlHttpRequest.responseText);
			alert("skipd数据读取错误，请格式化jffs分区后重新尝试！");
			if (typeof cb === "function") {
				cb(false);
			}
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
	var params_tt_0 = ["ss_obfs", "v2ray_use_json", "v2ray_network_security_ai", "v2ray_mux_enable", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "xray_use_json", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_show", "hy2_ai", "hy2_tfo"];
	var params_tt_1 = ["type" ,"server", "mode", "port", "password", "method", "ss_obfs_host", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_json", "tuic_json", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_cg"];
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
	refresh_basic_input_width();
}
function refresh_options() {
	if (node_max == 0) return false;
	var option0 = $("#ssconf_basic_node");
	var option3 = $("#ss_failover_s4_3");
	
	option0.find('option').remove().end();
	option3.find('option').remove().end();

	for (var field in confs) {
		var c = confs[field];
		option3.append('<option value="' + field + '">' + c["name"] + '</option>');
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
				text: "【SS】" + group_tag + c.name
			}));
		}
		else if(c.type == "1"){
			//ssr
			option0.append($("<option>", {
				value: field,
				text: "【SSR】" + group_tag + c.name
			}));
		}
		else if(c.type == "3"){
			//vmess
			option0.append($("<option>", {
				value: field,
				text: c.use_json == "1" ? "【json】" + group_tag + c.name : "【Vmess】" + group_tag + c.name
			}));
		}
		else if(c.type == "4"){
			//vless
			option0.append($("<option>", {
				value: field,
				text: c.use_json == "1" ? "【json】" + group_tag + c.name : "【Vless】" + group_tag + c.name
			}));
		}
		else if(c.type == "5"){
			//trojan
			option0.append($("<option>", {
				value: field,
				text: "【Trojan】" + group_tag + c.name
			}));
		}
		else if(c.type == "6"){																								//fancyss-full							
			//naive
			option0.append($("<option>", {																					//fancyss-full
				value: field,																								//fancyss-full
				text: "【Naïve】" + group_tag + c.name																		//fancyss-full
			}));																											//fancyss-full
		}																													//fancyss-full
		else if(c.type == "7"){																								//fancyss-full
			//tuic																											//fancyss-full
			option0.append($("<option>", {																					//fancyss-full
				value: field,																								//fancyss-full
				text: "【Tuic】" + group_tag + c.name																		//fancyss-full
			}));																											//fancyss-full
		}																													//fancyss-full
		else if(c.type == "8"){
			//hysteria2
			option0.append($("<option>", {
				value: field,
				text: "【hysteria2】" + group_tag + c.name
			}));
		}
	}
	option0.val(db_ss["ssconf_basic_node"]||"1");
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
	E("ss_basic_row").value = db_ss["ss_basic_row"]||15;
}
function save() {
	var node_sel = E("ssconf_basic_node").value;
	submit_flag="1";
	dbus["ssconf_basic_node"] = node_sel;
	E("ss_state2").innerHTML = "国外连接 - " + "Waiting....";
	E("ss_state3").innerHTML = "国内连接 - " + "Waiting....";
	// key define
	var params_input = [
	  "ss_failover_s1",
	  "ss_failover_s2_1",
	  "ss_failover_s2_2",
	  "ss_failover_s3_1",
	  "ss_failover_s3_2",
	  "ss_failover_s4_1",
	  "ss_failover_s4_2",
	  "ss_failover_s4_3",
	  "ss_failover_s5",
	  "ss_basic_interval",
	  "ss_basic_row",
	  "ss_basic_dns_plan",
	  "ss_basic_chng_china_net_1_typ",
	  "ss_basic_chng_china_udp_1_opt",
	  "ss_basic_chng_china_udp_1_usr",
	  "ss_basic_chng_china_tcp_1_opt",
	  "ss_basic_chng_china_tcp_1_usr",
	  "ss_basic_chng_china_dot_1_opt",
	  "ss_basic_chng_china_dot_1_usr",
	  "ss_basic_chng_china_net_2_typ",
	  "ss_basic_chng_china_udp_2_opt",
	  "ss_basic_chng_china_udp_2_usr",
	  "ss_basic_chng_china_tcp_2_opt",
	  "ss_basic_chng_china_tcp_2_usr",
	  "ss_basic_chng_china_dot_2_opt",
	  "ss_basic_chng_china_dot_2_usr",
	  "ss_basic_chng_china_net_3_typ",
	  "ss_basic_chng_china_udp_3_opt",
	  "ss_basic_chng_china_udp_3_usr",
	  "ss_basic_chng_china_tcp_3_opt",
	  "ss_basic_chng_china_tcp_3_usr",
	  "ss_basic_chng_china_dot_3_opt",
	  "ss_basic_chng_china_dot_3_usr",
	  "ss_basic_chng_trust_net_1_typ",
	  "ss_basic_chng_trust_udp_1_opt",
	  "ss_basic_chng_trust_udp_1_usr",
	  "ss_basic_chng_trust_tcp_1_opt",
	  "ss_basic_chng_trust_tcp_1_usr",
	  "ss_basic_chng_trust_dot_1_opt",
	  "ss_basic_chng_trust_dot_1_usr",
	  "ss_basic_chng_trust_net_2_typ",
	  "ss_basic_chng_trust_udp_2_opt",
	  "ss_basic_chng_trust_udp_2_usr",
	  "ss_basic_chng_trust_tcp_2_opt",
	  "ss_basic_chng_trust_tcp_2_usr",
	  "ss_basic_chng_trust_dot_2_opt",
	  "ss_basic_chng_trust_dot_2_usr",
	  "ss_basic_chng_trust_net_3_typ",
	  "ss_basic_chng_trust_udp_3_opt",
	  "ss_basic_chng_trust_udp_3_usr",
	  "ss_basic_chng_trust_tcp_3_opt",
	  "ss_basic_chng_trust_tcp_3_usr",
	  "ss_basic_chng_trust_dot_3_opt",
	  "ss_basic_chng_trust_dot_3_usr",
	  //"ss_basic_chng_dns_query_times",
	  "ss_basic_chng",
	  "ss_basic_smrt",
	  "ss_basic_rule_update",
	  "ss_basic_rule_update_time",
	  "ssr_subscribe_mode",
	  "ss_basic_online_links_proxy",
	  "ss_basic_online_ua",
	  "ss_basic_node_update",
	  "ss_basic_node_update_day",
	  "ss_basic_node_update_hr",
	  "ss_basic_exclude",
	  "ss_basic_include",
	  "ss_acl_default_port",
	  "ss_acl_default_mode",
	  "ss_reboot_check",
	  "ss_basic_week",
	  "ss_basic_day",
	  "ss_basic_inter_min",
	  "ss_basic_inter_hour",
	  "ss_basic_inter_day",
	  "ss_basic_inter_pre",
	  "ss_basic_time_hour",
	  "ss_basic_time_min",
	  "ss_basic_tri_reboot_time",
	  "ss_basic_server_resolv",
	  "ss_basic_server_resolv_user",
	  "ss_basic_furl",
	  "ss_basic_curl",
	  "ss_basic_latency_batch",
	  "ss_basic_lt_cru_opts",
	  "ss_basic_lt_cru_time",
	  "ss_basic_hy2_up_speed",
	  "ss_basic_hy2_dl_speed",
	  "ss_basic_hy2_tfo_switch",
	  "ss_basic_hy2_cg_opt"
	];
	var params_check = [
	  "ss_failover_enable",
	  "ss_failover_c1",
	  "ss_failover_c2",
	  "ss_failover_c3",
	  "ss_adv_sub",
	  "ss_basic_tablet",
	  "ss_basic_noserver",
	  "ss_basic_dragable",
	  "ss_basic_qrcode",
	  "ss_basic_enable",
	  "ss_basic_gfwlist_update",
	  "ss_basic_tfo",
	  "ss_basic_nonetcheck",
	  "ss_basic_nochnipcheck",
	  "ss_basic_nofrnipcheck",
	  "ss_basic_noruncheck",
	  "ss_basic_chnroute_update",
	  "ss_basic_chnlist_update",
	  "ss_basic_add_ispdns",
	  "ss_basic_dns_hijack",
	  "ss_basic_mcore",
	  "ss_basic_chng_china_dns_1_chk",
	  "ss_basic_chng_china_dns_2_chk",
	  "ss_basic_chng_china_dns_3_chk",
	  "ss_basic_chng_trust_dns_1_chk",
	  "ss_basic_chng_trust_dns_2_chk",
	  "ss_basic_chng_trust_dns_3_chk",
	  "ss_basic_chng_ipv6_drop_direc",
	  "ss_basic_chng_ipv6_drop_proxy",
	  "ss_basic_block_resov",
	  "ss_basic_dns_serverx",
	  "ss_basic_proxy_newb",
	  //"ss_basic_proxy_ipv4",
	  //"ss_basic_proxy_ipv6"
	  "ss_basic_udpoff",
	  "ss_basic_udpall",
	  "ss_basic_block_quic",
	  "ss_acl_default_udp",
	  "ss_acl_default_quic",
	  "ss_basic_sub_ai"
	];
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
		if (E(params_check[i])) {
			dbus[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
		}
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
			dbus["ss_acl_udp_" + rowid] = E("ss_acl_udp_" + rowid).checked ? '1' : '0';
			dbus["ss_acl_quic_" + rowid] = E("ss_acl_quic_" + rowid).checked ? '1' : '0';
		}
	}
	// node data: write node data under using from the main pannel incase of data change
	dbus["ssconf_basic_mode_" + node_sel] = E("ss_basic_mode").value;
	// ss
	if (db_ss["ssconf_basic_type_" + node_sel] =="0" ){
		var params_ssi_1 = ["mode", "server", "port", "method", "ss_obfs_host"];
		var params_ssi_2 = ["ss_obfs"];
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
	}
	// ssr
	if (db_ss["ssconf_basic_type_" + node_sel] =="1" ){
		var params_sri_1 = ["mode", "server", "port", "method", "rss_obfs", "rss_protocol", "rss_obfs_param", "rss_protocol_param"];
		dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
		for (var i = 0; i < params_sri_1.length; i++) {
			dbus["ssconf_basic_" + params_sri_1[i] + "_" + node_sel] = E("ss_basic_" + params_sri_1[i]).value;
		}
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
			if(E("ss_basic_v2ray_network").value == "httpupgrade"){
				dbus["ssconf_basic_v2ray_network_host_" + node_sel] = E("ss_basic_v2ray_network_host").value;
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
			var params_xr_more = ["server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_network_security_sni", "xray_fingerprint", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http"];
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
			if(E("ss_basic_xray_network").value == "httpupgrade"){
				dbus["ssconf_basic_xray_network_host_" + node_sel] = E("ss_basic_xray_network_host").value;
				dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
			}
			if(E("ss_basic_xray_network").value == "xhttp"){
				dbus["ssconf_basic_xray_xhttp_mode_" + node_sel] = E("ss_basic_xray_xhttp_mode").value;
				dbus["ssconf_basic_xray_network_host_" + node_sel] = E("ss_basic_xray_network_host").value;
				dbus["ssconf_basic_xray_network_path_" + node_sel] = E("ss_basic_xray_network_path").value;
			}
			dbus["ssconf_basic_xray_network_security_" + node_sel] = E("ss_basic_xray_network_security").value;
			dbus["ssconf_basic_xray_network_security_sni_" + node_sel] = E("ss_basic_xray_network_security_sni").value;
			dbus["ssconf_basic_xray_pcs_" + node_sel] = E("ss_basic_xray_pcs").value;
			dbus["ssconf_basic_xray_vcn_" + node_sel] = E("ss_basic_xray_vcn").value;
			if(E("ss_basic_xray_network_security").value == "tls"){
				if(E("ss_basic_xray_network").value == "tcp"){
					dbus["ssconf_basic_xray_flow_" + node_sel] = E("ss_basic_xray_flow").value;
				}else{
					dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				}
				dbus["ssconf_basic_xray_network_security_ai_" + node_sel] = E("ss_basic_xray_network_security_ai").checked ? '1' : '';
				dbus["ssconf_basic_xray_network_security_alpn_h2_" + node_sel] = E("ss_basic_xray_network_security_alpn_h2").checked ? '1' : '';
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = E("ss_basic_xray_network_security_alpn_http").checked ? '1' : '';
				dbus["ssconf_basic_xray_fingerprint_" + node_sel] = E("ss_basic_xray_fingerprint").value;
			}else if(E("ss_basic_xray_network_security").value == "reality"){
				if(E("ss_basic_xray_network").value == "tcp"){
					dbus["ssconf_basic_xray_flow_" + node_sel] = E("ss_basic_xray_flow").value;
				}else{
					dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				}
				dbus["ssconf_basic_xray_show_" + node_sel] = E("ss_basic_xray_show").checked ? '1' : '';
				dbus["ssconf_basic_xray_fingerprint_" + node_sel] = E("ss_basic_xray_fingerprint").value;
				dbus["ssconf_basic_xray_publickey_" + node_sel] = E("ss_basic_xray_publickey").value;
				dbus["ssconf_basic_xray_shortid_" + node_sel] = E("ss_basic_xray_shortid").value;
				dbus["ssconf_basic_xray_spiderx_" + node_sel] = E("ss_basic_xray_spiderx").value;
			}else{
				dbus["ssconf_basic_xray_flow_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_ai_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_h2_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = "";
				dbus["ssconf_basic_xray_network_security_alpn_http_" + node_sel] = "";
			}
		}
	}
	// trojan
	if (db_ss["ssconf_basic_type_" + node_sel] =="5" ){
		var params_tj_1 = ["mode", "server", "port", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn"];
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
	// fancyss_full_2
	// hysteria2
	if (db_ss["ssconf_basic_type_" + node_sel] =="8" ){
		var params_hy2_1 = ["mode", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_cg"];
		for (var i = 0; i < params_hy2_1.length; i++) {
			dbus["ssconf_basic_" + params_hy2_1[i] + "_" + node_sel] = E("ss_basic_" + params_hy2_1[i]).value;
		}
		dbus["ssconf_basic_hy2_ai_" + node_sel] = E("ss_basic_hy2_ai").checked ? '1' : '';
		dbus["ssconf_basic_hy2_tfo_" + node_sel] = E("ss_basic_hy2_tfo").checked ? '1' : '';
	}
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
					if (flag != "1" && flag != "2"){
						showSSLoadingBar();
					}
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
					if(event.data == "XU6J03M6"){
						E("ok_button").style.display = "";
						count_down_close();
						ws.close();
					}else if(event.data == "fancyss"){
						ws.close();
						if (flag == "1"){
							refreshpage();
						}
					}else{
						E('log_content3').value += event.data + '\n';
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
function applyVisibility(container, ctx) {
	if (!ctx) return;
	var root = (typeof container == "string") ? document.querySelector(container) : container;
	if (!root) return;
	var rows = root.querySelectorAll("[data-show],[data-show-any],[data-show-not]");
	for (var i = 0; i < rows.length; i++) {
		var row = rows[i];
		var show = true;
		var showAll = row.dataset.show;
		var showAny = row.dataset.showAny;
		var showNot = row.dataset.showNot;
		if (showAll){
			var tokensAll = showAll.trim().split(/\s+/);
			for (var a = 0; a < tokensAll.length; a++) {
				if (!ctx[tokensAll[a]]){
					show = false;
					break;
				}
			}
		}
		if (show && showAny){
			var tokensAny = showAny.trim().split(/\s+/);
			var anyOk = false;
			for (var b = 0; b < tokensAny.length; b++) {
				if (ctx[tokensAny[b]]){
					anyOk = true;
					break;
				}
			}
			if (!anyOk) show = false;
		}
		if (show && showNot){
			var tokensNot = showNot.trim().split(/\s+/);
			for (var c = 0; c < tokensNot.length; c++) {
				if (ctx[tokensNot[c]]){
					show = false;
					break;
				}
			}
		}
		row.style.display = show ? "" : "none";
	}
}
function getFieldValue(id, def) {
	var el = E(id);
	return el ? el.value : (def || "");
}
function getFieldChecked(id) {
	var el = E(id);
	return el ? el.checked : false;
}
function getNodeCtx() {
	if (!save_flag) return null;
	var ctx = {};
	ctx.ss_on = (save_flag == "shadowsocks");
	ctx.ssr_on = (save_flag == "shadowsocksR");
	ctx.v2ray_on = (save_flag == "v2ray");
	ctx.xray_on = (save_flag == "xray");
	ctx.trojan_on = (save_flag == "trojan");
	ctx.naive_on = (save_flag == "naive");		//fancyss-full
	ctx.tuic_on = (save_flag == "tuic");		//fancyss-full
	ctx.hy2_on = (save_flag == "hysteria2");

	ctx.v_json_on = ctx.v2ray_on && getFieldChecked("ss_node_table_v2ray_use_json");
	ctx.v_json_off = ctx.v2ray_on && !getFieldChecked("ss_node_table_v2ray_use_json");
	var v_net = getFieldValue("ss_node_table_v2ray_network");
	var v_head_tcp = getFieldValue("ss_node_table_v2ray_headtype_tcp");
	ctx.v_net_tcp = v_net == "tcp";
	ctx.v_net_kcp = v_net == "kcp";
	ctx.v_net_quic = v_net == "quic";
	ctx.v_net_grpc = v_net == "grpc";
	ctx.v_grpc_on = ctx.v_net_grpc;
	ctx.v_host_on = v_net == "ws" || v_net == "h2" || v_net == "quic" || v_net == "httpupgrade" || (v_net == "tcp" && v_head_tcp == "http");
	ctx.v_path_on = v_net == "ws" || v_net == "h2" || v_net == "quic" || v_net == "grpc" || v_net == "httpupgrade" || (v_net == "tcp" && v_head_tcp == "http");
	ctx.v_tls_on = getFieldValue("ss_node_table_v2ray_network_security") == "tls";
	ctx.v_mux_on = getFieldChecked("ss_node_table_v2ray_mux_enable");

	ctx.x_json_on = ctx.xray_on && getFieldChecked("ss_node_table_xray_use_json");
	ctx.x_json_off = ctx.xray_on && !getFieldChecked("ss_node_table_xray_use_json");
	var x_net = getFieldValue("ss_node_table_xray_network");
	var x_head_tcp = getFieldValue("ss_node_table_xray_headtype_tcp");
	ctx.x_net_tcp = x_net == "tcp";
	ctx.x_net_kcp = x_net == "kcp";
	ctx.x_net_quic = x_net == "quic";
	ctx.x_net_grpc = x_net == "grpc";
	ctx.x_grpc_on = ctx.x_net_grpc;
	ctx.x_xhttp_on = x_net == "xhttp";
	ctx.x_host_on = x_net == "ws" || x_net == "h2" || x_net == "quic" || x_net == "httpupgrade" || x_net == "xhttp" || (x_net == "tcp" && x_head_tcp == "http");
	ctx.x_path_on = x_net == "ws" || x_net == "h2" || x_net == "quic" || x_net == "grpc" || x_net == "httpupgrade" || x_net == "xhttp" || (x_net == "tcp" && x_head_tcp == "http");
	ctx.x_tls_on = getFieldValue("ss_node_table_xray_network_security") == "tls";
	ctx.x_real_on = getFieldValue("ss_node_table_xray_network_security") == "reality";
	ctx.x_ai_off = !getFieldChecked("ss_node_table_xray_network_security_ai");
	ctx.x_flow_on = ctx.x_net_tcp && (ctx.x_tls_on || ctx.x_real_on);

	ctx.trojan_ai_off = !getFieldChecked("ss_node_table_trojan_ai");
	ctx.hy2_ai_off = !getFieldChecked("ss_node_table_hy2_ai");
	ctx.hy2_obfs_on = getFieldValue("ss_node_table_hy2_obfs") != "0";

	ctx.ss_obfs_allowed = ctx.ss_on && getFieldValue("ss_node_table_mode") != "3";
	ctx.ss_obfs_host_on = ctx.ss_obfs_allowed && getFieldValue("ss_node_table_ss_obfs") != "0";

	ctx.basic_server_on = ctx.ss_on || ctx.ssr_on || (ctx.v2ray_on && ctx.v_json_off) || (ctx.xray_on && ctx.x_json_off) || ctx.trojan_on;
	ctx.basic_pass_on = ctx.ss_on || ctx.ssr_on;
	return ctx;
}
function applyNodeVisibility() {
	var ctx = getNodeCtx();
	if (!ctx) return;
	applyVisibility("#table_add_nodes", ctx);
	var vPathRow = $('#ss_node_table_v2ray_network_path').closest('tr');
	if (vPathRow.length){
		if (ctx.v_grpc_on){
			vPathRow.find('th').html('* serviceName');
		}else{
			vPathRow.find('th').html('* 路径 (path)');
		}
	}
	var xPathRow = $('#ss_node_table_xray_network_path').closest('tr');
	if (xPathRow.length){
		if (ctx.x_grpc_on){
			xPathRow.find('th').html('* serviceName');
		}else{
			xPathRow.find('th').html('* 路径 (path)');
		}
	}
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
	var hy2_on = false;
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
		var hy2_on = false;
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
		var hy2_on = false;
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
		var hy2_on = false;
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
		var hy2_on = false;
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
	else if (node_type == "8") {
		var ss_on = false;
		var ssr_on = false;
		var v2ray_on = false;
		var xray_on = false;
		var trojan_on = false;
		var naive_on = false;	//fancyss-full
		var tuic_on = false;	//fancyss-full
		var hy2_on = true;
	}
	var v_json_on = E("ss_basic_v2ray_use_json").checked == true;
	var v_json_off = E("ss_basic_v2ray_use_json").checked == false;
	var v_http_on = E("ss_basic_v2ray_network").value == "tcp" && E("ss_basic_v2ray_headtype_tcp").value == "http";
	var v_host_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || E("ss_basic_v2ray_network").value == "quic" || E("ss_basic_v2ray_network").value == "httpupgrade" || v_http_on;
	var v_path_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || E("ss_basic_v2ray_network").value == "quic" || E("ss_basic_v2ray_network").value == "grpc" || E("ss_basic_v2ray_network").value == "httpupgrade" || v_http_on;
	var v_tls_on = E("ss_basic_v2ray_network_security").value == "tls";
	var v_grpc_on = E("ss_basic_v2ray_network").value == "grpc";
	var x_json_on = E("ss_basic_xray_use_json").checked == true;
	var x_json_off = E("ss_basic_xray_use_json").checked == false;
	var x_http_on = E("ss_basic_xray_network").value == "tcp" && E("ss_basic_xray_headtype_tcp").value == "http";
	var x_host_on = E("ss_basic_xray_network").value == "ws" || E("ss_basic_xray_network").value == "h2" || E("ss_basic_xray_network").value == "quic" || E("ss_basic_xray_network").value == "httpupgrade" || E("ss_basic_xray_network").value == "xhttp" || x_http_on;
	var x_path_on = E("ss_basic_xray_network").value == "ws" || E("ss_basic_xray_network").value == "h2" || E("ss_basic_xray_network").value == "quic" || E("ss_basic_xray_network").value == "grpc" || E("ss_basic_xray_network").value == "httpupgrade" || E("ss_basic_xray_network").value == "xhttp" || x_http_on;
	var x_tls_on = E("ss_basic_xray_network_security").value == "tls";
	var x_real_on = E("ss_basic_xray_network_security").value == "reality";
	var x_tcp_on = E("ss_basic_xray_network").value == "tcp";
	var x_grpc_on = E("ss_basic_xray_network").value == "grpc";
	var x_xhttp_on = E("ss_basic_xray_network").value == "xhttp";
	var x_ai_off = E("ss_basic_xray_network_security_ai").checked == false;
	var trojan_ai_off = E("ss_basic_trojan_ai").checked == false;
	var hy2_ai_off = E("ss_basic_hy2_ai").checked == false;
	var v_net = E("ss_basic_v2ray_network").value;
	var x_net = E("ss_basic_xray_network").value;
	var ctx = {
		ss_on: ss_on,
		ssr_on: ssr_on,
		v2ray_on: v2ray_on,
		xray_on: xray_on,
		trojan_on: trojan_on,
		naive_on: naive_on,  //fancyss-full
		tuic_on: tuic_on,    //fancyss-full
		hy2_on: hy2_on,
		basic_server_on: ss_on || ssr_on || (v2ray_on && v_json_off) || (xray_on && x_json_off) || trojan_on,
		basic_pass_on: ss_on || ssr_on,
		ss_obfs_host_on: ss_on && E("ss_basic_ss_obfs").value != "0",
		v_json_on: v_json_on,
		v_json_off: v_json_off,
		v_net_tcp: v_net == "tcp",
		v_net_kcp: v_net == "kcp",
		v_net_quic: v_net == "quic",
		v_net_grpc: v_net == "grpc",
		v_host_on: v_host_on,
		v_path_on: v_path_on,
		v_tls_on: v_tls_on,
		v_mux_on: E("ss_basic_v2ray_mux_enable").checked,
		x_json_on: x_json_on,
		x_json_off: x_json_off,
		x_net_tcp: x_net == "tcp",
		x_net_kcp: x_net == "kcp",
		x_net_quic: x_net == "quic",
		x_net_grpc: x_net == "grpc",
		x_host_on: x_host_on,
		x_path_on: x_path_on,
		x_tls_on: x_tls_on,
		x_real_on: x_real_on,
		x_ai_off: x_ai_off,
		x_flow_on: x_tcp_on && (x_tls_on || x_real_on),
		x_xhttp_on: x_xhttp_on,
		trojan_ai_off: trojan_ai_off,
		hy2_obfs_on: hy2_on && E("ss_basic_hy2_obfs").value != "0",
		hy2_ai_off: hy2_ai_off
	};
	applyVisibility("#table_basic", ctx);
	if(v_grpc_on){
		$("#ss_basic_v2ray_network_path_tr > th > a").html("* serviceName");
	}else{
		$("#ss_basic_v2ray_network_path_tr > th > a").html("* 路径 (path)");
	}
	if(x_grpc_on){
		$("#ss_basic_xray_network_path_tr > th > a").html("* serviceName");
	}else{
		$("#ss_basic_xray_network_path_tr > th > a").html("* 路径 (path)");
	}
	applyNodeVisibility();
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
		$("#ss_basic_hy2_up_speed").parent().parent().hide();
		$("#ss_basic_online_links_proxy").parent().parent().hide();
		$("#ss_basic_sub_ai").parent().parent().hide();
		$("#ss_basic_online_ua").parent().parent().hide();
		$("#ss_basic_node_update").parent().parent().hide();
		$("#ss_basic_exclude").parent().parent().hide();
		$("#ss_basic_include").parent().parent().hide();
		$("#ss_basic_remove_node").hide();
		$("#ss_sub_save_only").hide();
	}else{
		$("#ssr_subscribe_mode").parent().parent().show();
		$("#ss_basic_hy2_up_speed").parent().parent().show();
		$("#ss_basic_online_links_proxy").parent().parent().show();
		$("#ss_basic_sub_ai").parent().parent().show();
		$("#ss_basic_online_ua").parent().parent().show();
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
		if(ws_flag == 1){
			push_data_ws("ss_dummy.sh", "", dbus_post, "1");
		}else{
			push_data("dummy_script.sh", "", dbus_post, "1");
		}
	}
	if ( $(r).attr("id") == "ss_adv_sub" ) {
		var dbus_post = {};
		dbus_post["ss_adv_sub"] = E("ss_adv_sub").checked ? '1' : '0';
		if(ws_flag == 1){
			push_data_ws("ss_dummy.sh", "", dbus_post, "2");
		}else{
			push_data("dummy_script.sh", "", dbus_post, "2");
		}
	}
	refresh_acl_table();
}
function update_visibility() {
	var a  = E("ss_basic_rule_update").value == "1";
	var b  = E("ss_basic_node_update").value == "1";
	var d  = E("ss_basic_tri_reboot_time").value;
	var e = E("ss_basic_server_resolv").value;
	var f = E("ss_basic_dig_opt").value;

	showhide("ss_basic_rule_update_time", a);
	showhide("update_choose", a);
	showhide("ss_basic_node_update_day", b);
	showhide("ss_basic_node_update_hr", b);
	showhide("ss_basic_tri_reboot_time_note", (d != "0"));
	showhide("ss_basic_server_resolv_user", e == "99");
	showhide("ss_basic_dig_opt_usr", f == "99");

	// china-1
	var i  = E("ss_basic_chng_china_dns_1_chk").checked;
	var i0 = E("ss_basic_chng_china_net_1_typ").value;
	var i1 = E("ss_basic_chng_china_udp_1_opt").value;
	var i2 = E("ss_basic_chng_china_tcp_1_opt").value;
	var i3 = E("ss_basic_chng_china_dot_1_opt").value;
	showhide("ss_basic_chng_china_net_1_typ", i);
	showhide("ss_basic_chng_china_udp_1_opt", (i && i0 == "udp"));
	showhide("ss_basic_chng_china_udp_1_usr", (i && i0 == "udp" && i1 == "99"));
	showhide("ss_basic_chng_china_tcp_1_opt", (i && i0 == "tcp"));
	showhide("ss_basic_chng_china_tcp_1_usr", (i && i0 == "tcp" && i2 == "99"));
	showhide("ss_basic_chng_china_dot_1_opt", (i && i0 == "dot"));
	showhide("ss_basic_chng_china_dot_1_usr", (i && i0 == "dot" && i3 == "99"));
	
	// china-2
	var j  = E("ss_basic_chng_china_dns_2_chk").checked;
	var j0 = E("ss_basic_chng_china_net_2_typ").value;
	var j1 = E("ss_basic_chng_china_udp_2_opt").value;
	var j2 = E("ss_basic_chng_china_tcp_2_opt").value;
	var j3 = E("ss_basic_chng_china_dot_2_opt").value;
	showhide("ss_basic_chng_china_net_2_typ", j);
	showhide("ss_basic_chng_china_udp_2_opt", (j && j0 == "udp"));
	showhide("ss_basic_chng_china_udp_2_usr", (j && j0 == "udp" && j1 == "99"));
	showhide("ss_basic_chng_china_tcp_2_opt", (j && j0 == "tcp"));
	showhide("ss_basic_chng_china_tcp_2_usr", (j && j0 == "tcp" && j2 == "99"));
	showhide("ss_basic_chng_china_dot_2_opt", (j && j0 == "dot"));
	showhide("ss_basic_chng_china_dot_2_usr", (j && j0 == "dot" && j3 == "99"));
	
	// china-3
	var k  = E("ss_basic_chng_china_dns_3_chk").checked;
	var k0 = E("ss_basic_chng_china_net_3_typ").value;
	var k1 = E("ss_basic_chng_china_udp_3_opt").value;
	var k2 = E("ss_basic_chng_china_tcp_3_opt").value;
	var k3 = E("ss_basic_chng_china_dot_3_opt").value;
	showhide("ss_basic_chng_china_net_3_typ", k);
	showhide("ss_basic_chng_china_udp_3_opt", (k && k0 == "udp"));
	showhide("ss_basic_chng_china_udp_3_usr", (k && k0 == "udp" && k1 == "99"));
	showhide("ss_basic_chng_china_tcp_3_opt", (k && k0 == "tcp"));
	showhide("ss_basic_chng_china_tcp_3_usr", (k && k0 == "tcp" && k2 == "99"));
	showhide("ss_basic_chng_china_dot_3_opt", (k && k0 == "dot"));
	showhide("ss_basic_chng_china_dot_3_usr", (k && k0 == "dot" && k3 == "99"));

	// trust-1
	var l  = E("ss_basic_chng_trust_dns_1_chk").checked;
	var l0 = E("ss_basic_chng_trust_net_1_typ").value;
	var l1 = E("ss_basic_chng_trust_udp_1_opt").value;
	var l2 = E("ss_basic_chng_trust_tcp_1_opt").value;
	var l3 = E("ss_basic_chng_trust_dot_1_opt").value;
	showhide("ss_basic_chng_trust_net_1_typ", l);
	showhide("ss_basic_chng_trust_udp_1_opt", (l && l0 == "udp"));
	showhide("ss_basic_chng_trust_udp_1_usr", (l && l0 == "udp" && l1 == "99"));
	showhide("ss_basic_chng_trust_tcp_1_opt", (l && l0 == "tcp"));
	showhide("ss_basic_chng_trust_tcp_1_usr", (l && l0 == "tcp" && l2 == "99"));
	showhide("ss_basic_chng_trust_dot_1_opt", (l && l0 == "dot"));
	showhide("ss_basic_chng_trust_dot_1_usr", (l && l0 == "dot" && l3 == "99"));

	// trust-2
	var m  = E("ss_basic_chng_trust_dns_2_chk").checked;
	var m0 = E("ss_basic_chng_trust_net_2_typ").value;
	var m1 = E("ss_basic_chng_trust_udp_2_opt").value;
	var m2 = E("ss_basic_chng_trust_tcp_2_opt").value;
	var m3 = E("ss_basic_chng_trust_dot_2_opt").value;
	showhide("ss_basic_chng_trust_net_2_typ", m);
	showhide("ss_basic_chng_trust_udp_2_opt", (m && m0 == "udp"));
	showhide("ss_basic_chng_trust_udp_2_usr", (m && m0 == "udp" && m1 == "99"));
	showhide("ss_basic_chng_trust_tcp_2_opt", (m && m0 == "tcp"));
	showhide("ss_basic_chng_trust_tcp_2_usr", (m && m0 == "tcp" && m2 == "99"));
	showhide("ss_basic_chng_trust_dot_2_opt", (m && m0 == "dot"));
	showhide("ss_basic_chng_trust_dot_2_usr", (m && m0 == "dot" && m3 == "99"));

	// trust-3
	var n  = E("ss_basic_chng_trust_dns_3_chk").checked;
	var n0 = E("ss_basic_chng_trust_net_3_typ").value;
	var n1 = E("ss_basic_chng_trust_udp_3_opt").value;
	var n2 = E("ss_basic_chng_trust_tcp_3_opt").value;
	var n3 = E("ss_basic_chng_trust_dot_3_opt").value;
	showhide("ss_basic_chng_trust_net_3_typ", n);
	showhide("ss_basic_chng_trust_udp_3_opt", (n && n0 == "udp"));
	showhide("ss_basic_chng_trust_udp_3_usr", (n && n0 == "udp" && n1 == "99"));
	showhide("ss_basic_chng_trust_tcp_3_opt", (n && n0 == "tcp"));
	showhide("ss_basic_chng_trust_tcp_3_usr", (n && n0 == "tcp" && n2 == "99"));
	showhide("ss_basic_chng_trust_dot_3_opt", (n && n0 == "dot"));
	showhide("ss_basic_chng_trust_dot_3_usr", (n && n0 == "dot" && n3 == "99"));

	var t1 = E("ss_basic_lt_cru_opts").value == "1";
	var t2 = E("ss_basic_lt_cru_opts").value == "2";
	showhide("ss_basic_lt_cru_time", t1 || t2);

	if (E("ss_basic_dns_plan").value == "1"){
		$(".chng").show();
		$(".smrt").hide();							
	}else if(E("ss_basic_dns_plan").value == "2"){
		$(".chng").hide();
		$(".smrt").show();
		$(".dohc").hide();
	}else if(E("ss_basic_dns_plan").value == "3"){
		$(".chng").hide();
		$(".smrt").hide();
	}
	showhide("ss_dnsmasq_cus", E("ss_basic_dns_serverx").checked == false);
}

function Add_profile() { //点击节点页面内添加节点动作
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').show();
	reset_node_form();
	tabclickhandler(0); //默认显示添加ss节点
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
	reset_node_form();
}
function tabclickhandler(_type) {
	E('ssTitle').className = "vpnClientTitle_td_unclick";
	E('ssrTitle').className = "vpnClientTitle_td_unclick";
	E('vmessTitle').className = "vpnClientTitle_td_unclick";
	E('vlessTitle').className = "vpnClientTitle_td_unclick";
	E('trojanTitle').className = "vpnClientTitle_td_unclick";
	E('naiveTitle').className = "vpnClientTitle_td_unclick";	//fancyss-full
	E('tuicTitle').className = "vpnClientTitle_td_unclick";		//fancyss-full
	E('hy2Title').className = "vpnClientTitle_td_unclick";
	if (_type == 0) {
		save_flag = "shadowsocks";
		E('ssTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 1) {
		save_flag = "shadowsocksR";
		E('ssrTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 3) {
		save_flag = "v2ray";
		E('vmessTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 4) {
		save_flag = "xray";
		E('vlessTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 5) {
		save_flag = "trojan";
		E('trojanTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 6) {
		save_flag = "naive";
		E('naiveTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 7) {
		save_flag = "tuic";
		E('tuicTitle').className = "vpnClientTitle_td_click";
	} else if (_type == 8) {
		save_flag = "hysteria2";
		E('hy2Title').className = "vpnClientTitle_td_click";
	} else {
		save_flag = "shadowsocks";
		E('ssTitle').className = "vpnClientTitle_td_click";
	}
	applyNodeVisibility();
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
		var params1 = ["mode", "name", "server", "port", "method", "ss_obfs", "ss_obfs_host"]; //ss
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
		var params5_1 = ["mode", "name", "server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx"]; //for xray
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
		var params6 = ["mode", "name", "server", "port", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn"]; //trojan
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
	else if (flag == 'hysteria2') {
		var params8 = ["mode", "name", "hy2_server", "hy2_port", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_cg"];
		for (var i = 0; i < params8.length; i++) {
			ns[p + "_" + params8[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params8[i]).val());
		}
		ns[p + "_hy2_ai_" + node_max] = E("ss_node_table_hy2_ai").checked ? '1' : '';
		ns[p + "_hy2_tfo_" + node_max] = E("ss_node_table_hy2_tfo").checked ? '1' : '';
		ns[p + "_type_" + node_max] = "8";
	}
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
				E("ss_node_table_trojan_pcs").value = "";
				E("ss_node_table_trojan_vcn").value = "";
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
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "ss_obfs", "ss_obfs_host", "latency", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "xray_uuid", "xray_alterid", "xray_prot", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_show", "xray_json", "tuic_json", "xray_use_json", "type", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_ai", "hy2_tfo", "hy2_cg"];
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
			refresh_dbss(function() {
				reorder_trs();
				refresh_options();
			});
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
	var params1_input = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_cg"];
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
			console.log(params1_check[i])
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
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";
		$("#ssTitle").html("编辑ss节点");
		tabclickhandler(0);		
	}
	else if(c["type"] == "1"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "";
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";
		$("#ssrTitle").html("编辑SSR节点");
		tabclickhandler(1);		
	}
	else if(c["type"] == "3"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("vmessTitle").style.display = "";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";
		$("#vmessTitle").html("编辑V2Ray账号");
		tabclickhandler(3);
	}
	else if(c["type"] == "4"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";
		$("#vlessTitle").html("编辑Xray账号");
		tabclickhandler(4);
	}
	else if(c["type"] == "5"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "";
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";		//fancyss-full
		E("hy2Title").style.display = "none";
		$("#trojanTitle").html("编辑trojan账号");
		tabclickhandler(5);
	}
	//fancyss_naive_1
	else if(c["type"] == "6"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
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
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "none";
		E("naiveTitle").style.display = "none";
		E("tuicTitle").style.display = "";
		E("hy2Title").style.display = "none";
		$("#naiveTitle").html("编辑tuic账号");
		tabclickhandler(7);
	}
	//fancyss_tuic_2
	else if(c["type"] == "8"){
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "none";
		E("vmessTitle").style.display = "none";
		E("vlessTitle").style.display = "none";
		E("trojanTitle").style.display = "none";	//fancyss-full
		E("naiveTitle").style.display = "none";		//fancyss-full
		E("tuicTitle").style.display = "none";
		E("hy2Title").style.display = "";
		$("#hy2Title").html("编辑hysteria2账号");
		tabclickhandler(8);
	}
	show_add_node_panel();
	$("#cancel_Btn").css("margin-left", "10px");
	$('#add_fancyss_node_title').html("修改节点");
}
function edit_ss_node_conf(flag) {
	var ns = {};
	var p = "ssconf_basic";
	if (flag == 'shadowsocks') {
		var params1 = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host"];
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
		var params5_1 = ["mode", "name", "server", "port", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx"]; //for xray
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
		var params6 = ["mode", "name", "server", "port", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn"]; //trojan
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
	else if (flag == 'hysteria2') {
		var params8 = ["mode", "name", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_cg"];
		for (var i = 0; i < params8.length; i++) {
			ns[p + "_" + params8[i] + "_" + edit_id] = $.trim($('#ss_node_table' + "_" + params8[i]).val());
		}
		ns[p + "_hy2_ai_" + edit_id] = E("ss_node_table_hy2_ai").checked ? "1" : "";
		ns[p + "_hy2_tfo_" + edit_id] = E("ss_node_table_hy2_tfo").checked ? "1" : "";
		ns[p + "_type_" + edit_id] = "8";
	}
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
			E("ss_node_table_trojan_pcs").value = "";
			E("ss_node_table_trojan_vcn").value = "";
			E("ss_node_table_trojan_tfo").checked = false;
			E("ss_node_table_naive_prot").value = "https";	//fancyss-full
			E("ss_node_table_naive_server").value = "";		//fancyss-full
			E("ss_node_table_naive_port").value = "443";	//fancyss-full
			E("ss_node_table_naive_user").value = "";		//fancyss-full
			E("ss_node_table_naive_pass").value = "";		//fancyss-full
			E("ss_node_table_tuic_json").value = "";		//fancyss-full
			E("ss_node_table_hy2_server").value = "";
			E("ss_node_table_hy2_port").value = "";
			E("ss_node_table_hy2_pass").value = "";
			E("ss_node_table_hy2_tfo").value = "";
			E("ss_node_table_hy2_obfs").value = "0";
			E("ss_node_table_hy2_obfs_pass").value = "";
			E("ss_node_table_hy2_sni").value = "";
			E("ss_node_table_hy2_pcs").value = "";
			E("ss_node_table_hy2_vcn").value = "";
			E("ss_node_table_hy2_ai").checked = true;
			E("ss_node_table_hy2_cg").value = "brutal";
			// refresh panel
			refresh_node_panel();
		}
	});
	cancel_add_node();
}
function refresh_node_panel(cb) {
	return $.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		success: function(data) {
			db_ss = data.result[0];
			normalize_latency_val();
			ss_node_sel();
			if (typeof cb === "function") {
				cb();
			}
		},
		error: function() {
			if (typeof cb === "function") {
				cb();
			}
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
	// if (node_nu == 0 && poped == 0) pop_node_add();
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
		var params = ["group", "name", "port", "method", "password", "mode", "ss_obfs", "ss_obfs_host", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "xray_uuid", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx", "xray_show", "xray_json", "tuic_json", "xray_use_json", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_pass", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_ai", "hy2_tfo", "hy2_cg"];
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
		var params_sp = ["v2ray_mux_enable", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http"];
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
function refresh_table(cb) {
	return $.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		cache:false,
		success: function(data) {
			db_ss = data.result[0];
			normalize_latency_val();
			generate_node_info();
			refresh_options();
			refresh_html();
			if (typeof cb === "function") {
				cb();
			}
		},
		error: function() {
			if (typeof cb === "function") {
				cb();
			}
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
	if(node_nu && db_ss["ss_basic_latency_val"] != "0"){
		//开启延迟测试
		if(noserver == "1"){
			//关闭server
			var width = ["", "5%", "53%", "0%", "10%", "10%", "16%", ];
		}else{
			//开启server
			var width = ["", "5%", "27%", "28%", "10%", "10%", "16%", ];
		}
	}else{
		//关闭延迟测试
		if(noserver == "1"){
			//关闭server
			var width = ["", "5%", "63%", "0%", "16%", "0%", "16%" ];
		}else{
			//开启server
			var width = ["", "5%", "34%", "31%", "10%", "0%", "16%" ];
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
	if(node_nu && db_ss["ss_basic_latency_val"] != "0"){
		html += '<th style="width:' + width[5] + ';" id="depay_th">web落地延迟</th>'
	}
	html += '<th style="width:' + width[6] + ';">操作</th>'
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
			if(c["type"] == 8)
			{
				html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';
				html += '<div style="display: none;" class="shadow2"></div>';
				html += '<div class="server">' + c["hy2_server"] + '</div>';
				html += '</td>';
			}
			else if(c["type"] == 6)																					//fancyss-full
			{																										//fancyss-full
				html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';	//fancyss-full
				html += '<div style="display: none;" class="shadow2"></div>';										//fancyss-full
				html += '<div class="server">' + c["naive_server"] + '</div>';										//fancyss-full
				html += '</td>';																					//fancyss-full
			}																										//fancyss-full
			else
			{
				if(E("ss_basic_qrcode").checked){
					html += '<td style="width:' + width[3] + ';cursor:pointer" class="node_server" id="server_' + c["node"] + '" title="' + c["server"] + '" onclick="makeQRcode(this)">';
				}else{
					html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';
				}
				html += '<div style="display: none;" class="shadow2"></div>';
				html += '<div class="server">' + c["server"] + '</div>';
				html += '</td>';
			}
		}
		//节点类型
		html +='<td style="width:' + width[4] + ';">';

		switch(c["type"]) {
			case '0' :
				if(c["ss_obfs"] == "http" || c["ss_obfs"] == "tls"){
					html +='ss[obfs]';
				}else{
					html +='ss';
				}
				break;
			case '1' :
				html +='ssr';
				break;
			case '3' :
				if(c["protoc"]){
					html += c["protoc"];
				}else{
					html += 'vmess';
				}
				break;
			case '4' :
				if(c["protoc"]){
					html += c["protoc"];
				}else{
					html += c["xray_prot"];
				}
				break;
			case '5' :
				html +='trojan';
				break;
			case '6' :														//fancyss-full
				html +='Naïve';												//fancyss-full
				break;														//fancyss-full
			case '7' :														//fancyss-full
				html +='tuic';												//fancyss-full
				break;														//fancyss-full
			case '8' :
				html +='hy2';
				break;
		}
		
		html +='</td>';
		//webtest
		if(node_nu && db_ss["ss_basic_latency_val"] != "0"){
			html += '<td style="width:' + width[5] + ';overflow:hidden;text-overflow:clip;" id="ss_node_lt_' + c["node"] + '" class="latency"><span class="latency_val"></span></td>';
		}
		//节点操作
		html += '<td style="width:' + width[6] + ';white-space:nowrap;">'
		if(node_nu && db_ss["ss_basic_latency_val"] != "0"){
			html += '<img src="/res/speed.png" class="latency_btn" data-node="' + c["node"] + '" style="width:22px;height:22px;cursor:pointer;vertical-align:middle;margin:-2px 0px 0px 0px;" title="点击后将测试此节点的web落地延迟！" onmouseover="this.src=\'/res/speed_blue.png\';" onmouseout="this.src=\'/res/speed.png\';" onclick="test_latency_single(' + c["node"] + ');return false;" />'
		}
		html += '<input style="margin:-2px 0px -4px -2px;" id="dd_node_' + c["node"] + '" class="edit_btn" type="button" onclick="edit_conf_table(this);" value="">'
		html += '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="remove_conf_table(this);" value="">'
		html += '<div class="deactivate_icon" style="display:inline-block;vertical-align:middle;margin:-2px 0px 0px -2px;width:26px;height:26px;" id="apply_ss_node_' + c["node"] + '" onclick="apply_this_ss_node(this);"></div>';
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
		if(db_ss["ss_basic_latency_batch"] == "1"){
			html += '<a onclick="test_latency_now(2)" href="javascript:void(0);"></lable>开始 web 延迟测试<lable id="ss_wts_show"></lable></a>'
		}else{
			html += '<a href="javascript:void(0);" style="color:#999;cursor:not-allowed"></lable>批量测速已关闭</a>'
		}
		if(db_ss["ss_basic_latency_val"] == "0"){
			html += '<a onclick="enable_latency_feature()" href="javascript:void(0);"></lable>开启延迟测试功能</a>'
		}else{
			html += '<a onclick="test_latency_now(0)" href="javascript:void(0);"></lable>关闭延迟测试功能</a>'
		}
		html += '<a onclick="clear_latency_cache()" href="javascript:void(0);"></lable>清空延迟测试结果</a>'
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
	// load cached webtest results if available
	if(node_nu && db_ss["ss_basic_latency_val"] != "0"){
		load_latency_cache();
	}
	if(node_max != 0 && node_max != node_nu ){
		console.log("自动调整顺序！")
		save_new_order();
		//ss_node_sel();
	}
	// ask or not ask for webtest
	if(db_ss["ss_basic_latency_val"]){
		latency_test(db_ss["ss_basic_latency_val"]);
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
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "ss_obfs", "ss_obfs_host", "latency", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_kcp_seed", "v2ray_headtype_quic", "v2ray_grpc_mode", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_network_security_ai", "v2ray_network_security_alpn_h2", "v2ray_network_security_alpn_http", "v2ray_network_security_sni", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "xray_uuid", "xray_alterid", "xray_prot", "xray_encryption", "xray_flow", "xray_network", "xray_headtype_tcp", "xray_headtype_kcp", "xray_headtype_quic", "xray_grpc_mode", "xray_xhttp_mode", "xray_network_path", "xray_network_host", "xray_network_security", "xray_network_security_ai", "xray_network_security_alpn_h2", "xray_network_security_alpn_http", "xray_network_security_sni", "xray_pcs", "xray_vcn", "xray_fingerprint", "xray_publickey", "xray_shortid", "xray_spiderx","xray_show", "xray_json", "tuic_json", "xray_use_json", "type", "trojan_ai", "trojan_uuid", "trojan_sni", "trojan_pcs", "trojan_vcn", "trojan_tfo", "naive_prot", "naive_server", "naive_port", "naive_user", "naive_pass", "hy2_server", "hy2_port", "hy2_up", "hy2_dl", "hy2_obfs", "hy2_obfs_pass", "hy2_pass", "hy2_sni", "hy2_pcs", "hy2_vcn", "hy2_ai", "hy2_tfo", "hy2_cg"];
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
			refresh_dbss(function() {
				reorder_trs();
				refresh_options();
				getNowFormatDate();
				ss_node_sel();
			});
		}
	});
}
function reorder_trs(){
	var trs = $("#ss_node_list_table tr");
	var noserver = parseInt(E("ss_basic_noserver").checked ? "1":"0");
	var has_latency = node_nu && db_ss["ss_basic_latency_val"] != "0";
	var idx_order = 1;
	var idx_name = 2;
	var idx_server = (noserver != "1") ? 3 : 0;
	var idx_type = (noserver != "1") ? 4 : 3;
	var idx_latency = has_latency ? ((noserver != "1") ? 5 : 4) : 0;
	var idx_ops = has_latency ? ((noserver != "1") ? 6 : 5) : ((noserver != "1") ? 5 : 4);
	for (var i = 0; i < trs.length; i++) {
		// 改写显示的顺序
		var new_nu = i + 1;
		//tr
		var row_sel = '#ss_node_list_table tr:nth-child(' + new_nu + ')';
		var $row = $(row_sel);
		$row.attr("id", "node_" + new_nu);
		//$('#ss_node_list_table tr:nth-child(' + new_nu + ')').removeAttr("class");
		//$('#ss_node_list_table tr:nth-child(' + new_nu + ')').removeAttr("style");
		//序号
		$row.find('td:nth-child(' + idx_order + ')').attr("id", "node_order_" + new_nu);
		$row.find('td:nth-child(' + idx_order + ')').html(String(new_nu));
		//节点名称
		$row.find('td:nth-child(' + idx_name + ')').attr("id", "ss_node_name_" + new_nu);
		//服务器地址
		if(idx_server){
			$row.find('td:nth-child(' + idx_server + ')').attr("id", "server_" + new_nu);
		}
		//类型
		$row.find('td:nth-child(' + idx_type + ')').attr("id", "server_" + new_nu);
		if(idx_latency){
			$row.find('td:nth-child(' + idx_latency + ')').attr("id", "ss_node_lt_" + new_nu);
		}
		var $ops = $row.find('td:nth-child(' + idx_ops + ')');
		$ops.find('input.edit_btn').attr("id", "dd_node_" + new_nu);
		$ops.find('input.remove_btn').attr("id", "td_node_" + new_nu);
		$ops.find('div.activate_icon, div.deactivate_icon').attr("id", "apply_ss_node_" + new_nu);
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
		if(c["ss_obfs"] == "1"){
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"])) + "@" + c["server"] + ":" + c["port"] + "/?plugin=obfs-local%3Bobfs%3D" + c["ss_obfs"] + "%3Bobfs-host%3D" + c["ss_obfs_host"] + "#" + c["name"];
		}else{
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"]) + "@" + c["server"] + ":" + c["port"] + "#" + c["name"]);
		}
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
	dbus_post["ss_basic_furl"] = E("ss_basic_furl").value;
	dbus_post["ss_basic_curl"] = E("ss_basic_curl").value;
	dbus_post["ss_basic_latency_batch"] = E("ss_basic_latency_batch").value;
	dbus_post["ss_basic_lt_cru_opts"] = E("ss_basic_lt_cru_opts").value;
	dbus_post["ss_basic_lt_cru_time"] = E("ss_basic_lt_cru_time").value;
	var post_dbus = compfilter(db_ss, dbus_post);
	if(isObjectEmpty(post_dbus) == false){
		if(post_dbus.hasOwnProperty("ss_basic_furl")){
			post_para += 1;
		}
		if(post_dbus.hasOwnProperty("ss_basic_curl")){
			post_para += 2;
		}
		//console.log(post_para);
		//console.log(post_dbus);
		//now post
		var id = parseInt(Math.random() * 100000000);
		var postData = {"id": id, "method": "ss_webtest.sh", "params":[post_para], "fields": post_dbus};
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
	if(test_flag == 2 && db_ss["ss_basic_latency_batch"] != "1"){
		layer.msg("批量测速已关闭");
		return;
	}
	var dbus_post = {};
	dbus_post["ss_basic_latency_val"] = String(test_flag);
	if(test_flag == 0){
		var post_para = "close_latency_test";
	}else if(test_flag == 2){
		var post_para = "manual_webtest";
	}
	//now post
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_webtest.sh", "params":[post_para], "fields": dbus_post};
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
					batch_test_running = false;
					$("#ss_wts_show").html("");
					$("#dropdown").width(150);
				}
				if(test_flag == "2"){
					$(".latency .latency_val").html("waiting...");
					batch_test_running = true;
				}
			}
		}
	});
}
function clear_latency_cache() {
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_webtest.sh", "params":["clear_webtest"], "fields": {}};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == "busy"){
				layer.msg("正在测速，请稍后重试");
				return;
			}
			if (response.result == id){
				$(".latency .latency_val").html("");
				$("#ss_wts_show").html("");
				$("#dropdown").width(150);
			}
		}
	});
}
function enable_latency_feature() {
	var dbus_post = {};
	dbus_post["ss_basic_latency_val"] = "2";
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_webtest.sh", "params":["0"], "fields": dbus_post};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if (response.result == id){
				close_latency_flag = 0;
				refresh_table();
			}
		}
	});
}
function normalize_latency_val(){
	if(db_ss["ss_basic_latency_val"] === undefined || db_ss["ss_basic_latency_val"] === null || db_ss["ss_basic_latency_val"] === ""){
		db_ss["ss_basic_latency_val"] = "0";
	}
}
function test_latency_single(node){
	if(!node) return;
	if(batch_test_running){
		check_batch_status(function(done){
			if(done){
				test_latency_single(node);
			}else{
				layer.msg("批量测速中，无法进行单节点测速");
			}
		});
		return;
	}
	if(single_test_running){
		if(String(single_test_node) != String(node)){
			layer.msg("请等待当前测试完成");
			return;
		}else{
			return;
		}
	}
	var cell = $("#ss_node_lt_" + node + " .latency_val");
	if(cell.length){
		cell.html("testing...");
	}
	single_test_wait[node] = true;
	single_test_running = true;
	single_test_node = node;
	disable_latency_buttons(node);
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_webtest.sh", "params":["single_test", String(node)], "fields": {}};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == "busy"){
				if(cell.length){
					cell.html("busy");
				}
				layer.msg("正在批量测速，请稍后重试");
				single_test_running = false;
				single_test_node = null;
				enable_latency_buttons();
				return;
			}
			if (response.result == id){
				setTimeout(function() { get_latency_data_single(node, 0); }, 300);
			}else{
				single_test_running = false;
				single_test_node = null;
				enable_latency_buttons();
			}
		},
		error: function() {
			single_test_running = false;
			single_test_node = null;
			enable_latency_buttons();
		}
	});
}

function check_batch_status(cb){
	$.ajax({
		url: '/_temp/webtest.txt',
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			if(res && res.indexOf("stop>") !== -1){
				batch_test_running = false;
				if(typeof cb === "function"){ cb(true); }
			}else{
				if(typeof cb === "function"){ cb(false); }
			}
		},
		error: function(){
			if(typeof cb === "function"){ cb(false); }
		}
	});
}
function latency_test(action) {
	if(action == "0") return;
	if(db_ss["ss_basic_latency_batch"] != "1") return;
	//console.log("start latency test")
	
	if(action == "2"){
		var bash_para = "web_webtest";
		batch_test_running = true;
	}
	//now post
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_webtest.sh", "params":[bash_para], "fields": ""};
	$.ajax({
		type: "POST",
		async: true,
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			//console.log(response.result)
			$(".latency .latency_val").html("waiting...");
			get_latency_data(action);
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			$(".latency .latency_val").html("失败!");
			batch_test_running = false;
		},
		timeout: 60000
	});
}
function get_latency_data_single(node, retry){
	if(retry > 40){
		var cell = $("#ss_node_lt_" + node + " .latency_val");
		if(cell.length){
			cell.html("timeout");
		}
		single_test_wait[node] = false;
		single_test_running = false;
		single_test_node = null;
		enable_latency_buttons();
		return;
	}
	var URL = '/_temp/webtest.txt'
	$.ajax({
		url: URL,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			const lines = res.split('\n');
			var value = null;
			for(var i=lines.length - 1; i >= 0; i--){
				const parts = lines[i].split('>').map(part => part.trim());
				if(parts.length >= 2 && parts[0] == String(node)){
					value = parts[1];
					break;
				}
			}
			if(single_test_wait[node]){
				if(value && String(value).indexOf("testing") === 0){
					single_test_wait[node] = false;
				}else{
					setTimeout(function() { get_latency_data_single(node, retry + 1); }, 800);
					return;
				}
			}
			if(!value || String(value).indexOf("testing") === 0 || String(value).indexOf("waiting") === 0){
				setTimeout(function() { get_latency_data_single(node, retry + 1); }, 800);
			}else{
				write_webtest([[String(node), value]]);
				single_test_running = false;
				single_test_node = null;
				enable_latency_buttons();
			}
		},
		error: function(){
			setTimeout(function() { get_latency_data_single(node, retry + 1); }, 800);
		},
	});
}

function disable_latency_buttons(active_node){
	$(".latency_btn").each(function() {
		var n = $(this).data("node");
		if(String(n) === String(active_node)) return;
		if($(this).data("orig-title") === undefined){
			$(this).data("orig-title", $(this).attr("title") || "");
		}
		$(this).attr("title", "请等待当前测试完成");
		$(this).css({"opacity":"0.4","cursor":"not-allowed"});
	});
}

function enable_latency_buttons(){
	$(".latency_btn").each(function() {
		var orig = $(this).data("orig-title");
		if(orig !== undefined){
			$(this).attr("title", orig);
		}
		$(this).css({"opacity":"1","cursor":"pointer"});
	});
}
function get_latency_data(action){
	if(close_latency_flag == 1) return false;
	var URL = '/_temp/webtest.txt'
	$.ajax({
		url: URL,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
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
				batch_test_running = false;
				//console.log("stop getting webtest result!");
					$.ajax({
						type: "GET",
						url: "/_api/ss_basic_webtest_ts",
						dataType: "json",
						success: function(data) {
							db_get = data.result[0];
							if(db_get["ss_basic_webtest_ts"]){
							$("#ss_wts_show").html("<em>【上次完成时间: " + db_get["ss_basic_webtest_ts"] + "】</em>")
							$("#dropdown").width(370);
						}
					}
				});
			}else{
				//console.log("getting webtest result...");
					setTimeout(function() { get_latency_data(2); }, 1000);
			}
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
				setTimeout(function() { get_latency_data(action); }, 1000);
		},
	});
}
function load_latency_cache(){
	var URL = '/_temp/webtest.txt';
	$.ajax({
		url: URL,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			const data = parse_webtest_complete(res);
			const usable = count_usable_webtest(data.list);
			const threshold = Math.max(1, Math.floor(node_nu * 0.5));
			if(data.complete && usable >= threshold){
				batch_test_running = false;
				write_webtest(data.list);
			}else{
				load_latency_backup(usable);
			}
		}
	});
}
function load_latency_backup(minCount){
	var URL = '/_temp/webtest_bakcup.txt';
	$.ajax({
		url: URL,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(res) {
			const data = parse_webtest_complete(res);
			const usable = count_usable_webtest(data.list);
			if(usable >= Math.max(1, minCount || 0)){
				write_webtest(data.list);
			}else if(usable > 0){
				write_webtest(data.list);
			}
		}
	});
}
function parse_webtest_complete(res){
	const lines = res.split('\n');
	let current = {};
	let last_complete = null;
	lines.forEach(line => {
		const parts = line.split('>').map(part => part.trim());
		if(parts.length >= 2){
			const key = parts[0];
			const val = parts[1];
			if(!key){
				return;
			}
			if(key === "stop"){
				if(Object.keys(current).length){
					last_complete = current;
				}
				current = {};
				return;
			}
			current[key] = val;
		}
	});
	if(last_complete){
		return { list: Object.entries(last_complete), complete: true };
	}
	return { list: Object.entries(current), complete: false };
}
function has_usable_webtest(array){
	return array.some(function(item){
		return $.isNumeric(item[1]) || item[1] == "failed" || item[1] == "timeout" || item[1] == "ns";
	});
}
function count_usable_webtest(array){
	var cnt = 0;
	array.forEach(function(item){
		if($.isNumeric(item[1]) || item[1] == "failed" || item[1] == "timeout" || item[1] == "ns"){
			cnt++;
		}
	});
	return cnt;
}
function write_webtest(ps){
	for(var i = 0; i<ps.length; i++){
		var nu = ps[i][0];
		var lag = ps[i][1];
		if(typeof lag === "string"){
			lag = lag.replace(/\.{3,}/, "...");
			if(lag.indexOf("testing") === 0){
				lag = "testing...";
			}
		}
		var $cell = $('#ss_node_lt_' + nu);
		var $val = $cell.length ? $cell.find(".latency_val") : null;
		if(typeof lag === "string" && (lag.indexOf("testing") === 0 || lag.indexOf("waiting") === 0)){
			if($val && $val.length){
				var curr = $val.text().trim();
				if(curr && curr !== "-" && curr.indexOf("testing") !== 0 && curr.indexOf("waiting") !== 0){
					continue;
				}
			}
		}
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
			}else if(lag == "timeout"){
				test_result = '<font color="#FF0000">timeout!</font>';
			}else if(lag == "ns"){
				test_result = '<font color="#FF0000">不支持!</font>';
			}else{
				test_result = '<font color="#00FFCC">' + lag +'</font>'
			}
		}
		
		if($cell.length){
			if($val && $val.length){
				$val.html(test_result);
			}else{
				$cell.html(test_result);
			}
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
		setTimeout(get_realtime_log, 600);
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
function updatelist(arg) {
	var dbus_post = {};
	db_ss["ss_basic_action"] = "8";
	dbus_post["ss_basic_rule_update"] = E("ss_basic_rule_update").value;
	dbus_post["ss_basic_rule_update_time"] = E("ss_basic_rule_update_time").value;
	dbus_post["ss_basic_gfwlist_update"] = E("ss_basic_gfwlist_update").checked ? '1' : '0';
	dbus_post["ss_basic_chnroute_update"] = E("ss_basic_chnroute_update").checked ? '1' : '0';
	dbus_post["ss_basic_chnlist_update"] = E("ss_basic_chnlist_update").checked ? '1' : '0';
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
			// 处理内置推荐
			if (res["ads_url_1"] && res["ads_des_1"]){
				ads_url_1 = res["ads_url_1"];
				ads_des_1 = res["ads_des_1"];
				if (node_nu == 0 && poped == 0) pop_node_add_ads();
				if(!E("ss_online_links").value){
					sub_ads_html = '<a target="_blank" href="' + ads_url_1 + '"><em>' + ads_des_1 + '</em></a>';
					$('#ss_sub_ads').html(sub_ads_html)
				}
			}else{
				if (node_nu == 0 && poped == 0) pop_node_add();
			}
			
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
				setInterval(scroll_msg, res["ads_time"]);
			}else{
				setInterval(scroll_msg, 5000);
			}
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			console.log(XmlHttpRequest.responseText);
			if (node_nu == 0 && poped == 0) pop_node_add();
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

var tab_actions = {
	0: function() {
		$('#apply_button').show();
		$('#ss_failover_save').hide();
		showhide("table_basic", (node_max != 0));
		change_select_width('#ssconf_basic_node');
		change_select_width('#ss_basic_method');
		refresh_basic_input_width();
	},
	1: function() {
		$('#apply_button').hide();
		$(".nodeTable").show();
		select_default_node(3);
	},
	2: function() {
		$('#apply_button').show();
		$('#ss_failover_save').show();
		verifyFields();
	},
	3: function() {
		var selects = [
			'#ss_basic_chng_china_udp_1_opt',
			'#ss_basic_chng_china_tcp_1_opt',
			'#ss_basic_chng_china_dot_1_opt',
			'#ss_basic_chng_china_udp_2_opt',
			'#ss_basic_chng_china_tcp_2_opt',
			'#ss_basic_chng_china_dot_2_opt',
			'#ss_basic_chng_china_udp_3_opt',
			'#ss_basic_chng_china_tcp_3_opt',
			'#ss_basic_chng_china_dot_3_opt',
			'#ss_basic_chng_trust_udp_1_opt',
			'#ss_basic_chng_trust_tcp_1_opt',
			'#ss_basic_chng_trust_dot_1_opt',
			'#ss_basic_chng_trust_udp_2_opt',
			'#ss_basic_chng_trust_tcp_2_opt',
			'#ss_basic_chng_trust_dot_2_opt',
			'#ss_basic_chng_trust_udp_3_opt',
			'#ss_basic_chng_trust_tcp_3_opt',
			'#ss_basic_chng_trust_dot_3_opt'
		];
		$('#apply_button').show();
		$('#ss_failover_save').hide();
		for (var i = 0; i < selects.length; i++) {
			change_select_width(selects[i], '1');
		}
		change_select_width('#ss_basic_server_resolv');
		change_select_width('#ss_basic_dig_opt');
		update_visibility();
		autoTextarea(E("ss_dnsmasq"), 0, 500);
	},
	4: function() {
		var fields = [
			"ss_wan_white_ip",
			"ss_wan_white_domain",
			"ss_wan_black_ip",
			"ss_wan_black_domain"
		];
		$('#apply_button').show();
		$('#ss_failover_save').hide();
		for (var i = 0; i < fields.length; i++) {
			autoTextarea(E(fields[i]), 0, 400);
		}
	},
	7: function() {
		$('#apply_button').hide();
		$('#ss_failover_save').hide();
		update_visibility();
	},
	8: function() {
		$('#apply_button').show();
		$('#ss_failover_save').hide();
		refresh_acl_table();
	},
	9: function() {
		$('#apply_button').show();
		$('#ss_failover_save').hide();
		update_visibility();
	},
	10: function() {
		$('#apply_button').hide();
		$('#ss_failover_save').hide();
		get_log();
	}
};

function handle_tab_click() {
	var match = this.className.match(/show-btn(\d+)/);
	if (!match) return;
	var idx = parseInt(match[1], 10);
	tabSelect(idx);
	if (tab_actions[idx]) {
		tab_actions[idx]();
	}
}

function bind_tab_handlers() {
	$('[class*="show-btn"]').each(function() {
		if (this.className.match(/show-btn\d+/)) {
			$(this).off('click.tab').on('click.tab', handle_tab_click);
		}
	});
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
	bind_tab_handlers();
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

function refresh_basic_input_width() {
	var inputs = ['#ss_basic_server', '#ss_basic_password', '#ss_basic_xray_uuid', '#ss_basic_xray_publickey'];
	for (var i = 0; i < inputs.length; i++) {
		change_select_width(inputs[i], null, {min: 152, max: 438});
	}
}

function change_select_width(o, p, cfg) {
	var $el = $(o);
	if (!$el.length) return;
	var tagName = ($el.prop('tagName') || '').toLowerCase();

	if (tagName === "input") {
		$el.off("input.auto_width change.auto_width keyup.auto_width").on("input.auto_width change.auto_width keyup.auto_width", function() {
			var $this = $(this);
			if (!$this.data("auto_width_min")) {
				$this.data("auto_width_min", Math.ceil($this.outerWidth()));
			}

			var text = $this.val();
			if (!text) text = $this.attr("placeholder") || "";

			var $aux = $("<span></span>").text(text);
			$aux.css({
				position: "absolute",
				left: "-9999px",
				top: "-9999px",
				visibility: "hidden",
				whiteSpace: "pre",
				fontSize: $this.css("font-size"),
				fontFamily: $this.css("font-family"),
				fontWeight: $this.css("font-weight"),
				letterSpacing: $this.css("letter-spacing")
			});
			$("body").append($aux);

			var aux_width = Math.ceil($aux.outerWidth());
			$aux.remove();

			var min_width = cfg && !isNaN(parseInt(cfg.min, 10))
				? parseInt(cfg.min, 10)
				: (parseInt($this.data("auto_width_min"), 10) || 0);
			if (aux_width < min_width) aux_width = min_width;

			var max_width = cfg && !isNaN(parseInt(cfg.max, 10))
				? parseInt(cfg.max, 10)
				: parseFloat($this.css("max-width"));
			if (!isNaN(max_width) && max_width > 0 && aux_width > max_width) {
				aux_width = max_width;
			}
			$this.width(aux_width);
		}).trigger("input");
		return;
	}

	$el.off("click.auto_width change.auto_width").on("click.auto_width change.auto_width", function() {
		var text = $(this).find("option:selected").text();
		var className = $(this).attr("class") || "";
		var $aux = $('<select class="' + className + '">').append($("<option/>").text(text));
		$(this).after($aux);
		var aux_width = $aux.width();
		if (aux_width < 135 && p == "1") {
			aux_width = 135;
		}
		if (aux_width < 118 && p == "0") {
			aux_width = 118;
		}
		$(this).width(aux_width);
		$aux.remove();
	}).trigger("change");
}

function set_ss_status_waiting(text) {
	E("ss_state2").innerHTML = "国外连接 - " + text;
	E("ss_state3").innerHTML = "国内连接 - " + text;
}

function apply_ss_status(res, with_heartbeat) {
	if (res && res.indexOf("@@") != -1){
		var arr = res.split("@@");
		if (arr[0] == "" || arr[1] == "") {
			set_ss_status_waiting("Waiting for first refresh...");
		} else {
			E("ss_state2").innerHTML = arr[0];
			E("ss_state3").innerHTML = arr[1];
		}
		if (with_heartbeat && arr[2] == "1") {
			var dbus_post = {};
			dbus_post["ss_heart_beat"] = "0";
			push_data("dummy_script.sh", "", dbus_post, "2");
		}
		return true;
	}
	set_ss_status_waiting("Waiting ...");
	return false;
}

function setup_status_ws(onFail, with_heartbeat, onReady) {
	if (wss && wss.readyState === 1){
		wss_open = 1;
		wss.onerror = function(event) {
			//console.log('WS Error: ' + event.data);
			wss_open = 0;
			onFail();
		};
		wss.onclose = function() {
			//console.log('WS DISCONNECT');
			wss_open = 0;
			onFail();
		};
		wss.onmessage = function(event) {
			apply_ss_status(event.data, with_heartbeat);
		};
		if (typeof onReady === "function") {
			onReady();
		}
		return true;
	}
	if (ws_flag != 1){
		onFail();
		return false;
	}
	wss = new WebSocket("ws://" + hostname + ":803/");
	var ws_open_timeout = false;
	var ws_test_timer = setTimeout(function() {
		ws_open_timeout = true;
		wss_open = 0;
		try {
			wss.close();
		} catch (e) {}
		onFail();
	}, 1000);
	wss.onopen = function() {
		if (ws_open_timeout){
			try {
				wss.close();
			} catch (e) {}
			return;
		}
		clearTimeout(ws_test_timer);
		//console.log('成功建立websocket链接，开始获取后台状态...');
		wss_open = 1;
		if (typeof onReady === "function") {
			onReady();
		}
	};
	wss.onerror = function(event) {
		if (ws_open_timeout){
			return;
		}
		clearTimeout(ws_test_timer);
		//console.log('WS Error: ' + event.data);
		wss_open = 0;
		onFail();
	};
	wss.onclose = function() {
		if (ws_open_timeout){
			return;
		}
		clearTimeout(ws_test_timer);
		//console.log('WS DISCONNECT');
		wss_open = 0;
		onFail();
	};
	wss.onmessage = function(event) {
		apply_ss_status(event.data, with_heartbeat);
	};
	return true;
}

function get_ss_status(use_ws) {
	if (typeof use_ws == "undefined"){
		use_ws = (ws_flag == 1);
	}
	set_ss_status_waiting("Waiting..");
	if (db_ss['ss_basic_enable'] != "1") {
		return false;
	}

	if(db_ss["ss_failover_enable"] == "1"){
		if (use_ws){
			get_ss_status_back();
		}else{
			get_ss_status_back_httpd();
		}
	}else{
		if (use_ws){
			get_ss_status_front();
		}else{
			get_ss_status_front_httpd();
		}
	}
}
function get_ss_status_front() {
	setup_status_ws(get_ss_status_front_httpd, false, get_ss_status_front_websocket);
}

function get_ss_status_front_httpd() {
	if (submit_flag == "1") {
		//console.log("wait for 5s to get next status...")
		setTimeout(get_ss_status_front_httpd, 5000);
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
	setTimeout(get_ss_status_front_httpd, refreshRate);
}
function get_ss_status_front_websocket() {
	if (submit_flag == "1") {
		//console.log("wait for 5s to get next status...")
		setTimeout(get_ss_status_front_websocket, 5000);
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
		setTimeout(get_ss_status_front_websocket, refreshRate);
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
	
	setup_status_ws(get_ss_status_back_httpd, true, get_ss_status_back_websocket);
}
function get_ss_status_back_websocket() {
	try {
		wss.send("cat /tmp/upload/ss_status.txt");
	} catch (ex) {
		console.log('Cannot send: ' + ex);
	}
	if (wss_open == "1"){
		setTimeout(get_ss_status_back_websocket, 1000);
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
	setTimeout(get_ss_status_back_httpd, time_wait);
}
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
		var note1 = '1. gfwlist的域名清单来自：<a href="https://github.com/hq450/fancyss/blob/3.0/rules_ng/gfwlist.gz" target="_blank"><em><u>https://github.com/hq450/fancyss/blob/3.0/rules_ng/gfwlist.gz</u></em></a>，收录了常见的被gfw屏蔽的域名。';
		var note2 = '2. 由于gfwlist清单较长，将每次随机选取100个域名进行测试！理想情况下，解析结果应该全部是海外IP地址，没有大陆IP地址！';
		var note3 = '3. 解析结果和速度可能受节点、DNS方案、上游DNS缓存等因素影响，本测试也无法判断解析结果正确性！所以测试结果仅供参考！';
	}
	else if(s == 5){
		$("#log_dig").show();
		$("#log_resv").hide();
		dns_log["ss_basic_logname"] = "dns_cdn_china";
		var note1 = '1. chnlist的域名清单来自：<a href="https://github.com/felixonmars/dnsmasq-china-list" target="_blank"><em><u>https://github.com/felixonmars/dnsmasq-china-list</u></em></a> 的accelerated-domains.china.conf，并经过fancyss项目整理。';
		var note2 = '2. 由于chnlist清单较长，将每次随机选取100个域名进行测试！由于chnlist收录的域名条件位解析结果或者NS服务器在国内，所以很多域名解析到国外是正常的！';
	}
	else if(s == 6){
		$("#log_dig").hide();
		$("#log_resv").show();
		var note1 = '1. 本测试需要用到dig程序，因程序体积较大，fancyss默认不包含此程序，点击测试的时候会自动尝试下载该程序。';
		var note2 = '1. 本测试仅针对DNS解析最终端，即本机dnsmasq 53端口的DNS服务器测试，每次测试前会自动清空dnsmasq缓存，以避免缓存影响。';
		var note3 = '2. 用dig进行测试可以方便的知道在本插件选定的DNS方案下，域名解析的ipv4结果';
		dbus_commit["ss_basic_dig_opt"] = E("ss_basic_dig_opt").value
		dbus_commit["ss_basic_dig_opt_usr"] = E("ss_basic_dig_opt_usr").value
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
			setTimeout(dns_test, 2000);
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
					setTimeout(function() { get_dns_log(s); }, 500);
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
		$("#ssf_test_url").html(E("ss_basic_furl").value)
		E("ssf_status_div").style.visibility = "visible";
		$('#ssf_status_div').offset({top: elem_h_offset, left: elem_w_offset});
		get_status_log(1);
	}else{
		var elem_h = $("#ssc_status_div").height();
		var elem_w = $("#ssc_status_div").width();
		var elem_h_offset = (page_h - elem_h) / 2;
		var elem_w_offset = (page_w - elem_w) / 2 + 90;
		if(elem_h_offset < 0) elem_h_offset = 10;
		$("#ssc_test_url").html(E("ss_basic_curl").value)
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
					setTimeout(function() { get_status_log(s); }, 3123);
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
					setTimeout(get_log_httpd, 100);
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
					setTimeout(get_realtime_log, 100);
				}
			retArea.value = response.myReplace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		},
			error: function() {
				setTimeout(get_realtime_log, 500);
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
	setTimeout(count_down_close, 1000);
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
			obj["udp"] = get_acl_udp_value(obj["mode"], db_acl[p + "_udp_" + field]);
			obj["quic"] = get_acl_quic_value(db_acl[p + "_quic_" + field]);
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
	acls[p + "_udp_" + acl_node_max] = E("ss_acl_udp").checked ? "1" : "0";
	acls[p + "_quic_" + acl_node_max] = E("ss_acl_quic").checked ? "1" : "0";
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
	var params = ["ip", "name", "port", "mode", "udp", "quic"];
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

function capture_node_form_defaults() {
	var defaults = {};
	$("#table_add_nodes").find("input,select,textarea").each(function() {
		if (!this.id) return;
		if (this.type === "checkbox" || this.type === "radio") {
			defaults[this.id] = this.checked;
		} else {
			defaults[this.id] = this.value;
		}
	});
	node_form_defaults = defaults;
}

function reset_node_form() {
	if (!node_form_defaults) {
		capture_node_form_defaults();
	}
	$("#table_add_nodes").find("input,select,textarea").each(function() {
		if (!this.id) return;
		if (node_form_defaults && Object.prototype.hasOwnProperty.call(node_form_defaults, this.id)) {
			if (this.type === "checkbox" || this.type === "radio") {
				this.checked = !!node_form_defaults[this.id];
			} else {
				this.value = node_form_defaults[this.id];
			}
		} else {
			if (this.type === "checkbox" || this.type === "radio") {
				this.checked = false;
			} else {
				this.value = "";
			}
		}
	});
	$("#ssTitle").html("SS节点");
	$("#ssrTitle").html("SSR节点");
	$("#vmessTitle").html("Vmess节点");
	$("#vlessTitle").html("Vless节点");
	$("#trojanTitle").html("Trojan节点");
	$("#naiveTitle").html("Naïve节点");
	$("#tuicTitle").html("tuic节点");
	$("#hy2Title").html("hysteria2节点");
	E("ssTitle").style.display = "";
	E("ssrTitle").style.display = "";
	E("vmessTitle").style.display = "";
	E("vlessTitle").style.display = "";
	E("trojanTitle").style.display = "";
	E("naiveTitle").style.display = "";			//fancyss-full
	E("tuicTitle").style.display = "";			//fancyss-full
	E("hy2Title").style.display = "";
	E("add_node").style.display = "";
	E("edit_node").style.display = "none";
	E("continue_add").style.display = "";
	$("#cancel_Btn").css("margin-left", "160px");
	$('#add_fancyss_node_title').html("添加节点");
	edit_id = null;
}
function refresh_acl_table(q, cb) {
	return $.ajax({
		type: "GET",
		url: "/_api/ss_acl",
		dataType: "json",
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
			set_acl_checkbox_state("ss_acl_default_udp", get_acl_udp_value($('#ss_acl_default_mode').val() || E("ss_basic_mode").value, db_acl["ss_acl_default_udp"]));
			set_acl_checkbox_state("ss_acl_default_quic", get_acl_quic_value(db_acl["ss_acl_default_quic"]));
			//write dynamic table value
				for (var i = 1; i < acl_node_max + 1; i++) {
					$('#ss_acl_mode_' + i).val(db_acl["ss_acl_mode_" + i]);
					$('#ss_acl_port_' + i).val(db_acl["ss_acl_port_" + i]);
					$('#ss_acl_name_' + i).val(db_acl["ss_acl_name_" + i]);
					sync_acl_port_state("ss_acl_port_" + i, db_acl["ss_acl_mode_" + i]);
					set_acl_checkbox_state("ss_acl_udp_" + i, get_acl_udp_value(db_acl["ss_acl_mode_" + i], db_acl["ss_acl_udp_" + i]));
					set_acl_checkbox_state("ss_acl_quic_" + i, get_acl_quic_value(db_acl["ss_acl_quic_" + i]));
				}
			//set default rule port to all when game mode enabled
			set_default_port();
				//after table generated and value filled, set default value for first line_image1
				$('#ss_acl_mode').val("1");
				$('#ss_acl_port').val("80,443");
				sync_acl_port_state("ss_acl_port", $('#ss_acl_mode').val());
				set_acl_checkbox_state("ss_acl_udp", false);
				set_acl_checkbox_state("ss_acl_quic", true);
			sync_acl_udp_quic_labels();
			if (typeof cb === "function") {
				cb();
			}
		},
		error: function() {
			if (typeof cb === "function") {
				cb();
			}
		}
	});
}
function set_mode_1() {
	//set the first line of the table, if mode is gfwlist mode or game mode,set the port to all
	if ($('#ss_acl_mode').val() == 0 || $('#ss_acl_mode').val() == 3) {
		$("#ss_acl_port").val("all");
	} else if ($('#ss_acl_mode').val() == 1) {
		$("#ss_acl_port").val("80,443");
	} else if ($('#ss_acl_mode').val() == 2 || $('#ss_acl_mode').val() == 5) {
		$("#ss_acl_port").val("22,80,443");
	}
	sync_acl_port_state("ss_acl_port", $('#ss_acl_mode').val());
	update_acl_udp_quic_label_pair("ss_acl_udp", "ss_acl_quic");
}
function set_mode_2(o) {
	var id2 = $(o).attr("id");
	var ids2 = id2.split("_");
	id2 = ids2[ids2.length - 1];
	if ($(o).val() == 0 || $(o).val() == 3) {
		$("#ss_acl_port_" + id2).val("all");
	} else if ($(o).val() == 1) {
		$("#ss_acl_port_" + id2).val("80,443");
	} else if ($(o).val() == 2 || $(o).val() == 5) {
		$("#ss_acl_port_" + id2).val("22,80,443");
	}
	sync_acl_port_state("ss_acl_port_" + id2, $(o).val());
	update_acl_udp_quic_label_pair("ss_acl_udp_" + id2, "ss_acl_quic_" + id2);
}
function set_default_port() {
	if ($('#ss_acl_default_mode').val() == 0 || $('#ss_acl_default_mode').val() == 3) {
		$("#ss_acl_default_port").val("all");
	} else if ($('#ss_acl_default_mode').val() == 1) {
		$("#ss_acl_default_port").val("80,443");
	} else if ($('#ss_acl_default_mode').val() == 2 || $('#ss_acl_default_mode').val() == 5) {
		$("#ss_acl_default_port").val("22,80,443");
	}
	sync_acl_port_state("ss_acl_default_port", $('#ss_acl_default_mode').val());
	update_acl_udp_quic_label_pair("ss_acl_default_udp", "ss_acl_default_quic");
}
function is_acl_game_mode(mode) {
	return String(mode) == "3";
}
function is_acl_no_proxy_mode(mode) {
	return String(mode) == "0";
}
function get_acl_mode_value_by_udp_id(udpId) {
	if (udpId == "ss_acl_udp") {
		return $('#ss_acl_mode').val();
	}
	if (udpId == "ss_acl_default_udp") {
		if (E("ss_acl_default_mode")) {
			return $('#ss_acl_default_mode').val();
		}
		return E("ss_basic_mode").value;
	}
	var ids = udpId.split("_");
	var rowid = ids[ids.length - 1];
	if (rowid && E("ss_acl_mode_" + rowid)) {
		return $('#ss_acl_mode_' + rowid).val();
	}
	return "";
}
function sync_acl_checkbox_ui(boxId, title, disabled) {
	var box = E(boxId);
	if (!box) {
		return;
	}
	var labelWrap = box.parentNode;
	var text = E(boxId + "_label");
	box.disabled = !!disabled;
	box.title = title;
	box.style.cursor = disabled ? "not-allowed" : "pointer";
	if (labelWrap) {
		labelWrap.style.cursor = disabled ? "not-allowed" : "pointer";
		labelWrap.title = title;
	}
	if (text) {
		text.title = title;
	}
}
function sync_acl_port_state(portId, mode) {
	var portSelect = E(portId);
	if (!portSelect) {
		return;
	}
	var noProxy = is_acl_no_proxy_mode(mode);
	if (noProxy) {
		portSelect.value = "all";
	}
	portSelect.disabled = noProxy;
	portSelect.title = noProxy ? "不通过代理时，目标端口将全部走本地网络直连" : "";
	portSelect.style.cursor = noProxy ? "not-allowed" : "pointer";
}
function sync_acl_checkbox_state_by_mode(udpId, quicId, mode) {
	var udpBox = E(udpId);
	var quicBox = E(quicId);
	if (!udpBox || !quicBox) {
		return;
	}
	if (is_acl_no_proxy_mode(mode)) {
		udpBox.checked = false;
		quicBox.checked = false;
		sync_acl_checkbox_ui(udpId, "不通过代理时，udp将走本地网络直连", true);
		sync_acl_checkbox_ui(quicId, "不通过代理时，quic流量将走本地网络直连", true);
		return;
	}
	if (is_acl_game_mode(mode)) {
		udpBox.checked = true;
	}
	sync_acl_checkbox_ui(udpId, is_acl_game_mode(mode) ? "游戏模式下UDP默认开启，无法关闭" : "开启该主机的UDP代理", is_acl_game_mode(mode));
	sync_acl_checkbox_ui(quicId, "屏蔽该主机的QUIC流量", false);
}
function get_acl_udp_value(mode, value) {
	if (is_acl_game_mode(mode)) {
		return true;
	}
	if (typeof value != "undefined") {
		return value == "1";
	}
	return db_ss["ss_basic_udpall"] == "1";
}
function get_acl_quic_value(value) {
	if (typeof value != "undefined") {
		return value == "1";
	}
	if (typeof db_ss["ss_basic_block_quic"] != "undefined") {
		return db_ss["ss_basic_block_quic"] == "1";
	}
	return true;
}
function set_acl_checkbox_state(id, checked) {
	if (E(id)) {
		E(id).checked = !!checked;
	}
}
function update_acl_udp_quic_label_pair(udpId, quicId) {
	var mode = get_acl_mode_value_by_udp_id(udpId);
	sync_acl_checkbox_state_by_mode(udpId, quicId, mode);
	var udpLabel = E(udpId + "_label");
	var quicLabel = E(quicId + "_label");
	if (is_acl_no_proxy_mode(mode)) {
		if (udpLabel) {
			udpLabel.style.textDecoration = "none";
			udpLabel.style.color = "#999999";
			udpLabel.style.opacity = "1";
		}
		if (quicLabel) {
			quicLabel.style.textDecoration = "none";
			quicLabel.style.color = "#999999";
			quicLabel.style.opacity = "1";
		}
		return;
	}
	if (udpLabel && E(udpId)) {
		var udpEnabled = E(udpId).checked;
		udpLabel.style.textDecoration = udpEnabled ? "none" : "line-through";
		udpLabel.style.color = udpEnabled ? "#3cb371" : "#d9534f";
		udpLabel.style.opacity = "1";
	}
	if (quicLabel && E(quicId)) {
		var quicBlocked = E(quicId).checked;
		quicLabel.style.textDecoration = quicBlocked ? "line-through" : "none";
		quicLabel.style.color = quicBlocked ? "#d9534f" : "#3cb371";
		quicLabel.style.opacity = "1";
	}
}
function sync_acl_udp_quic_labels() {
	var boxes = document.querySelectorAll('input[type="checkbox"]');
	for (var i = 0; i < boxes.length; i++) {
		var udpId = boxes[i].id;
		if (udpId.indexOf("ss_acl") !== 0 || udpId.indexOf("udp") === -1) {
			continue;
		}
		var quicId = udpId.replace("_udp", "_quic");
		if (quicId !== udpId) {
			update_acl_udp_quic_label_pair(udpId, quicId);
		}
	}
}
function render_acl_port_select(id, className, style) {
	var code = '';
	code += '<select id="' + id + '"';
	if (className) {
		code += ' class="' + className + '"';
	}
	if (style) {
		code += ' style="' + style + '"';
	}
	code += '>';
	code += '<option value="80,443">80,443</option>';
	code += '<option value="22,80,443">22,80,443</option>';
	code += '<option value="22,80,443,8080,8443">22,80,443,8080,8443</option>';
	code += '<option value="all">all</option>';
	code += '</select>';
	return code;
}
function render_acl_udp_control(udpId, quicId, udpChecked) {
	var code = '';
	code += '<div style="display:flex;align-items:center;justify-content:center;white-space:nowrap;font-size:11px;line-height:1;">';
	code += '<label style="display:flex;align-items:center;gap:3px;cursor:pointer;margin:0;" title="开启该主机的UDP代理">';
	code += '<input type="checkbox" id="' + udpId + '"' + (udpChecked ? ' checked' : '') + ' onchange="update_acl_udp_quic_label_pair(\'' + udpId + '\', \'' + quicId + '\')" />';
	code += '<span id="' + udpId + '_label">UDP</span>';
	code += '</label>';
	code += '</div>';
	return code;
}
function render_acl_quic_control(udpId, quicId, quicChecked) {
	var code = '';
	code += '<div style="display:flex;align-items:center;justify-content:center;white-space:nowrap;font-size:11px;line-height:1;">';
	code += '<label style="display:flex;align-items:center;gap:3px;cursor:pointer;margin:0;" title="屏蔽该主机的QUIC流量">';
	code += '<input type="checkbox" id="' + quicId + '"' + (quicChecked ? ' checked' : '') + ' onchange="update_acl_udp_quic_label_pair(\'' + udpId + '\', \'' + quicId + '\')" />';
	code += '<span id="' + quicId + '_label">QUIC</span>';
	code += '</label>';
	code += '</div>';
	return code;
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
	code += '<th width="18%">客户端地址</th>'
	code += '<th width="20%">主机别名</th>'
	code += '<th width="18%">访问控制</th>'
	code += '<th width="8%">UDP代理</th>'
	code += '<th width="8%">屏蔽QUIC</th>'
	code += '<th width="22%">代理端口</th>'
	code += '<th width="6%">操作</th>'
	code += '</tr>'
	code += '</table>'
	// acl table input area
	code += '<table id="ACL_table" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" class="list_table acl_lists" style="margin:-1px 0px 0px 0px;">'
	code += '<tr>'
	// ip addr
	code += '<td width="18%">'
	code += '<div style="display:flex;align-items:center;gap:0;padding:0 4px;box-sizing:border-box;">'
	code += '<input type="text" maxlength="15" class="input_ss_table" id="ss_acl_ip" align="left" style="flex:1;min-width:0;width:auto;height:25px;line-height:25px;margin-left:0;text-align:center;box-sizing:border-box;" autocomplete="off" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off">'
	code += '<img id="pull_arrow" height="14px;" src="/res/arrow-down.gif" style="flex:none;cursor:pointer;" onclick="pullLANIPList(this);" title="<#select_IP#>">'
	code += '</div>'
	code += '<div id="ClientList_Block" class="clientlist_dropdown" style="margin-left:2px;margin-top:25px;"></div>'
	code += '</td>'
	// name
	code += '<td width="20%">'
	code += '<input type="text" id="ss_acl_name" class="input_ss_table" maxlength="50" style="display:block;width:92%;max-width:92%;height:25px;line-height:25px;margin:0 auto;box-sizing:border-box;text-align:center" placeholder="" />'
	code += '</td>'
	// mode
	code += '<td width="18%">'
	code += '<select id="ss_acl_mode" style="width:100%;max-width:100%;box-sizing:border-box;margin:0;text-align:center;text-align-last:center;padding-left:0;" class="input_option" onchange="set_mode_1(this);">'
	code += '<option value="0">不通过代理</option>'
	code += '<option value="1">gfwlist模式</option>'
	code += '<option value="2">大陆白名单模式</option>'
	code += '<option value="3">游戏模式</option>'
	code += '<option value="5">全局代理模式</option>'
	// code += '<option value="6">回国模式</option>'
	code += '</select>'
	code += '</td>'
	code += '<td width="8%">'
	code += render_acl_udp_control('ss_acl_udp', 'ss_acl_quic', false);
	code += '</td>'
	code += '<td width="8%">'
	code += render_acl_quic_control('ss_acl_udp', 'ss_acl_quic', true);
	code += '</td>'
	// port
	code += '<td width="22%">'
	code += render_acl_port_select('ss_acl_port', 'input_option', 'width:100%;max-width:100%;box-sizing:border-box;margin:0;text-align-last:center;padding-left:0;')
	code += '</td>'
	// add/delete
	code += '<td width="6%">'
	code += '<input style="margin-left: 6px;margin: -2px 0px -4px -2px;" type="button" class="add_btn" onclick="addTr()" value="" />'
	code += '</td>'
	code += '</tr>'
	// acl table rule area
	for (var field in acl_confs) {
		var ac = acl_confs[field];
		code += '<tr id="acl_tr_' + ac["acl_node"] + '">';
		
		code += '<td width="18%">' + ac["ip"] + '</td>';
		
		code += '<td width="20%">';
		code += '<input type="text" placeholder="' + ac["acl_node"] + '号机" id="ss_acl_name_' + ac["acl_node"] + '" name="ss_acl_name_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="display:block;width:92%;max-width:92%;height:25px;line-height:25px;margin:0 auto;box-sizing:border-box;" placeholder="" />';
		code += '</td>';
		
		code += '<td width="18%">';
		code += '<select id="ss_acl_mode_' + ac["acl_node"] + '" name="ss_acl_mode_' + ac["acl_node"] + '" style="width:100%;max-width:100%;box-sizing:border-box;margin:0;" class="sel_option" onchange="set_mode_2(this);">';
		if ($("#ss_basic_mode").val() == 6) {
			code += '<option value="0">不通过代理</option>';
			//code += '<option value="6">回国模式</option>';
		} else {
			code += '<option value="0">不通过代理</option>';
			code += '<option value="1">gfwlist模式</option>';
			code += '<option value="2">大陆白名单模式</option>';
			code += '<option value="3">游戏模式</option>';
			code += '<option value="5">全局代理模式</option>';
			//code += '<option value="6">回国模式</option>';
		}
		code += '</select>'
		code += '</td>';
		code += '<td width="8%">';
		code += render_acl_udp_control('ss_acl_udp_' + ac["acl_node"], 'ss_acl_quic_' + ac["acl_node"], ac["udp"]);
		code += '</td>';
		code += '<td width="8%">';
		code += render_acl_quic_control('ss_acl_udp_' + ac["acl_node"], 'ss_acl_quic_' + ac["acl_node"], ac["quic"]);
		code += '</td>';
		code += '<td width="22%">';
		code += render_acl_port_select('ss_acl_port_' + ac["acl_node"], 'sel_option', 'width:100%;max-width:100%;box-sizing:border-box;');
		code += '</td>';
		
		code += '<td width="6%">';
		code += '<input style="margin: -2px 0px -4px -2px;" id="acl_node_' + ac["acl_node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
		code += '</td>';
		code += '</tr>';
	}
	code += '<tr>';
	if (n == 0) {
		code += '<td width="18%">所有主机</td>';
	} else {
		code += '<td width="18%">其它主机</td>';
	}
	code += '<td width="20%">默认规则</td>';
	ssmode = E("ss_basic_mode").value;
	var defaultMode = typeof db_acl["ss_acl_default_mode"] != "undefined" ? db_acl["ss_acl_default_mode"] : ssmode;
	var defaultUdp = get_acl_udp_value(defaultMode, db_acl["ss_acl_default_udp"]);
	var defaultQuic = get_acl_quic_value(db_acl["ss_acl_default_quic"]);
	if (n == 0) {
		if (ssmode == 0) {
			code += '<td width="18%">SS关闭</td>';
		} else if (ssmode == 1) {
			code += '<td width="18%">gfwlist模式</td>';
		} else if (ssmode == 2) {
			code += '<td width="18%">大陆白名单模式</td>';
		} else if (ssmode == 3) {
			code += '<td width="18%">游戏模式</td>';
		} else if (ssmode == 5) {
			code += '<td width="18%">全局模式</td>';
		} else if (ssmode == 6) {
			//code += '<td width="18%">回国模式</td>';
		}
	} else {
		code += '<td width="18%">';
		code += '<select id="ss_acl_default_mode" style="width:100%;max-width:100%;box-sizing:border-box;margin:0;" class="sel_option" onchange="set_default_port();">';
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
			//code += '<option value="6" selected>回国模式</option>';
		}
		code += '</select>';
		code += '</td>';
	}
	code += '<td width="8%">';
	code += render_acl_udp_control('ss_acl_default_udp', 'ss_acl_default_quic', defaultUdp);
	code += '</td>';
	code += '<td width="8%">';
	code += render_acl_quic_control('ss_acl_default_udp', 'ss_acl_default_quic', defaultQuic);
	code += '</td>';
	code += '<td width="22%">';
	code += render_acl_port_select('ss_acl_default_port', 'sel_option', 'width:100%;max-width:100%;box-sizing:border-box;');
	code += '</td>';
	code += '<td width="6%">';
	code += '</td>';
	code += '</tr>';
	code += '</table>';

	$(".acl_lists").remove();
	$('#ss_acl_table').append(code);
	sync_acl_udp_quic_labels();
	
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
		layer.confirm('你确定要删除吗？', {
			shade: 0.8,
		}, function(index) {
			layer.close(index);
			save_online_nodes(action);
		}, function(index) {
			layer.close(index);
			return false;
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
		dbus_post["ss_basic_online_links_proxy"] = E("ss_basic_online_links_proxy").value;
		dbus_post["ss_basic_sub_ai"] = E("ss_basic_sub_ai").checked ? "1":"0";
		dbus_post["ss_basic_online_ua"] = E("ss_basic_online_ua").value;
		dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
		dbus_post["ss_basic_node_update_day"] = E("ss_basic_node_update_day").value;
		dbus_post["ss_basic_node_update_hr"] = E("ss_basic_node_update_hr").value;
		dbus_post["ss_basic_exclude"] = E("ss_basic_exclude").value.replace(pattern,"") || "";
		dbus_post["ss_basic_include"] = E("ss_basic_include").value.replace(pattern,"") || "";
		dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
		dbus_post["ss_basic_hy2_up_speed"] = E("ss_basic_hy2_up_speed").value;
		dbus_post["ss_basic_hy2_dl_speed"] = E("ss_basic_hy2_dl_speed").value;
		dbus_post["ss_basic_hy2_tfo_switch"] = E("ss_basic_hy2_tfo_switch").value;
		dbus_post["ss_basic_hy2_cg_opt"] = E("ss_basic_hy2_cg_opt").value;
	}

	if(ws_flag == 1){
		push_data_ws("ss_online_update.sh", action,  dbus_post);
	}else{
		push_data("ss_online_update.sh", action,  dbus_post);
	}
}
function xray_binary_update(){
	var dbus_post = {};
	db_ss["ss_basic_action"] = "15";
	note = "<li style='line-height:32px'>xray二进制来自于fancyss项目编译压缩：<a style='color:#22ab39;' href='https://github.com/hq450/fancyss/tree/3.0/binaries/xray' target='_blank'>https://github.com/hq450/fancyss/tree/3.0/binaries/xray</a></li>";
	note += "<li style='line-height:32px'>你也可以自行下载Xray-core官方<a style='color:#22ab39;' href='https://github.com/XTLS/Xray-core/releases' target='_blank'>release</a>的二进制文件，替换路由器内/koolshare/bin/xray文件</li>";
	note += "<li style='line-height:32px'>因二进制更新/升级导致代理无法工作的，请检查你的配置是否兼容新版本程序！</li>";
	layer.open({
		type: 0,
		skin: 'layui-layer-lan',
		shade: 0.8,
		title: 'Xray程序更新！',
		time: 0,
		area: '670px',
		offset: '350px',
		btnAlign: 'c',
		maxmin: true,
		content: note,
		btn: ['开始更新'],
		btn1: function() {
			push_data("ss_xray.sh", 2, dbus_post);
			layer.closeAll();
		}
	});
}
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
	arg = "edit_smartdns_smrt_" + o;
	var name = 'smartdns_smrt_' + o;
	SMARTDNS_FLAG = o;
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
function edit_smartdns_conf(o){
	var smat_config_idx=E("ss_basic_smrt").value
	get_smartdns_conf(smat_config_idx);
	$('#smartdns_chnd_conf').val("");
	$("#smartdns_settings").fadeIn(200);
}
function close_smartdns_conf(){
	$("#smartdns_settings").fadeOut(200);
}
function save_smartdns_conf(){
	db_ss["ss_basic_action"] = "22";
	dbus["ss_basic_smartdns_rule"] = Base64.encode(E("smartdns_chnd_conf").value);
	push_data("ss_conf.sh", "save_smartdns_smrt_" + SMARTDNS_FLAG,  dbus);
}
function reset_smartdns_conf(){
	db_ss["ss_basic_action"] = "23";
	push_data("ss_conf.sh", "reset_smartdns_smrt_" + SMARTDNS_FLAG,  dbus);
}
function restart_smartdns() {
	var dbus_post = {};
	document.getElementById("loading_block3").innerHTML = "重启smartdns进程 ..."
	$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，重启中 ...</font></li>");
	dbus_post["ss_basic_dns_plan"] = E("ss_basic_dns_plan").value;
	dbus_post["ss_basic_smrt"] = E("ss_basic_smrt").value;
	dbus_post["ss_basic_add_ispdns"] = E("ss_basic_add_ispdns").checked ? '1' : '0';
	dbus_post["ss_basic_block_resov"] = E("ss_basic_block_resov").checked ? '1' : '0';
	dbus_post["ss_basic_dns_serverx"] = E("ss_basic_dns_serverx").checked ? '1' : '0';
	if(ws_flag == 1){
		push_data_ws("ss_conf.sh", "restart_smrt",  dbus_post);
	}else{
		push_data("ss_conf.sh", "restart_smrt",  dbus_post);
	}
}
function restart_chinadns() {
	var dbus_post = {};
	document.getElementById("loading_block3").innerHTML = "重启chinadns-ng进程 ..."
	$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，重启中 ...</font></li>");
	var chng_params_input = ["ss_basic_dns_plan", "ss_basic_chng", "ss_basic_chng_china_net_1_typ", "ss_basic_chng_china_udp_1_opt", "ss_basic_chng_china_udp_1_usr", "ss_basic_chng_china_tcp_1_opt", "ss_basic_chng_china_tcp_1_usr", "ss_basic_chng_china_dot_1_opt", "ss_basic_chng_china_dot_1_usr", "ss_basic_chng_china_net_2_typ", "ss_basic_chng_china_udp_2_opt", "ss_basic_chng_china_udp_2_usr", "ss_basic_chng_china_tcp_2_opt", "ss_basic_chng_china_tcp_2_usr", "ss_basic_chng_china_dot_2_opt", "ss_basic_chng_china_dot_2_usr", "ss_basic_chng_china_net_3_typ", "ss_basic_chng_china_udp_3_opt", "ss_basic_chng_china_udp_3_usr", "ss_basic_chng_china_tcp_3_opt", "ss_basic_chng_china_tcp_3_usr", "ss_basic_chng_china_dot_3_opt", "ss_basic_chng_china_dot_3_usr", "ss_basic_chng_trust_net_1_typ", "ss_basic_chng_trust_udp_1_opt", "ss_basic_chng_trust_udp_1_usr", "ss_basic_chng_trust_tcp_1_opt", "ss_basic_chng_trust_tcp_1_usr", "ss_basic_chng_trust_dot_1_opt", "ss_basic_chng_trust_dot_1_usr", "ss_basic_chng_trust_net_2_typ", "ss_basic_chng_trust_udp_2_opt", "ss_basic_chng_trust_udp_2_usr", "ss_basic_chng_trust_tcp_2_opt", "ss_basic_chng_trust_tcp_2_usr", "ss_basic_chng_trust_dot_2_opt", "ss_basic_chng_trust_dot_2_usr", "ss_basic_chng_trust_net_3_typ", "ss_basic_chng_trust_udp_3_opt", "ss_basic_chng_trust_udp_3_usr", "ss_basic_chng_trust_tcp_3_opt", "ss_basic_chng_trust_tcp_3_usr", "ss_basic_chng_trust_dot_3_opt", "ss_basic_chng_trust_dot_3_usr"];
	for (var i = 0; i < chng_params_input.length; i++) {
		dbus_post[chng_params_input[i]] = E(chng_params_input[i]).value;
	}
	var chng_params_check = ["ss_basic_chng_china_dns_1_chk", "ss_basic_chng_china_dns_2_chk", "ss_basic_chng_china_dns_3_chk", "ss_basic_chng_trust_dns_1_chk", "ss_basic_chng_trust_dns_2_chk","ss_basic_chng_trust_dns_3_chk", "ss_basic_chng_ipv6_drop_direc", "ss_basic_chng_ipv6_drop_proxy", "ss_basic_block_resov", "ss_basic_dns_serverx"];
	for (var i = 0; i < chng_params_check.length; i++) {
		dbus_post[chng_params_check[i]] = E(chng_params_check[i]).checked ? '1' : '0';;
	}
	if(ws_flag == 1){
		push_data_ws("ss_conf.sh", "restart_chng",  dbus_post);
	}else{
		push_data("ss_conf.sh", "restart_chng",  dbus_post);
	}
}
function toggleKeyMask(o, show){
	var el = $(o).attr("id");
	//console.log(el)
	if (!el) return;
	if (show){
		$(o).removeClass('fcx-mask');
	} else {
		$(o).addClass('fcx-mask');
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
											  "http://www.163.com",
											  "http://connect.rom.miui.com/generate_204",
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
								var lt_batch = [
											["0", "关闭批量测速"],
											["1", "开启批量测速"]
										   ]
								var lt_time = [["15", "每隔15分钟"], ["20", "每隔20分钟"], ["30", "每隔30分钟"], ["60", "每隔60分钟"]];
								$('#table_test').forms([
									{ title: '延迟测试设置', thead:'1'},
									{ title: '<a onmouseover="mOver(this, 147)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">web延迟测试域名 - 国外</a>', id:'ss_basic_furl', type:'select', style:'width:auto', options:furl, value:''},
									{ title: '<a onmouseover="mOver(this, 148)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">web延迟测试域名 - 国内</a>', id:'ss_basic_curl', type:'select', style:'width:auto', options:curl, value:''},
									{ title: '批量测速开关', id:'ss_basic_latency_batch', type:'select', style:'width:auto', options:lt_batch, value:''},
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
														、<a href="https://github.com/apernet/hysteria" target="_blank"><em><u>Hysteria2</u></em></a>
														八种协议的科学上网工具。
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
											<div id="smartdns_settings" style="box-shadow: 3px 3px 10px #000;margin-top: -65px;position: absolute;-webkit-border-radius: 5px;-moz-border-radius: 5px;border-radius:10px;z-index: 10;background-color:#2B373B;margin-left: -215px;top: 240px;width:980px;return height:auto;box-shadow: 3px 3px 10px #000;background: rgba(0,0,0,0.85);display:none;">
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
																	<span id="ss_state2">国外连接 - Waiting</span>
																	<br/>
																	<span id="ss_state3">国内连接 - Waiting</span>
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
														  			<td width="12.5%" align="center" id="vmessTitle" onclick="tabclickhandler(3);">Vmess节点</td>
														  			<td width="12.5%" align="center" id="vlessTitle" onclick="tabclickhandler(4);">Vless节点</td>
														  			<td width="12.5%" align="center" id="trojanTitle" onclick="tabclickhandler(5);">Trojan节点</td>
														  			<td width="12.5%" align="center" id="naiveTitle" onclick="tabclickhandler(6);">Naïve节点</td>		<!--fancyss-full-->
														  			<td width="12.5%" align="center" id="tuicTitle" onclick="tabclickhandler(7);">tuic节点</td>		<!--fancyss-full-->
														  			<td width="12.5%" align="center" id="hy2Title" onclick="tabclickhandler(8);">hysteria2节点</td>
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
																		{ title: '使用json配置', data:{show:'v2ray_on'}, id:'ss_node_table_v2ray_use_json', type:'checkbox', func:'v', help:'27', value:false},
																		{ title: '使用json配置', data:{show:'xray_on'}, id:'ss_node_table_xray_use_json', type:'checkbox', func:'v', help:'25', value:false},
																		{ title: '节点别名', id:'ss_node_table_name', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '服务器地址', data:{show:'basic_server_on'}, id:'ss_node_table_server', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '服务器端口', data:{show:'basic_server_on'}, id:'ss_node_table_port', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '密码', data:{show:'basic_pass_on'}, id:'ss_node_table_password', type:'text', maxlen:'64', style:'width:400px'},
																		{ title: '加密方式', data:{show:'basic_pass_on'}, id:'ss_node_table_method', type:'select', options:option_method, style:'width:412px', value: "aes-256-cfb"},
																		// ss
																		{ title: '混淆 (obfs)', data:{show:'ss_obfs_allowed'}, id:'ss_node_table_ss_obfs', type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], style:'width:412px', value: "0"},
																		{ title: '混淆主机名 (obfs-host)', data:{show:'ss_obfs_host_on'}, id:'ss_node_table_ss_obfs_host', type:'text', maxlen:'300', style:'width:400px', ph:'bing.com'},
																		// ssr
																		{ title: '协议 (protocol)', data:{show:'ssr_on'}, id:'ss_node_table_rss_protocol', type:'select', func:'v', options:option_protocals, style:'width:412px', value: "0"},
																		{ title: '协议参数 (protocol_param)', data:{show:'ssr_on'}, id:'ss_node_table_rss_protocol_param', type:'text', maxlen:'300', style:'width:400px', ph:'id:password'},
																		{ title: '混淆 (obfs)', data:{show:'ssr_on'}, id:'ss_node_table_rss_obfs', type:'select', func:'v', options:option_obfs, style:'width:412px', value: "0"},
																		{ title: '混淆参数 (obfs_param)', data:{show:'ssr_on'}, id:'ss_node_table_rss_obfs_param', type:'text', maxlen:'300', style:'width:400px', ph:'bing.com'},
																		// v2ray
																		{ title: '<em>服务器配置</em>（以下配置使用vmess作为传出协议，其它传出协议请使用json配置）', class:'v2ray_elem', data:{show:'v2ray_on v_json_off'}, th:'2'},
																		{ title: '用户id (id)', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_uuid', type:'text', maxlen:'300', hint:'49', style:'width:400px'},
																		{ title: '额外ID (Alterld)', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_alterid', type:'text', maxlen:'300', style:'width:400px', value: "0"},
																		{ title: '加密方式 (security)', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_security', type:'select', options:option_v2enc, style:'width:412px', value: "auto"},
																		{ title: '<em>底层传输方式</em>', class:'v2ray_elem', data:{show:'v2ray_on v_json_off'}, th:'2'},
																		{ title: '传输协议 (network)', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_network', type:'select', func:'v', options:["tcp", "kcp", "ws", "h2", "quic", "grpc", "httpupgrade"], style:'width:412px', value: "tcp"},
																		{ title: '* tcp伪装类型 (type)', data:{show:'v2ray_on v_json_off v_net_tcp'}, id:'ss_node_table_v2ray_headtype_tcp', type:'select', func:'v', options:option_headtcp, style:'width:412px', value: "none"},
																		{ title: '* kcp伪装类型 (type)', data:{show:'v2ray_on v_json_off v_net_kcp'}, id:'ss_node_table_v2ray_headtype_kcp', type:'select', func:'v', options:option_headkcp, style:'width:412px', value: "none"},
																		{ title: '* quic伪装类型 (type)', data:{show:'v2ray_on v_json_off v_net_quic'}, id:'ss_node_table_v2ray_headtype_quic', type:'select', options:option_headquic, value: "none"},
																		{ title: '* grpc模式', data:{show:'v2ray_on v_json_off v_net_grpc'}, id:'ss_node_table_v2ray_grpc_mode', type:'select', options:option_grpcmode, value: ""},
																		{ title: '* 伪装域名 (host)', data:{show:'v2ray_on v_json_off v_host_on'}, id:'ss_node_table_v2ray_network_host', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '* 路径 (path)', data:{show:'v2ray_on v_json_off v_path_on'}, id:'ss_node_table_v2ray_network_path', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '* kcp seed', data:{show:'v2ray_on v_json_off v_net_kcp'}, id:'ss_node_table_v2ray_kcp_seed', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '底层传输安全', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"]], style:'width:412px', value: "none"},
																		{ title: '* 跳过证书验证 (AllowInsecure)', data:{show:'v2ray_on v_json_off v_tls_on'}, id:'ss_node_table_v2ray_network_security_ai', type:'checkbox', hint:'56', value: "false"},
																		{ title: '* alpn', data:{show:'v2ray_on v_json_off v_tls_on'}, multi: [
																			{ suffix: '<input type="checkbox" id="ss_node_table_v2ray_network_security_alpn_h2">h2' },
																			{ suffix: '<input type="checkbox" id="ss_node_table_v2ray_network_security_alpn_http">http/1.1' },
																		]},
																		{ title: 'SNI', data:{show:'v2ray_on v_json_off v_tls_on'}, id:'ss_node_table_v2ray_network_security_sni', type:'text'},
																		{ title: '多路复用 (Mux)', data:{show:'v2ray_on v_json_off'}, id:'ss_node_table_v2ray_mux_enable', type:'checkbox', func:'v', value: false},
																		{ title: '* Mux并发连接数', data:{show:'v2ray_on v_json_off v_mux_on'}, id:'ss_node_table_v2ray_mux_concurrency', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: 'v2ray json', data:{show:'v2ray_on v_json_on'}, id:'ss_node_table_v2ray_json', type:'textarea', rows:'32', ph:ph_v2ray, style:'width:400px'},
																		// xray
																		{ title: '<em>服务器配置</em>（以下配置使用vless作为传出协议，其它传出协议请使用json配置）', class:'xray_elem', data:{show:'xray_on x_json_off'}, th:'2'},
																		{ title: '用户id (id)', data:{show:'xray_on x_json_off'}, id:'ss_node_table_xray_uuid', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '加密 (encryption)', data:{show:'xray_on x_json_off'}, id:'ss_node_table_xray_encryption', type:'text', hint:'55', maxlen:'300', style:'width:400px', value: "none"},
																		{ title: 'flow (流控模式，没有请留空)', data:{show:'xray_on x_json_off x_flow_on'}, id:'ss_node_table_xray_flow', type:'select', options:option_xflow, style:'width:412px', value: ""},
																		{ title: '<em>底层传输方式</em>', class:'xray_elem', data:{show:'xray_on x_json_off'}, th:'2'},
																		{ title: '传输协议 (network)', data:{show:'xray_on x_json_off'}, id:'ss_node_table_xray_network', type:'select', func:'v', options:["tcp", "kcp", "ws", "h2", "quic", "grpc", "httpupgrade", "xhttp"], style:'width:412px', value: "tcp"},
																		{ title: '* tcp伪装类型 (type)', data:{show:'xray_on x_json_off x_net_tcp'}, id:'ss_node_table_xray_headtype_tcp', type:'select', hint:'36', func:'v', options:option_headtcp, style:'width:412px', value: "none"},
																		{ title: '* 伪装类型 (type)', data:{show:'xray_on x_json_off x_net_kcp'}, id:'ss_node_table_xray_headtype_kcp', type:'select', func:'v', options:option_headkcp, style:'width:412px', value: "none"},
																		{ title: '* quic伪装类型 (type)', data:{show:'xray_on x_json_off x_net_quic'}, id:'ss_node_table_xray_headtype_quic', type:'select', options:option_headquic, value: "none"},
																		{ title: '* grpc模式', data:{show:'xray_on x_json_off x_net_grpc'}, id:'ss_node_table_xray_grpc_mode', type:'select', options:option_grpcmode, value: "multi"},
																		{ title: '* xhttp模式', data:{show:'xray_on x_json_off x_xhttp_on'}, id:'ss_node_table_xray_xhttp_mode', type:'select', options:option_xhttpmode, value: "auto"},
																		{ title: '* 伪装域名 (host)', data:{show:'xray_on x_json_off x_host_on'}, id:'ss_node_table_xray_network_host', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '* 路径 (path)', data:{show:'xray_on x_json_off x_path_on'}, id:'ss_node_table_xray_network_path', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '* kcp seed', data:{show:'xray_on x_json_off x_net_kcp'}, id:'ss_node_table_xray_kcp_seed', type:'text', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: '底层传输安全', data:{show:'xray_on x_json_off'}, id:'ss_node_table_xray_network_security', type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"], ["reality", "reality"]], style:'width:412px', value: "none"},
																		{ title: '* 跳过证书验证 (AllowInsecure)', data:{show:'xray_on x_json_off x_tls_on'}, id:'ss_node_table_xray_network_security_ai', type:'checkbox', func:'v', hint:'56', value: "false"},
																		{ title: '* pinnedPeerCertSha256', data:{show:'xray_on x_json_off x_tls_on x_ai_off'}, id:'ss_node_table_xray_pcs', type:'text', style:'width:400px', ph:'没有请留空'},
																		{ title: '* verifyPeerCertByName', data:{show:'xray_on x_json_off x_tls_on x_ai_off'}, id:'ss_node_table_xray_vcn', type:'text', style:'width:400px', ph:'没有请留空'},
																		{ title: '* alpn', data:{show:'xray_on x_json_off x_tls_on'}, multi: [
																			{ suffix: '<input type="checkbox" id="ss_node_table_xray_network_security_alpn_h2">h2' },
																			{ suffix: '<input type="checkbox" id="ss_node_table_xray_network_security_alpn_http">http/1.1' },
																		]},
																		{ title: '* show', data:{show:'xray_on x_json_off x_real_on'}, id:'ss_node_table_xray_show', type:'checkbox', value:false},
																		{ title: '* fingerprint', data:{show:'xray_on x_json_off', showAny:'x_tls_on x_real_on'}, id:'ss_node_table_xray_fingerprint', type:'select', options:option_fingerprint, value: ""},
																		{ title: '* SNI', data:{show:'xray_on x_json_off', showAny:'x_tls_on x_real_on'}, id:'ss_node_table_xray_network_security_sni', type:'text'},
																		{ title: '* publicKey', data:{show:'xray_on x_json_off x_real_on'}, id:'ss_node_table_xray_publickey', maxlen:'300', style:'width:400px', type:'text'},
																		{ title: '* shortId', data:{show:'xray_on x_json_off x_real_on'}, id:'ss_node_table_xray_shortid', type:'text', style:'width:400px', ph:'没有请留空'},
																		{ title: '* spiderX', data:{show:'xray_on x_json_off x_real_on'}, id:'ss_node_table_xray_spiderx', type:'text', ph:'没有请留空'},
																		{ title: 'xray json', data:{show:'xray_on x_json_on'}, id:'ss_node_table_xray_json', type:'textarea', rows:'32', ph:ph_xray, style:'width:400px'},
																		// trojan
																		{ title: 'trojan 密码', data:{show:'trojan_on'}, id:'ss_node_table_trojan_uuid', type:'text', maxlen:'300', style:'width:400px'},
																		{ title: '跳过证书验证 (AllowInsecure)', data:{show:'trojan_on'}, id:'ss_node_table_trojan_ai', type:'checkbox', func:'v', value: "false"},
																		{ title: 'pinnedPeerCertSha256', data:{show:'trojan_on trojan_ai_off'}, id:'ss_node_table_trojan_pcs', type:'text', style:'width:400px'},
																		{ title: 'verifyPeerCertByName', data:{show:'trojan_on trojan_ai_off'}, id:'ss_node_table_trojan_vcn', type:'text', style:'width:400px'},
																		{ title: 'SNI', data:{show:'trojan_on'}, id:'ss_node_table_trojan_sni', type:'text', style:'width:400px'},
																		{ title: 'tcp fast open', data:{show:'trojan_on'}, id:'ss_node_table_trojan_tfo', type:'checkbox', value: "false"},
																		// naive
																		{ title: 'NaïveProxy 协议', data:{show:'naive_on'}, id:'ss_node_table_naive_prot', type:'select', func:'v', options:option_naive_prot, maxlen:'300', style:'width:412px', value: "https"},		//fancyss-full
																		{ title: 'NaïveProxy 服务器', data:{show:'naive_on'}, id:'ss_node_table_naive_server', type:'text', maxlen:'300', style:'width:400px'},														//fancyss-full
																		{ title: 'NaïveProxy 端口', data:{show:'naive_on'}, id:'ss_node_table_naive_port', type:'text', maxlen:'300', style:'width:400px', value: "443"},												//fancyss-full
																		{ title: 'NaïveProxy 账户', data:{show:'naive_on'}, id:'ss_node_table_naive_user', type:'text', maxlen:'300', style:'width:400px'},															//fancyss-full
																		{ title: 'NaïveProxy 密码', data:{show:'naive_on'}, id:'ss_node_table_naive_pass', type:'text', maxlen:'300', style:'width:400px'},															//fancyss-full
																		// tuic
																		{ title: 'tuic client json', data:{show:'tuic_on'}, id:'ss_node_table_tuic_json', type:'textarea', rows:'18', ph:ph_tuic, style:'width:400px'},												//fancyss-full
																		// hy2
																		{ title: '服务器', data:{show:'hy2_on'}, id:'ss_node_table_hy2_server', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},
																		{ title: '端口', data:{show:'hy2_on'}, id:'ss_node_table_hy2_port', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: "443"},
																		{ title: '认证密码', data:{show:'hy2_on'}, id:'ss_node_table_hy2_pass', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},
																		{ title: '最大上行（mbps）', data:{show:'hy2_on'}, id:'ss_node_table_hy2_up', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: ""},
																		{ title: '最大下行（mbps）', data:{show:'hy2_on'}, id:'ss_node_table_hy2_dl', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', value: ""},
																		{ title: 'tcp fast open', data:{show:'hy2_on'}, id:'ss_node_table_hy2_tfo', type:'checkbox', class:'hy2_elem', value: "false"},
																		{ title: '混淆类型', data:{show:'hy2_on'}, id:'ss_node_table_hy2_obfs', type:'select', class:'hy2_elem', func:'v', options:option_hy2_obfs, maxlen:'300', style:'width:412px', value: "0"},
																		{ title: '混淆密码', data:{show:'hy2_on hy2_obfs_on'}, id:'ss_node_table_hy2_obfs_pass', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},
																		{ title: 'SNI（域名）', data:{show:'hy2_on'}, id:'ss_node_table_hy2_sni', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px'},
																		{ title: '允许不安全', data:{show:'hy2_on'}, id:'ss_node_table_hy2_ai', type:'checkbox', func:'v', class:'hy2_elem', value: "false"},
																		{ title: 'pinnedPeerCertSha256', data:{show:'hy2_on hy2_ai_off'}, id:'ss_node_table_hy2_pcs', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: 'verifyPeerCertByName', data:{show:'hy2_on hy2_ai_off'}, id:'ss_node_table_hy2_vcn', type:'text', class:'hy2_elem', maxlen:'300', style:'width:400px', ph:'没有请留空'},
																		{ title: 'congestion', data:{show:'hy2_on'}, id:'ss_node_table_hy2_cg', type:'select', class:'hy2_elem', func:'v', options:option_hy2_cg, maxlen:'300', style:'width:412px', value: "brutal"},
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
															{ title: '使用json配置', id:'ss_basic_v2ray_use_json', data:{show:'v2ray_on'}, type:'checkbox', func:'v', hint:'27'},
															{ title: '使用json配置', id:'ss_basic_xray_use_json', data:{show:'xray_on'}, type:'checkbox', func:'v', hint:'27'},
															{ title: '服务器地址', id:'ss_basic_server', data:{show:'basic_server_on'}, type:'text', maxlen:'100'},
															{ title: '服务器端口', id:'ss_basic_port', data:{show:'basic_server_on'}, type:'text', maxlen:'100'},
															{ title: '密码', id:'ss_basic_password', data:{show:'basic_pass_on'}, type:'password', maxlen:'100', peekaboo:'1'},
															{ title: '加密方式', id:'ss_basic_method', data:{show:'basic_pass_on'}, type:'select', func:'v', options:option_method},
															// ss
															{ title: '混淆 (obfs)', id:'ss_basic_ss_obfs', data:{show:'ss_on'}, type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], value: "0"},
															{ title: '混淆主机名 (obfs_host)', id:'ss_basic_ss_obfs_host', data:{show:'ss_obfs_host_on'}, type:'text', maxlen:'100', ph:'bing.com'},
															// ssr
															{ title: '协议 (protocol)', id:'ss_basic_rss_protocol', data:{show:'ssr_on'}, type:'select', func:'v', options:option_protocals},
															{ title: '协议参数 (protocol_param)', id:'ss_basic_rss_protocol_param', data:{show:'ssr_on'}, type:'password', hint:'54', maxlen:'100', ph:'id:password', peekaboo:'1'},
															{ title: '混淆 (obfs)', id:'ss_basic_rss_obfs', data:{show:'ssr_on'}, type:'select', func:'v', options:option_obfs},
															{ title: '混淆参数 (obfs_param)', id:'ss_basic_rss_obfs_param', data:{show:'ssr_on'}, type:'text', hint:'11', maxlen:'300', ph:'cloudflare.com;bing.com'},
															// v2ray
															{ title: '用户id (id)', id:'ss_basic_v2ray_uuid', data:{show:'v2ray_on v_json_off'}, type:'password', hint:'49', maxlen:'300', style:'width:300px;', peekaboo:'1'},
															{ title: '额外ID (Alterld)', id:'ss_basic_v2ray_alterid', data:{show:'v2ray_on v_json_off'}, type:'text', hint:'48', maxlen:'50'},
															{ title: '加密方式 (security)', id:'ss_basic_v2ray_security', data:{show:'v2ray_on v_json_off'}, type:'select', hint:'47', options:option_v2enc},
															{ title: '传输协议 (network)', id:'ss_basic_v2ray_network', data:{show:'v2ray_on v_json_off'}, type:'select', func:'v', hint:'35', options:["tcp", "kcp", "ws", "h2", "quic", "grpc", "httpupgrade"]},
															{ title: '* tcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_tcp', data:{show:'v2ray_on v_json_off v_net_tcp'}, type:'select', func:'v', hint:'36', options:option_headtcp},
															{ title: '* kcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_kcp', data:{show:'v2ray_on v_json_off v_net_kcp'}, type:'select', func:'v', hint:'37', options:option_headkcp},
															{ title: '* quic伪装类型 (type)', id:'ss_basic_v2ray_headtype_quic', data:{show:'v2ray_on v_json_off v_net_quic'}, type:'select', options:option_headquic},
															{ title: '* grpc模式', id:'ss_basic_v2ray_grpc_mode', data:{show:'v2ray_on v_json_off v_net_grpc'}, type:'select', options:option_grpcmode},
															{ title: '* 伪装域名 (host)', id:'ss_basic_v2ray_network_host', data:{show:'v2ray_on v_json_off v_host_on'}, type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '* 路径 (path)', rid:'ss_basic_v2ray_network_path_tr', id:'ss_basic_v2ray_network_path', data:{show:'v2ray_on v_json_off v_path_on'}, type:'text', hint:'29', maxlen:'300', ph:'没有请留空'},
															{ title: '* kcp seed', id:'ss_basic_v2ray_kcp_seed', data:{show:'v2ray_on v_json_off v_net_kcp'}, type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '底层传输安全', id:'ss_basic_v2ray_network_security', data:{show:'v2ray_on v_json_off'}, type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"]]},
															{ title: '* 跳过证书验证 (AllowInsecure)', id:'ss_basic_v2ray_network_security_ai', data:{show:'v2ray_on v_json_off v_tls_on'}, type:'checkbox', hint:'56'},
															{ title: '* alpn', id:'ss_basic_v2ray_network_security_alpn', data:{show:'v2ray_on v_json_off v_tls_on'}, multi: [
																{ suffix: '<input type="checkbox" id="ss_basic_v2ray_network_security_alpn_h2">h2' },
																{ suffix: '<input type="checkbox" id="ss_basic_v2ray_network_security_alpn_http">http/1.1' },
															]},
															{ title: '* SNI', id:'ss_basic_v2ray_network_security_sni', data:{show:'v2ray_on v_json_off v_tls_on'}, type:'text'},
															{ title: '多路复用 (Mux)', id:'ss_basic_v2ray_mux_enable', data:{show:'v2ray_on v_json_off'}, type:'checkbox', func:'v', hint:'31'},
															{ title: 'Mux并发连接数', id:'ss_basic_v2ray_mux_concurrency', data:{show:'v2ray_on v_json_off v_mux_on'}, type:'text', hint:'32', maxlen:'300'},
															{ title: 'v2ray json', id:'ss_basic_v2ray_json', data:{show:'v2ray_on v_json_on'}, type:'textarea', rows:'36', ph:ph_v2ray},
															// xray
															{ title: '用户id (id)', id:'ss_basic_xray_uuid', data:{show:'xray_on x_json_off'}, type:'password', hint:'49', maxlen:'300', style:'width:300px;', peekaboo:'1'},
															{ title: '加密 (encryption)', id:'ss_basic_xray_encryption', data:{show:'xray_on x_json_off'}, type:'text', hint:'55', maxlen:'50'},
															{ title: 'flow (流控模式，没有请留空)', id:'ss_basic_xray_flow', data:{show:'xray_on x_json_off x_flow_on'}, type:'select', options:option_xflow},
															{ title: '传输协议 (network)', id:'ss_basic_xray_network', data:{show:'xray_on x_json_off'}, type:'select', func:'v', hint:'35', options:["tcp", "kcp", "ws", "h2", "quic", "grpc", "httpupgrade", "xhttp"]},
															{ title: '* tcp伪装类型 (type)', id:'ss_basic_xray_headtype_tcp', data:{show:'xray_on x_json_off x_net_tcp'}, type:'select', func:'v', hint:'36', options:option_headtcp},
															{ title: '* kcp伪装类型 (type)', id:'ss_basic_xray_headtype_kcp', data:{show:'xray_on x_json_off x_net_kcp'}, type:'select', func:'v', hint:'37', options:option_headkcp},
															{ title: '* quic伪装类型 (type)', id:'ss_basic_xray_headtype_quic', data:{show:'xray_on x_json_off x_net_quic'}, type:'select', options:option_headquic},
															{ title: '* grpc模式', id:'ss_basic_xray_grpc_mode', data:{show:'xray_on x_json_off x_net_grpc'}, type:'select', options:option_grpcmode},
															{ title: '* xhttp模式', id:'ss_basic_xray_xhttp_mode', data:{show:'xray_on x_json_off x_xhttp_on'}, type:'select', options:option_xhttpmode, value: "auto"},
															{ title: '* 伪装域名 (host)', id:'ss_basic_xray_network_host', data:{show:'xray_on x_json_off x_host_on'}, type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '* 路径 (path)', rid:'ss_basic_xray_network_path_tr', id:'ss_basic_xray_network_path', data:{show:'xray_on x_json_off x_path_on'}, type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '* kcp seed', id:'ss_basic_xray_kcp_seed', data:{show:'xray_on x_json_off x_net_kcp'}, type:'text', maxlen:'300', ph:'没有请留空'},
															{ title: '底层传输安全', id:'ss_basic_xray_network_security', data:{show:'xray_on x_json_off'}, type:'select', func:'v', options:[["none", "关闭"], ["tls", "tls"], ["reality", "reality"]]},
															{ title: '* 跳过证书验证 (AllowInsecure)', id:'ss_basic_xray_network_security_ai', data:{show:'xray_on x_json_off x_tls_on'}, type:'checkbox', func:'v', hint:'56'},
															{ title: '* pinnedPeerCertSha256', id:'ss_basic_xray_pcs', data:{show:'xray_on x_json_off x_tls_on x_ai_off'}, type:'text', style:'width:440px', ph:'没有请留空'},
															{ title: '* verifyPeerCertByName', id:'ss_basic_xray_vcn', data:{show:'xray_on x_json_off x_tls_on x_ai_off'}, type:'text', ph:'没有请留空'},
															{ title: '* alpn', id:'ss_basic_xray_network_security_alpn', data:{show:'xray_on x_json_off x_tls_on'}, multi: [
																{ suffix: '<input type="checkbox" id="ss_basic_xray_network_security_alpn_h2">h2' },
																{ suffix: '<input type="checkbox" id="ss_basic_xray_network_security_alpn_http">http/1.1' },
															]},
															{ title: '* show', id:'ss_basic_xray_show', data:{show:'xray_on x_json_off x_real_on'}, type:'checkbox'},
															{ title: '* fingerprint', id:'ss_basic_xray_fingerprint', data:{show:'xray_on x_json_off', showAny:'x_tls_on x_real_on'}, type:'select', options:option_fingerprint},
															{ title: '* SNI', id:'ss_basic_xray_network_security_sni', data:{show:'xray_on x_json_off', showAny:'x_tls_on x_real_on'}, type:'text', ph:'realitySettings中的serverName'},
															{ title: '* publickey', id:'ss_basic_xray_publickey', data:{show:'xray_on x_json_off x_real_on'}, type:'password', maxlen:'300', style:'width:320px;', ph:'填写公钥', peekaboo:'1'},
															{ title: '* shortId', id:'ss_basic_xray_shortid', data:{show:'xray_on x_json_off x_real_on'}, type:'text', ph:'没有请留空'},
															{ title: '* spiderX', id:'ss_basic_xray_spiderx', data:{show:'xray_on x_json_off x_real_on'}, type:'text', ph:'没有请留空'},
															{ title: 'xray json', id:'ss_basic_xray_json', data:{show:'xray_on x_json_on'}, type:'textarea', rows:'36', ph:ph_xray},
															{ title: '其它', rid:'xray_binary_update_tr', data:{show:'xray_on'}, prefix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="xray_binary_update(2)">更新xray程序</a>'},
															//trojan
															{ title: 'trojan 密码', id:'ss_basic_trojan_uuid', data:{show:'trojan_on'}, type:'password', maxlen:'300', style:'width:280px;', peekaboo:'1'},
															{ title: '跳过证书验证 (AllowInsecure)', id:'ss_basic_trojan_ai', data:{show:'trojan_on'}, type:'checkbox', func:'v'},
															{ title: 'pinnedPeerCertSha256', id:'ss_basic_trojan_pcs', data:{show:'trojan_on trojan_ai_off'}, type:'text', style:'width:440px', ph:'没有请留空'},
															{ title: 'verifyPeerCertByName', id:'ss_basic_trojan_vcn', data:{show:'trojan_on trojan_ai_off'}, type:'text', ph:'没有请留空'},
															{ title: 'SNI', id:'ss_basic_trojan_sni', data:{show:'trojan_on'}, type:'text'},
															{ title: 'tcp fast open', id:'ss_basic_trojan_tfo', data:{show:'trojan_on'}, type:'checkbox'},
															// naive
															{ title: 'NaïveProxy 协议', id:'ss_basic_naive_prot', data:{show:'naive_on'}, type:'select', func:'v', options:option_naive_prot, maxlen:'300', value: "https"},								//fancyss-full
															{ title: 'NaïveProxy 服务器', id:'ss_basic_naive_server', data:{show:'naive_on'}, type:'text', maxlen:'300'},																					//fancyss-full
															{ title: 'NaïveProxy 端口', id:'ss_basic_naive_port', data:{show:'naive_on'}, type:'text', maxlen:'300', value: "443"},																			//fancyss-full
															{ title: 'NaïveProxy 账户', id:'ss_basic_naive_user', data:{show:'naive_on'}, type:'text', maxlen:'300'},																						//fancyss-full
															{ title: 'NaïveProxy 密码', id:'ss_basic_naive_pass', data:{show:'naive_on'}, type:'text', maxlen:'300'},																						//fancyss-full
															//tuic
															{ title: 'tuic json', id:'ss_basic_tuic_json', data:{show:'tuic_on'}, type:'textarea', rows:'18', ph:ph_tuic},																					//fancyss-full
															//hysteria2
															{ title: '服务器', id:'ss_basic_hy2_server', data:{show:'hy2_on'}, type:'text', maxlen:'300'},
															{ title: '端口', id:'ss_basic_hy2_port', data:{show:'hy2_on'}, type:'text', maxlen:'300'},
															{ title: '认证密码', id:'ss_basic_hy2_pass', data:{show:'hy2_on'}, type:'text', maxlen:'300'},
															{ title: '最大上行（mbps）', id:'ss_basic_hy2_up', data:{show:'hy2_on'}, type:'text', maxlen:'300'},
															{ title: '最大下行（mbps）', id:'ss_basic_hy2_dl', data:{show:'hy2_on'}, type:'text', maxlen:'300'},
															{ title: 'tcp fast open', id:'ss_basic_hy2_tfo', data:{show:'hy2_on'}, type:'checkbox'},
															{ title: '混淆类型', id:'ss_basic_hy2_obfs', data:{show:'hy2_on'}, type:'select', func:'v', options:option_hy2_obfs, maxlen:'300', value: "0"},
															{ title: '混淆密码', id:'ss_basic_hy2_obfs_pass', data:{show:'hy2_on hy2_obfs_on'}, type:'text', maxlen:'300'},
															{ title: 'SNI（域名）', id:'ss_basic_hy2_sni', data:{show:'hy2_on'}, type:'text'},
															{ title: '允许不安全', id:'ss_basic_hy2_ai', data:{show:'hy2_on'}, type:'checkbox', func:'v'},
															{ title: 'pinnedPeerCertSha256', id:'ss_basic_hy2_pcs', data:{show:'hy2_on hy2_ai_off'}, type:'text', style:'width:440px', ph:'没有请留空'},
															{ title: 'verifyPeerCertByName', id:'ss_basic_hy2_vcn', data:{show:'hy2_on hy2_ai_off'}, type:'text', ph:'没有请留空'},
															{ title: 'congestion', id:'ss_basic_hy2_cg', data:{show:'hy2_on'}, type:'select', func:'v', options:option_hy2_cg, maxlen:'300', value: "brutal"},
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
												<div id="ss_dns_table"></div>
												<table id="table_dns" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
													option_dnsp = [
																  ["1", "chinadns-ng"]
																  ,["2", "smartdns"]
																  ];
														// 节点域名解析DNS方案： udp选项
														option_server_resolve = [
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
																			 ["99", "自定义DNS (udp)"]
																			 ];
														option_domain_for_dig = [
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
																			 ["group", "自定义域名"],
																			 ["99", "自定义域名"]
																			 ];
														option_smrt = [
																	   ["1", "1：【国内优先】"],
																	   ["2", "2：【国外优先】"],
																	   ["3", "3：【智能判断】"],
																	   ["4", "4：【自定义配置1】"],
																	   ["5", "5：【自定义配置2】"],
																	   ["5", "5：【自定义配置3】"],
																	  ];
														option_chng = [
																	   ["1", "1：【国内优先】"],
																	   ["2", "2：【国外优先】"],
																	   ["3", "3：【智能判断】"],
																	  ];
														var ph1 = "需端口号如：8.8.8.8:53";
														var ph3 = "# 填入自定义的dnsmasq设置，一行一个&#10;# 例如hosts设置：&#10;address=/weibo.com/2.2.2.2&#10;# 防DNS劫持设置：&#10;bogus-nxdomain=220.250.64.18"
														$('#table_dns').forms([
															// new_dns: chinadns-ng
															{ title: '<em>DNS设置</em>', th:'2'},
															{ title: '选择DNS主方案', class:'new_dns_main', multi: [
																{ id: 'ss_basic_dns_plan', type:'select', func:'u', options:option_dnsp, style:'width:120px;', value:'1'},
																{ suffix: '&nbsp;&nbsp;'}
															]},
															{ title: '&nbsp;&nbsp;*选择chinadns-ng配置', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng', type:'select', func:'u', options:option_chng, style:'width:209px;', value:'3'},
															]},
															{ title: '&nbsp;&nbsp;*中国DNS-1 <em>(直连) 🎯</em>', hint:'133', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_china_dns_1_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_china_net_1_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'udp'},
																{ id: 'ss_basic_chng_china_udp_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_udp_1_usr', type:'text', style:'width:120px;', ph:'114.114.114.114', value:'114.114.114.114' },
																{ id: 'ss_basic_chng_china_tcp_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_tcp_1_usr', type:'text', style:'width:120px;', ph:'114.114.114.114', value:'114.114.114.114' },
																{ id: 'ss_basic_chng_china_dot_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_dot_1_usr', type:'text', style:'width:180px;', ph:'dot.pub@1.12.12.21', value:'dot.pub@1.12.12.21' },
																{ suffix:'&nbsp;&nbsp;'},
															]},
															{ title: '&nbsp;&nbsp;*中国DNS-2 <em>(直连) 🎯</em>', hint:'133', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_china_dns_2_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_china_net_2_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'tcp'},
																{ id: 'ss_basic_chng_china_udp_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_udp_2_usr', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_tcp_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_tcp_2_usr', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_dot_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_dot_2_usr', type: 'text', style:'width:180px;', ph:'dot.pub@1.12.12.21', value:'dot.pub@1.12.12.21' },
																{ suffix:'&nbsp;&nbsp;'},
															]},
															{ title: '&nbsp;&nbsp;*中国DNS-3 <em>(直连) 🎯</em>', hint:'133', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_china_dns_3_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_china_net_3_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'dot'},
																{ id: 'ss_basic_chng_china_udp_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_udp_3_usr', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_tcp_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_tcp_3_usr', type: 'text', style:'width:120px;', ph:'114.114.115.115', value:'114.114.115.115' },
																{ id: 'ss_basic_chng_china_dot_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_china_dot_3_usr', type: 'text', style:'width:180px;', ph:'dot.pub@1.12.12.21', value:'dot.pub@1.12.12.21' },
																{ suffix:'&nbsp;&nbsp;'},
															]},
															{ title: '&nbsp;&nbsp;*可信DNS-1 <font color="#FF0066">(代理) 🚀</font>', hint:'134', class:'new_dns chng', multi: [
																{ id: 'ss_basic_chng_trust_dns_1_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_trust_net_1_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'tcp'},
																{ id: 'ss_basic_chng_trust_udp_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_udp_1_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_tcp_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_tcp_1_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_dot_1_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_dot_1_usr', type: 'text', style:'width:180px;', value:'one.one.one.one@1.1.1.1', ph:'one.one.one.one@1.1.1.1' },
																{ suffix: '&nbsp;&nbsp;'},
															]},
															{ title: '&nbsp;&nbsp;*可信DNS-2 <font color="#FF0066">(代理) 🚀</font>', class:'new_dns chng', hint:'134', multi: [
																{ id: 'ss_basic_chng_trust_dns_2_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_trust_net_2_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'tcp'},
																{ id: 'ss_basic_chng_trust_udp_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_udp_2_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_tcp_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_tcp_2_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_dot_2_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_dot_2_usr', type: 'text', style:'width:180px;', value:'one.one.one.one@1.1.1.1', ph:'one.one.one.one@1.1.1.1' },
																{ suffix: '&nbsp;&nbsp;'},
															]},
															{ title: '&nbsp;&nbsp;*可信DNS-3 <font color="#FF0066">(代理) 🚀</font>', class:'new_dns chng', hint:'134', multi: [
																{ id: 'ss_basic_chng_trust_dns_3_chk', type:'checkbox', func:'u', value:true},
																{ id: 'ss_basic_chng_trust_net_3_typ', type:'select', func:'u', options:["udp", "tcp", "dot"], style:'width:50px;', value:'dot'},
																{ id: 'ss_basic_chng_trust_udp_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_udp_3_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_tcp_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_tcp_3_usr', type: 'text', style:'width:120px;', value:'8.8.8.8:53', ph:ph1 },
																{ id: 'ss_basic_chng_trust_dot_3_opt', type:'select', func:'u', options:[], style:'width:auto;'},
																{ id: 'ss_basic_chng_trust_dot_3_usr', type: 'text', style:'width:180px;', value:'one.one.one.one@1.1.1.1', ph:'one.one.one.one@1.1.1.1' },
																{ suffix: '&nbsp;&nbsp;'},
															]},	
															{ title: '&nbsp;&nbsp;*过滤AAAA记录（--no-ipv6）', class:'new_dns chng', hint:'145', multi: [
																{ id: 'ss_basic_chng_ipv6_drop_direc', type:'checkbox', func:'u', value:false},
																{ suffix: '<a>过滤直连</a>' },
																{ suffix: '&nbsp;&nbsp;'},
																{ id: 'ss_basic_chng_ipv6_drop_proxy', type:'checkbox', func:'u', value:true},
																{ suffix: '<a>过滤代理</a>' },
															]},
															//{ title: '发送重复DNS查询包（--repeat-times）', class:'new_dns chng', id:'ss_basic_chng_dns_query_times', type:'text', value: '1'},
															{ title: '&nbsp;&nbsp;*选择smartdns配置', class:'new_dns smrt', multi: [
																{ id: 'ss_basic_smrt', type:'select', func:'u', options:option_smrt, style:'width:209px;', value:'1'},
																{ suffix: '&nbsp;&nbsp;'},
																{ suffix: '<a type="button" id="edit_smartdns_conf" class="ss_btn" style="cursor:pointer" onclick="edit_smartdns_conf()">编辑smartdns配置</a>'},
															]},
															{ title: '&nbsp;&nbsp;*追加ISP DNS', id:'ss_basic_add_ispdns', type:'checkbox', hint:'151', class:'new_dns smrt', value:true},
															{ title: '&nbsp;&nbsp;*屏蔽BlockList域名解析', id:'ss_basic_block_resov', type:'checkbox', hint:'104', func:'u', value:false},
															{ title: '&nbsp;&nbsp;*替换dnsmasq(实验特性)', id:'ss_basic_dns_serverx', type:'checkbox', hint:'105', func:'u', value:false},
															//{ title: '&nbsp;&nbsp;*重启chinadns-ng', rid: 'restart_chinadns', class:'new_dns chng', multi: [	
															//	{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="restart_chinadns()">重启chinadns-ng</a>'},
															//]},	
															//{ title: '&nbsp;&nbsp;*重启smartdns', rid: 'restart_smartdns', class:'new_dns smrt', multi: [	
															//	{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="restart_smartdns()">重启smartdns</a>'},
															//]},	
															{ title: '<em>其它DNS相关设置</em>', th:'2'},
															{ title: 'DNS重定向', id:'ss_basic_dns_hijack', type:'checkbox', hint:'106', value:true},
															{ title: 'DNS解析测试', rid: 'ss_dns_test', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(1)">测试cdn</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(2)">测试apple china</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(3)">测试google china</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(4)">测试gfwlist</a>&nbsp;&nbsp;'},
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(5)">测试chnlist</a>&nbsp;&nbsp;'},
															]},
															{ title: 'DNS解析测试(dig)', rid: 'ss_dig_test', multi: [
																{ id: 'ss_basic_dig_opt', type:'select', func:'u', options:option_domain_for_dig, style:'width:240px;', value:'1'},
																{ id: 'ss_basic_dig_opt_usr', type: 'text', style:'width:145px;', ph:'输入域名', value:''},
																{ suffix: '&nbsp;&nbsp;' },
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="dns_test(6)">dig</a>&nbsp;&nbsp;'},
															]},
															{ title: '重启dnsmasq', rid: 'ss_dnsmasq_restart', multi: [	
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="restart_dnsmaq()">重启dnsmasq</a>'},
															]},	
															// server dns resolver
																{ title: '节点域名解析DNS方案', hint:'107', multi: [
																	{ id: 'ss_basic_server_resolv', type:'select', func:'u', options:option_server_resolve, style:'width:160px;', value:'-1'},
																	{ id: 'ss_basic_server_resolv_user', type: 'text', style:'width:145px;', ph:'176.103.130.130:5353', value:'176.103.130.130:5353'},
																]},
																{ title: '自定义dnsmasq', rid: 'ss_dnsmasq_cus', id:'ss_dnsmasq', type:'textarea', hint:'34', rows:'12', ph:ph3},
															]);
															// chinadns-ng preset DNS servers moved to /res/dns_servers.json.js

														var isp_dns_raw='<% nvram_get("wan0_dns"); %>';
														if(!isp_dns_raw){
															var isp_dns_raw='<% nvram_get("wan0_dns_r"); %>';
														}
														if(!isp_dns_raw){
															var isp_dns_raw='<% nvram_get("wan_dns"); %>';
														}
														if(!isp_dns_raw){
															var isp_dns_raw='<% nvram_get("wan0_xdns"); %>';
														}
														if(!isp_dns_raw){
															var isp_dns_raw="223.5.5.5 223.6.6.6";
														}
														var isp_dns_1=isp_dns_raw.split(" ")[0];
														var isp_dns_2=isp_dns_raw.split(" ")[1];
														validator.ipv4_addr(isp_dns_1);
														if(isp_dns_1 && isp_dns_2){
															var ispDNS = {
																ipv4: [
																	{ addr: isp_dns_1, description: "主用DNS" },
																	{ addr: isp_dns_2, description: "备用DNS" }
																]
															};
														}else if(isp_dns_1 && !isp_dns_2){
															var ispDNS = {
																ipv4: [
																	{ addr: isp_dns_1, description: "主用DNS" }
																]
															};
														}else{
															var ispDNS = {
																ipv4: [
																	{ addr: "223.5.5.5", description: "备用DNS" }
																]
															};
														}
														const ispDnsSelectors = new Set([
														  'ss_basic_chng_china_udp_1_opt',
														  'ss_basic_chng_china_udp_2_opt',
														  'ss_basic_chng_china_udp_3_opt'
														]);
														function addISPdns(select, netType) {
															// 获取对应的IP版本
															const version = netType === 'all' ? 'ipv4' : netType; // 根据实际情况调整
															
															// 创建optgroup容器
															const group = document.createElement('optgroup');
															group.label = '运营商DNS';
															
															// 填充选项
															(ispDNS[version] || []).forEach(server => {
																const option = document.createElement('option');
																option.value = server.addr;
																option.textContent = `${server.addr}${server.description ? ` (${server.description})` : ''}`;
																group.appendChild(option);
															});
														
															// 插入到现有内容最前部
															if (group.children.length > 0) {
																select.insertBefore(group, select.firstChild);
															}
														}
														
														// 协议筛选器（类型统一为数字）
														const protocolFilters = {
															udp: type => [1, 3].includes(type),
															tcp: type => [2, 3].includes(type),
															dot: type => type === 4
														};
														
														function buildOptions(dnsdata, protocol, netType) {
															const fragment = document.createDocumentFragment();
															
															Object.entries(dnsdata).forEach(([provider, servers]) => {
															const group = document.createElement('optgroup');
															group.label = provider;
															
															servers.forEach(server => {
																if (protocolFilters[protocol](server.type) && (netType === 'all' || server.net === netType)) {
																	const option = document.createElement('option');
																	
																	option.value = server.addr;
																	
																	// 构建描述文本
																	let desc = [
																	  server.addr,
																	  //server.net.toUpperCase(),
																	  server.description
																	  //server.type === 3 ? 'UDP+TCP' : '',
																	  //server.type === 4 ? 'DoT' : ''
																	].filter(Boolean).join(' - ');
																	
																	option.textContent = desc;
																	group.appendChild(option);
																}
															});
														
															if (group.children.length > 0) {
																fragment.appendChild(group);
															}
															});
															return fragment;
														}
														
														function addCustomDNS(select) {
															// 创建自定义分组
															const customGroup = document.createElement('optgroup');
															customGroup.label = '自定义DNS';
															
															const customOption = document.createElement('option');
															customOption.value = '99';
															customOption.textContent = '自定义DNS';
															
															customGroup.appendChild(customOption);
															select.appendChild(customGroup);
														}
														
														function populateSelect(selectorId, dnsdata, protocol, netType) {
															const select = document.getElementById(selectorId);
															select.innerHTML = '';
															
															// 1. 插入运营商DNS（最顶部）
															if (ispDnsSelectors.has(selectorId)) {
																addISPdns(select, netType);
															}
															
															// 2. 添加动态DNS选项
															const dynamicGroups = buildOptions(dnsdata, protocol, netType);
															select.appendChild(dynamicGroups);
															
															// 3. 添加自定义DNS（最底部）
															addCustomDNS(select);
														}
														function setSelectDefault(selectorId, defaultValue) {
															const select = document.getElementById(selectorId);
															
															// 方法1：直接设置value属性
															select.value = defaultValue;
															
															// 方法2：遍历选项设置selected
															Array.from(select.options).forEach(option => {
															  option.selected = option.value === defaultValue;
															});
															
															// 验证设置结果
															if(select.value !== defaultValue) {
															  console.warn(`默认值${defaultValue}不存在于选项中`);
															}
														}
														// 初始化加载-china
														if('<% nvram_get("ipv6_service"); %>' == "disabled" ){
															populateSelect('ss_basic_chng_china_udp_1_opt', china_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_china_udp_2_opt', china_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_china_udp_3_opt', china_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_china_tcp_1_opt', china_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_china_tcp_2_opt', china_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_china_tcp_3_opt', china_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_china_dot_1_opt', china_dnsData, 'dot', 'ipv4');
															populateSelect('ss_basic_chng_china_dot_2_opt', china_dnsData, 'dot', 'ipv4');
															populateSelect('ss_basic_chng_china_dot_3_opt', china_dnsData, 'dot', 'ipv4');
														}else{
															populateSelect('ss_basic_chng_china_udp_1_opt', china_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_china_udp_2_opt', china_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_china_udp_3_opt', china_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_china_tcp_1_opt', china_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_china_tcp_2_opt', china_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_china_tcp_3_opt', china_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_china_dot_1_opt', china_dnsData, 'dot', 'all');
															populateSelect('ss_basic_chng_china_dot_2_opt', china_dnsData, 'dot', 'all');
															populateSelect('ss_basic_chng_china_dot_3_opt', china_dnsData, 'dot', 'all');
														}

														// 初始化加载-trust
														if('<% nvram_get("ipv6_service"); %>' == "disabled" ){
															populateSelect('ss_basic_chng_trust_udp_1_opt', trust_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_trust_udp_2_opt', trust_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_trust_udp_3_opt', trust_dnsData, 'udp', 'ipv4');
															populateSelect('ss_basic_chng_trust_tcp_1_opt', trust_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_trust_tcp_2_opt', trust_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_trust_tcp_3_opt', trust_dnsData, 'tcp', 'ipv4');
															populateSelect('ss_basic_chng_trust_dot_1_opt', trust_dnsData, 'dot', 'ipv4');
															populateSelect('ss_basic_chng_trust_dot_2_opt', trust_dnsData, 'dot', 'ipv4');
															populateSelect('ss_basic_chng_trust_dot_3_opt', trust_dnsData, 'dot', 'ipv4');
														}else{
															populateSelect('ss_basic_chng_trust_udp_1_opt', trust_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_trust_udp_2_opt', trust_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_trust_udp_3_opt', trust_dnsData, 'udp', 'all');
															populateSelect('ss_basic_chng_trust_tcp_1_opt', trust_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_trust_tcp_2_opt', trust_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_trust_tcp_3_opt', trust_dnsData, 'tcp', 'all');
															populateSelect('ss_basic_chng_trust_dot_1_opt', trust_dnsData, 'dot', 'all');
															populateSelect('ss_basic_chng_trust_dot_2_opt', trust_dnsData, 'dot', 'all');
															populateSelect('ss_basic_chng_trust_dot_3_opt', trust_dnsData, 'dot', 'all');
														}

														// set default - china
														if(isp_dns_1){
															setSelectDefault('ss_basic_chng_china_udp_1_opt', isp_dns_1);
															setSelectDefault('ss_basic_chng_china_udp_2_opt', isp_dns_1);
															setSelectDefault('ss_basic_chng_china_udp_3_opt', isp_dns_1);
														}else{
															setSelectDefault('ss_basic_chng_china_udp_1_opt', '223.5.5.5');
															setSelectDefault('ss_basic_chng_china_udp_2_opt', '223.5.5.5');
															setSelectDefault('ss_basic_chng_china_udp_3_opt', '223.5.5.5');
														}
														setSelectDefault('ss_basic_chng_china_tcp_1_opt', '119.28.28.28');
														setSelectDefault('ss_basic_chng_china_tcp_2_opt', '119.28.28.28');
														setSelectDefault('ss_basic_chng_china_tcp_3_opt', '119.28.28.28');
														setSelectDefault('ss_basic_chng_china_dot_1_opt', 'dns.alidns.com@223.5.5.5');
														setSelectDefault('ss_basic_chng_china_dot_2_opt', 'dns.alidns.com@223.5.5.5');
														setSelectDefault('ss_basic_chng_china_dot_3_opt', 'dns.alidns.com@223.5.5.5');

														// set default - trust
														setSelectDefault('ss_basic_chng_trust_udp_1_opt', '1.1.1.1');
														setSelectDefault('ss_basic_chng_trust_udp_2_opt', '1.1.1.1');
														setSelectDefault('ss_basic_chng_trust_udp_3_opt', '1.1.1.1');
														setSelectDefault('ss_basic_chng_trust_tcp_1_opt', '8.8.8.8');
														setSelectDefault('ss_basic_chng_trust_tcp_2_opt', '1.1.1.1');
														setSelectDefault('ss_basic_chng_trust_tcp_3_opt', '8.8.8.8');
														setSelectDefault('ss_basic_chng_trust_dot_1_opt', 'dns.google.com@8.8.4.4');
														setSelectDefault('ss_basic_chng_trust_dot_2_opt', 'dns.google.com@8.8.4.4');
														setSelectDefault('ss_basic_chng_trust_dot_3_opt', 'dns.google.com@8.8.4.4');
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
														var gfwl = addCommas('<% nvram_get("gfwlist_numbers"); %>');
														var chnl = addCommas('<% nvram_get("chnroute_numbers"); %>');
														var chnn = addCommas('<% nvram_get("chnroute_ips"); %>');
														var cdnn = addCommas('<% nvram_get("chnlist_numbers"); %>');
														$('#table_rules').forms([
															{ title: 'gfwlist 域名数量（被墙域名）', multi: [
																{ suffix: '<em>'+ gfwl +'</em>&nbsp;条，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules_ng/gfwlist.gz" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_gfwlist"); %></i></a>' },
															]},
															{ title: 'chnlist 域名数量（大陆域名）', multi: [
																{ suffix: '<em>'+ cdnn +'</em>&nbsp;条，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules_ng/chnlist.gz" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_chnlist"); %></i></a>' },
															]},
															{ title: 'chnroute 大陆白名单IP段数量', multi: [
																{ suffix: '<em>'+ chnl +'</em>&nbsp;行，包含 <em>' + chnn + '</em>&nbsp;个ip地址，版本：' },
																{ suffix: '<a href="https://github.com/hq450/fancyss/blob/3.0/rules_ng/chnroute.txt" target="_blank">' },
																{ suffix: '<i><% nvram_get("update_chnroute"); %></i></a>' },
															]},
															{ title: '规则定时更新任务', hint:'44', multi: [
																{ id:'ss_basic_rule_update', type:'select', func:'u', style:'width:auto', options:[["0", "禁用"], ["1", "开启"]], value:'0'},
																{ id:'ss_basic_rule_update_time', type:'select', style:'width:auto', options:option_ruleu, value:'4'},
																{ suffix: '<a id="update_choose">' },
																{ suffix: '<input type="checkbox" id="ss_basic_gfwlist_update" title="选择此项应用gfwlist.conf自动更新">gfwlist' },
																{ suffix: '<input type="checkbox" id="ss_basic_chnroute_update" title="选择此项应用chnroute.txt自动更新">chnroute' },
																{ suffix: '<input type="checkbox" id="ss_basic_chnlist_update" title="选择此项应用chnlist.txt自动更新">chnlist</a>' },
																{ suffix: '&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(1)">保存设置</a>' },
															]},
															{ title: '规则手动更新', multi: [
																{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(2)">立即更新规则</a>'},
															]},
															{ title: '二进制更新', multi: [
																{ suffix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="xray_binary_update(2)">更新xray程序</a>&nbsp;'},
															]},
														]);
													</script>
												</table>
												<table id="table_subscribe" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
													<script type="text/javascript">
														var option_noded = [["0", "每天"], ["1", "周一"], ["2", "周二"], ["3", "周三"], ["4", "周四"], ["5", "周五"], ["6", "周六"], ["7", "周日"]];
														var option_hy2_tfo = [["0", "强制关闭"], ["1", "强制开启"], ["2", "根据订阅"]];
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
															{ title: '订阅地址管理<br><br><font color="#ffcc00">支持SS/SSR/V2ray/Xray/Trojan</font>', multi: [
																{ id:'ss_online_links', type:'textarea', hint:'116', rows:'12', ph:ph1},
																{ suffix: '<span id="ss_sub_ads"></span>' },
															]},
															{ title: '订阅节点模式设定', id:'ssr_subscribe_mode', type:'select', style:'width:auto', options:option_modes, value:'2'},
															{ title: 'hysteria2订阅设置', multi: [
																{ suffix: '上行:' },
																{ id: 'ss_basic_hy2_up_speed', type: 'text', maxlen:'200', style:'width:30px;', value:''},
																{ suffix: 'mbps，' },
																{ suffix: '下行:' },
																{ id: 'ss_basic_hy2_dl_speed', type: 'text', maxlen:'200', style:'width:30px;', value:''},
																{ suffix: 'mbps，' },
																{ suffix: 'tfo:' },
																{ id:'ss_basic_hy2_tfo_switch', type:'select', style:'width:auto', options:option_hy2_tfo, value:'2'},
																{ suffix: '&nbsp;congestion:' },
																{ id:'ss_basic_hy2_cg_opt', type:'select', style:'width:70px', options:option_hy2_cg, value:'brutal'},
															]},
															{ title: '订阅节点允许不安全', id:'ss_basic_sub_ai', hint:'113', type:'checkbox', value:true},
															{ title: '下载订阅时走代理网络', id:'ss_basic_online_links_proxy', type:'select', style:'width:auto', options:[["0", "自动判断"], ["1", "走代理"], ["2", "不走代理"]], value:'0'},
															{ title: '自定义UserAgent', id:'ss_basic_online_ua', type:'select', style:'width:auto', hint:'112', options:[["0", "fancyss默认（≥3.3.9）"], ["1", "curl/wget（≤3.3.8）"], ["2", "V2rayN"], ["3", "V2rayNG"], ["4", "Shadowrocket"]], value:'0'},
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
															//{ title: '透明代理', hint:'146', multi: [
															//	{ id: 'ss_basic_proxy_ipv4', type:'checkbox', func:'u', value:true},
															//	{ suffix: '<a>ipv4</a>' },
															//	{ suffix: '&nbsp;&nbsp;'},
															//	{ id: 'ss_basic_proxy_ipv6', type:'checkbox', func:'u', value:true},
															//	{ suffix: '<a>ipv6</a>' },
															//]},
															{ title: 'New Bing模式', id:'ss_basic_proxy_newb', hint:'149', type:'checkbox', value:true},
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">性能优化</td></tr>'},
															{ title: 'ssr开启多核心支持', id:'ss_basic_mcore', hint:'108', type:'checkbox', value:true},										//fancyss-hnd
															{ title: 'ss/v2ray/xray开启tcp fast open', id:'ss_basic_tfo', type:'checkbox', value:false},										//fancyss-hnd
															{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">其它</td></tr>'},
															{ title: '插件开启时 - 跳过网络可用性检测', id:'ss_basic_nonetcheck', hint:'138', type:'checkbox', value:false},
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
