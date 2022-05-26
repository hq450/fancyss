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
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/dbconf?p=ss&v=<% uptime(); %>"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<style>
    .cloud_main_radius h2 { border-bottom:1px #AAA dashed;}
	.cloud_main_radius h3 { font-size:12px;color:#FFF;font-weight:normal;font-style: normal;}
	.cloud_main_radius h4 { font-size:12px;color:#FC0;font-weight:normal;font-style: normal;}
	.cloud_main_radius h5 { color:#FFF;font-weight:normal;font-style: normal;}
</style>

<script>
var socks5 = 0
var Base64;
if(typeof btoa == "Function") {
   Base64 = {encode:function(e){ return btoa(e); }, decode:function(e){ return atob(e);}};
} else {
   Base64 ={_keyStr:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",encode:function(e){var t="";var n,r,i,s,o,u,a;var f=0;e=Base64._utf8_encode(e);while(f<e.length){n=e.charCodeAt(f++);r=e.charCodeAt(f++);i=e.charCodeAt(f++);s=n>>2;o=(n&3)<<4|r>>4;u=(r&15)<<2|i>>6;a=i&63;if(isNaN(r)){u=a=64}else if(isNaN(i)){a=64}t=t+this._keyStr.charAt(s)+this._keyStr.charAt(o)+this._keyStr.charAt(u)+this._keyStr.charAt(a)}return t},decode:function(e){var t="";var n,r,i;var s,o,u,a;var f=0;e=e.replace(/[^A-Za-z0-9\+\/\=]/g,"");while(f<e.length){s=this._keyStr.indexOf(e.charAt(f++));o=this._keyStr.indexOf(e.charAt(f++));u=this._keyStr.indexOf(e.charAt(f++));a=this._keyStr.indexOf(e.charAt(f++));n=s<<2|o>>4;r=(o&15)<<4|u>>2;i=(u&3)<<6|a;t=t+String.fromCharCode(n);if(u!=64){t=t+String.fromCharCode(r)}if(a!=64){t=t+String.fromCharCode(i)}}t=Base64._utf8_decode(t);return t},_utf8_encode:function(e){e=e.replace(/\r\n/g,"\n");var t="";for(var n=0;n<e.length;n++){var r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r)}else if(r>127&&r<2048){t+=String.fromCharCode(r>>6|192);t+=String.fromCharCode(r&63|128)}else{t+=String.fromCharCode(r>>12|224);t+=String.fromCharCode(r>>6&63|128);t+=String.fromCharCode(r&63|128)}}return t},_utf8_decode:function(e){var t="";var n=0;var r=c1=c2=0;while(n<e.length){r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r);n++}else if(r>191&&r<224){c2=e.charCodeAt(n+1);t+=String.fromCharCode((r&31)<<6|c2&63);n+=2}else{c2=e.charCodeAt(n+1);c3=e.charCodeAt(n+2);t+=String.fromCharCode((r&15)<<12|(c2&63)<<6|c3&63);n+=3}}return t}}
}
String.prototype.replaceAll = function(s1,s2){
　　return this.replace(new RegExp(s1,"gm"),s2);
}
function init() {
	show_menu(menu_hook);
	buildswitch();
	conf2obj();
	//delTr_onstart();
    var rrt = document.getElementById("switch");
    if (document.form.ss_lb_enable.value != "1") {
        rrt.checked = false;
    } else {
        rrt.checked = true;
    }
    loadAllConfigs();
    refresh_table();
    load_lb_node_nu();
    generate_link();
    update_visibility();
}

function buildswitch(){
	$j("#switch").click(
	function(){
		if(document.getElementById('switch').checked){
			document.form.ss_lb_enable.value = 1;
			
		}else{
			document.form.ss_lb_enable.value = 0;
		}
	});
}

function onSubmitCtrl(o, s) {

		lb_enable = $G("ss_lb_enable").value;
		if (lb_enable == 0){
			del_lb_node();
		}else if (lb_enable == 1){
	    	if (lb_node_nu < 2){
    			alert("必须选择大于或者等于2个节点，才能正常提交！");
    			return false;
   	 		}
			add_new_lb_node();
		}
		document.form.action_mode.value = s;
		document.form.SystemCmd.value = "ss_lb_config.sh";
		document.form.ss_basic_action.value = 9;
		document.form.submit();
		showSSLoadingBar();
    	noChange2 = 0;
    	setTimeout("checkCmdRet2();", 500);
}

function conf2obj(){ //用dbus值填写表单
    for (var field in db_ss) {
        $j('#'+field).val(db_ss[field]);
    }
}

function getAllConfigs() { //取得所有ss节点数据，并且格式化成数组
    var dic = {};
    node_global_max = 0;
    for (var field in db_ss) {
        names = field.split("_");
        dic[names[names.length - 1]] = 'ok';
    }
    confs = {};
    var p = "ssconf_basic";
    var params = ["name", "server", "port", "password", "method"];
    for (var field in dic) {
        var obj = {};
        if (typeof db_ss[p + "_name_" + field] == "undefined") {
            obj["name"] = '节点' + field;
        } else {
            obj["name"] = db_ss[p + "_name_" + field];
        }
        
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
	        if (time_total == 0.00){
		        obj["webtest"] = '<font color=#FFCC00">failed</font>';
	        }else{
		         obj["webtest"] = parseFloat(db_ss[p + "_webtest_" + field].split(":")[0]).toFixed(2) + " s";
	        }
        }
        
		if (typeof db_ss[p + "_mode_" + field] == "undefined"){
			obj["mode"] = '';
		}else {
            obj["mode"] = db_ss[p + "_mode_" + field];
        }

        if (typeof db_ss[p + "_onetime_auth_" + field] == "undefined"){
			obj["onetime_auth"] = '';
		}else {
            obj["onetime_auth"] = db_ss[p + "_onetime_auth_" + field];
        }
        if (typeof db_ss[p + "_use_rss_" + field] == "undefined"){
			obj["use_rss"] = '';
		}else {
            obj["use_rss"] = db_ss[p + "_use_rss_" + field];
        }

        if (typeof db_ss[p + "_use_lb_" + field] == "undefined"){
			obj["use_lb"] = '0';
		}else {
            obj["use_lb"] = db_ss[p + "_use_lb_" + field];
        }
        if (typeof db_ss[p + "_iflb_" + field] == "undefined"){
			obj["iflb"] = '0';
		}else {
            obj["iflb"] = db_ss[p + "_iflb_" + field];
        }

        if (typeof db_ss[p + "_weight_" + field] == "undefined"){
			obj["weight"] = '';
		}else {
            obj["weight"] = db_ss[p + "_weight_" + field];
        }
        if (typeof db_ss[p + "_lbmode_" + field] == "undefined"){
			obj["lbmode"] = '';
		}else {
            obj["lbmode"] = db_ss[p + "_lbmode_" + field];
        }
        if (typeof db_ss[p + "_rss_protocol_" + field] == "undefined"){
			obj["rss_protocol"] = '';
		}else {
            obj["rss_protocol"] = db_ss[p + "_rss_protocol_" + field];
        }
        
        if (typeof db_ss[p + "_rss_obfs_" + field] == "undefined"){
			obj["rss_obfs"] = '';
		}else {
            obj["rss_obfs"] = db_ss[p + "_rss_obfs_" + field];
        }
        
        if (typeof db_ss[p + "_rss_obfs_param_" + field] == "undefined"){
			obj["rss_obfs_param"] = '';
		}else {
            obj["rss_obfs_param"] = db_ss[p + "_rss_obfs_param_" + field];
        }

        for (var i = 1; i < params.length; i++) {
            var ofield = p + "_" + params[i] + "_" + field;
            if (typeof db_ss[ofield] == "undefined") {
                obj = null;
                break;
            }
            obj[params[i]] = db_ss[ofield];
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
    return confs;    
}

function load_lb_node_nu(){
	lb_node_nu = 0;
	confs = getAllConfigs();
	for (var field in confs) {
		var c = confs[field];
		if (c["use_lb"] == "1"){
			lb_node_nu ++;
		}
	}
}

function loadBasicOptions(confs) { //载入节点选择列表
    var option = $j("#ss_lb_node");
    option.find('option').remove().end();
    for (var field in confs) {
        var c = confs[field];
		if (c["use_lb"] != 1 && c["server"] !== "127.0.0.1"){ //节点选择列表中显示所有的非负载均衡节点，并且不显示负载均衡节点本身
        option.append($j("<option>", {
            value: field,
            text: c.name
        }));
		}
    }
}

function add_new_lb_node(){ //点击添加按钮后，
	confs = getAllConfigs();
	cur_lb_node=node_global_max + 1;
	for (var field in confs) {
		var c = confs[field];
		
		if (c["server"] == "127.0.0.1" && c["port"] == db_ss['ss_lb_port']){
			//alert("你的节点列表里已经有负载均衡的节点，请删除后再添加");
			cur_lb_node=field;
		}
		if (confs[field].use_lb == 1){
			min_lb_node=field;
		}
	}
    var ns = {};
	ns["ssconf_basic_name_" + cur_lb_node] = $G("ss_lb_name").value;
	ns["ssconf_basic_server_" + cur_lb_node] = "127.0.0.1";
	ns["ssconf_basic_mode_" + cur_lb_node] = db_ss['ssconf_basic_mode_' + min_lb_node];
	ns["ssconf_basic_port_" + cur_lb_node] = $G("ss_lb_port").value;
	ns["ssconf_basic_password_" + cur_lb_node] = db_ss['ssconf_basic_password_' + min_lb_node];
	ns["ssconf_basic_method_" + cur_lb_node] = db_ss['ssconf_basic_method_' + min_lb_node];
	ns["ssconf_basic_onetime_auth_" + cur_lb_node] = db_ss['ssconf_basic_onetime_auth_' + min_lb_node];
	ns["ssconf_basic_rss_protocol_" + cur_lb_node] = db_ss['ssconf_basic_rss_protocol_' + min_lb_node];
	ns["ssconf_basic_rss_obfs_" + cur_lb_node] = db_ss['ssconf_basic_rss_obfs_' + min_lb_node];
	ns["ssconf_basic_rss_obfs_param_" + cur_lb_node] = db_ss['ssconf_basic_rss_obfs_param_' + min_lb_node];
	ns["ssconf_basic_use_rss_" + cur_lb_node] = db_ss['ssconf_basic_use_rss_' + min_lb_node];
	//ns["ssconf_basic_iflb_" + cur_lb_node] = "1";
    $j.ajax({
        url: '/applydb.cgi?p=ssconf_basic',
        contentType: "application/x-www-form-urlencoded",
        dataType: 'text',
        data: $j.param(ns),
        error: function(xhr) {
            console.log("error in posting config of table");
        },
        success: function(response) {
            console.log("success in posting config of table");
        }
    });
}

function del_lb_node(o) { //删除节点功能
	confs = getAllConfigs();
	cur_lb_node=node_global_max + 1;
	for (var field in confs) {
		var c = confs[field];
		
		if (c["server"] == "127.0.0.1" && c["port"] == db_ss['ss_lb_port']){
			cur_lb_node=field;
		}
	}

    var ns = {};
	ns["ssconf_basic_name_" + cur_lb_node] = "";
	ns["ssconf_basic_server_" + cur_lb_node] = "";
	ns["ssconf_basic_mode_" + cur_lb_node] = "";
	ns["ssconf_basic_port_" + cur_lb_node] = "";
	ns["ssconf_basic_password_" + cur_lb_node] = "";
	ns["ssconf_basic_method_" + cur_lb_node] = "";
	ns["ssconf_basic_onetime_auth_" + cur_lb_node] = "";
	ns["ssconf_basic_rss_protocol_" + cur_lb_node] = "";
	ns["ssconf_basic_rss_obfs_" + cur_lb_node] = "";
	ns["ssconf_basic_rss_obfs_param_" + cur_lb_node] = "";
	ns["ssconf_basic_use_rss_" + cur_lb_node] = "";
	//ns["ssconf_basic_iflb_" + cur_lb_node] = "";
    $j.ajax({
        url: '/applydb.cgi?use_rm=1&p=ssconf_basic',
        contentType: "application/x-www-form-urlencoded",
        dataType: 'text',
        data: $j.param(ns),
        error: function(xhr) {
            console.log("error in posting config of table");
        },
        success: function(response) {
            console.log("success in posting config of table");
        }
    });
}

function addTr(){ //点击添加按钮动作
	lb_node_nu ++;
    var ns = {};
	var node_sel = $G("ss_lb_node").value;
	ns["ssconf_basic_use_lb_" + node_sel] = 1;
	ns["ssconf_basic_weight_" + node_sel] = $G("ss_lb_weight").value;
	ns["ssconf_basic_lbmode_" + node_sel] = $G("ss_lb_mode").value;
    $j.ajax({
        url: '/applydb.cgi?p=ssconf_basic',
        contentType: "application/x-www-form-urlencoded",
        dataType: 'text',
        data: $j.param(ns),
        error: function(xhr) {
            console.log("error in posting config of table");
        },
        success: function(response) {
            refresh_table();
            loadAllConfigs();
            $j("#ss_lb_node option[value='" + node_sel + "']").remove();
            
        }
    });
}

function delTr(o) { //删除节点功能
	lb_node_nu --;
    var id = $j(o).attr("id");
    var ids = id.split("_");
    var p = "ssconf_basic";
    id = ids[ids.length - 1];
    var ns = {};
	ns["ssconf_basic_use_lb_" + id] = "";
	ns["ssconf_basic_weight_" + id] = "";
	ns["ssconf_basic_lbmode_" + id] = "";
    $j.ajax({
        url: '/applydb.cgi?use_rm=1&p=ssconf_basic',
        contentType: "application/x-www-form-urlencoded",
        dataType: 'text',
        data: $j.param(ns),
        error: function(xhr) {
            console.log("error in posting config of table");
        },
        success: function(response) {
            refresh_table();
            loadAllConfigs();
        }
    });
}


function delTr_onstart() { //删除节点功能
	confs = getAllConfigs();
	for (var field in confs) {
		var c = confs[field];
		if (c["server"] == "127.0.0.1" && c["port"] == db_ss['ss_lb_port']){
			//alert("你的节点列表里已经有负载均衡的节点，请删除后再添加");
			console.log("lb_node already in table");
			return true;
		}
	}

	var ns = {};
	for (var i = 1; i < node_global_max; i++) {
		ns["ssconf_basic_use_lb_" + i] = "";
	}
	
    $j.ajax({
        url: '/applydb.cgi?use_rm=1&p=ssconf_basic',
        contentType: "application/x-www-form-urlencoded",
        dataType: 'text',
        data: $j.param(ns),
        error: function(xhr) {
            console.log("error in posting config of table");
        },
        success: function(response) {
            refresh_table();
            loadAllConfigs();
        }
    });
}

function refresh_table() {
	$j.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr){
		},
		success: function(response){
			$j.globalEval(response);
			$j("#lb_node_table").find("tr:gt(0)").remove();
			$j('#lb_node_table tr:last').after(refresh_html());
		}
	});
}

function refresh_html() {
	confs = getAllConfigs();
	var html = '';
    for (var field in confs) {
        var c = confs[field];
		if(c["use_lb"] == 1){
    		html = html + '<tr>';
    		html = html + '<td id="ss_node_name_' + c["node"] + '" style="width:85px;">' + c["name"] + '</td>';
    		html = html + '<td id="ss_node_server_' + c["node"] + '" style="width:85px;">' + c["server"] + '</td>';
    		html = html + '<td id="ss_node_port_' + c["node"] + '" style="width:37px;">' + c["port"] + '</td>';
    		html = html + '<td id="ss_node_password_' + c["node"] + '" style="width:75px;">' + Base64.decode(c["password"]) + '</td>';
    		html = html + '<td id="ss_node_method_' + c["node"] + '" style="width:75px;">' + c["method"] + '</td>';
			if(c["lbmode"] == 3){
    			html = html + '<td id="ss_node_mode_' + c["node"] + '" style="width:75px;">备用节点</td>';
			}else if(c["lbmode"] == 2){
    			html = html + '<td id="ss_node_mode_' + c["node"] + '" style="width:75px;">主用节点</td>';
			}else if(c["lbmode"] == 1){
    			html = html + '<td id="ss_node_mode_' + c["node"] + '" style="width:75px;">负载均衡</td>';
			}
    		html = html + '<td id="ss_node_weight_' + c["node"] + '" style="width:75px;">' + c["weight"] + '</td>';
    		html = html + '<td style="width:33px;">'
    		html = html + '<input style="margin-top: 4px;margin-left:-3px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
    		html = html + '</td>';
    		html = html + '</tr>';
		}
    }
    return html;
}

function loadAllConfigs() {
    confs = getAllConfigs();
    loadBasicOptions(confs);
}

function reload_Soft_Center(){
location.href = "/Main_Soft_center.asp";
}

function generate_link(){
	var link = window.btoa("http://"+'<% nvram_get("lan_ipaddr"); %>'+":1188")
	document.getElementById("link4.1").href = "http://"+'<% nvram_get("lan_ipaddr"); %>'+":1188";
	document.getElementById("link4.1").innerHTML = "<i><u>http://"+'<% nvram_get("lan_ipaddr"); %>'+":1188</i></u>";
}

function update_visibility(){
	showhide("heartbeat_detai", (document.form.ss_lb_heartbeat.value == "1"));
}
var _responseLen;
var noChange2 = 0;
function checkCmdRet2(){
	$j.ajax({
		url: '/cmdRet_check.htm',
		dataType: 'html',
		error: function(xhr){
			setTimeout("checkCmdRe2t();", 1000);
			},
		success: function(response){
			var retArea = $G("log_content3");
			if(response.search("XU6J03M6") != -1){
				retArea.value = response.replace("XU6J03M6", " ");
				$G("ok_button").style.display = "";
				retArea.scrollTop = retArea.scrollHeight;
				x = 6;
				count_down_close();
				return true;
			}else{
				$G("ok_button").style.display = "none";
			}
			
			if(_responseLen == response.length){
				noChange2++;
			}else{
				noChange2 = 0;
			}

			if(noChange2 > 12){
				return false;
			}else{
				setTimeout("checkCmdRet2();", 1000);
			}
			retArea.value = response;
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		}
	});
}

var x = 6;
function count_down_close(){
	if (x == "0"){
		hideSSLoadingBar();
	}
	if (x < 0){
		$G("ok_button1").value = "手动关闭"
		return false;
	}
	$G("ok_button1").value = "自动关闭（" + x + "）"
	--x;
	setTimeout("count_down_close();",1000);
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
			<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;">
			<textarea cols="63" rows="25" wrap="off" readonly="readonly" id="log_content3" style="border:1px solid #000;width:99%; font-family:'Courier New', Courier, mono; font-size:11px;background:#000;color:#FFFFFF;"></textarea>
			</div>
			<div id="ok_button" class="apply_gen" style="background: #000;display: none;">
				<input id="ok_button1" class="button_gen" type="button" onclick="hideSSLoadingBar()" value="确定">
			</div>
			</td>
		</tr>
	</table>
	</div>
	<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
	<form method="POST" name="form" action="/applydb.cgi?p=ss" target="hidden_frame">
	<input type="hidden" name="current_page" value="Main_Ss_LoadBlance.asp"/>
	<input type="hidden" name="next_page" value="Main_Ss_LoadBlance.asp"/>
	<input type="hidden" name="group_id" value=""/>
	<input type="hidden" name="modified" value="0"/>
	<input type="hidden" name="action_mode" value=""/>
	<input type="hidden" name="action_script" value=""/>
	<input type="hidden" name="action_wait" value=""/>
	<input type="hidden" name="first_time" value=""/>
	<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>"/>
	<input type="hidden" id="ss_basic_action" name="ss_basic_action" value="9" />
	<input type="hidden" name="SystemCmd" onkeydown="onSubmitCtrl(this, ' Refresh ')" value="ss_config.sh"/>
	<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>"/>
	<input type="hidden" id="ss_lb_enable" name="ss_lb_enable" value='<% dbus_get_def("ss_lb_enable", "0"); %>'/>
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
										<table width="100%" height="150px" style="border-collapse:collapse;">
                                            <tr >
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
                                                                            <h3 id="push_content2"><font color="#FFCC00">注意：设置负载均衡的节点需要加密方式和密码完全一致！SS、SSR、KCP之间暂不支持设置负载均衡。</font></h3>
                                                                        </li>
                                                                        <li id="push_content3_li" style="margin-top:-5px;">
                                                                            <h3 id="push_content3">提交设置后会开启haproxy，并在ss节点配置中增加一个服务器IP为127.0.0.1，端口为负载均衡服务器端口的帐号；</h3>
                                                                        </li>
                                                                        <li id="push_content4_li" style="margin-top:-5px;">
                                                                            <h3 id="push_content4">负载均衡模式下不支持udp转发：不能使用ss-tunnel作为国外dns方案。</h3>
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
										<table style="margin:-20px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="routing_table">
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
														<label for="switch">
															<input id="switch" class="switch" type="checkbox" style="display: none;">
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
												  	<input type="password" maxlength="64" id="ss_lb_passwd" name="ss_lb_passwd" value="<% nvram_get("http_passwd"); %>" class="input_ss_table" style="width:80px;" autocorrect="off" autocapitalize="off"></input>
													<div style="margin-left:420px;margin-top:-21px;margin-bottom:2px"><input type="checkbox" name="show_pass" onclick="pass_checked(document.form.ss_lb_passwd);">
                                			      </div>
                                			    </td>
                                			</tr>
											<tr>
												<th>Haproxy端口(用于ss监听)</th>
												<td>
												  	<input type="text" maxlength="64" id="ss_lb_port" name="ss_lb_port" value="1181" class="input_ss_table" style="width:60px;" autocorrect="off" autocapitalize="off"></input>
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
												  	<input type="text" maxlength="64" id="ss_lb_up" name="ss_lb_up" value="2" class="input_ss_table" style="width:20px;" autocorrect="off" autocapitalize="off"></input>
													次;
													&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
													失败:
												  	<input type="text" maxlength="64" id="ss_lb_down" name="ss_lb_down" value="3" class="input_ss_table" style="width:20px;" autocorrect="off" autocapitalize="off"></input>
													次;
													&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
													心跳间隔:
												  	<input type="text" maxlength="64" id="ss_lb_interval" name="ss_lb_interval" value="2000" class="input_ss_table" style="width:40px;" autocorrect="off" autocapitalize="off"></input>
													ms
													</span>
												</td>
											</tr>
											<tr>
												<th>节点名（添加到ss节点列表）</th>
												<td>
												  	<input type="text" maxlength="64" id="ss_lb_name" name="ss_lb_name" value="负载均衡" class="input_ss_table" style="width:80px;" autocorrect="off" autocapitalize="off"></input>
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

										<table style="margin:10px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="lb_node_table">
											<tr>
												<th style="width:70px;">服务器别名</th>
												<th style="width:90px;">服务器</th>
												<th style="width:90px;">服务器端口</th>
												<th style="width:90px;">密码</th>
												<th style="width:90px;">加密方式</th>
												<th style="width:35px;">属性</th>
												<th style="width:35px;">权重</th>
												<th style="width:35px;">删除</th>
											</tr>
										</table>
                                    	<div id="log_content" style="margin-top:10px;display: none;">
											<textarea cols="63" rows="21" wrap="off" readonly="readonly" id="log_content1" style="width:99%; font-family:'Courier New', Courier, mono; font-size:11px;background:#475A5F;color:#FFFFFF;"></textarea>
										</div>
                                    	
										<div class="apply_gen">
											<input id="cmdBtn" class="button_gen" type="button" onclick="onSubmitCtrl(this, ' Refresh ')" value="提交">
										</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>

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
	</form>
	</td>
	<div id="footer"></div>
</body>
</html>



