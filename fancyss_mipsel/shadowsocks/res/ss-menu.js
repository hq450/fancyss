
function browser_compatibility1(){
	//fw versiom
	var _fw="<% nvram_get("extendno"); %>";
	fw_version=parseFloat(_fw.split("X")[1]);
	// chrome
	var isChrome = navigator.userAgent.search("Chrome") > -1;
	if(isChrome){
		var major = navigator.userAgent.match("Chrome\/([0-9]*)\.");    //check for major version
		var isChrome56 = (parseInt(major[1], 10) >= 56);
	} else {
		var isChrome56 = false;
	}
	if((isChrome56) && document.getElementById("FormTitle") && fw_version < 7.5){
		document.getElementById("FormTitle").className = "FormTitle_chrome56";
		//console.log("fw_version", fw_version);
	}else if((isChrome56) && document.getElementById("FormTitle") && fw_version >= 7.5){
		document.getElementById("FormTitle").className = "FormTitle";
		//console.log("chrome", fw_version);
	}
	//firefox
	var isFirefox = navigator.userAgent.search("Firefox") > -1;
	if((isFirefox) && document.getElementById("FormTitle") && fw_version < 7.5){
		document.getElementById("FormTitle").className = "FormTitle_firefox";
		if(current_url.indexOf("Main_Ss_Content.asp") == 0){
			document.getElementById("FormTitle").style.marginTop = "-100px"
			//console.log("firefox -100");
		}

	}else if((isFirefox) && document.getElementById("FormTitle") && fw_version >= 7.5){
		document.getElementById("FormTitle").className = "FormTitle_firefox";
		if(current_url.indexOf("Main_Ss_Content.asp") == 0){
			document.getElementById("FormTitle").style.marginTop = "0px"		
			//console.log("firefox 0");
		}

	}
}

function menu_hook(title, tab) {
	browser_compatibility1();
	var enable_ss = "<% nvram_get("enable_ss"); %>";
	var enable_soft = "<% nvram_get("enable_soft"); %>";
	if(enable_ss == "1" && enable_soft == "1"){
		tabtitle[tabtitle.length -2] = new Array("", "shadowsocks设置", "负载均衡设置", "Socks5设置");
		tablink[tablink.length -2] = new Array("", "Main_Ss_Content.asp", "Main_Ss_LoadBlance.asp",  "Main_SsLocal_Content.asp");
	}else{
		tabtitle[tabtitle.length -1] = new Array("", "shadowsocks设置", "负载均衡设置", "Socks5设置");
		tablink[tablink.length -1] = new Array("", "Main_Ss_Content.asp", "Main_Ss_LoadBlance.asp",  "Main_SsLocal_Content.asp");
	}
}


var Base64;
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


String.prototype.replaceAll = function(s1,s2){
　　return this.replace(new RegExp(s1,"gm"),s2);
}

function showSSLoadingBar(seconds){
	if(window.scrollTo)
		window.scrollTo(0,0);

	disableCheckChangedStatus();
	
	htmlbodyforIE = document.getElementsByTagName("html");  //this both for IE&FF, use "html" but not "body" because <!DOCTYPE html PUBLIC.......>
	htmlbodyforIE[0].style.overflow = "hidden";	  //hidden the Y-scrollbar for preventing from user scroll it.
	
	winW_H();

	var blockmarginTop;
	var blockmarginLeft;
	if (window.innerWidth)
		winWidth = window.innerWidth;
	else if ((document.body) && (document.body.clientWidth))
		winWidth = document.body.clientWidth;
	
	if (window.innerHeight)
		winHeight = window.innerHeight;
	else if ((document.body) && (document.body.clientHeight))
		winHeight = document.body.clientHeight;

	if (document.documentElement  && document.documentElement.clientHeight && document.documentElement.clientWidth){
		winHeight = document.documentElement.clientHeight;
		winWidth = document.documentElement.clientWidth;
	}

	if(winWidth >1050){
	
		winPadding = (winWidth-1050)/2;	
		winWidth = 1105;
		blockmarginLeft= (winWidth*0.3)+winPadding-150;
	}
	else if(winWidth <=1050){
		blockmarginLeft= (winWidth)*0.3+document.body.scrollLeft-160;

	}
	
	if(winHeight >660)
		winHeight = 660;
	
	blockmarginTop= winHeight*0.3-140		
	
	document.getElementById("loadingBarBlock").style.marginTop = blockmarginTop+"px";
	// marked by Jerry 2012.11.14 using CSS to decide the margin
	document.getElementById("loadingBarBlock").style.marginLeft = blockmarginLeft+"px";
	document.getElementById("loadingBarBlock").style.width = 770+"px";

	
	/*blockmarginTop = document.documentElement.scrollTop + 200;
	document.getElementById("loadingBarBlock").style.marginTop = blockmarginTop+"px";*/

	document.getElementById("LoadingBar").style.width = winW+"px";
	document.getElementById("LoadingBar").style.height = winH+"px";
	
	loadingSeconds = seconds;
	progress = 100/loadingSeconds;
	y = 0;
	if (socks5 == "1"){
		LoadingLocalProgress(seconds);
	} else {
		LoadingSSProgress(seconds);
	}
	
}


function LoadingSSProgress(seconds){
	action = document.form.ss_basic_action.value;
	document.getElementById("LoadingBar").style.visibility = "visible";
	if (document.form.ss_basic_action.value == 9){
		document.getElementById("loading_block3").innerHTML = "应用负载均衡设置 ..."
		$j("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用负载均衡设置 ...</font></li>");
		return true;
	}
	if (document.form.ss_basic_enable.value == 0){
		document.getElementById("loading_block3").innerHTML = "SS服务关闭中 ..."
		$j("#loading_block2").html("<li><font color='#ffcc00'><a href='http://www.koolshare.cn' target='_blank'></font>SS工作有问题？请来我们的<font color='#ffcc00'>论坛www.koolshare.cn</font>反应问题...</font></li>");
	} else {
		if (action == 1 || action == 2 || action == 3 || action == 4){
			if (document.form.ss_basic_mode.value == 6){
				document.getElementById("loading_block3").innerHTML = "回国启用中 ..."
				$j("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
			}else if (document.form.ss_basic_mode.value == 5){
				document.getElementById("loading_block3").innerHTML = "全局模式启用中 ..."
				$j("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>此模式非科学上网方式，会影响国内网页速度...</font></li><li><font color='#ffcc00'>注意：全局模式并非VPN，只支持TCP流量转发...</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
			} else if (document.form.ss_basic_mode.value == 2){
				document.getElementById("loading_block3").innerHTML = "大陆白名单模式启用中 ..."
				$j("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
			} else if (document.form.ss_basic_mode.value == 1){
				document.getElementById("loading_block3").innerHTML = "gfwlist模式启用中 ..."
				$j("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>尝试不同的DNS解析方案，可以达到最佳的效果哦...</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
			}
		} else if (action == 5){
			document.getElementById("loading_block3").innerHTML = "shadowsocks插件升级 ..."
			//document.getElementById("log_content3").rows = 12;
			$j("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>升级服务会自动检测最新版本并下载升级...</font></li>");
		} else if (action == 6){
			document.getElementById("loading_block3").innerHTML = "shadowsocks规则更新 ..."
			$j("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>正在自动检测github上的更新...</font></li>");
		} else if (action == 7){
			document.getElementById("loading_block3").innerHTML = "恢复shadowsocks配置 ..."
			$j("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，配置恢复后需要重新提交！</font></li><li><font color='#ffcc00'>恢复配置中...</font></li>");
		} else if (action == 8){
			document.getElementById("loading_block3").innerHTML = "清空shadowsocks配置 ..."
			$j("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在清空shadowsocks配置...</font></li>");
		}
	}
}

function LoadingLocalProgress(seconds){
	document.getElementById("LoadingBar").style.visibility = "visible";
	document.getElementById("loading_block3").innerHTML = "socks5启用中 ..."
	$j("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>此模式非科学上网方式，会影响国内网页速度...</font></li><li><font color='#ffcc00'>注意：全局模式并非VPN，只支持TCP流量转发...</font></li>");
	y = y + progress;
	if(typeof(seconds) == "number" && seconds >= 0){
		if(seconds != 0){
			document.getElementById("proceeding_img").style.width = Math.round(y) + "%";
			document.getElementById("proceeding_img_text").innerHTML = Math.round(y) + "%";
	
			if(document.getElementById("loading_block1")){
				document.getElementById("proceeding_img_text").style.width = document.getElementById("loading_block1").clientWidth;
				document.getElementById("proceeding_img_text").style.marginLeft = "175px";
			}
			--seconds;
			setTimeout("LoadingLocalProgress("+seconds+");", 1000);
		}
		else{
			document.getElementById("proceeding_img_text").innerHTML = "完成";
			y = 0;
				setTimeout("hideSSLoadingBar();",1000);
				refreshpage();
		}
	}
}

function hideSSLoadingBar(){
	x = -1;
	document.getElementById("LoadingBar").style.visibility = "hidden";
	checkss = 0;
	var action = document.form.ss_basic_action.value;
	if (action == 5 || action == 6 ||action == 7 ||action == 8 || action == 9){
		refreshpage();
	}else{
		htmlbodyforIE = document.getElementsByTagName("html");  //this both for IE&FF, use "html" but not "body" because <!DOCTYPE html PUBLIC.......>
		htmlbodyforIE[0].style.overflowY = "visible";
		decode_show();
		checkss = 0;
		$G("ss_basic_password").value = Base64.decode($G("ss_basic_password").value);
		setTimeout("get_ss_status_data();",2000);
	}

}

function pass_checked(obj){
	switchType(obj, document.form.show_pass.checked, true);
}

function openShutManager(oSourceObj, oTargetObj, shutAble, oOpenTip, oShutTip) {
	var sourceObj = typeof oSourceObj == "string" ? document.getElementById(oSourceObj) : oSourceObj;
	var targetObj = typeof oTargetObj == "string" ? document.getElementById(oTargetObj) : oTargetObj;
	var openTip = oOpenTip || "";
	var shutTip = oShutTip || "";
	if (targetObj.style.display != "none") {
		if (shutAble) return;
		targetObj.style.display = "none";
		if (openTip && shutTip) {
			sourceObj.innerHTML = shutTip;
		}
	} else {
		if(isFirefox=navigator.userAgent.indexOf("Firefox")>0){
			$G(oTargetObj).style.margin = "0px 0px 0px 15px";
		}
			targetObj.style.display = "block";
		if (openTip && shutTip) {
		    sourceObj.innerHTML = openTip;
		}
	}
}

function openssHint(itemNum){
	statusmenu = "";	
	width="350px";

	if(itemNum == 10){
		statusmenu ="如果发现开关不能开启，那么请检查<a href='Advanced_System_Content.asp'><u><font color='#00F'>系统管理 -- 系统设置</font></u></a>页面内Enable JFFS custom scripts and configs是否开启。";
		_caption = "服务器说明";
	}
	
	if(itemNum == 0){
		width="750px";
		bgcolor="#CC0066",
		statusmenu ="<li>通过对路由器内ss访问(<a href='https://www.google.com.tw/' target='_blank'><u><font color='#00F'>https://www.google.com.tw/</font></u></a>)状态的检测，返回状态信息。状态检测默认每10秒进行一次，可以通过附加设置中的选项，更改检测时间间隔，每次检测都会请求<a href='https://www.google.com.tw/' target='_blank'><u><font color='#00F'>https://www.google.com.tw/</font></u></a>，该请求不会进行下载，仅仅请求HTTP头部，请求成功后，会返回working信息，请求失败，会返回Problem detected!</li>"
		statusmenu +="</br><li>状态检测只在SS主界面打开时进行，网页关闭后，后台是不会进行检测的，每次进入页面，或者切换模式，重新提交等操作，状态检测会在此后5秒后进行，在这之前，状态会显示为watting... 如果显示Waiting for first refresh...则表示正在等待首次状态检测的结果。</li>"
		statusmenu +="</br><li>状态检测反应的是路由器本身访问https://www.google.com.tw/的结果，并不代表电脑或路由器下其它终端的访问结果，透过状态检测，可以为使用SS代理中遇到的一些问题进行排查,一下列举一些常见的情况：</li>"
		statusmenu +="</br><b><font color='#CC0066'>1：双working，不能访问被墙网站：</font></b>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.1：DNS缓存：</font>可能你在未开启ss的时候访问过被墙域名，DNS缓存受到了污染，只需要简单的刷新下缓存，window电脑通过在CMD中运行命令：<font color='#669900'>ipconfig /flushdns</font>刷新电脑DNS缓存，手机端可以通过尝试开启飞行模式后关闭飞行模式刷新DNS缓存。"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.2：自定义DNS：</font>很多用户喜欢自己在电脑上定义DNS来使用，这样访问google等被墙网站，解析出来的域名基本都是污染的，因此建议将DNS解析改为自动获取。如果你的路由器很多人使用，你不能阻止别人自定义DNS，那么建议开启chromecast功能，路由器会将所有自定义的DNS劫持到自己的DNS服务器上，避免DNS污染。"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.3：host：</font>电脑端以前设置过host翻墙，host翻墙失效快，DNS解析将通过host完成，不过路由器，如果host失效，使用chnroute翻墙的模式将无法使用；即使未失效，在gfwlist模式下，域名解析通过电脑host完成，而无法进入ipset，同样使得翻墙无法使用，因此强烈建议清除相关host！"
		statusmenu +="</br><b><font color='#CC0066'>2：国内working，国外Problem detected!：</font></b>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.1：检查你的SS账号：</font>在电脑端用SS客户端检查是否正常；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.2：是否使用了域名：</font>一些SS服务商提供的域名，特别是较为复杂的域名，可能有解析不了的问题，可尝试更换为IP地址；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.3：是否使用了含有特殊字符的密码：</font>极少数情况下，电脑端账号使用正常，路由端却Problem detected!是因为使用了包含特殊字符的密码；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.4：尝试更换国外dns：</font>此部分详细解析，请看DNS部分帮助文档；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.5：更换shadowsocks主程序：</font>meirlin ss一直使用最新的shadowsocks-libev和shadowsocksR-libev代码编译主程序，如果某次更新后出现这种情况，在检查了以上均无问题后，可能出现的问题就是路由器内的ss主程序和服务器端的不匹配，此时你可以通过下载历史安装包，将旧的主程序替换掉新的，主程序位于路由器下的/koolshare/bin目录，shadowsocks-libev：ss-redir,ss-local,ss-tunnel；shadowsocksR-libev：rss-redir,rss-local,rss-tunnel；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.6：更新服务器端：</font>如果你不希望更换路由器端主程序，可以更新最新服务器端来尝试解决问题，另外建议使用原版SS的朋友,在服务器端部署和路由器端相同版本的shadowsocks-libev；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.7：ntp时间问题：</font>如果你使用SSR，一些混淆协议是需要验证ss服务器和路由器的时间的，如果时间相差太多，那么就会出现Problem detected! 。"
		statusmenu +="</br><b><font color='#CC0066'>3：双Problem detected!：</font></b>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>3.1：更换国内DNS：</font>在电脑端用SS客户端检查是否正常；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>3.2：逐项检查第2点中每个项目。</font>"
		statusmenu +="</br><b><font color='#CC0066'>4：国内Problem detected!，国外working：</font></b>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>4.1：尝试更换国内DNS。</font>"
		statusmenu +="</br><b><font color='#CC0066'>5：国外间歇性Problem detected!：</font></b>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>5.1：检查你的SS服务器ping和丢包：</font>一些线路可能在高峰期或者线路调整期，导致丢包过多，获取状态失败；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>5.2：升级新版本后出现这种情况：</font>merlin ss插件从2015年6月，其核心部分就基本无改动，升级新版本出现这种情况，最大可能的原因，新版本升级了最新的ss或者ssr的主程序，解决方法可以通过回滚路由器内程序，也可以升级你的服务器端到最新，如果你是自己搭建的用户,建议最新原版shadowsocks-libev程序。"
		statusmenu +="</br><b><font color='#CC0066'>6：你遇到了非常少见的情况：</font></b>来这里反馈吧：<a href='https://telegram.me/joinchat/DCq55kC7pgWKX9J4cJ4dJw' target='_blank'><u><font color='#00F'>telegram</font></u></a>。"
		_caption = "状态检测";
		return overlib(statusmenu, OFFSETX, -460, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
	}
	
	if(itemNum == 1){
		width="700px";
		bgcolor="#CC0066",
		//gfwlist
		statusmenu ="<span><b><font color='#CC0066'>【1】gfwlist模式:</font></b></br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;该模式使用gfwlist区分流量，Shadowsocks会将所有访问gfwlist内域名的TCP链接转发到Shadowsocks服务器，实现透明代理；</br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;和真正的gfwlist模式相比较，路由器内的gfwlist模式还是有一定缺点，因为它没法做到像gfwlist PAC文件一样，对某些域名的二级域名有例外规则。</br>"
		statusmenu +="<b><font color='#669900'>优点：</font></b>节省SS流量，可防止迅雷和PT流量。</br>"
		statusmenu +="<b><font color='#669900'>缺点：</font></b>代理受限于名单内的4000多个被墙网站，需要维护黑名单。一些不走域名解析的应用，比如telegram，需要单独添加IP/CIDR黑名单。</span></br></br>"
		//redchn
		statusmenu +="<span><b><font color='#CC0066'>【2】大陆白名单模式:</font></b></br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;该模式使用chnroute IP网段区分国内外流量，ss-redir将流量转发到Shadowsocks服务器，实现透明代理；</br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;由于采用了预先定义的ip地址块(chnroute)，所以DNS解析就非常重要，如果一个国内有的网站被解析到了国外地址，那么这个国内网站是会走ss的；</br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;因为使用了大量的cdn名单，能够保证常用的国内网站都获得国内的解析结果，但是即使如此还是不能完全保证国内的一些网站解析到国内地址，这个时候就推荐使用具备cdn解析能力的chinaDNS或者PcapDNSProxy。</br>"
		statusmenu +="<b><font color='#669900'>优点：</font></b>所有被墙国外网站均能通过代理访问，无需维护域名黑名单；主机玩家用此模式可以实现TCP代理国内直连。</br>"
		statusmenu +="<b><font color='#669900'>缺点：</font></b>消耗更多的Shadowsocks流量，迅雷下载和BT可能消耗SS流量。</span></br></br>"
		//overall
		statusmenu +="<span><b><font color='#CC0066'>【3】全局模式:</font></b></br>"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;除局域网和ss服务器等流量不走代理，其它都走代理(udp不走)，高级设置中提供了对代理协议的选择。</br>"
		statusmenu +="<b><font color='#669900'>优点：</font></b>简单暴力，全部出国；可选仅web浏览走ss，还是全部tcp代理走ss，因为不需要区分国内外流量，因此性能最好。</br>"
		statusmenu +="<b><font color='#669900'>缺点：</font></b>国内网站全部走ss，迅雷下载和BT全部走SS流量。</span></br></br>"
		_caption = "模式说明";
		return overlib(statusmenu, OFFSETX, -860, OFFSETY, -290, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
	}
	else if(itemNum == 2){
		
		statusmenu ="此处填入你的SS服务器的地址。</br>建议优先填入<font color='#F46'>IP地址</font>。填入域名，特别是一些服务商给的复杂域名，有时遇到无法解析会导致Problem detected!";
		_caption = "服务器";
	}
	else if(itemNum == 3){
		statusmenu ="此处填入你的SS服务器的端口";
		_caption = "服务器端口";
	}
	else if(itemNum == 4){
		statusmenu ="此处填入你的SS服务器的密码。</br><font color='#F46'>注意：</font>使用带有特殊字符的密码，可能会导致SS链接不上服务器。";
		_caption = "服务器密码";
	}
	else if(itemNum == 5){
		statusmenu ="此处填入你的SS服务器的加密方式。</br><font color='#F46'>建议</font>如果是自己搭建服务器，建议使用对路由器负担比较小的加密方式，例如chacha20,chacha20-ietf等。";
		_caption = "服务器加密方式";
	}
	else if(itemNum == 7){
		statusmenu ="此处选择一次性验证(OTA)选项。</br><font color='#F46'>注意：</font>一次性验证需要服务器端开启支持，才能选择！</br>一般自己搭建原生SS服务器，建议开启此选项，OTA有抗重放攻击的能力。"
		statusmenu +="</br>shadowsocks-libev和最新的shadowsocks-python服务器端都能支持OTA选项的开启。"
		statusmenu +="</br>shadowsocksR服务器端也兼容OTA，你需要在服务端配置协议为verify_sha1_compatible，混淆可选择任意一个，但必须是兼容版的。"
		statusmenu +="</br>更多信息，请参考<a href='https://shadowsocks.org/en/spec/one-time-auth.html' target='_blank'><u><font color='#00F'>一次性验证(OTA)</font></u></a>";
		_caption = "一次性验证(OTA)";
	}
	else if(itemNum == 8){
		statusmenu ="更多信息，请参考<a href='https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md' target='_blank'><u><font color='#00F'>ShadowsocksR 协议插件文档</font></u></a>"
		_caption = "协议插件（protocol）";
	}
	else if(itemNum == 9){
		statusmenu ="更多信息，请参考<a href='https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md' target='_blank'><u><font color='#00F'>ShadowsocksR 协议插件文档</font></u></a>"
		_caption = "混淆插件 (obfs)";
		
	}
	else if(itemNum == 11){
		statusmenu ="如果不知道如何填写，请一定留空，不然可能带来副作用！"
		statusmenu +="</br></br>请参考<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(8)'><font color='#00F'>协议插件（protocol）</font></a>和<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(9)'><font color='#00F'>混淆插件 (obfs)</font></a>内说明。"
		statusmenu +="</br></br>更多信息，请参考<a href='https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md' target='_blank'><u><font color='#00F'>ShadowsocksR 协议插件文档</font></u></a>"
		_caption = "自定义参数 (obfs_param)";
		//return overlib(statusmenu, OFFSETX, -860, OFFSETY, -290, LEFT, STICKY, WIDTH, 'width', CAPTION, " ", CLOSETITLE, '');
	}
	else if(itemNum == 12){
		width="500px";
		statusmenu ="此处显示你的SS插件当前的版本号，当前版本：<% dbus_get_def("ss_basic_version_local", "未知"); %>,如果需要回滚SS版本，请参考以下操作步骤：";
		statusmenu +="</br></br><font color='#CC0066'>1&nbsp;&nbsp;</font>进入<a href='Tools_Shell.asp' target='_blank'><u><font color='#00F'>webshell</font></u></a>或者其他telnet,ssh等能输入命令的工具";
		statusmenu +="</br><font color='#CC0066'>2&nbsp;&nbsp;</font>请依次输入以下命令，等待上一条命令执行完后再运行下一条(这里以回滚2.8.9为例)：";
		statusmenu +="</br></br>&nbsp;&nbsp;&nbsp;&nbsp;cd /tmp";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;wget --no-check-certificate https://raw.githubusercontent.com/koolshare/koolshare.github.io/mips_softerware_center/shadowsocks/history/shadowsocks_2.8.9.tar.gz";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;tar -zxvf /tmp/shadowsocks.tar.gz";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;chmod +x /tmp/shadowsocks/install.sh";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;sh /tmp/shadowsocks/install.sh";
		statusmenu +="</br></br>最后一条命令输入完后不会有任何打印信息。";
		statusmenu +="</br>回滚其它版本号，请参考<a href='https://github.com/koolshare/koolshare.github.io/tree/mips_softerware_center/shadowsocks/history' target='_blank'><u><font color='#00F'>版本历史列表</font></u></a>";
		_caption = "shadowsocks for merlin 版本";
	}
	else if(itemNum == 13){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;SSR表示shadowwocksR-libev，相比较原版shadowwocksR-libev，其提供了强大的协议混淆插件，让你避开gfw的侦测。"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;虽然你在节点编辑界面能够指定使用SS的类型，不过这里还是提供了勾选使用SSR的选项，是为了方便一些服务器端是兼容原版协议的用户，快速切换SS账号类型而设定。";
		_caption = "使用SSR";
	}
	else if(itemNum == 15){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;点击右侧的铅笔图标，进入节点界面，在节点界面，你可以进行节点的添加，修改，删除，应用，检查节点ping，和web访问性等操作。"
		_caption = "选择节点";
	}
	else if(itemNum == 16){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;此处不同模式会显示不同的图标，如果你是从2.0以前的老版本升级过来的，可能有些节点不会显示图标，只需要编辑一下节点，选择好模式，然后保存即可显示。"
		_caption = "模式";
	}
	else if(itemNum == 17){
		statusmenu ="节点名称支持中文，支持空格。"
		_caption = "节点名称";
	}
	else if(itemNum == 18){
		statusmenu ="优先建议使用ip地址"
		_caption = "服务器地址";
	}
	else if(itemNum == 19){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;ping/丢包功能用于检测你的路由器到ss服务器的ping值和丢包；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;一些奇葩的运营商可能会禁ping，一些SS服务器也会禁止ping，此处检测就会failed，所以遇到这种情况不必惊恐。"
		_caption = "ping/丢包";
	}
	else if(itemNum == 20){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;延迟是你访问所测试网站，请求完整个网站所花的时间，间接的反应了你的ss的速度；"
		_caption = "延迟";
	}
	else if(itemNum == 21){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;编辑节点功能能帮助你快速的更改ss某个节点的设置，比如服务商更换IP地址之后，可以快速更改；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;编辑节点目前只支持相同类型节点的编辑，比如不能将ss节点编辑为ssr节点，如果你的ssr节点是兼容原版协议的，建议你在主面板用使用ssr勾选框来进行更改。"
		_caption = "编辑节点";
	}
	else if(itemNum == 22){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;删除节点功能能快速的删除某个特定的节点，为了方便快速删除，删除节点点击后生效，不会有是否确认弹出。"
		_caption = "编辑节点";
	}
	else if(itemNum == 23){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;点击使用节点能快速的将该节点填入主面板，但是你需要在主面板点击提交，才能使用该节点。"
		_caption = "使用节点";
	}
	else if(itemNum == 24){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;导出功能可以将ss所有的设置全部导出，包括节点信息，dns设定，黑白名单设定等；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;恢复配置功能可以使用之前导出的文件，也可以使用标准的json格式节点文件。"
		_caption = "导出恢复";
	}
	else if(itemNum == 25){
		statusmenu ="<font color='#CC0066'>1&nbsp;&nbsp;在gfwlist模式下：</font>";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;将用此处定义的国内DNS解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/gfwlist.conf' target='_blank'><u><font color='#00F'>gfwlist</font></u></a>以外的网址，包括全部国内网址和国外未被墙的网址。"
		statusmenu +="</br></br><font color='#CC0066'>2&nbsp;&nbsp;在大陆白名单模式：</font>";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;将用此处定义的国内DNS将解析国内<a href='https://github.com/koolshare/koolshare.github.io' target='_blank'><font color='#00F'>2W+个域名（CDN名单）</font></a> 参与维护这个列表。"
		_caption = "国内DNS";
	}
	else if(itemNum == 26){
		width="750px";
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;国外DNS为大家提供了丰富的选择，其目的有二，一是为了保证大家有能用的国外DNS服务；二十在有能用的基础上，能够选择多种DNS解析方案，达到最佳的解析效果；所以如果你切换某个DNS程序，导致国外连接Problem detected! 那么久更换能用的就好，不用纠结某个解析方案不能用。"
		statusmenu +="&nbsp;&nbsp;&nbsp;&nbsp;</br></br>下面我会就我的认知对几种国外DNS方案做一个简单介绍："
		//dns2socks
		statusmenu +="</br><font color='#CC0066'>1:dns2socks：</font>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;可以说是万金油方案,作用是将 DNS请求通过一个socks5隧道转发到DNS服务器，和下文中ss-tunnel类似，不过1dns2socks是利用了SOCK5隧道代理，ss-tunnel是利用了加密UDP；该DNS方案不受到ss服务是否支持udp限制，不受到运营商是否封Opendns限制，只要能建立socoks5链接，就能使用；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;在gfwlist模式下，dns2socks用于针对性的解析gfwlist内的域名名单；在使用chnroute的模式（大陆白名单模式）dns2socks用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>以外的所有域名，所以一些没有包含在这份名单内的网站，而正好这个网站有部署国外地址的话，那么这个网站就会被解析为国外ip，然后由ipset判断流量走ss，当然这种情况是比较少的，因为一般常用的国内网站都包含在这份cdn名单内了。";
		//dnscrypt-proxy
		statusmenu +="</br><font color='#CC0066'>2:dnscrypt-proxy：</font>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;原理是通过加密连接到支持该程序的国外DNS服务器，由这些DNS服务器解析出gfwlist中域名的IP地址，因为该解析不走ss服务器，所以解析出的IP地址离SS服务器的距离随机，国外CDN较弱。这里提供了很多支持dnscrypt-proxy解析的节点列表，通常最常用的就是cisco(opendns)，不过国内有些地区的运营商针对opendns有封锁，所以有时候选择dnscrypt-proxy + opendns的方案可能行不通；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;在gfwlist模式下，dnscrypt-proxy用于针对性的解析gfwlist内的域名名单；在使用chnroute的模式（大陆白名单模式）dnscrypt-proxy用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>以外的所有域名，所以一些没有包含在这份名单内的网站，而正好这个网站有部署国外地址的话，那么这个网站就会被解析为国外ip，然后由ipset判断流量走ss，当然这种情况是比较少的，因为一般常用的国内网站都包含在这份cdn名单内了。";
		//ss-tunnel
		statusmenu +="</br><font color='#CC0066'>3:ss-tunnel：</font>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;原理是将DNS请求，通过ss-tunnel利用UDP发送到ss服务器上，由ss服务器向你定义的DNS服务器发送解析请求，解析出gfwlist中域名的IP地址，这种方式解析出来的IP地址会距离ss服务器更近，具有较强的国外CDN效果;"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;在gfwlist模式下，ss-tunnel用于针对性的解析gfwlist内的域名名单；在使用chnroute的模式（大陆白名单模式）ss-tunnel用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>以外的所有域名，所以一些没有包含在这份名单内的网站，而正好这个网站有部署国外地址的话，那么这个网站就会被解析为国外ip，然后由ipset判断流量走ss，当然这种情况是比较少的，因为一般常用的国内网站都包含在这份cdn名单内了。";
		//ChinaDNS
		statusmenu +="</br><font color='#CC0066'>4:ChinaDNS：</font>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;原理是通过ChinaDNS自身的DNS并发查询，同时将你要请求的域名同时向国内和国外DNS发起查询，然后用ChinaDNS内置的双向过滤+指针压缩功能来过滤掉污染ip，双向过滤保证了国内地址都用国内域名查询，因此使用ChinaDNS能够获得最佳的国内CDN效果，这里ChinaDNS国内服务器的选择是有要求的，这个DNS的ip地址必须在<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>定义的IP段内，同理你选择或者自定义的国外DNS必须在chnroute定义的IP段外，所以比如你在国内DNS处填写你的上级路由器的ip地址，类似192.168.1.1这种，会被ChinaDNS判断为国外IP地址,从而使得双向过滤功能失效，国外DNS解析的IP地址就会进入DNS缓存；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;因为ChinaDNS自己具备cdn解析能力，所以没必要再使用<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>,因为使用这个名单会对dnsmasq造成很大的负担！"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;为了保证ChinaDNS国外解析的效果，这里我给出的ChinaDNS国外DNS都是又经过了一层软件（dns2socks，dnscrypt-proxy，ss-tunnel）的；同时你也可以自定义ChinaDNS国外dns去直接去请求国外DNS服务器，但是cdn效果就不会有经过上层软件后好。这里如果选择dns2socks或者ss-tunnel，ChinaDNS解析国外DNS会向上游软件去请求，而这两个上游软件都会经过SS服务器，可以说能达到良好的国外CDN效果；"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;因为gfwlist模式的原理，不需要用到这个软件，也有良好的cdn效果，所以并没有必要在gfwlist模式中集成该方案;"
		//pdnsd
		statusmenu +="</br><font color='#CC0066'>5:pdnsd：</font>"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;pdnsd是一个老牌的dns解析软件了它不仅可以用来做解析软件，还能用来自己搭建dns缓存服务器；早期pdnsd的流行，主要是其支持TCP解析，然而随着gfw对投毒范围的越来越广泛，tcp解析已经不能保证无毒了，但是其强大的dns缓存机制，让我仍然不肯放弃它；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;pdnsd域名解析具备强大的dns缓存机制，通过修改最小ttl时间，可以让缓存进入电脑后很长时间才会失效，优点就是每次解析国外网站，仅需1ms的时间；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;设置pdnsd的上有服务器，建议使用UDP方式，因为TCP方式，除非自己搭建支持TCP查询的DNS服务器，很难避免污染的情况，而UDP方式也是提供了（dns2socks，dnscrypt-proxy，ss-tunnel）三种上游软件，这里就不再赘述；";
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;在gfwlist模式下，pdnsd用于针对性的解析gfwlist内的域名名单，因此pdnsd的DNS缓存也只针对这部分域名；在使用chnroute的模式（大陆白名单模式）dnscrypt-proxy用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>以外的所有域名，pdnsd的DNS缓存也针对这部分域名（但是范围比使用gfwlist要大得多了），所以一些没有包含在这份名单内的网站，而正好这个网站有部署国外地址的话，那么这个网站就会被解析为国外ip，然后由ipset判断流量走ss，当然这种情况是比较少的，因为一般常用的国内网站都包含在这份cdn名单内了。";
		_caption = "国外DNS";
		return overlib(statusmenu, OFFSETX, -860, OFFSETY, -290, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
		
	}
	else if(itemNum == 27){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;ChinaDNS用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>以外的国内网址的DNS。"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;因为ChinaDNS会将你定义的国内DNS和<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>做匹配，如果你定义的国内DNS不在<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>内，那么就是无效的，比如你定义了上级路由器的192.168.1.1的DNS那么就是无效的！"
		_caption = "ChinaDNS国内DNS";
	}
	else if(itemNum == 28){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;ChinaDNS用于解析<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>以外的国外网址的DNS。"
		_caption = "ChinaDNS国外DNS";
	}
	else if(itemNum == 29){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;除非你知道你在做什么，这里还是建议大家使用udp查询方式。"
		_caption = "pdnsd查询方式";
	}
	else if(itemNum == 30){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;如果使用TCP查询，请一定确保查询结果没有污染。"
		_caption = "pdnsd上游服务器（TCP）";
	}
	else if(itemNum == 31){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;dns2socks和ss-tunnel是走ss服务器的查询方式（国外cdn较好），dnscrypt-proxy是本地直接请求的方式（国外cdn较弱）。"
		_caption = "pdnsd上游服务器（UDP）";
	}
	else if(itemNum == 32){
		statusmenu ="&nbsp;&nbsp;&nbsp;&nbsp;默认给出了最小TTL 24小时，最长TTL1周。"
		_caption = "pdnsd缓存设置";
	}
	else if(itemNum == 33){
		statusmenu ="填入需要强制用国内DNS解析的域名，一行一个，格式如下：。"
		statusmenu +="</br>注意：不支持通配符！"
		statusmenu +="</br></br>koolshare.cn"
		statusmenu +="</br>baidu.com"
		statusmenu +="</br></br>需要注意的是，这里要填写的一定是网站的一级域名，比如taobao.com才是正确的，www.taobao.com，http://www.taobao.com/这些格式都是错误的！"
		_caption = "自定义需要CDN加速网站";
	}
	else if(itemNum == 34){
		statusmenu ="填入自定义的dnsmasq设置，一行一个，格式如下：。"
		statusmenu +="</br></br>#例如hosts设置："
		statusmenu +="</br>address=/koolshare.cn/2.2.2.2"
		statusmenu +="</br></br>#防DNS劫持设置"
		statusmenu +="</br>bogus-nxdomain=220.250.64.18"
		statusmenu +="</br></br>#指定config设置"
		statusmenu +="</br>conf-file=/jffs/mydnsmasq.conf"
		statusmenu +="</br></br>如果填入了错误的格式，可能导致dnsmasq启动失败！"
		statusmenu +="</br></br>如果填入的信息里带有英文逗号的，也会导致dnsmasq启动失败！"
		_caption = "自定义dnsamsq";
	}
	else if(itemNum == 38){
		statusmenu ="填入不需要走代理的外网ip/cidr地址，一行一个，格式如下：。"
		statusmenu +="</br></br>2.2.2.2"
		statusmenu +="</br>3.3.3.3"
		statusmenu +="</br>4.4.4.4/24"
		_caption = "IP/CIDR白名单";
	}
	else if(itemNum == 39){
		statusmenu ="填入不需要走代理的域名，一行一个，格式如下：。"
		statusmenu +="</br></br>google.com"
		statusmenu +="</br>facebook.com"
		statusmenu +="</br></br>需要注意的是，这里要填写的一定是网站的一级域名，比如google.com才是正确的，www.google.com，https://www.google.com/这些格式都是错误的！"
		statusmenu +="</br></br>需要清空电脑DNS缓存，才能立即看到效果"
		_caption = "域名白名单";
	}
	else if(itemNum == 40){
		statusmenu ="填入需要强制走代理的外网ip/cidr地址，，一行一个，格式如下：。"
		statusmenu +="</br></br>5.5.5.5"
		statusmenu +="</br>6.6.6.6"
		statusmenu +="</br>7.7.7.7/8"
		_caption = "IP/CIDR黑名单";
	}
	else if(itemNum == 41){
		statusmenu ="填入需要强制走代理的域名，，一行一个，格式如下：。"
		statusmenu +="</br></br>baidu.com"
		statusmenu +="</br>taobao.com"
		statusmenu +="</br></br>需要注意的是，这里要填写的一定是网站的一级域名，比如google.com才是正确的，www.baidu.com，http://www.baidu.com/这些格式都是错误的！"
		statusmenu +="</br></br>需要清空电脑DNS缓存，才能立即看到效果。"
		_caption = "IP/CIDR黑名单";
	}
	else if(itemNum == 42){
		statusmenu ="此处定义ss状态检测更新时间间隔，默认5秒。"
		_caption = "状态更新间隔";
	}
	else if(itemNum == 43){
		statusmenu ="chromecast功能能将所有来自局域网的DNS请求强行劫持到路由器自己的53端口上。"
		statusmenu +="</br>如果你不能防止局域网中的别人自定义DNS服务器，那么未必防止DNS污染，可以开启此选项；"
		statusmenu +="</br>开启后不管在电脑上定义什么DNS，都将会被劫持到你在路由器定义的DNS。"
		_caption = "chromecast";
	}
	else if(itemNum == 44){
		statusmenu ="shadowsocks规则更新包括了gfwlist模式中用到的<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/gfwlist.conf' target='_blank'><font color='#00F'><u>gfwlist</u></font></a>，在大陆白名单模式中用到的<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>和<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>"
		statusmenu +="</br>建议更新时间在凌晨闲时进行，以避免更新时重启ss服务器造成网络访问问题。"
		_caption = "shadowsocks规则自动更新";
	}
	else if(itemNum == 45){
		statusmenu ="通过局域网客户端控制功能，你能定义在当前模式下某个局域网地址是否走SS。"
		_caption = "局域网客户端控制";
	}
	else if(itemNum == 46){
		statusmenu ="一些用户的网络拨号可能比较滞后，为了保证SS在路由器开机后能正常启动，可以通过此功能，为ss的启动增加开机延迟。"
		_caption = "开机启动延迟";
	}
	else if(itemNum == 50){
		statusmenu ="通过此开关，你可以开启或者关闭侧边栏面板上的shadowsocks入口;"
		statusmenu +="</br>该开关在固件版本6.6.1（不包括6.6.1）以上起作用。"
		_caption = "侧边栏开关";
	}
	else if(itemNum == 51){
		width="600px";
		statusmenu ="如果你的ss服务器填写了域名，可以通过此处的设置来定义域名的解析方式"
		statusmenu +="</br></br><font color='#00F'>如果解析正确:</font>ip地址将用于ss的配置文件和iptables对vps ip的RETURN操作"
		statusmenu +="</br></br><font color='#00F'>如果解析失败:</font>ss的配置文件将会使用域名，然后由ss-redir自己去解析；iptables对vps ip的RETURN将不会添加，就会造成两种情况："
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;1，如果ss-redir自己也解析失败，就会出现Problem detected!，然后你将不能访问自己的vps，除非关闭ss"
		statusmenu +="</br>&nbsp;&nbsp;&nbsp;&nbsp;2，如果ss-redir自己解析成功，就会出现working...，虽然你能访问你的vps，但是是vps自己（127.0.0.1）访问自己，此时切换节点、关闭ss等操作，会断开你访问你vps的链接！当然，这对普通用户和购买ss帐号的用户没什么影响。"
		statusmenu +="</br></br>nslookup解析方式比较自由，能自定义dns解析服务器，解析成功率比较高，但是解析失败的时候可能导致脚本开在nslookup处，可能导致过早提交结束，从而导致fq的dns污染。"
		statusmenu +="</br></br>resolveip解析方式不会卡住脚本，如果4秒内不能解析成功，将不再尝试，然后把域名交给ss-redir自己取解析，并且不添加vps ip的RETURN条目。"
		statusmenu +="</br></br>如果你使用IP地址作为服务器地址，那么选择两者没有区别，如果你使用域名，建议优先使用resolveip方式，如果还是不行再使用nslookup方式，再不行，就更换nslookup方式的解析服务器"
		_caption = "SS服务器解析";
	}else if(itemNum == 52){
		statusmenu ="KCP协议，ss-libev混淆，负载均衡下均不支持UDP！"
		statusmenu +="</br>请检查你是否启用了其中之一。"
		_caption = "侧边栏开关";
	}else if(itemNum == 53){
		statusmenu ="此处可以自定义你偏向使用的DNS解析方案"
		statusmenu +="</br></br>国内优先：国外dns解析gfwlist名单内的国外域名，其余域名用国内dns解析，需要<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/gfwlist.conf' target='_blank'><u><font color='#00F'>gfwlist</font></u></a>，占用cpu较小，国内解析效果好。"
		statusmenu +="</br></br>国外优先：国内dns解析cdn名单内的国内域名用，其余域名用国外dns解析，需要<a href='https://github.com/koolshare/koolshare.github.io/blob/acelan_softcenter_ui/maintain_files/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>，占用cpu较大，国外解析效果好。"
		_caption = "侧边栏开关";
	}
	else if(itemNum == 54){
		statusmenu ="更多信息，请参考<a href='https://breakwa11.blogspot.jp/2017/01/shadowsocksr-mu.html' target='_blank'><u><font color='#00F'>ShadowsocksR 协议参数文档</font></u></a>"
		_caption = "协议参数（protocol）";
	}
		//return overlib(statusmenu, OFFSETX, -160, LEFT, DELAY, 200);
		//return overlib(statusmenu, OFFSETX, -160, LEFT, STICKY, WIDTH, 'width', CAPTION, " ", FGCOLOR, "#4D595D", CAPCOLOR, "#000000", CLOSECOLOR, "#000000", MOUSEOFF, "1",TEXTCOLOR, "#FFF", CLOSETITLE, '');
		return overlib(statusmenu, OFFSETX, -160, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');

	var tag_name= document.getElementsByTagName('a');	
	for (var i=0;i<tag_name.length;i++)
		tag_name[i].onmouseout=nd;
		
	if(helpcontent == [] || helpcontent == "" || hint_array_id > helpcontent.length)
		return overlib('<#defaultHint#>', HAUTO, VAUTO);
	else if(hint_array_id == 0 && hint_show_id > 21 && hint_show_id < 24)
		return overlib(helpcontent[hint_array_id][hint_show_id], FIXX, 270, FIXY, 30);
	else{
		if(hint_show_id > helpcontent[hint_array_id].length)
			return overlib('<#defaultHint#>', HAUTO, VAUTO);
		else
			return overlib(helpcontent[hint_array_id][hint_show_id], HAUTO, VAUTO);
	}
}

function showDropdownClientList(_callBackFun, _callBackFunParam, _interfaceMode, _containerID, _pullArrowID, _clientState) {
	document.body.addEventListener("click", function(_evt) {control_dropdown_client_block(_containerID, _pullArrowID, _evt);})
	if(clientList.length == 0){
		setTimeout(function() {
			genClientList();
			showDropdownClientList(_callBackFun, _callBackFunParam, _interfaceMode, _containerID, _pullArrowID);
		}, 500);
		return false;
	}

	var htmlCode = "";
	htmlCode += "<div id='" + _containerID + "_clientlist_online'></div>";
	htmlCode += "<div id='" + _containerID + "_clientlist_dropdown_expand' class='clientlist_dropdown_expand' onclick='expand_hide_Client(\"" + _containerID + "_clientlist_dropdown_expand\", \"" + _containerID + "_clientlist_offline\");' onmouseover='over_var=1;' onmouseout='over_var=0;'>Show Offline Client List</div>";
	htmlCode += "<div id='" + _containerID + "_clientlist_offline'></div>";
	document.getElementById(_containerID).innerHTML = htmlCode;

	var param = _callBackFunParam.split(">");
	var clientMAC = "";
	var clientIP = "";
	var getClientValue = function(_attribute, _clienyObj) {
		var attribute_value = "";
		switch(_attribute) {
			case "mac" :
				attribute_value = _clienyObj.mac;
				break;
			case "ip" :
				if(clientObj.ip != "offline") {
					attribute_value = _clienyObj.ip;
				}
				break;
			case "name" :
				attribute_value = (clientObj.nickName == "") ? clientObj.name.replace(/'/g, "\\'") : clientObj.nickName.replace(/'/g, "\\'");
				break;
			default :
				attribute_value = _attribute;
				break;
		}
		return attribute_value;
	};

	var genClientItem = function(_state) {
		var code = "";
		var clientName = (clientObj.nickName == "") ? clientObj.name : clientObj.nickName;
		
		code += '<a id=' + clientList[i] + ' title=' + clientList[i] + '>';
		if(_state == "online")
			code += '<div onclick="' + _callBackFun + '(\'';
		else if(_state == "offline")
			code += '<div style="color:#A0A0A0" onclick="' + _callBackFun + '(\'';
		for(var j = 0; j < param.length; j += 1) {
			if(j == 0) {
				code += getClientValue(param[j], clientObj);
			}
			else {
				code += '\', \'';
				code += getClientValue(param[j], clientObj);
			}
		}
		code += '\''
		code += ', '
		code += '\''
		code += clientName;
		code += '\');">';
		code += '<strong>';
		if(clientName.length > 32) {
			code += clientName.substring(0, 30) + "..";
		}
		else {
			code += clientName;
		}
		code += '</strong>';
		if(_state == "offline")
			code += '<strong title="Remove this client" style="float:right;margin-right:5px;cursor:pointer;" onclick="removeClient(\'' + clientObj.mac + '\', \'' + _containerID  + '_clientlist_dropdown_expand\', \'' + _containerID  + '_clientlist_offline\')">×</strong>';
		code += '</div><!--[if lte IE 6.5]><iframe class="hackiframe2"></iframe><![endif]--></a>';
		return code;
	};

	for(var i = 0; i < clientList.length; i +=1 ) {
		var clientObj = clientList[clientList[i]];
		switch(_clientState) {
			case "all" :
				if(_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if(_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if(clientObj.isOnline) {
					document.getElementById("" + _containerID + "_clientlist_online").innerHTML += genClientItem("online");
				}
				else if(clientObj.from == "nmpClient") {
					document.getElementById("" + _containerID + "_clientlist_offline").innerHTML += genClientItem("offline");
				}
				break;
			case "online" :
				if(_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if(_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if(clientObj.isOnline) {
					document.getElementById("" + _containerID + "_clientlist_online").innerHTML += genClientItem("online");
				}
				break;
			case "offline" :
				if(_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if(_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if(clientObj.from == "nmpClient") {
					document.getElementById("" + _containerID + "_clientlist_offline").innerHTML += genClientItem("offline");
				}
				break;
		}		
	}
	
	if(document.getElementById("" + _containerID + "_clientlist_offline").childNodes.length == "0") {
		if(document.getElementById("" + _containerID + "_clientlist_dropdown_expand") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_dropdown_expand"));
		}
		if(document.getElementById("" + _containerID + "_clientlist_offline") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_offline"));
		}
	}
	else {
		if(document.getElementById("" + _containerID + "_clientlist_dropdown_expand").innerText == "Show Offline Client List") {
			document.getElementById("" + _containerID + "_clientlist_offline").style.display = "none";
		}
		else {
			document.getElementById("" + _containerID + "_clientlist_offline").style.display = "";
		}
	}
	if(document.getElementById("" + _containerID + "_clientlist_online").childNodes.length == "0") {
		if(document.getElementById("" + _containerID + "_clientlist_online") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_online"));
		}
	}

	if(document.getElementById(_containerID).childNodes.length == "0")
		document.getElementById(_pullArrowID).style.display = "none";
	else
		document.getElementById(_pullArrowID).style.display = "";
}
