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
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/dbconf?p=ss&v=<% uptime(); %>"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<style>
.Bar_container{
width:85%;
height:20px;
border:1px inset #999;
margin:0 auto;
margin-top:20px \9;
background-color:#FFFFFF;
z-index:100;
}
#proceeding_img_text{
position:absolute;
z-index:101;
font-size:11px; color:#000000;
line-height:21px;
width: 83%;
}
#proceeding_img{
height:21px;
background:#C0D1D3 url(/images/ss_proceding.gif);
}
#ClientList_Block_PC {
border: 1px outset #999;
background-color: #576D73;
position: absolute;
*margin-top:26px;
margin-left: 3px;
*margin-left:-129px;
width: 255px;
text-align: left;
height: auto;
overflow-y: auto;
z-index: 200;
padding: 1px;
display: none;
}
#ClientList_Block_PC div {
background-color: #576D73;
height: auto;
*height:20px;
line-height: 20px;
text-decoration: none;
font-family: Lucida Console;
padding-left: 2px;
}
#ClientList_Block_PC a {
background-color: #EFEFEF;
color: #FFF;
font-size: 12px;
font-family: Arial, Helvetica, sans-serif;
text-decoration: none;
}
#ClientList_Block_PC div:hover, #ClientList_Block a:hover {
background-color: #3366FF;
color: #FFFFFF;
cursor: default;
}
</style>
<script>
var socks5 = 1
var $j = jQuery.noConflict();
var $G = function (id) {
return document.getElementById(id);
};

function init(){
	show_menu(menu_hook);
	conf_to_obj();
    buildswitch();
    toggle_switch();
    update_visibility();
}

function toggle_switch(){
    var rrt = document.getElementById("switch");
    if (document.form.ss_local_enable.value != "1") {
        rrt.checked = false;
    } else {
        rrt.checked = true;
    }
}

function buildswitch(){
    $j("#switch").click(
    function(){
        if(document.getElementById('switch').checked){
            document.form.ss_local_enable.value = 1;
            
        }else{
            document.form.ss_local_enable.value = 0;
        }
    });
}

function conf_to_obj(){
	if(typeof db_ss != "undefined") {
		for(var field in db_ss) {
			var el = document.getElementById(field);
			if(el != null) {
				el.value = db_ss[field];
			}
		}
	} else {
		document.getElementById("logArea").innerHTML = "无法读取配置,jffs为空或配置文件不存在?";
		return;
	}
}

function onSubmitCtrl(o, s) {
	if(validForm()){
		showSSLoadingBar(5);
		document.form.action_mode.value = s;
		updateOptions();
	}
}

function done_validating(action){
	return true;
}

function updateOptions(){
	document.form.enctype = "";
	document.form.encoding = "";
	document.form.action = "/applydb.cgi?p=ss_local_";
	document.form.SystemCmd.value = "ss_socks5.sh";
	document.form.submit();
}

function validForm(){
	var is_ok = true;
	return is_ok;
}

function update_visibility(){
	showhide("ss_obfs_host", (document.form.ss_local_obfs.value !== "0" ));
}

</script>
</head>
<body onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg">
		<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
			<tr>
				<td height="100">
					<div id="loading_block3" style="margin:10px auto;width:85%; font-size:12pt;"></div>
					<div id="loading_block1" class="Bar_container">
						<span id="proceeding_img_text"></span>
						<div id="proceeding_img"></div>
					</div>
					<div id="loading_block2" style="margin:10px auto; width:85%;">此期间请勿访问屏蔽网址，以免污染DNS进入缓存</div>
				</td>
			</tr>
		</table>
	</div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/applyss.cgi" target="hidden_frame">
	<input type="hidden" name="current_page" value="Main_SsLocal_Content.asp">
	<input type="hidden" name="next_page" value="Main_SsLocal_Content.asp">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="modified" value="0">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="action_wait" value="8">
	<input type="hidden" name="first_time" value="">
	<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
	<input type="hidden" name="SystemCmd" onkeydown="onSubmitCtrl(this, ' Refresh ')" value="">
	<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
	<input type="hidden" id="ss_local_enable" name="ss_local_enable" value='<% dbus_get_def("ss_local_enable", "0"); %>'/>
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
										<div class="formfonttitle">Shadowsocks - Socks5代理设置</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
										<div class="SimpleNote">
											<li><i>说明：</i>此页面允许配置第二个shadosocks账号，功能仅限于在路由器上打开一个连接到shadowsocks服务器的socks5端口。如果你使用chrome浏览器，你可以使用SwitchyOmega插件去连接这个socks5代理。</li></br>
											<li><i>此页面功能独立于ss，单独开关：</i></li>
										</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
										<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
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
												<th width="20%">服务器(建议填写IP地址)</th>
												<td>
													<input style="background-image: none;background-color: #576d73;border:1px solid gray" type="text" class="ssconfig input_ss_table" id="ss_local_server" name="ss_local_server" maxlength="100" value="">
												</td>
											</tr>
											<tr>
												<th width="20%">服务器端口</th>
												<td>
													<input type="text" class="ssconfig input_ss_table" id="ss_local_port" name="ss_local_port" maxlength="100" value="">
												</td>
											</tr>
											<tr>
												<th width="20%">密码</th>
													<td>
														<input type="password" class="ssconfig input_ss_table" id="ss_local_password" name="ss_local_password" maxlength="100" value="" onBlur="switchType(this, false);" onFocus="switchType(this, true);">
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
													<input type="text" class="ssconfig input_ss_table" id="ss_local_timeout" name="ss_local_timeout" maxlength="100" value="600">
												</td>
											</tr>
											<tr>
												<th width="20%">本地代理端口</th>
												<td>
													<input type="text" class="ssconfig input_ss_table" id="ss_local_proxyport" name="ss_local_proxyport" maxlength="100" value="1082">												
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
													<input type="text" name="ss_local_obfs_host" id="ss_local_obfs_host" placeholder="bing.com"  class="ssconfig input_ss_table" maxlength="100" value=""></input>
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
										<div id="warning" style="font-size:14px;margin:20px auto;"></div>
										<div class="apply_gen">
											<input class="button_gen" id="cmdBtn" onClick="onSubmitCtrl(this, ' Refresh ')" type="button" value="提交" />
										</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
										<div class="KoolshareBottom">论坛技术支持： <a href="http://www.koolshare.cn" target="_blank"> <i><u>www.koolshare.cn</u></i> </a> <br/>
										博客技术支持： <a href="http://www.mjy211.com" target="_blank"> <i><u>www.mjy211.com</u></i> </a> <br/>
										Github项目： <a href="https://github.com/koolshare/koolshare.github.io" target="_blank"> <i><u>github.com/koolshare</u></i> </a> <br/>
										Shell by： <a href="mailto:sadoneli@gmail.com"> <i>sadoneli</i> </a>, Web by： <i>Xiaobao</i> </div>
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
</form>
<div id="footer"></div>
</body>
<script type="text/javascript">
<!--[if !IE]>-->
jQuery.noConflict();
(function($){
var i = 0;
})(jQuery);
<!--<![endif]-->
</script>
</html>

