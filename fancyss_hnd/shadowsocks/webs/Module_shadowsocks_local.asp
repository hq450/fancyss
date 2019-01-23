<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Shadowsocks - Socks5代理设置</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script>
var x = 5;
var noChange = 0;
var _responseLen;
var params = ["ss_local_server", "ss_local_port", "ss_local_password", "ss_local_method", "ss_local_timeout", "ss_local_proxyport", "ss_local_obfs", "ss_local_acl"];

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
			conf2obj();
    		update_visibility();
		}
	});
}

function conf2obj(){
	E("ss_local_enable").checked = db_ss["ss_local_enable"] == "1";
	for (var i = 0; i < params.length; i++) {
		if(db_ss[params[i]]){
			E(params[i]).value = db_ss[params[i]];
		}
	}
}

function save() {
	var dbus = {};
	//checkbox
	dbus["ss_local_enable"] = E("ss_local_enable").checked ? '1' : '0';;
	//input
	for (var i = 0; i < params.length; i++) {
		if (E(params[i])) {
			dbus[params[i]] = E(params[i]).value;
		}
	}
	db_ss["ss_basic_action"] = 14;
	push_data("ss_socks5.sh", "start",  dbus);
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

function update_visibility(){
	showhide("ss_obfs_host", (E("ss_local_obfs").value !== "0" ));
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
	<input type="hidden" name="current_page" value="Module_shadowsocks_local.asp">
	<input type="hidden" name="next_page" value="Module_shadowsocks_local.asp">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="modified" value="0">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="action_wait" value="8">
	<input type="hidden" name="first_time" value="">
	<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
	<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top"><div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top"><div>&nbsp;</div>
										<div class="formfonttitle"><% nvram_get("productid"); %> 科学上网插件 - Socks5代理设置</div>
										<div style="float:right; width:15px; height:25px;margin-top:-20px">
											<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
										</div>
										<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
										<div class="SimpleNote">
											<li><i>说明：</i>此页面允许配置第二个shadosocks账号，功能仅限于在路由器上打开一个连接到shadowsocks服务器的socks5端口。如果你使用chrome浏览器，你可以使用SwitchyOmega插件去连接这个socks5代理。</li>
										</div>
										<div id="local_table" style="margin:5px 0px 0px 0px;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">Shadowsocks - ss-local - 高级设置</td>
													</tr>
												</thead>
                                        		<tr id="switch_tr">
                                        		    <th>
                                        		        <label>开关</label>
                                        		    </th>
                                        		    <td colspan="2">
                                        		        <div class="switch_field" style="display:table-cell;float: left;">
                                        		            <label for="ss_local_enable">
                                        		                <input id="ss_local_enable" class="switch" type="checkbox" style="display: none;">
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
													<th width="20%">服务器(建议填写IP地址)</th>
													<td>
														<input type="text" class="input_ss_table" id="ss_local_server" name="ss_local_server" maxlength="100" value="">
													</td>
												</tr>
												<tr>
													<th width="20%">服务器端口</th>
													<td>
														<input type="text" class="input_ss_table" id="ss_local_port" name="ss_local_port" maxlength="100" value="">
													</td>
												</tr>
												<tr>
													<th width="20%">密码</th>
														<td>
															<input type="password" name="ss_local_password" id="ss_local_password" class="input_ss_table" autocomplete="off" autocorrect="off" autocapitalize="off" maxlength="100" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr>
													<th width="20%">加密方法</th>
													<td>
														<select id="ss_local_method" name="ss_local_method" style="width:165px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="rc4-md5">rc4-md5</option>
															<option value="aes-128-gcm">aes-128-gcm</option>
															<option value="aes-192-gcm">aes-192-gcm</option>
															<option value="aes-256-gcm">aes-256-gcm</option>
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
															<option value="salsa20">salsa20</option>
															<option value="chacha20">chacha20</option>
															<option value="chacha20-poly1305">chacha20-poly1305</option>
															<option value="chacha20-ietf">chacha20-ietf</option>
															<option value="chacha20-ietf-poly1305">chacha20-ietf-poly1305</option>
														</select>
													</td>
												</tr>
												<tr>
													<th width="20%">超时时间</th>
													<td>
														<input type="text" class="input_ss_table" id="ss_local_timeout" name="ss_local_timeout" maxlength="100" value="600">
													</td>
												</tr>
												<tr>
													<th width="20%">本地代理端口</th>
													<td>
														<input type="text" class="input_ss_table" id="ss_local_proxyport" name="ss_local_proxyport" maxlength="100" value="1082">												
													</td>
												</tr>
												<tr id="ss_obfs">
													<th width="35%">混淆 (obfs)</th>
													<td>
														<select id="ss_local_obfs" name="ss_local_obfs" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="update_visibility();" >
															<option class="content_input_fd" value="0">关闭</option>
															<option class="content_input_fd" value="tls">tls</option>
															<option class="content_input_fd" value="http">http</option>
														</select>
													</td>
												</tr>
												<tr id="ss_obfs_host">
													<th width="35%">混淆主机名 (obfs_host)</th>
													<td>
														<input type="text" name="ss_local_obfs_host" id="ss_local_obfs_host" placeholder="bing.com"  class="input_ss_table" maxlength="100" value=""></input>
													</td>
												</tr>
												<tr id="acl_support">
													<th>ACL控制</th>
													<td>
														<select name="ss_local_acl" id="ss_local_acl" class="input_option" style="width:165px;margin:0px 0px 0px 2px;">
															<option value="0" selected>不使用</option>
															<option value="1">gfwlist.pac</option>
															<option value="2">chn.pac</option>
														</select>
													</td>
												</tr>
											</table>
										</div>
										<div id="warning" style="font-size:14px;margin:20px auto;"></div>
										<div class="apply_gen">
											<input class="button_gen" id="cmdBtn" onClick="save()" type="button" value="提交" />
										</div>
									</td>
								</tr>
							</table>
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

