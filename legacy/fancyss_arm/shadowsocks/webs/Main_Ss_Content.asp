<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
<meta HTTP-EQUIV="Expires" CONTENT="-1"/>
<link rel="shortcut icon" href="images/favicon.png"/>
<link rel="icon" href="images/favicon.png"/>
<title>【科学上网】</title>
<link rel="stylesheet" type="text/css" href="index_style.css"/>
<link rel="stylesheet" type="text/css" href="form_style.css"/>
<link rel="stylesheet" type="text/css" href="usp_style.css"/>
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/dbconf?p=ss&v=<% uptime(); %>"></script>
<script>
var isMenuopen = 0;
var _responseLen;
var noChange = 0;
var noChange2 = 0;
var node_global_max = 0;
var myid;
var checkss = 0;
var poped = 0;
var x = 5;
var refreshRate;

function init() {
	show_menu(menu_hook);
	update_ss_ui(db_ss);
	loadAllConfigs();
	decode_show();
	toggle_func();
	version_show();
	hook_event();
	detect();
	setTimeout("get_ss_status_data()", 500);
}

function hide_elem(){
	E("head_illustrate").style.display = "none";
	E("ss_switch_show").style.display = "none";
	E("ss_status1").style.display = "none";
	E("tablets").style.display = "none";
	E("tablet_1").style.display = "none";
	E("apply_button").style.display = "none";
	E("ss_switch_show").style.display = "none";
}

function detect(){
	var jff2_scripts="<% nvram_get("jffs2_scripts"); %>";
	var sw_mode="<% nvram_get("sw_mode"); %>";
	var dnsfilter_enable="<% nvram_get("dnsfilter_enable"); %>";
	var fw_version="<% nvram_get("extendno"); %>";
	var fw_version=parseFloat("<% nvram_get("extendno"); %>".split("X")[1]).toFixed(1);
	if(jff2_scripts != 1){ //没有开启 JFFS scripts选项
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【科学上网】插件不可用！因为你没有开启Enable JFFS custom scripts and configs选项！</h2><h2>请前往【系统管理】-<a href="Advanced_System_Content.asp"><u><em>【系统设置】</em></u></a>开启此选项再使用软件中心！！</h2>');
	}
	if(sw_mode != 1){ //使用的不是路由模式
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【科学上网】插件不可用！因为你的设备工作在非路由模式下！</h2><h2>请前往【系统管理】-<a href="Advanced_OperationMode_Content.asp"><u><em>【操作模式】</em></u></a>中选择无线路由器模式！才能正常使用本插件！</h2>');
	}
	if(dnsfilter_enable == 1){ //开启了DNSFilter
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【科学上网】插件不可用！因为开启了DNS过滤！</h2><h2>请前往【智能网络卫士】-<a href="DNSFilter.asp"><u><em>【DNS Filtering】</em></u></a>中关闭DNS过滤！才能正常使用本插件！</h2>');
	}
	if(fw_version < 7.2){ //固件版本过低，不兼容
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【科学上网】插件不可用！因为你的固件版本低于X7.2！</h2><h2>请更新最新固件！</h2>');
	}
}

function hook_event() {
	$("#mode_state").attr("cursor", "pointer");
	$("#mode_state").click(
	function() {
		pop_111();
	});
	
	$("#ss_basic_enable").click(
	function() {
		if (!E("ss_basic_enable").checked && db_ss["ss_basic_enable"] == 1) {
			save();
		}
	});
	//for udp tables
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
}

function pop_111() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 2,
			shade: .7,
			scrollbar: 0,
			title: '国内外分流信息:ip111.cn',
			area: ['750px', '480px'],
			//offset: ['355px', '368px'],
			fixed: false, //不固定
			maxmin: true,
			shadeClose: 1,
			id: 'LAY_layuipro',
			btnAlign: 'c',
			content: ['http://ip111.cn/', 'no'],
		});
	});
}

function pop_help() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 1,
			title: false,
			closeBtn: false,
			area: '600px;',
			//offset: ['355px', '443px'],
			shade: 0.8,
			shadeClose: 1,
			scrollbar: false,
			id: 'LAY_layuipro',
			btn: ['关闭窗口'],
			btnAlign: 'c',
			moveType: 1,
			content: '<div style="padding: 50px; line-height: 22px; background-color: #393D49; color: #fff; font-weight: 300;">\
				<b>梅林固件 - 科学上网插件 - ' + db_ss["ss_basic_version_local"] + '</b><br><br>\
				本插件是支持<a target="_blank" href="https://github.com/shadowsocks/shadowsocks-libev" ><u>SS</u></a>、<a target="_blank" href="https://github.com/shadowsocksrr/shadowsocksr-libev"><u>SSR</u></a>、<a target="_blank" href="http://firmware.koolshare.cn/binary/koolgame"><u>KoolGame</u></a>、<a target="_blank" href="https://github.com/v2ray/v2ray-core"><u>V2Ray</u></a>四种客户端的科学上网、游戏加速工具。<br>\
				本插件仅支持Merlin AM380 2.6.36.4内核的固件，请不要用于其它固件安装。<br>\
				使用本插件有任何问题，可以前往<a style="color:#e7bd16" target="_blank" href="https://github.com/hq450/fancyss/issues"><u>github的issue页面</u></a>反馈~<br><br>\
				● SS/SSR一键脚本：<a style="color:#e7bd16" target="_blank" href="https://github.com/onekeyshell/kcptun_for_ss_ssr/tree/master"><u>一键安装KCPTUN for SS/SSR on Linux</u></a><br>\
				● koolgame一键脚本：<a style="color:#e7bd16" target="_blank" href="https://github.com/clangcn/game-server"><u>一键安装koolgame服务器端脚本，完美支持nat2</u></a><br>\
				● V2Ray一键脚本：<a style="color:#e7bd16" target="_blank" href="https://233blog.com/post/17/"><u>V2Ray 搭建和优化详细图文教程</u></a><br>\
				● 插件交流：<a style="color:#e7bd16" target="_blank" href="https://t.me/joinchat/AAAAAEC7pgV9vPdPcJ4dJw"><u>加入telegram群组</u></a><br><br>\
				我们的征途是星辰大海 ^_^</div>'
		});
	});
}

function pop_node_add() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 0,
			shade: 0.8,
			title: '警告',
			time: 0,
			//area: ['390px', '330px'],
			maxmin: true,
			content: '你尚未添加任何节点信息！<br /> 点击下面按钮添加节点信息！',
			btn: ['手动添加', '订阅节点', '恢复配置'],
			yes: function() {
				$("#show_btn1_1").trigger("click");
				setTimeout("pop_tip()", 600);
				//layer.closeAll();
				layer.msg('请选择需要添加的节点类型', {
					shade: 0.2,
					time: 20000, //20s后自动关闭
					area: ['450px'],
					btn: ['添加ss节点', '添加ssr节点', '添加koolgame节点', '添加V2Ray节点'],
					btnAlign: 'c',
					btn1: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(0);", 320);
						layer.closeAll();
					},
					btn2: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(1);", 320);
					},
					btn3: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(2);", 320);
					},
					btn4: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(3);", 320);
					}
				});
			},
			btn2: function() {
				$("#show_btn4").trigger("click");
			},
			btn3: function() {
				$("#show_btn6").trigger("click");
			},
		});
		poped = 1;
	});
}

function pop_tip(){
	layer.tips('以后需要添加节点，可以点击此按钮！', '#add_ss_node', {
		tips: [1, '#3595CC'],
		time: 5000
	});
}

function isJSON(str) {
	if (typeof str == 'string' && str) {
		try {
			var obj = JSON.parse(str);
			if (typeof obj == 'object' && obj) {
				return true;
			} else {
				return false;
			}
		} catch (e) {
			console.log('error：' + str + '!!!' + e);
			return false;
		}
	}
	//console.log('It is not a string!')
}

function save() {
	var node_sel = E("ssconf_basic_node").value
	if (!node_sel) {
		alert("你尚未定义任何节点，提交失败！");
		return false
	}
	//stop check status
	checkss = 10001;
	E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
	E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
	//remove blank before string
	E("ss_basic_server").value = $.trim($("#ss_basic_server").val());
	E("ss_basic_port").value = $.trim($("#ss_basic_port").val());
	E("ss_basic_password").value = $.trim($("#ss_basic_password").val());
	//define dbus obkect to save
	var dbus = {};
	//key define
	var params_input = ["ssconf_basic_node", "ss_basic_mode", "ss_basic_server", "ss_basic_port", "ss_basic_method", "ss_basic_koolgame_udp", "ss_basic_ss_v2ray_plugin", "ss_basic_ss_v2ray_plugin_opts", "ss_basic_rss_protocol", "ss_basic_rss_protocol_param", "ss_basic_rss_obfs", "ss_basic_rss_obfs_param", "ssconf_basic_ping_node", "ssconf_basic_ping_method", "ssconf_basic_test_node", "ssconf_basic_test_domain", "ss_dns_china", "ss_dns_china_user", "ss_foreign_dns", "ss_dns2socks_user", "ss_chinadns_user", "ss_chinadns1_user",  "ss_sstunnel_user", "ss_direct_user", "ss_game2_dns_foreign", "ss_game2_dns2ss_user", "$ss_basic_kcp_lserver", "ss_basic_kcp_lport", "ss_basic_kcp_server", "ss_basic_kcp_port", "ss_basic_kcp_parameter", "ss_basic_rule_update", "ss_basic_rule_update_time", "ssr_subscribe_mode", "ssr_subscribe_obfspara", "ssr_subscribe_obfspara_val", "ss_basic_online_links_goss", "ss_basic_node_update", "ss_basic_node_update_day", "ss_basic_node_update_hr", "ss_base64_links", "ss_basic_refreshrate", "ss_basic_refreshrate", "ss_acl_default_port", "ss_online_action", "ss_acl_default_mode", "ss_basic_kcp_method", "ss_basic_kcp_password", "ss_basic_kcp_mode", "ss_basic_kcp_encrypt", "ss_basic_kcp_mtu", "ss_basic_kcp_sndwnd", "ss_basic_kcp_rcvwnd", "ss_basic_kcp_conn", "ss_basic_kcp_extra", "ss_basic_udp_software", "ss_basic_udp_node", "ss_basic_udpv1_lserver", "ss_basic_udpv1_lport", "ss_basic_udpv1_rserver", "ss_basic_udpv1_rport", "ss_basic_udpv1_password", "ss_basic_udpv1_mode", "ss_basic_udpv1_duplicate_nu", "ss_basic_udpv1_duplicate_time", "ss_basic_udpv1_jitter", "ss_basic_udpv1_report", "ss_basic_udpv1_drop", "ss_basic_udpv2_lserver", "ss_basic_udpv2_lport", "ss_basic_udpv2_rserver", "ss_basic_udpv2_rport", "ss_basic_udpv2_password", "ss_basic_udpv2_fec", "ss_basic_udpv2_timeout", "ss_basic_udpv2_mode", "ss_basic_udpv2_report", "ss_basic_udpv2_mtu", "ss_basic_udpv2_jitter", "ss_basic_udpv2_interval", "ss_basic_udpv2_drop", "ss_basic_udpv2_other", "ss_basic_udp2raw_lserver", "ss_basic_udp2raw_lport", "ss_basic_udp2raw_rserver", "ss_basic_udp2raw_rport", "ss_basic_udp2raw_password", "ss_basic_udp2raw_rawmode", "ss_basic_udp2raw_ciphermode", "ss_basic_udp2raw_authmode", "ss_basic_udp2raw_lowerlevel", "ss_basic_udp2raw_other", "ss_basic_udp_upstream_mtu", "ss_basic_udp_upstream_mtu_value", "ss_basic_v2ray_uuid", "ss_basic_v2ray_alterid", "ss_basic_v2ray_security", "ss_basic_v2ray_network", "ss_basic_v2ray_headtype_tcp", "ss_basic_v2ray_headtype_kcp", "ss_basic_v2ray_network_path", "ss_basic_v2ray_network_host", "ss_basic_v2ray_network_security", "ss_basic_v2ray_mux_concurrency", "ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_time_hour", "ss_basic_time_min", "ss_basic_tri_reboot_time", "ss_basic_tri_reboot_policy", "ss_basic_dnsmasq_fastlookup", "ss_basic_server_resolver", "ss_basic_server_resolver_user"];
	var params_check = ["ss_basic_enable", "ss_basic_use_kcp", "ss_basic_gfwlist_update", "ss_basic_chnroute_update", "ss_basic_cdn_update", "ss_basic_kcp_nocomp", "ss_basic_udp_boost_enable", "ss_basic_udpv1_disable_filter", "ss_basic_udpv2_disableobscure", "ss_basic_udpv2_disablechecksum", "ss_basic_udp2raw_boost_enable", "ss_basic_udp2raw_a", "ss_basic_udp2raw_keeprule", "ss_basic_v2ray_use_json", "ss_basic_v2ray_mux_enable", "ss_basic_dns_hijack"];
	var params_base64_a = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links"];
	var params_base64_b = ["ss_basic_password", "ss_basic_custom"];
	// collect data from input
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			dbus[params_input[i]] = E(params_input[i]).value;
		}
	}
	// collect data from checkbox
	for (var i = 0; i < params_check.length; i++) {
		dbus[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	// data need base64 encode:format a with "."
	for (var i = 0; i < params_base64_a.length; i++) {
		if (!E(params_base64_a[i]).value || E(params_base64_a[i]).value.indexOf(".") != -1) {
			dbus[params_base64_a[i]] = Base64.encode(E(params_base64_a[i]).value);
		} else {
			//乱码了或者格式不对！
			console.log("格式不正确")
			dbus[params_base64_a[i]] = "";
		}
	}
	// data need base64 encode, format b with plain text
	for (var i = 0; i < params_base64_b.length; i++) {
		dbus[params_base64_b[i]] = Base64.encode(E(params_base64_b[i]).value);
	}
	// for v2ray json, we need to process first: parse vmess:// format, encode json format
	if(E('ss_basic_v2ray_json').value.indexOf("vmess://") != -1){
		var vmess_node = JSON.parse(Base64.decode(E('ss_basic_v2ray_json').value.split("//")[1]));
		dbus["ss_basic_server"] = vmess_node.add;
		dbus["ssconf_basic_server_" + node_sel] = vmess_node.add;
		dbus["ss_basic_port"] = vmess_node.port;
		dbus["ssconf_basic_port_" + node_sel] = vmess_node.port;
		dbus["ss_basic_v2ray_uuid"] = vmess_node.id;
		dbus["ssconf_basic_v2ray_uuid_" + node_sel] = vmess_node.id;
		dbus["ss_basic_v2ray_security"] = "auto";
		dbus["ssconf_basic_v2ray_security_" + node_sel] = "auto";
		dbus["ss_basic_v2ray_alterid"] = vmess_node.aid;
		dbus["ssconf_basic_v2ray_alterid_" + node_sel] = vmess_node.aid;
		dbus["ss_basic_v2ray_network"] = vmess_node.net;
		dbus["ssconf_basic_v2ray_network_" + node_sel] = vmess_node.net;
		if(vmess_node.net == "tcp"){
			dbus["ss_basic_v2ray_headtype_tcp"] = vmess_node.type;
			dbus["ssconf_basic_v2ray_headtype_tcp_" + node_sel] = vmess_node.type;
		}else if(vmess_node.net == "kcp"){
			dbus["ss_basic_v2ray_headtype_kcp"] = vmess_node.type;
			dbus["ssconf_basic_v2ray_headtype_kcp_" + node_sel] = vmess_node.type;
		}
		dbus["ss_basic_v2ray_network_host"] = vmess_node.host;
		dbus["ssconf_basic_v2ray_network_host_" + node_sel] = vmess_node.host;
		dbus["ss_basic_v2ray_network_path"] = vmess_node.path;
		dbus["ssconf_basic_v2ray_network_path_" + node_sel] = vmess_node.path;
		if(vmess_node.tls == "tls"){
			dbus["ss_basic_v2ray_network_security"] = "tls";
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "tls";
		}else{
			dbus["ss_basic_v2ray_network_security"] = "none";
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "none";
		}
		dbus["ss_basic_v2ray_mux_enable"] = 1;
		dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = 1;
		dbus["ss_basic_v2ray_mux_concurrency"] = 8;
		dbus["ssconf_basic_v2ray_mux_concurrency_" + node_sel] = 8;
		dbus["ss_basic_v2ray_use_json"] = 0;
		dbus["ssconf_basic_v2ray_use_json_" + node_sel] = 0;
		dbus["ss_basic_v2ray_json"] = "";
		dbus["ssconf_basic_v2ray_json"] = "";
	}else{
		if (E("ss_basic_v2ray_use_json").checked == true){
			if(isJSON(E('ss_basic_v2ray_json').value)){
				if(E('ss_basic_v2ray_json').value.indexOf("outbound") != -1){
					dbus["ss_basic_v2ray_json"] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
					dbus["ssconf_basic_v2ray_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
					var param_v2 = ["server", "port", "v2ray_uuid", "v2ray_security", "v2ray_alterid", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_host", "v2ray_network_path", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency"];
					for (var i = 0; i < param_v2.length; i++) {
						dbus["ss_basic_" + param_v2[i]] = "";
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
	var params = ["server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"];
	for (var i = 0; i < params.length; i++) {
		dbus["ssconf_basic_" + params[i] + "_" + node_sel] = E("ss_basic_" + params[i]).value;
	}
	// node data: checkbox
	dbus["ssconf_basic_use_kcp_" + node_sel] = E("ss_basic_use_kcp").checked ? '1' : '0';
	dbus["ssconf_basic_v2ray_use_json_" + node_sel] = E("ss_basic_v2ray_use_json").checked ? '1' : '0';
	dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = E("ss_basic_v2ray_mux_enable").checked ? '1' : '0';
	// node data: base64
	dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
	// collect values in acl table
	maxid = parseInt($("#ACL_table > tbody > tr:eq(-2) > td:nth-child(2) > input").attr("id").split("_")[3]);
	if(maxid){
		for ( var i = 1; i <= maxid; ++i ) {
			if (E("ss_acl_name_" + i)){
				dbus["ss_acl_name_" + i] = E("ss_acl_name_" + i).value;
				dbus["ss_acl_mode_" + i] = E("ss_acl_mode_" + i).value;
				dbus["ss_acl_port_" + i] = E("ss_acl_port_" + i).value;
			}
		}
	}
	// adjust some value when switch node between ss ssr v2ray koolgame
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
		var remove_ssr = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
		//console.log("use ssr");
		dbus["ss_basic_type"] = "1"
		dbus["ssconf_basic_type_" + node_sel] = "1"
		for (var i = 0; i < remove_ssr.length; i++) {
			dbus["ss_basic_" + remove_ssr[i]] = "";
			dbus["ssconf_basic_" + remove_ssr[i] + "_" + node_sel] = "";
		}
	} else {
		if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
			var remove_gamev2 = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
			//console.log("use v2");
			dbus["ss_basic_type"] = "2"
			dbus["ssconf_basic_type_" + node_sel] = "2"
			for (var i = 0; i < remove_gamev2.length; i++) {
				dbus["ss_basic_" + remove_gamev2[i]] = "";
				dbus["ssconf_basic_" + remove_gamev2[i] + "_" + node_sel] = "";
			}
		} else {
			if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
				var remove_v2ray = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"];
				//console.log("use v2ray");
				dbus["ss_basic_type"] = "3"
				dbus["ssconf_basic_type_" + node_sel] = "3"
				for (var i = 0; i < remove_v2ray.length; i++) {
					dbus["ss_basic_" + remove_v2ray[i]] = "";
					dbus["ssconf_basic_" + remove_v2ray[i] + "_" + node_sel] = "";
				}
			}else{
				var remove_ss = [ "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json"];
				//console.log("use ss");
				dbus["ss_basic_type"] = "0"
				dbus["ssconf_basic_type_" + node_sel] = "0"
				for (var i = 0; i < remove_ss.length; i++) {
					dbus["ss_basic_" + remove_ss[i]] = "";
					dbus["ssconf_basic_" + remove_ss[i] + "_" + node_sel] = "";
				}
			}
		}
	}
	if (E("ss_basic_enable").checked) {
		if (E("ss_basic_mode").value == "1") {
			db_ss["ss_basic_action"] = "1";
		} else if (E("ss_basic_mode").value == "2") {
			db_ss["ss_basic_action"] = "2";
		} else if (E("ss_basic_mode").value == "3") {
			db_ss["ss_basic_action"] = "3";
		} else if (E("ss_basic_mode").value == "5") {
			db_ss["ss_basic_action"] = "5";
		} else if (E("ss_basic_mode").value == "6") {
			db_ss["ss_basic_action"] = "6";
		}
	} else {
		db_ss["ss_basic_action"] = "0";
	}
	// 对象db_ss是已经存在skipd中的，对象dbus是要存进去的
	// 1 做一个检测，把dbus中与db_ss相同的值给剔除掉
	// 2 并且，如果一个field在db_ss中是没有（undefined），并且在dbus中是空值（""）的话，也需要剔除掉
	// 3 两次剔除后剩下的对象用于提交，减少skipd数据写入量
	// console.log("db_ss:", db_ss);
	// console.log("dbus:", dbus);
	var post_dbus = {};
	for (var key in dbus) {
		//console.log(key);
		if(db_ss[key] && dbus[key] && db_ss[key] == dbus[key]){
			//console.log("0", key, db_ss[key], dbus[key]);
			continue;
		}else if(db_ss[key] == undefined && (dbus[key] == "")){
			//console.log("1", key, db_ss[key], dbus[key]);
			continue;
		}else{
			//console.log("2", key, db_ss[key], dbus[key]);
			post_dbus[key] = dbus[key];
		}
	}
	console.log("post_dbus", post_dbus);
	post_dbus["SystemCmd"] = "ss_config.sh";
	post_dbus["action_mode"] = " Refresh ";
	post_dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(post_dbus);
}

function push_data(obj) {
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(obj),
		success: function(response) {
			showSSLoadingBar();
			noChange2 = 0;
			setTimeout("get_realtime_log();", 500);
		}
	});
}

function decode_show() {
	var temp_ss = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_online_links", "ss_basic_custom"];
	for (var i = 0; i < temp_ss.length; i++) {
		temp_str = E(temp_ss[i]).value;
		E(temp_ss[i]).value = Base64.decode(temp_str);
	}
}

function update_ss_ui(obj) {
	//console.log("test2", obj);
	var node_sel = obj["ssconf_basic_node"];
	for (var field in obj) {
		//console.log("test3", field);
		var el = E(field);

		if (el != null && el.getAttribute("type") == "checkbox") {
			//console.log("param_check", el.id);
			if (obj[field] != "1") {
				el.checked = false;
			} else {
				el.checked = true;
			}
			continue;
		}

		if (el != null) {
		//console.log("param_others", el.id);
			el.value = obj[field];
		}
	}
	E("ss_basic_password").value = Base64.decode(E("ss_basic_password").value);
	E("ss_basic_v2ray_json").value = do_js_beautify(Base64.decode(E("ss_basic_v2ray_json").value));
}

function verifyFields(r) {
	// somae variable
	var node_sel = E("ssconf_basic_node").value;
	var ssmode = E("ss_basic_mode").value;
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
		var ss_on = false;
		var ssr_on = true;
		var koolgame_on = false;
		var v2ray_on = false;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
	}else{
		if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
			var ss_on = false;
			var ssr_on = false;
			var koolgame_on = true;
			var v2ray_on = false;
			$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
			$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
		}else{
			if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
				var ss_on = false;
				var ssr_on = false;
				var koolgame_on = false;
				var v2ray_on = true;
				$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(51)"><font color="#ffcc00">地址（address）</font></a>');
				$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(50)"><font color="#ffcc00">端口（port）</font></a>');
			}else{
				var ss_on = true;
				var ssr_on = false;
				var koolgame_on = false;
				var v2ray_on = false;
				$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
				$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
			}
		}
	}
	// pop out node add
	if (node_global_max == 0 && poped == 0) {
		pop_node_add();
	}

	//basic pannel status show
	if (db_ss["ss_basic_mode"] == "0") {
		$("#mode_state").html("运行状态");
	} else if (db_ss["ss_basic_mode"] == "1") {
		$("#mode_state").html("运行状态【gfwlist模式】");
	} else if (db_ss["ss_basic_mode"] == "2") {
		$("#mode_state").html("运行状态【大陆白名单模式】");
	} else if (db_ss["ss_basic_mode"] == "3") {
		$("#mode_state").html("运行状态【游戏模式】");
	} else if (db_ss["ss_basic_mode"] == "5") {
		$("#mode_state").html("运行状态【全局模式】");
	} else if (db_ss["ss_basic_mode"] == "6") {
		$("#mode_state").html("运行状态【回国模式】");
	}


	//ss-libev
	showhide("ss_v2ray_plugin", (ss_on));
	showhide("ss_v2ray_plugin_opts", (ss_on && E("ss_basic_ss_v2ray_plugin").value != "0"));
	//ssr-libev
	showhide("ss_basic_rss_protocol_param_tr", (ssr_on));
	showhide("ss_basic_rss_protocol_tr", (ssr_on));
	showhide("ss_basic_rss_obfs_tr", (ssr_on));
	showhide("ss_basic_ticket_tr", (ssr_on));
	//koolgame
	showhide("ss_koolgame_udp_tr", koolgame_on);
	//v2ray
	var json_on = E("ss_basic_v2ray_use_json").checked == true;
	var json_off = E("ss_basic_v2ray_use_json").checked == false;
	var http_on = E("ss_basic_v2ray_network").value == "tcp" && E("ss_basic_v2ray_headtype_tcp").value == "http";
	var host_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || http_on;
	var path_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2";
	showhide("pass_tr", (!v2ray_on));
	showhide("method_tr", (!v2ray_on));
	showhide("server_tr", (json_off));
	showhide("port_tr", (json_off));
	showhide("v2ray_use_json_basic_tr", v2ray_on);
	showhide("v2ray_uuid_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_alterid_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_security_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_network_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_headtype_tcp_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "tcp"));
	showhide("v2ray_headtype_kcp_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "kcp"));
	showhide("v2ray_network_host_basic_tr", (v2ray_on && json_off && host_on));
	showhide("v2ray_network_path_basic_tr", (v2ray_on && json_off && path_on));
	showhide("v2ray_network_security_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_mux_enable_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_mux_concurrency_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_mux_enable").checked));
	showhide("v2ray_json_basic_tr", (v2ray_on && json_on));
	showhide("v2ray_binary_update_tr", v2ray_on);

	// dns pannel
	showhide("dns_plan_foreign", !koolgame_on);
	showhide("dns_plan_foreign_game2", koolgame_on);	
	//node add/edit pannel
	if (save_flag == "shadowsocks") {
		showhide("ss_v2ray_plugin_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_plugin_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray_plugin").val() != "0"));
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
		E("UDPspeeder_table").style.display = "";
		E("UDP2raw_table").style.display = "none";
		showhide("UDPspeederV1_table", E("ss_basic_udp_software").value == "1");
		showhide("UDPspeederV2_table", E("ss_basic_udp_software").value == "2");
	}else if($('.sub-btn2').hasClass("active2")){
		E("UDPspeeder_table").style.display = "none";
		E("UDPspeederV1_table").style.display = "none";
		E("UDPspeederV2_table").style.display = "none";
		E("UDP2raw_table").style.display = "";
	}else{
		$('.sub-btn1').addClass('active2');
		$('.sub-btn1').addClass('active2');
		$('.sub-btn2').removeClass('active2');
		E("UDPspeeder_table").style.display = "";
		E("UDPspeederV1_table").style.display = "";
		E("UDPspeederV2_table").style.display = "";
		E("UDP2raw_table").style.display = "none";
	}

	__ss_reboot_check=db_ss["ss_reboot_check"];
	if (__ss_reboot_check == "0") {
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="none";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="none";
	} else if(__ss_reboot_check	== "1")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "2")	{
		E('_ss_basic_week_pre').style.display="inline";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "3")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="inline";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "4")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="none";
		E('_ss_basic_inter_pre').style.display="inline";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
		__ss_basic_inter_pre=db_ss["ss_basic_inter_pre"];
		if (__ss_basic_inter_pre ==	"1") {
			E('ss_basic_inter_min').style.display="inline";
			E('ss_basic_inter_hour').style.display="none";
			E('ss_basic_inter_day').style.display="none";
			E('_ss_basic_time_pre').style.display="none";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		} else if(__ss_basic_inter_pre == "2") {
			E('ss_basic_inter_min').style.display="none";
			E('ss_basic_inter_hour').style.display="inline";
			E('ss_basic_inter_day').style.display="none";
			E('_ss_basic_time_pre').style.display="none";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		} else if(__ss_basic_inter_pre == "3") {
			E('ss_basic_inter_min').style.display="none";
			E('ss_basic_inter_hour').style.display="none";
			E('ss_basic_inter_day').style.display="inline";
			E('_ss_basic_time_pre').style.display="inline";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		}
	} else if(__ss_reboot_check	== "5")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="inline";
		E('_ss_basic_send_text').style.display="inline";
		E('ss_basic_time_hour').style.display="none";
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
	showhide("ss_basic_tri_reboot_policy", (g != "0"));
	if(f == "6"){
		$("#ss_foreign_dns_note").html('DNS over HTTPS (DoH)，<a href="https://cloudflare-dns.com/zh-Hans/" target="_blank"><em>cloudflare服务</em></a>，拒绝一切污染~');
	}else if(f == "7"){
		$("#ss_foreign_dns_note").html('v2ray_dns只有启用v2ray节点的时能使用');
	}else{
		$("#ss_foreign_dns_note").html('');
	}
}

function generate_lan_list(){
	ipaddr="<% nvram_get("lan_ipaddr"); %>";
	var ips = ipaddr.split(".");
	ip = ips[0] + "." + ips[1] + "." + ips[2] + ".";
	for (var i = 2; i < 255; i++) {
		$("#ss_acl_ip").append("<option value='" + ip + i + "'>" + ip + i + "</option>");
	}
}

function ssconf_node2obj(node_sel) {
	var p = "ssconf_basic";
	var obj = {};
	var params2 = ["password", "v2ray_json", "server", "mode", "port", "password", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_mux_enable", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_use_json"];

	for (var i = 0; i < params2.length; i++) {
		obj["ss_basic_" + params2[i]] = db_ss[p + "_" + params2[i] + "_" + node_sel] || "";
	}
	obj["ssconf_basic_node"] = node_sel;
	//console.log("test", obj);
	return obj;
}

function ss_node_sel(s) {
	if(!s){
		var node_sel = E("ssconf_basic_node").value;
		var obj = ssconf_node2obj(node_sel);
		update_ss_ui(obj);
	}
	verifyFields();
}

function getAllConfigs() {
	var dic = {};
	for (var field in db_ss) {
		names = field.split("ssconf_basic_name_");
		dic[names[names.length - 1]] = 'ok';
	}
	confs = {};
	//console.log("456", dic)
	var p = "ssconf_basic";
	for (var field in dic) {
		if (isNaN(field)){
			continue;
		}
		var obj = {};
		//节点名
		if (typeof db_ss[p + "_name_" + field] == "undefined") {
			obj["name"] = '节点' + field;
		} else {
			obj["name"] = db_ss[p + "_name_" + field];
		}
		//ping显示
		if (typeof db_ss[p + "_ping_" + field] == "undefined") {
			obj["ping"] = '';
		} else if (db_ss[p + "_ping_" + field] == "failed") {
			obj["ping"] = '<font color="#FFCC00">failed</font>';
		} else {
			obj["ping"] = parseFloat(db_ss[p + "_ping_" + field].split(" ")[0]).toPrecision(3) + " ms / " + parseFloat(db_ss[p + "_ping_" + field].split(" ")[3]) + "%";
		}

		if (typeof db_ss[p + "_webtest_" + field] == "undefined") {
			obj["webtest"] = '';
		} else {
			var time_total = parseFloat(db_ss[p + "_webtest_" + field].split(":")[0]).toFixed(2);
			if (time_total == 0.00) {
				obj["webtest"] = '<font color=#FFCC00">failed</font>';
			} else {
				obj["webtest"] = parseFloat(db_ss[p + "_webtest_" + field].split(":")[0]).toFixed(2) + " s";
			}
		}
		//空值为0
		if (typeof db_ss[p + "_use_kcp_" + field] == "undefined") {
			obj["use_kcp"] = '0';
		} else {
			obj["use_kcp"] = db_ss[p + "_use_kcp_" + field];
		}
		if (typeof db_ss[p + "_use_lb_" + field] == "undefined") {
			obj["use_lb"] = '0';
		} else {
			obj["use_lb"] = db_ss[p + "_use_lb_" + field];
		}
		
		if (typeof db_ss[p + "_server_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["server"] = "v2ray json";
			}else{
				obj["server"] = '';
			}
		} else {
			obj["server"] = db_ss[p + "_server_" + field];
		}

		if (typeof db_ss[p + "_port_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["port"] = "json";
			}else{
				obj["port"] = '';
			}
		} else {
			obj["port"] = db_ss[p + "_port_" + field];
		}

		if (typeof db_ss[p + "_method_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "0"){
				obj["method"] = db_ss[p + "_v2ray_security_" + field];
			}else if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["method"] = "v2ray json";
			}else{
				obj["method"] = '';
			}
		} else {
			obj["method"] = db_ss[p + "_method_" + field];
		}

		var params = ["password", "mode", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "group", "weight", "lbmode", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable"];
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + field;
			if (typeof db_ss["ssconf_basic_mode_" + field] == "undefined") {
				obj[params[i]] = '';
			}else{
				obj[params[i]] = db_ss[ofield];
			}
		}
		if (obj != null) {
			var node_i = parseInt(field);
			if (node_i > node_global_max) {
				node_global_max = node_i;
			}
			obj["node"] = field;
			confs[field] = obj;
		}
	}
	//console.log(confs)
	return confs;
}

function loadBasicOptions(confs) {
	var option = $("#ssconf_basic_node");
	var option1 = $("#ssconf_basic_ping_node");
	var option2 = $("#ssconf_basic_test_node");
	var option3 = $("#ss_basic_udp_node");
	
	option.find('option').remove().end();
	option1.find('option').remove().end();
	option2.find('option').remove().end();
	option3.find('option').remove().end();
	
	option1.append($("<option>", {
		value: 0,
		text: "全部节点"
	}));
	option2.append($("<option>", {
		value: 0,
		text: "全部节点"
	}));
	for (var field in confs) {
		var c = confs[field];
		if (c.rss_protocol) {  //判断节点为SSR
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
			if (c.koolgame_udp == "0" || c.koolgame_udp == "1") {  //判断节点为koolgame
				option.append($("<option>", {
					value: field,
					text: c.use_kcp == "1" ? "【koolgame+KCP】" + c.name : "【koolgame】" + c.name
				}));
			} else {
				if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
					option.append($("<option>", {
						value: field,
						text: c.use_kcp == "1" ? "【V2Ray+KCP】" + c.name : "【V2Ray】" + c.name
					}));
				}else{  //判断节点为ss
					option.append($("<option>", {
						value: field,
						text: c.use_kcp == "1" ? "【SS+KCP】" + c.name : "【SS】" + c.name
					}));
				}
			}
		}
		option1.append($("<option>", {
			value: field,
			text: c.name
		}));
		option2.append($("<option>", {
			value: field,
			text: c.name
		}));
		option3.append($("<option>", {
			value: field,
			text: c.name
		}));
	}
	if (node_global_max > 0) {
		var node_sel = "1";
		if (typeof db_ss.ssconf_basic_node != "undefined") {
			node_sel = db_ss.ssconf_basic_node;
		}
		option.val(node_sel);
		if (typeof db_ss.ss_basic_udp_node != "undefined") {
			option3.val(db_ss["ss_basic_udp_node"]);
		}
		ss_node_sel();
	}else{
		ss_node_sel("1");
	}
}

function loadAllConfigs() {
	confs = getAllConfigs();
	loadBasicOptions(confs);
}

function updateSs_node_listView() {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			loadAllConfigs();
		}
	});
}

function Add_profile() { //点击节点页面内添加节点动作
	checkTime = 2001; //停止节点页面刷新
	tabclickhandler(0); //默认显示添加ss节点
	E("ss_node_table_name").value = "";
	E("ss_node_table_server").value = "";
	E("ss_node_table_port").value = "";
	E("ss_node_table_password").value = "";
	E("ss_node_table_method").value = "aes-256-cfb";
	E("ss_node_table_mode").value = "1";
	E("ss_node_table_ss_v2ray_plugin").value = "0"
	E("ss_node_table_ss_v2ray_plugin_opts").value = "";
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
	$("#vpnc_settings").fadeIn(200);
}

function cancel_add_rule() { //点击添加节点面板上的返回
	E("vpnc_settings").style.display = "none";
}

var save_flag = ""; //type of Saving profile
function tabclickhandler(_type) {
	E('ssTitle').className = "vpnClientTitle_td_unclick";
	E('ssrTitle').className = "vpnClientTitle_td_unclick";
	E('gamev2Title').className = "vpnClientTitle_td_unclick";
	E('v2rayTitle').className = "vpnClientTitle_td_unclick";
	if (_type == 0) {
		save_flag = "shadowsocks";
		E("vpnc_type").value = "shadowsocks";
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
		showhide("ss_v2ray_plugin_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_plugin_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray_plugin").val() != "0"));
	} else if (_type == 1) {
		save_flag = "shadowsocksR";
		E("vpnc_type").value = "shadowsocksR";
		E('ssrTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
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
		E("vpnc_type").value = "gameV2";
		E('gamev2Title').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
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
		E("vpnc_type").value = "gameV2";
		E('v2rayTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "";
		E('ss_name_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
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

function add_ss_node_conf(flag) { //点击添加按钮动作
	var ns = {};
	var p = "ssconf_basic";
	node_global_max += 1;
	var params1 = ["mode", "name", "server", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts"]; //for ss
	var params2 = ["mode", "name", "server", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"]; //for ssr
	var params3 = ["mode", "name", "server", "port", "method", "koolgame_udp"]; //for ssr
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable"]; //for v2ray
	if(!$.trim($('#ss_node_table_name').val())){
		alert("节点名不能为空！！");
		return false;
	}
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params1[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params2[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params3[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "2";
	} else if (flag == 'v2ray') {
		//normal value
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params4_1[i]).val());
		}
		//checkbox value
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + node_global_max] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		//base64 value
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://")
				console.log(vmess_node)
				ns[p + "_server_" + node_global_max] = vmess_node.add;
				ns[p + "_port_" + node_global_max] = vmess_node.port;
				ns[p + "_v2ray_uuid_" + node_global_max] = vmess_node.id;
				ns[p + "_v2ray_security_" + node_global_max] = "auto";
				ns[p + "_v2ray_alterid_" + node_global_max] = vmess_node.aid;
				ns[p + "_v2ray_network_" + node_global_max] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns[p + "_v2ray_headtype_tcp_" + node_global_max] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns[p + "_v2ray_headtype_kcp_" + node_global_max] = vmess_node.type;
				}
				ns[p + "_v2ray_network_host_" + node_global_max] = vmess_node.host;
				ns[p + "_v2ray_network_path_" + node_global_max] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns[p + "_v2ray_network_security_" + node_global_max] = "tls";
				}else{
					ns[p + "_v2ray_network_security_" + node_global_max] = "none";
				}	
				ns[p + "_v2ray_mux_enable_" + node_global_max] = 1;
				ns[p + "_v2ray_mux_concurrency_" + node_global_max] = 8;
				ns[p + "_v2ray_use_json_" + node_global_max] = 0;
				ns[p + "_v2ray_json_" + node_global_max] = "";
			}else{
				if (E("ss_node_table_v2ray_use_json").checked == true){
					if(isJSON(E('ss_node_table_v2ray_json').value)){
						if(E('ss_node_table_v2ray_json').value.indexOf("outbound") != -1){
							ns[p + "_v2ray_json_" + node_global_max] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
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
		ns[p + "_type_" + node_global_max] = "3";
	}
	$.ajax({
		url: '/applydb.cgi?p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		success: function(response) {
			refresh_table();
			//尝试将table拉动到最下方
			E("ss_node_table_server").value = "";
			if ((E("continue_add_box").checked) == false) { //不选择连续添加的时候，清空其他数据
				E("ss_node_table_name").value = "";
				E("ss_node_table_port").value = "";
				E("ss_node_table_password").value = "";
				E("ss_node_table_method").value = "aes-256-cfb";
				E("ss_node_table_mode").value = "1";
				E("ss_node_table_ss_v2ray_plugin").value = "0"
				E("ss_node_table_ss_v2ray_plugin_opts").value = "";
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

function refresh_table() {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			$("#ss_node_list_table_main").find("tr:gt(0)").remove();
			$('#ss_node_list_table_main tr:last').after(refresh_html());
		}
	});
}

function refresh_html() {
	browser_compatibility1();
	confs = getAllConfigs();
	var n = 0;
	for (var i in confs) {
		n++;
	} //获取节点的数目
	if (eval(n) > "13.5") { //当节点数目大于13个的时候，显示为overflow，节点可以滚动
		if (isFirefox = navigator.userAgent.indexOf("Firefox") > 0) {
			E("ss_node_list_table_th").style.top = "426px";
			E("ss_node_list_table_td").style.top = "470px";
			E("ss_node_list_table_btn").style.top = "995px";
		} else {
			E("ss_node_list_table_th").style.top = "272px";
			E("ss_node_list_table_td").style.top = "315px";
			E("ss_node_list_table_btn").style.top = "840px";
		}
		$("#ss_node_list_table_th")[0].style.display = '';
		$("#ss_node_list_table_th")[0].style.width = '748px';
		$("#ss_node_list_table_td")[0].style.width = '749px';
		$("#ss_node_list_table_td")[0].style.height = '520px';
		$("#ss_node_list_table_td")[0].style.overflow = 'hidden';
		$("#ss_node_list_table_td")[0].style.position = 'absolute';
		$("#hide_when_folw")[0].style.display = 'none'
		$("#ss_node_list_table_main")[0].style["width"] = '748px';
		$("#ss_node_list_table_main")[0].style["height"] = '520px';
		$("#ss_node_list_table_main")[0].style["overflow-x"] = 'hidden';
		$("#ss_node_list_table_main")[0].style["overflow-y"] = 'scroll';
		$("#ss_node_list_table_main")[0].style["padding-right"] = '30px';
		$("#ss_node_list_table_btn")[0].style.width = '748px';
		$("#ss_node_list_table_btn")[0].style.position = 'absolute';
		$("#ss_node_list_table_btn")[0].style.margin = '';
	} else { //当节点数量小于等于13个的是否，显示为absolute，节点不可滚动
		$("#ss_node_list_table_th")[0].style.top = '';
		$("#ss_node_list_table_td")[0].style.top = '';
		$("#ss_node_list_table_btn")[0].style.top = '';
		$("#ss_node_list_table_th")[0].style.display = 'none';
		$("#ss_node_list_table_td")[0].style.width = '748px';
		$("#ss_node_list_table_td")[0].style.height = '';
		$("#ss_node_list_table_td")[0].style.overflow = '';
		$("#ss_node_list_table_td")[0].style.position = '';
		$("#ss_node_list_table_main")[0].style["height"] = '';
		$("#ss_node_list_table_main")[0].style["overflow-x"] = '';
		$("#ss_node_list_table_main")[0].style["overflow-y"] = '';
		$("#ss_node_list_table_main")[0].style["padding-right"] = '';
		$("#hide_when_folw")[0].style.display = ''
		$("#ss_node_list_table_btn")[0].style.position = '';
		$("#ss_node_list_table_btn")[0].style.margin = '5px 0px 0px 0px';
	}
	var html = '';
	for (var field in confs) {
		var c = confs[field];
		html = html + '<tr style="height:40px">';
		if (c["mode"] == 1) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/gfw.png"/></td>';
		} else if (c["mode"] == 2) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/chn.png"/></td>';
		} else if (c["mode"] == 3) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/game.png"/></td>';
		} else if (c["mode"] == 4) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/gameV2.png"/></td>';
		} else if (c["mode"] == 5) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/all.png"/></td>';
		} else {
			html = html + '<td style="width:40px"></td>';
		}
		html = html + '<td style="width:90px;" id="ss_node_name_' + c["node"] + '">' + c["name"] + '</td>';
		html = html + '<td style="width:90px;" id="ss_node_server_' + c["node"] + '"> ' + c["server"] + '</td>';
		html = html + '<td id="ss_node_port_' + c["node"] + '" style="width:37px;">' + c["port"] + '</td>';
		html = html + '<td id="ss_node_method_' + c["node"] + '" style="width:90px;"> ' + c["method"] + '</td>';
		if(!c["ping"]){
			html = html + '<td id="ss_node_ping_' + c["node"] + '" style="width:78px;" class="ping" id="ping_test_td_' + c["node"] + '" style="text-align: center;">' + "不支持" + '</td>';
		}else{
			html = html + '<td id="ss_node_ping_' + c["node"] + '" style="width:78px;" class="ping" id="ping_test_td_' + c["node"] + '" style="text-align: center;">' + c["ping"] + '</td>';
		}
		if (c["mode"] == 4 || c["use_kcp"] == 1) {
			html = html + '<td id="ss_node_webtest_' + c["node"] + '" style="width:36px;color: #FFCC33" id="web_test_td_' + c["node"] + '">' + 'null' + '</td>';
		} else {
			html = html + '<td id="ss_node_webtest_' + c["node"] + '" style="width:36px;" id="web_test_td_' + c["node"] + '">' + c["webtest"] + '</td>';
		}
		html = html + '<td style="width:33px;">'
		html = html + '<input style="margin:-2px 0px -4px -2px;" id="dd_node_' + c["node"] + '" class="edit_btn" type="button" onclick="return edit_conf_table(this);" value="">'
		html = html + '</td>';
		html = html + '<td style="width:33px;">'
		if ((c["node"]) == db_ss["ssconf_basic_node"] && db_ss["ss_basic_enable"] =="1") {
			html = html + '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="remove_running_node(this);" value="">'
		} else {
			html = html + '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="return remove_conf_table(this);" value="">'
		}
		html = html + '</td>';
		html = html + '<td style="width:65px;">'
		if ((c["node"]) == db_ss["ssconf_basic_node"] && db_ss["ss_basic_enable"] =="1") {
			if (c["rss_protocol"]) {
				html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #f072a5;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
			} else {
				if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") {
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #33CC33;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				} else {
					if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
					}else{
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #00CCFF;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
					}
				}
			}
		} else {
			if (c["rss_protocol"]) {
				html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #f072a5;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
			} else {
				if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") {
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #33CC33;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
				} else {
					if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					}else{
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #00CCFF;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					}
				}
			}
		}
		html = html + '</td>';
		html = html + '</tr>';
	}
	return html;
}
var node_nu;

function apply_Running_node() {
	alert("这个节点正在运行，你要干嘛？")
	return false;
}

function remove_running_node() {
	alert("这个节点正在运行，无法删除！")
	return false;
}

function apply_this_ss_node(s) { //应用此节点
	$('.show-btn1').addClass('active');
	$('.show-btn1_1').removeClass('active');
	cancel_add_rule(); //隐藏节点编辑面板
	E("tablets").style.display = "";
	E("tablet_1").style.display = "";
	E("apply_button").style.display = "";
	E("ss_node_list_table_th").style.display = "none";
	E("ss_node_list_table_td").style.display = "none";
	E("ss_node_list_table_btn").style.display = "none";
	confs = getAllConfigs();
	var option = $("#ssconf_basic_node");
	option.find('option').remove().end();
	for (var field in confs) {
		var c = confs[field];
		if (c.rss_protocol) {
			option.append($("<option>", {
				value: field,
				text: "【SSR】" + c.name
			}));
		} else {
			if (c.koolgame_udp == "0" || c.koolgame_udp == "1") {
				option.append($("<option>", {
					value: field,
					text: "【koolgame】" + c.name
				}));
			} else {
				if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
					option.append($("<option>", {
						value: field,
						text: "【V2Ray】" + c.name
					}));
				}else{
					option.append($("<option>", {
						value: field,
						text: "【SS】" + c.name
					}));
				}
			}
		}
	}
	if (node_global_max > 0) {
		var node_sel = "1";
		if (typeof db_ss.ssconf_basic_node != "undefined") {
			node_sel = db_ss.ssconf_basic_node;
		}
		option.val(node_sel);
	}

	checkTime = 2001; //停止节点页面刷新
	//ss_node_info_return();
	var node = $(s).attr("id");
	var nodes = node.split("_");
	node = nodes[nodes.length - 1];
	var node_sel = node;
	var obj = ssconf_node2obj(node_sel);
	E("ssconf_basic_node").value = node;
	update_ss_ui(obj);
	verifyFields();
	setTimeout("save();", 500);
}

function remove_conf_table(o) { //删除节点功能
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	var ns = {};
	var params = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "use_kcp", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "ping", "web_test", "use_lb", "lbmode", "weight", "use_kcp", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable", "type"];
	for (var i = 0; i < params.length; i++) {
		ns[p + "_" + params[i] + "_" + id] = "";
	}
	$.ajax({
		url: '/applydb.cgi?use_rm=1&p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		error: function(xhr) {
			console.log("error in posting config of table");
		},
		success: function(response) {
			refresh_table();
		}
	});
}

function edit_conf_table(o) { //编辑节点功能，显示编辑面板
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	confs = getAllConfigs();
	id = ids[ids.length - 1];
	var c = confs[id];
	var params1_base64 = ["password"];
	var params1_check = ["v2ray_use_json", "v2ray_mux_enable"];
	var params1_input = ["name", "server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"];
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
	
	if (c["rss_protocol"]) { //判断节点为SSR
		$("#vpnc_settings").fadeIn(200);
		E("ssTitle").style.display = "none";
		E("ssrTitle").style.display = "";
		E("gamev2Title").style.display = "none";
		E("v2rayTitle").style.display = "none";
		$("#ssrTitle").html("编辑SSR账号");
		tabclickhandler(1);
	} else {
		if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") { //判断节点为koolgame
			$("#vpnc_settings").fadeIn(200);
			E("ssTitle").style.display = "none";
			E("ssrTitle").style.display = "none";
			E("gamev2Title").style.display = "";
			E("v2rayTitle").style.display = "none";
			$("#gamev2Title").html("编辑koolgame账号");
			tabclickhandler(2);
		}else { 
			if(c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
				$("#vpnc_settings").fadeIn(200);
				E("ssTitle").style.display = "none";
				E("ssrTitle").style.display = "none";
				E("gamev2Title").style.display = "none";
				E("v2rayTitle").style.display = "";
				$("#v2rayTitle").html("编辑V2Ray账号");
				tabclickhandler(3);
			}else{ //判断节点为SS
				$("#vpnc_settings").fadeIn(200);
				E("ssTitle").style.display = "";
				E("ssrTitle").style.display = "none";
				E("gamev2Title").style.display = "none";
				E("v2rayTitle").style.display = "none";
				$("#ssTitle").html("编辑ss账号");
				tabclickhandler(0);
			}
		}
	}
	myid = id;
}

function edit_ss_node_conf(flag) { //编辑节点功能，数据重写
	var ns = {};
	var p = "ssconf_basic";
	var params1 = ["name", "server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts"]; //for ss
	var params2 = ["name", "server", "mode", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"]; //for ssr
	var params3 = ["name", "server", "mode", "port", "method", "koolgame_udp"]; //for ssr
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable"]; //for v2ray
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + myid] = $('#ss_node_table' + "_" + params1[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + myid] = $('#ss_node_table' + "_" + params2[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + myid] = $('#ss_node_table' + "_" + params3[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "2";
	} else if (flag == 'v2ray') {
		//normal value
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + myid] = $('#ss_node_table' + "_" + params4_1[i]).val();
		}
		//checkbox value
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + myid] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		//VMESS
		//if($("#ss_node_table_v2ray_json").val()){
		//	ns[p + "_v2ray_json_" + myid] = Base64.encode($("#ss_node_table_v2ray_json").val());
		//}
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://");
				console.log(vmess_node);
				ns["ssconf_basic_server_" + myid] = vmess_node.add;
				ns["ssconf_basic_port_" + myid] = vmess_node.port;
				ns["ssconf_basic_v2ray_uuid_" + myid] = vmess_node.id;
				ns["ssconf_basic_v2ray_security_" + myid] = "auto";
				ns["ssconf_basic_v2ray_alterid_" + myid] = vmess_node.aid;
				ns["ssconf_basic_v2ray_network_" + myid] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns["ssconf_basic_v2ray_headtype_tcp_" + myid] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns["ssconf_basic_v2ray_headtype_kcp_" + myid] = vmess_node.type;
				}
				ns["ssconf_basic_v2ray_network_host_" + myid] = vmess_node.host;
				ns["ssconf_basic_v2ray_network_path_" + myid] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns["ssconf_basic_v2ray_network_security_" + myid] = "tls";
				}else{
					ns["ssconf_basic_v2ray_network_security_" + myid] = "none";
				}
				ns["ssconf_basic_v2ray_mux_enable_" + myid] = 1;
				ns["ssconf_basic_v2ray_mux_concurrency_" + myid] = 8;
				ns["ssconf_basic_v2ray_use_json_" + myid] = 0;
				ns["ssconf_basic_v2ray_json_" + myid] = "";
			}else{
				console.log("use v2ray json");
				ns["ssconf_basic_v2ray_json_" + myid] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
			}
		}
		ns[p + "_type_" + myid] = "3";
	} 
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[], "fields": ns };
	$.ajax({
		url: '/applydb.cgi?p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		error: function(xhr) {
			console.log("error in posting config of table");
		},
		success: function(response) {
			refresh_table();
			E("ss_node_table_name").value = "";
			E("ss_node_table_port").value = "";
			E("ss_node_table_server").value = "";
			E("ss_node_table_password").value = "";
			E("ss_node_table_method").value = "aes-256-cfb";
			E("ss_node_table_mode").value = "1";
			E("ss_node_table_ss_v2ray_plugin").value = "0"
			E("ss_node_table_ss_v2ray_plugin_opts").value = "";
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
	updateSs_node_listView();
	$("#vpnc_settings").fadeOut(200);
}


function download_SS_node() {
	location.href = 'ss_conf_backup.txt';
}

function upload_ss_backup() {
	if (E('ss_file').value == "") return false;
	global_ss_node_refresh = false;
	E('ss_file_info').style.display = "none";
	E('loadingicon').style.display = "block";
	document.form.enctype = "multipart/form-data";
	document.form.encoding = "multipart/form-data";
	document.form.action = "/ssupload.cgi?a=/tmp/ss_conf_backup.txt";
	document.form.submit();
}


function upload_ok(isok) {
	var info = E('ss_file_info');
	if (isok == 1) {
		info.innerHTML = "上传完成";
		setTimeout("restore_ss_conf();", 1200);
	} else {
		info.innerHTML = "上传失败";
	}
	info.style.display = "block";
	E('loadingicon').style.display = "none";
}

function restore_ss_conf() {
	checkTime = 2001; //停止可能在进行的刷新
	db_ss["ss_basic_action"] = "9";
	var dbus = {};
	dbus["SystemCmd"] = "ss_conf_restore.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(dbus);
}

function remove_SS_node() {
	checkTime = 2001; //停止可能在进行的刷新
	db_ss["ss_basic_action"] = "10";
	var dbus = {};
	dbus["SystemCmd"] = "ss_conf_remove.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(dbus);
}

function ping_test() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_ping.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ssconf_basic_ping_node"] = E("ssconf_basic_ping_node").value;
	dbus["ssconf_basic_ping_method"] = E("ssconf_basic_ping_method").value;
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			checkTime = 0;
			refresh_ss_node_list_ping();
			alert("请等待片刻，测试结果将自动显示在对应节点列表!");
		}
	});
}

function remove_ping() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_ping_remove.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			alert("请等待片刻，如果结果未清空，请手动刷新页面!");
			setTimeout("refresh_table()", 1000);
		}
	});
}

function web_test() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_webtest.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ssconf_basic_test_node"] = E("ssconf_basic_test_node").value;
	dbus["ssconf_basic_test_domain"] = E("ssconf_basic_test_domain").value;
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			checkTime = 0;
			refresh_ss_node_list_webtest();
			alert("请等待片刻，测试结果将自动显示在对应节点列表!");
		}
	});
}

function remove_test() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_webtest_remove.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			alert("请等待片刻，如果结果未清空，请手动刷新页面!");
			setTimeout("refresh_table()", 1000);
		}
	});
}

var checkTime = 0;

function refresh_ss_node_list_ping() {
	if (checkTime < 200) {
		checkTime++;
		refresh_table();
		setTimeout("refresh_ss_node_list_ping()", 1000);
	}
	if (checkTime > 4) {
		confs = getAllConfigs();
		var n = 0;
		for (var i in confs) {
			n++;
		} //获取节点的数目
		var ping_flag = 0;
		for (var field in confs) {
			var c = confs[field].ping;
			if (c != "") {
				ping_flag++;
			}
		}
		if (E("ssconf_basic_ping_node").value == "0") {
			if (ping_flag == eval(n)) { //当ping被填满时，停止刷新
				checkTime = 2001;
			}
		} else {
			if (ping_flag == "1") { //当ping被填满时，停止刷新
				checkTime = 2001;
			}
		}
	}
}

function refresh_ss_node_list_webtest() {
	if (checkTime < 200) {
		checkTime++;
		refresh_table();
		setTimeout("refresh_ss_node_list_webtest()", 3000); //ping 出结果较慢，3秒刷新一次
	}
	if (checkTime > 2) {
		confs = getAllConfigs();
		var n = 0;
		for (var i in confs) {
			n++;
		} //获取节点的数目
		var webtest_flag = 0;
		for (var field in confs) {
			var c = confs[field].webtest;
			if (c != "") {
				webtest_flag++;
			}
		}
		if (webtest_flag == eval(n)) { //当ping被填满时，停止刷新
			checkTime = 2001;
		}
	}
}

function updatelist(action) {
	db_ss["ss_basic_action"] = "8";
	var dbus = {};
	dbus["SystemCmd"] = "ss_rule_update.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ss_basic_update_action"] = action;
	dbus["ss_basic_rule_update"] = E("ss_basic_rule_update").value;
	dbus["ss_basic_rule_update_time"] = E("ss_basic_rule_update_time").value;
	dbus["ss_basic_gfwlist_update"] = E("ss_basic_gfwlist_update").checked ? '1' : '0';
	dbus["ss_basic_chnroute_update"] = E("ss_basic_chnroute_update").checked ? '1' : '0';
	dbus["ss_basic_cdn_update"] = E("ss_basic_cdn_update").checked ? '1' : '0';
	push_data(dbus);
}

function version_show() {
	$.ajax({
		url: 'https://raw.githubusercontent.com/hq450/fancyss/master/fancyss_arm/config.json.js',
		type: 'GET',
		dataType: 'json',
		success: function(res) {
			if (typeof(res["version"]) != "undefined" && res["version"].length > 0) {
				if (res["version"] == db_ss["ss_basic_version_local"]) {
					$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：" + db_ss['ss_basic_version_local'] + "</i></a>");
				} else {
					if (typeof(db_ss["ss_basic_version_local"]) != "undefined") {
					    if (res["version"] > db_ss["ss_basic_version_local"]) {
						    $("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：" + db_ss['ss_basic_version_local'] + "</i></a>");
						    $("#updateBtn").html("<i>升级到：" + res.version + "</i>");
					    }
					} else {
						$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：未知</i></a>");
					}
				}
			}
		}
	});
}

function get_ss_status_data() {
	if (checkss < 10000) {
		checkss++;
		$.ajax({
			type: "get",
			url: "/dbconf?p=ss_basic_enable",
			dataType: "script",
			success: function() {
				if (db_ss_basic_enable['ss_basic_enable'] == "1") {
					$.ajax({
						url: '/ss_status',
						dataType: "html",
						success: function(response) {
							console.log(response)
							var arr = JSON.parse(response);
							if (arr[0] == "" || arr[1] == "") {
								E("ss_state2").innerHTML = "国外连接 - " + "Waiting for first refresh...";
								E("ss_state3").innerHTML = "国内连接 - " + "Waiting for first refresh...";
							} else {
								E("ss_state2").innerHTML = arr[0];
								E("ss_state3").innerHTML = arr[1];
							}
						}
					});
				} else {
					E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
					E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
				}
				refreshRate = Math.floor(Math.random() * 4000) + 4000;
				setTimeout("get_ss_status_data();", refreshRate);
			}

		});
	}else{
		E("ss_state2").innerHTML = "国外连接 - " + "Waiting...";
		E("ss_state3").innerHTML = "国内连接 - " + "Waiting...";
	}
}

function get_udp_status() {
	$.ajax({
		url: 'apply.cgi?current_page=Main_Ss_Content.asp.asp&next_page=Main_Ss_Content.asp.asp&group_id=&modified=0&action_mode=+Refresh+&action_script=&action_wait=&first_time=&preferred_lang=CN&SystemCmd=ss_udp_status.sh&firmver=3.0.0.4',
		dataType: 'html',
		success: function (response) {
			setTimeout("write_udp_status();", 1000);
			return true;
		}
	});
}

var noChange4 = 0;
function write_udp_status() {
	E("udp_status").value = "获取中......"
	$.ajax({
		url: '/res/ss_udp_status.htm',
		dataType: 'html',
		error: function(xhr) {
			setTimeout("write_udp_status();", 500);
		},
		success: function(response) {
			var retArea = E("udp_status");
			if (response.search("XU6J03M6") != -1) {
				retArea.innerHTML = response.replace("XU6J03M6", " ");
				return true;
			}
			if (_responseLen == response.length) {
				noChange4++;
			} else {
				noChange4 = 0;
			}
			if (noChange4 > 100) {
				return false;
			} else {
				setTimeout("write_udp_status();", 400);
			}
			retArea.innerHTML = response.replace("XU6J03M6", " ");
			_responseLen = response.length;
		}
	});
}

function update_ss() {
	db_ss["ss_basic_action"] = "7";
	var dbus = {};
	dbus["SystemCmd"] = "ss_update.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(dbus);
}

function toggle_func() {
	var ssmode = E("ss_basic_mode").value;
	$('.show-btn1').addClass('active');
	$(".show-btn1").click(
		function() {
			$('.show-btn1').addClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			verifyFields();
			ss_node_info_return();
		});
	$(".show-btn1_1").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').addClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "none";
			E("ss_node_list_table_td").style.display = "";
			E("ss_node_list_table_btn").style.display = "";
			refresh_table();
			update_ping_method();
		});
	$(".show-btn2").click(
		//dns pannel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').addClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn3").click(
		// black_white list panel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').addClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			showhide("ss_wan_black_ip_tr", (ssmode != "5"));
			showhide("ss_wan_black_domain_tr", (ssmode != "5"));
			E("apply_button").style.display = "";
			ss_node_info_return();
		});
	$(".show-btn3_1").click(
		// black_white list panel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').addClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			autoTextarea(E("ss_basic_kcp_parameter"));
			ss_node_info_return();
		});
	$(".show-btn3_2").click(
		// black_white list panel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').addClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			ss_node_info_return();
			update_visibility();
			get_udp_status();
		});
	$(".show-btn4").click(
		//rule manage
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').addClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "none";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn5").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').addClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			ss_node_info_return();
			setTimeout("showDropdownClientList('setClientIP', 'ip', 'all', 'ClientList_Block', 'pull_arrow', 'online');", 1000);
			refresh_acl_table();
			update_visibility();
		});
	$(".show-btn6").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').addClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn7").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn3_1').removeClass('active');
			$('.show-btn3_2').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').addClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_3_1").style.display = "none";
			E("tablet_3_2").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "";
			E("apply_button").style.display = "none";
			E("log_content").style.display = "";
			ss_node_info_return();
			get_log();
		});
	$("#update_log").click(
		function() {
			window.open("https://github.com/hq450/fancyss/blob/master/fancyss_arm/Changelog.txt");
		});
	$("#log_content2").click(
		function() {
			x = -1;
		});
}

function ss_node_info_return() {
	cancel_add_rule();
	E("ss_node_list_table_th").style.display = "none";
	E("ss_node_list_table_td").style.display = "none";
	E("ss_node_list_table_btn").style.display = "none";
	checkTime = 2001;
}

function get_log() {
	$.ajax({
		url: '/cmdRet_check.htm',
		dataType: 'html',

		error: function(xhr) {
			setTimeout("get_log();", 1000);
		},
		success: function(response) {
			var retArea = E("log_content1");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				return true;
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}

			if (noChange > 5) {
				//retArea.value = "当前日志文件为空";
				return false;
			} else {
				setTimeout("get_log();", 200);
			}

			retArea.value = response;
			_responseLen = response.length;
		}
	});
}

function get_realtime_log() {
	$.ajax({
		url: '/cmdRet_check.htm',
		dataType: 'html',
		error: function(xhr) {
			setTimeout("get_realtime_log();", 1000);
		},
		success: function(response) {
			var retArea = E("log_content3");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				E("ok_button").style.display = "";
				retArea.scrollTop = retArea.scrollHeight;
				x = 5;
				count_down_close();
				return true;
			} else {
				E("ok_button").style.display = "none";
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 1000) {
				return false;
			} else {
				setTimeout("get_realtime_log();", 250);
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

function update_ping_method() {
	$("#ssconf_basic_ping_method").find('option').remove().end();
	if (E("ssconf_basic_ping_node").value == "0") {
		$("#ssconf_basic_ping_method").append("<option value='1'>单线ping(10次/节点)</option>");
		$("#ssconf_basic_ping_method").append("<option value='2'>并发ping(10次/节点)</option>");
		$("#ssconf_basic_ping_method").append("<option value='3'>并发ping(20次/节点)</option>");
		$("#ssconf_basic_ping_method").append("<option value='4'>并发ping(50次/节点)</option>");
	} else {
		$("#ssconf_basic_ping_method").append("<option value='5'>ping(10次)</option>");
		$("#ssconf_basic_ping_method").append("<option value='6'>ping(20次)</option>");
		$("#ssconf_basic_ping_method").append("<option value='7'>ping(50次)</option>");
	}
}

function reload_Soft_Center() {
	location.href = "/Main_Soft_center.asp";
}

function getACLConfigs() {
	var dict = {};
	acl_node_max = 0;
	for (var field in db_ss) {
		names = field.split("_");
		dict[names[names.length - 1]] = 'ok';
	}
	acl_confs = {};
	var p = "ss_acl";
	var params = ["ip", "port", "mode"];
	for (var field in dict) {
		var obj = {};
		if (typeof db_ss[p + "_name_" + field] == "undefined") {
			obj["name"] = db_ss[p + "_ip_" + field];
		} else {
			obj["name"] = db_ss[p + "_name_" + field];
		}
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + field;
			if (typeof db_ss[ofield] == "undefined") {
				obj = null;
				break;
			}
			obj[params[i]] = db_ss[ofield];
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
	$.ajax({
		url: '/applydb.cgi?p=ss_acl',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(acls),
		success: function(response) {
			confs = getAllConfigs();
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
	$.ajax({
		url: '/applydb.cgi?use_rm=1&p=ss_acl',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(acls),
		success: function(response) {
			refresh_acl_table();
		}
	});
}

function refresh_acl_table(q) {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			$("#ACL_table").find("tr:gt(1)").remove();
			$('#ACL_table tr:last').after(refresh_acl_html());
			//write defaut rule mode when switching ss mode
			if (typeof db_ss["ss_acl_default_mode"] != "undefined") {
				if (E("ss_basic_mode").value == 1 && db_ss["ss_acl_default_mode"] == 1 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 2 && db_ss["ss_acl_default_mode"] == 2 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 3 && db_ss["ss_acl_default_mode"] == 3 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 5 && db_ss["ss_acl_default_mode"] == 5 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
			}
			//write default rule port
			if (typeof db_ss["ss_acl_default_port"] != "undefined") {
				$('#ss_acl_default_port').val(db_ss["ss_acl_default_port"]);
			} else {
				$('#ss_acl_default_port').val("all");
			}
			//write dynamic table value
			for (var i = 1; i < acl_node_max + 1; i++) {
				$('#ss_acl_mode_' + i).val(db_ss["ss_acl_mode_" + i]);
				$('#ss_acl_port_' + i).val(db_ss["ss_acl_port_" + i]);
				$('#ss_acl_name_' + i).val(db_ss["ss_acl_name_" + i]);
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
		//E("ss_acl_port_" + id2).disabled=true;
	} else if ($(o).val() == 1) {
		$("#ss_acl_port_" + id2).val("80,443");
		//E("ss_acl_port_" + id2).disabled=false;
	} else if ($(o).val() == 2) {
		$("#ss_acl_port_" + id2).val("22,80,443");
		//E("ss_acl_port_" + id2).disabled=false;
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
	} //获取节点的数目
	var code = '';
	for (var field in acl_confs) {
		var ac = acl_confs[field];
		code = code + '<tr>';
		code = code + '<td>' + ac["ip"] + '</td>';
		code = code + '<td>';
		code = code + '<input type="text" placeholder="' + ac["acl_node"] + '号机" id="ss_acl_name_' + ac["acl_node"] + '" name="ss_acl_name_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		code = code + '</td>';
		code = code + '<td>';
		code = code + '<select id="ss_acl_mode_' + ac["acl_node"] + '" name="ss_acl_mode_' + ac["acl_node"] + '" style="width:160px;margin:0px 0px 0px 2px;" class="input_option_2" onchange="set_mode_2(this);">';
		if ($("#ss_basic_mode").val() == 6) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="6">回国模式</option>';
		} else {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="1">gfwlist模式</option>';
			code = code + '<option value="2">大陆白名单模式</option>';
			code = code + '<option value="3">游戏模式</option>';
			code = code + '<option value="5">全局代理模式</option>';
			code = code + '<option value="6">回国模式</option>';
		}
		code = code + '</select>'
		code = code + '</td>';
		code = code + '<td>';
		if (ac["mode"] == 3) {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，游戏模式下默认全端口" readonly = "readonly" />';
		} else if (ac["mode"] == 0) {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，不通过SS下默认全端口" readonly = "readonly" />';
		} else {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		}
		code = code + '</td>';
		code = code + '<td>';
		code = code + '<input style="margin: -3px 0px -5px 6px;" id="acl_node_' + ac["acl_node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
		code = code + '</td>';
		code = code + '</tr>';
	}
	code = code + '<tr>';
	if (n == 0) {
		code = code + '<td>所有主机</td>';
	} else {
		code = code + '<td>其它主机</td>';
	}
	code = code + '<td>默认规则</td>';
	ssmode = E("ss_basic_mode").value;
	if (n == 0) {
		if (ssmode == 0) {
			code = code + '<td>SS关闭</td>';
		} else if (ssmode == 1) {
			code = code + '<td>gfwlist模式</td>';
		} else if (ssmode == 2) {
			code = code + '<td>大陆白名单模式</td>';
		} else if (ssmode == 3) {
			code = code + '<td>游戏模式</td>';
		} else if (ssmode == 5) {
			code = code + '<td>全局模式</td>';
		} else if (ssmode == 6) {
			code = code + '<td>回国模式</td>';
		}
	} else {
		code = code + '<td>';
		code = code + '<select id="ss_acl_default_mode" name="ss_acl_default_mode" style="width:160px;margin:0px 0px 0px 2px;" class="input_option_2" onchange="set_default_port();">';
		if (ssmode == 0) {
			code = code + '<td>SS关闭</td>';
		} else if (ssmode == 1) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="1" selected>gfwlist模式</option>';
		} else if (ssmode == 2) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="2" selected>大陆白名单模式</option>';
		} else if (ssmode == 3) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="3" selected>游戏模式</option>';
		} else if (ssmode == 5) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="5" selected>全局代理模式</option>';
		} else if (ssmode == 6) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="6" selected>回国模式</option>';
		}
		code = code + '</select>';
		code = code + '</td>';
	}
	code = code + '<td>';
	code = code + '<input type="text" id="ss_acl_default_port" name="ss_acl_default_port" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
	code = code + '</td>';
	code = code + '<td>';
	code = code + '</td>';
	code = code + '</tr>';
	return code;

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
	validator.validIPForm(document.form.ss_acl_ip, 0);
}

function get_proc_status() {
	noChange3 = 0;
	now_get_status();
	setTimeout("write_proc_status();", 500);
	$("#detail_status").fadeIn(200);
}

function close_proc_status() {
	$("#detail_status").fadeOut(200);
}

function now_get_status() {
	$.ajax({
		url: 'apply.cgi?current_page=Main_Ss_Content.asp.asp&next_page=Main_Ss_Content.asp.asp&group_id=&modified=0&action_mode=+Refresh+&action_script=&action_wait=&first_time=&preferred_lang=CN&SystemCmd=ss_proc_status.sh&firmver=3.0.0.4',
		dataType: 'html'
	});
}

var noChange3 = 0;
function write_proc_status() {
	E("proc_status").value = ""
	$.ajax({
		url: '/res/ss_proc_status.htm',
		dataType: 'html',
		error: function(xhr) {
			setTimeout("write_proc_status();", 1400);
		},
		success: function(response) {
			var retArea = E("proc_status");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				//retArea.scrollTop = retArea.scrollHeight;
				return true;
			} else {}
			if (_responseLen == response.length) {
				noChange3++;
			} else {
				noChange3 = 0;
			}
			if (noChange3 > 100) {
				return false;
			} else {
				setTimeout("write_proc_status();", 500);
			}
			retArea.value = response.replace("XU6J03M6", " ");
			//retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
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
	var dbus = {};
	dbus["SystemCmd"] = "ss_online_update.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ss_online_action"] = action;
	dbus["ss_online_links"] = Base64.encode(E("ss_online_links").value);
	dbus["ssr_subscribe_mode"] = E("ssr_subscribe_mode").value;
	dbus["ssr_subscribe_obfspara"] = E("ssr_subscribe_obfspara").value;
	dbus["ssr_subscribe_obfspara_val"] = E("ssr_subscribe_obfspara_val").value;
	dbus["ss_basic_online_links_goss"] = E("ss_basic_online_links_goss").value;
	dbus["ss_basic_node_update"] = E("ss_basic_node_update").value;
	dbus["ss_basic_node_update_day"] = E("ss_basic_node_update_day").value;
	dbus["ss_basic_node_update_hr"] = E("ss_basic_node_update_hr").value;
	dbus["ss_basic_node_update"] = E("ss_basic_node_update").value;
	dbus["ss_base64_links"] = E("ss_base64_links").value;
	push_data(dbus);
}

function v2ray_binary_update (){
	db_ss["ss_basic_action"] = "15";
	var dbus = {};
	dbus["SystemCmd"] = "ss_v2ray.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	require(['/res/layer/layer.js'], function(layer) {
		layer.confirm('<li>为了避免不必要的问题，请保证路由器和服务器上的v2ray版本一致！</li><br /><li>你确定要更新v2ray二进制吗？</li>', {
			shade: 0.8,
		}, function(index) {
			$("#log_content3").attr("rows", "20");
			push_data(dbus);
			layer.close(index);
			return true;
			//save_online_nodes(action);
		}, function(index) {
			layer.close(index);
			return false;
		});
	});
}

function status_onchange(){
    var __ss_reboot_check="";
    var ___ss_basic_inter_pre="";
    __ss_reboot_check=E("ss_reboot_check").value;
    ___ss_basic_inter_pre=E("ss_basic_inter_pre").value;
    //alert(__ss_reboot_check)
    if (__ss_reboot_check == "0") {
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="none";
    } else if(__ss_reboot_check == "1"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="inline";
        E('ss_basic_time_hour').style.display="inline";
    } else if(__ss_reboot_check == "2"){
        E('_ss_basic_week_pre').style.display="inline";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('ss_basic_time_hour').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_reboot_check == "3"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="inline";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('ss_basic_time_hour').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_reboot_check == "4"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="inline";
        if (___ss_basic_inter_pre == "1") {
            E('ss_basic_inter_min').style.display="inline";
            E('ss_basic_inter_hour').style.display="none";
            E('ss_basic_inter_day').style.display="none";
            E('_ss_basic_time_pre').style.display="none";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
        } else if(___ss_basic_inter_pre == "2"){
            E('ss_basic_inter_min').style.display="none";
            E('ss_basic_inter_hour').style.display="inline";
            E('ss_basic_inter_day').style.display="none";
            E('_ss_basic_time_pre').style.display="none";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
        } else if(___ss_basic_inter_pre == "3"){
            E('ss_basic_inter_min').style.display="none";
            E('ss_basic_inter_hour').style.display="none";
            E('ss_basic_inter_day').style.display="inline";
            E('_ss_basic_time_pre').style.display="inline";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
            E('ss_basic_time_hour').style.display="inline";
        }
    } else if(__ss_reboot_check == "5"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
        E('ss_basic_time_hour').style.display="none";
    }
}
function inter_pre_onchange(){
    var __ss_basic_inter_pre="";
    __ss_basic_inter_pre=E("ss_basic_inter_pre").value;
    if (__ss_basic_inter_pre == "1") {
        E('ss_basic_inter_min').style.display="inline";
        E('ss_basic_inter_hour').style.display="none";
        E('ss_basic_inter_day').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_basic_inter_pre == "2"){
        E('ss_basic_inter_min').style.display="none";
        E('ss_basic_inter_hour').style.display="inline";
        E('ss_basic_inter_day').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_basic_inter_pre == "3"){
        E('ss_basic_inter_min').style.display="none";
        E('ss_basic_inter_hour').style.display="none";
        E('ss_basic_inter_day').style.display="inline";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    }
}

function set_cron(action) {
	var dbus = {};
	dbus["SystemCmd"] = "ss_reboot_job.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ss_basic_reboot_action"] = action;
	if(action == 1){
		//设定定时重启
		db_ss["ss_basic_action"] = "16";
		var cron_params1 = ["ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_custom", "ss_basic_time_hour", "ss_basic_time_min"]; //for ss
		for (var i = 0; i < cron_params1.length; i++) {
			dbus[cron_params1[i]] = E(cron_params1[i]).value;
		}
		
		if (!E("ss_basic_custom").value) {
			dbus["ss_basic_custom"] = "";
		} else {
			dbus["ss_basic_custom"] = Base64.encode(E("ss_basic_custom").value);
		}
	}else if(action == 2){
		//设定触发重启
		db_ss["ss_basic_action"] = "17";
		var cron_params2 = ["ss_basic_tri_reboot_time", "ss_basic_tri_reboot_policy"]; //for ss
		for (var i = 0; i < cron_params2.length; i++) {
			dbus[cron_params2[i]] = E(cron_params2[i]).value;
		}
	}
	push_data(dbus);
}

</script>
</head>
<body onload="init();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<div id="LoadingBar" class="popup_bar_bg">
<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock"  align="center">
	<tr>
		<td height="100">
		<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
		<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
		<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;overflow:hidden">
			<textarea cols="63" rows="21" wrap="on" readonly="readonly" id="log_content3" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:#000;color:#FFFFFF;outline: none;padding-left:3px;padding-right:22px;overflow-x:hidden"></textarea>
		</div>
		<div id="ok_button" class="apply_gen" style="background: #000;display: none;">
			<input id="ok_button1" class="button_gen" type="button" onclick="hideSSLoadingBar()" value="确定">
		</div>
		</td>
	</tr>
</table>
</div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/applydb.cgi?p=ss" target="hidden_frame">
<input type="hidden" name="current_page" value="Main_Ss_Content.asp"/>
<input type="hidden" name="next_page" value="Main_Ss_Content.asp"/>
<input type="hidden" name="group_id" value=""/>
<input type="hidden" name="modified" value="0"/>
<input type="hidden" name="action_mode" value=""/>
<input type="hidden" name="action_script" value=""/>
<input type="hidden" name="action_wait" value="6"/>
<input type="hidden" name="first_time" value=""/>
<input type="hidden" id="vpnc_type" name="vpnc_type" value="">
<input type="hidden" id="ss_online_action" name="ss_online_action" value="" />
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>"/>
<input type="hidden" name="SystemCmd" value=""/>
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>"/>
<table class="content" align="center" cellpadding="0" cellspacing="0">
	<tr>
		<td width="17">&nbsp;</td>
		<!--=====Beginning of Main Menu=====-->
		<td valign="top" width="202">
			<div id="mainMenu"></div>
			<div id="subMenu"></div>
		</td>
		<td valign="top">
			<div id="tabMenu" class="submenuBlock"></div>
			<!--=====Beginning of Main Content=====-->
			<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0" id="table_for_all" style="display: block;">
				<tr>
					<td align="left" valign="top">
						<div>
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle">梅林固件 - 科学上网插件</div>
										<div style="float:right; width:15px; height:25px;margin-top:-20px">
											<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
										</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
										<div class="SimpleNote" id="head_illustrate">本插件是支持<a href="https://github.com/shadowsocks/shadowsocks-libev" target="_blank"><em><u>SS</u></em></a>、<a href="https://github.com/shadowsocksrr/shadowsocksr-libev" target="_blank"><em><u>SSR</u></em></a>、<a href="http://firmware.koolshare.cn/binary/koolgame/" target="_blank"><em><u>KoolGame</u></em></a>、<a href="https://github.com/v2ray/v2ray-core" target="_blank"><em><u>V2Ray</u></em></a>四种客户端的科学上网、游戏加速工具。</div>
										<div style="margin-top: 0px;text-align: center;font-size: 18px;margin-bottom: 0px;" class="formfontdesc" id="cmdDesc"></div>
										<!-- this is the popup area for status -->
										<div id="detail_status"  class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: 0px;display: none;">
											<div class="user_title">【科学上网】状态检测</div>
											<div style="margin-left:15px"><i>&nbsp;&nbsp;目前本功能支持ss相关进程状态和iptables表状态检测。</i></div>
											<div id="user_tr" style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden">
												<textarea cols="63" rows="36" wrap="off" id="proc_status" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
											</div>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="close_proc_status();" value="返回主界面">	
											</div>	
										</div>
										<!-- end of the popouparea -->
										<div id="ss_switch_show">
											<table style="margin:0px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="ss_switch_table">
												<thead>
												<tr>
													<td colspan="2">开关</td>
												</tr>
												</thead>
												<tr>
												<th id="ss_switch"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(10)">科学上网开关</a></th>
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
															<a id="updateBtn" type="button" class="ss_btn" style="cursor:pointer" onclick="update_ss(3)">检查并更新</a>
														</div>
														<div id="ss_version_show" style="display:table-cell;float: left;position: absolute;margin-left:170px;padding: 5.5px 0px;">
															<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(12)">
																<i>当前版本：<% dbus_get_def("ss_basic_version_local", "未知"); %></i>
															</a>
														</div>
														<div style="display:table-cell;float: left;margin-left:270px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" target="_blank" href="https://github.com/hq450/fancyss/blob/master/fancyss_arm/Changelog.txt">更新日志</a>
														</div>
														<div style="display:table-cell;float: left;margin-left:350px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" href="javascript:void(0);" onclick="pop_help()">插件帮助</a>
														</div>
													</td>
												</tr>
                                    		</table>
                                    	</div>
                                    	<div id="ss_status1">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr id="ss_state">
												<th id="mode_state" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(0)">SS运行状态</a></th>
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
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_proc_status(3)" href="javascript:void(0);">详细状态</a>
														</div>
													</td>
												</tr>
											</table>
										</div>
										<div id="tablets">
											<table style="margin:10px 0px 0px 0px;border-collapse:collapse" width="100%" height="37px">
												<tr width="235px">
													<td colspan="4" cellpadding="0" cellspacing="0" style="padding:0" border="1" bordercolor="#000">
														<input id="show_btn1" class="show-btn1" style="cursor:pointer" type="button" value="账号设置" />
														<input id="show_btn1_1" class="show-btn1_1" style="cursor:pointer" type="button" value="节点管理" />
														<input id="show_btn2" class="show-btn2" style="cursor:pointer" type="button" value="DNS设定" />
														<input id="show_btn3" class="show-btn3" style="cursor:pointer" type="button" value="黑白名单" />
														<input id="show_btn3_1" class="show-btn3_1" style="cursor:pointer" type="button" value="KCP加速" />
														<input id="show_btn3_2" class="show-btn3_2" style="cursor:pointer" type="button" value="UDP加速"/>
														<input id="show_btn4" class="show-btn4" style="cursor:pointer" type="button" value="更新管理" />
														<input id="show_btn5" class="show-btn5" style="cursor:pointer" type="button" value="访问控制" />
														<input id="show_btn6" class="show-btn6" style="cursor:pointer" type="button" value="附加功能" />
														<input id="show_btn7" class="show-btn7" style="cursor:pointer" type="button" value="查看日志" />
													</td>
												</tr>
											</table>
										</div>
										<div id="vpnc_settings"  class="contentM_qis" style="box-shadow: 3px 3px 10px #000;margin-top: 50px;">
											<table class="QISform_wireless" border=0 align="center" cellpadding="5" cellspacing="0">
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
														<!-- vpnc_pptp/l2tp start  -->
														<div>
														<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
															<tr id="ss_node_table_mode_tr">
																<th>使用模式</th>
																<td>
																	<select id="ss_node_table_mode" name="ss_node_table_mode" class="input_option" style="width:350px;margin:0px 0px 0px 2px;" onchange="verifyFields(this, 1);">
																		<option value="1">【1】 gfwlist模式</option>
																		<option value="2">【2】 大陆白名单模式</option>
																		<option value="3">【3】 游戏模式</option>
																		<option value="5">【4】 全局代理模式</option>
																		<option value="6">【5】 回国模式</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_use_json_tr" style="display: none;">
																<th width="35%">
																	使用json配置&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(27)"><font color="#ffcc00"><u>[说明]</u></font></a>
																</th>
																<td>
																	<input type="checkbox" id="ss_node_table_v2ray_use_json" name="ss_node_table_v2ray_use_json" onclick="verifyFields(this, 1);" >
																</td>
															</tr>
															<tr id="ss_name_support_tr" style="display: none;">
																<th>节点别名</th>
																<td>
																  	<input type="text" maxlength="64" id="ss_node_table_name" name="ss_node_table_name" value="" class="input_ss_table" style="width:342px;float:left;" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_server_support_tr" style="display: none;">
																<th>服务器地址</th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_server" name="ss_node_table_server" value="" class="input_ss_table" style="width:342px;float:left;" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_port_support_tr" style="display: none;">
																<th>服务器端口</th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_port" name="ss_node_table_port" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_passwd_support_tr" style="display: none;">
																<th>密码</th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_password" name="ss_node_table_password" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_method_support_tr" style="display: none;">
																<th>加密方式</th>
																<td>
																	<select id="ss_node_table_method" name="ss_node_table_method" class="input_option" style="width:350px;margin:0px 0px 0px 2px;">
																		<option value="none">none</option>
																		<option value="rc4">rc4</option>
																		<option value="rc4-md5">rc4-md5</option>
																		<option value="rc4-md5-6">rc4-md5-6</option>
																		<option value="aes-128-gcm">AEAD_AES_128_GCM</option>
																		<option value="aes-192-gcm">AEAD_AES_192_GCM</option>
																		<option value="aes-256-gcm">AEAD_AES_256_GCM</option>
																		<option value="aes-128-cfb">aes-128-cfb</option>
																		<option value="aes-192-cfb">aes-192-cfb</option>
																		<option value="aes-256-cfb" selected>aes-256-cfb</option>
																		<option value="aes-128-ctr">aes-128-ctr</option>
																		<option value="aes-192-ctr">aes-192-ctr</option>
																		<option value="aes-256-ctr">aes-256-ctr</option>
																		<option value="camellia-128-cfb">camellia-128-cfb</option>
																		<option value="camellia-192-cfb">camellia-192-cfb</option>
																		<option value="camellia-256-cfb">camellia-256-cfb</option>
																		<option value="bf-cfb">bf-cfb</option>
																		<option value="cast5-cfb">cast5-cfb</option>
																		<option value="idea-cfb">idea-cfb</option>
																		<option value="rc2-cfb">rc2-cfb</option>
																		<option value="seed-cfb">seed-cfb</option>
																		<option value="salsa20">salsa20</option>
																		<option value="chacha20">chacha20</option>
																		<option value="chacha20-ietf">chacha20-ietf</option>
																		<option value="chacha20-ietf-poly1305">chacha20-ietf-poly1305</option>
																		<option value="xchacha20-ietf-poly1305">xchacha20-ietf-poly1305</option>
																	</select>
																</td>	
															</tr>
															<tr id="ss_v2ray_plugin_support" style="display: none;">
																<th>v2ray-plugin</th>
																<td>
																	<select name="ss_node_table_ss_v2ray_plugin" id="ss_node_table_ss_v2ray_plugin" class="input_option" style="width:350px;margin:0px 0px 0px 2px;" onchange="verifyFields(this, 1);">
																		<option value="0" selected>关闭</option>
																		<option value="1">启用</option>
																	</select>
																</td>
															</tr>
															<tr id="ss_v2ray_plugin_opts_support" style="display: none;">
																<th>v2ray-plugin参数</th>
																<td>
																	<input type="text" name="ss_node_table_ss_v2ray_plugin_opts" id="ss_node_table_ss_v2ray_plugin_opts" placeholder="tls;host=cloudfront.com"  class="input_ss_table" style="width:342px;" maxlength="100" value=""/>
																</td>
															</tr>
															<tr id="ssr_protocol_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>协议 (protocol)</u></a></th>
																<td>
																	<select id="ss_node_table_rss_protocol" name="ss_node_table_rss_protocol" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="origin" selected>origin</option>
																		<option value="verify_simple">verify_simple</option>
																		<option value="verify_sha1">verify_sha1</option>
																		<option value="auth_sha1">auth_sha1</option>
																		<option value="auth_sha1_v2">auth_sha1_v2</option>
																		<option value="auth_sha1_v4">auth_sha1_v4</option>
																		<option value="auth_aes128_md5">auth_aes128_md5</option>
																		<option value="auth_aes128_sha1">auth_aes128_sha1</option>
																		<option value="auth_chain_a">auth_chain_a</option>
																		<option value="auth_chain_b">auth_chain_b</option>
																		<option value="auth_chain_c">auth_chain_c</option>
																		<option value="auth_chain_d">auth_chain_d</option>
																		<option value="auth_chain_e">auth_chain_e</option>
																		<option value="auth_chain_f">auth_chain_f</option>
																	</select>
																</td>
															</tr>
															<tr id="ssr_protocol_param_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>协议参数 (protocol_param)</u></a></th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_rss_protocol_param" name="ss_node_table_rss_protocol_param" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ssr_obfs_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>混淆 (obfs)</u></a></th>
																<td>
																	<select id="ss_node_table_rss_obfs" name="ss_node_table_rss_obfs" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="plain">plain</option>
																		<option value="http_simple">http_simple</option>
																		<option value="http_post">http_post</option>
																		<option value="tls1.2_ticket_auth">tls1.2_ticket_auth</option>
																	</select>
																</td>
															</tr>
															<tr id="ssr_obfs_param_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md" target="_blank"><u>混淆参数 (obfs_param)</u></a></th>
																<td>
																	<input type="text" name="ss_node_table_rss_obfs_param" id="ss_node_table_rss_obfs_param" placeholder="cloudflare.com"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="gameV2_udp_tr" style="display: none;">
																<th width="35%">UDP通道</th>
																<td>
																	<select id="ss_node_table_koolgame_udp" name="ss_node_table_koolgame_udp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="0">udp in udp</option>
																		<option value="1">udp in tcp</option>
																	</select>
																</td>
															</tr>
										      				<!--===================================v2ray===========================================-->			
															<tr id="v2ray_uuid_tr" style="display: none;">
																<th width="35%">用户id（id）</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_uuid" id="ss_node_table_v2ray_uuid"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>															
															<tr id="v2ray_alterid_tr" style="display: none;">
																<th width="35%">额外ID (Alterld)</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_alterid" id="ss_node_table_v2ray_alterid"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>		
															<tr id="v2ray_security_tr" style="display: none;">
																<th width="35%">加密方式 (security)</th>
																<td>
																	<select id="ss_node_table_v2ray_security" name="ss_node_table_v2ray_security" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="auto">自动</option>
																		<option value="aes-128-cfb">aes-128-cfb</option>
																		<option value="aes-128-gcm">aes-128-gcm</option>
																		<option value="chacha20-poly1305">chacha20-poly1305</option>
																		<option value="none">不加密</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_tr" style="display: none;">
																<th width="35%">传输协议 (network)</th>
																<td>
																	<select id="ss_node_table_v2ray_network" name="ss_node_table_v2ray_network" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
																		<option value="tcp">tcp</option>
																		<option value="kcp">kcp</option>
																		<option value="ws">ws</option>
																		<option value="h2">h2</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_headtype_tcp_tr" style="display: none;">
																<th width="35%">tcp伪装类型 (type)</th>
																<td>
																	<select id="ss_node_table_v2ray_headtype_tcp" name="ss_node_table_v2ray_headtype_tcp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
																		<option value="none">不伪装</option>
																		<option value="http">伪装http</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_headtype_kcp_tr" style="display: none;">
																<th width="35%">kcp伪装类型 (type)</th>
																<td>
																	<select id="ss_node_table_v2ray_headtype_kcp" name="ss_node_table_v2ray_headtype_kcp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
																		<option value="none">不伪装</option>
																		<option value="srtp">伪装视频通话(srtp)</option>
																		<option value="utp">伪装BT下载(uTP)</option>
																		<option value="wechat-video">伪装微信视频通话</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_host_tr" style="display: none;">
																<th width="35%">伪装域名 (host)</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_network_host" id="ss_node_table_v2ray_network_host"  class="input_ss_table" placeholder="没有请留空" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_network_path_tr" style="display: none;">
																<th width="35%">路径 (path)</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_network_path" id="ss_node_table_v2ray_network_path"  class="input_ss_table" placeholder="没有请留空" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_network_security_tr" style="display: none;">
																<th width="35%">底层传输安全</th>
																<td>
																	<select id="ss_node_table_v2ray_network_security" name="ss_node_table_v2ray_network_security" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="none">关闭</option>
																		<option value="tls">tls</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_mux_enable_tr" style="display: none;">
																<th width="35%">多路复用 (Mux)</th>
																<td>
																	<input type="checkbox" id="ss_node_table_v2ray_mux_enable" name="ss_node_table_v2ray_mux_enable" onclick="verifyFields(this, 1);" value="0">
																</td>
															</tr>
															<tr id="v2ray_mux_concurrency_tr" style="display: none;">
																<th width="35%">Mux并发连接数</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_mux_concurrency" id="ss_node_table_v2ray_mux_concurrency"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_json_tr" style="display: none;">
																<th width="35%">v2ray json</th>
																<td>
																	<textarea placeholder="# 此处填入v2ray json，内容可以是标准的也可以是压缩的
																	# 请保证你json内的outbound配置正确！！！
																	# ------------------------------------
																	# 同样支持vmess://链接填入，格式如下：
																	vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIjIzMyIsDQogICJhZGQiOiAiMjMzLjIzMy4yMzMuMjMzIiwNCiAgInBvcnQiOiAiMjMzIiwNCiAgImlkIjogImFlY2EzYzViLTc0NzktNDFjMy1hMWUzLTAyMjkzYzg2Y2EzOCIsDQogICJhaWQiOiAiMjMzIiwNCiAgIm5ldCI6ICJ3cyIsDQogICJ0eXBlIjogIm5vbmUiLA0KICAiaG9zdCI6ICJ3d3cuMjMzLmNvbSIsDQogICJwYXRoIjogIi8yMzMiLA0KICAidGxzIjogInRscyINCn0=" rows="32" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_node_table_v2ray_json" name="ss_node_table_v2ray_json" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
																</td>
															</tr>
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
										
										<!--=====bacic show =====-->
										<div id="tablet_1">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr id="node_select">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(15)">节点选择</a></th>
													<td>
														<select id="ssconf_basic_node" name="ssconf_basic_node" style="width:auto;min-width:164px;max-width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="ss_node_sel();" ></select>
													</td>
												</tr>
												<tr id="mode_select">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(1)">模式</a>
														</th>
													<td>
														<select id="ss_basic_mode" name="ss_basic_mode" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option value="1">【1】 gfwlist模式</option>
															<option value="2">【2】 大陆白名单模式</option>
															<option value="3">【3】 游戏模式</option>
															<option value="5">【4】 全局代理模式</option>
															<option value="6">【5】 回国模式</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_use_json_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(27)"><font color="#ffcc00">使用json配置</font></a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_v2ray_use_json" name="ss_basic_v2ray_use_json" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="server_tr">
													<th id="server_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a></th>
													<td>
														<input type="text" class="input_ss_table" id="ss_basic_server" name="ss_basic_server" maxlength="100" value=""/>
													</td>
												</tr>
												<tr id="port_tr">
													<th id="port_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a></th>
													<td>
														<input type="text" class="input_ss_table" id="ss_basic_port" name="ss_basic_port" maxlength="100" value="" />
													</td>
												</tr>
												<tr id="pass_tr">
													<th id="pass_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(4)">密码</a></th>
													<td>
														<input type="password" name="ss_basic_password" id="ss_basic_password" class="input_ss_table" autocomplete="off" autocorrect="off" autocapitalize="off" maxlength="100" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>												
												<tr id="method_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(5)">加密方式</a></th>
													<td>
														<select id="ss_basic_method" name="ss_basic_method" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none">none</option>
															<option value="rc4">rc4</option>
															<option value="rc4-md5">rc4-md5</option>
															<option value="rc4-md5-6">rc4-md5-6</option>
															<option value="aes-128-gcm">AEAD_AES_128_GCM</option>
															<option value="aes-192-gcm">AEAD_AES_192_GCM</option>
															<option value="aes-256-gcm">AEAD_AES_256_GCM</option>
															<option value="aes-128-cfb">aes-128-cfb</option>
															<option value="aes-192-cfb">aes-192-cfb</option>
															<option value="aes-256-cfb" selected>aes-256-cfb</option>
															<option value="aes-128-ctr">aes-128-ctr</option>
															<option value="aes-192-ctr">aes-192-ctr</option>
															<option value="aes-256-ctr">aes-256-ctr</option>
															<option value="camellia-128-cfb">camellia-128-cfb</option>
															<option value="camellia-192-cfb">camellia-192-cfb</option>
															<option value="camellia-256-cfb">camellia-256-cfb</option>
															<option value="bf-cfb">bf-cfb</option>
															<option value="cast5-cfb">cast5-cfb</option>
															<option value="idea-cfb">idea-cfb</option>
															<option value="rc2-cfb">rc2-cfb</option>
															<option value="seed-cfb">seed-cfb</option>
															<option value="salsa20">salsa20</option>
															<option value="chacha20">chacha20</option>
															<option value="chacha20-ietf">chacha20-ietf</option>
															<option value="chacha20-ietf-poly1305">chacha20-ietf-poly1305</option>
															<option value="xchacha20-ietf-poly1305">xchacha20-ietf-poly1305</option>
														</select>
													</td>
												</tr>
												<tr id="ss_koolgame_udp_tr" >
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(6)">UDP通道</a></th>
													<td>
														<select id="ss_basic_koolgame_udp" name="ss_basic_koolgame_udp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option value="0">udp in udp</option>
															<option value="1">udp in tcp</option>
														</select>
													</td>
												</tr>
												<tr id="ss_v2ray_plugin">
													<th width="35%">v2ray-plugin</th>
													<td>
														<select id="ss_basic_ss_v2ray_plugin" name="ss_basic_ss_v2ray_plugin" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="0">关闭</option>
															<option class="content_input_fd" value="1">启用</option>
														</select>
													</td>
												</tr>
												<tr id="ss_v2ray_plugin_opts">
													<th width="35%">v2ray-plugin参数</th>
													<td>
														<input type="text" name="ss_basic_ss_v2ray_plugin_opts" id="ss_basic_ss_v2ray_plugin_opts" placeholder="tls;host=cloudfront.com"  class="input_ss_table" maxlength="100" value=""/>
													</td>
												</tr>
												
												<tr id="ss_basic_rss_protocol_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(8)">协议 (protocol)</a></th>
													<td>
														<select id="ss_basic_rss_protocol" name="ss_basic_rss_protocol" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="origin">origin</option>
															<option class="content_input_fd" value="verify_simple">verify_simple</option>
															<option class="content_input_fd" value="verify_sha1">verify_sha1</option>
															<option class="content_input_fd" value="auth_sha1">auth_sha1</option>
															<option class="content_input_fd" value="auth_sha1_v2">auth_sha1_v2</option>
															<option class="content_input_fd" value="auth_sha1_v4">auth_sha1_v4</option>
															<option value="auth_aes128_md5">auth_aes128_md5</option>
															<option value="auth_aes128_sha1">auth_aes128_sha1</option>
															<option value="auth_chain_a">auth_chain_a</option>
															<option value="auth_chain_b">auth_chain_b</option>
															<option value="auth_chain_c">auth_chain_c</option>
															<option value="auth_chain_d">auth_chain_d</option>
															<option value="auth_chain_e">auth_chain_e</option>
															<option value="auth_chain_f">auth_chain_f</option>
														</select>
														<span id="ss_basic_rss_protocol_alert" style="margin-left:5px;margin-top:-20px;margin-bottom:0px"></span>
													</td>
												</tr>
												<tr id="ss_basic_rss_protocol_param_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(54)">协议参数 (protocol_param)</a></th>
													<td>
														<input type="password" name="ss_basic_rss_protocol_param" id="ss_basic_rss_protocol_param" placeholder="id:password"  class="input_ss_table" maxlength="100" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_rss_obfs_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(9)">混淆 (obfs)</a></th>
													<td>
														<select id="ss_basic_rss_obfs" name="ss_basic_rss_obfs" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="plain">plain</option>
															<option class="content_input_fd" value="http_simple">http_simple</option>
															<option class="content_input_fd" value="http_post">http_post</option>
															<option class="content_input_fd" value="tls1.2_ticket_auth">tls1.2_ticket_auth</option>
														</select>
														<span id="ss_basic_rss_obfs_alert" style="margin-left:5px;margin-top:-20px;margin-bottom:0px"></span>
													</td>
												</tr>
												<tr id="ss_basic_ticket_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(11)">混淆参数 (obfs_param)</a></th>
													<td>
														<input type="text" name="ss_basic_rss_obfs_param" id="ss_basic_rss_obfs_param" placeholder="cloudflare.com"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>
										      	<!--===================================v2ray===========================================-->			
												<tr id="v2ray_uuid_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(49)"><font color="#ffcc00">用户id（id）</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_uuid" id="ss_basic_v2ray_uuid"  class="input_ss_table" style="width:300px;" maxlength="300" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>															
												<tr id="v2ray_alterid_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(48)"><font color="#ffcc00">额外ID (Alterld)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_alterid" id="ss_basic_v2ray_alterid"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>		
												<tr id="v2ray_security_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(47)"><font color="#ffcc00">加密方式 (security)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_security" name="ss_basic_v2ray_security" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="none">不加密</option>
															<option value="auto">自动</option>
															<option value="aes-128-cfb">aes-128-cfb</option>
															<option value="aes-128-gcm">aes-128-gcm</option>
															<option value="chacha20-poly1305">chacha20-poly1305</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_network_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(35)"><font color="#ffcc00">传输协议 (network)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_network" name="ss_basic_v2ray_network" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="tcp">tcp</option>
															<option value="kcp">kcp</option>
															<option value="ws">ws</option>
															<option value="h2">h2</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_headtype_tcp_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(36)"><font color="#ffcc00">&nbsp;&nbsp;* tcp伪装类型 (type)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_headtype_tcp" name="ss_basic_v2ray_headtype_tcp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none">不伪装</option>
															<option value="http">伪装http</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_headtype_kcp_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(37)"><font color="#ffcc00">&nbsp;&nbsp;* kcp伪装类型 (type)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_headtype_kcp" name="ss_basic_v2ray_headtype_kcp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none">不伪装</option>
															<option value="srtp">伪装视频通话(srtp)</option>
															<option value="utp">伪装BT下载(uTP)</option>
															<option value="wechat-video">伪装微信视频通话</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_network_host_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(28)"><font color="#ffcc00">&nbsp;&nbsp;* 伪装域名 (host)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_network_host" id="ss_basic_v2ray_network_host" class="input_ss_table"  placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_network_path_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(29)"><font color="#ffcc00">&nbsp;&nbsp;* 路径 (path)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_network_path" id="ss_basic_v2ray_network_path" class="input_ss_table"  placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_network_security_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(30)"><font color="#ffcc00">底层传输安全</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_network_security" name="ss_basic_v2ray_network_security" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="none">关闭</option>
															<option value="tls">tls</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_mux_enable_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(31)"><font color="#ffcc00">多路复用 (Mux)</font></a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_v2ray_mux_enable" name="ss_basic_v2ray_mux_enable" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="v2ray_mux_concurrency_basic_tr" style="display: none;">
													<th width="35%">
													<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(32)"><font color="#ffcc00">Mux并发连接数</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_mux_concurrency" id="ss_basic_v2ray_mux_concurrency"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_json_basic_tr" style="display: none;">
													<th width="35%">v2ray json</th>
													<td>
														<textarea  placeholder="# 此处填入v2ray json，内容可以是标准的也可以是压缩的
																	# 请保证你json内的outbound配置正确！！！
																	# ------------------------------------
																	# 同样支持vmess://链接填入，格式如下：
																	vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIjIzMyIsDQogICJhZGQiOiAiMjMzLjIzMy4yMzMuMjMzIiwNCiAgInBvcnQiOiAiMjMzIiwNCiAgImlkIjogImFlY2EzYzViLTc0NzktNDFjMy1hMWUzLTAyMjkzYzg2Y2EzOCIsDQogICJhaWQiOiAiMjMzIiwNCiAgIm5ldCI6ICJ3cyIsDQogICJ0eXBlIjogIm5vbmUiLA0KICAiaG9zdCI6ICJ3d3cuMjMzLmNvbSIsDQogICJwYXRoIjogIi8yMzMiLA0KICAidGxzIjogInRscyINCn0=" rows="40" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_basic_v2ray_json" name="ss_basic_v2ray_json" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
													</td>
												</tr>
												<tr id="v2ray_binary_update_tr" style="display: none;">
													<th width="35%">其它</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="v2ray_binary_update(2)">更新V2Ray程序</V2R></a>
													</td>
												</tr>
											</table>
										</div>
										<!-- 节点面板 -->
										<div id="ss_node_list_table_th" style="display: none; height:40px;margin:-1px 0px 0px 0px">
											<table style="margin:-1px 0px 0px 0px;table-layout:fixed;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable1">
												<tr height="40px">
													<th style="width:40px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(16)">模式</a></th>
													<th style="width:90px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(17)">节点名称</a></th>
													<th style="width:90px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(18)">服务器地址</a></th>
													<th style="width:37px;">端口</th>
													<th style="width:90px;">加密方式</th>
													<th style="width:78px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(19)">ping/丢包</a></th>
													<th style="width:36px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(20)">延迟</a></th>
													<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(21)">编辑</a></th>
													<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(22)">删除</a></th>
													<th style="width:65px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(23)">使用</a></th>
												</tr>
											</table>
										</div>
										<div id="ss_node_list_table_td" style="display: none;">
											<div id="ss_node_list_table_main" style="width:748px;">
												<table id="ss_node_list_table" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable1">
													<tr id="hide_when_folw" height="40px" style="display: none;">
														<th style="width:40px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(16)">模式</a></th>
														<th style="width:90px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(17)">节点名称</a></th>
														<th style="width:90px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(18)">服务器地址</a></th>
														<th style="width:37px;">端口</th>
														<th style="width:90px;">加密方式</th>
														<th style="width:78px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(19)">ping/丢包</a></th>
														<th style="width:36px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(20)">延迟</a></th>
														<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(21)">编辑</a></th>
														<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(22)">删除</a></th>
														<th style="width:65px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(23)">使用</a></th>
													</tr>
												</table>
											</div>
										</div>
										<div id="ss_node_list_table_btn" style="display: none;width: 100%;">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th style="width:20%;">ping测试</th>
													<td>
														<input class="ss_btn" style="cursor:pointer;" onClick="ping_test()" type="button" value="ping测试"/>
														<select id="ssconf_basic_ping_node" name="ssconf_basic_ping_node" style="width:124px;margin:0px 0px 0px 2px;" class="input_option" onchange="update_ping_method();"></select>
														<select id="ssconf_basic_ping_method" name="ssconf_basic_ping_method" style="width:160px;margin:0px 0px 0px 2px;" class="input_option"></select>
														<input class="ss_btn" style="cursor:pointer;" onClick="remove_ping()" type="button" value="清空结果"/>
													</td>
												</tr>
												<tr>
													<th style="width:20%;">web测试</th>
													<td>
														<input class="ss_btn" style="cursor:pointer;" onClick="web_test()" type="button" value="web测试"/>
															<select id="ssconf_basic_test_node" name="ssconf_basic_test_node" style="width:124px;margin:0px 0px 0px 2px;" class="input_option">
															</select>
														<select id="ssconf_basic_test_domain" name="ssconf_basic_test_domain" style="width:160px;margin:0px 0px 0px 2px;" class="input_option">
															<option class="content_input_fd" value="https://www.google.com.hk/">google.com</option>
															<option class="content_input_fd" value="https://www.twitter.com/">twitter.com</option>
															<option class="content_input_fd" value="https://www.facebook.com/">facebook.com</option>
															<option class="content_input_fd" value="https://www.youtube.com/">youtube.com</option>
														</select>
														<input class="ss_btn" style="cursor:pointer;" onClick="remove_test()" type="button" value="清空结果"/>
													</td>
												</tr>
											</table>
											<table>
												<tr>
													<td>
														<div id="node_return_button" class="apply_gen" style="margin-left: 188px;;float: left;">
															<input id="add_ss_node" class="button_gen" onClick="Add_profile()" type="button" value="添加节点"/>
														</div>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_2=====-->
										<div id="tablet_2" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr id="dns_plan_china">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(25)">选择中国DNS</a></th>
													<td id="dns_plan_china_td">
														<select id="ss_dns_china" name="ss_dns_china" class="input_option" onclick="update_visibility();" >
															<option value="1" selected>运营商DNS【自动获取】</option>
															<option value="2">阿里DNS1【223.5.5.5】</option>
															<option value="3">阿里DNS2【223.6.6.6】</option>
															<option value="4">114DNS1【114.114.114.114】</option>
															<option value="5">114DNS1【114.114.115.115】</option>
															<option value="6">cnnic DNS【1.2.4.8】</option>
															<option value="7">cnnic DNS【210.2.4.8】</option>
															<option value="8">oneDNS1【117.50.11.11】</option>
															<option value="9">oneDNS2【117.50.22.22】</option>
															<option value="10">百度DNS【180.76.76.76】</option>
															<option value="11">DNSpod DNS【119.29.29.29】</option>
															<option value="12">自定义</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_dns_china_user" name="ss_dns_china_user" value="">
													</td>
												</tr>
												<tr id="dns_plan_foreign">
													<th width="20%">
														选择外国DNS&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(26)"><font color="#ffcc00"><u>[说明]</u></font></a>
													</th>
													<td>
														<select id="ss_foreign_dns" name="ss_foreign_dns" class="input_option" onclick="update_visibility();" >
															<option value="3" selected="">dns2socks</option>
															<option value="4">ss-tunnel</option>
															<option value="1">cdns</option>
															<option value="5">chinadns1</option>
															<option value="2">chinadns2</option>
															<option value="6">https_dns_proxy</option>
															<option value="7">v2ray_dns</option>
															<option value="8">直连</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_dns2socks_user" name="ss_dns2socks_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
														<input type="text" class="input_ss_table" id="ss_chinadns1_user" name="ss_chinadns1_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
														<input type="text" class="input_ss_table" id="ss_chinadns_user" name="ss_chinadns_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
														<input type="text" class="input_ss_table" id="ss_sstunnel_user" name="ss_sstunnel_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
														<input type="text" class="input_ss_table" id="ss_direct_user" name="ss_direct_user" style="width:160px" placeholder="需端口号如：8.8.8.8#53" value="8.8.8.8#53">
														<span id="ss_foreign_dns_note"></span>
													</td>
												</tr>
												<tr id="dns_plan_foreign_game2" style="display: none;">
												<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(47)">选择国外DNS</a></th>
													<td>
														<select id="ss_game2_dns_foreign" name="ss_game2_dns_foreign" class="input_option" onclick="update_visibility();" disabled="disabled" >
															<option value="1" selected>koolgame内置</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_game2_dns2ss_user" name="ss_game2_dns2ss_user" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
														<br/>
															<span id="dns_plan_foreign0">默认使用koolgame内置的DNS2SS域名解析</span>
													</td>
												</tr>
												<tr>
													<th>DNS劫持（原chromecast功能）&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(106)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<input type="checkbox" id="ss_basic_dns_hijack" onclick="verifyFields(this, 1);" checked="" />
													</td>
												</tr>
												<tr>
													<th>节点域名解析DNS服务器&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(107)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select id="ss_basic_server_resolver" name="ss_basic_server_resolver" class="input_option" onclick="update_visibility();" >
															<option value="1" selected>运营商DNS【自动获取】</option>
															<option value="2">阿里DNS1【223.5.5.5】</option>
															<option value="3">阿里DNS2【223.6.6.6】</option>
															<option value="4">114DNS1【114.114.114.114】</option>
															<option value="5">114DNS1【114.114.115.115】</option>
															<option value="6">cnnic DNS【1.2.4.8】</option>
															<option value="7">cnnic DNS【210.2.4.8】</option>
															<option value="8">oneDNS1【117.50.11.11】</option>
															<option value="9">oneDNS2【117.50.22.22】</option>
															<option value="10">百度DNS【180.76.76.76】</option>
															<option value="11">DNSpod DNS【119.29.29.29】</option>
															<option value="12">自定义</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_basic_server_resolver_user" name="ss_basic_server_resolver_user" value="">
													</td>
												</tr>
												<tr>
												<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(34)">自定义dnsmasq</a></th>
													<td>
														<textarea placeholder="# 填入自定义的dnsmasq设置，一行一个
# 例如hosts设置：
address=/weibo.com/2.2.2.2
# 防DNS劫持设置：
bogus-nxdomain=220.250.64.18" rows="12" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_dnsmasq" name="ss_dnsmasq" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_3=====-->
										<div id="tablet_3" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr id="ss_wan_white_ip_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(38)">IP/CIDR白名单</a><br>
														<br>
														<font color="#ffcc00">添加不需要走代理的外网ip地址</font>
													</th>
													<td>
														<textarea placeholder="# 填入不需要走代理的外网ip地址，一行一个，格式（IP/CIDR）如下
2.2.2.2
3.3.3.3
4.4.4.4/24" cols="50" rows="7" id="ss_wan_white_ip" name="ss_wan_white_ip" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_white_domain_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(39)">域名白名单</a><br>
														<br>
														<font color="#ffcc00">添加不需要走代理的域名</font>
													</th>
													<td>
														<textarea placeholder="# 填入不需要走代理的域名，一行一个，格式如下：
google.com
facebook.com
# 需要清空电脑DNS缓存，才能立即看到效果。" cols="50" rows="7" id="ss_wan_white_domain" name="ss_wan_white_domain" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_black_ip_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(40)">IP/CIDR黑名单</a><br>
														<br>
														<font color="#ffcc00">添加需要强制走代理的外网ip地址</font>
													</th>
													<td>
														<textarea placeholder="# 填入需要强制走代理的外网ip地址，一行一个，格式（IP/CIDR）如下：
5.5.5.5
6.6.6.6
7.7.7.7/8" cols="50" rows="7" id="ss_wan_black_ip" name="ss_wan_black_ip" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_black_domain_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(41)">域名黑名单</a><br>
														<br>
														<font color="#ffcc00">添加需要强制走代理的域名</font>
													</th>
													<td>
														<textarea placeholder="# 填入需要强制走代理的域名，一行一个，格式如下：
baidu.com
taobao.com
# 需要清空电脑DNS缓存，才能立即看到效果。" cols="50" rows="7" id="ss_wan_black_domain" name="ss_wan_black_domain" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_3_1=====-->
										<div id="tablet_3_1" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th width="35%">
														KCP加速开关
													</th>
													<td>
														<input type="checkbox" id="ss_basic_use_kcp" onclick="verifyFields(this, 1);" />
													</td>
												</tr>
												<tr>
													<th width="35%">KCP参数配置方式</th>
													<td>
														<select id="ss_basic_kcp_method" name="ss_basic_kcp_method" class="input_option" onchange="verifyFields(this, 1);" style="width:164px;margin:0px 0px 0px 2px;">
															<option value="1">选择模式</option>
															<option value="2" selected>输入模式</option>
														</select>		
													</td>
												</tr>

												<tr id="ss_kcp_l_server_port_tr">
													<th width="35%">kcp本地监听地址：端口 （-l）</th>
													<td>
														<input type="text" name="ss_basic_kcp_lserver" id="ss_basic_kcp_lserver" class="input_ss_table" style="width:120px;" maxlength="200" value="0.0.0.0" readonly/>
														:
														<input type="text" name="ss_basic_kcp_lport" id="ss_basic_kcp_lport" class="input_ss_table" style="width:44px;" maxlength="200" value="1091" readonly/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(90)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_kcp_r_server_port_tr">
													<th width="35%">kcp服务器地址：端口 （-r）</th>
													<td>
														<input type="text" name="ss_basic_kcp_server" id="ss_basic_kcp_server" class="input_ss_table" style="width:120px;" maxlength="200" value=""/>
														:
														<input type="text" name="ss_basic_kcp_port" id="ss_basic_kcp_port" class="input_ss_table" style="width:44px;" maxlength="200" value=""/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(91)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<!--<tr id="ss_basic_kcp_port_tr">
													<th width="35%">KCP 端口</th>
													<td>
														<input type="text" name="ss_basic_kcp_port" id="ss_basic_kcp_port"  class="input_ss_table" maxlength="200" value=""/>
													</td>
												</tr>-->
												<tr id="ss_basic_kcp_password_tr" style="display: none;">
													<th width="35%">密码 (--key)</th>
													<td>
														<input type="text" name="ss_basic_kcp_password" id="ss_basic_kcp_password"  class="input_ss_table" maxlength="200" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_mode_tr" style="display: none;">
													<th width="35%">速度模式 (--mode)</th>
													<td>
														<select id="ss_basic_kcp_mode" name="ss_basic_kcp_mode" class="input_option" style="width:164px;margin:0px 0px 0px 2px;">
															<option value="manual">manual</option>
															<option value="normal">normal</option>
															<option value="fast">fast</option>
															<option value="fast2" selected="">fast2</option>
															<option value="fast3">fast3</option
														</select>		
													</td>
												</tr>
												<tr id="ss_basic_kcp_encrypt_tr" style="display: none;">
													<th width="35%">加密方式 (--crypt)</th>
													<td>
														<select id="ss_basic_kcp_encrypt" name="ss_basic_kcp_encrypt" class="input_option" style="width:164px;margin:0px 0px 0px 2px;">
															<option value="aes">aes</option>
															<option value="aes-128">aes-128</option>
															<option value="aes-192" selected="">aes-192</option>
															<option value="salsa20">salsa20</option>
															<option value="blowfish">blowfish</option>
															<option value="twofish">twofish</option>
															<option value="cast5">cast5</option>
															<option value="3des">3des</option>
															<option value="tea">tea</option>
															<option value="xtea">xtea</option>
															<option value="xor">xor</option>
															<option value="none">none</option>
														</select>		
													</td>
												</tr>
												<tr id="ss_basic_kcp_mtu_tr" style="display: none;">
													<th width="35%">MTU (--mtu)</th>
													<td>
														<input type="text" name="ss_basic_kcp_mtu" id="ss_basic_kcp_mtu"  class="input_ss_table" maxlength="200" value=""/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_sndwnd_tr" style="display: none;">
													<th width="35%">发送窗口 (--sndwnd)</th>
													<td>
														<input type="text" name="ss_basic_kcp_sndwnd" id="ss_basic_kcp_sndwnd"  class="input_ss_table" maxlength="200" value=""/>
													</td>
												</tr>												
												<tr id="ss_basic_kcp_rcvwnd_tr" style="display: none;">
													<th width="35%">接收窗口 (--rcvwnd)</th>
													<td>
														<input type="text" name="ss_basic_kcp_rcvwnd" id="ss_basic_kcp_rcvwnd"  class="input_ss_table" maxlength="200" value=""/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_conn_tr" style="display: none;">
													<th width="35%">链接数 (--conn)</th>
													<td>
														<input type="text" name="ss_basic_kcp_conn" id="ss_basic_kcp_conn"  class="input_ss_table" maxlength="200" value=""/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_nocomp_tr" style="display: none;">
													<th width="35%">关闭数据压缩 (--nocomp)</th>
													<td>
														<input type="checkbox" name="ss_basic_kcp_nocomp" id="ss_basic_kcp_nocomp"/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_extra_tr" style="display: none;">
													<th width="35%">其它配置项</th>
													<td>
														<input type="text" name="ss_basic_kcp_extra" id="ss_basic_kcp_extra"  class="input_ss_table" style="width:98%" value="" placeholder="请将速度模式为manual的参数和其它参数依次填写进来" title="请将速度模式为manual的参数和其它参数依次填写进来"/>
													</td>
												</tr>
												<tr id="ss_basic_kcp_parameter_tr" style="display: none;">
													<th width="35%">KCP参数</th>
													<td>
														<textarea style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#576D73;color:#FFFFFF;border:1px solid gray;" id="ss_basic_kcp_parameter" name="ss_basic_kcp_parameter" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_3_2=====-->
										<div id="tablet_3_2" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th width="35%">UDP加速节点选择</th>
													<td>
														<select id="ss_basic_udp_node" name="ss_basic_udp_node" style="width:auto;min-width:130px;max-width:130px;margin:0px 0px 0px 2px;" class="input_option"></select>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(97)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr>
													<th width="35%">设置ss/ssr-redir MTU</th>
													<td>
														<select id="ss_basic_udp_upstream_mtu" name="ss_basic_udp_upstream_mtu" style="width:auto;margin:0px 0px 0px 2px;" class="input_option" onchange="update_visibility();" >
																<option value="0">不设定</option>
																<option value="1">手动指定</option>
														</select>
														<input type="text" name="ss_basic_udp_upstream_mtu_value" id="ss_basic_udp_upstream_mtu_value" class="input_ss_table" style="width:40px;" value="1200"/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(98)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr>
													<th width="35%">帮助信息</th>
													<td>
														<ul>
															<li>你可以只开启UDPspeeder加速udp，或者只开启UDP2raw将udp转为tcp；</li>
															<li>你也可以将UDPspeeder和UDP2raw都开启，并配置它们串联工作；</li>
															<li>
																帮助文档：												
																<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.v1.md"><em><u>UDPspeederV1</u></em></a>
																&nbsp;
																<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/blob/master/doc/README.zh-cn.md"><em><u>UDPspeederV2</u></em></a>
																&nbsp;
																<a type="button" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/udp2raw-tunnel/blob/master/doc/README.zh-cn.md"><em><u>udp2raw-tunnel</u></em></a>
															</li>
														</ul>
													</td>
												</tr>
												<tr>
													<th>UDPspeeder运行状态</th>
													<td>
														<span id="udp_status">获取中...</span>
													</td>
												</tr>
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
											<table id="UDPspeeder_table" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th colspan="2"><em>UDPspeeder 设置</em></th>
												</tr>
												<tr>
													<th width="35%">UDPspeeder开关</th>
													<td>
														<input type="checkbox" id="ss_basic_udp_boost_enable"/>
													</td>
												</tr>
												<tr>
													<th width="35%">UDPspeeder版本</th>
													<td>
														<select id="ss_basic_udp_software" name="ss_basic_udp_software" class="input_option" style="width:130px" onchange="verifyFields(this, 1);" >
															<option value="1" selected>UDPspeederV1</option>
															<option value="2">UDPspeederV2</option>
														</select>	
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(104)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
											</table>
											<table id="UDPspeederV1_table" style="display:none;margin:0px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th colspan="2"><em>UDPspeederV1 参数设置</em></th>
												</tr>
												<tr id="ss_basic_udpv1_l_server_port_tr">
													<th width="35%">* 本地监听地址：端口 （-l）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_lserver" id="ss_basic_udpv1_lserver" class="input_ss_table" style="width:120px;" maxlength="200" value="0.0.0.0" readonly/>
														:
														<input type="text" name="ss_basic_udpv1_lport" id="ss_basic_udpv1_lport" class="input_ss_table" style="width:44px;" maxlength="200" value="1092" readonly/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(99)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_r_server_port_tr">
													<th width="35%">* 服务器地址：端口 （-r）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_rserver" id="ss_basic_udpv1_rserver" class="input_ss_table" style="width:120px;" maxlength="200" value=""/>
														:
														<input type="text" name="ss_basic_udpv1_rport" id="ss_basic_udpv1_rport" class="input_ss_table" style="width:44px;" maxlength="200" value=""/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(100)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_password_tr">
													<th width="35%">* 密码 （-k,--key）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_password" id="ss_basic_udpv1_password"  class="input_ss_table" maxlength="200" value="" style="width:120px;" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_middle">
													<th colspan="2">
														以下为包发送选项，两端设置可以不同, 只影响本地包发送。
													</th>
												</tr>
												<tr id="ss_basic_udpv1_duplicate_nu_tr">
													<th width="35%">* 冗余包数量 （-d）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_duplicate_nu" id="ss_basic_udpv1_duplicate_nu" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>默认0，留空则使用默认值。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_duplicate_time_tr">
													<th width="35%">* 冗余包发送延迟 （-t）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_duplicate_time" id="ss_basic_udpv1_duplicate_time" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>默认值20（2ms），留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_jitter_tr">
													<th width="35%">* 原始数据抖动延迟 （-j）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_jitter" id="ss_basic_udpv1_jitter" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>默认0，留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_report_tr">
													<th width="35%">* 数据发送和接受报告 （--report）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_report" id="ss_basic_udpv1_report" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：s，留空则不使用。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_drop_tr">
													<th width="35%">* 随机丢包 （--random-drop）</th>
													<td>
														<input type="text" name="ss_basic_udpv1_drop" id="ss_basic_udpv1_drop" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：0.01%，留空则不使用。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv1_middle">
													<th colspan="2">
														以下为包接收选项，两端设置可以不同，只影响本地包接受。
													</th>
												</tr>
												<tr id="ss_basic_udpv1_disable_filter_tr">
													<th width="35%">* 关闭重复包过滤器 （--disable-filter）</th>
													<td>
														<input type="checkbox" id="ss_basic_udpv1_disable_filter"/>
													</td>
												</tr>
											</table>
											<table id="UDPspeederV2_table" style="display:none;margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th colspan="2"><em>UDPspeederV2 参数设置</em></th>
												</tr>
												<tr id="ss_basic_udpv2_l_server_port_tr">
													<th width="35%">* 本地监听地址：端口 （-l）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_lserver" id="ss_basic_udpv2_lserver" class="input_ss_table" style="width:120px;" maxlength="200" value="0.0.0.0" readonly/>
														:
														<input type="text" name="ss_basic_udpv2_lport" id="ss_basic_udpv2_lport" class="input_ss_table" style="width:44px;" maxlength="200" value="1092" readonly/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(99)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_r_server_port_tr">
													<th width="35%">* 服务器地址：端口 （-r）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_rserver" id="ss_basic_udpv2_rserver" class="input_ss_table" style="width:120px;" maxlength="200" value=""/>
														:
														<input type="text" name="ss_basic_udpv2_rport" id="ss_basic_udpv2_rport" class="input_ss_table" style="width:44px;" maxlength="200" value=""/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(100)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_password_tr">
													<th width="35%">* 密码 （-k,--key）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_password" id="ss_basic_udpv2_password"  class="input_ss_table" maxlength="200" value="" style="width:120px;" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_middle">
													<th colspan="2">
														以下为包发送选项，两端设置可以不同, 只影响本地包发送。
													</th>
												</tr>
												<tr id="ss_basic_udpv2_fec_tr">
													<th width="35%">* fec参数 （-f）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_fec" id="ss_basic_udpv2_fec" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>必填，x:y，每x个包额外发送y个包。</a>
														<a type="button" class="ss_btn" style="cursor:pointer" target="_blank" href="https://github.com/wangyu-/UDPspeeder/wiki/%E4%BD%BF%E7%94%A8%E7%BB%8F%E9%AA%8C">fec使用经验</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_timeout_tr">
													<th width="35%">* timeout参数 （--timeout）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_timeout" id="ss_basic_udpv2_timeout" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：ms，默认8，留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_mode_tr">
													<th width="35%">* mode参数 （--mode）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_mode" id="ss_basic_udpv2_mode" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>默认0，留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_report_tr">
													<th width="35%">* 数据发送和接受报告 （--report）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_report" id="ss_basic_udpv2_report" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：s，留空则不使用。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_mtu_tr">
													<th width="35%">* mtu参数 （--mtu）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_mtu" id="ss_basic_udpv2_mtu" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>默认1250，留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_jitter_tr">
													<th width="35%">* 原始数据抖动延迟 （-j,--jitter）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_jitter" id="ss_basic_udpv2_jitter" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：ms，默认0，留空则使用默认值</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_interval_tr">
													<th width="35%">* 时间窗口 （-i,--interval）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_interval" id="ss_basic_udpv2_interval" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：ms，默认0，留空则使用默认值。</a>
													</td>
												</tr>

												<tr id="ss_basic_udpv2_drop_tr">
													<th width="35%">* 随机丢包 （--random-drop）</th>
													<td>
														<input type="text" name="ss_basic_udpv2_drop" id="ss_basic_udpv2_drop" class="input_ss_table" style="width:120px;" maxlength="200" value="" />
														<a>单位：0.01%，默认0，留空则使用默认值。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_middle">
													<th colspan="2">
														以下服务器和客户端设置必须一致！
													</th>
												</tr>
												<tr id="ss_basic_udpv2_disableobscure_tr">
													<th width="35%">* 关闭数据包随机填充（--disable-obscure）</th>
													<td>
														<input type="checkbox" id="ss_basic_udpv2_disableobscure"/>
														<a>关闭可节省一点带宽和cpu。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_disablechecksum_tr">
													<th width="35%">* 关闭数据包验证（--disable-checksum）</th>
													<td>
														<input type="checkbox" id="ss_basic_udpv2_disablechecksum"/>
														<a>关闭可节省一点带宽和cpu。</a>
													</td>
												</tr>
												<tr id="ss_basic_udpv2_middle">
													<th colspan="2">
														其它参数
													</th>
												</tr>
												<tr id="ss_basic_udpv2_other_tr">
													<th width="35%">* 其它参数</th>
													<td>
														<input type="text" name="ss_basic_udpv2_other" id="ss_basic_udpv2_other" class="input_ss_table" style="width:200px;" value="" />
														<br /><a>其它高级参数，请手动输入，如 -q1 等。</a>
													</td>
												</tr>										
											</table>

											<table id="UDP2raw_table" style="display:none;margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th colspan="2"><em>UDP2raw 设置</em></th>
												</tr>
												<tr>
													<th width="35%">UDP2raw开关</th>
													<td>
														<input type="checkbox" id="ss_basic_udp2raw_boost_enable"/>
													</td>
												</tr>
												<tr>
													<th colspan="2"><em>UDP2raw 参数设置</em></th>
												</tr>
												<tr id="ss_basic_udp2raw_l_server_port_tr">
													<th width="35%">* 本地监听地址：端口 （-l）</th>
													<td>
														<input type="text" name="ss_basic_udp2raw_lserver" id="ss_basic_udp2raw_lserver" class="input_ss_table" style="width:120px;" maxlength="200" value="0.0.0.0" readonly/>
														:
														<input type="text" name="ss_basic_udp2raw_lport" id="ss_basic_udp2raw_lport" class="input_ss_table" style="width:44px;" maxlength="200" value="1093" readonly/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(101)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_r_server_port_tr">
													<th width="35%">* 服务器地址：端口 （-r）</th>
													<td>
														<input type="text" name="ss_basic_udp2raw_rserver" id="ss_basic_udp2raw_rserver" class="input_ss_table" style="width:120px;" maxlength="200" value=""/>
														:
														<input type="text" name="ss_basic_udp2raw_rport" id="ss_basic_udp2raw_rport" class="input_ss_table" style="width:44px;" maxlength="200" value=""/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(102)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_password_tr">
													<th width="35%">* 密码 （-k,--key）</th>
													<td>
														<input type="text" name="ss_basic_udp2raw_password" id="ss_basic_udp2raw_password"  class="input_ss_table" maxlength="200" value="" style="width:120px;" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_rawmode_tr">
													<th width="35%">* 模式（--raw-mode）</th>
													<td>
														<select id="ss_basic_udp2raw_rawmode" name="ss_basic_udp2raw_rawmode" class="input_option" style="width:130px">
															<option value="faketcp" selected="">faketcp</option>
															<option value="udp">udp</option>
															<option value="icmp">icmp</option>
														</select>	
														<a>默认:faketcp</a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_ciphermode_tr">
													<th width="35%">* 加密模式 （--cipher-mode）</th>
													<td>
														<select id="ss_basic_udp2raw_ciphermode" name="ss_basic_udp2raw_ciphermode" class="input_option" style="width:130px">
															<option value="aes128cbc" selected="">aes128cbc</option>
															<option value="aes128cfb">aes128cfb</option>
															<option value="xor">xor</option>
															<option value="none">无</option>
														</select>	
														<a>默认:aes128cbc</a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_authmode_tr">
													<th width="35%">* 校验模式 （--auth-mode）</th>
													<td>
														<select id="ss_basic_udp2raw_authmode" name="ss_basic_udp2raw_authmode" class="input_option" style="width:130px">
															<option value="md5" selected="">md5</option>
															<option value="hmac_sha1">hmac_sha1</option>
															<option value="crc32">crc32</option>
															<option value="icmp">icmp</option>
															<option value="simple">simple</option>
															<option value="none">none</option>
														</select>	
														<a>默认:md5</a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_a_tr">
													<th width="35%">* 自动添加/删除iptables（-a,--auto-rule）</th>
													<td>
														<input type="checkbox" checked="" id="ss_basic_udp2raw_a"/>
														<a>梅林固件请勾选此选项</a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_keeprule_tr">
													<th width="35%">* 定期检查iptables（--keep-rule）</th>
													<td>
														<input type="checkbox" checked="" id="ss_basic_udp2raw_keeprule"/>
														<a>梅林固件请勾选此选项</a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_lowerlevel_tr">
													<th width="35%">* 绕过本地iptables（--lower-level）</th>
													<td>
														<input type="text" name="ss_basic_udp2raw_lowerlevel" id="ss_basic_udp2raw_lowerlevel" class="input_ss_table" style="width:120px;" value=""/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(103)"><font color="#ffcc00"><u>帮助</u></font></a>
													</td>
												</tr>
												<tr id="ss_basic_udp2raw_other_tr">
													<th width="35%">* 其它参数</th>
													<td>
														<input type="text" name="ss_basic_udp2raw_other" id="ss_basic_udp2raw_other" class="input_ss_table" style="width:98%;" value="" />
														<br /><a>其它未列出来的参数，请手动输入，如 --force-sock-buf --seq-mode 1 等。</a>
													</td>
												</tr>	
											</table>
										</div>	
										<div id="tablet_4" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr  id="gfw_number">
													<th id="gfw_nu1" width="35%">gfwlist域名数量</th>
													<td id="gfw_nu2">
															<% nvram_get("ipset_numbers"); %>&nbsp;条，最后更新版本：
															<a href="https://github.com/hq450/fancyss/blob/master/rules/gfwlist.conf" target="_blank">
																<i><% nvram_get("update_ipset"); %></i>
														</a>
													</td>
												</tr>
												<tr  id="chn_number">
													<th id="chn_nu1" width="35%">大陆白名单IP段数量</th>
												<td id="chn_nu2">
													<p>
														<% nvram_get("chnroute_numbers"); %>&nbsp;行，最后更新版本：
														<a href="https://github.com/hq450/fancyss/blob/master/rules/chnroute.txt" target="_blank">
															<i><% nvram_get("update_chnroute"); %></i>
														</a>
													</p>
												</td>
												</tr>
												<tr  id="cdn_number">		
													<th id="cdn_nu1" width="35%">国内域名数量（cdn名单）</th>		
													<td id="cdn_nu2">		
														<p>		
														<% nvram_get("cdn_numbers"); %>&nbsp;条，最后更新版本：		
															<a href="https://github.com/hq450/fancyss/blob/master/rules/cdn.txt" target="_blank">		
																<i><% nvram_get("update_cdn"); %></i>		
															</a>		
														</p>		
													</td>		
												</tr>
												<tr id="update_rules">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(44)">规则定时更新任务</a></th>
													<td>
														<select id="ss_basic_rule_update" name="ss_basic_rule_update" class="input_option" onchange="update_visibility();" >
															<option value="0">禁用</option>
															<option value="1">开启</option>
														</select>
														<select id="ss_basic_rule_update_time" name="ss_basic_rule_update_time" class="input_option" title="选择规则列表自动更新时间，更新后将自动重启SS" onchange="update_visibility();" >
															<option value="0">00:00点</option>
															<option value="1">01:00点</option>
															<option value="2">02:00点</option>
															<option value="3">03:00点</option>
															<option value="4">04:00点</option>
															<option value="5">05:00点</option>
															<option value="6">06:00点</option>
															<option value="7">07:00点</option>
															<option value="8">08:00点</option>
															<option value="9">09:00点</option>
															<option value="10">10:00点</option>
															<option value="11">11:00点</option>
															<option value="12">12:00点</option>
															<option value="13">13:00点</option>
															<option value="14">14:00点</option>
															<option value="15">15:00点</option>
															<option value="16">16:00点</option>
															<option value="17">17:00点</option>
															<option value="18">18:00点</option>
															<option value="19">19:00点</option>
															<option value="20">20:00点</option>
															<option value="21">21:00点</option>
															<option value="22">22:00点</option>
															<option value="23">23:00点</option>
														</select>
															&nbsp;
															<a id="update_choose">
																<input type="checkbox" id="ss_basic_gfwlist_update" title="选择此项应用gfwlist自动更新">gfwlist
																<input type="checkbox" id="ss_basic_chnroute_update">chnroute
																<input type="checkbox" id="ss_basic_cdn_update">CDN
															</a>
															<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(1)">保存设置</a>
															<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(2)">立即更新</a>
													</td>
												</tr>
											</table>
											<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"/></div>
											<table id="conf_table1" style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
												<tr>
													<td colspan="3">SSR/v2ray订阅设置</td>
												</tr>
												</thead>
												<tr>
													<th width="35%">订阅地址管理（支持SSR/v2ray）</th>
													<td>
														<textarea placeholder="填入需要订阅的地址，多个地址分行填写" rows=8 style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;border:1px solid gray;" id="ss_online_links" name="ss_online_links" title="" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr>
													<th width="35%">订阅节点模式设定（SSR/v2ray）</th>
													<td>
														<select id="ssr_subscribe_mode" name="ssr_subscribe_mode" class="input_option" onchange="update_visibility();" >
															<option value="1">【1】 gfwlist模式</option>
															<option value="2">【2】 大陆白名单模式</option>
															<option value="3">【3】 游戏模式</option>
															<option value="5">【4】 全局代理模式</option>
															<option value="6">【5】 回国模式</option>
														</select>
													</td>
												</tr>
												<tr>
													<th width="35%">订阅节点混淆参数设定（SSR）</th>
													<td>
														<select id="ssr_subscribe_obfspara" name="ssr_subscribe_obfspara" class="input_option" onchange="update_visibility();" >
															<option value="0">留空</option>
															<option value="1" selected="">使用订阅设定</option>
															<option value="2">自定义</option>
														</select>
														<input type="text" id="ssr_subscribe_obfspara_val" name="ssr_subscribe_obfspara_val" class="input_ss_table" maxlength="50" style="width:140px;" placeholder="" value="www.baidu.com" />
													</td>
												</tr>
												<tr>
													<th width="35%">下载订阅时走SS/SSR/v2ray代理网络</th>
													<td>
														<select id="ss_basic_online_links_goss" name="ss_basic_online_links_goss" class="input_option" onchange="update_visibility();" >
															<option value="0" selected="">不走代理</option>
															<option value="1">走代理</option>
														</select>
													</td>
												</tr>
												<tr>
													<th width="35%">订阅计划任务</th>
													<td>
														<select id="ss_basic_node_update" name="ss_basic_node_update" class="input_option" onchange="update_visibility();" >
															<option value="0" selected="">禁用</option>
															<option value="1">开启</option>
														</select>
														<select id="ss_basic_node_update_day" name="ss_basic_node_update_day" class="input_option" onchange="update_visibility();" >
															<option value="7" selected="">每天</option>
															<option value="1">周一</option>
															<option value="2">周二</option>
															<option value="3">周三</option>
															<option value="4">周四</option>
															<option value="5">周五</option>
															<option value="6">周六</option>
															<option value="0">周日</option>
														</select>
														<select id="ss_basic_node_update_hr" name="ss_basic_node_update_hr" class="input_option" onchange="update_visibility();" >
															<option value="0">0点</option><option value="1">1点</option><option value="2">2点</option><option value="3" selected="">3点</option><option value="4">4点</option><option value="5">5点</option><option value="6">6点</option><option value="7">7点</option><option value="8">8点</option><option value="9">9点</option><option value="10">10点</option><option value="11">11点</option><option value="12">12点</option><option value="13">13点</option><option value="14">14点</option><option value="15">15点</option><option value="16">16点</option><option value="17">17点</option><option value="18">18点</option><option value="19">19点</option><option value="20">20点</option><option value="21">21点</option><option value="22">22点</option><option value="23">23点</option>
														</select>
													</td>
												</tr>
												<tr>
													<th width="35%">删除节点</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(0)">删除全部节点</a>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(1)">删除全部订阅节点</a>
													</td>
												</tr>
												<tr>
													<th width="35%">订阅操作</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(2)">仅保存设置</a>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(3)">保存并订阅</a>
													</td>
												</tr>
											</table>
											<table style="margin:8px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
												<tr>
													<td colspan="3">通过SS/SSR/vmess链接添加服务器</td>
												</tr>
												</thead>
												<tr>
													<th width="35%">SS/SSR/vmess链接</th>
													<td>
														<textarea placeholder="填入以ss://或者ssr://或者vmess://开头的链接，多个链接请分行填写" rows=9 style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;border:1px solid gray;" id="ss_base64_links" name="ss_base64_links" title="" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr>
													<th width="35%">操作</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_online_nodes(4)">解析并保存为节点</a>
													</td>
												</tr>
											</table>
										</div>
										<!--====LAN ACL=====-->
										<div id="tablet_5" style="display: none;">
											<table id="ACL_table" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
													<tr>
														<th style="width:180px;">主机IP地址</th>
														<th style="width:160px;">主机别名</th>
														<th style="width:160px;">访问控制</th>
														<th style="width:160px;">目标端口</th>
														<th style="width:60px;">添加/删除</th>
													</tr>
													<tr>
														<td>
															<input type="text" maxlength="15" class="input_15_table" id="ss_acl_ip" name="ss_acl_ip" align="left" onkeypress="return validator.isIPAddr(this, event)" style="float:left;" autocomplete="off" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off">
															<img id="pull_arrow" height="14px;" src="images/arrow-down.gif" align="right" onclick="pullLANIPList(this);" title="<#select_IP#>">
															<div id="ClientList_Block" class="clientlist_dropdown" style="margin-left:2px;margin-top:25px;"></div>
														</td>
														<td>
															<input type="text" id="ss_acl_name" name="ss_acl_name" class="input_ss_table" maxlength="50" style="width:140px;" placeholder="" />
														</td>
														<td>
															<select id="ss_acl_mode" name="ss_acl_mode" style="width:160px;margin:0px 0px 0px 2px;" class="input_option" onchange="set_mode_1(this);">
																<option value="0">不通过代理</option>
																<option value="1">gfwlist模式</option>
																<option value="2">大陆白名单模式</option>
																<option value="3">游戏模式</option>
																<option value="5">全局代理模式</option>
																<option value="6">回国模式</option>
															</select>
														</td>
														<td>
															<select id="ss_acl_port" name="ss_acl_port" style="width:100px;margin:0px 0px 0px 2px;" class="input_option">
																<option value="80,443">80,443</option>
																<option value="22,80,443">22,80,443</option>
																<option value="all">all</option>
															</select>
														</td>
														<td style="width:66px">
															<input style="margin-left: 6px;margin: -3px 0px -5px 6px;" type="button" class="add_btn" onclick="addTr()" value="" />
														</td>
													</tr>
											</table>
											<div id="ACL_note">
											<div><i>1&nbsp;&nbsp;默认状态下，所有局域网的主机都会走当前节点的模式（主模式），相当于即不启用局域网访问控制。</i></div>
											<div><i>2&nbsp;&nbsp;当你添加了主机，并设置默认规则为不通过SS，则只有添加的主机才会走相应的模式。</i></div>
											<div><i>3&nbsp;&nbsp;当你添加了主机，并设置默认规则为当前节点的模式，除了添加的主机才会走相应的模式，未添加的主机会走默认规则的模式。</i></div>
											<div><i>4&nbsp;&nbsp;如果使用了KCP协议，或者负载均衡，因为它们不支持udp，所以不能控制单个主机走游戏模式。</i></div>
											</div>
										</div>
										<!--===== addon =====-->
										<div id="tablet_6" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr>
													<th style="width:20%;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(24)">导出SS配置</a></th>
													<td>
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_SS_node();" value="导出配置">
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="remove_SS_node();" value="清空配置">
													</td>
												</tr>
												<tr>
													<th style="width:20%;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(24)">恢复SS配置（支持ss/ssr的json节点）</a></th>
													<td>
														<input style="color:#FFCC00;*color:#000;width: 200px;" id="ss_file" type="file" name="file"/>
														<img id="loadingicon" style="margin-left:5px;margin-right:5px;display:none;" src="/images/InternetScan.gif"/>
														<span id="ss_file_info" style="display:none;">完成</span>
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="upload_ss_backup();" value="恢复配置"/>
													</td>
												</tr>
												<tr>
													<th	width="20%">插件定时重启设定（实验）</th>
													<td>
														<select	id="ss_reboot_check" name="ss_reboot_check"	style="margin:0px 0px 0px 2px;"	class="input_option" onchange="status_onchange();" >
															<option	value="0" selected>关闭</option>
															<option	value="1">每天</option>
															<option	value="2">每周</option>
															<option	value="3">每月</option>
															<option	value="4">每隔</option>
															<option	value="5">自定义</option>
														</select>
														<span id="_ss_basic_week_pre" style="display: none;">
															<select	id="ss_basic_week" name="ss_basic_week"	style="margin:0px 0px 0px 2px;"	class="input_option" >
																<option	value="1">一</option>
																<option	value="2">二</option>
																<option	value="3">三</option>
																<option	value="4">四</option>
																<option	value="5">五</option>
																<option	value="6">六</option>
																<option	value="7">日</option>
															</select>
														</span>
														<span id="_ss_basic_day_pre" style="display: none;">
															<select	id="ss_basic_day" name="ss_basic_day" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="1">1日</option>
																<option	value="2">2日</option>
																<option	value="3">3日</option>
																<option	value="4">4日</option>
																<option	value="5">5日</option>
																<option	value="6">6日</option>
																<option	value="7">7日</option>
																<option	value="8">8日</option>
																<option	value="9">9日</option>
																<option	value="10">10日</option>
																<option	value="11">11日</option>
																<option	value="12">12日</option>
																<option	value="13">13日</option>
																<option	value="14">14日</option>
																<option	value="15">15日</option>
																<option	value="16">16日</option>
																<option	value="17">17日</option>
																<option	value="18">18日</option>
																<option	value="19">19日</option>
																<option	value="20">20日</option>
																<option	value="21">21日</option>
																<option	value="22">22日</option>
																<option	value="23">23日</option>
																<option	value="24">24日</option>
																<option	value="25">25日</option>
																<option	value="26">26日</option>
																<option	value="27">27日</option>
																<option	value="28">28日</option>
																<option	value="29">29日</option>
																<option	value="30">30日</option>
																<option	value="31">31日</option>
															</select>
														</span>
														<span id="_ss_basic_inter_pre" style="display: none;">
															<select	id="ss_basic_inter_min"	name="ss_basic_inter_min" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="1">1</option>
																<option	value="5">5</option>
																<option	value="10">10</option>
																<option	value="15">15</option>
																<option	value="20">20</option>
																<option	value="25">25</option>
																<option	value="30">30</option>
															</select>
															<select	id="ss_basic_inter_hour" name="ss_basic_inter_hour"	style="display:	none; margin:0px 0px 0px 2px;" class="input_option"	>
																<option	value="1">1</option>
																<option	value="2">2</option>
																<option	value="3">3</option>
																<option	value="4">4</option>
																<option	value="5">5</option>
																<option	value="6">6</option>
																<option	value="7">7</option>
																<option	value="8">8</option>
																<option	value="9">9</option>
																<option	value="10">10</option>
																<option	value="11">11</option>
																<option	value="12">12</option>
															</select>
															<select	id="ss_basic_inter_day"	name="ss_basic_inter_day" style="display: none;	margin:0px 0px 0px 2px;" class="input_option" >
																<option	value="1">1</option>
																<option	value="2">2</option>
																<option	value="3">3</option>
																<option	value="4">4</option>
																<option	value="5">5</option>
																<option	value="6">6</option>
																<option	value="7">7</option>
																<option	value="8">8</option>
																<option	value="9">9</option>
																<option	value="10">10</option>
																<option	value="11">11</option>
																<option	value="12">12</option>
																<option	value="13">13</option>
																<option	value="14">14</option>
																<option	value="15">15</option>
																<option	value="16">16</option>
																<option	value="17">17</option>
																<option	value="18">18</option>
																<option	value="19">19</option>
																<option	value="20">20</option>
																<option	value="21">21</option>
																<option	value="22">22</option>
																<option	value="23">23</option>
																<option	value="24">24</option>
																<option	value="25">25</option>
																<option	value="26">26</option>
																<option	value="27">27</option>
																<option	value="28">28</option>
																<option	value="29">29</option>
																<option	value="30">30</option>
															</select>
															<select	id="ss_basic_inter_pre"	name="ss_basic_inter_pre" style="margin:0px	0px	0px	2px;" class="input_option" onchange="inter_pre_onchange();"	>
																<option	value="1">分钟</option>
																<option	value="2">小时</option>
																<option	value="3">天</option>
															</select>
														</span>
														<span id="_ss_basic_custom_pre"	style="display:	none;">
															<input type="text" id="ss_basic_custom"	name="ss_basic_custom" class="input_6_table" maxlength="50"	title="填写说明：&#13;此处填写1-23之间任意小时&#13;小时间用逗号间隔，如：&#13;当天的8点、10点、15点则填入：8,10,15" placeholder="8,10,15" style="width:150px;" /> 小时
														</span>
														<span id="_ss_basic_time_pre" style="display: none;">
															<select	id="ss_basic_time_hour"	name="ss_basic_time_hour" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="0">0时</option>
																<option	value="1">1时</option>
																<option	value="2">2时</option>
																<option	value="3">3时</option>
																<option	value="4">4时</option>
																<option	value="5">5时</option>
																<option	value="6">6时</option>
																<option	value="7">7时</option>
																<option	value="8">8时</option>
																<option	value="9">9时</option>
																<option	value="10">10时</option>
																<option	value="11">11时</option>
																<option	value="12">12时</option>
																<option	value="13">13时</option>
																<option	value="14">14时</option>
																<option	value="15">15时</option>
																<option	value="16">16时</option>
																<option	value="17">17时</option>
																<option	value="18">18时</option>
																<option	value="19">19时</option>
																<option	value="20">20时</option>
																<option	value="21">21时</option>
																<option	value="22">22时</option>
																<option	value="23">23时</option>
															</select>
															<select	id="ss_basic_time_min" name="ss_basic_time_min"	style="margin:0px 0px 0px 2px;"	class="input_option" >
																<option	value="0">0分</option>
																<option	value="1">1分</option>
																<option	value="2">2分</option>
																<option	value="3">3分</option>
																<option	value="4">4分</option>
																<option	value="5">5分</option>
																<option	value="6">6分</option>
																<option	value="7">7分</option>
																<option	value="8">8分</option>
																<option	value="9">9分</option>
																<option	value="10">10分</option>
																<option	value="11">11分</option>
																<option	value="12">12分</option>
																<option	value="13">13分</option>
																<option	value="14">14分</option>
																<option	value="15">15分</option>
																<option	value="16">16分</option>
																<option	value="17">17分</option>
																<option	value="18">18分</option>
																<option	value="19">19分</option>
																<option	value="20">20分</option>
																<option	value="21">21分</option>
																<option	value="22">22分</option>
																<option	value="23">23分</option>
																<option	value="24">24分</option>
																<option	value="25">25分</option>
																<option	value="26">26分</option>
																<option	value="27">27分</option>
																<option	value="28">28分</option>
																<option	value="29">29分</option>
																<option	value="30">30分</option>
																<option	value="31">31分</option>
																<option	value="32">32分</option>
																<option	value="33">33分</option>
																<option	value="34">34分</option>
																<option	value="35">35分</option>
																<option	value="36">36分</option>
																<option	value="37">37分</option>
																<option	value="38">38分</option>
																<option	value="39">39分</option>
																<option	value="40">40分</option>
																<option	value="41">41分</option>
																<option	value="42">42分</option>
																<option	value="43">43分</option>
																<option	value="44">44分</option>
																<option	value="45">45分</option>
																<option	value="46">46分</option>
																<option	value="47">47分</option>
																<option	value="48">48分</option>
																<option	value="49">49分</option>
																<option	value="50">50分</option>
																<option	value="51">51分</option>
																<option	value="52">52分</option>
																<option	value="53">53分</option>
																<option	value="54">54分</option>
																<option	value="55">55分</option>
																<option	value="56">56分</option>
																<option	value="57">57分</option>
																<option	value="58">58分</option>
																<option	value="59">59分</option>
															</select>
														</span>
														<span id="_ss_basic_send_text" style="display: none;">重启插件</span>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(1)">保存设置</a>
													</td>
												</tr>
												<tr>
													<th>插件触发重启设定（实验）</th>
													<td>
														<select	id="ss_basic_tri_reboot_time" name="ss_basic_tri_reboot_time" style="margin:0px	0px	0px	2px;" class="input_option" onclick="update_visibility();">
															<option	value="0" selected>关闭</option>
															<option	value="2">每隔2分钟</option>
															<option	value="5">每隔5分钟</option>
															<option	value="10">每隔10分钟</option>
															<option	value="15">每隔15分钟</option>
															<option	value="20">每隔20分钟</option>
															<option	value="25">每隔25分钟</option>
															<option	value="30">每隔30分钟</option>
														</select>
														<span id="ss_basic_tri_reboot_time_note">解析服务器IP，如果发生变更，则重启</span>
														<select	id="ss_basic_tri_reboot_policy" name="ss_basic_tri_reboot_policy" style="margin:0px 0px 0px 2px;" class="input_option" >
															<option	value="1" selected>整个插件</option>
															<option	value="2">dnsmasq</option>
														</select>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(2)">保存设置</a>
													</td>
												</tr>
												<tr>
													<th>替换为dnsmasq-fastlookup&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(105)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select	id="ss_basic_dnsmasq_fastlookup" name="ss_basic_dnsmasq_fastlookup" style="margin:0px 0px 0px 2px;" class="input_option" onclick="update_visibility();">
															<option	value="0" selected>【0】不替换</option>
															<option	value="1">【1】插件开启后替换，插件关闭后恢复原版dnsmasq</option>
															<option	value="2">【2】在用到cdn.conf时替换，插件关闭后恢复原版dnsmasq</option>
															<option	value="3">【3】插件开启后替换，插件关闭后保持替换，不恢复原版dnsmasq</option>
														</select>
													</td>
												</tr>
											</table>
										</div>
										<!--log_content-->
										<div id="tablet_7" style="display: none;">
												<div id="log_content" style="margin-top:-1px;display:none;overflow:hidden;outline: 1px solid #222;">
													<textarea cols="63" rows="36" wrap="on" readonly="readonly" id="log_content1" style="width:97%; padding-left:4px; padding-right:37px; border:0px solid #222; font-family:'Lucida Console'; font-size:11px; background:#475A5F; color:#FFFFFF;outline:none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
										</div>		

										<div class="apply_gen" id="loading_icon">
											<img id="loadingIcon" style="display:none;" src="/images/InternetScan.gif">
										</div>
										<div id="apply_button" class="apply_gen">
											<input class="button_gen" type="button" onclick="save()" value="保存&应用">
											<!--<input class="button_gen" type="button" onclick="save(1)" value="保存">-->
										</div>
										<div id="warn_msg_1" style="display: none;text-align:center; line-height: 4em;"><i></i></div>
										<div id="warn_msg_2" style="display: none;text-align:center; line-height: 4em;"><i></i></div>
									</td>
								</tr>
							</table>
						</div>
					</td>
				</tr>
			</table>
		<!--=====End of Main Content=====-->
		</td>
		<td width="10" align="center" valign="top"></td>
	</tr>
</table>
</form>
<div id="footer"></div>
</body>
</html>
