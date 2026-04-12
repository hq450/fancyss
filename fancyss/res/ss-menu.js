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

function buildDataAttrs(data) {
	var out = '';
	if (!data) return out;
	for (var key in data) {
		if (!data.hasOwnProperty(key)) continue;
		var attr = key.replace(/[A-Z]/g, function(m) {
			return '-' + m.toLowerCase();
		});
		out += ' data-' + attr + '="' + escapeHTML(UT(data[key])) + '"';
	}
	return out;
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
		var dataAttrs = buildDataAttrs(v.data);
		if (v.th) {
			form += '<tr' + ((v.rid) ? ' id="' + v.rid + '"' : '') + ((v.class) ? ' class="' + v.class + '"' : '') + dataAttrs + '><th colspan="' + v.th + '">' + v.title + '</th></tr>';
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
		form += '<tr' + ((v.rid) ? ' id="' + v.rid + '"' : '') + ((v.class) ? ' class="' + v.class + '"' : '') + dataAttrs + ((v.hidden) ? ' style="display: none;"' : '') + '>';
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
					common += ' class="input_ss_table fcx-mask" data-lpignore="true" data-1p-ignore="true" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"';
					if (f.style) common += ' style="' + f.style + '"';
					if (f.peekaboo) common += ' readonly onBlur="toggleKeyMask(this, false);" onfocus="this.removeAttribute(' + '\'readonly\'' + ');toggleKeyMask(this, true);"';
					output += '<input type="text"' + ' value="' + escapeHTML(UT(f.value)) + '"' + (f.maxlen ? (' maxlength="' + f.maxlen + '" ') : '') + common + '>';
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
		if (v.hint) form += '<th><a class="hintstyle" style="color:#03a9f4;" href="javascript:void(0);" onclick="openssHint(' + v.hint + ', 0)" onmouseover="mOver(this, ' + v.hint + ')" onmouseout="RunmOut(this)" >' + v.title + '</a></th><td>' + output;
		else if (v.thtd) form += '<th>' + v.title + '</th><td>' + output;
		else form += '<th>' + v.title + '</th><td>' + output;
		form += '</td></tr>';
	});
	return form;
}
function pop_111() {
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
}
function pop_help() {
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
			、<a target="_blank" href="https://github.com/Itsusinn/tuic"><u>tuic</u></a>\
			七种客户端的科学上网、游戏加速工具。<br \><br \>\
			本插件支持以Asuswrt、Asuswrt-Merlin为基础的，带软件中心的固件，目前固件均由<a style="color:#e7bd16" target="_blank" href="https://www.koolcenter.com/">https:\/\/www.koolcenter.com/</a>提供。<br \><br \>\
			使用本插件有任何问题，可以前往<a style="color:#e7bd16" target="_blank" href="https://github.com/hq450/fancyss/issues"><u>github的issue页面</u></a>反馈~<br \><br \>\
			● 插件交流：<a style="color:#e7bd16" target="_blank" href="https://t.me/+PzdfDBssIIFmMThl"><u>加入telegram群组</u></a><br \><br \>\
			我们的征途是星辰大海 ^_^</div>'
	});
}
function pop_node_add() {
	note = "<li>检测到你尚未添加任何代理节点！你至少需要一个节点，才能让插件正常工作！</li><br /> ";
	note += "<li>如果你已经有节点，请从【手动添加】【节点订阅】【恢复配置】中选择一种添加。</li><br />";
	layer.open({
		type: 0,
		skin: 'layui-layer-lan',
		shade: 0.8,
		title: '提醒',
		area: ['620px', '220px'],
		time: 0,
		btnAlign: 'c',
		maxmin: true,
		content: note,
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
		success: function(layero, index){
			console.log(index);
			var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
			var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
			var elem_h = E("layui-layer" + index).clientHeight;
			var elem_w = E("layui-layer" + index).clientWidth;
			var elem_h_offset = (page_h - elem_h) / 2 - 90;
			var elem_w_offset = (page_w - elem_w) / 2 + 90;
			if(elem_h_offset < 0){
				elem_h_offset = 10;
			}
			$('#layui-layer' + index).offset({top: elem_h_offset, left: elem_w_offset});
		}
	});
	poped = 1;
}

function pop_node_add_ads() {
	note = "<li>检测到你尚未添加任何代理节点！你至少需要一个节点，才能让插件正常工作！</li><br /> ";
	note += "<li>如果你已经有节点，请从【手动添加】【节点订阅】【恢复配置】中选择一种添加。</li><br />";
	note += "<li>如果你没有节点且不知道如何购买或搭建，可以点击【机场推荐】购买本插件推荐的机场<br />";
	layer.open({
		type: 0,
		skin: 'layui-layer-lan',
		shade: 0.8,
		title: '提醒',
		area: ['620px', '280px'],
		time: 0,
		btnAlign: 'c',
		maxmin: true,
		content: note,
		btn: ['手动添加', '订阅节点', '恢复配置', '机场推荐'],
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
		btn4: function() {
			window.open(
				ads_url_1,
				'_blank'
			);
			return false;
		},
		success: function(layero, index){
			console.log(index);
			var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
			var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
			var elem_h = E("layui-layer" + index).clientHeight;
			var elem_w = E("layui-layer" + index).clientWidth;
			var elem_h_offset = (page_h - elem_h) / 2 - 90;
			var elem_w_offset = (page_w - elem_w) / 2 + 90;
			if(elem_h_offset < 0){
				elem_h_offset = 10;
			}
			$('#layui-layer' + index).offset({top: elem_h_offset, left: elem_w_offset});
		}
	});
	poped = 1;
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
	tabtitle[tabtitle.length - 1] = new Array("", "fancyss科学上网", "__INHERIT__");
	tablink[tablink.length - 1] = new Array("", "Module_shadowsocks.asp", "NULL");
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
	document.getElementById("loadingBarBlock").style.width = 780 + "px";
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
	} else if (action == 28) {
		document.getElementById("loading_block3").innerHTML = "xray分流模式启用中 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在生成节点分流配置 ...</font></li><li><font color='#ffcc00'>所有剩余流量会走兜底节点，命中规则的流量会按顺序切换到对应出站节点。</font></li>");
	} else if (action == 7) {
		document.getElementById("loading_block3").innerHTML = "科学上网插件升级 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>升级服务会自动检测最新版本并下载升级...</font></li>");
	} else if (action == 8) {
		document.getElementById("loading_block3").innerHTML = "科学上网规则更新 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，等待脚本运行完毕后再刷新！</font></li><li><font color='#ffcc00'>正在自动检测github上的更新...</font></li>");
	} else if (action == 9) {
		document.getElementById("loading_block3").innerHTML = "恢复科学上网配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，配置恢复后需要重新提交！</font></li><li><font color='#ffcc00'>恢复配置中...</font></li><li><font color='#ffcc00'>旧版兼容SH备份恢复时间可能较长，请耐心等待日志输出。</font></li>");
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
	} else if (action == 25) {
		document.getElementById("loading_block3").innerHTML = "生成旧版兼容配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在生成旧版兼容配置...</font></li><li><font color='#ffcc00'>节点较多时耗时会比较长，日志会显示导出阶段和节点进度。</font></li>");
	} else if (action == 26) {
		document.getElementById("loading_block3").innerHTML = "生成新版本JSON配置 ..."
		$("#loading_block2").html("<li><font color='#ffcc00'>请勿刷新本页面，正在整理新版本JSON配置...</font></li>");
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
	$("#overDiv").unbind();
	$(obj).css({
		"color": "#00ffe4",
		"text-decoration": "underline"
	});
	openssHint(hint, mouse_status);
}
function mOut(obj){
	if (mouse_status == 0) return;
	if ($("#overDiv").is(":hover") == false){
		E("overDiv").style.visibility = "hidden";
	}else{
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
	mOut("' + obj + '");
}
var ol_textfont="Lucida Console";
var ol_captionfont="Lucida Console";
var ol_closefont="Lucida Console";

function openssHint(itemNum, flag) {
	mouse_status = flag;
	statusmenu = "";
	width = "350px";
	if (itemNum == 0) {
		width = "820px";
		bgcolor = "#CC0066",
			statusmenu = "<li>插件运行状态会定时请求你在【web延迟测试】中设置的检测网址，只取HTTP响应头，不下载完整网页；显示的延迟是HTTP响应时间，不是传统ping。</li>"
		statusmenu += "<br /><li><font color='#00F'>未开启IPv6代理：</font>国外检测优先使用 <font color='#669900'>-x socks5://127.0.0.1:23456</font>，主要检查节点可用性和路由器本机DNS解析是否正常，这是当前IPv4场景的默认最佳实践。</li>"
		statusmenu += "<br /><li><font color='#00F'>开启IPv6代理：</font>国外检测会拆分为【国外IPv4】和【国外IPv6】；两项都会直接走透明代理链路，不再使用 <font color='#669900'>-x socks5</font>，这样才能正确检测IPv6透明代理，同时把DNS、ipset、iptables、透明代理一起覆盖到。</li>"
		statusmenu += "<br /><li><font color='#00F'>提示：</font>web 延迟测试地址使用插件内置检测网址；开启IPv6代理时，建议优先选择支持 IPv6 的国外检测网址。故障转移中的国外状态历史仍然只记录IPv4结果。</li>"
		statusmenu += "<br /><li><font color='#00F'>边界说明：</font>这里的检测结果用于判断当前 fancyss 运行链路对测试域名的访问情况，不等同于节点本身可用性检测；节点可用性请结合 web 延迟测试、详细状态和终端实际访问一起判断。</li>"
		statusmenu += "<br /><br /><b><font color='#CC0066'>常见结果说明：</font></b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>1. 国外IPv4 √，国外IPv6 X：</font>节点大概率不支持IPv6，或者远端协议/服务器未提供IPv6能力，建议关闭IPv6代理。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>2. 国内√，国外X：</font>优先检查节点配置、服务器可用性、国外DNS、程序运行状态，以及iptables/ipset是否正常。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>3. 国内X，国外√：</font>通常是国内DNS、WAN连通性，或本地网络环境异常。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>4. 双X：</font>通常是插件未正确启动、DNS异常、WAN故障，或节点本身不可用。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<font color='#00F'>5. 双√但终端仍异常：</font><b>重点先做这3项：</b>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;5.1 刷新终端DNS缓存/浏览器缓存，手机可开关飞行模式后重试；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;5.2 把终端自定义DNS改为自动获取，避免本地DNS污染或绕过路由器DNS；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;5.3 清理终端hosts或其它本地解析覆盖规则，避免域名被错误指向。"
		statusmenu += "<br /><br />如果需要进一步定位，请结合【详细状态】和【故障转移】-【查看历史状态】一起判断。"
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
	} else if (itemNum == 11) {
		statusmenu = "如果不知道如何填写，请一定留空，不然可能带来副作用！"
		statusmenu += "<br /><br />请参考<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(8)'><font color='#00F'>协议插件（protocol）</font></a>和<a class='hintstyle' href='javascript:void(0);' onclick='openssHint(9)'><font color='#00F'>混淆插件 (obfs)</font></a>内说明。"
		statusmenu += "<br /><br />更多信息，请参考<a href='https://github.com/koolshare/shadowsocks-rss/blob/master/ssr.md' target='_blank'><u><font color='#00F'>ShadowsocksR 协议插件文档</font></u></a>"
		_caption = "自定义参数 (obfs_param)";
	} else if (itemNum == 24) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;导出功能可以将ss所有的设置全部导出，包括节点信息，dns设定，黑白名单设定等；"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;恢复配置功能可以使用之前导出的文件，也可以使用标准的json格式节点文件。"
		_caption = "导出恢复";
	} else if (itemNum == 27) {
		statusmenu = "<br /><font color='#CC0066'><b>1:不勾选（自动生成json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式只支持vmess作为传出协议，不支持socks，shadowsocks，vless；提交后会根据你的配置自动生成v2ray的json配置。"
		statusmenu += "<br /><br /><font color='#CC0066'><b>3:勾选（自定义json）：</b></font>"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;此方式支持配置v2ray支持的所有传出协议，包括vmess、vless、socks，shadowsocks等，插件会取你的json的outbound/outbounds部分，并自动配置透明代理和socks传进协议，以便在路由器上工作。"
		statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;如果使用Xray作为核心【附加功能处启用】，v2ray json配置方式还可以配置仅xray支持的协议，比如vless-tcp + xtls。"
		_caption = "使用json配置";
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
		} else if (itemNum == 29) {
			width = "750px";
			statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings】位置，常见如下："
			statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;1) ws: 【wsSettings → path】"
			statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;2) h2: 【httpSettings → path】"
			statusmenu += "<br />&nbsp;&nbsp;&nbsp;&nbsp;3) httpupgrade: 【httpupgradeSettings → path】（部分核心/版本可能命名不同）"
			statusmenu += "<br /><br />没有请留空，一般以 / 开头，例如：/ray 或 /";
			_caption = "路径 (path)";
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
		statusmenu = "shadowsocks规则更新包括了gfwlist模式中用到的<a href='https://github.com/hq450/fancyss/blob/master/rules/gfwlist.conf' target='_blank'><font color='#00F'><u>gfwlist</u></font></a>，在大陆白名单模式和游戏模式中用到的<a href='https://github.com/hq450/fancyss/blob/master/rules/chnroute.txt' target='_blank'><u><font color='#00F'>chnroute</font></u></a>和<a href='https://github.com/hq450/fancyss/blob/master/rules/chnlist.txt' target='_blank'><u><font color='#00F'>国内cdn名单</font></u></a>"
		statusmenu += "<br />建议更新时间在凌晨闲时进行，以避免更新时重启ss服务器造成网络访问问题。"
		_caption = "shadowsocks规则自动更新";
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
		statusmenu = "<br />此参数在客户端json配置文件的【outbound/outbounds → streamSettings → tlsSettings → allowInsecure】位置。<br /><br />勾选后会跳过证书校验，仅建议在自签证书、测试环境，或服务提供方明确要求时使用。<br /><br />Xray-core 计划于 2026 年 6 月 1 日移除 allowInsecure，建议尽快改用 pinnedPeerCertSha256（pcs）/ verifyPeerCertByName（vcn）。";
		_caption = "AllowInsecure";
	} else if (itemNum == 151) {
		width = "600px";
		statusmenu = "<b>追加ISP DNS：</b><br /><br />"
		statusmenu += "开启此处后，在smartdns的配置文件中的server配置中，中国国内组(group chn)将自动追加ISP DNS，以获得更好的CDN解析。<br />"
		_caption = "说明：";
	} else if (itemNum == 104) {
		width = "600px";
		statusmenu = "<b>屏蔽BlockList域名解析：</b><br /><br />"
		statusmenu += "fancyss提供了一份屏蔽域名解析名单：<a href='https://github.com/hq450/fancyss/blob/3.0/rules_ng/block_list.txt' target='_blank'><u><font color='#00F'>block list</font></u></a>，目前该list收录了一些Adobe激活相关的域名，开启后这些域名将不会得到解析，如果你使用正版adobe软件，请保持此处关闭。<br />"
		_caption = "说明：";
	} else if (itemNum == 105) {
		width = "600px";
		statusmenu = "<b>替换dnsmasq：</b><br /><br />"
		statusmenu += "开启此处后，将会关闭dnsmasq的dns服务器功能，chinadns-ng、smartdns将监听在53端口，以提供dns服务，这将让DNS请求再减少一层转发。<br />"
		statusmenu += "由于华硕/梅林机型的一些服务和dnsmasq深度绑定，部分机型替换后可能会有问题，请谨慎使用此功能，。<br />"
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
	} else if (itemNum == 110) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;匹配节点名称和节点域名/IP，含关键词的节点不会添加，多个关键词用<font color='#00F'>英文逗号</font>分隔，关键词支持中文、英文、数字，如：<font color='#CC0066'>测试,过期,剩余,曼谷,M247,D01,硅谷</font><br />&nbsp;&nbsp;&nbsp;&nbsp;此功能支持SS/SSR/V2ray/Xray订阅，<font color='#00F'>[排除]关键词</font>功能和<font color='#00F'>[包括]关键词</font>功能同时起作用。"
		_caption = "[排除]关键词：";
	} else if (itemNum == 111) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;匹配节点名称和节点域名/IP，含关键词的节点才会添加，多个关键词用<font color='#00F'>英文逗号</font>分隔，关键词支持中文、英文、数字，如：<font color='#CC0066'>香港,深圳,NF,BGP</font><br />&nbsp;&nbsp;&nbsp;&nbsp;此功能支持SS/SSR/V2ray/Xray订阅，<font color='#00F'>[排除]关键词</font>功能和<font color='#00F'>[包括]关键词</font>功能同时起作用。"
		_caption = "[包括]关键词：";
	} else if (itemNum == 112) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;一些机场需要特定的UA才能获得通用订阅，如果你使用默认订阅无法获得正确的而节点，可以尝试切换不同的UA来进行订阅！";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;fancyss 3.3.8及其以前版本使用的UA是：curl/wget。";
		_caption = "说明";
	} else if (itemNum == 113) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;一些机场的vmess/vless/trojan/hysteria2节点必须设置允许不安全才能工作，勾选这里后订阅的节点将默认启用允许不安全！";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;如果不勾选，允许不安全设定将跟随机场订阅设定(如果机场有此设定的话)。";
		_caption = "说明";
	} else if (itemNum == 117) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;当订阅解析走sub-tool时，默认只输出解析摘要。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;开启后会把每个成功保留的节点逐条写入订阅日志，便于排查订阅内容、过滤结果和节点名称。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;注意：逐节点日志会明显增加日志I/O，节点很多时会拖慢订阅速度，建议仅在调试时开启。";
		_caption = "说明";
	} else if (itemNum == 118) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;有些机场会把剩余流量、到期时间、同步时间等信息伪装成普通节点放在订阅前几条。默认会自动过滤这些“订阅信息节点”。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;如果你希望把这些信息节点也保留到节点列表中，请开启此开关。";
		statusmenu += "<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;开启后，这些信息节点将参与订阅结果校验；像Sync这类每次都会变化的信息，可能会让订阅更频繁地判定为“节点发生变更”。";
		_caption = "说明";
	} else if (itemNum == 116) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处填入你的机场订阅链接，通常是http://或https://开头的链接，多个链接可以分行填写！<br />&nbsp;&nbsp;&nbsp;&nbsp;也可以增加非http开头的行作为注释，或使用空行或者符号线作为分割，订阅脚本仅会提取http://或https://开头的链接用以订阅，示例：<br />-------------------------------------------------<br />🚀魅影极速<br />https://subserver.maying.io/xxx<br /><br />🛩️nextitally<br />https://naixisubs.com/downloadConfig/xxx<br />-------------------------------------------------"
		_caption = "订阅地址管理";
	} else if (itemNum == 133) {
		width = "640px";
		statusmenu = "<div style='padding-left:16px;padding-right:16px;line-height:1.5'>";
		statusmenu += "<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。";
		statusmenu += "chinadns-ng支持自定义多组中国DNS和可信DNS作为上游DNS，中国DNS用于解析中国域名，可信DNS用于解析境外域名，具体情况见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng的工作原理</font></u></a>。";
		statusmenu += "<br />";
		statusmenu += "<br />";
		statusmenu += "建议可以开启替换dnsmasq功能，这样DNS查询将少一层经过dnsmasq的转发，此时dnsmasq将关闭53端口的DNS查询功能，只保留基础的dhcp等功能。";
		statusmenu += "<br />";
		statusmenu += "----------------------------------------------------------------------------<br />";
		statusmenu += "未开启替换dnsmasq功能：<br />";
		statusmenu += "<font color='#F00'>udp：DNS请求 → dnsmasq → chinadns-ng(匹配国内域名) → 国内直连 → 国内udp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>tcp：DNS请求 → dnsmasq → chinadns-ng(匹配国内域名) → 国内直连 → 国内tcp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>dot：DNS请求 → dnsmasq → chinadns-ng(匹配国内域名) → 国内直连 → 国内dot DNS服务器</font><br />";
		statusmenu += "----------------------------------------------------------------------------<br />";
		statusmenu += "开启替换dnsmasq功能后：<br />";
		statusmenu += "<font color='#F00'>udp：DNS请求 → chinadns-ng(匹配国内域名) → 国内直连 → 国内udp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>tcp：DNS请求 → chinadns-ng(匹配国内域名) → 国内直连 → 国内tcp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>dot：DNS请求 → chinadns-ng(匹配国内域名) → 国内直连 → 国内dot DNS服务器</font><br />";
		statusmenu += "----------------------------------------------------------------------------<br />";
		statusmenu += "1️⃣需要至少开启一组中国DNS，三组不能设置相同的中国DNS，不能任两组都使用同样的设定。<br />";
		statusmenu += "2️⃣国内建议设置至少一组运营商DNS，通常来说，使用运营商DNS可以获得较好的DNS查询效果。<br />";
		statusmenu += "3️⃣教育网环境，建议使用运营商DNS或者教育网DNS，也可以增加一个公共DNS配合使用。<br />";
		statusmenu += "4️⃣DNS的选择没有绝对的最佳可言，适合自己的才是最好的，不懂的建议直接使用运营商DNS。<br />";
		statusmenu += "</div>";
		_caption = "说明：";
		$("#overDiv_table5").css("line-height", "1.4");
	} else if (itemNum == 134) {
		width = "800px";
		statusmenu = "<div style='padding-left:16px;padding-right:16px;line-height:1.5'>";
		statusmenu += "<a href='https://github.com/zfl9/chinadns-ng' target='_blank'><u><font color='#00F'>chinadns-ng</font></u></a>是一款非常好用的DNS分流查询工具，作者是<a href='https://github.com/zfl9' target='_blank'><u><font color='#00F'>zfl9</font></u></a>。";
		statusmenu += "chinadns-ng支持自定义多组中国DNS和可信DNS作为上游DNS，中国DNS用于解析中国域名，可信DNS用于解析境外域名，具体情况见<a href='https://github.com/zfl9/chinadns-ng#工作原理' target='_blank'><u><font color='#00F'>chinadns-ng的工作原理</font></u></a>。";
		statusmenu += "<br /><br />";
		statusmenu += "在可信DNS设定中，为了保证DNS解析结果可靠无污染，因此本插件默认会将所有的国外DNS请求都经过代理，即<b>远端DNS解析</b>。经过代理进行解析，相当于DNS请求是国外代理服务器自己发起的解析请求，国外DNS服务器会自动根据代理服务器的位置，返回地理位置最近（速度最快）的解析结果。因此，不论是udp、tcp还是dot协议，只要是远端DNS解析，解析效果理论上都是最佳的。";
		statusmenu += "<br /><br />";
		statusmenu += "对于udp DNS服务器而言，需要代理节点和代理软件都支持udp，缺一不可。如果代理节点不支持udp，或者代理软件不支持udp代理，比如naiveproxy节点，就无法使用udp DNS。对于tcp DNS和dot DNS而言，两者的解析都会走tcp协议，所以只要代理协议支持tcp代理就能保证解析。而目前几乎所有的代理软件都能代理tcp协议，所以建议至少设置一组tcp/dot协议的DNS作为可信DNS！";
		statusmenu += "<br /><br />";
		statusmenu += "另外，即使你的代理软件和代理服务器都支持udp协议，也不建议在可信DNS中只设置一个udp DNS上游，因为udp协议本身“不可靠”的特点，加上可能存在的QoS等情况，可能会出现某次解析失败的问题，所以在可信DNS设置中，建议至少建议至少设置一组tcp/dot协议的DNS作为可信DNS！";
		statusmenu += "<br /><br />";
		statusmenu += "另外，建议可以开启替换dnsmasq功能，这样DNS查询将少一层经过dnsmasq的转发，此时dnsmasq将关闭53端口的DNS查询功能，只保留基础的dhcp等功能。<br />";
		statusmenu += "-----------------------------------------------------------------------<br />";
		statusmenu += "未开启替换dnsmasq功能：<br />";
		statusmenu += "<font color='#F00'>udp：DNS请求 → dnsmasq → chinadns-ng(匹配国外域名) → 节点udp代理 → 国外udp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>tcp：DNS请求 → dnsmasq → chinadns-ng(匹配国外域名) → 节点tcp代理 → 国外tcp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>dot：DNS请求 → dnsmasq → chinadns-ng(匹配国外域名) → 节点tcp代理 → 国外dot DNS服务器</font><br />";
		statusmenu += "-----------------------------------------------------------------------<br />";
		statusmenu += "开启替换dnsmasq功能后：<br />";
		statusmenu += "<font color='#F00'>udp：DNS请求 → chinadns-ng(匹配国外域名) → 节点udp代理 → 国外udp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>tcp：DNS请求 → chinadns-ng(匹配国外域名) → 节点tcp代理 → 国外tcp DNS服务器</font><br />";
		statusmenu += "<font color='#F00'>dot：DNS请求 → chinadns-ng(匹配国外域名) → 节点tcp代理 → 国外dot DNS服务器</font><br />";
		statusmenu += "-----------------------------------------------------------------------<br />";
		statusmenu += "1️⃣需要至少开启一组选可信DNS，以保证国外DNS的正常解析。<br />";
		statusmenu += "2️⃣某些不支持udp的代理服务器，无法使用udp协议，此时可以考虑切换到tcp。<br />";
		statusmenu += "3️⃣NaïveProxy由于自身特性，不支持udp代理，所以Naïve节点的可信DNS-1无法使用udp协议！<br />";
		statusmenu += "4️⃣为避免udp协议DNS不可用，建议至少设置一组tcp/dot协议的DNS作为可信DNS！！<br />";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 138) {
		width = "450px";
		statusmenu = "fancyss运行需要网络畅通，如果本地网络不通，fancyss将无法正常运行<br /><br />";
		statusmenu += "如果能保证你的路由器本地网络稳定性，那么在插件开启时跳过网络可用性检测！";
		_caption = "跳过网络可用性检测";
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
		statusmenu += "chinadns-ng支持过滤ipv6 DNS（AAAA）查询，具体情况见<a href='https://github.com/zfl9/chinadns-ng?tab=readme-ov-file#no-ipv6' target='_blank'><u><font color='#00F'>chinadns-ng对no-ipv6命令的说明</font></u></a>。<br /><br />";
		statusmenu += "由于chinadns-ng的no-ipv6命令需要配合group信息和ip判定结果进行设置，所以本插件为了简便，做了ipv6解析结果过滤的预设<br /><br />";
		statusmenu += "过滤直连：过滤通过中国DNS查询解析得到的 AAAA 记录<br /><br />";
		statusmenu += "过滤代理：过滤通过可信DNS查询解析得到的 AAAA 记录<br /><br />";
		statusmenu += "1. 当路由器开启了ipv6功能，但是目前插件尚未支持ipv6代理，如果可信DNS查询到AAAA记录，会导致本地直连访问，导致访问速度慢、流媒体及AI网站检测出地区不符等问题，所以建议勾选【过滤代理】<br /><br />";
		statusmenu += "2. 当本地没有启用ipv6功能，如果可信DNS查询到AAAA记录，会导致本地直连访问，但是却无法访达。<br />";
		_caption = "说明";
	} else if (itemNum == 146) {
		width = "600px";
		statusmenu =  "勾选此处后，fancyss将劫持ipv6流量，并将匹配的流量进行代理<br /><br />";
		statusmenu += "1. 请确保你的代理节点支持ipv6，可以是纯ipv6，也可以是ipv4 + ipv6双栈。如果节点不支持ipv6，可能会导致海外网站无法访问。<br /><br />";
		statusmenu += "2. 此处勾选后，DNS设定中，AAAA记录的过滤行为将会自动变更，将不再过滤海外域名的ipv6解析。<br /><br />";
		_caption = "说明：";
	} else if (itemNum == 147) {
		width = "500px";
		statusmenu = "1. 此处设定的网址将用于所有节点的 web 延迟测试，同时用于插件运行状态中的国外状态检测，保存后立即生效。<br /><br />";
		statusmenu += "2. 插件默认国外检测网址为：<font color='#669900'>http://www.google.com/generate_204</font><br /><br />";
		statusmenu += "3. 此处使用插件预置的国外测试网址，通过下拉框直接选择即可。<br /><br />";
		statusmenu += "4. 如果开启了 IPv6 代理，请优先选择支持 IPv6 的国外检测网址，否则【国外IPv6】可能显示失败。<br /><br />";
		statusmenu += "5. 这里的检测结果用于判断 fancyss 当前运行链路，不等同于节点本身可用性检测；节点是否可用请结合 web 延迟测试、详细状态和实际访问结果一起判断。<br /><br />";
		statusmenu += "6. 部分中转机场可能会对特定测试网址做优化或劫持，导致不同地区节点测出相似延迟，此时建议更换测试网址。<br />";
		_caption = "说明：";
	} else if (itemNum == 148) {
		width = "500px";
		statusmenu = "1. 此处设定的网址将用于插件运行状态中的国内状态检测，保存后立即生效。<br /><br />";
		statusmenu += "2. 插件默认国内检测网址为：<font color='#669900'>http://connectivitycheck.platform.hicloud.com/generate_204</font><br /><br />";
		statusmenu += "3. 此处使用插件预置的国内测试网址，通过下拉框直接选择即可。<br /><br />";
		statusmenu += "4. 建议选择国内可稳定访问、响应轻量、返回固定的检测网址，以减少误判。<br /><br />";
		statusmenu += "5. 这里的检测结果用于判断 fancyss 当前国内直连链路，不等同于节点本身可用性检测。<br />";
		_caption = "说明：";
	} else if (itemNum == 149) {
		width = "600px";
		statusmenu += "勾选new bing模式后，访问<a style='color:#00F' href='https://bing.com/' target='_blank'>https://bing.com/</a>将不会跳转到<a style='color:#00F' href='https://cn.bing.com/' target='_blank'>https://cn.bing.com/</a><br /><br />";
		statusmenu += "如果勾选后依然跳转到bing中国，需要清除浏览器缓存后重试！<br /><br />";
		statusmenu += "此功能等同于在域名黑名单内添加：bing.com<br />";
		_caption = "说明：";
	} else if (itemNum == 150) {
		width = "650px";
		statusmenu += "1. 游戏模式下udp代理默认开启，此处设置无效<br /><br />";
		statusmenu += "2. 大陆白名单摸下，开启udp代理后，效果和游戏模式等同<br /><br />";
		statusmenu += "3. 节点必须支持udp代理才能看到实际效果，否则希望被代理的udp包将无法抵达<br /><br />";
		statusmenu += "4. 关闭udp代理时，建议开启屏蔽quic，这样udp443端口的海外数据包将被屏蔽，以避免直连访问海外h3网站。<br />";
		_caption = "说明：";
	} else if (itemNum == 152) {
		width = "720px";
		statusmenu += "一些海外网站和APP用优先使用http3/quic协议，此协议基于udp协议443端口。此时有两个选择，A：代理udp 443，B：屏蔽udp 443<br /><br />";
		statusmenu += "A：代理udp 443<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;代理udp 443需要节点支持udp代理，即使你有支持udp代理的节点，这也不一定是美好的，因为udp很多时候被运营商，国际出口等qos限速，会导致用quic看youtube视频速度慢等情况。<br /><br />";
		statusmenu += "B：屏蔽udp 443<br /><br />";
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;屏蔽udp 443后，http3的网站知道你无法使用quic，将会自动回落到基于tcp的http2，而代理软件都是支持tcp的，所以最后也能成功访问这类网站，且不会有udp qos限速的情况。<br /><br />";
		statusmenu += "";
		statusmenu += "-----------------------------------------------------------------------<br />";
		statusmenu += "";
		statusmenu += "1. 当udp代理开启时（或使用游戏模式），开启此处将不会代理443端口udp流量，且屏蔽本机发往海外的udp 443端口数据包，此时海外http3网站访问将自动回落到基于tcp的http2，最后正确走tcp代理。<br /><br />";
		statusmenu += "2. 当udp代理开启时（或使用游戏模式），关闭此处将代理443端口udp流量，此时访问海外http3网站将会走udp代理，有时候udp代理速度不及tcp，会导致比如看youtube速度较慢。<br /><br />";
		statusmenu += "3. 当udp代理关闭时，开启此处将后将会屏蔽本机发往海外的udp 443端口数据包，效果跟情形1一样，将回落到http2后走tcp代理<br /><br />";
		statusmenu += "4. 当udp代理关闭时，关闭此处后海外udp 443流量将直连，可能导致chatgpt等http3网站检测到国内ip而不可用。<br /><br />";
		statusmenu += "总之，除非你特别了解这个功能，否则请默认勾选屏蔽quic流量，以保证http3/quic协议网站的正确访问。";
		_caption = "说明：";
	} else if (itemNum == 153) {
		width = "760px";
		statusmenu = "<div style='padding-left:16px;padding-right:16px;line-height:1.6'>";
		statusmenu += "<b>主DNS方案用于决定 fancyss 采用哪套 DNS 分流内核。</b><br /><br />";
		statusmenu += "<b><font color='#CC0066'>chinadns-ng：</font></b>链路更直接，中国DNS和可信DNS分别控制。<br />";
		statusmenu += "优点：内存占用较小，通常在 5MB 左右；在指定 ISP DNS 的前提下，虽然不支持 IP 优选，但国内解析体验一般也不会比 smartdns 差很多。<br />";
		statusmenu += "适用：更适合 ARMv7、小内存机型，或希望以更低资源占用获得稳定 DNS 分流体验的场景。<br /><br />";
		statusmenu += "<b><font color='#CC0066'>smartdns：</font></b>更擅长多上游并发、缓存、测速和双栈优选，综合体验更偏向“自动择优”。<br />";
		statusmenu += "优点：在 fancyss 上可以实现国内解析优选 IP，但通常需要为 chn 组指定多个 DNS 上游。<br />";
		statusmenu += "缺点：内存占用较高，通常在 40MB 左右；不能对经过代理的域名解析做 IP 优选。<br /><br />";
		statusmenu += "<font color='#00F'>建议：</font>ARMv7、小内存机型优先选 <b>chinadns-ng</b>；ARMv8、大内存机型，且追求更极致国内 DNS 体验时选 <b>smartdns</b>。";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 154) {
		width = "760px";
		statusmenu = "<div style='padding-left:16px;padding-right:16px;line-height:1.6'>";
		statusmenu += "<b><font color='#CC0066'>1.【国内优先】</font></b><br />";
		statusmenu += "原理：除 GFW 域名和黑名单域名使用 gfw 组 DNS 解析外，其余域名优先使用 chn 组 DNS 解析。<br />";
		statusmenu += "适用：希望国内网站 / CDN 命中更稳，推荐 GFW 黑名单模式使用。<br />";
		statusmenu += "优点：国内 CDN 表现更好。<br />";
		statusmenu += "缺点：国外 CDN 表现一般。<br /><br />";
		statusmenu += "<b><font color='#CC0066'>2.【国外优先】</font></b><br />";
		statusmenu += "原理：除国内域名列表和白名单域名使用 chn 组 DNS 解析外，其余域名优先使用 gfw 组 DNS 解析。<br />";
		statusmenu += "适用：更看重海外站点的解析质量，推荐大陆白名单模式 / 游戏模式使用。<br />";
		statusmenu += "优点：国外 CDN 表现更好，且不会有 DNS 泄露。<br />";
		statusmenu += "缺点：国内 CDN 表现一般。<br /><br />";
		statusmenu += "<b><font color='#CC0066'>3.【智能判断】</font></b><br />";
		statusmenu += "原理：GFW 域名和黑名单域名使用 gfw 组 DNS 解析，国内域名列表和白名单域名使用 chn 组 DNS 解析，其余未收录域名自动判断。<br />";
		statusmenu += "适用：所有模式均可使用。<br />";
		statusmenu += "优点：国内外 CDN 都能兼顾，整体更均衡。<br />";
		statusmenu += "缺点：会有轻微 DNS 泄露。";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 155) {
		width = "760px";
		statusmenu = "<div style='padding-left:16px;padding-right:16px;line-height:1.6'>";
		statusmenu += "<b><font color='#CC0066'>1.【国内优先】</font></b><br />";
		statusmenu += "原理：除 GFW 域名和黑名单域名使用可信 DNS 解析外，其余域名优先使用中国 DNS 解析。<br />";
		statusmenu += "适用：希望国内网站 / CDN 命中更稳，推荐 GFW 黑名单模式使用。<br />";
		statusmenu += "优点：国内 CDN 表现更好。<br />";
		statusmenu += "缺点：国外 CDN 表现一般。<br /><br />";
		statusmenu += "<b><font color='#CC0066'>2.【国外优先】</font></b><br />";
		statusmenu += "原理：除国内域名列表和白名单域名使用中国 DNS 解析外，其余域名优先使用可信 DNS 解析。<br />";
		statusmenu += "适用：更看重海外站点的解析质量，推荐大陆白名单模式 / 游戏模式使用。<br />";
		statusmenu += "优点：国外 CDN 表现更好，且不会有 DNS 泄露。<br />";
		statusmenu += "缺点：国内 CDN 表现一般。<br /><br />";
		statusmenu += "<b><font color='#CC0066'>3.【智能判断】</font></b><br />";
		statusmenu += "原理：GFW 域名和黑名单域名使用可信 DNS 解析，国内域名列表和白名单域名使用中国 DNS 解析，其余未收录域名自动判断。<br />";
		statusmenu += "适用：所有模式均可使用。<br />";
		statusmenu += "优点：国内外 CDN 都能兼顾，整体更均衡。<br />";
		statusmenu += "缺点：会有轻微 DNS 泄露。";
		statusmenu += "</div>";
		_caption = "说明：";
	} else if (itemNum == 156) {
		width = "560px";
		statusmenu = "1. 该选项仅在【定时测试节点延迟】关闭时生效。<br /><br />";
		statusmenu += "2. 在设定分钟内再次访问节点列表，会直接复用现有测速结果；超过设定分钟后访问，页面会自动触发一次批量测速刷新。<br /><br />";
		statusmenu += "3. 自动触发时会显示 waiting / loading / booting 等中间状态，不会再静默刷新。";
		_caption = "说明：";
	}
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
