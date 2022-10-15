
(function($) {
	function DohClientApi(opts) {
		this.config = $.extend(
			{},
			this.config,
			opts,
		);
	}

	var pt = DohClientApi.prototype;
	pt.constructor = DohClientApi;

	pt.config = {
		url: "/api/v1"
	};

	pt.QTYPE = {
		A:    "A",
		AAAA: "AAAA"
	};

	pt.QCLASS = {
		IN: "IN",
		CS: "CS",
		CH: "CH",
		HS: "HS"
	};

	pt._post = function(url, data) {
		return $.ajax({
			url: url,
			async: true,
			method: "POST",
			contentType: "application/x-www-form-urlencoded; charset=utf-8",
			data: data,
			dataType: "json"
		})
		.fail(function(jqXHR, textStatus, errorThrown) {
			console.error(arguments);
		});
	};

	/*
	 * Example:
	 *
	 * api.get({
	 *     type:  "<A|AAAA>",
	 *     class: "<IN|CS|CH|HS>",
	 *     name:  "<Domain>"
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.get = function(d) {
		var url = this.config.url + "/get";
		return this._post(url, d);
	};

	/*
	 * Example:
	 *
	 * api.list({
	 *     offset: <numeric>,
	 *     limit:  <numeric>
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.list = function(d) {
		var url = this.config.url + "/list";
		return this._post(url, d);
	};

	/*
	 * Example:
	 *
	 * api.put({
	 *     type:  "<A|AAAA>",
	 *     ip:    "<IPv4|IPv6>",
	 *     name:  "<Domain>"
	 *     ttl:   <numeric>
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.put = function(d) {
		var url = this.config.url + "/put";
		return this._post(url, d);
	};

	/*
	 * Example:
	 *
	 * api.delete({
	 *     type:  "<A|AAAA>",
	 *     class: "<IN|CS|CH|HS>",
	 *     name:  "<Domain>"
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.delete = function(d) {
		var url = this.config.url + "/delete";
		return this._post(url, d);
	};

	/*
	 * Example:
	 *
	 * api.save({
	 *     file:  "<PATH>"
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.save = function(d) {
		var url = this.config.url + "/save";
		return this._post(url, d);
	};

	/*
	 * Example:
	 *
	 * api.load({
	 *     file:     "<PATH>",
	 *     override: "<0|1>",
	 * })
	 * .done(function (d) {
	 *   if (d.error) {
	 *       console.error(d);
	 *   }
	 *   else {
	 *       console.log(d);
	 *   }
	 * });
	 * */
	pt.load = function(d) {
		var url = this.config.url + "/load";
		return this._post(url, d);
	};

	$.DohClientApi = DohClientApi;

})(jQuery);
