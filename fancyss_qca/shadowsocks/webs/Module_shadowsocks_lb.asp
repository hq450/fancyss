<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
<meta HTTP-EQUIV="Expires" CONTENT="-1"/>
<link rel="shortcut icon" href="images/favicon.png"/>
<link rel="icon" href="images/favicon.png"/>
<title>软件中心 - 负载均衡</title>
<link rel="stylesheet" type="text/css" href="index_style.css"/>
<link rel="stylesheet" type="text/css" href="form_style.css"/>
<link rel="stylesheet" type="text/css" href="usp_style.css"/>
<link rel="stylesheet" type="text/css" href="ParentalControl.css">
<link rel="stylesheet" type="text/css" href="css/icon.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script>
var db_ss = {};
var _responseLen;
var noChange = 0;
var x = 5;
var lb_node_nu = 0;
var node_global_max = 0;
var dbus = {}
var params = ["ss_lb_passwd", "ss_lb_port", "ss_lb_heartbeat", "ss_lb_up", "ss_lb_down", "ss_lb_interval", "ss_lb_name", "ss_lb_weight", "ss_lb_mode"];

function init() {
	show_menu(menu_hook);
	get_dbus_data();
}

function get_dbus_data() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			//console.log(db_ss);
			conf2obj();
			loadAllConfigs();
			refresh_table();
			load_lb_node_nu();
			generate_link();
			update_visibility();
			buildswitch();
		}
	});
}

function buildswitch() {
	$("#ss_lb_enable").click(
	function() {
		if (!E("ss_lb_enable").checked && db_ss["ss_lb_enable"] == 1) {
			save();
		}
	});
	$("#log_content2").click(
		function() {
			x = -1;
		});
}

function conf2obj(){
	E("ss_lb_enable").checked = db_ss["ss_lb_enable"] == "1";
	for (var i = 0; i < params.length; i++) {
		if(db_ss[params[i]]){
			E(params[i]).value = db_ss[params[i]];
		}
	}
}

function save() {
	lb_enable = E("ss_lb_enable").checked ? '1' : '0';
	if (lb_enable == 0) {
		del_lb_node();
	} else if (lb_enable == 1) {
		if (lb_node_nu < 2) {
			alert("必须选择大于或者等于2个节点，才能正常提交！");
			return false;
		}
		add_new_lb_node();
	}
	//checkbox
	dbus["ss_lb_enable"] = lb_enable;

	//input
	for (var i = 0; i < params.length; i++) {
		if (E(params[i])) {
			dbus[params[i]] = E(params[i]).value;
		}
	}
	db_ss["ss_basic_action"] = 12;
	console.log(dbus);
	push_data("ss_lb_config.sh", "start",  dbus);
}

function push_data(script, arg, obj){
	showSSLoadingBar();
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
				get_realtime_log();
			}
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
				x = 6;
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
			if(db_ss[p + "_ping_" + field].split(" ")[3]){
				obj["ping"] = parseFloat(db_ss[p + "_ping_" + field].split(" ")[0]).toPrecision(3) + " ms / " + parseFloat(db_ss[p + "_ping_" + field].split(" ")[3]) + "%";
			}else{
				obj["ping"] = parseFloat(db_ss[p + "_ping_" + field].split(" ")[0]).toPrecision(3) + " ms";
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

		var params = ["password", "mode", "ss_obfs", "ss_obfs_host", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "group", "weight", "lbmode", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable"];
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

function load_lb_node_nu() {
	confs = getAllConfigs();
	for (var field in confs) {
		var c = confs[field];
		if (c["use_lb"] == "1") {
			lb_node_nu++;
		}
	}
}

function loadBasicOptions(confs) { //载入节点选择列表
	var option = $("#ss_lb_node");
	option.find('option').remove().end();
	for (var field in confs) {
		var c = confs[field];
		if (c["use_lb"] != 1 && c["server"] !== "127.0.0.1") { //节点选择列表中显示所有的非负载均衡节点，并且不显示负载均衡节点本身
			option.append($("<option>", {
				value: field,
				text: c.name
			}));
		}
	}
}

function add_new_lb_node() {
	confs = getAllConfigs();
	cur_lb_node = node_global_max + 1;
	
	for (var field in confs) {
		var c = confs[field];

		if (c["server"] == "127.0.0.1" && c["port"] == db_ss['ss_lb_port']) {
			cur_lb_node = field;
		}
		if (confs[field].use_lb == 1) {
			min_lb_node = field;
		}
	}
	dbus["ssconf_basic_name_" + cur_lb_node] = E("ss_lb_name").value;
	dbus["ssconf_basic_server_" + cur_lb_node] = "127.0.0.1";
	dbus["ssconf_basic_mode_" + cur_lb_node] = db_ss['ssconf_basic_mode_' + min_lb_node];
	dbus["ssconf_basic_port_" + cur_lb_node] = E("ss_lb_port").value;
	dbus["ssconf_basic_password_" + cur_lb_node] = db_ss['ssconf_basic_password_' + min_lb_node];
	dbus["ssconf_basic_method_" + cur_lb_node] = db_ss['ssconf_basic_method_' + min_lb_node];
	dbus["ssconf_basic_ss_obfs" + cur_lb_node] = db_ss['ss_basic_ss_obfs' + min_lb_node];
	dbus["ssconf_basic_ss_obfs_host" + cur_lb_node] = db_ss['ss_basic_ss_obfs_host' + min_lb_node];
	dbus["ssconf_basic_ss_v2ray" + cur_lb_node] = db_ss['ssconf_basic_ss_v2ray' + min_lb_node];
	dbus["ssconf_basic_ss_v2ray_opts" + cur_lb_node] = db_ss['ssconf_basic_ss_v2ray_opts' + min_lb_node];
	dbus["ssconf_basic_rss_protocol_" + cur_lb_node] = db_ss['ssconf_basic_rss_protocol_' + min_lb_node];
	dbus["ssconf_basic_rss_protocol_param_" + cur_lb_node] = db_ss['ssconf_basic_rss_protocol_param_' + min_lb_node];
	dbus["ssconf_basic_rss_obfs_" + cur_lb_node] = db_ss['ssconf_basic_rss_obfs_' + min_lb_node];
	dbus["ssconf_basic_rss_obfs_param_" + cur_lb_node] = db_ss['ssconf_basic_rss_obfs_param_' + min_lb_node];
	//dbus["ssconf_basic_koolgame_udp" + cur_lb_node] = db_ss['ss_basic_koolgame_udp' + min_lb_node];
}

function del_lb_node(o) {
	confs = getAllConfigs();
	cur_lb_node = node_global_max + 1;
	for (var field in confs) {
		var c = confs[field];

		if (c["server"] == "127.0.0.1" && c["port"] == db_ss['ss_lb_port']) {
			cur_lb_node = field;
		}
	}

	var ns = {};
	dbus["ssconf_basic_name_" + cur_lb_node] = "";
	dbus["ssconf_basic_server_" + cur_lb_node] = "";
	dbus["ssconf_basic_mode_" + cur_lb_node] = "";
	dbus["ssconf_basic_port_" + cur_lb_node] = "";
	dbus["ssconf_basic_password_" + cur_lb_node] = "";
	dbus["ssconf_basic_method_" + cur_lb_node] = "";
	dbus["ssconf_basic_ss_obfs" + cur_lb_node] = "";
	dbus["ssconf_basic_ss_obfs_host" + cur_lb_node] = "";
	dbus["ssconf_basic_rss_protocol_" + cur_lb_node] = "";
	dbus["ssconf_basic_rss_protocol_param_" + cur_lb_node] = "";
	dbus["ssconf_basic_rss_obfs_" + cur_lb_node] = "";
	dbus["ssconf_basic_rss_obfs_param_" + cur_lb_node] = "";
	dbus["ssconf_basic_koolgame_udp" + cur_lb_node] = "";
}

function addTr() { //点击添加按钮动作
	lb_node_nu++;
	var ns = {};
	var node_sel = E("ss_lb_node").value;
	if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
		alert("不支持v2ray节点负载均衡！")
		return false;
	}
	if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
		alert("不支持koolgame节点负载均衡！")
		return false;
	}
	
	ns["ssconf_basic_use_lb_" + node_sel] = "1";
	ns["ssconf_basic_weight_" + node_sel] = E("ss_lb_weight").value;
	ns["ssconf_basic_lbmode_" + node_sel] = E("ss_lb_mode").value;
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[2], "fields": ns};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if (response.result == id){
				refresh_table();
				loadAllConfigs();
				$("#ss_lb_node option[value='" + node_sel + "']").remove();
			}
		}
	});
}

function delTr(o) { //删除节点功能
	lb_node_nu--;
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	var ns = {};
	ns["ssconf_basic_use_lb_" + id] = "";
	ns["ssconf_basic_weight_" + id] = "";
	ns["ssconf_basic_lbmode_" + id] = "";
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "dummy_script.sh", "params":[2], "fields": ns};
	$.ajax({
		type: "POST",
		cache:false,
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if (response.result == id){
				refresh_table();
				loadAllConfigs();
			}
		}
	});
}

function refresh_table() {
	$.ajax({
		type: "GET",
		url: "/_api/ss",
		dataType: "json",
		async: false,
		success: function(data) {
			db_ss = data.result[0];
			$("#lb_node_table_2").remove();
			$('#lb_node_table').after(refresh_html());
		}
	});
}

function refresh_html() {
	confs = getAllConfigs();
	var html = '';
	html = html + '<table id="lb_node_table_2" style="margin:-1px 0px 0px 0px;" width="750px" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="list_table">';
	for (var field in confs) {
		var c = confs[field];
		if (c["use_lb"] == 1) {
			html = html + '<tr height="40px">';
			html = html + '<td width="20%" id="ss_node_name_' + c["node"] + '">' + c["name"] + '</td>';
			html = html + '<td width="15%" id="ss_node_server_' + c["node"] + '">' + c["server"] + '</td>';
			html = html + '<td width="15%" id="ss_node_port_' + c["node"] + '">' + c["port"] + '</td>';
			html = html + '<td width="11%" id="ss_node_password_' + c["node"] + '">' + Base64.decode(c["password"]) + '</td>';
			html = html + '<td width="15%" id="ss_node_method_' + c["node"] + '">' + c["method"] + '</td>';
			if (c["lbmode"] == 3) {
				html = html + '<td width="8%" id="ss_node_mode_' + c["node"] + '">备用节点</td>';
			} else if (c["lbmode"] == 2) {
				html = html + '<td width="8%" id="ss_node_mode_' + c["node"] + '">主用节点</td>';
			} else if (c["lbmode"] == 1) {
				html = html + '<td width="11%" id="ss_node_mode_' + c["node"] + '">负载均衡</td>';
			}
			html = html + '<td width="5%" id="ss_node_weight_' + c["node"] + '">' + c["weight"] + '</td>';
			html = html + '<td width="8%" style="width:33px;">'
			html = html + '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
			html = html + '</td>';
			html = html + '</tr>';
		}
	}
	html = html + '</table>';
	return html;
}

function loadAllConfigs() {
	confs = getAllConfigs();
	loadBasicOptions(confs);
}

function generate_link() {
	var link = window.btoa("http://" + '<% nvram_get("lan_ipaddr"); %>' + ":1188")
	E("link4.1").href = "http://" + '<% nvram_get("lan_ipaddr"); %>' + ":1188";
	E("link4.1").innerHTML = "<i><u>http://" + '<% nvram_get("lan_ipaddr"); %>' + ":1188</i></u>";
}

function update_visibility() {
	showhide("heartbeat_detai", (E("ss_lb_heartbeat").value == "1"));
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
</script>
</head>
<body onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg_ks">
	<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock"  align="center">
		<tr>
			<td height="100">
			<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
			<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
			<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;">
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
	<input type="hidden" name="current_page" value="Module_shadowsocks_lb.asp"/>
	<input type="hidden" name="next_page" value="Module_shadowsocks_lb.asp"/>
	<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>"/>
	<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>"/>
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
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle"><% nvram_get("productid"); %> 科学上网插件 - 负载均衡</div>
										<div style="float:right; width:15px; height:25px;margin-top:-20px">
											<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
										</div>
										<div style="margin:10px 0 25px 5px;" class="splitLine"></div>
										<table width="100%" height="150px" style="border-collapse:collapse;">
                                            <tr>
                                                <td colspan="5" class="cloud_main_radius">
                                                    <div style="padding:10px;width:95%;font-style:italic;font-size:14px;">
                                                        <br/><br/>
                                                        <table width="100%" >
                                                            <tr>
                                                                <td>
                                                                    <ul style="margin-top:-80px;padding-left:15px;" >
                                                                        <li style="margin-top:-5px;">
                                                                            <h3 id="push_content1" >在此页面可以设置多个shadowsocks或者shadowsocksR帐号负载均衡，同时具有故障转移、自动恢复的功能。</h3>
                                                                        </li>
                                                                        <li  style="margin-top:-5px;">
                                                                            <h3 id="push_content2"><font color="#FFCC00">注意：负载均衡的节点需要加密方式和密码完全一致！SS、SSR、KCP之间不支持设置负载均衡；不支持v2ray节点的负载均衡。</font></h3>
                                                                        </li>
                                                                        <li id="push_content3_li" style="margin-top:-5px;">
                                                                            <h3 id="push_content3">提交设置后会开启haproxy，并在ss节点配置中增加一个服务器IP为127.0.0.1，端口为负载均衡服务器端口的帐号；</h3>
                                                                        </li>
                                                                        <li id="push_content4_li" style="margin-top:-5px;">
                                                                            <h3 id="push_content4">负载均衡模式下不支持udp转发：不能使用游戏模式，不能使用ss-tunnel作为国外dns方案。</h3>
                                                                        </li>
                                                                        <li id="push_content5_li" style="margin-top:-5px;">
                                                                            <h3 id="push_content4">强烈建议需要负载均衡的ss节点使用ip格式，使用域名会使haproxy进程加载过慢！</h3>
                                                                        </li>
                                                                    </ul>
                                                                </td>
                                                            </tr>
                                                        </table>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr height="10px">
                                                <td colspan="3"></td>
                                            </tr>
                                        </table>
										<div id="lb_setting" style="margin:-25px 0px 0px 0px;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="routing_table">
												<thead>
												<tr>
													<td colspan="2">开关设置</td>
												</tr>
												</thead>
												<tr id="switch_tr">
													<th>
														<label>是否启用负载均衡</label>
													</th>
													<td colspan="2">
														<div class="switch_field" style="display:table-cell">
															<label for="ss_lb_enable">
																<input id="ss_lb_enable" class="switch" type="checkbox" style="display: none;">
																<div class="switch_container" >
																	<div class="switch_bar"></div>
																	<div class="switch_circle transition_style">
																		<div></div>
																	</div>
																</div>
															</label>
														</div>
													</td>
												</tr>
                                				<tr>
                                				   <th style="width:25%;">Haproxy控制台</th>
                                				   <td>
                                				      <div style="padding-top:5px;">
                                				         <a id="link4.1" href="http://aria2.me/glutton/" target="_blank"></a>
														&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														登录帐号：<i><% nvram_get("http_username"); %></i>
														&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														登录密码：
													  	<input type="password" maxlength="64" id="ss_lb_passwd" name="ss_lb_passwd" value="<% nvram_get("http_passwd"); %>" class="input_ss_table" style="width:80px;" autocorrect="off" autocapitalize="off" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
                                				      </div>
                                				    </td>
                                				</tr>
												<tr>
													<th>Haproxy端口(用于ss监听)</th>
													<td>
													  	<input type="text" maxlength="64" id="ss_lb_port" name="ss_lb_port" value="1181" class="input_ss_table" style="width:60px;" autocorrect="off" autocapitalize="off"/>
													</td>
												</tr>

												<tr>
													<th>Haproxy故障检测心跳</th>
													<td>
														<select id="ss_lb_heartbeat" name="ss_lb_heartbeat" style="width:70px;margin:0px 0px 0px 2px;" class="input_option" onchange="update_visibility();">
															<option value="0">不启用</option>
															<option value="1" selected>启用</option>
														</select>
														<span id="heartbeat_detai">
														&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														成功:
													  	<input type="text" maxlength="64" id="ss_lb_up" name="ss_lb_up" value="2" class="input_ss_table" style="width:20px;" autocorrect="off" autocapitalize="off"/>
														次;
														&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														失败:
													  	<input type="text" maxlength="64" id="ss_lb_down" name="ss_lb_down" value="3" class="input_ss_table" style="width:20px;" autocorrect="off" autocapitalize="off"/>
														次;
														&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														心跳间隔:
													  	<input type="text" maxlength="64" id="ss_lb_interval" name="ss_lb_interval" value="2000" class="input_ss_table" style="width:40px;" autocorrect="off" autocapitalize="off"/>
														ms
														</span>
													</td>
												</tr>
												<tr>
													<th>节点名（添加到ss节点列表）</th>
													<td>
													  	<input type="text" maxlength="64" id="ss_lb_name" name="ss_lb_name" value="负载均衡" class="input_ss_table" style="width:80px;" autocorrect="off" autocapitalize="off"/>
													</td>
												</tr>
												<tr>
													<th>服务器添加</th>
                                        			<td>
                                        			    <select id="ss_lb_node" name="ss_lb_node" style="width:130px;margin:0px 0px 0px 2px;" class="input_option" >
                                        			    </select>
                                        			    &nbsp;&nbsp;&nbsp;&nbsp;
                                        			    权重:
														<input type="text" class="input_ss_table" style="width:30px" id="ss_lb_weight" name="ss_lb_weight" maxlength="100" value="50"/>
                                        			    &nbsp;&nbsp;&nbsp;&nbsp;
														属性:
														<select id="ss_lb_mode" name="ss_lb_mode" style="width:90px;margin:0px 0px 0px 2px;" class="input_option" onchange="update_visibility();">
															<option value="1" selected>负载均衡</option>
															<option value="2">主用节点</option>
															<option value="3">备用节点</option>
														</select>
														
                                        			    <input style="float:left;margin-top:-28px;margin-left:370px;" type="button" class="add_btn" onclick="addTr()" value=""/>
                                        			</td>
												</tr>
                                    		</table>
										</div>
										<div id="lb_list" style="margin:20px 0px 0px 0px;">
											<table id="lb_node_table" style="margin:-1px 0px 0px 0px;" width="750px" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable_table">
												<tr height="40px">
													<th width="20%">服务器别名</th>
													<th width="15%">服务器</th>
													<th width="15%">服务器端口</th>
													<th width="11%">密码</th>
													<th width="15%">加密方式</th>
													<th width="11%">属性</th>
													<th width="5%">权重</th>
													<th width="8%">删除</th>
												</tr>
											</table>
										</div>
                                    	<div id="log_content" style="margin-top:10px;display: none;">
											<textarea cols="63" rows="21" wrap="off" readonly="readonly" id="log_content1" style="width:99%; font-family:'Lucida Console'; font-size:11px;background:#475A5F;color:#FFFFFF;"></textarea>
										</div>
                                    	
										<div class="apply_gen">
											<input id="cmdBtn" class="button_gen" type="button" onclick="save()" value="提交">
										</div>
									</td>
								</tr>
							</table>
						</td>
						<td width="10" align="center" valign="top"></td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
	</td>
	<div id="footer"></div>
</body>
</html>



