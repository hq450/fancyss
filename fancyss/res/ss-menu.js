function E(e) {
	return (typeof(e) == 'string') ? document.getElementById(e) : e;
}
function isObjectEmpty(obj) {
	return Object.keys(obj).length === 0;
}
var elem = {
	parentElem: function(e, tagName) {
		e = E(e);
		tagName = tagName.toUpperCase();
		while (e.parentNode) {
			e = e.parentNode;
			if (e.tagName == tagName) return e;
		}
		return null;
	},
	display: function() {
		var enable = arguments[arguments.length - 1];
		for (var i = 0; i < arguments.length - 1; ++i) {
			E(arguments[i]).style.display = enable ? '' : 'none';
		}
	},
}

function get_config(name, def) {
	return ((typeof(nvram) != 'undefined') && (typeof(nvram[name]) != 'undefined')) ? nvram[name] : def;
}

(function($) {
	$.fn.forms = function(data, settings) {
		$(this).append(createFormFields(data, settings));
	}
})(jQuery);

function escapeHTML(s) {
	function esc(c) {
		return '&#' + c.charCodeAt(0) + ';';
	}
	return s.replace(/[&"'<>\r\n]/g, esc);
}

function UT(v) {
	return (typeof(v) == 'undefined') ? '' : '' + v;
}

function createFormFields(data, settings) {
	var id, id1, common, output, form = '', multiornot;
	var s = $.extend({
		'align': 'left',
		'grid': ['col-sm-3', 'col-sm-9']

	}, settings);
	$.each(data, function(key, v) {
		if (!v) {
			form += '<br />';
			return;
		}
		if (v.ignore) return;
		if (v.th) {
			form += '<tr' + ((v.class) ? ' class="' + v.class + '"' : '') + '><th colspan="' + v.th + '">' + v.title + '</th></tr>';
			return;
		}
		if (v.thead) {
			form += '<thead><tr><td colspan="2">' + v.title + '</td></tr></thead>';
			return;
		}
		if (v.td) {
			form += v.td;
			return;
		}
		form += '<tr' + ((v.rid) ? ' id="' + v.rid + '"' : '') + ((v.class) ? ' class="' + v.class + '"' : '') + ((v.hidden) ? ' style="display: none;"' : '') + '>';
		if (v.help) {
			v.title += '&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(' + v.help + ')"><font color="#ffcc00"><u>[说明]</u></font></a>';
		}
		if (v.text) {
			if (v.title)
				form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.title + '</label><div class="' + s.grid[1] + ' text-block">' + v.text + '</div></fieldset>';
			else
				form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.text + '</label></fieldset>';
			return;
		}
		if (v.multi) multiornot = v.multi;
		else multiornot = [v];
		output = '';
		$.each(multiornot, function(key, f) {
			id = (f.id ? f.id : '');
			common = ' id="' + id + '"';
			if (f.func == 'v') common += ' onchange="verifyFields(this, 1);"';
			else if (f.func == 'u') common += ' onchange="update_visibility();"';
			else if (f.func) common += ' ' + f.func

			if (f.attrib) common += ' ' + f.attrib;
			if (f.ph) common += ' placeholder="' + f.ph + '"';
			if (f.disabled) common += ' disabled="disabled"'
			if (f.prefix) output += f.prefix;
			switch (f.type) {
				case 'checkbox':
					if (f.css) common += ' class="' + f.css + '"';
					if (f.style) common += ' style="' + f.style + '"';
					output += '<input type="checkbox"' + (f.value ? ' checked' : '') + common + '>' + (f.suffix ? f.suffix : '');
					break;
				case 'radio':
					output += '<input type="radio"' + (f.name ? 'name=' + f.name : '') + common + 'class="input"'  + (f.value == 1 ? ' checked' : '') + '>' + (f.suffix ? f.suffix : '');
					break;
				case 'password':
					common += ' class="input_ss_table" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"';
					if (f.style) common += ' style="' + f.style + '"';
					if (f.peekaboo) common += ' readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute(' + '\'readonly\'' + ');"';
					output += '<input type="' + f.type + '"' + ' value="' + escapeHTML(UT(f.value)) + '"' + (f.maxlen ? (' maxlength="' + f.maxlen + '" ') : '') + common + '>';
					break;
				case 'text':
					if (f.css) common += ' class="input_ss_table ' + f.css + '"';
					else common += ' class="input_ss_table" spellcheck="false"';
					if (f.style) common += ' style="' + f.style + '"';
					if (f.title) common += ' title="' + f.title + '"';
					output += '<input type="' + f.type + '"' + ' value="' + escapeHTML(UT(f.value)) + '"' + (f.maxlen ? (' maxlength="' + f.maxlen + '" ') : '') + common + '>';
					break;
				case 'select':
					if (f.css) common += ' class="input_option ' + f.css + '"';
					else common += ' class="input_option"';
					if (f.style) common += ' style="' + f.style + ';margin:0px 0px 0px 2px;"';
					else common += ' style="width:164px;margin:0px 0px 0px 2px;"';
					output += '<select' + common + '>';
					for (optsCount = 0; optsCount < f.options.length; ++optsCount) {
						a = f.options[optsCount];
						if (!Array.isArray(a)) {
							output += '<option value="' + a + '"' + ((a == f.value) ? ' selected' : '') + '>' + a + '</option>';
						} else {
							if (a.length == 1) a.push(a[0]);
							if (a[0] == "group"){
								output += '<optgroup label="' + a[1] + '">';
							}else{
								output += '<option value="' + a[0] + '"' + ((a[0] == f.value) ? ' selected' : '') + '>' + a[1] + '</option>';
							}
						}
					}
					output += '</select>';
					break;
				case 'textarea':
					common += ' autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"';
					if (f.style) common += ' style="' + f.style + ';margin:0px 0px 0px 2px;"';
					else common += ' style="margin:0px 0px 0px 2px;"';
					if (f.rows) common += ' rows="' + f.rows + '"';
					output += '<textarea ' + common + (f.wrap ? (' wrap=' + f.wrap) : '') + '>' + escapeHTML(UT(f.value)) + '</textarea>';
					break;
				default:
					if (f.custom) output += f.custom;
					break;
			}
			if (f.suffix && (f.type != 'checkbox' && f.type != 'radio')) output += f.suffix;
		});
		//if (v.hint) form += '<th><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(' + v.hint + ')">' + v.title + '</a></th><td>' + output;
		//if (v.hint) form += '<th><a class="hintstyle" href="javascript:void(0);" onmouseover="mOver(this, ' + v.hint + ')" onmouseout="mOut(this)" ><em>' + v.title + '</em></a></th><td>' + output;
		if (v.hint) form += '<th><a class="hintstyle" style="color:#03a9f4;" href="javascript:void(0);" onmouseover="mOver(this, ' + v.hint + ')" onmouseout="RunmOut(this)" >' + v.title + '</a></th><td>' + output;
		else if (v.thtd) form += '<th>' + v.title + '</th><td>' + output;
		else form += '<th>' + v.title + '</th><td>' + output;
		form += '</td></tr>';
	});
	return form;
}
function pop_111() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 2,
			shade: .7,
			scrollbar: 0,
			title: '国内外分流信息来源：<a style="color:#00F" href="https://ip.skk.moe/" target="_blank">https://ip.skk.moe/</a>',
			area: ['850px', '760px'],
			fixed: false,   
			move: false,
			maxmin: true,
			shadeClose: 1,
			id: 'LAY_layuipro',
			btnAlign: 'c',
			content: ['https://ip.skk.moe/', 'yes'],
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
			shade: 0.8,
			shadeClose: 1,
			scrollbar: false,
			id: 'LAY_layuipro',
			btn: ['关闭窗口'],
			btnAlign: 'c',
			moveType: 1,
			content: '<div style="padding: 50px; line-height: 22px; background-color: #393D49; color: #fff; font-weight: 300;">\
				<b><% nvram_get("productid"); %> - 科学上网插件 - ' + db_ss["ss_basic_version_local"] + '</b><br \><br \>\
				本插件是支持\
				<a target="_blank" href="https://github.com/shadowsocks/shadowsocks-libev"><u>SS</u></a>\
				、<a target="_blank" href="https://github.com/shadowsocksrr/shadowsocksr-libev"><u>SSR</u></a>\
				、<a target="_blank" href="https://github.com/v2ray/v2ray-core"><u>V2ray</u></a>\
				、<a target="_blank" href="https://github.com/XTLS/xray-core"><u>Xray</u></a>\
				、<a target="_blank" href="https://github.com/trojan-gfw/trojan"><u>Trojan</u></a>\
				、<a target="_blank" href="https://github.com/klzgrad/naiveproxy"><u>NaïveProxy</u></a>\
				、<a target="_blank" href="https://github.com/EAimTY/tuic"><u>tuic</u></a>\
				七种客户端的科学上网、游戏加速工具。<br \><br \>\
				本插件支持以Asuswrt、Asuswrt-Merlin为基础的，带软件中心的固件，目前固件均由<a style="color:#e7bd16" target="_blank" href="https://www.koolcenter.com/">https:\/\/www.koolcenter.com/</a>提供。<br \><br \>\
				使用本插件有任何问题，可以前往<a style="color:#e7bd16" target="_blank" href="https://github.com/hq450/fancyss/issues"><u>github的issue页面</u></a>反馈~<br \><br \>\
				● 插件交流：<a style="color:#e7bd16" target="_blank" href="https://t.me/joinchat/AAAAAEC7pgV9vPdPcJ4dJw"><u>加入telegram群组</u></a><br \><br \>\
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
			maxmin: true,
			content: '你尚未添加任何节点信息！<br /> 点击下面按钮添加节点信息！',
			btn: ['手动添加', '订阅节点', '恢复配置'],
			btn1: function() {
				$("#add_ss_node").trigger("click");
				layer.closeAll();
			},
			btn2: function() {
				$("#show_btn7").trigger("click");
			},
			btn3: function() {
				$("#show_btn9").trigger("click");
			},
		});
		poped = 1;
	});
}
function compare(val1,val2){
	return val1-val2;
}
function compfilter(a, b){
	var c = {};
	for (var key in b) {
		if(a[key] && b[key] && a[key] == b[key]){
			continue;
		}else if(a[key] == undefined && (b[key] == "")){
			continue;
		}else{
			c[key] = b[key];
		}
	}
	return c;
}
function autoTextarea(elem, extra, maxHeight) {
	extra = extra || 0;
	var isFirefox = !!document.getBoxObjectFor || 'mozInnerScreenX' in window,
		isOpera = !!window.opera && !!window.opera.toString().indexOf('Opera'),
		addEvent = function(type, callback) {
			elem.addEventListener ?
				elem.addEventListener(type, callback, false) :
				elem.attachEvent('on' + type, callback);
		},
		getStyle = elem.currentStyle ? function(name) {
			var val = elem.currentStyle[name];

			if (name === 'height' && val.search(/px/i) !== 1) {
				var rect = elem.getBoundingClientRect();
				return rect.bottom - rect.top -
					parseFloat(getStyle('paddingTop')) -
					parseFloat(getStyle('paddingBottom')) + 'px';
			};

			return val;
		} : function(name) {
			return getComputedStyle(elem, null)[name];
		},
		minHeight = parseFloat(getStyle('height'));

	elem.style.resize = 'none';

	var change = function() {
		var scrollTop, height,
			padding = 0,
			style = elem.style;

		if (elem._length === elem.value.length) return;
		elem._length = elem.value.length;

		if (!isFirefox && !isOpera) {
			padding = parseInt(getStyle('paddingTop')) + parseInt(getStyle('paddingBottom'));
		};
		scrollTop = document.body.scrollTop || document.documentElement.scrollTop;

		elem.style.height = minHeight + 'px';
		if (elem.scrollHeight > minHeight) {
			if (maxHeight && elem.scrollHeight > maxHeight) {
				height = maxHeight - padding;
				style.overflowY = 'auto';
			} else {
				height = elem.scrollHeight - padding;
				style.overflowY = 'hidden';
			};
			style.height = height + extra + 'px';
			scrollTop += parseInt(style.height) - elem.currHeight;
			elem.currHeight = parseInt(style.height);
		};
	};
	addEvent('propertychange', change);
	addEvent('input', change);
	addEvent('focus', change);
	change();
}
function getNowFormatDate(s) {
	var date = new Date();
	var seperator1 = "-";
	var seperator2 = ":";
	var month = date.getMonth() + 1;
	var strDate = date.getDate();
	if (month >= 1 && month <= 9) {
		month = "0" + month;
	}
	if (strDate >= 0 && strDate <= 9) {
		strDate = "0" + strDate;
	}
	var currentdate = date.getFullYear() + seperator1 + month + seperator1 + strDate + " " + date.getHours() + seperator2 + date.getMinutes() + seperator2 + date.getSeconds() + seperator1 + date.getMilliseconds();
	console.log(s, currentdate);
}
function menu_hook() {
	tabtitle[tabtitle.length - 1] = new Array("", "科学上网设置", "负载均衡设置", "Socks5设置", "__INHERIT__");
	tablink[tablink.length - 1] = new Array("", "Module_shadowsocks.asp", "Module_shadowsocks_lb.asp", "Module_shadowsocks_local.asp", "NULL");
}
function versionCompare(v1, v2, options) {
	var lexicographical = options && options.lexicographical,
		zeroExtend = options && options.zeroExtend,
		v1parts = v1.split('.'),
		v2parts = v2.split('.');
	function isValidPart(x) {
		return (lexicographical ? /^\d+[A-Za-z]*$/ : /^\d+$/).test(x);
	}
	if (!v1parts.every(isValidPart) || !v2parts.every(isValidPart)) {
		return NaN;
	}
	if (zeroExtend) {
		while (v1parts.length < v2parts.length) v1parts.push("0");
		while (v2parts.length < v1parts.length) v2parts.push("0");
	}
	if (!lexicographical) {
		v1parts = v1parts.map(Number);
		v2parts = v2parts.map(Number);
	}
	for (var i = 0; i < v1parts.length; ++i) {
		if (v2parts.length == i) {
			return true;
		}
		if (v1parts[i] == v2parts[i]) {
			continue;
		} else if (v1parts[i] > v2parts[i]) {
			return true;
		} else {
			return false;
		}
	}
	if (v1parts.length != v2parts.length) {
		return false;
	}
	return false;
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
}
function showSSLoadingBar(seconds) {
	if (window.scrollTo)
		window.scrollTo(0, 0);

	disableCheckChangedStatus();

	htmlbodyforIE = document.getElementsByTagName("html"); //this both for IE&FF, use "html" but not "body" because <!DOCTYPE html PUBLIC.......>
	htmlbodyforIE[0].style.overflow = "hidden"; //hidden the Y-scrollbar for preventing from user scroll it.

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

	if (document.documentElement && document.documentElement.clientHeight && document.documentElement.clientWidth) {
		winHeight = document.documentElement.clientHeight;
		winWidth = document.documentElement.clientWidth;
	}

	if (winWidth > 1050) {

		winPadding = (winWidth - 1050) / 2;
		winWidth = 1105;
		blockmarginLeft = (winWidth * 0.3) + winPadding - 150;
	} else if (winWidth <= 1050) {
		blockmarginLeft = (winWidth) * 0.3 + document.body.scrollLeft - 160;

	}

	if (winHeight > 660)
		winHeight = 660;

	blockmarginTop = winHeight * 0.3 - 140

	document.getElementById("loadingBarBlock").style.marginTop = blockmarginTop + "px";
	document.getElementById("loadingBarBlock").style.marginLeft = blockmarginLeft + "px";
	document.getElementById("loadingBarBlock").style.width = 770 + "px";
	document.getElementById("LoadingBar").style.width = winW + "px";
	document.getElementById("LoadingBar").style.height = winH + "px";

	loadingSeconds = seconds;
	progress = 100 / loadingSeconds;
	y = 0;
	LoadingSSProgress(seconds);
}

function LoadingSSProgress(seconds) {
	action = db_ss["ss_basic_action"];
	document.getElementById("LoadingBar").style.visibility = "visible";
	if (action == 0) {
		document.getElementById("loading_block3").innerHTML = "科学上网功能关闭中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'><a href='https://github.com/hq450/fancyss' target='_blank'></font>插件工作有问题？请到<em>GITHUB</em>提交issue...</font></li>");
	} else if (action == 1) {
		document.getElementById("loading_block3").innerHTML = "gfwlist模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>尝试不同的DNS解析方案，可以达到最佳的效果哦...</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
	} else if (action == 2) {
		document.getElementById("loading_block3").innerHTML = "大陆白名单模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
	} else if (action == 3) {
		document.getElementById("loading_block3").innerHTML = "游戏模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>为确保游戏工作，请确保你的SS账号支持UDP转发...</font></li><font color='#ffcc00'><li>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
	} else if (action == 5) {
		document.getElementById("loading_block3").innerHTML = "全局模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>此期间请勿访问屏蔽网址，以免污染DNS进入缓存</font></li><li><font color='#ffcc00'>此模式非科学上网方式，会影响国内网页速度...</font></li><li><font color='#ffcc00'>注意：全局模式并非VPN，只支持TCP流量转发...</font></li><li><font color='#ffcc00'>请等待日志显示完毕，并出现自动关闭按钮！</font></li><li><font color='#ffcc00'>在此期间请不要刷新本页面，不然可能导致问题！</font></li>");
	} else if (action == 6) {
		document.getElementById("loading_block3").innerHTML = "回国模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在应用配置...</font></li>");
	} else if (action == 7) {
		document.getElementById("loading_block3").innerHTML = "科学上网插件升级 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>升级服务会自动检测最新版本并下载升级...</font></li>");
	} else if (action == 8) {
		document.getElementById("loading_block3").innerHTML = "科学上网规则更新 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>正在自动检测github上的更新...</font></li>");
	} else if (action == 9) {
		document.getElementById("loading_block3").innerHTML = "恢复科学上网配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，配置恢复后需要重新提交！</font></li><li><font color='#ffcc00'>恢复配置中...</font></li>");
	} else if (action == 10) {
		document.getElementById("loading_block3").innerHTML = "清空科学上网配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在清空科学上网配置...</font></li>");
	} else if (action == 11) {
		document.getElementById("loading_block3").innerHTML = "插件打包中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>打包时间较长，请稍等...</font></li><li><font color='#ffcc00'>打包的插件可以用于离线安装...</font></li>");
	} else if (action == 12) {
		document.getElementById("loading_block3").innerHTML = "应用负载均衡设置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用负载均衡设置 ...</font></li>");
	} else if (action == 13) {
		document.getElementById("loading_block3").innerHTML = "SSR节点订阅 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在订阅中 ...</font></li>");
	} else if (action == 14) {
		document.getElementById("loading_block3").innerHTML = "socks5代理设置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用中 ...</font></li>");
	} else if (action == 15) {
		document.getElementById("loading_block3").innerHTML = "V2Ray 二进制文件更新 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，更新中 ...</font></li>");
	} else if (action == 16) {
		document.getElementById("loading_block3").innerHTML = "设置插件重启定时任务 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用中 ...</font></li>");
	} else if (action == 17) {
		document.getElementById("loading_block3").innerHTML = "设置插件触发重启定时任务 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用中 ...</font></li>");
	} else if (action == 18) {
		document.getElementById("loading_block3").innerHTML = "设置节点ping ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用中 ...</font></li>");
	} else if (action == 19) {
		document.getElementById("loading_block3").innerHTML = "设置故障转移 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，应用中 ...</font></li>");
	} else if (action == 20) {
		document.getElementById("loading_block3").innerHTML = "XRay 二进制文件更新 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，更新中 ...</font></li>");
	} else if (action == 21) {
		document.getElementById("loading_block3").innerHTML = "重启dnsmasq进程 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，重启中 ...</font></li>");
	} else if (action == 22) {
		document.getElementById("loading_block3").innerHTML = "保存smartdns配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，保存中 ...</font></li>");
	} else if (action == 23) {
		document.getElementById("loading_block3").innerHTML = "重置smartdns配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，重置中 ...</font></li>");
	} else if (action == 24) {
		document.getElementById("loading_block3").innerHTML = "清除dohclient缓存 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，清除中 ...</font></li>");
	}
}
function hideSSLoadingBar() {
	x = -1;
	E("LoadingBar").style.visibility = "hidden";
	checkss = 0;
	refreshpage();
}
function mOver(obj, hint){
	mouse_status = 1;
	//$("#overDiv").unbind('mouseout', function() { 
	//	E("overDiv").style.visibility = "hidden";
	//});
	$("#overDiv").unbind();
	$(obj).css({
		"color": "#00ffe4",
		"text-decoration": "underline"
	});
	openssHint(hint);
}
function mOut(obj){
	if (mouse_status == 1) return;
	if ($("#overDiv").is(":hover") == false){
		// close hint automaticly
		E("overDiv").style.visibility = "hidden";
	}else{
		// close hint whetn mounseout
		$("#overDiv").bind('mouseleave', function() {
			E("overDiv").style.visibility = "hidden";
		});
	}
}
function RunmOut(obj){
	$(obj).css({
		"color": "#03a9f4",
		"text-decoration": ""
	});
	setTimeout('mOut("' + obj + '");', 100);
}
function openssHint(itemNum) {
	statusmenu = "";
	width = "350px";
	mouse_status = 0;
	if (itemNum == 0) {
		width = "850px";
		bgcolor = "#CC0066",
			statusmenu = "<li>在路由器内部，通过httping，访问<a href='https://www.google.com.tw/' target='_blank'><u><font color='#00F'>www.google.com.tw</font></u></a>检测国外连接状态，访问<a href='https://www.baidu.com/' target='_blank'><u><font color='#00F'>www.baidu.com</font></u></a>检测国内连接状态，返回状态信息。然后默认在4000ms - 7000ms的区间内随机进行下一次检测，每次检测都会访问对应的检测网站，该访问不会进行下载整个网页，而仅仅请求HTTP头部，请求成功会返回√，请求失败会返回<font color='#FF0000'>X</font>，还会显示请求检测网站header的延迟，注意此延迟不是传统的icmp ping！</li>"
		statusmenu += "<br /><li>国内、国外状态检测的历史记录会显示在【故障转移】内的日志窗口，该日志记录会实时更新，且最新的一条记录即为插件顶部的【插件运行状态】；</li>"
		statusmenu += "<br /><li>状态检测反应的是路由器本身访问www.google.com.tw的结果，并不代表电脑或路由器下其它终端的访问结果，透过状态检测，可以为使用科学上网中遇到的一些问题进行排查,一下列举一些常见的情况：</li>"
		statusmenu += "<br /><b><font color='#CC0066'>1：双√，不能访问被墙网站：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.1：电脑DNS缓存：</font>可能你在未开启ss的时候访问过被墙域名，DNS缓存受到了污染，只需要简单的刷新下缓存，window电脑通过在CMD中运行命令：<font color='#669900'>ipconfig /flushdns</font>刷新电脑DNS缓存，手机端可以通过尝试开启飞行模式后关闭飞行模式刷新DNS缓存。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.2：电脑自定义DNS：</font>很多用户喜欢自己在电脑上定义DNS来使用，这样访问google等被墙网站，解析出来的域名基本都是污染的，因此建议将DNS解析改为自动获取。如果你的路由器很多人使用，你不能阻止别人自定义DNS，那么建议开启chromecast功能，路由器会将所有自定义的DNS劫持到自己的DNS服务器上，避免DNS污染。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1.3：电脑host：</font>电脑端以前设置过host翻墙，host翻墙失效快，DNS解析将通过host完成，不过路由器，如果host失效，使用chnroute翻墙的模式将无法使用；即使未失效，在gfwlist模式下，域名解析通过电脑host完成，而无法进入ipset，同样使得翻墙无法使用，因此强烈建议清除相关host！"
		statusmenu += "<br /><b><font color='#CC0066'>2：国内√，国外<font color='#FF0000'>X</font>：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.1：检查你的科学上网账号：</font>在电脑端用相应客户端检查是否正常；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.2：是否使用了域名：</font>一些机场提供的域名，特别是较为复杂的域名，可能有解析不了的问题，可尝试更换为IP地址，或者更换节点解析DNS；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.3：是否使用了含有特殊字符的密码：</font>极少数情况下，电脑端账号使用正常，路由端却<font color='#FF0000'>X</font>是因为使用了包含特殊字符的密码；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.4：尝试更换国外DNS：</font>此部分详细解析，请看DNS部分帮助文档；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.5：检查程序运行状态：</font>在本插件内点击【详细状态按钮】，可以看到当前程序运行状态，如果某个程序显示未运行，就会导致错误。尝试重启插件/重启路由器/添加虚拟内存等操作，也许可以解决此问题"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.5：检查iptables工作状态：</font>在本插件内点击【详细状态按钮】，可以看到当前iptables状态，如果某个iptables链下没有规则，就会导致错误，这可能是由于其它插件冲突导致的，包括但不限于系统防火墙、qos、其它插件！请关闭相应服务后，重启科学上网插件看是否恢复正常！"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.7：更新服务器端程序：</font>一些代理软件，由于更新后导致新旧版本不兼容，所以一半要求服务器端和客户端部署相同版本号的程序。如果你不希望更换路由器端主程序，可以更新最新服务器端来尝试解决问题，另外建议使用原版SS的朋友,在服务器端部署和路由器端相同版本的shadowsocks-libev；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.8：ntp时间问题：</font>如果你使用ssr或者V2ray，一些协议是需要验证服务器和路由器的时间的，如果时间相差太多，那么就会出现<font color='#FF0000'>X</font> 。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2.9：是否在插件内定义了错误格式的黑白名单</font>：如果定义的格式错误，会造成路由器dnsmasq无法启动，从而无法正常解析域名。点击【详细状态按钮】按钮能看到dnsmasq运行状态！"
		statusmenu += "<br /><b><font color='#CC0066'>3：双<font color='#FF0000'>X</font>：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>3.1：更换国内DNS：</font>在电脑端用SS客户端检查是否正常；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>3.2：逐项检查第2点中每个项目。</font>"
		statusmenu += "<br /><b><font color='#CC0066'>4：国内<font color='#FF0000'>X</font>，国外√：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>4.1：尝试更换国内DNS。</font>"
		statusmenu += "<br /><b><font color='#CC0066'>5：国外间歇性<font color='#FF0000'>X</font>：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>5.1：检查你的服务器ping和丢包：</font>一些线路可能在高峰期或者线路调整期，导致丢包过多，获取状态失败；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>5.2：如果是升级新版本科学上网插件后出现这种情况：</font>fancyss插件从2015年6月，其核心部分就基本无改动，升级新版本出现这种情况，最大可能的原因，新版本升级了最新的ss或者ssr的主程序，解决方法可以通过回滚路由器内程序，也可以升级你的服务器端到最新，如果你是自己搭建的用户,建议最新原版shadowsocks-libev程序。"
		statusmenu += "<br /><b><font color='#CC0066'>6：你遇到了非常少见的情况：</font></b>来这里反馈吧：<a href='https://telegram.me/joinchat/DCq55kC7pgWKX9J4cJ4dJw' target='_blank'><u><font color='#00F'>telegram</font></u></a>。"
		_caption = "状态检测";
	}
	if (itemNum == 1) {
		width = "700px";
		bgcolor = "#CC0066",
		statusmenu = "<span><b><font color='#CC0066'>【1】gfwlist模式:</font></b><br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;该模式使用gfwlist区分流量，Shadowsocks会将所有访问gfwlist内域名的TCP链接转发到Shadowsocks服务器，实现透明代理；<br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;和真正的gfwlist模式相比较，路由器内的gfwlist模式还是有一定缺点，因为它没法做到像gfwlist PAC文件一样，对某些域名的二级域名有例外规则。<br />"
		statusmenu += "<b><font color='#669900'>优点：</font></b>节省节点流量，可防止迅雷和PT流量。<br />"
		statusmenu += "<b><font color='#669900'>缺点：</font></b>代理受限于名单内的4000多个被墙网站，需要维护黑名单。一些不走域名解析的应用，比如telegram，需要单独添加IP/CIDR黑名单。</span><br /><br />"
		statusmenu += "<span><b><font color='#CC0066'>【2】大陆白名单模式:</font></b><br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;该模式使用chnroute IP网段区分国内外流量，ss-redir将流量转发到Shadowsocks服务器，实现透明代理；<br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;由于采用了预先定义的ip地址块(chnroute)，所以DNS解析就非常重要，如果一个国内有的网站被解析到了国外地址，那么这个国内网站是会走ss的；<br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;因为使用了大量的cdn名单，能够保证常用的国内网站都获得国内的解析结果，但是即使如此还是不能完全保证国内的一些网站解析到国内地址，这个时候就推荐使用具备cdn解析能力的cdns或者chinadns2。<br />"
		statusmenu += "<b><font color='#669900'>优点：</font></b>所有被墙国外网站均能通过代理访问，无需维护域名黑名单；主机玩家用此模式可以实现TCP代理UDP国内直连。<br />"
		statusmenu += "<b><font color='#669900'>缺点：</font></b>消耗更多的Shadowsocks流量，迅雷下载和BT可能消耗代理流量。</span><br /><br />"
		statusmenu += "<span><b><font color='#CC0066'>【3】游戏模式:</font></b><br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;游戏模式较于其它模式最大的特点就是支持UDP代理，能让游戏的UDP链接走代理，主机玩家用此模式可以实现TCP+UDP走代理；<br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;由于采用了预先定义的ip地址块(chnroute)，所以DNS解析就非常重要，如果一个国内有的网站被解析到了国外地址，那么这个国内网站是会走ss的。<br />"
		statusmenu += "<b><font color='#669900'>优点：</font></b>除了具有大陆白名单模式的优点外，还能代理UDP链接，并且实现主机游戏<b> NAT2!</b><br />"
		statusmenu += "<b><font color='#669900'>缺点：</font></b>由于UDP链接也走代理，而迅雷等BT下载多为UDP链接，如果下载资源的P2P链接中有国外链接，这部分流量就会走代理！</span><br /><br />"
		statusmenu += "<span><b><font color='#CC0066'>【4】全局模式:</font></b><br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;除局域网和ss服务器等流量不走代理，其它都走代理(udp不走)，高级设置中提供了对代理协议的选择。<br />"
		statusmenu += "<b><font color='#669900'>优点：</font></b>简单暴力，全部出国；可选仅web浏览走ss，还是全部tcp代理走ss，因为不需要区分国内外流量，因此性能最好。<br />"
		statusmenu += "<b><font color='#669900'>缺点：</font></b>国内网站全部走ss，迅雷下载和BT全部走代理流量。</span><br /><br />"
		statusmenu += "<span><b><font color='#CC0066'>【5】回国模式:</font></b><br />"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;提供给国外的朋友，通过在中间服务器翻回来，以享受一些视频、音乐等网络服务。<br />"
		statusmenu += "<b><font color='#669900'>提示：</font></b>回国模式选择外国DNS只能使用直连~<br />"
		_caption = "模式说明";
	} else if (itemNum == 6) {
		statusmenu = "此处选择你希望UDP的通道。<br />很多游戏都走udp的初衷就是加速udp连接。<br />如果你到vps的udp链接较快，可以选择udp in udp，如果你的运营商封锁了udp，可以选择udp in tcp。";
		_caption = "游戏模式V2 UDP通道";
	} else if (itemNum == 7) {
		statusmenu = "请注意：本设置<b>不是v2ray使用shadowsocks协议！</b>";
		statusmenu += "而是基于v2ray的<a href='https://www.v2ray.com/chapter_02/05_transport.html' target='_blank'><u><font color='#00F'>传输配置</font></u></a>作为SS的混淆方式。";
		statusmenu += "<br />因为v2ray-plugin与simple-obfs同为Shadowsocks <a href='https://github.com/shadowsocks/shadowsocks-org/wiki/Plugin' target='_blank'><font color='#00F'><u>SIP003插件</u></font></a>的实现，";
		statusmenu += "所以打开v2ray-plugin会<b>忽略原混淆(obfs)</b>的设置。";
		statusmenu += "<br />关于这个插件的信息以及参数(opts)，请查看仓库：<a href='https://github.com/shadowsocks/v2ray-plugin' target='_blank'><u><font color='#00F'>v2ray-plugin</font></u></a>";
		_caption = "v2ray-plugin设置";
	if (itemNum == 10) {
		statusmenu = "如果发现开关不能开启，那么请检查<a href='Advanced_System_Content.asp'><u><font color='#00F'>系统管理 -- 系统设置</font></u></a>页面内Enable JFFS custom scripts and configs是否开启。";
		_caption = "服务器说明";
	}
	} else if (itemNum == 11) {
		statusmenu = "如果不知道如何填写，请一定留空，不然可能带来副作用！"
		statusmenu += "<br /><br />请参考<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(8)'><font color='#00F'>协议插件（protocol）</font></a>和<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(9)'><font color='#00F'>混淆插件 (obfs)</font></a>内说明。"
		statusmenu += "<br /><br />更多信息，请参考<a href='https://github.com/koolshare/shadowsocks-rss/blob/master/ssr.md' target='_blank'><u><font color='#00F'>ShadowsocksR 协议插件文档</font></u></a>"
		_caption = "自定义参数 (obfs_param)";
	} else if (itemNum == 13) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;SSR表示shadowwocksR-libev，相比较原版shadowwocksR-libev，其提供了强大的协议混淆插件，让你避开gfw的侦测。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;虽然你在节点编辑界面能够指定使用SS的类型，不过这里还是提供了勾选使用SSR的选项，是为了方便一些服务器端是兼容原版协议的用户，快速切换SS账号类型而设定。";
		_caption = "使用SSR";
	} else if (itemNum == 15) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;点击右侧的铅笔图标，进入节点界面，在节点界面，你可以进行节点的添加，修改，删除，应用，检查节点ping，和web访问性等操作。"
		_caption = "选择节点";
	} else if (itemNum == 16) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处不同模式会显示不同的图标，如果你是从2.0以前的老版本升级过来的，可能有些节点不会显示图标，只需要编辑一下节点，选择好模式，然后保存即可显示。"
		_caption = "模式";
	} else if (itemNum == 17) {
		statusmenu = "节点名称支持中文，支持空格。"
		_caption = "节点名称";
	} else if (itemNum == 18) {
		statusmenu = "优先建议使用ip地址"
		_caption = "服务器地址";
	} else if (itemNum == 19) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;ping/丢包功能用于检测你的路由器到ss服务器的ping值和丢包；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;比如一些游戏线路对ping值和丢包有要求，可以选择ping值较低，丢包较少的节点；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;一些奇葩的运营商可能会禁ping，一些SS服务器也会禁止ping，此处检测就会failed，所以遇到这种情况不必惊恐。"
		_caption = "ping/丢包";
	} else if (itemNum == 21) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;编辑节点功能能帮助你快速的更改ss某个节点的设置，比如服务商更换IP地址之后，可以快速更改；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;编辑节点目前只支持相同类型节点的编辑，比如不能将ss节点编辑为ssr节点，如果你的ssr节点是兼容原版协议的，建议你在主面板用使用ssr勾选框来进行更改。"
		_caption = "编辑节点";
	} else if (itemNum == 22) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;删除节点功能能快速的删除某个特定的节点，为了方便快速删除，删除节点点击后生效，不会有是否确认弹出。"
		_caption = "编辑节点";
	} else if (itemNum == 23) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;点击使用节点能快速的将该节点填入主面板，但是你需要在主面板点击提交，才能使用该节点。<br />不同的颜色代表了不同的节点类型，SS：蓝色；SSR；粉色，V2：绿色"
		_caption = "使用节点";
	} else if (itemNum == 24) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;导出功能可以将ss所有的设置全部导出，包括节点信息，dns设定，黑白名单设定等；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;恢复配置功能可以使用之前导出的文件，也可以使用标准的json格式节点文件。"
		_caption = "导出恢复";
	} else if (itemNum == 26) {
		width = "1000px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;国外DNS为大家提供了丰富的选择，其目的有二，一是为了保证大家有能用的国外DNS服务；二是在有能用的基础上，能够选择多种DNS解析方案，达到最佳的解析效果；所以如果你切换到某个DNS程序，导致国外连接<font color='#FF0000'>X</font>， 那么更换能用的就好，不用纠结某个解析方案不能用。"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<br /><br />名词约定："
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1：</b>此模式以gfwlist为分流方式，如gfwlist模式";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2：</b>此模式以chnroute为分流方式，如大陆白名单模式、游戏模式";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>vps：</b>SS/SSR/V2ray服务器端";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<br /><br />各DNS方案做简单介绍："
		statusmenu += "<br /><font color='#CC0066'><b>dns2socks：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;万金油方案，DNS请求通过socks5隧道（由本地ss-local/ssr-local/v2ray提供）转发到vps，然后由vps向你定义的DNS服务器发起tcp dns解析请求，和下文中ss-tunnel类似，不过dns2socks是利用了socks5隧道代理，ss-tunnel是利用了加密UDP；该DNS方案不受到ss服务是否支持udp限制，只要能建立socoks5链接，就能使用。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1：</b>gfwlist.txt内的国外网站解析使用dns2socks，其余全部使用你选择的中国DNS解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2：</b>cdn.txt内的国内网站解析使用中国DNS，其余全部使用dns2socks。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>特点：</b>国外解析通过vps代为请求；模式2下由cdn.txt定义国内解析名单，对cpu负担稍大，建议使用dnsmasq-fastlookup。";
		statusmenu += "<br /><font color='#CC0066'><b>ss-tunnel：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;原理是将DNS请求通过ss-tunnel/ssr-tunnel利用udp协议发送到vps，然后由vps向你定义的DNS发起udp dns解析请求，解析到正确的IP地址，其解析效果和dns2socks应该是一样的。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1：</b>gfwlist.txt内的国外网站解析使用ss-tunnel，其余全部使用你选择的中国DNS解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2：</b>cdn.txt内的国内网站解析使用中国DNS，其余全部使用ss-tunnel。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>特点：</b>国外解析通过vps代为请求；模式2下由cdn.txt定义国内解析名单，对cpu负担稍大，建议使用dnsmasq-fastlookup。";
		statusmenu += "<br /><font color='#CC0066'><b>v2ray/xray_dns：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;v2ray/xray/trojan自带的dns，通过在v2ray/xray/trojan的json配置文件中添加一个新的传入连接来转发dns请求，使用效果应该和ss/ssr下使用ss-tunnel一样";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1：</b>gfwlist.txt内的国外网站解析使用v2ray_dns，其余全部使用你选择的中国DNS解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2：</b>cdn.txt内的国内网站解析使用中国DNS，其余全部使用v2ray_dns。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>特点：</b>国外解析通过vps代为请求；模式2下由cdn.txt定义国内解析名单，对cpu负担稍大，建议使用dnsmasq-fastlookup。";
		statusmenu += "<br /><font color='#CC0066'><b>SmartDNS：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;SmartDNS是一个运行在本地的DNS服务器，SmartDNS接受本地客户端的DNS查询请求，从多个上游DNS服务器获取DNS查询结果，并将访问速度最快的结果返回给客户端，提高网络访问速度。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;在本插件中，SmartDNS根据运行方式的不同，会生成不同的配置文件，简单的来说：SmartDNS的7913端口负责国外解析，SmartDNS的5335端口负责国内解析，具体如下。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1（仅中国DNS设定为SmartDNS）：</b>gfwlist.txt内的国外网站解析使用你选择的外国DNS方案，其余全部使用SmartDNS的5335端口解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1（仅外国DNS设定为SmartDNS）：</b>gfwlist.txt内的国外网站解析使用SmartDNS的7913端口解析，其余全部使用你选择的中国DNS解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式1（中国DNS和外国DNS均设定为SmartDNS）：</b>gfwlist.txt内的国外网站解析使用SmartDNS的7913端口解析，其余全部使用SmartDNS的5335端口解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2（仅中国DNS设定为SmartDNS）：</b>cdn.txt内的国内网站解析使用SmartDNS的5335端口解析，其余全部使用使用你选择外国DNS方案解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2（仅外国DNS设定为SmartDNS）：</b>cdn.txt内的国内网站解析使用你选择的中国DNS解析，其余全部使用SmartDNS的7913端口解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>模式2（中国DNS和外国DNS均设定为SmartDNS）：</b>cdn.txt内的国内网站解析使用SmartDNS的5335端口解析，其余全部使用SmartDNS的7913端口解析。";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>特点：</b>国外解析直连国外DNS服务器；模式2下由cdn.txt定义国内解析名单，对cpu负担稍大，建议使用dnsmasq-fastlookup。另外因为SmartDNS只会给出一个\"最优的\"解析结果，而可能对一些靠多个cdn解析同时连接下载加速的应用造成速度损失。";
		statusmenu += "<br /><font color='#CC0066'><b>直连：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;本地直接向DNS服务器请求获取国外网站的解析地址，目前此选项仅限于回国模式使用，因为在国外网络下查询国外DNS服务器不会有DNS污染。";
		_caption = "国外DNS";
	} else if (itemNum == 27) {
		statusmenu = "<br /><font color='#CC0066'><b>1:不勾选（自动生成json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式只支持vmess作为传出协议，不支持socks，shadowsocks，vless；提交后会根据你的配置自动生成v2ray的json配置。"
		statusmenu += "<br /><br /><font color='#CC0066'><b>3:勾选（自定义json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式支持配置v2ray支持的所有传出协议，包括vmess、vless、socks，shadowsocks等，插件会取你的json的outbound/outbounds部分，并自动配置透明代理和socks传进协议，以便在路由器上工作。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;如果使用Xray作为核心【附加功能处启用】，v2ray json配置方式还可以配置仅xray支持的协议，比如vless-tcp + xtls。"
		_caption = "使用json配置";
	}  else if (itemNum == 25) {
		statusmenu = "<br /><font color='#CC0066'><b>1:不勾选（自动生成json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式只支持vless作为传出协议，不支持socks、shadowsocks、vmess、trojan；提交后会根据你的配置自动生成xray的json配置，配置文件在/koolshare/ss/xray.json。"
		statusmenu += "<br /><br /><font color='#CC0066'><b>3:勾选（自定义json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式支持配置xray支持的所有传出协议，包括vmess、vless、socks、shadowsocks、trojan等协议，插件会取你的json的outbound/outbounds部分，并自动配置透明代理和socks传进协议，以便在路由器上工作。"
		_caption = "使用json配置";
	} else if (itemNum == 28) {
		width = "750px";
		statusmenu = "<b>如果客户端json配置文件内没有此项，此处请留空！</b>"
		statusmenu += "<br /><br /><font color='#CC0066'><b>1:传输协议tcp + 伪装类型http：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → tcpSettings → headers → Host】位置"
		statusmenu += "<br />&nbsp;&nbsp;如有多个域名，请用英文逗号隔开，如：www.baidu.com,www.sina.com.cn"
		statusmenu += "<br /><br /><font color='#CC0066'><b>2:传输协议ws：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → wsSettings → headers → Host】位置"
		statusmenu += "<br /><br /><font color='#CC0066'><b>3:传输协议h2：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → httpSettings → host】位置"
		statusmenu += "<br />&nbsp;&nbsp;如有多个域名，请用英文逗号隔开，如：www.baidu.com,www.sina.com.cn"
		statusmenu += "<br /><br /><font color='#CC0066'><b>4:传输协议quic：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → quicSettings → security】位置"
		statusmenu += "<br />&nbsp;&nbsp;如有多个域名，请用英文逗号隔开，如：www.baidu.com,www.sina.com.cn"
		_caption = "伪装域名 (host)";
	} else if (itemNum == 29) {
		width = "750px";
		statusmenu = "<b>如果客户端json配置文件内没有此项，此处请留空！</b><br /><br />path的设定应该和服务器端保持一致，值应该和你nginx或者candy的配置内的一致！"
		statusmenu += "<br /><br /><font color='#CC0066'><b>1:[tcp + http] path：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → tcpSettings → header → request → path】位置"
		statusmenu += "<br /><br /><font color='#CC0066'><b>2:ws path：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → wsSettings → path】位置"
		statusmenu += "<br /><br /><font color='#CC0066'><b>3:h2 path：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → httpSettings → path】位置"
		statusmenu += "<br /><br /><font color='#CC0066'><b>4:quic path：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;此参数在客户端json配置文件的【outbound/outbounds → streamSettings → quicSettings → key】位置"
		_caption = "路径 (path)";
	} else if (itemNum == 31) {
		width = "400px";
		statusmenu = "<b>此处控制开启或者关闭多路复用 (Mux)</b>"
		statusmenu += "<br /><br />此参数在客户端json配置文件的【outbound/outbounds → mux → enabled】位置"
		_caption = "多路复用 (Mux)";
	} else if (itemNum == 32) {
		width = "750px";
		statusmenu = "<b>控制Mux并发连接数，默认值：8，如果客户端json配置文件没有请留空</b>"
		statusmenu += "<br /><br />此参数在客户端json配置文件的【outbound/outbounds → mux → concurrency】位置，如果没有，请留空"
		_caption = "Mux并发连接数";
	} else if (itemNum == 33) {
		statusmenu = "填入需要强制用国内DNS解析的域名，一行一个，格式如下：。"
		statusmenu += "<br />注意：不支持通配符！"
		statusmenu += "<br /><br />koolshare.cn"
		statusmenu += "<br />baidu.com"
		statusmenu += "<br /><br />需要注意的是，这里要填写的一定是网站的一级域名，比如taobao.com才是正确的，www.taobao.com，http://www.taobao.com/这些格式都是错误的！"
		_caption = "自定义需要CDN加速网站";
	} else if (itemNum == 34) {
		statusmenu = "填入自定义的dnsmasq设置，一行一个，格式如下：。"
		statusmenu += "<br /><br />#例如hosts设置："
		statusmenu += "<br />address=/koolshare.cn/2.2.2.2"
		statusmenu += "<br /><br />#防DNS劫持设置"
		statusmenu += "<br />bogus-nxdomain=220.250.64.18"
		statusmenu += "<br /><br />#指定config设置"
		statusmenu += "<br />conf-file=/jffs/mydnsmasq.conf"
		statusmenu += "<br /><br />如果填入了错误的格式，可能导致dnsmasq启动失败！"
		statusmenu += "<br /><br />如果填入的信息里带有英文逗号的，也会导致dnsmasq启动失败！"
		_caption = "自定义dnsamsq";
	} else if (itemNum == 35) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings → network】位置"
		_caption = "传输协议 (network)";
	} else if (itemNum == 36) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings → tcpSettings → header → type】位置，如果没有此参数，则为不伪装"
		_caption = "tcp伪装类型 (type)";
	} else if (itemNum == 37) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings → kcpSettings → header → type】位置，如果参数为none，则为不伪装"
		_caption = "kcp伪装类型 (type)";
		return overlib(statusmenu, OFFSETX, -560, OFFSETY, -290, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
	} else if (itemNum == 38) {
		statusmenu = "填入不需要走代理的外网ip/cidr地址，一行一个，格式如下：。"
		statusmenu += "<br /><br />2.2.2.2"
		statusmenu += "<br />3.3.3.3"
		statusmenu += "<br />4.4.4.4/24"
		_caption = "IP/CIDR白名单";
	} else if (itemNum == 39) {
		statusmenu = "填入不需要走代理的域名，一行一个，格式如下：。"
		statusmenu += "<br /><br />google.com"
		statusmenu += "<br />facebook.com"
		statusmenu += "<br /><br />需要注意的是，这里要填写的一定是网站的一级域名，比如google.com才是正确的，www.google.com，https://www.google.com/这些格式都是错误的！"
		statusmenu += "<br /><br />需要清空电脑DNS缓存，才能立即看到效果"
		_caption = "域名白名单";
	} else if (itemNum == 40) {
		statusmenu = "填入需要强制走代理的外网ip/cidr地址，，一行一个，格式如下：。"
		statusmenu += "<br /><br />5.5.5.5"
		statusmenu += "<br />6.6.6.6"
		statusmenu += "<br />7.7.7.7/8"
		_caption = "IP/CIDR黑名单";
	} else if (itemNum == 41) {
		statusmenu = "填入需要强制走代理的域名，，一行一个，格式如下：。"
		statusmenu += "<br /><br />baidu.com"
		statusmenu += "<br />taobao.com"
		statusmenu += "<br /><br />需要注意的是，这里要填写的一定是网站的一级域名，比如google.com才是正确的，www.baidu.com，http://www.baidu.com/这些格式都是错误的！"
		statusmenu += "<br /><br />需要清空电脑DNS缓存，才能立即看到效果。"
		_caption = "IP/CIDR黑名单";
	} else if (itemNum == 44) {
		statusmenu = "shadowsocks规则更新包括了gfwlist模式中用到的<a href='https://github.com/hq450/fancyss/blob/master/rules/gfwlist.conf' target='_blank'><font color='#00F'><u>gfwlist</u></font></a>，在大陆白名单模式和游戏模式中用到的<a href='https://github.com/hq450/fancyss/blob/master/rules/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>和<a href='https://github.com/hq450/fancyss/blob/master/rules/cdn.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>"
		statusmenu += "<br />建议更新时间在凌晨闲时进行，以避免更新时重启ss服务器造成网络访问问题。"
		_caption = "shadowsocks规则自动更新";
	} else if (itemNum == 45) {
		statusmenu = "通过局域网客户端控制功能，你能定义在当前模式下某个局域网地址是否走SS。"
		_caption = "局域网客户端控制";
	} else if (itemNum == 46) {
		statusmenu = "一些用户的网络拨号可能比较滞后，为了保证SS在路由器开机后能正常启动，可以通过此功能，为ss的启动增加开机延迟。"
		_caption = "开机启动延迟";
	} else if (itemNum == 47) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → users → security】位置"
		_caption = "加密方式 (security)";
	} else if (itemNum == 48) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → users → alterId】位置"
		_caption = "额外ID (Alterld)";
	} else if (itemNum == 49) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → users → id】位置<br /><br />"
		_caption = "用户id (id)";
	} else if (itemNum == 50) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → port】位置"
		_caption = "端口（port）";
	} else if (itemNum == 51) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → address】位置"
		_caption = "地址（address）";
	} else if (itemNum == 54) {
		statusmenu = "更多信息，请参考<a href='https://breakwa11.blogspot.jp/2017/01/shadowsocksr-mu.html' target='_blank'><u><font color='#00F'>ShadowsocksR 协议参数文档</font></u></a>"
		_caption = "协议参数（protocol）";
	} else if (itemNum == 55) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → users → encryption】位置<br /><br />此参数仅用于Xray的VLESS协议，不过目前VLESS没有自带加密。所以目前都设置为none，请用于可靠信道，如 TLS。<br /><br />参考文档：<a href='https://xtls.github.io/config/outbounds/vless.html#outboundconfigurationobject' target='_blank'><font color='#00F'><u>https://xtls.github.io/config/outbounds/vless.html#outboundconfigurationobject</u></font></a>"
		_caption = "加密（encryption）";
	} else if (itemNum == 55) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → settings → vnext → users → flow】位置<br /><br />此参数仅用于Xray的VLESS协议，此处设置流控模式，用于选择 XTLS 的算法，仅在xtls开启后此处设置才会生效！。<br /><br />参考文档：<a href='https://xtls.github.io/config/outbounds/vless.html#outboundconfigurationobject' target='_blank'><font color='#00F'><u>https://xtls.github.io/config/outbounds/vless.html#outboundconfigurationobject</u></font></a>"
		_caption = "加密（encryption）";
	} else if (itemNum == 56) {
		width = "750px";
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings → tlsSettings】位置<br /><br />设置为false表示安全，true表示不安全。很多机场没有配置tls证书的，需要设置为true才能使得节点正常工作<br />"
		_caption = "加密（encryption）";
	} else if (itemNum == 90) {
		statusmenu = "此处设定为预设不可更改。<br />&nbsp;&nbsp;&nbsp;&nbsp;1. 单开KCPTUN的情况下，ss-redir的TCP流量都会转发到此；<br />&nbsp;&nbsp;&nbsp;&nbsp;2. KCPTUN和UDP2raw串联的模式下，ss-redir的TCP流量才会转发到UDP2raw；"
		_caption = "说明：";
	} else if (itemNum == 91) {
		width = "600px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;1. <b>单独加速：</b>此处配置为服务器ip+服务器端口(或者留空+服务器端口)，KCPTUN的UDP流量会转发给服务器；<br />&nbsp;&nbsp;&nbsp;&nbsp;2.  <b>串联1：</b>此处配置为127.0.0.1:1092（即UDPspeeder监听端口）时，可配置kcptun和UDPspeeder串联，KCPTUN的UDP流量会转发给UDPspeeder，然后转为tcp，并转发给服务器的UDP2raw。同时你需要在服务器端配置KCPTUN和UDP2raw的串联。<br />&nbsp;&nbsp;&nbsp;&nbsp;2.  <b>串联3：</b>此处配置为127.0.0.1:1093（即UDP2raw监听端口）时，可配置kcptun和udp2raw串联，KCPTUN的UDP流量会转发给UDP2raw，然后转为tcp，并转发给服务器的UDP2raw。同时你需要在服务器端配置KCPTUN和UDP2raw的串联。"
		_caption = "说明：";
	} else if (itemNum == 97) {
		width = "600px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;UDPspeeder(V1/V2)针对udp传输进行优化，能加速udp，降低udp的丢包，特别适合游戏。<br />&nbsp;&nbsp;&nbsp;&nbsp;UDP2raw可以将udp协议转为tcp，这对一些对udp有限制或者qos的情况特别好用，UDP2raw不是一个udp加速工具，如果需要udp加速，还需要配合UDPspeeder(V1/V2)串联使用。<br />&nbsp;&nbsp;&nbsp;&nbsp;正确开启的姿势是需要在服务器端配置UDPspeeder(V1/V2)/UDP2raw的服务器端程序，然后在路由器下，需要以下条件才能正常开启：<b><br />1. 当前正在使用游戏模式或者访问控制主机中有游戏模式主机；<br />2. 此处加速的节点和正在使用的节点一致；<br />3. 正确配置并开启UDPspeeder(V1/V2)或UDP2raw，或者两者都开启（串联模式）。</b>	 "
		_caption = "说明：";
	} else if (itemNum == 98) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处设定的MTU值将用于ss-redir/ssr-redir。<br />&nbsp;&nbsp;&nbsp;&nbsp;因为UDPspeeder(V1/V2)和UDP2raw对上游软件的MTU有要求，此处方便高级用户对其进行设定，以达到更好的UDP加速效果。不知道如何设定的请选择不设定，以免造成不必要的问题<br />&nbsp;&nbsp;&nbsp;&nbsp;此处的设定只有在UDPspeeder(V1/V2)/UDP2raw开启或者两者都开启的情况下才会生效。"
		_caption = "说明：";
	} else if (itemNum == 99) {
		statusmenu = "此处设定为预设不可更改。<br />&nbsp;&nbsp;&nbsp;&nbsp;1. 单开UDPspeeder(V1/V2)模式或者UDPspeeder(V1/V2)和UDP2raw双开（串联模式下），ss-redir的UDP流量都会转发到此；<br />&nbsp;&nbsp;&nbsp;&nbsp;2. 只有UDPepeeder未开启且UDP2raw开启的情况下，ss-redir的UDP流量才会转发到UDP2raw；"
		_caption = "说明：";
	} else if (itemNum == 100) {
		width = "600px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;1.单开UDPspeeder(V1/V2)模式下，ss-redir的udp流量经过UDPspeeder(V1/V2)加速后的UDP流量会转发到服务器，此处应按填写服务器的ip和服务器端UDPspeeder(V1/V2)的监听端口；<br />&nbsp;&nbsp;&nbsp;&nbsp;2.UDPspeeder(V1/V2)和UDP2raw双开（串联模式下），ss-redir的udp流量经过UDPspeeder(V1/V2)加速后的UDP流量会先转发给本地的UDP2raw程序，然后由UDP2raw和服务器的UDP2raw之间利用TCP（faketcp模式）协议进行通讯，然后服务器的UDP2raw收到TCP（faketcp模式）后还原为UDPspeeder(V1/V2)加速后的流量转发给服务器的UDPspeeder(V1/V2)，然后服务器的UDPspeeder(V1/V2)将此流量继续还原为ss-redir的UDP流量，转发给服务器的ss服务器程序。 所以路由器下UDPspeeder(V1/V2)和UDP2raw的串联也需要服务器端UDPspeeder(V1/V2)和UDP2raw的串联。"
		_caption = "说明：";
	} else if (itemNum == 101) {
		width = "600px";
		statusmenu = "此处设定为预设不可更改。<br />&nbsp;&nbsp;&nbsp;&nbsp;1.单开UDP2raw模式下，ss-redir的UDP流量会转发到此；<br />&nbsp;&nbsp;&nbsp;&nbsp;2.UDPspeeder(V1/V2)和UDP2raw双开（串联模式下），ss-redir的UDP流量会转发到UDPspeeder(V1/V2)，经过UDPspeeder(V1/V2)加速后的udp流量流量会转发到此（即转发到UDP2raw），形成UDPspeeder(V1/V2)和UDP2raw的串联。"
		_caption = "说明";
	} else if (itemNum == 102) {
		width = "600px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;1.单开udp2raw模式下，ss-redir的udp流量经过udp2raw转换为tcp后的流量会转发此处设置的到服务器端口，此处应按填写服务器的ip和服务器端UDPspeeder(V1/V2)的监听端口；<br />&nbsp;&nbsp;&nbsp;&nbsp;2.在UDPspeeder(V1/V2)和UDP2raw双开（串联模式下），ss-redir的udp流量经过UDPspeeder(V1/V2)加速后的UDP流量，经过udp2raw转换为tcp后的流量会转发此处设置的到服务器端口，此处应按填写服务器的ip和服务器端UDPspeeder(V1/V2)的监听端口；"
		_caption = "说明：";
	} else if (itemNum == 103) {
		width = "600px";
		statusmenu = "梅林固件推荐使用auto.<br />&nbsp;&nbsp;&nbsp;&nbsp;大部分udp2raw不能连通的情况都是设置了不兼容的iptables造成的。--lower-level选项允许绕过本地iptables。<br />&nbsp;&nbsp;&nbsp;&nbsp;虽然作者推荐merlin固件使用auto，但是merlin固件在某些拨号网络下可能无法通过--lower-level auto自动获取参数，而导致udp2raw启动失败，此时可以手动填写此处或者留空（实测留空也是可以工作的）"
		_caption = "说明：";
	} else if (itemNum == 104) {
		width = "600px";
		statusmenu = "<br />&nbsp;&nbsp;&nbsp;&nbsp;UDPspeeder有两个版本，V2是V1的升级版本，只有V2版才支持FEC；V1和V2版都支持多倍发包，V2通过配置FEC比例就能达到V1的多倍发包效果。<br />如果你只需要多倍发包，可以直接用V1版，V1版配置更简单，占用内存更小，而且经过了几个月的考验，很稳定。V2版在梅林固件下的消耗更高一些。"
		_caption = "说明：";
	} else if (itemNum == 105) {
		width = "600px";
		statusmenu = "<b>帮助信息：</b><br />dnsmasq配置文件里的ipset,address,server规则一多，路由器CPU使用率就上去了。<br />而现在gfwlist 5000+条server规则，5000+多条ipset规则！<br />而为了更好的国内解析效果，还引入了40000+条的server规则！<br />一旦访问网页，每次域名解析的时候，dnsmasq都会遍历这些名单，造成大量的cpu消耗！！<br />而改进版的dnsmasq，这里称dnsmasq-fastlookup，见原作者infinet帖<a href='https://www.v2ex.com/t/172010' target='_blank'><u><font color='#00F'>作者原帖</font></u></a><br />大概的意思就是原版的dnsmasq很慢（因为遍历查询方式）<br />而原作者infinet改的dnsmasq很快（因为hash查询方式）<br />可以大大的解放路由器cpu因dns查询带来的消耗！加快dns查询速度！<br />相关链接：<a href='https://github.com/infinet/dnsmasq' target='_blank'><u><font color='#00F'>dnsmasq-fastlookup源码</font></u></a>，<a href='http://koolshare.cn/thread-65484-1-1.html' target='_blank'><u><font color='#00F'>dnsmasq-fastlookup性能测试</font></u></a><br />-----------------------------------------------------------------------------------------<br />原先dnsmasq-fastlookup有问题可能会导致进程死掉，造成无法上网，而现在经过作者更新，已经相当稳定，故而添加此功能。<br />请根据自己实际需要选择替换方案~"
		_caption = "说明：";
	} else if (itemNum == 106) {
		width = "600px";
		statusmenu = "DNS重定向.<br />&nbsp;&nbsp;&nbsp;&nbsp;开启该功能后，局域网内所有客户端的udp 53端口的DNS解析请求将会被强制劫持（制劫持）到使用路由器提供的DNS进行解析，以避免DNS污染。<br />&nbsp;&nbsp;&nbsp;&nbsp;例如当局域网内有用户在电脑上自定义DNS解析服务器为8.8.8.8时候，该电脑向8.8.8.8的DNS请求，将会被强制劫持到路由器的dns服务器如：192.168.50.1。例如在启用了本插件后，局域网内的设备已经可以访问谷歌网站，但是如果设备请求到了污染的DNS，会导致该设备无法访问谷歌，所以当你无法控制局域网内一些设备自定义DNS行为的情况下，启用该功能可以保证局域网内所有客户端不会受到DNS污染。"
		_caption = "说明：";
	} else if (itemNum == 107) {
		width = "650px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;通常来说，代理节点服务器地址都是域名格式，在启用节点的时候需要对其进行解析，以获取正确的IP地址，此处可以定义用于节点域名解析的DNS。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;此处提供了udp查询进行服务器节点的解析。";
		statusmenu += "<br /><br /><font color='#00F'>关于自动选取模式：</font>：可以自定义在全部DNS服务器内自动选取，或者单独在国内组或者国外组进行自动选取。自动选取模式下会随机使用你定义组内的某个DNS服务器，如果解析成功，下次解析将默认使用该服务器。如果解析失败或超时（2s），则会自动切换到组内下一个DNS服务器！直到解析成功，或者将组内的DNS服务器全部使用一次！";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>1.</font>一些机场节点做了解析分流，因此建议国内使用插件选择国内组。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>2.</font>一些机场节点的域名托管在国外服务商，此时使用国外的DNS服务器效果可能更好。";
		_caption = "节点域名解析DNS服务器：";
	} else if (itemNum == 108) {
		statusmenu = "ss/ssr/trojan多核心支持.<br />&nbsp;&nbsp;&nbsp;&nbsp;开启后ss-redir/rss-redir/trojan将同时运行在路由器的全部核心上，最大化ss-redir/rss-redir/trojan的性能。注意：如果线路速度不存在瓶颈，可能使CPU全部核心满载，影响路由的稳定性。"
		_caption = "ss/ssr/trojan多核心支持：";
	} else if (itemNum == 109) {
		statusmenu = "插件触发重启设定说明：<br />&nbsp;&nbsp;&nbsp;&nbsp;当你的ss/ssr/koolgame/v2ray服务器，或者负载均衡服务器节点使用域名的时候，可以在此处设定定时解析域名时间，当检测到相应的解析地址发生改变的时候，定时任务会自动重启插件，以应用新的ip地址。<br />&nbsp;&nbsp;&nbsp;&nbsp;服务器有多个解析地址的建议不要使用！！v2ray开了cdn的也建议不要使用！！因为这可能会导致每次检测到的ip都不一样而让插件在后台频繁重启！"
		_caption = "说明：";
	} else if (itemNum == 110) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;匹配节点名称和节点域名/IP，含关键词的节点不会添加，多个关键词用<font color='#00F'>英文逗号</font>分隔，关键词支持中文、英文、数字，如：<font color='#CC0066'>测试,过期,剩余,曼谷,M247,D01,硅谷</font><br />&nbsp;&nbsp;&nbsp;&nbsp;此功能支持SS/SSR/V2ray/Xray订阅，<font color='#00F'>[排除]关键词</font>功能和<font color='#00F'>[包括]关键词</font>功能同时起作用。"
		_caption = "[排除]关键词：";
	} else if (itemNum == 111) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;匹配节点名称和节点域名/IP，含关键词的节点才会添加，多个关键词用<font color='#00F'>英文逗号</font>分隔，关键词支持中文、英文、数字，如：<font color='#CC0066'>香港,深圳,NF,BGP</font><br />&nbsp;&nbsp;&nbsp;&nbsp;此功能支持SS/SSR/V2ray/Xray订阅，<font color='#00F'>[排除]关键词</font>功能和<font color='#00F'>[包括]关键词</font>功能同时起作用。"
		_caption = "[包括]关键词：";
	} else if (itemNum == 113) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;新订阅方式，成功获取远程节点后，先一次性删除本地订阅节点，然后再一次性写入远程节点。<br /><br /><b>优点：</b>因一次性写入，不需要做交叉对比，所以订阅速度快，且节点不会乱序。<br /><br /><b>缺点：</b>订阅信息较少，不知道订阅前后是否有节点变化！"
		_caption = "快速订阅";
	} else if (itemNum == 114) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;<a href='https://github.com/XTLS/Xray-core' target='_blank'><u><font color='#00F'>Xray-core</font></u></a> 是 v2ray-core 的超集，含更好的整体性能和 XTLS 等一系列增强，且完全兼容 v2ray-core 的功能及配置。<br /><br />1. 你可以用Xray-core跑所有的vmess和vless节点<br />2. 使用Xray-core你还可以配置VLESS-TCP + XTLS节点，这点V2ray无法做到。<br />3. 如果你的vmess节点不工作，也可以尝试使用Xray核心。"
		_caption = "说明";
	} else if (itemNum == 115) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;一般来说你用不到这个选项，但是如果你的xray进程不稳定，你可以尝试开启此功能，此功能使用perp实时守护进程！。"
		_caption = "说明";
	} else if (itemNum == 116) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处填入你的机场订阅链接，通常是http://或https://开头的链接，多个链接可以分行填写！<br />&nbsp;&nbsp;&nbsp;&nbsp;也可以增加非http开头的行作为注释，或使用空行或者符号线作为分割，订阅脚本仅会提取http://或https://开头的链接用以订阅，示例：<br />-------------------------------------------------<br />🚀魅影极速<br />https://subserver.maying.io/xxx<br /><br />🛩️nextitally<br />https://naixisubs.com/downloadConfig/xxx<br />-------------------------------------------------"
		_caption = "订阅地址管理";
	} else if (itemNum == 117) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;使用此方式添加节点不会和已有节点进行对比，多次使用相同链接会让相同节点被添加多次，请注意！";
		_caption = "通过ss/ssr/vmess/vless链接添加节点";
	} else if (itemNum == 118) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;勾选此选项将会用shadowsocks-rust替换shadowsocks-libev！";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>注意1：</b>fancyss插件包默认不提供shadowsocks-rust的二进制文件，所以你需要点击右侧按钮下载shadowsocks-rust二进制文件！";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<b>注意2：</b>shadowsocks-rust支持的加密方式如下：plain, none, aes-128-gcm, aes-256-gcm, chacha20-ietf-poly1305, 2022-blake3-aes-128-gcm, 2022-blake3-aes-256-gcm, 2022-blake3-chacha20-poly1305";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;如果你使用的节点不是这些加密方式，那改节点肯定会出现工作异常！";
		_caption = "用shadowsocks-rust替代shadowsocks-libev";
	} else if (itemNum == 119) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;Xray-core是支持trojan协议的，所以trojan节点不仅可以用trojan程序来运行，还能用Xray核心来运行";
		_caption = "说明";
	} else if (itemNum == 120) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;一些trojan机场节点需要允许不安全才能正常工作，但是其节点订阅却没有指定允许不安全，此时可以开启此处，开启后会强制所有trojan节点允许不安全";
		_caption = "说明";
	} else if (itemNum == 121) {
		width = "650px";
		statusmenu = "&nbsp;&nbsp;自动选取模式下会随机请求列表里的某个DNS服务器，如果解析成功，下次解析将默认使用该服务器。";
		statusmenu += "<br /><br />&nbsp;&nbsp;如果解析失败或超时（2s），则会自动切换域名列表里的下一个DNS服务器！直到解析成功，或者将列表里的所有DNS使用一轮！当然你也可指定一个DNS，或者自定义一个支持udp协议查询的DNS用于节点域名的解析";
		statusmenu += "<br /><br />&nbsp;&nbsp;目前用于节点域名解析的DNS列表包含了国内外主流DNS服务器，如下：";
		statusmenu += "<br />";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;运营商DNS-1（空则使用223.5.5.5）";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;运营商DNS-2（空则使用运营商DNS-1）";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;阿里DNS【223.5.5.5】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;阿里DNS【223.6.6.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;114DNS【114.114.114.114】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;114DNS【114.114.115.115】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;cnnic DNS【1.2.4.8】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;cnnic DNS【210.2.4.8】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OneDNS【117.50.11.11】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OneDNS【52.80.66.66】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNSPod DNS【119.29.29.29】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNSPod DNS【119.28.28.28】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;百度DNS【180.76.76.76】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 电信/铁通/移动【101.226.4.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 电信/铁通/移动【218.30.118.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 联通【123.125.81.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 联通【140.207.198.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;google DNS【8.8.8.8】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;google DNS【8.8.4.4】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;IBM DNS【9.9.9.9】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;CloudFlare DNS【1.1.1.1】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;CloudFlare DNS【1.0.0.1】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OpenDNS【208.67.222.222:5353】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OpenDNS【208.67.222.220】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNS.SB【45.11.45.11】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;quad101 【101.101.101.101】";
		_caption = "说明";
	} else if (itemNum == 122) {
		width = "450px";
		statusmenu = "&nbsp;&nbsp;<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>类似于ChinaDNS，不过使用 DoH 作为上游服务器，同时还支持udp、tcp查询。<br /><br />";
		statusmenu += "&nbsp;&nbsp;dohclient自带DNS分流，和ChinaDNS一样，可以指定一个国内上游DNS服务器和一个国外DNS服务器，并使用大陆IP地址段（chnroute.txt）进行分流。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意：</font>如果你的网络环境udp查询效果不佳（udp差的大内网，上游限制等情况），可尝试更改为tcp或DoH查询，以规避udp被屏蔽、丢包、被QoS等情况。<br /><br />";
		_caption = "dohclient：";
	} else if (itemNum == 123) {
		width = "650px";
		statusmenu = "ECS，即edns-client-subnet，<a href='https://taoshu.in/dns/edns-client-subnet.html' target='_blank'><u><font color='#00F'>ECS简介</font></u></a><br /><br />";
		statusmenu += "&nbsp;&nbsp;勾选此ECS开关后，国内的DNS查询将会附加ECS标签，服务器会根据ECS标签里的网段信息，返回较近的解析IP地址，所以此处开启ECS后，国内的DNS查询CDN效果理论上会更好！<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了在DNS查询时附件上ECS信息，插件开启过程中会检测本机的国内公网出口IPV4地址，并用此地址作为ECS信息。为了避免用户准确的IP地址信息隐私泄露，插件默认情况下会将ip地址最后一位处理为0，同时使用24作为掩码来规避此情况。比如你的代理服务器出口IP地址为：1.1.1.1，那么查询时候会处理成：1.1.1.0/24，这对于DNS查询要求的地理信息精度已经完全够用，事实上，一部分支持ECS的DNS服务器强制要求掩码不能超过24。<br /><br />";
		statusmenu += "本插件使用了明显的标志符号标注了各个DNS服务器对ECS的支持情况，具体如下（具体支持情况请使用<font color='#F00'>【DNS解析测试(dig)】</font>功能检测）：<br />";
		statusmenu += "🟠 代表该DNS服务器支持ECS，域名查询结果都会正常返回ECS标签；<br />";
		statusmenu += "⚫ 代表该DNS服务器不支持ECS，域名查询结果不会有ECS标签返回；<br />";
		_caption = "ECS说明：";
	} else if (itemNum == 124) {
		width = "450px";
		statusmenu = "&nbsp;&nbsp;<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>类似于ChinaDNS，不过使用 DoH 作为上游服务器，同时还支持tcp查询。<br /><br />";
		statusmenu += "&nbsp;&nbsp;dohclient自带DNS分流，和ChinaDNS一样，可以指定一个国内上游DNS服务器和一个国外DNS服务器，并使用大陆IP地址段（chnroute.txt）进行分流。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意：</font>因国外udp查询无法强制使用代理，所以查询结果存在污染，故没有开放国外udp查询选项！<br /><br />";
		_caption = "dohclient：";
	} else if (itemNum == 125) {
		width = "650px";
		statusmenu = "ECS，即edns-client-subnet，<a href='https://taoshu.in/dns/edns-client-subnet.html' target='_blank'><u><font color='#00F'>ECS简介</font></u></a><br /><br />";
		statusmenu += "&nbsp;&nbsp;勾选此ECS开关后，国外的DNS查询将会附加ECS标签，DNS服务器会根据ECS标签里的网段信息返回较近的解析IP地址，所以此处开启ECS后，国外的DNS查询CDN效果理论上会更好！<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了在DNS查询时附件上ECS信息，插件开启过程中会检测本机的国外出口公网IPV4地址（检测代理服务器出口地址），并用此地址作为ECS信息。为了避免用户准确的IP地址信息隐私泄露，插件默认情况下会将ip地址最后一位处理为0，同时使用24作为掩码来规避此情况。比如你的代理服务器出口IP地址为：1.1.1.1，那么查询时候会处理成：1.1.1.0/24，这对于DNS查询要求的地理信息精度已经完全够用，事实上，一部分支持ECS的DNS服务器强制要求掩码不能超过24。<br /><br />";
		statusmenu += "&nbsp;&nbsp;成功开启ECS后，你可以使用本插件的<font color='#F00'>【DNS解析测试(dig)】</font>功能来查询国外域名，如果上游DNS支持ECS，且ECS开启成功则返回的查询结果中会带有ECS信息，比如返回的CLIENT-SUBNET字段会带有国外出口公网IPV4网段信息。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意1：</font>如果代理服务器出口地址检测失败，国外DNS的ECS将会强制关闭，即使ECS开关处于勾选状态！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意2：</font>部分DoH DNS服务尚未提供ECS支持，比如Cloudflare，不支持ECS的DNS查询的结果不带ECS标签，但是不会影响域名解析！<br /><br />";
		statusmenu += "本插件使用了明显的标志符号标注了各个DNS服务器对ECS的支持情况，具体如下：<br />";
		statusmenu += "🟠 代表该DNS服务器支持ECS，域名查询结果都会正常返回ECS标签；<br />";
		statusmenu += "⚫ 代表该DNS服务器不支持ECS，域名查询结果不会有ECS标签返回；<br />";
		statusmenu += "🟡 代表该DNS服务器对部分域名查询支持ECS，部分域名查询不支持ECS，比如AdGuard；<br />";
		_caption = "ECS说明：";
	} else if (itemNum == 126) {
		width = "450px";
		statusmenu = "勾选此处后，国外的DNS查询将会强制使用本插件23456端口的socks5代理进行！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意1：</font>在国内环境下，因gfw屏蔽等原因，除了部分国外DNS服务器可以直连解析，其它服务器均需要使用代理（勾选Proxy）才能正常使用！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意2：</font>即使部分DoH DNS服务器可以直连解析，也不能完全保证不丢包！所以建议全程勾选Proxy开关，除非你有特殊的要求！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意3：</font>通过dohclient进行tcp协议的国外DNS查询，同样建议勾选Proxy，以规避屏蔽、丢包等情况！<br /><br />";
		_caption = "Proxy说明：";
	} else if (itemNum == 127) {
		statusmenu = "缓存时长<br /><br />";
		statusmenu += "&nbsp;&nbsp;dohclient自带了DNS缓存数据库功能，能将DNS查询结果缓存到本地，缓存文件位于/tmp/doh_main.db，选择不同的缓存策略可以获得不同的解析速度体验。<br /><br />";
		statusmenu += "&nbsp;&nbsp;如果不知道如何选择，请保持默认，即【跟随TTL】；选择过高的缓存时长可能或导致长时间后，部分网站/服务的解析地址发生改变，但是本地无法得到更新的情况。<br /><br />";
		_caption = "缓存时长说明：";
	} else if (itemNum == 128) {
		width = "450px";
		statusmenu = "&nbsp;&nbsp;缓存持久化并非dohclient自带的功能，而是fancyss插件附加功能，该功能让用户决定在插件重启时是否重建缓存。<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#CC0066'>不勾选：</font>重启插件、更换节点等操作都会删除本地的缓存文件/tmp/doh_main.db，重启完成后重建全新的缓存。<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#CC0066'>勾选：</font>重启插件、更换节点等操作都会保留本地的dohclient缓存文件，重启完成后可以使用之前的缓存。<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#00F'>说明1：</font>如果你长期使用相同的代理节点，或者相近的节点（比如都是香港节点），可以考虑勾选。<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#00F'>说明2：</font>如果你使用较多的不同节点，且节点属地不一致，建议不勾选，不然不同节点下使用相同的缓存可能会导致CDN失效！<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#00F'>说明3：</font>如果使用不同节点观看Netflix等流媒体，同样不建议勾选！<br /><br />";
		statusmenu += "&nbsp;&nbsp;<font color='#00F'>说明4：</font>不论勾选与否，重启路由器后缓存都会丢失，插件开启后会重建全新缓存！<br /><br />";
		_caption = "缓存持久化：";
	} else if (itemNum == 129) {
		width = "650px";
		statusmenu = "&nbsp;&nbsp;自动选取模式下会随机请求列表里的某个DNS服务器，如果解析成功，下次解析将默认使用该服务器。";
		statusmenu += "<br /><br />&nbsp;&nbsp;如果解析失败或超时（2s），则会自动切换域名列表里的下一个DNS服务器！直到解析成功，或者将列表里的所有DNS使用一轮！当然你也可指定一个DNS，或者自定义一个支持tcp协议查询的DNS用于节点域名的解析";
		statusmenu += "<br /><br />&nbsp;&nbsp;目前用于节点域名解析的DNS列表包含了国内外主流支持tcp解析的DNS服务器，如下：";
		statusmenu += "<br />";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;阿里DNS【223.5.5.5】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;阿里DNS【223.6.6.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;114DNS【114.114.114.114】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;114DNS【114.114.115.115】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNSPod DNS【119.29.29.29】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNSPod DNS【119.28.28.28】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 电信/铁通/移动【218.30.118.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 联通【123.125.81.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;360DNS 联通【140.207.198.6】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;google DNS【8.8.8.8】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;google DNS【8.8.4.4】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;IBM DNS【9.9.9.9】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;CloudFlare DNS【1.1.1.1】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;CloudFlare DNS【1.0.0.1】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OpenDNS【208.67.222.222:5353】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;OpenDNS【208.67.222.220】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;DNS.SB【45.11.45.11】";
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;quad101 【101.101.101.101】";
		_caption = "说明";
	} else if (itemNum == 130) {
		// 中国DNS-1，中国DNS-2：ecs
		width = "650px";
		statusmenu = "ECS，即edns-client-subnet，<a href='https://taoshu.in/dns/edns-client-subnet.html' target='_blank'><u><font color='#00F'>ECS简介</font></u></a><br /><br />";
		statusmenu += "&nbsp;&nbsp;勾选此ECS开关后，此处中国的DNS的DNS查询将会附加ECS标签，DNS服务器会根据ECS标签里的网段信息返回较近的解析IP地址，所以在使用公共DNS服务的时候开启ECS，国内的DNS查询CDN效果理论上会更好！<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了在DNS查询时附件上ECS信息，插件开启过程中会检测本机的国内出口公网IPV4地址，并用此地址作为ECS信息。为了避免用户准确的IP地址信息隐私泄露，插件默认情况下会将ip地址最后一位处理为0，同时使用24作为掩码来规避此情况。比如你的IP地址为：110.110.110.110，那么查询时候会处理成：110.110.110.0/24，这对于DNS查询要求的地理信息精度已经完全够用，事实上，一部分支持ECS的DNS服务器强制要求掩码不能超过24。<br /><br />";
		statusmenu += "&nbsp;&nbsp;成功开启ECS后，你可以使用本插件的<font color='#F00'>【DNS解析测试(dig)】</font>功能来查询国内域名，如果上游DNS支持ECS，且ECS开启成功，则返回的查询结果中会带有ECS信息，比如返回结果的CLIENT-SUBNET字段会带有国内出口公网IPV4网段信息。<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了实现支持ECS的DNS查询，udp DNS查询使用了dns-ecs-forcer程序，其来自rampageX的开源项目：<a href='https://github.com/rampageX/DEF' target='_blank'><u><font color='#00F'>DEF</font></u></a>；tcp DNS查询使用了dns-ecs-forcer加dns2tcp两个程序，dns2tcp来自zfl9的开源项目：<a href='https://github.com/zfl9/dns2tcp' target='_blank'><u><font color='#00F'>dns2tcp</font></u></a>；DoH DNS查询使用了dohclient程序，其来自GangZhuo的开源项目：<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>。<br />";
		statusmenu += "&nbsp;&nbsp;在此感谢以上作者的开源贡献！。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意1：</font>并不是所有的上游DNS服务器都支持ECS！比如运营商DNS等，具体支持情况请用【DNS解析测试(dig)】查询国内域名测试。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意2：</font>对不支持ECS的DNS，勾选上ECS也不会有负面影响，仅仅是查询的结果将不会返回ECS信息，但是不会影响域名正常解析！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意3：</font>由于目前smartdns对于ECS的支持并不是很好，所以不论是udp、tcp还是DoH协议下，选择smartdns都不支持ECS！<br /><br />";
		statusmenu += "本插件使用了明显的标志符号标注了各个DNS服务器对ECS的支持情况，具体如下：<br />";
		statusmenu += "🟠 代表该DNS服务器支持ECS，域名查询结果都会正常返回ECS标签；<br />";
		statusmenu += "⚫ 代表该DNS服务器不支持ECS，域名查询结果不会有ECS标签返回；<br />";
		statusmenu += "⚪ 代表该DNS服务器对ECS的支持不确定，一般来说运营商DNS都不支持ECS，自定义DNS随情况而定<br /><br />";
		_caption = "ECS说明：";
	} else if (itemNum == 131) {
		// 可信DNS-1 ecs
		width = "650px";
		statusmenu = "ECS，即edns-client-subnet，<a href='https://taoshu.in/dns/edns-client-subnet.html' target='_blank'><u><font color='#00F'>ECS简介</font></u></a><br /><br />";
		statusmenu += "&nbsp;&nbsp;勾选此ECS开关后，此处可信DNS-1的DNS查询将会附加ECS标签，DNS服务器会根据ECS标签里的网段信息返回较近的解析IP地址，所以在使用国外可信DNS的时候开启ECS，国外的CDN效果理论上会更好！<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了在DNS查询时附件上ECS信息，插件开启过程中会检测本机的国外出口公网IPV4地址（即检测代理服务器出口地址），并用此地址作为ECS信息。为了避免用户准确的IP地址信息隐私泄露，插件默认情况下会将ip地址最后一位处理为0，同时使用24作为掩码来规避此情况。比如你的代理服务器出口IP地址为：1.1.1.1，那么查询时候会处理成：1.1.1.0/24，这对于DNS查询要求的地理信息精度已经完全够用，事实上，一部分支持ECS的DNS服务器强制要求掩码不能超过24。<br /><br />";
		statusmenu += "&nbsp;&nbsp;成功开启ECS后，你可以使用本插件的<font color='#F00'>【DNS解析测试(dig)】</font>功能来查询国外域名，如果上游DNS支持ECS，且ECS开启成功则返回的查询结果中会带有ECS信息，比如返回的CLIENT-SUBNET字段会带有国外出口公网IPV4网段信息。<br /><br />";
		statusmenu += "&nbsp;&nbsp;为了实现支持ECS的DNS查询，dns2socks使用了支持ECS的V2.2版本；ss-tunnel和v2/xray_dns的DNS查询使用了dns-ecs-forcer程序，其来自rampageX的开源项目：<a href='https://github.com/rampageX/DEF' target='_blank'><u><font color='#00F'>DEF</font></u></a>；dohclient程序本身支持ECS，其来自GangZhuo的开源项目：<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>。<br />";
		statusmenu += "&nbsp;&nbsp;在此感谢以上作者的开源贡献！。<br /><br />";
		statusmenu += "<font color='#CC0066'>注意1：</font>如果代理服务器出口地址检测失败，可信DNS-1的ECS将会强制关闭，即使ECS开关处于勾选状态！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意2：</font>对不支持ECS的DNS，勾选上ECS也不会有负面影响，仅仅是查询的结果将不会返回ECS信息，但是不会影响域名正常解析！<br /><br />";
		statusmenu += "<font color='#CC0066'>注意3：</font>由于目前smartdns对于ECS的支持并不是很好，所以不论是udp、tcp还是DoH协议下，选择smartdns都不支持ECS！<br /><br />";
		statusmenu += "本插件使用了明显的标志符号标注了各个DNS服务器对ECS的支持情况，具体如下（具体支持情况请使用<font color='#F00'>【DNS解析测试(dig)】</font>功能检测）：<br />";
		statusmenu += "🟠 代表该DNS服务器支持ECS，域名查询结果都会正常返回ECS标签；<br />";
		statusmenu += "⚫ 代表该DNS服务器不支持ECS，域名查询结果不会有ECS标签返回；<br />";
		statusmenu += "🟡 代表该DNS服务器对部分域名查询支持ECS，部分域名查询不支持ECS，比如AdGuard；<br />";
		statusmenu += "⚪ 代表该DNS服务器对ECS的支持不确定，一般来说运营商DNS都不支持ECS，自定义DNS随情况而定<br /><br />";
		_caption = "ECS说明：";
	} else if (itemNum == 132) {
		// 可信DNS-2 ecs
		width = "650px";
		statusmenu = "可信DNS-2 (--trust-dns)的DNS全部是直连查询类型，而很多国外DNS服务器被国家防火墙屏蔽，这就导致了直连解析能用的DNS服务器比较少。<br /><br />";
		statusmenu += "<font color='#CC0066'>[直连] smartdns</font>：该smartdns定义了多组的DoH和DoT协议的上游DNS服务器，以保证可以获得国外域名的解析结果，由于目前smartdns对于ECS的支持并不是很好，所以不论是DoH还是DoT协议下，选择smartdns都不支持ECS！。<br /><br />";
		statusmenu += "<font color='#CC0066'>[直连] dohclient</font>：由于dohclient只能定义一个上游服务器，所以此处给出了几个没有被屏蔽的上游DoH服务器，遗憾的是这几个服务器都不支持ECS，不然改解析方案也可以获得较好的国外cdn效果，不过此处还是提供了ECS开关，是为未来也许可以新增支持能直连DoH，且支持ECS的服务器。<br /><br />";
		statusmenu += "<font color='#CC0066'>[直连] 原生udp</font>：直接使用udp协议，从本机（不经代理）向上级服务器发起DNS查询，不建议普通用户使用！由于国家防火墙具有的DNS抢答投毒机制，很难获得无污染的解析结果！但是也可能存在极少的非标准端口DNS，或者自己搭建的DNS服务器，可以获得无污染的解析结果。<br /><br />";
		statusmenu += "<font color='#CC0066'>[直连] 原生tcp</font>：直接使用tcp协议，从本机（不经代理）向上级服务器发起DNS查询，不建议普通用户使用！，由于国家防火墙会对很多DNS服务器TCP查询请求进行TCP阻断，所以能用的服务器也不多！也存在一些非标准端口的DNS，或者自己搭建的支持tcp解析的DNS是可用的。<br /><br />";
		statusmenu += "本插件使用了明显的标志符号标注了各个DNS服务器对ECS的支持情况，具体如下：<br />";
		statusmenu += "🟠 代表该DNS服务器支持ECS，域名查询结果都会正常返回ECS标签；<br />";
		statusmenu += "⚫ 代表该DNS服务器不支持ECS，域名查询结果不会有ECS标签返回；<br />";
		_caption = "ECS说明：";
	} else if (itemNum == 133) {
		// 中国DNS-1
		width = "780px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。";
		statusmenu += "chinadns-ng支持自定义两组中国和两组可信DNS，中国DNS用于解析中国域名，可信DNS用于解析境外域名，具体情况见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng的工作原理</font></u></a>。";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;在DNS进阶设定中，chinadns-ng方案开放了其两组中国和两组可信DNS的设定，并且在此基础上通过其它开源软件的协助，在chinadns的国内上游实现了tcp和DoH协议的DNS查询。具体如下：";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>udp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>chinadns-ng直接请求上游国内udp DNS服务器，获得解析结果，再经过chinadns-ng内部分流后给出结果。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng →  国内udp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns-ecs-forcer → 国内udp DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>tcp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用开源DNS工具<a href='https://github.com/zfl9/dns2tcp' target='_blank'><u><font color='#00F'>dns2tcp</font></u></a>，将DNS查询从udp模式转换为tcp模式，所以要求DNS服务器支持tcp查询。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dns2tcp → 国内tcp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns-ecs-forcer → dns2tcp → 国内tcp DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>DoH：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用开源程序<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>请求国内DoH DNS服务器，该程序支持DoH (dns over https) 协议下的DNS查询！<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient (ecs=0) → 国内DoH DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient (ecs=1) → 国内DoH DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;以上udp和tcp协议下的ECS支持由开源工具<a href='https://github.com/rampageX/DEF' target='_blank'><u><font color='#00F'>dns-ecs-forcer</font></u></a>程序实现。";
		statusmenu += "<br />";
		statusmenu += "--------------------------------------------------------------------------------------------------------------------";
		statusmenu += "<br />";
		statusmenu += "<div style='padding-left:16px;padding-right:16px'>";
		statusmenu += "1️⃣需要至少开启一组中国DNS，即选择中国DNS-1和选择中国DNS-2至少开启一个，也可以同时开启，且不能两组都使用同样的设定。<br /><br />";
		statusmenu += "2️⃣某些网络环境或运营商udp较差的情况，可以考虑使用tcp或者DoH协议，或者开一个udp协议作为基础，一个tcp或DoH协议作为保障，来保证国内DNS的正常解析。<br /><br />";
		statusmenu += "3️⃣通常来说，使用运营商DNS可以获得较好的DNS查询效果，当然也不是绝对的，因为使用公共DNS，如果配合ECS也可以获得很好的效果。<br /><br />";
		statusmenu += "4️⃣对于教育网环境，为了保证校内使用校园网资源的时候也获得教育网的ip解析结果，建议使用运营商DNS或者教育网DNS，也可以增加一个一个公共DNS配合使用。<br /><br />";
		statusmenu += "5️⃣DNS的选择没有绝对的最佳可言，适合自己的才是最好的，对于不懂如何选择的朋友，建议直接使用运营商DNS即可，无需纠结。<br /><br />";
		statusmenu += "</div>";
		_caption = "说明：";
		$("#overDiv_table5").css("line-height", "1.4");
	} else if (itemNum == 134) {
		width = "780px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。";
		statusmenu += "chinadns-ng支持自定义两组中国和两组可信DNS，中国DNS用于解析中国域名，可信DNS用于解析境外域名，具体情况见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng的工作原理</font></u></a>。";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;在DNS进阶设定中，chinadns-ng方案开放了其两组中国和两组可信DNS的设定，并且可信DNS-1方案均为经过节点代理的请求解析。并且通过其它开源软件的协助，在chinadns的国外上游实现了tcp和DoH协议的DNS查询。具体如下：";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>udp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用代理软件（ss/ssr/v2ray/xray/trojan）自己的udp代理，经过代理节点请求udp DNS服务器获得解析结果。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → 代理软件(udp) → 国外udp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns-ecs-forcer → 代理软件(udp) → 国内udp DNS服务器<br />";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>tcp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用dns2socks软件，并通过代理软件（ss/ssr/v2ray/xray/trojan/naive）提供的socks5代理隧道进行tcp DNS查询。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dns2socks(开ECS) → 代理软件(socks5) → 国外tcp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns2socks(关ECS) → 代理软件(socks5) → 国外tcp DNS服务器<br />";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>DoH：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>，并通过代理软件（ss/ssr/v2ray/xray/trojan/naive）提供的socks5代理隧道进行DoH DNS查询。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient(ecs=0) → 代理软件(socks5) → 国外DoH DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient(ecs=1) → 代理软件(socks5) → 国外DoH DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;以上udp协议下的ECS支持由开源工具<a href='https://github.com/rampageX/DEF' target='_blank'><u><font color='#00F'>dns-ecs-forcer</font></u></a>程序实现。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;以上tcp协议下的ECS支持由dns2socks程序实现。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;以上DoH协议下的ECS支持由dohclient程序实现。";
		statusmenu += "<br />";
		statusmenu += "--------------------------------------------------------------------------------------------------------------------";
		statusmenu += "<br />";
		statusmenu += "<div style='padding-left:16px;padding-right:16px'>";
		statusmenu += "1️⃣需要至少开启一组选可信DNS，以保证国外DNS的正常解析。<br /><br />";
		statusmenu += "2️⃣某些不支持udp的代理服务器，无法使用udp协议，此时可以考虑切换到tcp或者DoH。<br /><br />";
		statusmenu += "3️⃣某些没开53端口的代理服务器，无法在udp/tcp协议下使用53端口DNS服务器进行查询，可以考虑切换到dohclient。<br /><br />";
		statusmenu += "4️⃣Trojan协议由trojan核心运行时不支持udp代理，Trojan协议由xray运行时候支持udp协议！<br /><br />";
		statusmenu += "5️⃣NaïveProxy由于自身特性，不支持udp代理，所以Naïve节点的可信DNS-1无法使用udp协议！<br /><br />";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 135) {
		width = "780px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。";
		statusmenu += "chinadns-ng支持自定义两组中国和两组可信DNS，中国DNS用于解析中国域名，可信DNS用于解析境外域名，具体情况见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng的工作原理</font></u></a>。";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;在DNS进阶设定中，chinadns-ng方案开放了其两组中国和两组可信DNS的设定，并且可信DNS-2方案均为直连请求（不经过节点代理）方案。并且通过其它开源软件的协助，在chinadns的国外上游实现了tcp和DoH协议的DNS查询。具体如下：";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>udp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>chinadns-ng直接请求上游国外udp DNS服务器，获得解析结果，再经过chinadns-ng内部分流后给出结果。。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng →  国外udp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns-ecs-forcer → 国外udp DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>tcp：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用开源DNS工具<a href='https://github.com/zfl9/dns2tcp' target='_blank'><u><font color='#00F'>dns2tcp</font></u></a>，将DNS查询从udp模式转换为tcp模式，所以要求国外DNS服务器支持tcp查询。<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dns2tcp → 国外tcp DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dns-ecs-forcer → dns2tcp → 国外tcp DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "🔶<font color='#F00'>DoH：</font><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>原理：</font>使用开源程序<a href='https://github.com/GangZhuo/dohclient' target='_blank'><u><font color='#00F'>dohclient</font></u></a>请求国外DoH DNS服务器，该程序支持DoH (dns over https) 协议下的DNS查询！<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS关：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient (ecs=0) → 国外DoH DNS服务器<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CC0066'>ECS开：</font>DNS请求 → dnsmasq → chinadns-ng → dohclient (ecs=1) → 国外DoH DNS服务器";
		statusmenu += "<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;以上udp和tcp协议下的ECS支持由开源工具<a href='https://github.com/rampageX/DEF' target='_blank'><u><font color='#00F'>dns-ecs-forcer</font></u></a>程序实现。";
		statusmenu += "<br />";
		statusmenu += "--------------------------------------------------------------------------------------------------------------------";
		statusmenu += "<br />";
		statusmenu += "<div style='padding-left:16px;padding-right:16px'>";
		statusmenu += "1️⃣需要至少开启一组选可信DNS，以保证国外DNS的正常解析。<br /><br />";
		statusmenu += "2️⃣在国内直连国外DNS服务器进行udp查询会有DNS污染的问题，请自行解决（使用无污染的DNS，或者自建DNS服务器等）。<br /><br />";
		statusmenu += "3️⃣即使一些国外DNS服务没有被国家防火墙屏蔽，但由于是跨国直连，也有较大概率存在不稳定的情况。<br /><br />";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 136) {
		width = "690px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;基础DNS方案由fancyss 3.0.3及其以前版本的DNS方案演变继承而来，其主要特点如下：<br /><br />";
		statusmenu += "<div style='padding-left:16px;padding-right:16px'>";
		statusmenu += "1️⃣在基础DNS方案下，由dnsmasq负责DNS解析的国内外分流，具体如下：<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶gfwlist模式：由外国DNS负责解析gfwlist内的域名，其余由中国DNS解析，即国内优先模式；<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶大陆白名单/游戏模式：由中国DNS负责解析cdn名单内的域名，其余由外国DNS解析，即国外优先模式；<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶全局模式：下全部域名由外国DNS解析。<br /><br />";
		statusmenu += "2️⃣因为dnsmasq分流需要加载较多规则，特别是大陆白名单和游戏模式下，需要用到包含了6万多条域名的cdn名单，且dnsmasq对名单的匹配是遍历的方式，所以dnsmasq进程需要消耗更多的cpu算力，这对一些性能较差的路由器来说不是特别友好。<br /><br />";
		statusmenu += "3️⃣在基础DNS方案下，推荐的中国DNS方案为：运营商DNS；推荐的外国DNS解析方案为：dns2socks。<br /><br />";
		statusmenu += "4️⃣在lite版本的fancyss中，为了更好的控制安装包的体积，因此smartdns功能被精简了。<br /><br />";
		statusmenu += "</div>";
		_caption = "基础DNS方案说明：";
	} else if (itemNum == 137) {
		width = "690px";
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;进阶DNS方案有更好的DNS分流和更低的dnsmasq负载，且开放了更多的设置选项，特点如下：<br /><br />";
		statusmenu += "<div style='padding-left:16px;padding-right:16px'>";
		statusmenu += "1️⃣在进阶DNS方案下，由对应子方案的程序进行国内外的DNS分流，具体如下：<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶chinadns-ng：由gfwlist和cdn名单配合大陆ip网段实现DNS分流，具体见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng工作原理</font></u></a>；<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶smartdns：由gfwlist和cdn名单配合解析组实现国内外DNS解析分流；<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;🔶dohclient：由dohclient加载chnroute大陆ip网段实现国内外DNS解析分流；<br /><br />";
		statusmenu += "2️⃣由于以上软件在名单列表匹配上均采用更加高效的方法，因此DNS分流并不会消耗太多cpu，且相比基础DNS方案中，dnsmasq的工作负担也大大降低了。<br /><br />";
		statusmenu += "3️⃣进阶DNS方案里，目前国内外DNS分流效果最好的是chinadns-ng，如无其它特殊要求，建议使用chinadns-ng作为默认的DNS方案即可。<br /><br />";
		statusmenu += "</div>";
		_caption = "进阶DNS方案说明：";
	} else if (itemNum == 138) {
		width = "450px";
		statusmenu = "fancyss运行需要网络畅通，如果本地网络不通，fancyss将无法正常运行<br /><br />";
		statusmenu += "如果能保证你的路由器本地网络稳定性，那么在插件开启时跳过网络可用性检测！";
		_caption = "跳过网络可用性检测";
	} else if (itemNum == 139) {
		width = "450px";
		statusmenu = "因部分代理协议要求本地时间和服务器时间一致才能正常工作，比如vmess协议等<br /><br />";
		statusmenu = "如果插件检测到你本地时间和实际时间相差大于60秒，插件会帮忙自动校正时间<br /><br />";
		statusmenu = "此功能可能会导致系统提示时间未同步，如遇到此情况也建议勾选本选项<br /><br />";
		statusmenu += "如果能保证你的路由器本地时间准确，或者你使用的协议对时间没有要求，那么在插件开启时跳过时间一致性检测！";
		_caption = "跳过时间一致性检测";
	} else if (itemNum == 140) {
		width = "450px";
		statusmenu = "fancyss运行需要国内DNS畅通，如果不通，fancyss将无法正常运行<br /><br />";
		statusmenu += "如果能保证你的国内DNS稳定畅通，那么在可以插件开启时跳过国内DNS可用性检测！";
		_caption = "跳过国内DNS可用性检测";
	} else if (itemNum == 141) {
		width = "450px";
		statusmenu = "此可信DNS检测仅仅针对使用进阶DNS设定中的chinadns-ng<br /><br />";
		statusmenu += "如果可信DNS不通，那么将会无法访问代理网站；当然，如果节点本身由问题，也可能导致可信DNS不通";
		statusmenu += "勾选后将不会对可信DNS的可用性进行检测！";
		_caption = "跳过可信DNS可用性检测";
	} else if (itemNum == 142) {
		width = "450px";
		statusmenu = "在插件开启初期（尚未开启代理程序和应用任何分流规则的时候），插件会对路由器网络的国内出口ip进行检测<br /><br />";
		statusmenu += "此检测结果将会被用于国内DNS ECS功能的开启，如果你的国内DNS不不使用ECS，那么完全可以关闭此检测！";
		statusmenu += "如果你的国内DNS使用了ECS功能，勾选此功能后会强制关掉国内DNS的ECS功能！";
		_caption = "跳过国内出口ip检测";
	} else if (itemNum == 143) {
		width = "450px";
		statusmenu = "在插件开启后期（代理程序和分流规则等都已经应用完毕），插件会对路由器网络的代理出口ip进行检测<br /><br />";
		statusmenu += "此检测结果将会被用于国外DNS ECS功能的开启，如果你的国外DNS不使用ECS，那么完全可以关闭此检测！";
		statusmenu += "如果你的可信DNS使用了ECS功能，勾选此功能后会强制关掉可信DNS的ECS功能！";
		_caption = "跳过代理出口ip检测";
	} else if (itemNum == 144) {
		width = "450px";
		statusmenu = "fancyss在开启的时候会运行代理程序、dns程序等相关程序，每个程序启动后会马上进行检测，以得知该程序是否已经在后台运行了.<br /><br />";
		statusmenu += "如果勾选此选项，那么程序启动后将不会进行相应的检测，这可以节约一些fancyss的启动时间。";
		_caption = "跳过程序启动检测";
	} else if (itemNum == 145) {
		width = "680px";
		statusmenu = "<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。<br /><br />";
		statusmenu += "chinadns-ng支持过滤ipv6 DNS（AAAA）查询，具体情况见<a href='https://github.com/zfl9/chinadns-ng#命令选项' target='_blank'><u><font color='#00F'>chinadns-ng的命令选项</font></u></a>。<br /><br />";
		statusmenu += "○ a：过滤 所有 域名的 AAAA 查询<br />";
		statusmenu += "○ m：过滤 tag:chn 域名的 AAAA 查询<br />";
		statusmenu += "○ g：过滤 tag:gfw 域名的 AAAA 查询<br />";
		statusmenu += "○ n：过滤 tag:none 域名的 AAAA 查询<br />";
		statusmenu += "○ c：禁止向 china 上游转发 AAAA 查询<br />";
		statusmenu += "○ t：禁止向 trust 上游转发 AAAA 查询<br />";
		statusmenu += "○ C：当 tag:none 域名的 AAAA 查询只存在 china 上游路径时，过滤 china 上游的 非大陆ip 响应<br />";
		statusmenu += "○ T：当 tag:none 域名的 AAAA 查询只存在 trust 上游路径时，过滤 trust 上游的 非大陆ip 响应<br /><br />";
		statusmenu += "如 act：过滤 所有 域名的 AAAA 查询、禁止向 china 上游转发 AAAA 查询、禁止向 trust 上游转发 AAAA 查询<br />";
		statusmenu += "如 gt：过滤 tag:gfw 域名的 AAAA 查询、禁止向 trust 上游转发 AAAA 查询<br />";
		statusmenu += "如 mc：过滤 tag:chn 域名的 AAAA 查询、禁止向 china 上游转发 AAAA 查询<br />";
		_caption = "说明";
	} else if (itemNum == 146) {
		width = "600px";
		statusmenu = "fancyss现在同时支持ping测试和web延迟测试，ping延迟测试和web延迟测试各有优缺点，在实际使用中更建议使用web延迟测试<br /><br />";
		statusmenu += "ping延迟的优点<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 测试速度快<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. 能反应到服务器的丢包情况<br /><br />";
		statusmenu += "ping延迟的缺点<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 只能测试到服务器的icmp包延迟，且服务器禁ping后无法获取延迟<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. 中转机场只能获得到国内中转服务器的延迟，无法获得到国外代理服务器的延迟<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;3. 能ping通不代表此节点可用，ping不通也不代表节点不可用（可能是服务器禁ping）<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;4. ping低不代表该节点访问网页延迟低<br /><br />";
		statusmenu += "web延迟的优点<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 能反应当前节点代理是否可用，能测出延迟即代表节点可用<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. 能测试到实际经过代理访问网页的延迟，不受机场中转影响<br /><br />";
		statusmenu += "web延迟的缺点<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;1. 测试速度较慢，虽然web延迟测试是多线程的，但是也无法和PC相比<br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;2. 无法反应节点的丢包情况，当然如果丢包及其严重，也会测试不通<br />";
		_caption = "说明：";
	} else if (itemNum == 147) {
		width = "500px";
		statusmenu = "1. 此处设定的域名将用于所有节点的web延迟测试，同时用于插件运行状态中的国外运行状态检测（保存后立即生效）<br /><br />";
		statusmenu += "2. 不同的url测试的结果不一样是正常的，fancyss在3.2.1版本之前一直是采用的www.google.com.tw作为测试域名，现在可以根据自己的情况自由选择<br /><br />";
		statusmenu += "3. 因为机场节点服务器通常是各个国家的，要测试到最好的延迟，使用一些大服务商提供的测试url更加准确，比如google、apple、clodflare<br /><br />";
		statusmenu += "4. 部分中转机场会在中转机上劫持测试url，以返回更好的延迟，导致比如香港、美国等不同地区节点测出相似的延迟，此时建议更换测试url，以获得真实延迟<br />";
		_caption = "说明：";
	} else if (itemNum == 148) {
		width = "500px";
		statusmenu += "1. 此处设定的域名将用于插件运行状态中的国内运行状态检测，（保存后立即生效）fancyss在3.2.1版本之前使用的是www.baidu.com<br /><br />";
		statusmenu += "2. fancyss在3.2.1版本之前使用的是www.baidu.com作为测试域名，现在可以根据自己情况选择一个延迟较低的来使用<br />";
		_caption = "说明：";
	} else if (itemNum == 149) {
		width = "600px";
		statusmenu += "勾选new bing模式后，访问<a style='color:#00F' href='https://bing.com/' target='_blank'>https://bing.com/</a>将不会跳转到<a style='color:#00F' href='https://cn.bing.com/' target='_blank'>https://cn.bing.com/</a><br /><br />";
		statusmenu += "如果勾选后依然跳转到bing中国，需要清除浏览器缓存后重试！<br /><br />";
		statusmenu += "此功能等同于在域名黑名单内添加：bing.com<br />";
		_caption = "说明：";
	} else if (itemNum == 150) {
		width = "650px";
		statusmenu += "1. 因为游戏模式已经有了udp代理，此处功能仅针对gfwlist模式、大陆白名单模式、全局模式下的udp代理行为<br /><br />";
		statusmenu += "2. 大陆白名单摸下，开启udp代理后，效果和游戏模式等同<br /><br />";
		statusmenu += "3. 节点必须支持udp代理才能看到实际效果，否则希望被代理的udp包将无法抵达<br /><br />";
		statusmenu += "4. 勾选仅chatgpt后，只有访问chatgpt网页的udp会被代理，其他udp包不会被代理<br /><br />";
		statusmenu += "5. 勾选仅chatgpt后，还无法访问chatgpt的，请检查节点是否支持udp，节点的区域是否被openai限制。<br />";
		_caption = "说明：";
	}
	//return overlib(statusmenu, OFFSETX, -160, LEFT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');
	return overlib(statusmenu, OFFSETX, 30, OFFSETY, 10, RIGHT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');

	var tag_name = document.getElementsByTagName('a');
	for (var i = 0; i < tag_name.length; i++)
		tag_name[i].onmouseout = nd;

	if (helpcontent == [] || helpcontent == "" || hint_array_id > helpcontent.length)
		return overlib('<#defaultHint#>', HAUTO, VAUTO);
	else if (hint_array_id == 0 && hint_show_id > 21 && hint_show_id < 24)
		return overlib(helpcontent[hint_array_id][hint_show_id], FIXX, 270, FIXY, 30);
	else {
		if (hint_show_id > helpcontent[hint_array_id].length)
			return overlib('<#defaultHint#>', HAUTO, VAUTO);
		else
			return overlib(helpcontent[hint_array_id][hint_show_id], HAUTO, VAUTO);
	}
}

function showDropdownClientList(_callBackFun, _callBackFunParam, _interfaceMode, _containerID, _pullArrowID, _clientState) {
	document.body.addEventListener("click", function(_evt) {
		control_dropdown_client_block(_containerID, _pullArrowID, _evt);
	})
	if (clientList.length == 0) {
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
		switch (_attribute) {
			case "mac":
				attribute_value = _clienyObj.mac;
				break;
			case "ip":
				if (clientObj.ip != "offline") {
					attribute_value = _clienyObj.ip;
				}
				break;
			case "name":
				attribute_value = (clientObj.nickName == "") ? clientObj.name.replace(/'/g, "\\'") : clientObj.nickName.replace(/'/g, "\\'");
				break;
			default:
				attribute_value = _attribute;
				break;
		}
		return attribute_value;
	};

	var genClientItem = function(_state) {
		var code = "";
		var clientName = (clientObj.nickName == "") ? clientObj.name : clientObj.nickName;

		code += '<a id=' + clientList[i] + ' title=' + clientList[i] + '>';
		if (_state == "online")
			code += '<div onclick="' + _callBackFun + '(\'';
		else if (_state == "offline")
			code += '<div style="color:#A0A0A0" onclick="' + _callBackFun + '(\'';
		for (var j = 0; j < param.length; j += 1) {
			if (j == 0) {
				code += getClientValue(param[j], clientObj);
			} else {
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
		if (clientName.length > 32) {
			code += clientName.substring(0, 30) + "..";
		} else {
			code += clientName;
		}
		code += '</strong>';
		if (_state == "offline")
			code += '<strong title="Remove this client" style="float:right;margin-right:5px;cursor:pointer;" onclick="removeClient(\'' + clientObj.mac + '\', \'' + _containerID + '_clientlist_dropdown_expand\', \'' + _containerID + '_clientlist_offline\')">×</strong>';
		code += '</div><!--[if lte IE 6.5]><iframe class="hackiframe2"></iframe><![endif]--></a>';
		return code;
	};

	for (var i = 0; i < clientList.length; i += 1) {
		var clientObj = clientList[clientList[i]];
		switch (_clientState) {
			case "all":
				if (_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if (_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if (clientObj.isOnline) {
					document.getElementById("" + _containerID + "_clientlist_online").innerHTML += genClientItem("online");
				} else if (clientObj.from == "nmpClient") {
					document.getElementById("" + _containerID + "_clientlist_offline").innerHTML += genClientItem("offline");
				}
				break;
			case "online":
				if (_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if (_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if (clientObj.isOnline) {
					document.getElementById("" + _containerID + "_clientlist_online").innerHTML += genClientItem("online");
				}
				break;
			case "offline":
				if (_interfaceMode == "wl" && (clientList[clientList[i]].isWL == 0)) {
					continue;
				}
				if (_interfaceMode == "wired" && (clientList[clientList[i]].isWL != 0)) {
					continue;
				}
				if (clientObj.from == "nmpClient") {
					document.getElementById("" + _containerID + "_clientlist_offline").innerHTML += genClientItem("offline");
				}
				break;
		}
	}

	if (document.getElementById("" + _containerID + "_clientlist_offline").childNodes.length == "0") {
		if (document.getElementById("" + _containerID + "_clientlist_dropdown_expand") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_dropdown_expand"));
		}
		if (document.getElementById("" + _containerID + "_clientlist_offline") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_offline"));
		}
	} else {
		if (document.getElementById("" + _containerID + "_clientlist_dropdown_expand").innerText == "Show Offline Client List") {
			document.getElementById("" + _containerID + "_clientlist_offline").style.display = "none";
		} else {
			document.getElementById("" + _containerID + "_clientlist_offline").style.display = "";
		}
	}
	if (document.getElementById("" + _containerID + "_clientlist_online").childNodes.length == "0") {
		if (document.getElementById("" + _containerID + "_clientlist_online") != null) {
			removeElement(document.getElementById("" + _containerID + "_clientlist_online"));
		}
	}
	if (document.getElementById(_containerID).childNodes.length == "0"){
		document.getElementById(_pullArrowID).style.display = "none";
	} else {
		document.getElementById(_pullArrowID).style.display = "";
	}
}

function do_js_beautify(source) {
	js_source = source.replace(/^\s+/, '');
	tab_size = 2;
	tabchar = ' ';
	return js_beautify(js_source, tab_size, tabchar);
}

function pack_js(source) {
	var input = source;
	var packer = new Packer;
	var output = packer.pack(input, 0, 0);
	return output
}


function js_beautify(js_source_text, indent_size, indent_character, indent_level) {

	var input, output, token_text, last_type, last_text, last_word, current_mode, modes, indent_string;
	var whitespace, wordchar, punct, parser_pos, line_starters, in_case;
	var prefix, token_type, do_block_just_closed, var_line, var_line_tainted;

	function trim_output() {
		while (output.length && (output[output.length - 1] === ' ' || output[output.length - 1] === indent_string)) {
			output.pop();
		}
	}

	function print_newline(ignore_repeated) {
		ignore_repeated = typeof ignore_repeated === 'undefined' ? true : ignore_repeated;

		trim_output();

		if (!output.length) {
			return; // no newline on start of file
		}

		if (output[output.length - 1] !== "\n" || !ignore_repeated) {
			output.push("\n");
		}
		for (var i = 0; i < indent_level; i++) {
			output.push(indent_string);
		}
	}

	function print_space() {
		var last_output = output.length ? output[output.length - 1] : ' ';
		if (last_output !== ' ' && last_output !== '\n' && last_output !== indent_string) { // prevent occassional duplicate space
			output.push(' ');
		}
	}

	function print_token() {
		output.push(token_text);
	}

	function indent() {
		indent_level++;
	}

	function unindent() {
		if (indent_level) {
			indent_level--;
		}
	}

	function remove_indent() {
		if (output.length && output[output.length - 1] === indent_string) {
			output.pop();
		}
	}

	function set_mode(mode) {
		modes.push(current_mode);
		current_mode = mode;
	}

	function restore_mode() {
		do_block_just_closed = current_mode === 'DO_BLOCK';
		current_mode = modes.pop();
	}

	function in_array(what, arr) {
		for (var i = 0; i < arr.length; i++) {
			if (arr[i] === what) {
				return true;
			}
		}
		return false;
	}

	function get_next_token() {
		var n_newlines = 0;
		var c = '';

		do {
			if (parser_pos >= input.length) {
				return ['', 'TK_EOF'];
			}
			c = input.charAt(parser_pos);

			parser_pos += 1;
			if (c === "\n") {
				n_newlines += 1;
			}
		}
		while (in_array(c, whitespace));

		if (n_newlines > 1) {
			for (var i = 0; i < 2; i++) {
				print_newline(i === 0);
			}
		}
		var wanted_newline = (n_newlines === 1);


		if (in_array(c, wordchar)) {
			if (parser_pos < input.length) {
				while (in_array(input.charAt(parser_pos), wordchar)) {
					c += input.charAt(parser_pos);
					parser_pos += 1;
					if (parser_pos === input.length) {
						break;
					}
				}
			}

			if (parser_pos !== input.length && c.match(/^[0-9]+[Ee]$/) && input.charAt(parser_pos) === '-') {
				parser_pos += 1;

				var t = get_next_token(parser_pos);
				c += '-' + t[0];
				return [c, 'TK_WORD'];
			}

			if (c === 'in') { // hack for 'in' operator
				return [c, 'TK_OPERATOR'];
			}
			return [c, 'TK_WORD'];
		}

		if (c === '(' || c === '[') {
			return [c, 'TK_START_EXPR'];
		}

		if (c === ')' || c === ']') {
			return [c, 'TK_END_EXPR'];
		}

		if (c === '{') {
			return [c, 'TK_START_BLOCK'];
		}

		if (c === '}') {
			return [c, 'TK_END_BLOCK'];
		}

		if (c === ';') {
			return [c, 'TK_END_COMMAND'];
		}

		if (c === '/') {
			var comment = '';
			if (input.charAt(parser_pos) === '*') {
				parser_pos += 1;
				if (parser_pos < input.length) {
					while (!(input.charAt(parser_pos) === '*' && input.charAt(parser_pos + 1) && input.charAt(parser_pos + 1) === '/') && parser_pos < input.length) {
						comment += input.charAt(parser_pos);
						parser_pos += 1;
						if (parser_pos >= input.length) {
							break;
						}
					}
				}
				parser_pos += 2;
				return ['/*' + comment + '*/', 'TK_BLOCK_COMMENT'];
			}
			if (input.charAt(parser_pos) === '/') {
				comment = c;
				while (input.charAt(parser_pos) !== "\x0d" && input.charAt(parser_pos) !== "\x0a") {
					comment += input.charAt(parser_pos);
					parser_pos += 1;
					if (parser_pos >= input.length) {
						break;
					}
				}
				parser_pos += 1;
				if (wanted_newline) {
					print_newline();
				}
				return [comment, 'TK_COMMENT'];
			}

		}

		if (c === "'" || // string
			c === '"' || // string
			(c === '/' &&
				((last_type === 'TK_WORD' && last_text === 'return') || (last_type === 'TK_START_EXPR' || last_type === 'TK_END_BLOCK' || last_type === 'TK_OPERATOR' || last_type === 'TK_EOF' || last_type === 'TK_END_COMMAND')))) { // regexp
			var sep = c;
			var esc = false;
			c = '';

			if (parser_pos < input.length) {

				while (esc || input.charAt(parser_pos) !== sep) {
					c += input.charAt(parser_pos);
					if (!esc) {
						esc = input.charAt(parser_pos) === '\\';
					} else {
						esc = false;
					}
					parser_pos += 1;
					if (parser_pos >= input.length) {
						break;
					}
				}

			}

			parser_pos += 1;
			if (last_type === 'TK_END_COMMAND') {
				print_newline();
			}
			return [sep + c + sep, 'TK_STRING'];
		}

		if (in_array(c, punct)) {
			while (parser_pos < input.length && in_array(c + input.charAt(parser_pos), punct)) {
				c += input.charAt(parser_pos);
				parser_pos += 1;
				if (parser_pos >= input.length) {
					break;
				}
			}
			return [c, 'TK_OPERATOR'];
		}

		return [c, 'TK_UNKNOWN'];
	}


	indent_character = indent_character || ' ';
	indent_size = indent_size || 4;

	indent_string = '';
	while (indent_size--) {
		indent_string += indent_character;
	}

	input = js_source_text;

	last_word = ''; // last 'TK_WORD' passed
	last_type = 'TK_START_EXPR'; // last token type
	last_text = ''; // last token text
	output = [];

	do_block_just_closed = false;
	var_line = false;
	var_line_tainted = false;

	whitespace = "\n\r\t ".split('');
	wordchar = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$'.split('');
	punct = '+ - * / % & ++ -- = += -= *= /= %= == === != !== > < >= <= >> << >>> >>>= >>= <<= && &= | || ! !! , : ? ^ ^= |='.split(' ');

	line_starters = 'continue,try,throw,return,var,if,switch,case,default,for,while,break,function'.split(',');

	current_mode = 'BLOCK';
	modes = [current_mode];

	indent_level = indent_level || 0;
	parser_pos = 0; // parser position
	in_case = false; // flag for parser that case/default has been processed, and next colon needs special attention
	while (true) {
		var t = get_next_token(parser_pos);
		token_text = t[0];
		token_type = t[1];
		if (token_type === 'TK_EOF') {
			break;
		}

		switch (token_type) {

			case 'TK_START_EXPR':
				var_line = false;
				set_mode('EXPRESSION');
				if (last_type === 'TK_END_EXPR' || last_type === 'TK_START_EXPR') {
				} else if (last_type !== 'TK_WORD' && last_type !== 'TK_OPERATOR') {
					print_space();
				} else if (in_array(last_word, line_starters) && last_word !== 'function') {
					print_space();
				}
				print_token();
				break;

			case 'TK_END_EXPR':
				print_token();
				restore_mode();
				break;

			case 'TK_START_BLOCK':

				if (last_word === 'do') {
					set_mode('DO_BLOCK');
				} else {
					set_mode('BLOCK');
				}
				if (last_type !== 'TK_OPERATOR' && last_type !== 'TK_START_EXPR') {
					if (last_type === 'TK_START_BLOCK') {
						print_newline();
					} else {
						print_space();
					}
				}
				print_token();
				indent();
				break;

			case 'TK_END_BLOCK':
				if (last_type === 'TK_START_BLOCK') {
					trim_output();
					unindent();
				} else {
					unindent();
					print_newline();
				}
				print_token();
				restore_mode();
				break;

			case 'TK_WORD':

				if (do_block_just_closed) {
					print_space();
					print_token();
					print_space();
					break;
				}

				if (token_text === 'case' || token_text === 'default') {
					if (last_text === ':') {
						remove_indent();
					} else {
						unindent();
						print_newline();
						indent();
					}
					print_token();
					in_case = true;
					break;
				}


				prefix = 'NONE';
				if (last_type === 'TK_END_BLOCK') {
					if (!in_array(token_text.toLowerCase(), ['else', 'catch', 'finally'])) {
						prefix = 'NEWLINE';
					} else {
						prefix = 'SPACE';
						print_space();
					}
				} else if (last_type === 'TK_END_COMMAND' && (current_mode === 'BLOCK' || current_mode === 'DO_BLOCK')) {
					prefix = 'NEWLINE';
				} else if (last_type === 'TK_END_COMMAND' && current_mode === 'EXPRESSION') {
					prefix = 'SPACE';
				} else if (last_type === 'TK_WORD') {
					prefix = 'SPACE';
				} else if (last_type === 'TK_START_BLOCK') {
					prefix = 'NEWLINE';
				} else if (last_type === 'TK_END_EXPR') {
					print_space();
					prefix = 'NEWLINE';
				}

				if (last_type !== 'TK_END_BLOCK' && in_array(token_text.toLowerCase(), ['else', 'catch', 'finally'])) {
					print_newline();
				} else if (in_array(token_text, line_starters) || prefix === 'NEWLINE') {
					if (last_text === 'else') {
						print_space();
					} else if ((last_type === 'TK_START_EXPR' || last_text === '=') && token_text === 'function') {
					} else if (last_type === 'TK_WORD' && (last_text === 'return' || last_text === 'throw')) {
						print_space();
					} else if (last_type !== 'TK_END_EXPR') {
						if ((last_type !== 'TK_START_EXPR' || token_text !== 'var') && last_text !== ':') {
							if (token_text === 'if' && last_type === 'TK_WORD' && last_word === 'else') {
								print_space();
							} else {
								print_newline();
							}
						}
					} else {
						if (in_array(token_text, line_starters) && last_text !== ')') {
							print_newline();
						}
					}
				} else if (prefix === 'SPACE') {
					print_space();
				}
				print_token();
				last_word = token_text;

				if (token_text === 'var') {
					var_line = true;
					var_line_tainted = false;
				}

				break;

			case 'TK_END_COMMAND':

				print_token();
				var_line = false;
				break;

			case 'TK_STRING':

				if (last_type === 'TK_START_BLOCK' || last_type === 'TK_END_BLOCK') {
					print_newline();
				} else if (last_type === 'TK_WORD') {
					print_space();
				}
				print_token();
				break;

			case 'TK_OPERATOR':

				var start_delim = true;
				var end_delim = true;
				if (var_line && token_text !== ',') {
					var_line_tainted = true;
					if (token_text === ':') {
						var_line = false;
					}
				}

				if (token_text === ':' && in_case) {
					print_token(); // colon really asks for separate treatment
					print_newline();
					break;
				}

				in_case = false;

				if (token_text === ',') {
					if (var_line) {
						if (var_line_tainted) {
							print_token();
							print_newline();
							var_line_tainted = false;
						} else {
							print_token();
							print_space();
						}
					} else if (last_type === 'TK_END_BLOCK') {
						print_token();
						print_newline();
					} else {
						if (current_mode === 'BLOCK') {
							print_token();
							print_newline();
						} else {
							print_token();
							print_space();
						}
					}
					break;
				} else if (token_text === '--' || token_text === '++') { // unary operators special case
					if (last_text === ';') {
						start_delim = true;
						end_delim = false;
					} else {
						start_delim = false;
						end_delim = false;
					}
				} else if (token_text === '!' && last_type === 'TK_START_EXPR') {
					start_delim = false;
					end_delim = false;
				} else if (last_type === 'TK_OPERATOR') {
					start_delim = false;
					end_delim = false;
				} else if (last_type === 'TK_END_EXPR') {
					start_delim = true;
					end_delim = true;
				} else if (token_text === '.') {
					start_delim = false;
					end_delim = false;

				} else if (token_text === ':') {
					if (last_text.match(/^\d+$/)) {
						start_delim = true;
					} else {
						start_delim = false;
					}
				}
				if (start_delim) {
					print_space();
				}

				print_token();

				if (end_delim) {
					print_space();
				}
				break;

			case 'TK_BLOCK_COMMENT':

				print_newline();
				print_token();
				print_newline();
				break;

			case 'TK_COMMENT':

				print_space();
				print_token();
				print_newline();
				break;

			case 'TK_UNKNOWN':
				print_token();
				break;
		}

		last_type = token_type;
		last_text = token_text;
	}

	return output.join('');

}

var base2 = {
	name: "base2",
	version: "1.0",
	exports: "Base,Package,Abstract,Module,Enumerable,Map,Collection,RegGrp,Undefined,Null,This,True,False,assignID,detect,global",
	namespace: ""
};
new

function(_y) {
	var Undefined = K(),
		Null = K(null),
		True = K(true),
		False = K(false),
		This = function() {
			return this
		};
	var global = This();
	var base2 = global.base2;
	var _z = /%([1-9])/g;
	var _g = /^\s\s*/;
	var _h = /\s\s*$/;
	var _i = /([\/()[\]{}|*+-.,^$?\\])/g;
	var _9 = /try/.test(detect) ? /\bbase\b/ : /.*/;
	var _a = ["constructor", "toString", "valueOf"];
	var _j = detect("(jscript)") ? new RegExp("^" + rescape(isNaN).replace(/isNaN/, "\\w+") + "$") : {
		test: False
	};
	var _k = 1;
	var _2 = Array.prototype.slice;
	_5();

	function assignID(a) {
		if (!a.base2ID) a.base2ID = "b2_" + _k++;
		return a.base2ID
	};
	var _b = function(a, b) {
		base2.__prototyping = this.prototype;
		var c = new this;
		if (a) extend(c, a);
		delete base2.__prototyping;
		var e = c.constructor;

		function d() {
			if (!base2.__prototyping) {
				if (this.constructor == arguments.callee || this.__constructing) {
					this.__constructing = true;
					e.apply(this, arguments);
					delete this.__constructing
				} else {
					return extend(arguments[0], c)
				}
			}
			return this
		};
		c.constructor = d;
		for (var f in Base) d[f] = this[f];
		d.ancestor = this;
		d.base = Undefined;
		if (b) extend(d, b);
		d.prototype = c;
		if (d.init) d.init();
		return d
	};
	var Base = _b.call(Object, {
			constructor: function() {
				if (arguments.length > 0) {
					this.extend(arguments[0])
				}
			},
			base: function() {},
			extend: delegate(extend)
		},
		Base = {
			ancestorOf: function(a) {
				return _7(this, a)
			},
			extend: _b,
			forEach: function(a, b, c) {
				_5(this, a, b, c)
			},
			implement: function(a) {
				if (typeof a == "function") {
					a = a.prototype
				}
				extend(this.prototype, a);
				return this
			}
		});
	var Package = Base.extend({
		constructor: function(e, d) {
			this.extend(d);
			if (this.init) this.init();
			if (this.name && this.name != "base2") {
				if (!this.parent) this.parent = base2;
				this.parent.addName(this.name, this);
				this.namespace = format("var %1=%2;", this.name, String2.slice(this, 1, -1))
			}
			if (e) {
				var f = base2.JavaScript ? base2.JavaScript.namespace : "";
				e.imports = Array2.reduce(csv(this.imports),
					function(a, b) {
						var c = h(b) || h("JavaScript." + b);
						return a += c.namespace
					},
					"var base2=(function(){return this.base2})();" + base2.namespace + f) + lang.namespace;
				e.exports = Array2.reduce(csv(this.exports),
					function(a, b) {
						var c = this.name + "." + b;
						this.namespace += "var " + b + "=" + c + ";";
						return a += "if(!" + c + ")" + c + "=" + b + ";"
					},
					"", this) + "this._l" + this.name + "();";
				var g = this;
				var i = String2.slice(this, 1, -1);
				e["_l" + this.name] = function() {
					Package.forEach(g,
						function(a, b) {
							if (a && a.ancestorOf == Base.ancestorOf) {
								a.toString = K(format("[%1.%2]", i, b));
								if (a.prototype.toString == Base.prototype.toString) {
									a.prototype.toString = K(format("[object %1.%2]", i, b))
								}
							}
						})
				}
			}

			function h(a) {
				a = a.split(".");
				var b = base2,
					c = 0;
				while (b && a[c] != null) {
					b = b[a[c++]]
				}
				return b
			}
		},
		exports: "",
		imports: "",
		name: "",
		namespace: "",
		parent: null,
		addName: function(a, b) {
			if (!this[a]) {
				this[a] = b;
				this.exports += "," + a;
				this.namespace += format("var %1=%2.%1;", a, this.name)
			}
		},
		addPackage: function(a) {
			this.addName(a, new Package(null, {
				name: a,
				parent: this
			}))
		},
		toString: function() {
			return format("[%1]", this.parent ? String2.slice(this.parent, 1, -1) + "." + this.name : this.name)
		}
	});
	var Abstract = Base.extend({
		constructor: function() {
			throw new TypeError("Abstract class cannot be instantiated.");
		}
	});
	var _m = 0;
	var Module = Abstract.extend(null, {
		namespace: "",
		extend: function(a, b) {
			var c = this.base();
			var e = _m++;
			c.namespace = "";
			c.partial = this.partial;
			c.toString = K("[base2.Module[" + e + "]]");
			Module[e] = c;
			c.implement(this);
			if (a) c.implement(a);
			if (b) {
				extend(c, b);
				if (c.init) c.init()
			}
			return c
		},
		forEach: function(c, e) {
			_5(Module, this.prototype,
				function(a, b) {
					if (typeOf(a) == "function") {
						c.call(e, this[b], b, this)
					}
				},
				this)
		},
		implement: function(a) {
			var b = this;
			var c = b.toString().slice(1, -1);
			if (typeof a == "function") {
				if (!_7(a, b)) {
					this.base(a)
				}
				if (_7(Module, a)) {
					for (var e in a) {
						if (b[e] === undefined) {
							var d = a[e];
							if (typeof d == "function" && d.call && a.prototype[e]) {
								d = _n(a, e)
							}
							b[e] = d
						}
					}
					b.namespace += a.namespace.replace(/base2\.Module\[\d+\]/g, c)
				}
			} else {
				extend(b, a);
				_c(b, a)
			}
			return b
		},
		partial: function() {
			var c = Module.extend();
			var e = c.toString().slice(1, -1);
			c.namespace = this.namespace.replace(/(\w+)=b[^\)]+\)/g, "$1=" + e + ".$1");
			this.forEach(function(a, b) {
				c[b] = partial(bind(a, c))
			});
			return c
		}
	});

	function _c(a, b) {
		var c = a.prototype;
		var e = a.toString().slice(1, -1);
		for (var d in b) {
			var f = b[d],
				g = "";
			if (d.charAt(0) == "@") {
				if (detect(d.slice(1))) _c(a, f)
			} else if (!c[d]) {
				if (d == d.toUpperCase()) {
					g = "var " + d + "=" + e + "." + d + ";"
				} else if (typeof f == "function" && f.call) {
					g = "var " + d + "=base2.lang.bind('" + d + "'," + e + ");";
					c[d] = _o(a, d)
				}
				if (a.namespace.indexOf(g) == -1) {
					a.namespace += g
				}
			}
		}
	};

	function _n(a, b) {
		return function() {
			return a[b].apply(a, arguments)
		}
	};

	function _o(b, c) {
		return function() {
			var a = _2.call(arguments);
			a.unshift(this);
			return b[c].apply(b, a)
		}
	};
	var Enumerable = Module.extend({
		every: function(c, e, d) {
			var f = true;
			try {
				forEach(c,
					function(a, b) {
						f = e.call(d, a, b, c);
						if (!f) throw StopIteration;
					})
			} catch (error) {
				if (error != StopIteration) throw error;
			}
			return !!f
		},
		filter: function(e, d, f) {
			var g = 0;
			return this.reduce(e,
				function(a, b, c) {
					if (d.call(f, b, c, e)) {
						a[g++] = b
					}
					return a
				}, [])
		},
		invoke: function(b, c) {
			var e = _2.call(arguments, 2);
			return this.map(b, (typeof c == "function") ?
				function(a) {
					return a == null ? undefined : c.apply(a, e)
				} : function(a) {
					return a == null ? undefined : a[c].apply(a, e)
				})
		},
		map: function(c, e, d) {
			var f = [],
				g = 0;
			forEach(c,
				function(a, b) {
					f[g++] = e.call(d, a, b, c)
				});
			return f
		},
		pluck: function(b, c) {
			return this.map(b,
				function(a) {
					return a == null ? undefined : a[c]
				})
		},
		reduce: function(c, e, d, f) {
			var g = arguments.length > 2;
			forEach(c,
				function(a, b) {
					if (g) {
						d = e.call(f, d, a, b, c)
					} else {
						d = a;
						g = true
					}
				});
			return d
		},
		some: function(a, b, c) {
			return !this.every(a, not(b), c)
		}
	});
	var _1 = "#";
	var Map = Base.extend({
		constructor: function(a) {
			if (a) this.merge(a)
		},
		clear: function() {
			for (var a in this)
				if (a.indexOf(_1) == 0) {
					delete this[a]
				}
		},
		copy: function() {
			base2.__prototyping = true;
			var a = new this.constructor;
			delete base2.__prototyping;
			for (var b in this)
				if (this[b] !== a[b]) {
					a[b] = this[b]
				}
			return a
		},
		forEach: function(a, b) {
			for (var c in this)
				if (c.indexOf(_1) == 0) {
					a.call(b, this[c], c.slice(1), this)
				}
		},
		get: function(a) {
			return this[_1 + a]
		},
		getKeys: function() {
			return this.map(II)
		},
		getValues: function() {
			return this.map(I)
		},
		has: function(a) {
			/*@cc_on @*/
			/*@if(@_jscript_version<5.5)return $Legacy.has(this,_1+a);@else @*/
			return _1 + a in this;
			/*@end @*/
		},
		merge: function(b) {
			var c = flip(this.put);
			forEach(arguments,
				function(a) {
					forEach(a, c, this)
				},
				this);
			return this
		},
		put: function(a, b) {
			this[_1 + a] = b
		},
		remove: function(a) {
			delete this[_1 + a]
		},
		size: function() {
			var a = 0;
			for (var b in this)
				if (b.indexOf(_1) == 0) a++;
			return a
		},
		union: function(a) {
			return this.merge.apply(this.copy(), arguments)
		}
	});
	Map.implement(Enumerable);
	Map.prototype.filter = function(e, d) {
		return this.reduce(function(a, b, c) {
				if (!e.call(d, b, c, this)) {
					a.remove(c)
				}
				return a
			},
			this.copy(), this)
	};
	var _0 = "~";
	var Collection = Map.extend({
		constructor: function(a) {
			this[_0] = new Array2;
			this.base(a)
		},
		add: function(a, b) {
			assert(!this.has(a), "Duplicate key '" + a + "'.");
			this.put.apply(this, arguments)
		},
		clear: function() {
			this.base();
			this[_0].length = 0
		},
		copy: function() {
			var a = this.base();
			a[_0] = this[_0].copy();
			return a
		},
		forEach: function(a, b) {
			var c = this[_0];
			var e = c.length;
			for (var d = 0; d < e; d++) {
				a.call(b, this[_1 + c[d]], c[d], this)
			}
		},
		getAt: function(a) {
			var b = this[_0].item(a);
			return (b === undefined) ? undefined : this[_1 + b]
		},
		getKeys: function() {
			return this[_0].copy()
		},
		indexOf: function(a) {
			return this[_0].indexOf(String(a))
		},
		insertAt: function(a, b, c) {
			assert(this[_0].item(a) !== undefined, "Index out of bounds.");
			assert(!this.has(b), "Duplicate key '" + b + "'.");
			this[_0].insertAt(a, String(b));
			this[_1 + b] = null;
			this.put.apply(this, _2.call(arguments, 1))
		},
		item: function(a) {
			return this[typeof a == "number" ? "getAt" : "get"](a)
		},
		put: function(a, b) {
			if (!this.has(a)) {
				this[_0].push(String(a))
			}
			var c = this.constructor;
			if (c.Item && !instanceOf(b, c.Item)) {
				b = c.create.apply(c, arguments)
			}
			this[_1 + a] = b
		},
		putAt: function(a, b) {
			arguments[0] = this[_0].item(a);
			assert(arguments[0] !== undefined, "Index out of bounds.");
			this.put.apply(this, arguments)
		},
		remove: function(a) {
			if (this.has(a)) {
				this[_0].remove(String(a));
				delete this[_1 + a]
			}
		},
		removeAt: function(a) {
			var b = this[_0].item(a);
			if (b !== undefined) {
				this[_0].removeAt(a);
				delete this[_1 + b]
			}
		},
		reverse: function() {
			this[_0].reverse();
			return this
		},
		size: function() {
			return this[_0].length
		},
		slice: function(a, b) {
			var c = this.copy();
			if (arguments.length > 0) {
				var e = this[_0],
					d = e;
				c[_0] = Array2(_2.apply(e, arguments));
				if (c[_0].length) {
					d = d.slice(0, a);
					if (arguments.length > 1) {
						d = d.concat(e.slice(b))
					}
				}
				for (var f = 0; f < d.length; f++) {
					delete c[_1 + d[f]]
				}
			}
			return c
		},
		sort: function(c) {
			if (c) {
				this[_0].sort(bind(function(a, b) {
						return c(this[_1 + a], this[_1 + b], a, b)
					},
					this))
			} else this[_0].sort();
			return this
		},
		toString: function() {
			return "(" + (this[_0] || "") + ")"
		}
	}, {
		Item: null,
		create: function(a, b) {
			return this.Item ? new this.Item(a, b) : b
		},
		extend: function(a, b) {
			var c = this.base(a);
			c.create = this.create;
			if (b) extend(c, b);
			if (!c.Item) {
				c.Item = this.Item
			} else if (typeof c.Item != "function") {
				c.Item = (this.Item || Base).extend(c.Item)
			}
			if (c.init) c.init();
			return c
		}
	});
	var _p = /\\(\d+)/g,
		_q = /\\./g,
		_r = /\(\?[:=!]|\[[^\]]+\]/g,
		_s = /\(/g,
		_t = /\$(\d+)/,
		_u = /^\$\d+$/;
	var RegGrp = Collection.extend({
		constructor: function(a, b) {
			this.base(a);
			this.ignoreCase = !!b
		},
		ignoreCase: false,
		exec: function(g, i) {
			g += "";
			var h = this,
				j = this[_0];
			if (!j.length) return g;
			if (i == RegGrp.IGNORE) i = 0;
			return g.replace(new RegExp(this, this.ignoreCase ? "gi" : "g"),
				function(a) {
					var b, c = 1,
						e = 0;
					while ((b = h[_1 + j[e++]])) {
						var d = c + b.length + 1;
						if (arguments[c]) {
							var f = i == null ? b.replacement : i;
							switch (typeof f) {
								case "function":
									return f.apply(h, _2.call(arguments, c, d));
								case "number":
									return arguments[c + f];
								default:
									return f
							}
						}
						c = d
					}
					return a
				})
		},
		insertAt: function(a, b, c) {
			if (instanceOf(b, RegExp)) {
				arguments[1] = b.source
			}
			return base(this, arguments)
		},
		test: function(a) {
			return this.exec(a) != a
		},
		toString: function() {
			var d = 1;
			return "(" + this.map(function(c) {
				var e = (c + "").replace(_p,
					function(a, b) {
						return "\\" + (d + Number(b))
					});
				d += c.length + 1;
				return e
			}).join(")|(") + ")"
		}
	}, {
		IGNORE: "$0",
		init: function() {
			forEach("add,get,has,put,remove".split(","),
				function(b) {
					_8(this, b,
						function(a) {
							if (instanceOf(a, RegExp)) {
								arguments[0] = a.source
							}
							return base(this, arguments)
						})
				},
				this.prototype)
		},
		Item: {
			constructor: function(a, b) {
				if (b == null) b = RegGrp.IGNORE;
				else if (b.replacement != null) b = b.replacement;
				else if (typeof b != "function") b = String(b);
				if (typeof b == "string" && _t.test(b)) {
					if (_u.test(b)) {
						b = parseInt(b.slice(1))
					} else {
						var c = '"';
						b = b.replace(/\\/g, "\\\\").replace(/"/g, "\\x22").replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\$(\d+)/g, c + "+(arguments[$1]||" + c + c + ")+" + c).replace(/(['"])\1\+(.*)\+\1\1$/, "$1");
						b = new Function("return " + c + b + c)
					}
				}
				this.length = RegGrp.count(a);
				this.replacement = b;
				this.toString = K(a + "")
			},
			length: 0,
			replacement: ""
		},
		count: function(a) {
			a = (a + "").replace(_q, "").replace(_r, "");
			return match(a, _s).length
		}
	});
	var lang = {
		name: "lang",
		version: base2.version,
		exports: "assert,assertArity,assertType,base,bind,copy,extend,forEach,format,instanceOf,match,pcopy,rescape,trim,typeOf",
		namespace: ""
	};

	function assert(a, b, c) {
		if (!a) {
			throw new(c || Error)(b || "Assertion failed.");
		}
	};

	function assertArity(a, b, c) {
		if (b == null) b = a.callee.length;
		if (a.length < b) {
			throw new SyntaxError(c || "Not enough arguments.");
		}
	};

	function assertType(a, b, c) {
		if (b && (typeof b == "function" ? !instanceOf(a, b) : typeOf(a) != b)) {
			throw new TypeError(c || "Invalid type.");
		}
	};

	function copy(a) {
		var b = {};
		for (var c in a) {
			b[c] = a[c]
		}
		return b
	};

	function pcopy(a) {
		_d.prototype = a;
		return new _d
	};

	function _d() {};

	function base(a, b) {
		return a.base.apply(a, b)
	};

	function extend(a, b) {
		if (a && b) {
			if (arguments.length > 2) {
				var c = b;
				b = {};
				b[c] = arguments[2]
			}
			var e = global[(typeof b == "function" ? "Function" : "Object")].prototype;
			if (base2.__prototyping) {
				var d = _a.length,
					c;
				while ((c = _a[--d])) {
					var f = b[c];
					if (f != e[c]) {
						if (_9.test(f)) {
							_8(a, c, f)
						} else {
							a[c] = f
						}
					}
				}
			}
			for (c in b) {
				if (e[c] === undefined) {
					var f = b[c];
					if (c.charAt(0) == "@") {
						if (detect(c.slice(1))) extend(a, f)
					} else {
						var g = a[c];
						if (g && typeof f == "function") {
							if (f != g) {
								if (_9.test(f)) {
									_8(a, c, f)
								} else {
									f.ancestor = g;
									a[c] = f
								}
							}
						} else {
							a[c] = f
						}
					}
				}
			}
		}
		return a
	};

	function _7(a, b) {
		while (b) {
			if (!b.ancestor) return false;
			b = b.ancestor;
			if (b == a) return true
		}
		return false
	};

	function _8(c, e, d) {
		var f = c[e];
		var g = base2.__prototyping;
		if (g && f != g[e]) g = null;

		function i() {
			var a = this.base;
			this.base = g ? g[e] : f;
			var b = d.apply(this, arguments);
			this.base = a;
			return b
		};
		i.method = d;
		i.ancestor = f;
		c[e] = i
	};
	if (typeof StopIteration == "undefined") {
		StopIteration = new Error("StopIteration")
	}

	function forEach(a, b, c, e) {
		if (a == null) return;
		if (!e) {
			if (typeof a == "function" && a.call) {
				e = Function
			} else if (typeof a.forEach == "function" && a.forEach != arguments.callee) {
				a.forEach(b, c);
				return
			} else if (typeof a.length == "number") {
				_e(a, b, c);
				return
			}
		}
		_5(e || Object, a, b, c)
	};
	forEach.csv = function(a, b, c) {
		forEach(csv(a), b, c)
	};
	forEach.detect = function(c, e, d) {
		forEach(c,
			function(a, b) {
				if (b.charAt(0) == "@") {
					if (detect(b.slice(1))) forEach(a, arguments.callee)
				} else e.call(d, a, b, c)
			})
	};

	function _e(a, b, c) {
		if (a == null) a = global;
		var e = a.length || 0,
			d;
		if (typeof a == "string") {
			for (d = 0; d < e; d++) {
				b.call(c, a.charAt(d), d, a)
			}
		} else {
			for (d = 0; d < e; d++) {
				/*@cc_on @*/
				/*@if(@_jscript_version<5.2)if($Legacy.has(a,d))@else @*/
				if (d in a)
				/*@end @*/
					b.call(c, a[d], d, a)
			}
		}
	};

	function _5(g, i, h, j) {
		var k = function() {
			this.i = 1
		};
		k.prototype = {
			i: 1
		};
		var l = 0;
		for (var m in new k) l++;
		_5 = (l > 1) ?
			function(a, b, c, e) {
				var d = {};
				for (var f in b) {
					if (!d[f] && a.prototype[f] === undefined) {
						d[f] = true;
						c.call(e, b[f], f, b)
					}
				}
			} : function(a, b, c, e) {
				for (var d in b) {
					if (a.prototype[d] === undefined) {
						c.call(e, b[d], d, b)
					}
				}
			};
		_5(g, i, h, j)
	};

	function instanceOf(a, b) {
		if (typeof b != "function") {
			throw new TypeError("Invalid 'instanceOf' operand.");
		}
		if (a == null) return false;
		/*@cc_on if(typeof a.constructor!="function"){return typeOf(a)==typeof b.prototype.valueOf()}@*/
		if (a.constructor == b) return true;
		if (b.ancestorOf) return b.ancestorOf(a.constructor);
		/*@if(@_jscript_version<5.1)@else @*/
		if (a instanceof b) return true;
		/*@end @*/
		if (Base.ancestorOf == b.ancestorOf) return false;
		if (Base.ancestorOf == a.constructor.ancestorOf) return b == Object;
		switch (b) {
			case Array:
				return !!(typeof a == "object" && a.join && a.splice);
			case Function:
				return typeOf(a) == "function";
			case RegExp:
				return typeof a.constructor.$1 == "string";
			case Date:
				return !!a.getTimezoneOffset;
			case String:
			case Number:
			case Boolean:
				return typeOf(a) == typeof b.prototype.valueOf();
			case Object:
				return true
		}
		return false
	};

	function typeOf(a) {
		var b = typeof a;
		switch (b) {
			case "object":
				return a == null ? "null" : typeof a.constructor == "undefined" ? _j.test(a) ? "function" : b : typeof a.constructor.prototype.valueOf();
			case "function":
				return typeof a.call == "function" ? b : "object";
			default:
				return b
		}
	};
	var JavaScript = {
		name: "JavaScript",
		version: base2.version,
		exports: "Array2,Date2,Function2,String2",
		namespace: "",
		bind: function(c) {
			var e = global;
			global = c;
			forEach.csv(this.exports,
				function(a) {
					var b = a.slice(0, -1);
					extend(c[b], this[a]);
					this[a](c[b].prototype)
				},
				this);
			global = e;
			return c
		}
	};

	function _6(b, c, e, d) {
		var f = Module.extend();
		var g = f.toString().slice(1, -1);
		forEach.csv(e,
			function(a) {
				f[a] = unbind(b.prototype[a]);
				f.namespace += format("var %1=%2.%1;", a, g)
			});
		forEach(_2.call(arguments, 3), f.implement, f);
		var i = function() {
			return f(this.constructor == f ? c.apply(null, arguments) : arguments[0])
		};
		i.prototype = f.prototype;
		for (var h in f) {
			if (h != "prototype" && b[h]) {
				f[h] = b[h];
				delete f.prototype[h]
			}
			i[h] = f[h]
		}
		i.ancestor = Object;
		delete i.extend;
		i.namespace = i.namespace.replace(/(var (\w+)=)[^,;]+,([^\)]+)\)/g, "$1$3.$2");
		return i
	};
	if ((new Date).getYear() > 1900) {
		Date.prototype.getYear = function() {
			return this.getFullYear() - 1900
		};
		Date.prototype.setYear = function(a) {
			return this.setFullYear(a + 1900)
		}
	}
	var _f = new Date(Date.UTC(2006, 1, 20));
	_f.setUTCDate(15);
	if (_f.getUTCHours() != 0) {
		forEach.csv("FullYear,Month,Date,Hours,Minutes,Seconds,Milliseconds",
			function(b) {
				extend(Date.prototype, "setUTC" + b,
					function() {
						var a = base(this, arguments);
						if (a >= 57722401000) {
							a -= 3600000;
							this.setTime(a)
						}
						return a
					})
			})
	}
	Function.prototype.prototype = {};
	if ("".replace(/^/, K("$$")) == "$") {
		extend(String.prototype, "replace",
			function(a, b) {
				if (typeof b == "function") {
					var c = b;
					b = function() {
						return String(c.apply(null, arguments)).split("$").join("$$")
					}
				}
				return this.base(a, b)
			})
	}
	var Array2 = _6(Array, Array, "concat,join,pop,push,reverse,shift,slice,sort,splice,unshift", Enumerable, {
		combine: function(e, d) {
			if (!d) d = e;
			return Array2.reduce(e,
				function(a, b, c) {
					a[b] = d[c];
					return a
				}, {})
		},
		contains: function(a, b) {
			return Array2.indexOf(a, b) != -1
		},
		copy: function(a) {
			var b = _2.call(a);
			if (!b.swap) Array2(b);
			return b
		},
		flatten: function(c) {
			var e = 0;
			return Array2.reduce(c,
				function(a, b) {
					if (Array2.like(b)) {
						Array2.reduce(b, arguments.callee, a)
					} else {
						a[e++] = b
					}
					return a
				}, [])
		},
		forEach: _e,
		indexOf: function(a, b, c) {
			var e = a.length;
			if (c == null) {
				c = 0
			} else if (c < 0) {
				c = Math.max(0, e + c)
			}
			for (var d = c; d < e; d++) {
				if (a[d] === b) return d
			}
			return -1
		},
		insertAt: function(a, b, c) {
			Array2.splice(a, b, 0, c);
			return c
		},
		item: function(a, b) {
			if (b < 0) b += a.length;
			return a[b]
		},
		lastIndexOf: function(a, b, c) {
			var e = a.length;
			if (c == null) {
				c = e - 1
			} else if (c < 0) {
				c = Math.max(0, e + c)
			}
			for (var d = c; d >= 0; d--) {
				if (a[d] === b) return d
			}
			return -1
		},
		map: function(c, e, d) {
			var f = [];
			Array2.forEach(c,
				function(a, b) {
					f[b] = e.call(d, a, b, c)
				});
			return f
		},
		remove: function(a, b) {
			var c = Array2.indexOf(a, b);
			if (c != -1) Array2.removeAt(a, c)
		},
		removeAt: function(a, b) {
			Array2.splice(a, b, 1)
		},
		swap: function(a, b, c) {
			if (b < 0) b += a.length;
			if (c < 0) c += a.length;
			var e = a[b];
			a[b] = a[c];
			a[c] = e;
			return a
		}
	});
	Array2.reduce = Enumerable.reduce;
	Array2.like = function(a) {
		return typeOf(a) == "object" && typeof a.length == "number"
	};
	var _v = /^((-\d+|\d{4,})(-(\d{2})(-(\d{2}))?)?)?T((\d{2})(:(\d{2})(:(\d{2})(\.(\d{1,3})(\d)?\d*)?)?)?)?(([+-])(\d{2})(:(\d{2}))?|Z)?$/;
	var _4 = {
		FullYear: 2,
		Month: 4,
		Date: 6,
		Hours: 8,
		Minutes: 10,
		Seconds: 12,
		Milliseconds: 14
	};
	var _3 = {
		Hectomicroseconds: 15,
		UTC: 16,
		Sign: 17,
		Hours: 18,
		Minutes: 20
	};
	var _w = /(((00)?:0+)?:0+)?\.0+$/;
	var _x = /(T[0-9:.]+)$/;
	var Date2 = _6(Date,
		function(a, b, c, e, d, f, g) {
			switch (arguments.length) {
				case 0:
					return new Date;
				case 1:
					return typeof a == "number" ? new Date(a) : Date2.parse(a);
				default:
					return new Date(a, b, arguments.length == 2 ? 1 : c, e || 0, d || 0, f || 0, g || 0)
			}
		},
		"", {
			toISOString: function(c) {
				var e = "####-##-##T##:##:##.###";
				for (var d in _4) {
					e = e.replace(/#+/,
						function(a) {
							var b = c["getUTC" + d]();
							if (d == "Month") b++;
							return ("000" + b).slice(-a.length)
						})
				}
				return e.replace(_w, "").replace(_x, "$1Z")
			}
		});
	delete Date2.forEach;
	Date2.now = function() {
		return (new Date).valueOf()
	};
	Date2.parse = function(a, b) {
		if (arguments.length > 1) {
			assertType(b, "number", "default date should be of type 'number'.")
		}
		var c = match(a, _v);
		if (c.length) {
			if (c[_4.Month]) c[_4.Month] --;
			if (c[_3.Hectomicroseconds] >= 5) c[_4.Milliseconds] ++;
			var e = new Date(b || 0);
			var d = c[_3.UTC] || c[_3.Hours] ? "UTC" : "";
			for (var f in _4) {
				var g = c[_4[f]];
				if (!g) continue;
				e["set" + d + f](g);
				if (e["get" + d + f]() != c[_4[f]]) {
					return NaN
				}
			}
			if (c[_3.Hours]) {
				var i = Number(c[_3.Sign] + c[_3.Hours]);
				var h = Number(c[_3.Sign] + (c[_3.Minutes] || 0));
				e.setUTCMinutes(e.getUTCMinutes() + (i * 60) + h)
			}
			return e.valueOf()
		} else {
			return Date.parse(a)
		}
	};
	var String2 = _6(String,
		function(a) {
			return new String(arguments.length == 0 ? "" : a)
		},
		"charAt,charCodeAt,concat,indexOf,lastIndexOf,match,replace,search,slice,split,substr,substring,toLowerCase,toUpperCase", {
			csv: csv,
			format: format,
			rescape: rescape,
			trim: trim
		});
	delete String2.forEach;

	function trim(a) {
		return String(a).replace(_g, "").replace(_h, "")
	};

	function csv(a) {
		return a ? (a + "").split(/\s*,\s*/) : []
	};

	function format(c) {
		var e = arguments;
		var d = new RegExp("%([1-" + (arguments.length - 1) + "])", "g");
		return (c + "").replace(d,
			function(a, b) {
				return e[b]
			})
	};

	function match(a, b) {
		return (a + "").match(b) || []
	};

	function rescape(a) {
		return (a + "").replace(_i, "\\$1")
	};
	var Function2 = _6(Function, Function, "", {
		I: I,
		II: II,
		K: K,
		bind: bind,
		compose: compose,
		delegate: delegate,
		flip: flip,
		not: not,
		partial: partial,
		unbind: unbind
	});

	function I(a) {
		return a
	};

	function II(a, b) {
		return b
	};

	function K(a) {
		return function() {
			return a
		}
	};

	function bind(a, b) {
		var c = typeof a != "function";
		if (arguments.length > 2) {
			var e = _2.call(arguments, 2);
			return function() {
				return (c ? b[a] : a).apply(b, e.concat.apply(e, arguments))
			}
		} else {
			return function() {
				return (c ? b[a] : a).apply(b, arguments)
			}
		}
	};

	function compose() {
		var c = _2.call(arguments);
		return function() {
			var a = c.length,
				b = c[--a].apply(this, arguments);
			while (a--) b = c[a].call(this, b);
			return b
		}
	};

	function delegate(b, c) {
		return function() {
			var a = _2.call(arguments);
			a.unshift(this);
			return b.apply(c, a)
		}
	};

	function flip(a) {
		return function() {
			return a.apply(this, Array2.swap(arguments, 0, 1))
		}
	};

	function not(a) {
		return function() {
			return !a.apply(this, arguments)
		}
	};

	function partial(e) {
		var d = _2.call(arguments, 1);
		return function() {
			var a = d.concat(),
				b = 0,
				c = 0;
			while (b < d.length && c < arguments.length) {
				if (a[b] === undefined) a[b] = arguments[c++];
				b++
			}
			while (c < arguments.length) {
				a[b++] = arguments[c++]
			}
			if (Array2.contains(a, undefined)) {
				a.unshift(e);
				return partial.apply(null, a)
			}
			return e.apply(this, a)
		}
	};

	function unbind(b) {
		return function(a) {
			return b.apply(a, _2.call(arguments, 1))
		}
	};

	function detect() {
		var d = NaN
			/*@cc_on||@_jscript_version@*/
		;
		var f = global.java ? true : false;
		if (global.navigator) {
			var g = /MSIE[\d.]+/g;
			var i = document.createElement("span");
			var h = navigator.userAgent.replace(/([a-z])[\s\/](\d)/gi, "$1$2");
			if (!d) h = h.replace(g, "");
			if (g.test(h)) h = h.match(g)[0] + " " + h.replace(g, "");
			base2.userAgent = navigator.platform + " " + h.replace(/like \w+/gi, "");
			f &= navigator.javaEnabled()
		}
		var j = {};
		detect = function(a) {
			if (j[a] == null) {
				var b = false,
					c = a;
				var e = c.charAt(0) == "!";
				if (e) c = c.slice(1);
				if (c.charAt(0) == "(") {
					try {
						b = new Function("element,jscript,java,global", "return !!" + c)(i, d, f, global)
					} catch (ex) {}
				} else {
					b = new RegExp("(" + c + ")", "i").test(base2.userAgent)
				}
				j[a] = !!(e ^ b)
			}
			return j[a]
		};
		return detect(arguments[0])
	};
	base2 = global.base2 = new Package(this, base2);
	var exports = this.exports;
	lang = new Package(this, lang);
	exports += this.exports;
	JavaScript = new Package(this, JavaScript);
	eval(exports + this.exports);
	lang.base = base;
	lang.extend = extend
};

new function() {
	new base2.Package(this, {
		imports: "Function2,Enumerable"
	});
	eval(this.imports);
	var i = RegGrp.IGNORE;
	var S = "~";
	var A = "";
	var F = " ";
	var p = RegGrp.extend({
		put: function(a, c) {
			if (typeOf(a) == "string") {
				a = p.dictionary.exec(a)
			}
			this.base(a, c)
		}
	}, {
		dictionary: new RegGrp({
			OPERATOR: /return|typeof|[\[(\^=,{}:;&|!*?]/.source,
			CONDITIONAL: /\/\*@\w*|\w*@\*\/|\/\/@\w*|@\w+/.source,
			COMMENT1: /\/\/[^\n]*/.source,
			COMMENT2: /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source,
			REGEXP: /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source,
			STRING1: /'(\\.|[^'\\])*'/.source,
			STRING2: /"(\\.|[^"\\])*"/.source
		})
	});
	var B = Collection.extend({
		add: function(a) {
			if (!this.has(a)) this.base(a);
			a = this.get(a);
			if (!a.index) {
				a.index = this.size()
			}
			a.count++;
			return a
		},
		sort: function(d) {
			return this.base(d || function(a, c) {
				return (c.count - a.count) || (a.index - c.index)
			})
		}
	}, {
		Item: {
			constructor: function(a) {
				this.toString = K(a)
			},
			index: 0,
			count: 0,
			encoded: ""
		}
	});
	var v = Base.extend({
		constructor: function(a, c, d) {
			this.parser = new p(d);
			if (a) this.parser.put(a, "");
			this.encoder = c
		},
		parser: null,
		encoder: Undefined,
		search: function(c) {
			var d = new B;
			this.parser.putAt(-1, function(a) {
				d.add(a)
			});
			this.parser.exec(c);
			return d
		},
		encode: function(c) {
			var d = this.search(c);
			d.sort();
			var b = 0;
			forEach(d, function(a) {
				a.encoded = this.encoder(b++)
			}, this);
			this.parser.putAt(-1, function(a) {
				return d.get(a).encoded
			});
			return this.parser.exec(c)
		}
	});
	var w = v.extend({
		constructor: function() {
			return this.base(w.PATTERN, function(a) {
				return "_" + Packer.encode62(a)
			}, w.IGNORE)
		}
	}, {
		IGNORE: {
			CONDITIONAL: i,
			"(OPERATOR)(REGEXP)": i
		},
		PATTERN: /\b_[\da-zA-Z$][\w$]*\b/g
	});
	var q = v.extend({
		encode: function(d) {
			var b = this.search(d);
			b.sort();
			var f = new Collection;
			var e = b.size();
			for (var h = 0; h < e; h++) {
				f.put(Packer.encode62(h), h)
			}

			function C(a) {
				return b["#" + a].replacement
			};
			var k = K("");
			var l = 0;
			forEach(b, function(a) {
				if (f.has(a)) {
					a.index = f.get(a);
					a.toString = k
				} else {
					while (b.has(Packer.encode62(l))) l++;
					a.index = l++;
					if (a.count == 1) {
						a.toString = k
					}
				}
				a.replacement = Packer.encode62(a.index);
				if (a.replacement.length == a.toString().length) {
					a.toString = k
				}
			});
			b.sort(function(a, c) {
				return a.index - c.index
			});
			b = b.slice(0, this.getKeyWords(b).split("|").length);
			d = d.replace(this.getPattern(b), C);
			var r = this.escape(d);
			var m = "[]";
			var t = this.getCount(b);
			var g = this.getKeyWords(b);
			var n = this.getEncoder(b);
			var u = this.getDecoder(b);
			return format(q.UNPACK, r, m, t, g, n, u)
		},
		search: function(a) {
			var c = new B;
			forEach(a.match(q.WORDS), c.add, c);
			return c
		},
		escape: function(a) {
			return a.replace(/([\\'])/g, "\\$1").replace(/[\r\n]+/g, "\\n")
		},
		getCount: function(a) {
			return a.size() || 1
		},
		getDecoder: function(c) {
			var d = new RegGrp({
				"(\\d)(\\|\\d)+\\|(\\d)": "$1-$3",
				"([a-z])(\\|[a-z])+\\|([a-z])": "$1-$3",
				"([A-Z])(\\|[A-Z])+\\|([A-Z])": "$1-$3",
				"\\|": ""
			});
			var b = d.exec(c.map(function(a) {
				if (a.toString()) return a.replacement;
				return ""
			}).slice(0, 62).join("|"));
			if (!b) return "^$";
			b = "[" + b + "]";
			var f = c.size();
			if (f > 62) {
				b = "(" + b + "|";
				var e = Packer.encode62(f).charAt(0);
				if (e > "9") {
					b += "[\\\\d";
					if (e >= "a") {
						b += "a";
						if (e >= "z") {
							b += "-z";
							if (e >= "A") {
								b += "A";
								if (e > "A") b += "-" + e
							}
						} else if (e == "b") {
							b += "-" + e
						}
					}
					b += "]"
				} else if (e == 9) {
					b += "\\\\d"
				} else if (e == 2) {
					b += "[12]"
				} else if (e == 1) {
					b += "1"
				} else {
					b += "[1-" + e + "]"
				}
				b += "\\\\w)"
			}
			return b
		},
		getEncoder: function(a) {
			var c = a.size();
			return q["ENCODE" + (c > 10 ? c > 36 ? 62 : 36 : 10)]
		},
		getKeyWords: function(a) {
			return a.map(String).join("|").replace(/\|+$/, "")
		},
		getPattern: function(a) {
			var a = a.map(String).join("|").replace(/\|{2,}/g, "|").replace(/^\|+|\|+$/g, "") || "\\x0";
			return new RegExp("\\b(" + a + ")\\b", "g")
		}
	}, {
		WORDS: /\b[\da-zA-Z]\b|\w{2,}/g,
		ENCODE10: "String",
		ENCODE36: "function(c){return c.toString(36)}",
		ENCODE62: "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}",
		UNPACK: "eval(function(p,a,c,k,e,r){e=%5;if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];k=[function(e){return r[e]||e}];e=function(){return'%6'};c=1};while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('%1',%2,%3,'%4'.split('|'),0,{}))"
	});
	global.Packer = Base.extend({
		constructor: function() {
			this.minifier = new j;
			this.shrinker = new o;
			this.privates = new w;
			this.base62 = new q
		},
		minifier: null,
		shrinker: null,
		privates: null,
		base62: null,
		pack: function(a, c, d, b) {
			a = this.minifier.minify(a);
			if (d) a = this.shrinker.shrink(a);
			if (b) a = this.privates.encode(a);
			if (c) a = this.base62.encode(a);
			return a
		}
	}, {
		version: "3.1",
		init: function() {
			eval("var e=this.encode62=" + q.ENCODE62)
		},
		data: new p({
			"STRING1": i,
			'STRING2': i,
			"CONDITIONAL": i,
			"(OPERATOR)\\s*(REGEXP)": "$1$2"
		}),
		encode52: function(c) {
			function d(a) {
				return (a < 52 ? '' : d(parseInt(a / 52))) + ((a = a % 52) > 25 ? String.fromCharCode(a + 39) : String.fromCharCode(a + 97))
			};
			var b = d(c);
			if (/^(do|if|in)$/.test(b)) b = b.slice(1) + 0;
			return b
		}
	});
	var j = Base.extend({
		minify: function(a) {
			a += "\n";
			a = a.replace(j.CONTINUE, "");
			a = j.comments.exec(a);
			a = j.clean.exec(a);
			a = j.whitespace.exec(a);
			a = j.concat.exec(a);
			return a
		}
	}, {
		CONTINUE: /\\\r?\n/g,
		init: function() {
			this.concat = new p(this.concat).merge(Packer.data);
			extend(this.concat, "exec", function(a) {
				var c = this.base(a);
				while (c != a) {
					a = c;
					c = this.base(a)
				}
				return c
			});
			forEach.csv("comments,clean,whitespace", function(a) {
				this[a] = Packer.data.union(new p(this[a]))
			}, this);
			this.conditionalComments = this.comments.copy();
			this.conditionalComments.putAt(-1, " $3");
			this.whitespace.removeAt(2);
			this.comments.removeAt(2)
		},
		clean: {
			"\\(\\s*([^;)]*)\\s*;\\s*([^;)]*)\\s*;\\s*([^;)]*)\\)": "($1;$2;$3)",
			"throw[^};]+[};]": i,
			";+\\s*([};])": "$1"
		},
		comments: {
			";;;[^\\n]*\\n": A,
			"(COMMENT1)\\n\\s*(REGEXP)?": "\n$3",
			"(COMMENT2)\\s*(REGEXP)?": function(a, c, d, b) {
				if (/^\/\*@/.test(c) && /@\*\/$/.test(c)) {
					c = j.conditionalComments.exec(c)
				} else {
					c = ""
				}
				return c + " " + (b || "")
			}
		},
		concat: {
			"(STRING1)\\+(STRING1)": function(a, c, d, b) {
				return c.slice(0, -1) + b.slice(1)
			},
			"(STRING2)\\+(STRING2)": function(a, c, d, b) {
				return c.slice(0, -1) + b.slice(1)
			}
		},
		whitespace: {
			"\\/\\/@[^\\n]*\\n": i,
			"@\\s+\\b": "@ ",
			"\\b\\s+@": " @",
			"(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])": "$1 $2",
			"([+-])\\s+([+-])": "$1 $2",
			"\\b\\s+\\$\\s+\\b": " $ ",
			"\\$\\s+\\b": "$ ",
			"\\b\\s+\\$": " $",
			"\\b\\s+\\b": F,
			"\\s+": A
		}
	});
	var o = Base.extend({
		decodeData: function(d) {
			var b = this._data;
			delete this._data;
			return d.replace(o.ENCODED_DATA, function(a, c) {
				return b[c]
			})
		},
		encodeData: function(f) {
			var e = this._data = [];
			return Packer.data.exec(f, function(a, c, d) {
				var b = "\x01" + e.length + "\x01";
				if (d) {
					b = c + b;
					a = d
				}
				e.push(a);
				return b
			})
		},
		shrink: function(g) {
			g = this.encodeData(g);

			function n(a) {
				return new RegExp(a.source, "g")
			};
			var u = /((catch|do|if|while|with|function)\b[^~{};]*(\(\s*[^{};]*\s*\))\s*)?(\{[^{}]*\})/;
			var G = n(u);
			var x = /\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/;
			var H = n(x);
			var D = /~#?(\d+)~/;
			var I = /[a-zA-Z_$][\w\$]*/g;
			var J = /~#(\d+)~/;
			var L = /\bvar\b/g;
			var M = /\bvar\s+[\w$]+[^;#]*|\bfunction\s+[\w$]+/g;
			var N = /\b(var|function)\b|\sin\s+[^;]+/g;
			var O = /\s*=[^,;]*/g;
			var s = [];
			var E = 0;

			function P(a, c, d, b, f) {
				if (!c) c = "";
				if (d == "function") {
					f = b + y(f, J);
					c = c.replace(x, "");
					b = b.slice(1, -1);
					if (b != "_no_shrink_") {
						var e = match(f, M).join(";").replace(L, ";var");
						while (x.test(e)) {
							e = e.replace(H, "")
						}
						e = e.replace(N, "").replace(O, "")
					}
					f = y(f, D);
					if (b != "_no_shrink_") {
						var h = 0,
							C;
						var k = match([b, e], I);
						var l = {};
						for (var r = 0; r < k.length; r++) {
							id = k[r];
							if (!l["#" + id]) {
								l["#" + id] = true;
								id = rescape(id);
								while (new RegExp(o.PREFIX + h + "\\b").test(f)) h++;
								var m = new RegExp("([^\\w$.])" + id + "([^\\w$:])");
								while (m.test(f)) {
									f = f.replace(n(m), "$1" + o.PREFIX + h + "$2")
								}
								var m = new RegExp("([^{,\\w$.])" + id + ":", "g");
								f = f.replace(m, "$1" + o.PREFIX + h + ":");
								h++
							}
						}
						E = Math.max(E, h)
					}
					var t = c + "~" + s.length + "~";
					s.push(f)
				} else {
					var t = "~#" + s.length + "~";
					s.push(c + f)
				}
				return t
			};

			function y(d, b) {
				while (b.test(d)) {
					d = d.replace(n(b), function(a, c) {
						return s[c]
					})
				}
				return d
			};
			while (u.test(g)) {
				g = g.replace(G, P)
			}
			g = y(g, D);
			var z, Q = 0;
			var R = new v(o.SHRUNK, function() {
				do z = Packer.encode52(Q++); while (new RegExp("[^\\w$.]" + z + "[^\\w$:]").test(g));
				return z
			});
			g = R.encode(g);
			return this.decodeData(g)
		}
	}, {
		ENCODED_DATA: /\x01(\d+)\x01/g,
		PREFIX: "\x02",
		SHRUNK: /\x02\d+\b/g
	})
};
