(function($) {
	var Api = $.DohClientApi;
	var api = new Api({});
	var query = { keyword: null, offset: 0, limit: 100 };
	var loading;

	/* Parse querystring */
	(function(){
		var s = location.search;
		if (s) {
			var arr = s.substr(1).split("&");
			for (var i = 0; i < arr.length; i++) {
				var kv = arr[i].split("=");
				query[kv[0]] = kv[1];
			}

			if (query.offset) {
				query.offset = parseInt(query.offset);
				if (!query.offset)
					query.offset = 0;
				else if (query.offset < 0)
					query.offset = 0;
			}

			if (query.limit) {
				query.limit = parseInt(query.limit);
				if (!query.limit)
					query.offset = 100;
				else if (query.limit < 1)
					query.limit = 100;
			}
		}
	})();

	loading = {
		el: $("#loading"),
		tx: $("#loading-message"),
		show: function (msg) {
			loading.tx.html(msg || "");
			loading.el.css("display", "flex");
		},
		hide: function (msg, delay) {
			if (msg) {
				loading.tx.html(msg || "");
			}
			if (delay) {
				setTimeout(function() {
					loading.el.css("display", "none");
				}, delay);
			}
			else {
				loading.el.css("display", "none");
			}
		}
	};

	function bindTable(r) {
		var html = [];
		if (r.error) {
			html.push('<tr>');
			html.push('  <td class="errmsg" colspan="4">' + (r.msg || "Unknown Error") + '</td>');
			html.push('</tr>');
		}
		else {
			var list = r.data.list || [];
			var i;
			for (i = 0; i < list.length; i++) {
				var d = list[i] || {};
				html.push('<tr>');
				html.push('  <td>' + (r.data.offset + i + 1) + '</td>');
				html.push('  <td>' + (d.key || '') + '</td>');
				html.push('  <td>' + (d.answers || '') + '</td>');
				html.push('  <td><a data-action="remove" data-key="' + (d.key || '') + '" class="remove" title="Remove" href="javascript: void(0);">Remove</a></td>');
				html.push('</tr>');
			}
			if (i == 0) {
				html.push('<tr>');
				html.push('  <td colspan="4">No Data</td>');
				html.push('</tr>');
			}
		}
		$("#tbList > tbody").html(html.join("\n"));
	}

	function bindRangeText(range, r) {
		if (range) {
			$(".offset-limit").html(
				"Total: " + r.data.total + ", " +
				"Current: " + (range.offset + 1) + " - " +
				              (range.offset + r.data.list.length) +
				" ");
		}
		else {
			$(".offset-limit").html("");
		}
	}

	function bindPageBar(range, r) {
		bindRangeText(range, r);
		if (range && r && !r.error) {
			if (range.offset == 0) {
				$(".prev-page").addClass("disabled");
			}
			else {
				$(".prev-page").removeClass("disabled");
			}
			if (range.offset + r.data.list.length >= r.data.total) {
				$(".next-page").addClass("disabled");
			}
			else {
				$(".next-page").removeClass("disabled");
			}
		}
		else {
			$(".prev-page").addClass("disabled");
			$(".next-page").addClass("disabled");
		}
	}

	function search() {
		loading.show("");
		api.list(query)
		.done(function (r) {
			bindTable(r);
			bindPageBar(query, r);
		})
		.always(function () {
			loading.hide();
		});
	}

	function doListAll() {
		query.offset = 0;
		query.keyword = $("#txKeyword").val()
		search();
	}

	function doGet() {
		var d = {
			"type":  $("#txType").val(),
			"class": $("#txClass").val(),
			"name":  $("#txDomain").val()
		};
		if (!d.name) {
			alert("Please input domain");
			$("#txDomain").focus();
			return;
		}
		loading.show("");
		api.get(d)
		.done(function (r) {
			if (!r.error)
				r.data = {
					offset: 0,
					limit: 1,
					total: 1,
					list: [r.data]
				};
			bindTable(r);
			bindPageBar(null, r);
		})
		.always(function () {
			loading.hide();
		});
	}

	function doPut() {
		var d = {
			"type":  $("#txType2").val(),
			"ip":    $("#txIP").val(),
			"name":  $("#txDomain2").val(),
			"ttl":   $("#txTTL").val()
		};
		if (!d.ip) {
			alert("Please input IP");
			$("#txIP").focus();
			return;
		}
		if (!d.name) {
			alert("Please input domain");
			$("#txDomain2").focus();
			return;
		}
		loading.show("");
		api.put(d)
		.always(function (r, textStatus, errorThrown) {
			if (textStatus === "success") {
				if (!r.error) {
					if (confirm("Success! Refresh the list?")) {
						search();
					}
				}
				else {
					loading.hide();
					alert(r.msg || "Unknown Error");
				}
			}
			else {
				loading.hide();
				alert(errorThrown);
			}
		});
	}

	function doSave() {
		var d = {
			"file":  $("#txSaveFile").val()
		};
		if (!d.file) {
			alert("Please input file path");
			$("#txSaveFile").focus();
			return;
		}
		loading.show("");
		api.save(d)
		.always(function (r, textStatus, errorThrown) {
			if (textStatus === "success") {
				if (!r.error) {
					alert(r.msg);
				}
				else {
					loading.hide();
					alert(r.msg || "Unknown Error");
				}
			}
			else {
				loading.hide();
				alert(errorThrown);
			}
		});
	}

	function doLoad() {
		var d = {
			"file":     $("#txLoadFile").val(),
			"override": $("#chkOverride")[0].checked ? 1 : 0
		};
		if (!d.file) {
			alert("Please input file path");
			$("#txLoadFile").focus();
			return;
		}
		loading.show("");
		api.load(d)
		.always(function (r, textStatus, errorThrown) {
			if (textStatus === "success") {
				if (!r.error) {
					if (confirm(r.msg + " Refresh the list?")) {
						search();
					}
				}
				else {
					loading.hide();
					alert(r.msg || "Unknown Error");
				}
			}
			else {
				loading.hide();
				alert(errorThrown);
			}
		});
	}

	function doRefresh() {
		search();
	}

	function doRemove(e) {
		var a = e.currentTarget;
		var d = $(a).data();
		if (confirm("Sure to remove?")) {
			loading.show("");
			api.delete({
				key: d.key
			})
			.always(function (r, textStatus, errorThrown) {
				if (textStatus === "success") {
					if (!r.error) {
						search();
					}
					else {
						loading.hide();
						alert(r.msg || "Unknown Error");
					}
				}
				else {
					loading.hide();
					alert(errorThrown);
				}
			});
		}
	}

	function doPrevPage(e) {
		var a = e.currentTarget;
		if (!$(a).hasClass("disabled") && query.offset > 0) {
			query.offset -= query.limit;
			if (query.offset < 0)
				query.offset = 0;
			search();
		}
	}

	function doNextPage(e) {
		var a = e.currentTarget;
		if (!$(a).hasClass("disabled")) {
			query.offset += query.limit;
			search();
		}
	}

	function doAction(e) {
		var a = e.currentTarget;
		var d = $(a).data();
		switch (d.action) {
			case "refresh":
				doRefresh(e);
				break;
			case "remove":
				doRemove(e);
				break;
			case "prev-page":
				doPrevPage(e);
				break;
			case "next-page":
				doNextPage(e);
				break;
		}
	}

	$(function() {
		search();

		$("#btnGet").click(doGet);
		$("#txDomain").on("keypress", function(e) {
			if(e.which == 13) {
				e.preventDefault();
				$("#btnGet").click();
			}
		});

		$("#btnPut").click(doPut);
		$("#txDomain2,#txIP,#txTTL").on("keypress", function(e) {
			if(e.which == 13) {
				e.preventDefault();
				$("#btnPut").click();
			}
		});

		$("#btnSaveTo").click(doSave);
		$("#txSaveFile").on("keypress", function(e) {
			if(e.which == 13) {
				e.preventDefault();
				$("#btnSaveTo").click();
			}
		});

		$("#btnLoadFrom").click(doLoad);
		$("#txLoadFile").on("keypress", function(e) {
			if(e.which == 13) {
				e.preventDefault();
				$("#btnLoadFrom").click();
			}
		});

		$("#btnListAll").click(doListAll);
		$("#txKeyword").on("keypress", function(e) {
			if(e.which == 13) {
				e.preventDefault();
				$("#btnListAll").click();
			}
		});

		$("#tbList").on("click", "a", doAction);

		$("#txKeyword").focus();
	});

})(jQuery);
