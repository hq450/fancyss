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
<title>【科学上网】</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" language="JavaScript" src="/js/table/table.js"></script>
<script type="text/javascript" language="JavaScript" src="/client_function.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script type="text/javascript" src="/res/tablednd.js"></script>
<script>
var db_ss = {};
var dbus = {};
var confs = {};
var node_max = 0;
var node_nu = 0;
var ss_nodes = [];
var nodeN = 15;
var trsH = 36;
var nodeH;
var node_idx;
var sel_mode;
var edit_id;
var isMenuopen = 0;
var _responseLen;
var noChange = 0;
var noChange2 = 0;
var noChange_status = 0;
var poped = 0;
var x = 5;
var ping_result = "";
var save_flag = "";
var STATUS_FLAG;
var refreshRate;
var ph_v2ray = "# 此处填入v2ray json，内容可以是标准的也可以是压缩的&#10;# 请保证你json内的outbound配置正确！！！&#10;# ------------------------------------&#10;# 同样支持vmess://链接填入，格式如下：&#10;vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIjIzMyIsDQogICJhZGQiOiAiMjMzLjIzMy4yMzMuMjMzIiwNCiAgInBvcnQiOiAiMjMzIiwNCiAgImlkIjogImFlY2EzYzViLTc0NzktNDFjMy1hMWUzLTAyMjkzYzg2Y2EzOCIsDQogICJhaWQiOiAiMjMzIiwNCiAgIm5ldCI6ICJ3cyIsDQogICJ0eXBlIjogIm5vbmUiLA0KICAiaG9zdCI6ICJ3d3cuMjMzLmNvbSIsDQogICJwYXRoIjogIi8yMzMiLA0KICAidGxzIjogInRscyINCn0="
var option_modes = [["1", "gfwlist模式"], ["2", "大陆白名单模式"], ["3", "游戏模式"], ["5", "全局代理模式"], ["6", "回国模式"]];
var option_method = [ "none",  "rc4",  "rc4-md5",  "rc4-md5-6",  "aes-128-gcm",  "aes-192-gcm",  "aes-256-gcm",  "aes-128-cfb",  "aes-192-cfb",  "aes-256-cfb",  "aes-128-ctr",  "aes-192-ctr",  "aes-256-ctr",  "camellia-128-cfb",  "camellia-192-cfb",  "camellia-256-cfb",  "bf-cfb",  "cast5-cfb",  "idea-cfb",  "rc2-cfb",  "seed-cfb",  "salsa20",  "chacha20",  "chacha20-ietf",  "chacha20-ietf-poly1305",  "xchacha20-ietf-poly1305" ];
var option_protocals = [ "origin", "verify_simple", "verify_sha1", "auth_sha1", "auth_sha1_v2", "auth_sha1_v4", "auth_aes128_md5", "auth_aes128_sha1", "auth_chain_a", "auth_chain_b", "auth_chain_c", "auth_chain_d", "auth_chain_e", "auth_chain_f" ];
var option_obfs = ["plain", "http_simple", "http_post", "tls1.2_ticket_auth"];
var option_v2enc = [["none", "不加密"], ["auto", "自动"], ["aes-128-cfb", "aes-128-cfb"], ["aes-128-gcm", "aes-128-gcm"], ["chacha20-poly1305", "chacha20-poly1305"]];
var option_headtcp = [["none", "不伪装"], ["http", "伪装http"]];
var option_headkcp = [["none", "不伪装"], ["srtp", "伪装视频通话(srtp)"], ["utp", "伪装BT下载(uTP)"], ["wechat-video", "伪装微信视频通话"]];
var heart_count = 1;
const pattern=/[`~!@#$^&*()=|{}':;'\\\[\]\.<>\/?~！@#￥……&*（）——|{}%【】'；：""'。，、？\s]/g;


function init() {
	show_menu(menu_hook);
	get_dbus_data();
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
function get_heart_beat() {
	$.ajax({
		type: "GET",
		url: "/_api/ss_heart_beat",
		dataType: "json",
		async: false,
		success: function(data) {
			heart_beat = data.result[0]["ss_heart_beat"];
			if(heart_beat == "1"){
				if (heart_count == "1"){
					var dbus_post = {};
					dbus_post["ss_heart_beat"] = "0";
					push_data("dummy_script.sh", "", dbus_post, "2");
					return true;
				}else{
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
		}
	});
	heart_count++
	setTimeout("get_heart_beat();", 10000);
}
function get_dbus_data() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		cache:false,
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			conf2obj(db_ss);
			generate_node_info();
			refresh_options();
			refresh_html();
			toggle_func();
			ss_node_sel();
			version_show();
			if(db_ss["ss_failover_enable"] == "1"){
				get_ss_status_back();
			}else{
				get_ss_status_front();
			}
			get_heart_beat();
			//console.log(productid);
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			console.log(XmlHttpRequest.responseText);
			alert("skipd数据读取错误，请格式化jffs分区后重新尝试！");
		}
		,timeout: 0
	});
}
function conf2obj(obj, action) {
	for (var field in obj) {
		var el = E(field);
		if (el != null && el.getAttribute("type") == "checkbox") {
			el.checked = obj[field] == "1" ? true:false;
			continue;
		}
		if (el != null) {
			el.value = obj[field];
		}
	}
	E("ss_basic_password").value = Base64.decode(E("ss_basic_password").value);
	E("ss_basic_v2ray_json").value = do_js_beautify(Base64.decode(E("ss_basic_v2ray_json").value));
	if(!action){
		var _base64 = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links", "ss_basic_custom"];
		for (var i = 0; i < _base64.length; i++) {
			if(E(_base64[i]).value != ""){
				E(_base64[i]).value = Base64.decode(E(_base64[i]).value);
			}
		}
	}
}
function ssconf_node2obj(node_sel) {
	var p = "ssconf_basic";
	var obj = {};
	var params2 = ["password", "v2ray_json", "server", "mode", "port", "password", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_mux_enable", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_use_json"];

	for (var i = 0; i < params2.length; i++) {
		obj["ss_basic_" + params2[i]] = db_ss[p + "_" + params2[i] + "_" + node_sel] || "";
	}
	obj["ssconf_basic_node"] = node_sel;
	return obj;
}
function ss_node_sel() {
	var node_sel = E("ssconf_basic_node").value;
	var obj = ssconf_node2obj(node_sel);
	conf2obj(obj, 1);
	verifyFields();
}
function refresh_options() {
	if (node_max == 0) return false;
	var option = $("#ssconf_basic_node");
	var option1 = $("#ss_basic_ping_node");
	var option2 = $("#ss_basic_udp_node");
	var option3 = $("#ss_failover_s4_3");
	
	option.find('option').remove().end();
	option1.find('option').remove().end();
	option2.find('option').remove().end();
	option3.find('option').remove().end();
	
	option1.append('<option value="off">关闭ping功能</option>');
	option1.append('<option value="0" selected>全部节点</option>');
	for (var field in confs) {
		var c = confs[field];
		if(c["type"] == "3" && c.v2ray_use_json == "1"){
			continue;
		}else{
			option1.append('<option value="' + field + '">' + c["name"] + '</option>');
			option2.append('<option value="' + field + '">' + c["name"] + '</option>');
		}
	}

	for (var field in confs) {
		var c = confs[field];
		option3.append('<option value="' + field + '">' + c["name"] + '</option>');
	}

	for (var field in confs) {
		var c = confs[field];
		if (c.rss_protocol) {
			if (c.group) {
				option.append($("<option>", {
					value: field,
					text: c.use_kcp == "1" ? "【SSR+KCP】" + c.group + " - " + c.name : "【SSR】" + c.group + " - " + c.name
				}));
			} else {
				option.append($("<option>", {
					value: field,
					text: c.use_kcp == "1" ? "【SSR+KCP】" + c.name : "【SSR】" + c.name
				}));
			}
		} else {
			if (c.koolgame_udp == "0" || c.koolgame_udp == "1") {
				option.append($("<option>", {
					value: field,
					text: c.use_kcp == "1" ? "【koolgame+KCP】" + c.name : "【koolgame】" + c.name
				}));
			} else {
				if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") {
					option.append($("<option>", {
						value: field,
						text: c.use_kcp == "1" ? "【V2Ray+KCP】" + c.name : "【V2Ray】" + c.name
					}));
				}else{
					option.append($("<option>", {
						value: field,
						text: c.use_kcp == "1" ? "【SS+KCP】" + c.name : "【SS】" + c.name
					}));
				}
			}
		}
	}
	option.val(db_ss["ssconf_basic_node"]||"1");
	option1.val(db_ss["ss_basic_ping_node"]||"0");
	option2.val(db_ss["ss_basic_udp_node"]||"1");
	option3.val((db_ss["ss_failover_s4_3"])||"1");
}
function save() {
	var node_sel = E("ssconf_basic_node").value;
	dbus["ssconf_basic_node"] = node_sel;
	E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
	E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
	//key define
	var params_input = ["ss_failover_s1", "ss_failover_s2_1", "ss_failover_s2_2", "ss_failover_s3_1", "ss_failover_s3_2", "ss_failover_s4_1", "ss_failover_s4_2", "ss_failover_s4_3", "ss_failover_s5", "ss_basic_interval", "ss_basic_row", "ss_basic_ping_node", "ss_basic_ping_method", "ss_dns_china", "ss_dns_china_user", "ss_foreign_dns", "ss_dns2socks_user", "ss_chinadns_user", "ss_chinadns1_user", "ss_sstunnel_user", "ss_direct_user", "ss_game2_dns_foreign", "ss_game2_dns2ss_user", "ss_basic_kcp_lserver", "ss_basic_kcp_lport", "ss_basic_kcp_server", "ss_basic_kcp_port", "ss_basic_kcp_parameter", "ss_basic_rule_update", "ss_basic_rule_update_time", "ssr_subscribe_mode", "ssr_subscribe_obfspara", "ssr_subscribe_obfspara_val", "ss_basic_online_links_goss", "ss_basic_node_update", "ss_basic_node_update_day", "ss_basic_node_update_hr", "ss_basic_exclude", "ss_basic_include", "ss_base64_links", "ss_acl_default_port", "ss_acl_default_mode", "ss_basic_kcp_method", "ss_basic_kcp_password", "ss_basic_kcp_mode", "ss_basic_kcp_encrypt", "ss_basic_kcp_mtu", "ss_basic_kcp_sndwnd", "ss_basic_kcp_rcvwnd", "ss_basic_kcp_conn", "ss_basic_kcp_extra", "ss_basic_udp_software", "ss_basic_udp_node", "ss_basic_udpv1_lserver", "ss_basic_udpv1_lport", "ss_basic_udpv1_rserver", "ss_basic_udpv1_rport", "ss_basic_udpv1_password", "ss_basic_udpv1_mode", "ss_basic_udpv1_duplicate_nu", "ss_basic_udpv1_duplicate_time", "ss_basic_udpv1_jitter", "ss_basic_udpv1_report", "ss_basic_udpv1_drop", "ss_basic_udpv2_lserver", "ss_basic_udpv2_lport", "ss_basic_udpv2_rserver", "ss_basic_udpv2_rport", "ss_basic_udpv2_password", "ss_basic_udpv2_fec", "ss_basic_udpv2_timeout", "ss_basic_udpv2_mode", "ss_basic_udpv2_report", "ss_basic_udpv2_mtu", "ss_basic_udpv2_jitter", "ss_basic_udpv2_interval", "ss_basic_udpv2_drop", "ss_basic_udpv2_other", "ss_basic_udp2raw_lserver", "ss_basic_udp2raw_lport", "ss_basic_udp2raw_rserver", "ss_basic_udp2raw_rport", "ss_basic_udp2raw_password", "ss_basic_udp2raw_rawmode", "ss_basic_udp2raw_ciphermode", "ss_basic_udp2raw_authmode", "ss_basic_udp2raw_lowerlevel", "ss_basic_udp2raw_other", "ss_basic_udp_upstream_mtu", "ss_basic_udp_upstream_mtu_value", "ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_time_hour", "ss_basic_time_min", "ss_basic_tri_reboot_time", "ss_basic_dnsmasq_fastlookup", "ss_basic_server_resolver", "ss_basic_server_resolver_user"];
	var params_check = ["ss_failover_enable", "ss_failover_c1", "ss_failover_c2", "ss_failover_c3", "ss_basic_tablet", "ss_basic_dragable", "ss_basic_qrcode", "ss_basic_enable", "ss_basic_gfwlist_update", "ss_basic_tfo", "ss_basic_tnd", "ss_basic_chnroute_update", "ss_basic_cdn_update", "ss_basic_kcp_nocomp", "ss_basic_udp_boost_enable", "ss_basic_udpv1_disable_filter", "ss_basic_udpv2_disableobscure", "ss_basic_udpv2_disablechecksum", "ss_basic_udp2raw_boost_enable", "ss_basic_udp2raw_a", "ss_basic_udp2raw_keeprule", "ss_basic_dns_hijack", "ss_basic_mcore"];
	var params_base64_a = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links"];
	var params_base64_b = ["ss_basic_custom"];
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
	// data need base64 encode:format a with "."
	for (var i = 0; i < params_base64_a.length; i++) {
		dbus[params_base64_a[i]] = E(params_base64_a[i]).value.indexOf(".") != -1 ? Base64.encode(E(params_base64_a[i]).value):"";
	}
	// data need base64 encode, format b with plain text
	for (var i = 0; i < params_base64_b.length; i++) {
		dbus[params_base64_b[i]] = Base64.encode(E(params_base64_b[i]).value);
	}
	// collect values in acl table
	if(E("ACL_table")){
		var tr = E("ACL_table").getElementsByTagName("tr");
		for (var i = 1; i < tr.length - 1; i++) {
			var rowid = tr[i].getAttribute("id").split("_")[2];
			if (E("ss_acl_name_" + i)){
				dbus["ss_acl_name_" + rowid] = E("ss_acl_name_" + rowid).value;
				dbus["ss_acl_mode_" + rowid] = E("ss_acl_mode_" + rowid).value;
				dbus["ss_acl_port_" + rowid] = E("ss_acl_port_" + rowid).value;
			}
		}
	}
	// for v2ray json, we need to process first: parse vmess:// format, encode json format
	if(E('ss_basic_v2ray_json').value.indexOf("vmess://") != -1){
		var vmess_node = JSON.parse(Base64.decode(E('ss_basic_v2ray_json').value.split("//")[1]));
		dbus["ssconf_basic_server_" + node_sel] = vmess_node.add;
		dbus["ssconf_basic_port_" + node_sel] = vmess_node.port;
		dbus["ssconf_basic_v2ray_uuid_" + node_sel] = vmess_node.id;
		dbus["ssconf_basic_v2ray_security_" + node_sel] = "auto";
		dbus["ssconf_basic_v2ray_alterid_" + node_sel] = vmess_node.aid;
		dbus["ssconf_basic_v2ray_network_" + node_sel] = vmess_node.net;
		if(vmess_node.net == "tcp"){
			dbus["ssconf_basic_v2ray_headtype_tcp_" + node_sel] = vmess_node.type;
		}else if(vmess_node.net == "kcp"){
			dbus["ssconf_basic_v2ray_headtype_kcp_" + node_sel] = vmess_node.type;
		}
		dbus["ssconf_basic_v2ray_network_host_" + node_sel] = vmess_node.host;
		dbus["ssconf_basic_v2ray_network_path_" + node_sel] = vmess_node.path;
		if(vmess_node.tls == "tls"){
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "tls";
		}else{
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "none";
		}
		dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = 1;
		dbus["ssconf_basic_v2ray_mux_concurrency_" + node_sel] = 8;
		dbus["ssconf_basic_v2ray_use_json_" + node_sel] = 0;
		dbus["ssconf_basic_v2ray_json"] = "";
	}else{
		if (E("ss_basic_v2ray_use_json").checked == true){
			if(isJSON(E('ss_basic_v2ray_json').value)){
				if(E('ss_basic_v2ray_json').value.indexOf("outbound") != -1){
					dbus["ssconf_basic_v2ray_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
					var param_v2 = ["server", "port", "v2ray_uuid", "v2ray_security", "v2ray_alterid", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_host", "v2ray_network_path", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency"];
					for (var i = 0; i < param_v2.length; i++) {
						dbus["ssconf_basic_" + param_v2[i] + "_" + node_sel] = "";
					}
				}else{
					alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
					return false;
				}
			}else{
				alert("错误！检测到你输入的v2ray配置不是标准json格式！");
				return false;
			}
		}
	}
	// node data: write node data under using from the main pannel incase of data change
	var params = ["server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"];
	for (var i = 0; i < params.length; i++) {
		dbus["ssconf_basic_" + params[i] + "_" + node_sel] = E("ss_basic_" + params[i]).value;
	}
	// node data: checkbox
	dbus["ssconf_basic_use_kcp_" + node_sel] = E("ss_basic_use_kcp").checked ? '1' : '0';
	dbus["ssconf_basic_v2ray_use_json_" + node_sel] = E("ss_basic_v2ray_use_json").checked ? '1' : '0';
	dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = E("ss_basic_v2ray_mux_enable").checked ? '1' : '0';
	// node data: base64
	dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
	// adjust some value when switch node between ss ssr v2ray koolgame
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
		var remove_ssr = [ "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
		dbus["ss_basic_type"] = "1"
		dbus["ssconf_basic_type_" + node_sel] = "1"
		for (var i = 0; i < remove_ssr.length; i++) {
			dbus["ss_basic_" + remove_ssr[i]] = "";
			dbus["ssconf_basic_" + remove_ssr[i] + "_" + node_sel] = "";
		}
	} else {
		if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
			var remove_gamev2 = [ "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
			dbus["ss_basic_type"] = "2"
			dbus["ssconf_basic_type_" + node_sel] = "2"
			for (var i = 0; i < remove_gamev2.length; i++) {
				dbus["ss_basic_" + remove_gamev2[i]] = "";
				dbus["ssconf_basic_" + remove_gamev2[i] + "_" + node_sel] = "";
			}
		} else {
			if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
				var remove_v2ray = [ "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"];
				dbus["ss_basic_type"] = "3"
				dbus["ssconf_basic_type_" + node_sel] = "3"
				for (var i = 0; i < remove_v2ray.length; i++) {
					dbus["ss_basic_" + remove_v2ray[i]] = "";
					dbus["ssconf_basic_" + remove_v2ray[i] + "_" + node_sel] = "";
				}
			}else{
				var remove_ss = [ "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
				dbus["ss_basic_type"] = "0"
				dbus["ssconf_basic_type_" + node_sel] = "0"
				for (var i = 0; i < remove_ss.length; i++) {
					dbus["ss_basic_" + remove_ss[i]] = "";
					dbus["ssconf_basic_" + remove_ss[i] + "_" + node_sel] = "";
				}
			}
		}
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
	push_data("ss_config.sh", "start",  post_dbus);
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
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
		var ss_on = false;
		var ssr_on = true;
		var koolgame_on = false;
		var v2ray_on = false;
	}else{
		if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
			var ss_on = false;
			var ssr_on = false;
			var koolgame_on = true;
			var v2ray_on = false;
		}else{
			if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
				var ss_on = false;
				var ssr_on = false;
				var koolgame_on = false;
				var v2ray_on = true;
			}else{
				var ss_on = true;
				var ssr_on = false;
				var koolgame_on = false;
				var v2ray_on = false;
			}
		}
	}
	//ss-libev
	elem.display(elem.parentElem('ss_basic_ss_obfs', 'tr'), ss_on);
	elem.display(elem.parentElem('ss_basic_ss_obfs_host', 'tr'), (ss_on && E("ss_basic_ss_obfs").value != "0"));
	elem.display(elem.parentElem('ss_basic_ss_v2ray', 'tr'), ss_on);
	elem.display(elem.parentElem('ss_basic_ss_v2ray_opts', 'tr'), (ss_on && E("ss_basic_ss_v2ray").value != "0"));
	//ssr-libev
	elem.display(elem.parentElem('ss_basic_rss_protocol_param', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_protocol', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_obfs', 'tr'), ssr_on);
	elem.display(elem.parentElem('ss_basic_rss_obfs_param', 'tr'), ssr_on);
	//koolgame
	elem.display(elem.parentElem('ss_basic_koolgame_udp', 'tr'), koolgame_on);
	//v2ray
	var json_on = E("ss_basic_v2ray_use_json").checked == true;
	var json_off = E("ss_basic_v2ray_use_json").checked == false;
	var http_on = E("ss_basic_v2ray_network").value == "tcp" && E("ss_basic_v2ray_headtype_tcp").value == "http";
	var host_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || http_on;
	var path_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2";
	elem.display(elem.parentElem('ss_basic_method', 'tr'), !v2ray_on);
	elem.display(elem.parentElem('ss_basic_password', 'tr'), !v2ray_on);
	elem.display(elem.parentElem('ss_basic_server', 'tr'), json_off);
	elem.display(elem.parentElem('ss_basic_port', 'tr'), json_off);
	elem.display(elem.parentElem('ss_basic_v2ray_use_json', 'tr'), v2ray_on);
	elem.display(elem.parentElem('ss_basic_v2ray_uuid', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_alterid', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_security', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_network', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_headtype_tcp', 'tr'), (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "tcp"));
	elem.display(elem.parentElem('ss_basic_v2ray_headtype_kcp', 'tr'), (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "kcp"));
	elem.display(elem.parentElem('ss_basic_v2ray_network_host', 'tr'), (v2ray_on && json_off && host_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_path', 'tr'), (v2ray_on && json_off && path_on));
	elem.display(elem.parentElem('ss_basic_v2ray_network_security', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_mux_enable', 'tr'), (v2ray_on && json_off));
	elem.display(elem.parentElem('ss_basic_v2ray_mux_concurrency', 'tr'), (v2ray_on && json_off && E("ss_basic_v2ray_mux_enable").checked));
	elem.display(elem.parentElem('ss_basic_v2ray_json', 'tr'), (v2ray_on && json_on));
	elem.display('v2ray_binary_update_tr', v2ray_on);
	// dns pannel
	showhide("dns_plan_foreign", !koolgame_on);
	showhide("dns_plan_foreign_game2", koolgame_on);
	//node add/edit pannel
	if (save_flag == "shadowsocks") {
		showhide("ss_obfs_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_obfs_host_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_obfs").val() != "0"));
		showhide("ss_v2ray_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray").val() != "0"));
	}
	if (save_flag == "v2ray") {
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_network_security_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || http_on_2;
			var path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2"
			showhide("v2ray_headtype_tcp_tr", (E("ss_node_table_v2ray_network").value == "tcp"));
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_network_host_tr", host_on_2);
			showhide("v2ray_network_path_tr", path_on_2);
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
		}
	}
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
	// 插件重启功能
	var Ti = E("ss_reboot_check").value;
	var In = E("ss_basic_inter_pre").value;
	var items = ["re1", "re2", "re3", "re4", "re4_1", "re4_2", "re4_3", "re5"];
	for ( var i = 1; i < items.length; ++i ) $("." + items[i]).hide();
	if (Ti != "0") $(".re" + Ti).show();
	if (Ti == "4") $(".re4_" + In).show();
	// failover
	if(E("ss_failover_enable").checked){
		$("#failover_settings_1").show();
		$("#failover_settings_2").show();
		$("#failover_settings_3").show();
	}else{
		$("#failover_settings_1").hide();
		$("#failover_settings_2").hide();
		$("#failover_settings_3").hide();
	}
	showhide("ss_failover_text_1",  E("ss_failover_enable").checked && E("ss_failover_s4_1").value == "2" && E("ss_failover_s4_2").value == "2");
	showhide("ss_failover_s4_2",  E("ss_failover_enable").checked && E("ss_failover_s4_1").value == "2");
	showhide("ss_failover_s4_3",  E("ss_failover_enable").checked && E("ss_failover_s4_1").value == "2" && E("ss_failover_s4_2").value == "1");
	// push on click
	var trid = $(r).attr("id")
	if ( trid == "ss_basic_qrcode" || trid == "ss_basic_dragable" || trid == "ss_basic_tablet" ) {
		var dbus_post = {};
		dbus_post[trid] = E(trid).checked ? '1' : '0';
		push_data("dummy_script.sh", "", dbus_post, "1");
	}	
	refresh_acl_table();
}
function update_visibility() {
	var a = E("ss_basic_rule_update").value == "1";
	var b = E("ss_basic_node_update").value == "1";
	var c = E("ssr_subscribe_obfspara").value == "2";
	var d = E("ss_basic_udp_upstream_mtu").value == "1";
	var e = E("ss_dns_china").value == "12";
	var f = E("ss_foreign_dns").value;
	var g = E("ss_basic_tri_reboot_time").value;
	var h = E("ss_basic_server_resolver").value == "12";
	var i = E("ss_basic_ping_node").value != "off" && E("ss_basic_ping_node").value != "";
	showhide("ss_basic_rule_update_time", a);
	showhide("update_choose", a);
	showhide("ss_basic_node_update_day", b);
	showhide("ss_basic_node_update_hr", b);
	showhide("ssr_subscribe_obfspara_val", c);
	showhide("ss_basic_udp_upstream_mtu_value", d);
	showhide("ss_dns_china_user", e);
	showhide("ss_basic_server_resolver_user", h);
	showhide("ss_chinadns_user", (f == "2"));
	showhide("ss_dns2socks_user", (f == "3"));
	showhide("ss_sstunnel_user", (f == "4"));
	showhide("ss_chinadns1_user", (f == "5"));
	showhide("ss_direct_user", (f == "8"));
	showhide("ss_basic_tri_reboot_time_note", (g != "0"));
	showhide("ss_basic_ping_method", i);
	showhide("ss_basic_ping_btn", i);
	if(f == "6"){
		$("#ss_foreign_dns_note").html('DNS over HTTPS (DoH)，<a href="https://cloudflare-dns.com/zh-Hans/" target="_blank"><em>cloudflare服务</em></a>，拒绝一切污染~');
	}else if(f == "7"){
		$("#ss_foreign_dns_note").html('v2ray_dns只有启用v2ray节点的时能使用');
	}else{
		$("#ss_foreign_dns_note").html('');
	}
}
function Add_profile() { //点击节点页面内添加节点动作
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').fadeIn(300);
	tabclickhandler(0); //默认显示添加ss节点
	E("ss_node_table_name").value = "";
	E("ss_node_table_server").value = "";
	E("ss_node_table_port").value = "";
	E("ss_node_table_password").value = "";
	E("ss_node_table_method").value = "aes-256-cfb";
	E("ss_node_table_mode").value = "1";
	E("ss_node_table_ss_obfs").value = "0"
	E("ss_node_table_ss_obfs_host").value = "";
	E("ss_node_table_ss_v2ray").value = "0"
	E("ss_node_table_ss_v2ray_opts").value = "";
	E("ss_node_table_rss_protocol").value = "origin";
	E("ss_node_table_rss_protocol_param").value = "";
	E("ss_node_table_rss_obfs").value = "plain";
	E("ss_node_table_rss_obfs_param").value = "";
	E("ss_node_table_koolgame_udp").value = "0";
	E("ss_node_table_v2ray_uuid").value = "";
	E("ss_node_table_v2ray_alterid").value = "";
	E("ss_node_table_v2ray_json").value = "";
	E("ssTitle").style.display = "";
	E("ssrTitle").style.display = "";
	E("gamev2Title").style.display = "";
	E("v2rayTitle").style.display = "";
	E("add_node").style.display = "";
	E("edit_node").style.display = "none";
	E("continue_add").style.display = "";
	$("#vpnc_settings").fadeIn(300);
	$(".contentM_qis").css("top", nodeH - 280 + "px");
}
function cancel_add_rule() { //点击添加节点面板上的返回
	$("#vpnc_settings").fadeOut(300);
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
}
function tabclickhandler(_type) {
	E('ssTitle').className = "vpnClientTitle_td_unclick";
	E('ssrTitle').className = "vpnClientTitle_td_unclick";
	E('gamev2Title').className = "vpnClientTitle_td_unclick";
	E('v2rayTitle').className = "vpnClientTitle_td_unclick";
	if (_type == 0) {
		save_flag = "shadowsocks";
		E('ssTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		showhide("ss_obfs_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_obfs_host_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_obfs").val() != "0"));
		showhide("ss_v2ray_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray").val() != "0"));
	} else if (_type == 1) {
		save_flag = "shadowsocksR";
		E('ssrTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";
		E('ss_v2ray_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "";
		E('ssr_protocol_param_tr').style.display = "";
		E('ssr_obfs_tr').style.display = "";
		E('ssr_obfs_param_tr').style.display = "";
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
	} else if (_type == 2) {
		save_flag = "gameV2";
		E('gamev2Title').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_obfs_support').style.display = "none";
		E('ss_obfs_host_support').style.display = "none";
		E('ss_v2ray_support').style.display = "none";
		E('ss_v2ray_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
	} else if (_type == 3) {
		save_flag = "v2ray";
		E('v2rayTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "";
		E('ss_name_support_tr').style.display = "";
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
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "";
		E('v2ray_alterid_tr').style.display = "";
		E('v2ray_security_tr').style.display = "";
		E('v2ray_network_tr').style.display = "";
		E('v2ray_headtype_tcp_tr').style.display = "";
		E('v2ray_headtype_kcp_tr').style.display = "";
		E('v2ray_network_path_tr').style.display = "";
		E('v2ray_network_host_tr').style.display = "";
		E('v2ray_network_security_tr').style.display = "";
		E('v2ray_mux_enable_tr').style.display = "";
		E('v2ray_mux_concurrency_tr').style.display = "";
		E('v2ray_json_tr').style.display = "";
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_network_security_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || http_on_2;
			var path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2"
			showhide("v2ray_headtype_tcp_tr", (E("ss_node_table_v2ray_network").value == "tcp"));
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_network_host_tr", host_on_2);
			showhide("v2ray_network_path_tr", path_on_2);
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
		}
	} 
	return save_flag;
}
function add_ss_node_conf(flag) {
	var ns = {};
	var p = "ssconf_basic";
	node_max += 1;
	var params1 = ["mode", "name", "server", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts"];
	var params2 = ["mode", "name", "server", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"];
	var params3 = ["mode", "name", "server", "port", "method", "koolgame_udp"];
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable"];
	if(!$.trim($('#ss_node_table_name').val())){
		alert("节点名不能为空！！");
		return false;
	}
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params1[i]).val());
		}
		ns[p + "_password_" + node_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_max] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params2[i]).val());
		}
		ns[p + "_password_" + node_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_max] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params3[i]).val());
		}
		ns[p + "_password_" + node_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_max] = "2";
	} else if (flag == 'v2ray') {
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + node_max] = $.trim($('#ss_node_table' + "_" + params4_1[i]).val());
		}
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + node_max] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://")
				console.log(vmess_node)
				ns[p + "_server_" + node_max] = vmess_node.add;
				ns[p + "_port_" + node_max] = vmess_node.port;
				ns[p + "_v2ray_uuid_" + node_max] = vmess_node.id;
				ns[p + "_v2ray_security_" + node_max] = "auto";
				ns[p + "_v2ray_alterid_" + node_max] = vmess_node.aid;
				ns[p + "_v2ray_network_" + node_max] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns[p + "_v2ray_headtype_tcp_" + node_max] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns[p + "_v2ray_headtype_kcp_" + node_max] = vmess_node.type;
				}
				ns[p + "_v2ray_network_host_" + node_max] = vmess_node.host;
				ns[p + "_v2ray_network_path_" + node_max] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns[p + "_v2ray_network_security_" + node_max] = "tls";
				}else{
					ns[p + "_v2ray_network_security_" + node_max] = "none";
				}	
				ns[p + "_v2ray_mux_enable_" + node_max] = 1;
				ns[p + "_v2ray_mux_concurrency_" + node_max] = 8;
				ns[p + "_v2ray_use_json_" + node_max] = 0;
				ns[p + "_v2ray_json_" + node_max] = "";
			}else{
				if (E("ss_node_table_v2ray_use_json").checked == true){
					if(isJSON(E('ss_node_table_v2ray_json').value)){
						if(E('ss_node_table_v2ray_json').value.indexOf("outbound") != -1){
							ns[p + "_v2ray_json_" + node_max] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
						}else{
							alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
							return false;
						}
					}else{
						alert("错误！检测到你输入的v2ray配置不是标准json格式！");
						return false;
					}
				}
			}
		}
		ns[p + "_type_" + node_max] = "3";
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
				E("ss_node_table_mode").value = "1";
				E("ss_node_table_ss_obfs").value = "0"
				E("ss_node_table_ss_obfs_host").value = "";
				E("ss_node_table_ss_v2ray").value = "0"
				E("ss_node_table_ss_v2ray_opts").value = "";
				E("ss_node_table_rss_protocol").value = "origin";
				E("ss_node_table_rss_protocol_param").value = "";
				E("ss_node_table_rss_obfs").value = "plain";
				E("ss_node_table_rss_obfs_param").value = "";
				E("ss_node_table_koolgame_udp").value = "0";
				E("ss_node_table_v2ray_uuid").value = "";
				E("ss_node_table_v2ray_alterid").value = "";
				E("ss_node_table_v2ray_json").value = "";
				cancel_add_rule();
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
	console.log("删除第", id, "个节点！！！")

	var dbus_tmp = {};
	var perf = "ssconf_basic_"
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "use_lb", "ping", "lbmode", "weight", "use_kcp", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "type"];
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
	var params1_base64 = ["password"];
	var params1_check = ["v2ray_use_json", "v2ray_mux_enable"];
	var params1_input = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"];
	if(c["v2ray_json"]){
		E("ss_node_table_v2ray_json").value = do_js_beautify(Base64.decode(c["v2ray_json"]));
	}
	for (var i = 0; i < params1_base64.length; i++) {
		if(c[params1_base64[i]]){
			E("ss_node_table_" + params1_base64[i]).value = Base64.decode(c[params1_base64[i]]);
		}
	}
	for (var i = 0; i < params1_check.length; i++) {
		if(c[params1_check[i]]){
			E("ss_node_table_" + params1_check[i]).checked = c[params1_check[i]] == "1";
		}
	}
	for (var i = 0; i < params1_input.length; i++) {
		if(c[params1_input[i]]){
			E("ss_node_table_" + params1_input[i]).value = c[params1_input[i]];
		}
	}
	E("cancelBtn").style.display = "";
	E("add_node").style.display = "none";
	E("edit_node").style.display = "";
	E("continue_add").style.display = "none";
	if (c["rss_protocol"]) {
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "";
		E("gamev2Title").style.display = "none";
		E("v2rayTitle").style.display = "none";
		$("#ssrTitle").html("编辑SSR账号");
		tabclickhandler(1);
	} else {
		if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") {
			E("ssTitle").style.display = "none";
			E("ssrTitle").style.display = "none";
			E("gamev2Title").style.display = "";
			E("v2rayTitle").style.display = "none";
			$("#gamev2Title").html("编辑koolgame账号");
			tabclickhandler(2);
		}else { 
			if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") {
				E("ssTitle").style.display = "none";
				E("ssrTitle").style.display = "none";
				E("gamev2Title").style.display = "none";
				E("v2rayTitle").style.display = "";
				$("#v2rayTitle").html("编辑V2Ray账号");
				tabclickhandler(3);
			}else{
				E("ssTitle").style.display = "";
				E("ssrTitle").style.display = "none";
				E("gamev2Title").style.display = "none";
				E("v2rayTitle").style.display = "none";
				$("#ssTitle").html("编辑ss账号");
				tabclickhandler(0);
			}
		}
	}
	if(E("ss_basic_row").value == "all"){
		var pos = $("#node_" + id)[0].offsetTop - 200;
		pos = pos < 0 ? 0 : pos;
		$(".contentM_qis").css("top", pos + "px");
	}else{
		$(".contentM_qis").css("top", "120px");
	}
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').fadeIn(300);
	$("#vpnc_settings").fadeIn(300);
}
function edit_ss_node_conf(flag) {
	var ns = {};
	var p = "ssconf_basic";
	var params1 = ["name", "server", "mode", "port", "method", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts"];
	var params2 = ["name", "server", "mode", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"];
	var params3 = ["name", "server", "mode", "port", "method", "koolgame_udp"]
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable"];
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params1[i]).val();
		}
		ns[p + "_password_" + edit_id] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + edit_id] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params2[i]).val();
		}
		ns[p + "_password_" + edit_id] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + edit_id] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params3[i]).val();
		}
		ns[p + "_password_" + edit_id] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + edit_id] = "2";
	} else if (flag == 'v2ray') {
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + edit_id] = $('#ss_node_table' + "_" + params4_1[i]).val();
		}
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + edit_id] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://");
				console.log(vmess_node);
				ns["ssconf_basic_server_" + edit_id] = vmess_node.add;
				ns["ssconf_basic_port_" + edit_id] = vmess_node.port;
				ns["ssconf_basic_v2ray_uuid_" + edit_id] = vmess_node.id;
				ns["ssconf_basic_v2ray_security_" + edit_id] = "auto";
				ns["ssconf_basic_v2ray_alterid_" + edit_id] = vmess_node.aid;
				ns["ssconf_basic_v2ray_network_" + edit_id] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns["ssconf_basic_v2ray_headtype_tcp_" + edit_id] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns["ssconf_basic_v2ray_headtype_kcp_" + edit_id] = vmess_node.type;
				}
				ns["ssconf_basic_v2ray_network_host_" + edit_id] = vmess_node.host;
				ns["ssconf_basic_v2ray_network_path_" + edit_id] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns["ssconf_basic_v2ray_network_security_" + edit_id] = "tls";
				}else{
					ns["ssconf_basic_v2ray_network_security_" + edit_id] = "none";
				}
				ns["ssconf_basic_v2ray_mux_enable_" + edit_id] = 0;
				ns["ssconf_basic_v2ray_mux_concurrency_" + edit_id] = 8;
				ns["ssconf_basic_v2ray_use_json_" + edit_id] = 0;
				ns["ssconf_basic_v2ray_json_" + edit_id] = "";
			}else{
				console.log("use v2ray json");
				ns["ssconf_basic_v2ray_json_" + edit_id] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
			}
		}
		ns[p + "_type_" + edit_id] = "3";
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
			E("ss_node_table_mode").value = "1";
			E("ss_node_table_ss_obfs").value = "0"
			E("ss_node_table_ss_obfs_host").value = "";
			E("ss_node_table_ss_v2ray").value = "0"
			E("ss_node_table_ss_v2ray_opts").value = "";
			E("ss_node_table_rss_protocol").value = "origin";
			E("ss_node_table_rss_protocol_param").value = "";
			E("ss_node_table_rss_obfs").value = "plain";
			E("ss_node_table_rss_obfs_param").value = "";
			E("ss_node_table_koolgame_udp").value = "0";
			E("ss_node_table_v2ray_uuid").value = "";
			E("ss_node_table_v2ray_alterid").value = "";
			E("ss_node_table_v2ray_json").value = "";
		}
	});
	$("#vpnc_settings").fadeOut(300);
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
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
		if (typeof(db_ss["ssconf_basic_rss_protocol_" + idx]) != "undefined"){
			obj["type"] = "1";
		} else {
			if (typeof(db_ss["ssconf_basic_koolgame_udp_" + idx]) != "undefined"){
				obj["type"] = "2";
			} else {
				if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + idx]) != "undefined"){
					obj["type"] = "3";
				}else{
					obj["type"] = "0";
				}
			}
		}
		//这些值统一处理
		var params = ["group", "name", "port", "method", "password", "mode", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "weight", "lbmode", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json"];
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + idx;
			if (typeof db_ss[ofield] == "undefined") {
				obj[params[i]] = '';
			}else{
				obj[params[i]] = db_ss[ofield];
			}
		}
		//兼容部分，这些值是空的话需要填为0
		var params_sp = ["use_kcp", "use_lb", "v2ray_mux_enable"];
		for (var i = 0; i < params_sp.length; i++) {
			if (typeof db_ss[p + "_" + params_sp[i] + "_" + idx] == "undefined") {
				obj[params_sp[i]] = '0';
			} else {
				obj[params_sp[i]] = db_ss[p + "_" + params_sp[i] + "_" + idx];
			}
		}
		if(db_ss[p + "_v2ray_use_json_" + idx] ==  "1"){
			//对v2ray json节点的处理
			var json = JSON.parse(Base64.decode(db_ss[p + "_v2ray_json_" + idx]));
			var server_addr;
			server_addr = json["outbound"];
			server_addr = (server_addr != undefined) ? server_addr : ""
			server_addr = (!!server_addr) ? server_addr.settings : ""
			server_addr = (!!server_addr) ? server_addr.vnext["0"] : ""
			server_addr = (!!server_addr) ? server_addr.address : ""
			if(server_addr){
				obj["server"] = server_addr;
			}else{
				obj["server"] = '';
			}
		}else{
			if (typeof db_ss[p + "_server_" + idx] == "undefined") {
				obj["server"] = '';
			}else{
				obj["server"] = db_ss[p + "_server_" + idx];
			}
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
	//console.log("refresh_html");
	// how many row to show
	var pageH = parseInt(E("FormTitle").style.height.split("px")[0]);
	var nodeT = 304;
	if(db_ss["ss_basic_row"]){
		if(db_ss["ss_basic_row"] == "all"){
			nodeN = node_nu;
		}else{
			nodeN = parseInt(db_ss["ss_basic_row"]);
		}
	}
	var nodeL  = parseInt((pageH-nodeT)/trsH) - 1;
	nodeH = nodeN*trsH
	if (nodeN > nodeL){
		//var maxH = node_nu*trsH + trsH
		$("#ss_list_table").attr("style", "height:" + (nodeH + trsH) + "px");
	}else{
		$("#ss_list_table").removeAttr("style");
	}
	var btnMv = (nodeN - node_nu)*trsH
	if(btnMv > 0){
		var btnTop = (nodeT + nodeH + 12) - (nodeN - node_nu)*trsH
	}else{
		var btnTop = (nodeT + nodeH + 12)
	}
	//console.log("页面整体高度：", pageH);
	//console.log("最大能显示行：", nodeL);
	//console.log("定义的显示行：", nodeN);
	//console.log("实际显示的行：", ss_nodes.length);
	//console.log("节点列表上界：", nodeT);
	//console.log("节点列表高度：", nodeH);
	// write option to ss_basic_row 
	$("#ss_basic_row").find('option').remove().end();
	for (var i = 10; i <= nodeL; i++) {
		$("#ss_basic_row").append('<option value="' + i + '">' + i + '</option>');
	}
	if (node_nu > nodeL){
		$("#ss_basic_row").append('<option value="all">全部显示</option>');
	}
	E("ss_basic_row").value = db_ss["ss_basic_row"]||nodeL;
	
	// define col width in different situation
	if(node_nu && E("ss_basic_ping_node") != "off" && E("ss_basic_ping_node") != ""){
		var width = ["", "5%", "30%", "30%", "8%", "12%", "10%", "5%", ];
	}else{
		var width = ["", "6%", "32%", "32%", "10%", "10%", "10%" ];
	}
	// make dynamic element
	var html = '';
	html += '<div class="nodeTable" style="height:' + trsH + 'px; margin: -1px 0px 0px 0px; width: 750px;">'
	html += '<table width="750px" border="0" align="center" cellpadding="4" cellspacing="0" class="FormTable_table" style="margin:-1px 0px 0px 0px;">'
	html += '<tr height="' + trsH + '">'
	html += '<th style="width:' + width[1] + ';">序号</th>'
	html += '<th style="width:' + width[2] + ';cursor:pointer" onclick="hide_name();" title="点我隐藏节点名称信息!" >节点名称</th>'
	html += '<th style="width:' + width[3] + ';cursor:pointer" onclick="hide_server();" title="点我隐藏服务器信息!" >服务器地址</th>'
	html += '<th style="width:' + width[4] + ';">类型</th>'
	if(node_nu && db_ss["ss_basic_ping_node"] != "off" && E("ss_basic_ping_node") != ""){
		html += '<th style="width:' + width[5] + ';" id="ping_th">ping/丢包</th>'
	}
	html += '<th style="width:' + width[6] + ';">编辑</th>'
	html += '<th style="width:' + width[7] + ';">使用</th>'
	html += '</tr>'
	html += '</table>'
	html += '</div>'
	
	html += '<div class="nodeTable" style="top: ' + nodeT + 'px; width: 750px; height: ' + nodeH + 'px; overflow: hidden; position: absolute;">'
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
		//server
		if(E("ss_basic_qrcode").checked){
			html += '<td style="width:' + width[3] + ';cursor:pointer" class="node_server" id="server_' + c["node"] + '" title="' + c["server"] + '" onclick="makeQRcode(this)">';
		}else{
			html += '<td style="width:' + width[3] + ';" class="node_server" id="server_' + c["node"] + '">';
		}
		html += '<div style="display: none;" class="shadow2"></div>';
		html += '<div class="server">' + c["server"] + '</div>';
		html += '</td>';
		//节点类型
		html +='<td style="width:' + width[4] + ';">';
		switch(c["type"]) {
			case '0' :
				if(c["ss_obfs"] == "http" || c["ss_obfs"] == "tls"){
					html +='ss+obfs';
				}else{
					html +='ss';
				}
				break;
			case '1' :
				html +='ssr';
				break;
			case '2' :
				html +='koolgame';
				break;
			case '3' :
				html +='v2ray';
				break;
		}
		html +='</td>';
		//ping/丢包
		if(node_nu && db_ss["ss_basic_ping_node"] != "off" && E("ss_basic_ping_node") != ""){
			if(c["type"] == "3" && c["v2ray_use_json"] == "1"){
				html += '<td style="width:' + width[5] + ';"></td>';
			}else{
				html += '<td style="width:' + width[5] + ';" id="ss_node_ping_' + c["node"] + '" class="ping"></td>';
			}
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
	html += '<div align="center" class="nodeTable" style="top: ' + btnTop + 'px; width: 750px; position: absolute;">'
	html += '<input id="add_ss_node" class="button_gen" onClick="Add_profile()" type="button" value="添加节点"/>'
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
	}
	// ask or not ask for ping
	if(E("ss_basic_ping_node").value != "off" && E("ss_basic_ping_node").value != ""){
		if(ping_result != ""){
			write_ping(ping_result);
		}else{
			ping_test();
		}
	}
	// select default node
	select_default_node(2);
	// make row moveable
	if(E("ss_basic_dragable").checked){
		order_adjustment();
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
	var temp = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "ss_obfs", "ss_obfs_host", "ss_v2ray", "ss_v2ray_opts", "koolgame_udp", "use_lb", "ping", "lbmode", "weight", "use_kcp", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "type"];
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
			$('#ss_node_list_table tr:nth-child(' + new_nu + ') td:nth-child(5)').attr("id", "ss_node_ping_" + new_nu);
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
	cancel_add_rule();
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
		if(c["ss_v2ray"] === "1"){
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"])) + "@" + c["server"] + ":" + c["port"] + "/?plugin=" + encodeURIComponent("v2ray-plugin;" +c["ss_v2ray_opts"]) + "#" + c["name"];
		}else if(c["ss_obfs"] === "1"){
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"])) + "@" + c["server"] + ":" + c["port"] + "/?plugin=obfs-local%3Bobfs%3D" + c["ss_obfs"] + "%3Bobfs-host%3D" + c["ss_obfs_host"] + "#" + c["name"];
		}else{
			var code = "ss://" + Base64.encode(c["method"] + ":" + Base64.decode(c["password"]) + "@" + c["server"] + ":" + c["port"] + "#" + c["name"]);
		}
	}else if(c["type"] == "1"){
    	var base64pass = c["password"].replace(/=+/,"");
    	var base64obfsparm = Base64.encode(c["rss_obfs_param"]).replace(/=+/,"");
    	var base64protoparam = Base64.encode(c["rss_protocol_param"]).replace(/=+/,"");
    	var base64remark = Base64.encode(c["name"]).replace(/=+/,"");
    	var base64group = Base64.encode(c["group"]).replace(/=+/,"");
    	var config_ssr = c["server"] + ":" + c["port"] + ":" + c["rss_protocol"] + ":" + c["method"] + ":" + c["rss_obfs"] + ":" + base64pass + "/?obfsparam=" + base64obfsparm + "&protoparam=" + base64protoparam + "&remarks=" + base64remark + "&group=" + base64group;
    	var code = "ssr:\/\/" + Base64.encode(config_ssr).replace(/=+/,"").replace(/\+/,"-").replace(/\//,"_");
	}else if(c["type"] == "2"){
		var code = 0;
	}else if(c["type"] == "3"){
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
			code.tls = c["v2ray_network_security"]
			if(c["v2ray_network"] == "tcp"){
				code.type = c["v2ray_headtype_tcp"]
			}else if(c["v2ray_network"] == "kcp"){
				code.type = c["v2ray_headtype_kcp"]
			}
			code = "vmess:\/\/" + Base64.encode(JSON.stringify(code));
		}
	}else{
		var code = 2;
	}
	$("#qrtitle").html(c["name"]);

	if(E("ss_basic_row").value == "all"){
		var pos = $("#node_" + id)[0].offsetTop - 200;
		pos = pos < 0 ? 0 : pos;
		$("#qrcode_show").css("top", pos + "px");
	}else{
		$("#qrcode_show").css("top", "240px");
	}

	showQRcode(code);
}
function showQRcode(data) {
	$("#qrcode").html("");
	if(data == 0){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">不支持koolgame配置的二维码生成！</span>')
	}else if(data == 1){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">暂不支持v2ray json配置的二维码生成！</span>')
	}else if(data == 2){
		$("#qrcode").html('<span style="font-size:16px;color:#000;">错误！！节点类型位置！！<br />请检查你的节点！</span>')
	}else{
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
function ping_switch() {
	//当ping功能关闭时，保存ss_basic_ping_node的关闭值，然后刷新表格以隐藏ping显示
	var dbus_post = {};
	if(E("ss_basic_ping_node").value == "off" || E("ss_basic_ping_node").value == ""){
		E("ss_basic_ping_method").style.display = "none";
		E("ss_basic_ping_btn").style.display = "none";
		dbus_post["ss_basic_ping_node"] = "off";
		//now post
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
					//清空内存中的ping结果，在未刷新界面情况下，下次打开ping功能就能重新请求了
					ping_result = "";
					$(".show-btn1").trigger("click");
					refresh_table();
				}
			}
		});
	}else{
		E("ss_basic_ping_method").style.display = "";
		E("ss_basic_ping_btn").style.display = "";
	}
}
function ping_now() {
	//点击【开始ping！】，需要重新请求一次后台脚本来ping，所以刷新一次表格，然后ping
	var dbus_post = {};
	dbus_post["ss_basic_ping_node"] = E("ss_basic_ping_node").value;
	dbus_post["ss_basic_ping_method"] = E("ss_basic_ping_method").value;

	//now post
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
				//清空内存中的ping结果，表格渲染完成后会重新请求的
				ping_result = "";
				$(".show-btn1").trigger("click");
				refresh_table();
			}
		}
	});
}
function ping_test() {
	//提交ping请求，拿到ping结果
	if(E("ss_basic_ping_node").value == "off" || E("ss_basic_ping_node").value == ""){
		return false;
	}else if(E("ss_basic_ping_node").value == "0"){
		$(".ping").html("测试中...");
	}else{
		$(".ping").html("");
		$("#ss_node_ping_" + E("ss_basic_ping_node").value).html("测试中...");
	}
	//now post
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_ping.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		async: true,
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			write_ping(response);
		},
		error: function(XmlHttpRequest, textStatus, errorThrown){
			//console.log(XmlHttpRequest.responseText);
			$(".ping").html("失败!");
		},
		timeout: 60000
	});
}
function write_ping(r){
	if(E("ss_basic_ping_node") == "off"){
		return false;
	}
	if ((String(r.result)).length <= 2){
		if(db_ss["ss_basic_ping_node"] == "0"){
			$(".ping").html("超时！");
		}else{
			$(".ping").html("");
			$("#ss_node_ping_" + db_ss["ss_basic_ping_node"]).html("超时！");
		}
	}else{
		ping_result = r;
		ps = eval(Base64.decode(r.result));
		for(var i = 0; i<ps.length; i++){
			var nu = parseInt(ps[i][0]);
			var ping = parseFloat(ps[i][1]);
			var loss = ps[i][2];
			if (!ping){
				if(E("ss_basic_ping_method").value == 1){
					test_result = '<font color="#FF0000">failed</font>';
				}else{
					if(loss == ""){
						test_result = '<font color="#FF0000">failed</font>';
					}else{
						test_result = '<font color="#FF0000">failed/' + loss + '</font>';
					}
				}
			}else{
				if(E("ss_basic_ping_method").value == 1){
					$('#ping_th').html("ping");
					if (ping <= 50){
						test_result = '<font color="#1bbf35">' + ping.toPrecision(3) +'ms</font>';
					}else if (ping > 50 && ping <= 100) {
						test_result = '<font color="#3399FF">' + ping.toPrecision(3) +'ms</font>';
					}else{
						test_result = '<font color="#f36c21">' + ping.toPrecision(3) +'ms</font>';
					}
				}else{
					$('#ping_th').html("ping/丢包");
					if (ping <= 50){
						test_result = '<font color="#1bbf35">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
					}else if (ping > 50 && ping <= 100) {
						test_result = '<font color="#3399FF">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
					}else{
						test_result = '<font color="#f36c21">' + ping.toPrecision(3) +'ms/' + loss + '</font>';
					}
				}
			}
			if($('#ss_node_ping_' + nu))
				$('#ss_node_ping_' + nu).html(test_result);
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
function download_SS_node(arg) {
	if(arg == 2){
		db_ss["ss_basic_action"] = "11";
		showSSLoadingBar();
		setTimeout("get_realtime_log();", 600);
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_conf.sh", "params":[arg], "fields": "" };
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
				}else if(arg == 2){
					var b = document.createElement('A')
					b.href = "_root/files/shadowsocks.tar.gz"
					b.download = 'shadowsocks_' + productid + '.tar.gz'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}else if(arg == 6){
					var b = document.createElement('A')
					b.href = "_root/files/ssf_status.txt"
					b.download = 'ssf_status.txt'
					document.body.appendChild(b);
					b.click();
					document.body.removeChild(b);
				}else if(arg == 7){
					var b = document.createElement('A')
					b.href = "_root/files/ssc_status.txt"
					b.download = 'ssc_status.txt'
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
	$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：" + db_ss['ss_basic_version_local'] + "</i></a>");
	$.ajax({
		url: 'https://raw.githubusercontent.com/hq450/fancyss/master/fancyss_hnd/config.json.js',
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
			ss_node_sel();
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
			$('#apply_button').hide();
			verifyFields();
		});
	$(".show-btn3").click(
		function() {
			tabSelect(3);
			$('#apply_button').show();
			update_visibility();
			autoTextarea(E("ss_dnsmasq"), 0, 500);
		});
	$(".show-btn4").click(
		function() {
			tabSelect(4);
			$('#apply_button').show();
			autoTextarea(E("ss_wan_white_ip"), 0, 400);
			autoTextarea(E("ss_wan_white_domain"), 0, 400);
			autoTextarea(E("ss_wan_black_ip"), 0, 400);
			autoTextarea(E("ss_wan_black_domain"), 0, 400);
		});
	$(".show-btn5").click(
		function() {
			tabSelect(5);
			$('#apply_button').show();
			verifyFields();
			autoTextarea(E("ss_basic_kcp_parameter"), 0, 100);
		});
	$(".show-btn6").click(
		function() {
			tabSelect(6);
			$('#apply_button').show();
			update_visibility();
			verifyFields();
			get_udp_status();
		});
	$(".show-btn7").click(
		function() {
			tabSelect(7);
			$('#apply_button').hide();
			update_visibility();
		});
	$(".show-btn8").click(
		function() {
			tabSelect(8);
			$('#apply_button').show();
			refresh_acl_table();
			//update_visibility();
		});
	$(".show-btn9").click(
		function() {
			tabSelect(9);
			$('#apply_button').show();
			update_visibility();
		});
	$(".show-btn10").click(
		function() {
			tabSelect(10);
			$('#apply_button').hide();
			get_log();
		});
	$("#update_log").click(
		function() {
			window.open("https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt");
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
function get_ss_status_front() {
	if (db_ss['ss_basic_enable'] != "1") {
		E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
		E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
		return false;
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_status.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
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
	setTimeout("get_ss_status_front();", refreshRate);
}
function get_ss_status_back() {
	if (db_ss['ss_basic_enable'] != "1") {
		E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
		E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
		return false;
	}
	$.ajax({
		url: '/_temp/ss_status.txt',
		type: 'GET',
		dataType: 'html',
		async: true,
		cache:false,
		success: function(response) {
			if(response.indexOf("@@") != -1){
				var arr = response.split("@@");
				if (arr[0] == "" || arr[1] == "") {
					E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
					E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
				} else {
					E("ss_state2").innerHTML = arr[0];
					E("ss_state3").innerHTML = arr[1];
				}
			}
		},
		error: function(xhr) {
			E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
			E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
		}
	});
	setTimeout("get_ss_status_back();", 3000);
}
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
function close_ssf_status() {
	$("#ssf_status_div").fadeOut(200);
	STATUS_FLAG = 0;
}
function close_ssc_status() {
	$("#ssc_status_div").fadeOut(200);
	STATUS_FLAG = 0;
}
function lookup_status_log(s) {
	STATUS_FLAG = 1;
	if(s == 1){
		$("#ssf_status_div").fadeIn(500);
		get_status_log(1);
	}else{
		$("#ssc_status_div").fadeIn(500);
		get_status_log(2);
	}
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
				setTimeout('get_status_log("' + s + '");', 1500);
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
	$.ajax({
		url: '/_temp/ss_log.txt',
		type: 'GET',
		dataType: 'html',
		async: true,
		cache:false,
		success: function(response) {
			var retArea = E("log_content1");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
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
				setTimeout("get_log();", 300);
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
				retArea.value = response.replace("XU6J03M6", " ");
				E("ok_button").style.display = "";
				retArea.scrollTop = retArea.scrollHeight;
				count_down_close();
				return true;
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 1000) {
				return false;
			} else {
				setTimeout("get_realtime_log();", 100);
			}
			retArea.value = response.replace("XU6J03M6", " ");
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
	code += '<table width="750px" border="0" align="center" cellpadding="4" cellspacing="0" class="FormTable_table acl_lists" style="margin:-1px 0px 0px 0px;">'
	code += '<tr>'
	code += '<th width="23%">主机IP地址</th>'
	code += '<th width="23%">主机别名</th>'
	code += '<th width="23%">访问控制</th>'
	code += '<th width="23%">目标端口</th>'
	code += '<th width="8%">操作</th>'
	code += '</tr>'
	code += '</table>'
	// acl table input area
	code += '<table id="ACL_table" width="750px" border="0" align="center" cellpadding="4" cellspacing="0" class="list_table acl_lists" style="margin:-1px 0px 0px 0px;">'
	code += '<tr>'
	// ip addr
	code += '<td width="23%">'
	code += '<input type="text" maxlength="15" class="input_ss_table" id="ss_acl_ip" align="left" style="float:left;width:110px;margin-left:16px;text-align:center" autocomplete="off" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off">'
	code += '<img id="pull_arrow" height="14px;" src="images/arrow-down.gif" align="right" onclick="pullLANIPList(this);" title="<#select_IP#>">'
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
	$('#ss_acl_table').after(code);
	
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
		obj.src = "/images/arrow-top.gif"
		element.style.display = 'block';
	} else{
		hideClients_Block();
	}
}
function hideClients_Block() {
	E("pull_arrow").src = "/images/arrow-down.gif";
	E('ClientList_Block').style.display = 'none';
}
function close_proc_status() {
	$("#detail_status").fadeOut(200);
}
function get_proc_status() {
	$("#detail_status").fadeIn(500);
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "ss_proc_status.sh", "params":[], "fields": ""};
	$.ajax({
		type: "POST",
		cache:false,
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
	dbus_post["ss_online_links"] = Base64.encode(E("ss_online_links").value);
	dbus_post["ssr_subscribe_mode"] = E("ssr_subscribe_mode").value;
	dbus_post["ssr_subscribe_obfspara"] = E("ssr_subscribe_obfspara").value;
	dbus_post["ssr_subscribe_obfspara_val"] = E("ssr_subscribe_obfspara_val").value;
	dbus_post["ss_basic_online_links_goss"] = E("ss_basic_online_links_goss").value;
	dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
	dbus_post["ss_basic_node_update_day"] = E("ss_basic_node_update_day").value;
	dbus_post["ss_basic_node_update_hr"] = E("ss_basic_node_update_hr").value;
	dbus_post["ss_basic_exclude"] = E("ss_basic_exclude").value.replace(pattern,"") || "";
	dbus_post["ss_basic_include"] = E("ss_basic_include").value.replace(pattern,"") || "";
	dbus_post["ss_basic_node_update"] = E("ss_basic_node_update").value;
	dbus_post["ss_base64_links"] = E("ss_base64_links").value;
	push_data("ss_online_update.sh", action,  dbus_post);
}
function v2ray_binary_update(){
	var dbus_post = {};
	db_ss["ss_basic_action"] = "15";
	require(['/res/layer/layer.js'], function(layer) {
		layer.confirm('<li>为了避免不必要的问题，请保证路由器和服务器上的v2ray版本一致！</li><br /><li>你确定要更新v2ray二进制吗？</li>', {
			shade: 0.8,
		}, function(index) {
			$("#log_content3").attr("rows", "20");
			push_data("ss_v2ray.sh", 1, dbus_post);
			layer.close(index);
			return true;
			//save_online_nodes(action);
		}, function(index) {
			layer.close(index);
			return false;
		});
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
</script>
</head>
<body onload="init();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 200;" >
<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
	<tr>
		<td height="100">
		<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
		<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
		<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;overflow:hidden">
			<textarea cols="50" rows="36" wrap="off" readonly="readonly" id="log_content3" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:3px;padding-right:22px;overflow-x:hidden"></textarea>
		</div>
		<div id="ok_button" class="apply_gen" style="background: #000;display: none;">
			<input id="ok_button1" class="button_gen" type="button" onclick="hideSSLoadingBar()" value="确定">
		</div>
		</td>
	</tr>
</table>
</div>
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
					<td bgcolor="#4D595D" align="left" valign="top">
						<div>
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle"><% nvram_get("productid"); %> 科学上网插件</div>
										<div style="float:right; width:15px; height:25px;margin-top:-20px">
											<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
										</div>
										<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
										<div class="SimpleNote" id="head_illustrate">本插件是支持<a href="https://github.com/shadowsocks/shadowsocks-libev" target="_blank"><em><u>SS</u></em></a>、<a href="https://github.com/shadowsocksrr/shadowsocksr-libev" target="_blank"><em><u>SSR</u></em></a>、<a href="http://firmware.koolshare.cn/binary/koolgame/" target="_blank"><em><u>KoolGame</u></em></a>、<a href="https://github.com/v2ray/v2ray-core" target="_blank"><em><u>V2Ray</u></em></a>四种客户端的科学上网、游戏加速工具。</div>
										<!-- this is the popup area for process status -->
										<div id="detail_status"  class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;display: none;">
											<div class="user_title">【科学上网】状态检测</div>
											<div style="margin-left:15px"><i>&nbsp;&nbsp;目前本功能支持ss相关进程状态和iptables表状态检测。</i></div>
											<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden">
												<textarea cols="63" rows="36" wrap="off" id="proc_status" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
											</div>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="close_proc_status();" value="返回主界面">
											</div>
										</div>
										<!-- this is the popup area for foreign status -->
										<div id="ssf_status_div"  class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;display: none;margin-left:0px;width:748px;">
											<div class="user_title">国外历史状态 - www.google.com.tw</div>
											<div style="margin-left:15px"><i>&nbsp;&nbsp;此功能仅在开启故障转移时生效。</i></div>
											<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden;">
												<textarea cols="63" rows="36" wrap="off" id="log_content_f" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
											</div>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="download_SS_node(6);" value="下载日志">
												<input class="button_gen" type="button" onclick="close_ssf_status();" value="返回主界面">
												<input style="margin-left:10px" type="checkbox" id="ss_failover_c4">
												<lable>&nbsp;暂停日志刷新</lable>
											</div>
										</div>
										<!-- this is the popup area for china status -->
										<div id="ssc_status_div"  class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: -20px;display: none;margin-left:0px;width:748px;">
											<div class="user_title">国内历史状态 - www.baidu.com</div>
											<div style="margin-left:15px"><i>&nbsp;&nbsp;此功能仅在开启故障转移时生效。</i></div>
											<div style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden;">
												<textarea cols="63" rows="36" wrap="off" id="log_content_c" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
											</div>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="download_SS_node(7);" value="下载日志">
												<input class="button_gen" type="button" onclick="close_ssc_status();" value="返回主界面">
												<input style="margin-left:10px" type="checkbox" id="ss_failover_c5">
											</div>
										</div>
										<!-- this is the popup area for QRcode -->
										<div id="qrcode_show" class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: 90px;margin-left:197px;display: none;width:356px;height:356px;background: #fff;">
											<div style="text-align: center;margin-top:10px"><span id="qrtitle" style="font-size:16px;color:#000;"></span></div>
											<div id="qrcode" style="margin: 10px 50px 10px 50px;width:256px;height:256px;text-align:center;overflow:hidden">
											</div>
											<div style="margin-top:15px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="cleanCode();" value="返回">
											</div>
										</div>
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
															<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(12)">
																<i>当前版本：</i>
															</a>
														</div>
														<div style="display:table-cell;float: left;margin-left:270px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" target="_blank" href="https://github.com/hq450/fancyss/blob/master/fancyss_hnd/Changelog.txt">更新日志</a>
														</div>
														<div style="display:table-cell;float: left;margin-left:350px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" href="javascript:void(0);" onclick="pop_help()">插件帮助</a>
														</div>
													</td>
												</tr>
											</table>
										</div>
										<div id="ss_status1" style="margin:-1px 0px 0px 0px;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
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
															<a type="button" class="ss_btn" style="cursor:pointer" onclick="pop_111(3)" href="javascript:void(0);">分流检测</a>
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
														<input id="show_btn5" class="show-btn5" style="cursor:pointer" type="button" value="KCP加速" />
														<input id="show_btn6" class="show-btn6" style="cursor:pointer" type="button" value="UDP加速"/>
														<input id="show_btn7" class="show-btn7" style="cursor:pointer" type="button" value="更新管理" />
														<input id="show_btn8" class="show-btn8" style="cursor:pointer" type="button" value="访问控制" />
														<input id="show_btn9" class="show-btn9" style="cursor:pointer" type="button" value="附加功能" />
														<input id="show_btn10" class="show-btn10" style="cursor:pointer" type="button" value="查看日志" />
													</td>
												</tr>
											</table>
										</div>
										<div id="vpnc_settings"  class="contentM_qis pop_div_bg">
											<table class="QISform_wireless" border="0" align="center" cellpadding="5" cellspacing="0">
												<tr style="height:32px;">
													<td>
														<table width="100%" border="0" align="left" cellpadding="0" cellspacing="0" class="vpnClientTitle">
															<tr>
													  		<td width="25%" align="center" id="ssTitle" onclick="tabclickhandler(0);">添加SS账号</td>
													  		<td width="25%" align="center" id="ssrTitle" onclick="tabclickhandler(1);">添加SSR账号</td>
													  		<td width="25%" align="center" id="gamev2Title" onclick="tabclickhandler(2);">添加koolgame账号</td>
													  		<td width="25%" align="center" id="v2rayTitle" onclick="tabclickhandler(3);">添加V2Ray配置</td>
															</tr>
														</table>
													</td>
												</tr>
												<tr>
													<td>
														<div>
														<table id="table_edit" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
															<script type="text/javascript">
																$('#table_edit').forms([
																	{ title: '使用模式', id:'ss_node_table_mode', type:'select', func:'v', options:option_modes, style:'width:350px', value: "1"},
																	{ title: '使用json配置', rid:'v2ray_use_json_tr', id:'ss_node_table_v2ray_use_json', type:'checkbox', func:'v', help:'27', value:false},
																	{ title: '节点别名', rid:'ss_name_support_tr', id:'ss_node_table_name', type:'text', maxlen:'64', style:'width:338px'},
																	{ title: '服务器地址', rid:'ss_server_support_tr', id:'ss_node_table_server', type:'text', maxlen:'64', style:'width:338px'},
																	{ title: '服务器端口', rid:'ss_port_support_tr', id:'ss_node_table_port', type:'text', maxlen:'64', style:'width:338px'},
																	{ title: '密码', rid:'ss_passwd_support_tr', id:'ss_node_table_password', type:'text', maxlen:'64', style:'width:338px'},
																	{ title: '加密方式', rid:'ss_method_support_tr', id:'ss_node_table_method', type:'select', options:option_method, style:'width:350px', value: "aes-256-cfb"},
																	{ title: 'UDP通道', rid:'gameV2_udp_tr', id:'ss_node_table_koolgame_udp', type:'select', options:[["0", "udp in udp"], ["1", "udp in tcp"]], style:'width:350px', value: "0"},
																	{ title: '混淆 (obfs)', rid:'ss_obfs_support', id:'ss_node_table_ss_obfs', type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], style:'width:350px', value: "0"},
																	{ title: '混淆主机名 (obfs-host)', rid:'ss_obfs_host_support', id:'ss_node_table_ss_obfs_host', type:'text', maxlen:'300', style:'width:338px', ph:'bing.com'},
																	{ title: 'v2ray-plugin', rid:'ss_v2ray_support', id:'ss_node_table_ss_v2ray', type:'select', func:'v', options:[["0", "关闭"], ["1", "开启"]], style:'width:350px', value: "0"},
																	{ title: 'v2ray-plugin参数', rid:'ss_v2ray_opts_support', id:'ss_node_table_ss_v2ray_opts', type:'text', maxlen:'300', style:'width:338px', ph:'tls;host=example.com;path=/'},
																	{ title: '协议 (protocol)', rid:'ssr_protocol_tr', id:'ss_node_table_rss_protocol', type:'select', func:'v', options:option_protocals, style:'width:350px', value: "0"},
																	{ title: '协议参数 (protocol_param)', rid:'ssr_protocol_param_tr', id:'ss_node_table_rss_protocol_param', type:'text', maxlen:'300', style:'width:338px', ph:'id:password'},
																	{ title: '混淆 (obfs)', rid:'ssr_obfs_tr', id:'ss_node_table_rss_obfs', type:'select', func:'v', options:option_obfs, style:'width:350px', value: "0"},
																	{ title: '混淆参数 (obfs_param)', rid:'ssr_obfs_param_tr', id:'ss_node_table_rss_obfs_param', type:'text', maxlen:'300', style:'width:338px', ph:'bing.com'},
																	{ title: '用户id（id）', rid:'v2ray_uuid_tr', id:'ss_node_table_v2ray_uuid', type:'text', maxlen:'300', style:'width:338px'},
																	{ title: '额外ID (Alterld)', rid:'v2ray_alterid_tr', id:'ss_node_table_v2ray_alterid', type:'text', maxlen:'300', style:'width:338px'},
																	{ title: '加密方式 (security)', rid:'v2ray_security_tr', id:'ss_node_table_v2ray_security', type:'select', options:option_v2enc, style:'width:350px', value: "auto"},
																	{ title: '传输协议 (network)', rid:'v2ray_network_tr', id:'ss_node_table_v2ray_network', type:'select', func:'v', options:["tcp", "kcp", "ws", "h2"], style:'width:350px', value: "tcp"},
																	{ title: 'tcp伪装类型 (type)', rid:'v2ray_headtype_tcp_tr', id:'ss_node_table_v2ray_headtype_tcp', type:'select', func:'v', options:option_headtcp, style:'width:350px', value: "none"},
																	{ title: 'kcp伪装类型 (type)', rid:'v2ray_headtype_kcp_tr', id:'ss_node_table_v2ray_headtype_kcp', type:'select', func:'v', options:option_headkcp, style:'width:350px', value: "none"},
																	{ title: '伪装域名 (host)', rid:'v2ray_network_host_tr', id:'ss_node_table_v2ray_network_host', type:'text', maxlen:'300', style:'width:338px'},
																	{ title: '路径 (path)', rid:'v2ray_network_path_tr', id:'ss_node_table_v2ray_network_path', type:'text', maxlen:'300', style:'width:338px', ph:'没有请留空'},
																	{ title: '底层传输安全', rid:'v2ray_network_security_tr', id:'ss_node_table_v2ray_network_security', type:'select', options:[["none", "关闭"], ["tls", "tls"]], style:'width:350px', value: "none"},
																	{ title: '多路复用 (Mux)', rid:'v2ray_mux_enable_tr', id:'ss_node_table_v2ray_mux_enable', type:'checkbox', func:'v', value:false},
																	{ title: 'Mux并发连接数', rid:'v2ray_mux_concurrency_tr', id:'ss_node_table_v2ray_mux_concurrency', type:'text', maxlen:'300', style:'width:338px'},
																	{ title: 'v2ray json', rid:'v2ray_json_tr', id:'ss_node_table_v2ray_json', type:'textarea', rows:'32', ph:ph_v2ray, style:'width:344px'},
																]);
															</script>
															</table>
														</div>
													</td>
												</tr>
											</table>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" style="margin-left: 160px;" type="button" onclick="cancel_add_rule();" id="cancelBtn" value="返回">
												<input id="add_node" class="button_gen" type="button" onclick="add_ss_node_conf(save_flag);" value="添加">
												<input id="edit_node" style="display: none;" class="button_gen" type="button" onclick="edit_ss_node_conf(save_flag);" value="修改">
												<a id="continue_add" style="display: none;margin-left: 20px;"><input id="continue_add_box" type="checkbox"  />连续添加</a>
											</div>
											<!--===================================Ending of vpnc setting Content===========================================-->
										</div>
										<div id="tablet_0" style="display: none;">
											<table id="table_basic" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<script type="text/javascript">
													$('#table_basic').forms([
														{ title: '节点选择', id:'ssconf_basic_node', type:'select', func:'onchange="ss_node_sel();"', options:[], value: "1"},
														{ title: '模式', id:'ss_basic_mode', type:'select', func:'v', hint:'1', options:option_modes, value: "1"},
														{ title: '使用json配置', id:'ss_basic_v2ray_use_json', type:'checkbox', func:'v', hint:'27'},
														{ title: '服务器', id:'ss_basic_server', type:'text', maxlen:'100'},
														{ title: '服务器端口', id:'ss_basic_port', type:'text', maxlen:'100'},
														{ title: '密码', id:'ss_basic_password', type:'password', maxlen:'100', peekaboo:'1'},
														{ title: '加密方式', id:'ss_basic_method', type:'select', func:'v', hint:'5', options:option_method},
														{ title: 'UDP通道', id:'ss_basic_koolgame_udp', type:'select', func:'v', hint:'6', options:[["0", "udp in udp"], ["1", "udp in tcp"]], value: "0"},
														{ title: '混淆 (obfs)', id:'ss_basic_ss_obfs', type:'select', func:'v', options:[["0", "关闭"], ["tls", "tls"], ["http", "http"]], value: "0"},
														{ title: '混淆主机名 (obfs_host)', id:'ss_basic_ss_obfs_host', type:'text', maxlen:'100', ph:'bing.com'},
														{ title: 'v2ray-plugin', id:'ss_basic_ss_v2ray', type:'select', hint: '7', func:'v', options:[["0", "关闭"], ["1", "打开"]], value: "0"},
														{ title: 'v2ray-plugin参数', id:'ss_basic_ss_v2ray_opts', type:'text', maxlen:'300', ph:'tls;host=yourhost.com;path=/;'},
														{ title: '协议 (protocol)', id:'ss_basic_rss_protocol', type:'select', func:'v', options:option_protocals},
														{ title: '协议参数 (protocol_param)', id:'ss_basic_rss_protocol_param', type:'password', hint:'54', maxlen:'100', ph:'id:password', peekaboo:'1'},
														{ title: '混淆 (obfs)', id:'ss_basic_rss_obfs', type:'select', func:'v', options:option_obfs},
														{ title: '混淆参数 (obfs_param)', id:'ss_basic_rss_obfs_param', type:'text', hint:'11', maxlen:'300', ph:'cloudflare.com;bing.com'},
														{ title: '用户id (id)', id:'ss_basic_v2ray_uuid', type:'password', hint:'49', maxlen:'300', style:'width:300px;', peekaboo:'1'},
														{ title: '额外ID (Alterld)', id:'ss_basic_v2ray_alterid', type:'text', hint:'48', maxlen:'50'},
														{ title: '加密方式 (security)', id:'ss_basic_v2ray_security', type:'select', hint:'47', options:option_v2enc},
														{ title: '传输协议 (network)', id:'ss_basic_v2ray_network', type:'select', func:'v', hint:'35', options:["tcp", "kcp", "ws", "h2"]},
														{ title: '* tcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_tcp', type:'select', func:'v', hint:'36', options:option_headtcp},
														{ title: '* kcp伪装类型 (type)', id:'ss_basic_v2ray_headtype_kcp', type:'select', func:'v', hint:'37', options:option_headkcp},
														{ title: '* 伪装域名 (host)', id:'ss_basic_v2ray_network_host', type:'text', hint:'28', maxlen:'300', ph:'没有请留空'},
														{ title: '* 路径 (path)', id:'ss_basic_v2ray_network_path', type:'text', hint:'29', maxlen:'300', ph:'没有请留空'},
														{ title: '底层传输安全', id:'ss_basic_v2ray_network_security', type:'select', hint:'30', options:[["none", "关闭"], ["tls", "tls"]]},
														{ title: '多路复用 (Mux)', id:'ss_basic_v2ray_mux_enable', type:'checkbox', func:'v', hint:'31'},
														{ title: 'Mux并发连接数', id:'ss_basic_v2ray_mux_concurrency', type:'text', hint:'32', maxlen:'300'},
														{ title: 'v2ray json', id:'ss_basic_v2ray_json', type:'textarea', rows:'36', ph:ph_v2ray},
														{ title: '其它', rid:'v2ray_binary_update_tr', prefix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="v2ray_binary_update(2)">更新V2Ray程序</a>'}
													]);
												</script>
											</table>
										</div>
										<div id="tablet_1" style="display: none;">
											<div id="ss_list_table"></div>
										</div>
										<div id="tablet_2" style="display: none;">
											<table id="table_failover" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<script type="text/javascript">
													var fa1 = ["2", "3", "4", "5"];
													var fa2_1 = ["10", "15", "20"];
													var fa2_2 = ["2", "3", "4", "5", "6", "7", "8"];
													var fa3_1 = ["10", "15", "20"];
													var fa3_2 = ["100", "150", "200", "250", "300", "350", "400", "450", "500", "1000"];
													var fa4_1 = [["0", "关闭插件"], ["1", "重启插件"], ["2", "切换到"]];
													var fa4_2 = [["1", "备用节点"], ["2", "下个节点"]];
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
															{ suffix:'<lable id="ss_failover_text_1">&nbsp;，即在节点列表内顺序循环。&nbsp;</lable>' },
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
											<div align="center" style="margin-top: 10px;">
												<input class="button_gen" type="button" onclick="save()" value="保存&amp;应用">
												<input style="margin-left:10px" id="ss_failover_save" class="button_gen" onclick="save_failover()" type="button" value="保存本页设置">
											</div>
											
										</div>
										<div id="tablet_3" style="display: none;">
											<table id="table_dns" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<script type="text/javascript">
													var option_dnsc = [["1", "运营商DNS【自动获取】"], ["2", "阿里DNS1【223.5.5.5】"], ["3", "阿里DNS2【223.6.6.6】"], ["4", "114DNS1【114.114.114.114】"], ["5", "114DNS2【114.114.115.115】"], ["6", "cnnic DNS1【1.2.4.8】"], ["7", "cnnic DNS2【210.2.4.8】"], ["8", "oneDNS1【117.50.11.11】"], ["9", "oneDNS2【117.50.11.22】"], ["10", "百度DNS【180.76.76.76】"], ["11", "DNSpod DNS【119.29.29.29】"], ["13", "SmartDNS"], ["12", "自定义DNS"]];
													var option_dnsf = [["3", "dns2socks"], ["4", "ss-tunnel"], ["1", "cdns"], ["5", "chinadns1"], ["2", "chinadns2"], ["6", "https_dns_proxy"], ["7", "v2ray_dns"], ["9", "SmartDNS"], ["8", "直连"]];
													var option_dnsr = [["1", "运营商DNS【自动获取】"], ["2", "阿里DNS1【223.5.5.5】"], ["3", "阿里DNS2【223.6.6.6】"], ["4", "114DNS1【114.114.114.114】"], ["5", "114DNS2【114.114.115.115】"], ["6", "cnnic DNS1【1.2.4.8】"], ["7", "cnnic DNS2【210.2.4.8】"], ["8", "oneDNS1【117.50.11.11】"], ["9", "oneDNS2【117.50.11.22】"], ["10", "百度DNS【180.76.76.76】"], ["11", "DNSpod DNS【119.29.29.29】"], ["13", "google DNS1【8.8.8.8】"], ["14", "google DNS2【8.8.4.4】"], ["15", "IBM DNS【9.9.9.9】"], ["12", "自定义DNS"]];
													var ph1 = "需端口号如：8.8.8.8:53"
													var ph2 = "需端口号如：8.8.8.8#53"
													var ph3 = "# 填入自定义的dnsmasq设置，一行一个&#10;# 例如hosts设置：&#10;address=/weibo.com/2.2.2.2&#10;# 防DNS劫持设置：&#10;bogus-nxdomain=220.250.64.18"
													$('#table_dns').forms([
														{ title: '选择中国DNS', multi: [
															{ id: 'ss_dns_china', type:'select', func:'u', options:option_dnsc, style:'width:auto;', value:'11'},
															{ id: 'ss_dns_china_user', type: 'text', ph:'114.114.114.114' }
														]},
														{ title: '选择外国DNS', hint:'26', rid:'dns_plan_foreign', multi: [
															{ id: 'ss_foreign_dns', type:'select', func:'u', options:option_dnsf, style:'width:auto;'},
															{ id: 'ss_dns2socks_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },
															{ id: 'ss_chinadns1_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },
															{ id: 'ss_chinadns_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },
															{ id: 'ss_sstunnel_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },
															{ id: 'ss_direct_user', type: 'text', value:'8.8.8.8#53', ph:ph2 },
															{ suffix: '&nbsp;&nbsp;<span id="ss_foreign_dns_note"></span>' },
														]},
														{ title: '选择外国DNS', rid:'dns_plan_foreign_game2', multi: [
															{ id: 'ss_game2_dns_foreign', type:'select', func:'u', disabled:'1', options:[["1", "koolgame内置"]], style:'width:auto;'},
															{ id: 'ss_game2_dns2ss_user', type: 'text', value:'8.8.8.8:53', ph:ph1 },
															{ suffix: '<br/>&nbsp;<span id="dns_plan_foreign0">默认使用koolgame内置的DNS2SS域名解析</span>' },
														]},														
														{ title: 'DNS劫持（原chromecast功能）', id:'ss_basic_dns_hijack', type:'checkbox', func:'v', hint:'106', value:true},
														{ title: '节点域名解析DNS服务器', hint:'107', multi: [
															{ id: 'ss_basic_server_resolver', type:'select', func:'u', options:option_dnsr, style:'width:auto;', value:'13'},
															{ id: 'ss_basic_server_resolver_user', type: 'text'},
														]},	
														{ title: '自定义dnsmasq', id:'ss_dnsmasq', type:'textarea', hint:'34', rows:'12', ph:ph3},
													]);
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
															{ suffix: '<a href="https://github.com/hq450/fancyss/blob/master/rules/gfwlist.conf" target="_blank">' },
															{ suffix: '<i><% nvram_get("update_ipset"); %></i></a>' },
														]},
														{ title: '大陆白名单IP段数量', multi: [
															{ suffix: '<em>'+ chnl +'</em>&nbsp;行，包含 <em>' + chnn + '</em>&nbsp;个ip地址，版本：' },
															{ suffix: '<a href="https://github.com/hq450/fancyss/blob/master/rules/chnroute.txt" target="_blank">' },
															{ suffix: '<i><% nvram_get("update_chnroute"); %></i></a>' },
														]},
														{ title: '国内域名数量（cdn名单）', multi: [
															{ suffix: '<em>'+ cdnn +'</em>&nbsp;条，版本：' },
															{ suffix: '<a href="https://github.com/hq450/fancyss/blob/master/rules/cdn.txt" target="_blank">' },
															{ suffix: '<i><% nvram_get("update_cdn"); %></i></a>' },
														]},
														{ title: '规则定时更新任务', hint:'44', multi: [
															{ id:'ss_basic_rule_update', type:'select', func:'u', style:'width:auto', options:[["0", "禁用"], ["1", "开启"]], value:'0'},
															{ id:'ss_basic_rule_update_time', type:'select', style:'width:auto', options:option_ruleu, value:'4'},
															{ suffix: '<a id="update_choose">' },
															{ suffix: '<input type="checkbox" id="ss_basic_gfwlist_update" title="选择此项应用gfwlist自动更新">gfwlist' },
															{ suffix: '<input type="checkbox" id="ss_basic_chnroute_update">chnroute' },
															{ suffix: '<input type="checkbox" id="ss_basic_cdn_update">CDN</a>' },
															{ suffix: '&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(1)">保存设置</a>' },
															{ suffix: '&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(2)">立即更新</a>' },
														]},
														{ title: 'V2ray二进制更新', prefix: '<a type="button" class="ss_btn" style="cursor:pointer" onclick="v2ray_binary_update(2)">更新V2Ray程序</a>'}
													]);
												</script>
											</table>
											<table id="table_subscribe" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<script type="text/javascript">
													var option_noded = [["7", "每天"], ["1", "周一"], ["2", "周二"], ["3", "周三"], ["4", "周四"], ["5", "周五"], ["6", "周六"], ["6", "周日"]];
													var option_nodeh = [];
													for (var i = 0; i < 24; i++){
														var _tmp = [];
														_i = String(i)
														_tmp[0] = _i;
														_tmp[1] = _i + "点";
														option_nodeh.push(_tmp);
													}
													var ph1 = "填入需要订阅的地址，多个地址分行填写";
													var ph2 = "多个关键词用英文逗号分隔，如：测试,过期,剩余,曼谷,M247,D01,硅谷";
													var ph3 = "多个关键词用英文逗号分隔，如：香港,深圳,NF,BGP";
													$('#table_subscribe').forms([
														{ title: 'SSR/v2ray订阅设置', thead:'1'},
														{ title: '订阅地址管理（支持SSR/v2ray）', id:'ss_online_links', type:'textarea', rows:'8', ph:ph1},
														{ title: '订阅节点模式设定（SSR/v2ray）', id:'ssr_subscribe_mode', type:'select', style:'width:auto', options:option_modes, value:'2'},
														{ title: '订阅节点混淆参数设定（SSR）', multi: [
															{ id:'ssr_subscribe_obfspara', type:'select', style:'width:auto', func:'u', options:[["0", "留空"], ["1", "使用订阅设定"], ["2", "自定义"]], value:'1'},
															{ id:'ssr_subscribe_obfspara_val', type:'text', style:'width:350px', maxlen:'300', value:'www.baidu.com'},
														]},
														{ title: '下载订阅时走SS/SSR/v2ray代理网络', id:'ss_basic_online_links_goss', type:'select', style:'width:auto', options:[["0", "不走代理"], ["1", "走代理"]], value:'0'},
														{ title: '订阅计划任务', multi: [
															{ id:'ss_basic_node_update', type:'select', style:'width:auto', func:'u', options:[["0", "禁用"], ["1", "开启"]], value:'0'},
															{ id:'ss_basic_node_update_day', type:'select', style:'width:auto', options:option_noded, value:'6'},
															{ id:'ss_basic_node_update_hr', type:'select', style:'width:auto', options:option_nodeh, value:'3'},
														]},
														{ title: '[排除]关键词（含关键词的节点不会添加）', rid:'ss_basic_exclude_tr', id:'ss_basic_exclude', type:'text', hint:'110', maxlen:'300', style:'width:95%', ph:ph2},
														{ title: '[包括]关键词（含关键词的节点才会添加）', rid:'ss_basic_include_tr', id:'ss_basic_include', type:'text', hint:'111', maxlen:'300', style:'width:95%', ph:ph3},
														{ title: '删除节点', multi: [
															{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(0)">删除全部节点</a>'},
															{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(1)">删除全部订阅节点</a>'},
														]},
														{ title: '订阅操作', multi: [
															{ suffix:'<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(2)">仅保存设置</a>'},
															{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(3)">保存并订阅</a>'},
														]},
													]);
												</script>
											</table>
											<table id="table_link" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<script type="text/javascript">
													var ph1 = "填入以ss://或者ssr://或者vmess://开头的链接，多个链接请分行填写";
													$('#table_subscribe').forms([
														{ title: '通过SS/SSR/vmess链接添加服务器', thead:'1'},
														{ title: 'SS/SSR/vmess链接', id:'ss_base64_links', type:'textarea', rows:'9', ph:ph1},
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
											<table id="table_addons" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
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
													var pingm = [["1", "ping(1次/节点)"], ["2", "ping(5次/节点)"], ["3", "ping(10次/节点)"], ["4", "ping(20次/节点)"]];
													var option_dnsfast = [["0", "【0】不替换"], ["1", "【1】插件开启后替换，插件关闭后恢复原版dnsmasq"], ["2", "【2】在用到cdn.conf时替换，插件关闭后恢复原版dnsmasq"], ["3", "【3】插件开启后替换，插件关闭后保持替换，不恢复原版dnsmasq"]]
													$('#table_addons').forms([
														{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">备份/恢复</td></tr>'},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;导出SS配置', hint:'24', multi: [
															{ suffix:'<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_SS_node(1);" value="导出配置">'},
															{ suffix:'&nbsp;<input type="button" class="ss_btn" style="cursor:pointer;" onclick="remove_SS_node();" value="清空配置">'},
															{ suffix:'&nbsp;<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_SS_node(2);" value="打包插件">'},
														]},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;恢复SS配置（支持ss/ssr的json节点）', hint:'24', multi: [
															{ suffix:'<input style="color:#FFCC00;*color:#000;width: 200px;" id="ss_file" type="file" name="file"/>'},
															{ suffix:'<img id="loadingicon" style="margin-left:5px;margin-right:5px;display:none;" src="/images/InternetScan.gif"/>'},
															{ suffix:'<span id="ss_file_info" style="display:none;">完成</span>'},
															{ suffix:'<input type="button" class="ss_btn" style="cursor:pointer;" onclick="upload_ss_backup();" value="恢复配置"/>'},
														]},											
														{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">定时任务</td></tr>'},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;插件定时重启设定', multi: [
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
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;插件触发重启设定', multi: [
															{ id:'ss_basic_tri_reboot_time', type:'select', style:'width:auto', help:'109', func:'u', options:option_trit, value:'0'},
															{ suffix:'<span id="ss_basic_tri_reboot_time_note">&nbsp;解析服务器IP，如果发生变更，则重启插件！</span>'},
															{ suffix:'&nbsp;<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(2)">保存设置</a>'},
														]},
														{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">节点列表</td></tr>'},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;ping测试设置', multi: [
															{ id:'ss_basic_ping_node', type:'select', style:'width:auto;max-width:220px', func:'onchange="ping_switch();"', options:[]},
															{ id:'ss_basic_ping_method', type:'select', style:'width:auto', help:'109', options:pingm, value:'1'},
															{ suffix:'&nbsp;<input id="ss_basic_ping_btn" class="ss_btn" style="cursor:pointer;" onClick="ping_now()" type="button" value="开始ping！"/>'},
														]},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;节点列表最大显示行数', id:'ss_basic_row', type:'select', func:'onchange="save_row();"', style:'width:auto', options:[]},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;开启生成二维码功能', id:'ss_basic_qrcode', func:'v', type:'checkbox', value:true},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;开启节点排序功能', id:'ss_basic_dragable', func:'v', type:'checkbox', value:true},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;设置节点列表为默认标签页', id:'ss_basic_tablet', func:'v', type:'checkbox', value:false},
														{ td: '<tr><td class="smth" style="font-weight: bold;" colspan="2">性能优化</td></tr>'},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;ss/ssr 开启多核心支持', id:'ss_basic_mcore', help:'108', type:'checkbox', value:true},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;ss-libev / v2ray 开启tcp fast open', id:'ss_basic_tfo', type:'checkbox', value:false},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;ss-libev 开启TCP_NODELAY', id:'ss_basic_tnd', type:'checkbox', value:false},
														{ title: '&nbsp;&nbsp;&nbsp;&nbsp;替换为dnsmasq-fastlookup', id:'ss_basic_dnsmasq_fastlookup', help:'105', type:'select', style:'width:auto', options:option_dnsfast},
													]);
												</script> 
											</table>
										</div>
										<div id="tablet_10" style="display: none;">
												<div id="log_content" style="margin-top:-1px;overflow:hidden;">
													<textarea cols="63" rows="36" wrap="on" readonly="readonly" id="log_content1" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
										</div>
										<div class="apply_gen" id="loading_icon">
											<img id="loadingIcon" style="display:none;" src="/images/InternetScan.gif">
										</div>
										<div id="apply_button" class="apply_gen">
											<input class="button_gen" type="button" onclick="save()" value="保存&应用">
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
