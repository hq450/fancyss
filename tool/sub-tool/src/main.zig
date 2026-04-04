const std = @import("std");
const builtin = @import("builtin");

const app_version = "0.1.0";
const max_input_size = 64 * 1024 * 1024;

const Command = enum {
    inspect,
    parse_uri_lines,
    summary,
    version,
};

const OutputFormat = enum {
    normalized,
    fancyss,

    fn name(self: OutputFormat) []const u8 {
        return switch (self) {
            .normalized => "normalized",
            .fancyss => "fancyss",
        };
    }
};

const LogLevel = enum {
    none,
    summary,
    verbose,
};

const InputKind = enum {
    empty,
    uri_lines,
    base64_uri_lines,
    ssep_envelope,
    html_login,
    html_redirect,
    html_page,
    clash_yaml,
    json_error,
    json,
    text_error,
    gzip,
    unknown,

    fn name(self: InputKind) []const u8 {
        return switch (self) {
            .empty => "empty",
            .uri_lines => "uri-lines",
            .base64_uri_lines => "base64-uri-lines",
            .ssep_envelope => "ssep-envelope",
            .html_login => "html-login",
            .html_redirect => "html-redirect",
            .html_page => "html-page",
            .clash_yaml => "clash-yaml",
            .json_error => "json-error",
            .json => "json",
            .text_error => "text-error",
            .gzip => "gzip",
            .unknown => "unknown",
        };
    }
};

const Options = struct {
    command: Command,
    input: ?[]const u8 = null,
    output: ?[]const u8 = null,
    group: ?[]const u8 = null,
    source_tag: ?[]const u8 = null,
    include_raw: bool = false,
    format: OutputFormat = .normalized,
    mode: ?[]const u8 = null,
    pkg_type: ?[]const u8 = null,
    sub_ai_force: bool = false,
    hy2_up: ?[]const u8 = null,
    hy2_dl: ?[]const u8 = null,
    hy2_tfo_switch: ?[]const u8 = null,
    hy2_cg_opt: ?[]const u8 = null,
    log_level: LogLevel = .none,
    log_output: ?[]const u8 = null,
};

const NormalizedNode = struct {
    scheme: []const u8,
    name: []const u8,
    server: []const u8,
    port: u16,

    group: ?[]const u8 = null,
    source_tag: ?[]const u8 = null,
    protocol: ?[]const u8 = null,
    method: ?[]const u8 = null,
    username: ?[]const u8 = null,
    password: ?[]const u8 = null,
    uuid: ?[]const u8 = null,
    network: ?[]const u8 = null,
    security: ?[]const u8 = null,
    host: ?[]const u8 = null,
    path: ?[]const u8 = null,
    sni: ?[]const u8 = null,
    flow: ?[]const u8 = null,
    obfs: ?[]const u8 = null,
    obfs_host: ?[]const u8 = null,
    obfs_password: ?[]const u8 = null,
    protocol_param: ?[]const u8 = null,
    alpn: ?[]const u8 = null,
    congestion_control: ?[]const u8 = null,
    fingerprint: ?[]const u8 = null,
    public_key: ?[]const u8 = null,
    short_id: ?[]const u8 = null,
    spider_x: ?[]const u8 = null,
    allow_insecure: ?bool = null,
    raw_uri: ?[]const u8 = null,
};

const ContentInfo = struct {
    kind: InputKind,
    content: []const u8,
};

const ParseResult = struct {
    nodes: std.ArrayList(NormalizedNode),
    total_lines: usize = 0,
    valid_lines: usize = 0,
    invalid_lines: usize = 0,
    ignored_lines: usize = 0,
    kind: InputKind = .unknown,

    fn init(_: std.mem.Allocator) ParseResult {
        return .{
            .nodes = std.ArrayList(NormalizedNode){},
        };
    }

    fn deinit(self: *ParseResult, allocator: std.mem.Allocator) void {
        self.nodes.deinit(allocator);
    }
};

pub fn main() void {
    run() catch |err| {
        const stderr = std.fs.File.stderr().deprecatedWriter();
        switch (err) {
            error.HelpRequested => {
                printUsage(std.fs.File.stdout().deprecatedWriter()) catch {};
                std.process.exit(0);
            },
            error.InvalidArguments => {
                printUsage(stderr) catch {};
            },
            error.UnsupportedInputKind => {
                stderr.print("error: unsupported input kind for this command\n", .{}) catch {};
            },
            else => {
                stderr.print("error: {s}\n", .{@errorName(err)}) catch {};
            },
        }
        std.process.exit(1);
    };
}

fn run() !void {
    const allocator = if (builtin.link_libc) std.heap.c_allocator else std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const options = try parseArgs(args);
    switch (options.command) {
        .version => {
            try std.fs.File.stdout().writeAll(app_version);
            try std.fs.File.stdout().writeAll("\n");
        },
        .inspect => try runInspect(allocator, options),
        .parse_uri_lines => try runParseUriLines(allocator, options),
        .summary => try runSummary(allocator, options),
    }
}

fn printUsage(writer: anytype) !void {
    try writer.writeAll(
        "Usage:\n" ++
        "  sub-tool inspect [--input path]\n" ++
        "  sub-tool parse-uri-lines [--input path] [--output path] [--format normalized|fancyss] [--group name] [--source-tag tag] [--mode value] [--pkg-type full|lite] [--sub-ai 0|1] [--hy2-up value] [--hy2-dl value] [--hy2-tfo-switch value] [--hy2-cg-opt value] [--log-level none|summary|verbose] [--log-output path] [--include-raw]\n" ++
        "  sub-tool summary [--input path]\n" ++
        "  sub-tool version\n",
    );
}

fn parseArgs(args: []const []const u8) !Options {
    if (args.len < 2) return error.InvalidArguments;

    const command = blk: {
        if (std.mem.eql(u8, args[1], "inspect")) break :blk Command.inspect;
        if (std.mem.eql(u8, args[1], "parse-uri-lines")) break :blk Command.parse_uri_lines;
        if (std.mem.eql(u8, args[1], "summary")) break :blk Command.summary;
        if (std.mem.eql(u8, args[1], "version")) break :blk Command.version;
        if (std.mem.eql(u8, args[1], "-h") or std.mem.eql(u8, args[1], "--help")) return error.HelpRequested;
        return error.InvalidArguments;
    };

    var options = Options{ .command = command };
    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--input")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.input = args[i];
        } else if (std.mem.eql(u8, arg, "--output")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.output = args[i];
        } else if (std.mem.eql(u8, arg, "--group")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.group = args[i];
        } else if (std.mem.eql(u8, arg, "--source-tag")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.source_tag = args[i];
        } else if (std.mem.eql(u8, arg, "--format")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            if (std.mem.eql(u8, args[i], "normalized")) {
                options.format = .normalized;
            } else if (std.mem.eql(u8, args[i], "fancyss")) {
                options.format = .fancyss;
            } else {
                return error.InvalidArguments;
            }
        } else if (std.mem.eql(u8, arg, "--mode")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.mode = args[i];
        } else if (std.mem.eql(u8, arg, "--pkg-type")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.pkg_type = args[i];
        } else if (std.mem.eql(u8, arg, "--sub-ai")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.sub_ai_force = parseBoolArg(args[i]);
        } else if (std.mem.eql(u8, arg, "--hy2-up")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.hy2_up = args[i];
        } else if (std.mem.eql(u8, arg, "--hy2-dl")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.hy2_dl = args[i];
        } else if (std.mem.eql(u8, arg, "--hy2-tfo-switch")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.hy2_tfo_switch = args[i];
        } else if (std.mem.eql(u8, arg, "--hy2-cg-opt")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.hy2_cg_opt = args[i];
        } else if (std.mem.eql(u8, arg, "--log-level")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            if (std.mem.eql(u8, args[i], "none")) {
                options.log_level = .none;
            } else if (std.mem.eql(u8, args[i], "summary")) {
                options.log_level = .summary;
            } else if (std.mem.eql(u8, args[i], "verbose")) {
                options.log_level = .verbose;
            } else {
                return error.InvalidArguments;
            }
        } else if (std.mem.eql(u8, arg, "--log-output")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            options.log_output = args[i];
        } else if (std.mem.eql(u8, arg, "--include-raw")) {
            options.include_raw = true;
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            return error.HelpRequested;
        } else {
            return error.InvalidArguments;
        }
    }

    return options;
}

fn runInspect(allocator: std.mem.Allocator, options: Options) !void {
    const raw = try readInput(allocator, options.input);
    defer allocator.free(raw);

    const info = try detectContentInfo(allocator, raw);
    defer if (info.content.ptr != raw.ptr) allocator.free(info.content);
    const redirect_url = if (info.kind == .html_redirect)
        try extractHtmlRedirectTargetAlloc(allocator, info.content)
    else
        null;
    defer if (redirect_url) |value| allocator.free(value);

    var scheme_counts = std.StringHashMap(usize).init(allocator);
    defer scheme_counts.deinit();
    const line_count = countUriSchemes(&scheme_counts, info.content);

    const stdout = std.fs.File.stdout().deprecatedWriter();
    try stdout.print(
        "{{\"kind\":\"{s}\",\"line_count\":{d},\"payload_bytes\":{d},\"scheme_count\":{d},\"schemes\":{{",
        .{ info.kind.name(), line_count.total_lines, info.content.len, line_count.scheme_total },
    );

    var it = scheme_counts.iterator();
    var first = true;
    while (it.next()) |entry| {
        if (!first) try stdout.writeAll(",");
        first = false;
        try writeJsonString(stdout, entry.key_ptr.*);
        try stdout.writeAll(":");
        try stdout.print("{d}", .{entry.value_ptr.*});
    }
    try stdout.writeAll("}");
    if (redirect_url) |value| {
        try stdout.writeAll(",\"redirect_url\":");
        try writeJsonString(stdout, value);
    }
    try stdout.writeAll("}\n");
}

fn runParseUriLines(allocator: std.mem.Allocator, options: Options) !void {
    const raw = try readInput(allocator, options.input);
    defer allocator.free(raw);

    var result = try parseSubscription(allocator, raw, options);
    defer result.deinit(allocator);

    const writer_file = if (options.output) |path|
        try std.fs.cwd().createFile(path, .{ .truncate = true })
    else
        null;
    defer if (writer_file) |*file| file.close();

    const writer = if (writer_file) |file|
        file.deprecatedWriter()
    else
        std.fs.File.stdout().deprecatedWriter();

    for (result.nodes.items) |node| {
        switch (options.format) {
            .normalized => try writer.print("{f}\n", .{std.json.fmt(node, .{ .emit_null_optional_fields = false })}),
            .fancyss => {
                const wrote = try writeFancyssNode(allocator, writer, node, options);
                if (!wrote) continue;
            },
        }
    }

    if (options.log_output) |path| {
        var log_file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        defer log_file.close();
        try writeParseLogs(log_file.deprecatedWriter(), result.nodes.items, options.log_level);
    }
}

fn runSummary(allocator: std.mem.Allocator, options: Options) !void {
    const raw = try readInput(allocator, options.input);
    defer allocator.free(raw);

    var result = try parseSubscription(allocator, raw, options);
    defer result.deinit(allocator);

    var scheme_counts = std.StringHashMap(usize).init(allocator);
    defer scheme_counts.deinit();

    for (result.nodes.items) |node| {
        const entry = try scheme_counts.getOrPut(node.scheme);
        if (!entry.found_existing) entry.value_ptr.* = 0;
        entry.value_ptr.* += 1;
    }

    const stdout = std.fs.File.stdout().deprecatedWriter();
    try stdout.print(
        "{{\"kind\":\"{s}\",\"total_lines\":{d},\"valid_lines\":{d},\"invalid_lines\":{d},\"ignored_lines\":{d},\"node_count\":{d},\"schemes\":{{",
        .{
            result.kind.name(),
            result.total_lines,
            result.valid_lines,
            result.invalid_lines,
            result.ignored_lines,
            result.nodes.items.len,
        },
    );

    var it = scheme_counts.iterator();
    var first = true;
    while (it.next()) |entry| {
        if (!first) try stdout.writeAll(",");
        first = false;
        try writeJsonString(stdout, entry.key_ptr.*);
        try stdout.writeAll(":");
        try stdout.print("{d}", .{entry.value_ptr.*});
    }
    try stdout.writeAll("}}\n");
}

fn parseBoolArg(value: []const u8) bool {
    return std.mem.eql(u8, value, "1") or
        stringEqualsIgnoreCase(value, "true") or
        stringEqualsIgnoreCase(value, "yes") or
        stringEqualsIgnoreCase(value, "on");
}

fn writeParseLogs(writer: anytype, nodes: []const NormalizedNode, level: LogLevel) !void {
    if (level == .none) return;

    var ss_count: usize = 0;
    var ssr_count: usize = 0;
    var vmess_count: usize = 0;
    var vless_count: usize = 0;
    var trojan_count: usize = 0;
    var naive_count: usize = 0;
    var tuic_count: usize = 0;
    var hy2_count: usize = 0;

    for (nodes) |node| {
        if (std.mem.eql(u8, node.scheme, "ss")) ss_count += 1
        else if (std.mem.eql(u8, node.scheme, "ssr")) ssr_count += 1
        else if (std.mem.eql(u8, node.scheme, "vmess")) vmess_count += 1
        else if (std.mem.eql(u8, node.scheme, "vless")) vless_count += 1
        else if (std.mem.eql(u8, node.scheme, "trojan")) trojan_count += 1
        else if (std.mem.eql(u8, node.scheme, "naive+https") or std.mem.eql(u8, node.scheme, "naive+quic")) naive_count += 1
        else if (std.mem.eql(u8, node.scheme, "tuic")) tuic_count += 1
        else if (std.mem.eql(u8, node.scheme, "hy2") or std.mem.eql(u8, node.scheme, "hysteria2")) hy2_count += 1;
    }

    try writer.print("SUMMARY\tTOTAL\t{d}\n", .{nodes.len});
    if (ss_count > 0) try writer.print("SUMMARY\tSS\t{d}\n", .{ss_count});
    if (ssr_count > 0) try writer.print("SUMMARY\tSSR\t{d}\n", .{ssr_count});
    if (vmess_count > 0) try writer.print("SUMMARY\tVMESS\t{d}\n", .{vmess_count});
    if (vless_count > 0) try writer.print("SUMMARY\tVLESS\t{d}\n", .{vless_count});
    if (trojan_count > 0) try writer.print("SUMMARY\tTROJAN\t{d}\n", .{trojan_count});
    if (naive_count > 0) try writer.print("SUMMARY\tNAIVE\t{d}\n", .{naive_count});
    if (tuic_count > 0) try writer.print("SUMMARY\tTUIC\t{d}\n", .{tuic_count});
    if (hy2_count > 0) try writer.print("SUMMARY\tHY2\t{d}\n", .{hy2_count});

    if (level != .verbose) return;
    for (nodes) |node| {
        try writer.writeAll("NODE\t");
        try writer.writeAll(node.scheme);
        try writer.writeAll("\t");
        try writer.writeAll(node.name);
        try writer.writeAll("\n");
    }
}

fn writeFancyssNode(allocator: std.mem.Allocator, writer: anytype, node: NormalizedNode, options: Options) !bool {
    if (options.pkg_type) |pkg_type| {
        if (!std.mem.eql(u8, pkg_type, "full") and
            (std.mem.eql(u8, node.scheme, "tuic") or std.mem.eql(u8, node.scheme, "naive+https") or std.mem.eql(u8, node.scheme, "naive+quic")))
        {
            return false;
        }
    }

    var first = true;
    try writer.writeAll("{");

    if (std.mem.eql(u8, node.scheme, "ss")) {
        const password_b64 = if (node.password) |v| try base64EncodeAlloc(allocator, v) else null;
        defer if (password_b64) |v| allocator.free(v);
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "method", node.method);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldMaybeString(writer, &first, "password", password_b64);
        try jsonFieldPort(writer, &first, "port", node.port);
        try jsonFieldString(writer, &first, "server", node.server);
        try jsonFieldString(writer, &first, "ss_obfs", node.obfs orelse "0");
        try jsonFieldMaybeString(writer, &first, "ss_obfs_host", node.obfs_host);
        try jsonFieldString(writer, &first, "type", "0");
    } else if (std.mem.eql(u8, node.scheme, "ssr")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "method", node.method);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldMaybeString(writer, &first, "password", node.password);
        try jsonFieldPort(writer, &first, "port", node.port);
        try jsonFieldMaybeString(writer, &first, "rss_obfs", node.obfs);
        try jsonFieldMaybeString(writer, &first, "rss_obfs_param", node.obfs_host);
        try jsonFieldMaybeString(writer, &first, "rss_protocol", node.protocol);
        try jsonFieldMaybeString(writer, &first, "rss_protocol_param", node.protocol_param);
        try jsonFieldString(writer, &first, "server", node.server);
        try jsonFieldString(writer, &first, "type", "1");
    } else if (std.mem.eql(u8, node.scheme, "vmess") and !isVmessPlainUri(node)) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const ai = effectiveAllowInsecure(node, options);
        const alpn_h2 = try hasToken(allocator, node.alpn, "h2");
        const alpn_http = try hasToken(allocator, node.alpn, "http/1.1");
        const network = node.network orelse "tcp";
        const security = node.security orelse "none";
        const host_value = if (std.mem.eql(u8, network, "kcp") or std.mem.eql(u8, network, "grpc")) null else node.host;
        const path_value = node.path;
        const mode_value = try rawUriQueryValueAlloc(allocator, node, "mode");
        defer if (mode_value) |v| allocator.free(v);
        const grpc_mode = if (std.mem.eql(u8, network, "grpc")) (mode_value orelse "multi") else null;
        const grpc_authority = try rawUriQueryValueAlloc(allocator, node, "authority");
        defer if (grpc_authority) |v| allocator.free(v);
        const headtype = node.protocol;
        const kcp_seed = if (std.mem.eql(u8, network, "kcp")) path_value else null;

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldPort(writer, &first, "port", node.port);
        try jsonFieldString(writer, &first, "server", node.server);
        try jsonFieldString(writer, &first, "type", "3");
        try jsonFieldString(writer, &first, "v2ray_alterid", node.protocol_param orelse "0");
        try jsonFieldMaybeString(writer, &first, "v2ray_grpc_mode", grpc_mode);
        try jsonFieldMaybeString(writer, &first, "v2ray_grpc_authority", grpc_authority);
        try jsonFieldMaybeString(writer, &first, "v2ray_headtype_kcp", if (std.mem.eql(u8, network, "kcp")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_headtype_quic", if (std.mem.eql(u8, network, "quic")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_headtype_tcp", if (std.mem.eql(u8, network, "tcp")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_kcp_seed", kcp_seed);
        try jsonFieldString(writer, &first, "v2ray_mux_enable", "0");
        try jsonFieldString(writer, &first, "v2ray_network", network);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_host", host_value);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_path", path_value);
        try jsonFieldString(writer, &first, "v2ray_network_security", security);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_security_ai", if (ai) "1" else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_security_alpn_h2", if (alpn_h2) "1" else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_security_alpn_http", if (alpn_http) "1" else null);
        try jsonFieldMaybeString(writer, &first, "v2ray_network_security_sni", node.sni);
        try jsonFieldString(writer, &first, "v2ray_security", node.method orelse "auto");
        try jsonFieldString(writer, &first, "v2ray_use_json", "0");
        try jsonFieldMaybeString(writer, &first, "v2ray_uuid", node.uuid);
    } else if (std.mem.eql(u8, node.scheme, "vmess") or std.mem.eql(u8, node.scheme, "vless")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const ai = effectiveAllowInsecure(node, options);
        const alpn_h2 = try hasToken(allocator, node.alpn, "h2");
        const alpn_http = try hasToken(allocator, node.alpn, "http/1.1");
        const network = node.network orelse "tcp";
        const security = node.security orelse "none";
        const mode_value = try rawUriQueryValueAlloc(allocator, node, "mode");
        defer if (mode_value) |v| allocator.free(v);
        const authority_value = try rawUriQueryValueAlloc(allocator, node, "authority");
        defer if (authority_value) |v| allocator.free(v);
        const service_name = try rawUriQueryValueAlloc(allocator, node, "serviceName");
        defer if (service_name) |v| allocator.free(v);
        const pcs_value = try rawUriQueryValueAlloc(allocator, node, "pcs");
        defer if (pcs_value) |v| allocator.free(v);
        const vcn_value = try rawUriQueryValueAlloc(allocator, node, "vcn");
        defer if (vcn_value) |v| allocator.free(v);
        const host_value = blk: {
            if (std.mem.eql(u8, network, "kcp") or std.mem.eql(u8, network, "grpc")) break :blk null;
            if (std.mem.eql(u8, network, "h2") and node.host == null) break :blk node.server;
            break :blk node.host;
        };
        const path_value = blk: {
            if (std.mem.eql(u8, network, "grpc") and service_name != null) break :blk service_name;
            break :blk node.path;
        };
        const headtype = node.protocol;
        const x_grpc_mode = if (std.mem.eql(u8, network, "grpc")) (mode_value orelse "gun") else null;
        const x_xhttp_mode = if (std.mem.eql(u8, network, "xhttp")) mode_value else null;
        const kcp_seed = if (std.mem.eql(u8, network, "kcp")) path_value else null;
        const encryption = if (node.method) |v| v else if (std.mem.eql(u8, node.scheme, "vmess")) "auto" else "none";

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldPort(writer, &first, "port", node.port);
        try jsonFieldString(writer, &first, "server", node.server);
        try jsonFieldString(writer, &first, "type", "4");
        try jsonFieldMaybeString(writer, &first, "xray_alterid", if (std.mem.eql(u8, node.scheme, "vmess")) (try rawUriQueryValueAlloc(allocator, node, "alterId") orelse "") else null);
        try jsonFieldString(writer, &first, "xray_encryption", encryption);
        try jsonFieldMaybeString(writer, &first, "xray_fingerprint", node.fingerprint);
        try jsonFieldMaybeString(writer, &first, "xray_flow", node.flow);
        try jsonFieldMaybeString(writer, &first, "xray_grpc_mode", x_grpc_mode);
        try jsonFieldMaybeString(writer, &first, "xray_grpc_authority", authority_value);
        try jsonFieldMaybeString(writer, &first, "xray_xhttp_mode", x_xhttp_mode);
        try jsonFieldMaybeString(writer, &first, "xray_headtype_kcp", if (std.mem.eql(u8, network, "kcp")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "xray_headtype_quic", if (std.mem.eql(u8, network, "quic")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "xray_headtype_tcp", if (std.mem.eql(u8, network, "tcp")) (headtype orelse "none") else null);
        try jsonFieldMaybeString(writer, &first, "xray_kcp_seed", kcp_seed);
        try jsonFieldString(writer, &first, "xray_network", network);
        try jsonFieldMaybeString(writer, &first, "xray_network_host", host_value);
        try jsonFieldMaybeString(writer, &first, "xray_network_path", path_value);
        try jsonFieldString(writer, &first, "xray_network_security", security);
        try jsonFieldMaybeString(writer, &first, "xray_network_security_ai", if (ai) "1" else null);
        try jsonFieldMaybeString(writer, &first, "xray_network_security_alpn_h2", if (alpn_h2) "1" else null);
        try jsonFieldMaybeString(writer, &first, "xray_network_security_alpn_http", if (alpn_http) "1" else null);
        try jsonFieldMaybeString(writer, &first, "xray_network_security_sni", node.sni);
        try jsonFieldMaybeString(writer, &first, "xray_pcs", pcs_value);
        try jsonFieldString(writer, &first, "xray_prot", node.scheme);
        try jsonFieldMaybeString(writer, &first, "xray_vcn", vcn_value);
        try jsonFieldMaybeString(writer, &first, "xray_publickey", node.public_key);
        try jsonFieldMaybeString(writer, &first, "xray_shortid", node.short_id);
        try jsonFieldString(writer, &first, "xray_show", "0");
        try jsonFieldMaybeString(writer, &first, "xray_spiderx", node.spider_x);
        try jsonFieldMaybeString(writer, &first, "xray_uuid", node.uuid);
    } else if (std.mem.eql(u8, node.scheme, "trojan")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const ai = effectiveAllowInsecure(node, options);
        const pcs_value = try rawUriQueryValueAlloc(allocator, node, "pcs");
        defer if (pcs_value) |v| allocator.free(v);
        const vcn_value = try rawUriQueryValueAlloc(allocator, node, "vcn");
        defer if (vcn_value) |v| allocator.free(v);
        const tfo_value = try rawUriQueryValueAlloc(allocator, node, "tfo");
        defer if (tfo_value) |v| allocator.free(v);
        const plugin_value = try rawUriQueryValueAlloc(allocator, node, "plugin");
        defer if (plugin_value) |v| allocator.free(v);
        const type_value = try rawUriQueryValueAlloc(allocator, node, "type");
        defer if (type_value) |v| allocator.free(v);
        const host_value = try rawUriQueryValueAlloc(allocator, node, "host");
        defer if (host_value) |v| allocator.free(v);
        const path_value = try rawUriQueryValueAlloc(allocator, node, "path");
        defer if (path_value) |v| allocator.free(v);
        var trojan_plugin: ?[]const u8 = null;
        var trojan_obfs: ?[]const u8 = null;
        var trojan_obfshost: ?[]const u8 = null;
        var trojan_obfsuri: ?[]const u8 = null;
        if (plugin_value) |plugin_raw| {
            trojan_plugin = plugin_raw;
            if (extractPluginField(allocator, plugin_raw, "obfs")) |v| trojan_obfs = v;
            if (extractPluginField(allocator, plugin_raw, "obfs-host")) |v| trojan_obfshost = v;
            if (extractPluginField(allocator, plugin_raw, "obfs-uri")) |v| trojan_obfsuri = v;
        } else if (type_value) |tv| {
            if (std.mem.eql(u8, tv, "ws")) {
                trojan_plugin = "obfs-local";
                trojan_obfs = "websocket";
                trojan_obfshost = host_value;
                trojan_obfsuri = path_value;
            }
        }

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldPort(writer, &first, "port", node.port);
        try jsonFieldString(writer, &first, "server", node.server);
        try jsonFieldString(writer, &first, "type", "5");
        try jsonFieldMaybeString(writer, &first, "trojan_ai", if (ai) "1" else null);
        try jsonFieldMaybeString(writer, &first, "trojan_pcs", pcs_value);
        try jsonFieldMaybeString(writer, &first, "trojan_sni", node.sni);
        try jsonFieldMaybeString(writer, &first, "trojan_tfo", tfo_value);
        try jsonFieldMaybeString(writer, &first, "trojan_uuid", node.password);
        try jsonFieldMaybeString(writer, &first, "trojan_vcn", vcn_value);
        try jsonFieldMaybeString(writer, &first, "trojan_plugin", trojan_plugin);
        try jsonFieldMaybeString(writer, &first, "trojan_obfs", trojan_obfs);
        try jsonFieldMaybeString(writer, &first, "trojan_obfshost", trojan_obfshost);
        try jsonFieldMaybeString(writer, &first, "trojan_obfsuri", trojan_obfsuri);
    } else if (std.mem.eql(u8, node.scheme, "naive+https") or std.mem.eql(u8, node.scheme, "naive+quic")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const password_b64 = if (node.password) |v| try base64EncodeAlloc(allocator, v) else null;
        defer if (password_b64) |v| allocator.free(v);

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldString(writer, &first, "type", "6");
        try jsonFieldMaybeString(writer, &first, "naive_prot", node.protocol);
        try jsonFieldString(writer, &first, "naive_server", node.server);
        try jsonFieldPort(writer, &first, "naive_port", node.port);
        try jsonFieldMaybeString(writer, &first, "naive_user", node.username);
        try jsonFieldMaybeString(writer, &first, "naive_pass", password_b64);
    } else if (std.mem.eql(u8, node.scheme, "tuic")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const tuic_json_b64 = try buildTuicJsonBase64Alloc(allocator, node, options);
        defer allocator.free(tuic_json_b64);

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldMaybeString(writer, &first, "tuic_json", tuic_json_b64);
        try jsonFieldString(writer, &first, "type", "7");
    } else if (std.mem.eql(u8, node.scheme, "hy2") or std.mem.eql(u8, node.scheme, "hysteria2")) {
        const group_hash = try makeGroupHashAlloc(allocator, node, options);
        defer if (group_hash) |v| allocator.free(v);
        const hy2_ctx = effectiveHy2Context(options);
        const ai = effectiveAllowInsecure(node, options);
        const vcn_value = try rawUriQueryValueAlloc(allocator, node, "vcn");
        defer if (vcn_value) |v| allocator.free(v);
        const tfo_value = try rawUriQueryValueAlloc(allocator, node, "tfo");
        defer if (tfo_value) |v| allocator.free(v);

        try jsonFieldMaybeString(writer, &first, "group", group_hash);
        try jsonFieldMaybeString(writer, &first, "mode", options.mode);
        try jsonFieldString(writer, &first, "name", node.name);
        try jsonFieldString(writer, &first, "type", "8");
        try jsonFieldString(writer, &first, "hy2_server", node.server);
        try jsonFieldPort(writer, &first, "hy2_port", node.port);
        try jsonFieldMaybeString(writer, &first, "hy2_pass", node.password);
        try jsonFieldMaybeString(writer, &first, "hy2_ai", if (ai) "1" else null);
        try jsonFieldMaybeString(writer, &first, "hy2_pcs", node.public_key);
        try jsonFieldMaybeString(writer, &first, "hy2_sni", node.sni);
        try jsonFieldMaybeString(writer, &first, "hy2_vcn", vcn_value);
        try jsonFieldString(writer, &first, "hy2_obfs", hy2ObfsValue(node.obfs));
        try jsonFieldMaybeString(writer, &first, "hy2_obfs_pass", node.obfs_password);
        try jsonFieldMaybeString(writer, &first, "hy2_up", hy2_ctx.up);
        try jsonFieldMaybeString(writer, &first, "hy2_dl", hy2_ctx.dl);
        try jsonFieldMaybeString(writer, &first, "hy2_cg", hy2_ctx.cg);
        try jsonFieldMaybeString(writer, &first, "hy2_tfo", resolveHy2Tfo(hy2_ctx.tfo_switch, tfo_value));
    } else {
        return false;
    }

    try writer.writeAll("}\n");
    return true;
}

fn jsonFieldSeparator(writer: anytype, first: *bool) !void {
    if (first.*) {
        first.* = false;
    } else {
        try writer.writeAll(",");
    }
}

fn jsonFieldString(writer: anytype, first: *bool, key: []const u8, value: []const u8) !void {
    try jsonFieldSeparator(writer, first);
    try writeJsonString(writer, key);
    try writer.writeAll(":");
    try writeJsonString(writer, value);
}

fn jsonFieldMaybeString(writer: anytype, first: *bool, key: []const u8, value: ?[]const u8) !void {
    if (value) |v| {
        if (v.len == 0) return;
        try jsonFieldString(writer, first, key, v);
    }
}

fn jsonFieldPort(writer: anytype, first: *bool, key: []const u8, port: u16) !void {
    var buf: [16]u8 = undefined;
    const text = try std.fmt.bufPrint(&buf, "{d}", .{port});
    try jsonFieldString(writer, first, key, text);
}

const Hy2Context = struct {
    up: ?[]const u8,
    dl: ?[]const u8,
    tfo_switch: []const u8,
    cg: []const u8,
};

fn effectiveHy2Context(options: Options) Hy2Context {
    var up = options.hy2_up;
    var dl = options.hy2_dl;
    if (up == null and dl != null) dl = null;
    if (up != null and dl == null) up = null;
    return .{
        .up = up,
        .dl = dl,
        .tfo_switch = options.hy2_tfo_switch orelse "2",
        .cg = if (up == null and dl == null) "bbr" else (options.hy2_cg_opt orelse "bbr"),
    };
}

fn hy2ObfsValue(obfs: ?[]const u8) []const u8 {
    if (obfs) |value| {
        if (std.mem.eql(u8, value, "salamander")) return "1";
        if (std.mem.eql(u8, value, "none")) return "0";
        return value;
    }
    return "0";
}

fn resolveHy2Tfo(tfo_switch: []const u8, raw_tfo: ?[]const u8) ?[]const u8 {
    if (std.mem.eql(u8, tfo_switch, "1")) return "1";
    if (std.mem.eql(u8, tfo_switch, "0")) return "0";
    return raw_tfo;
}

fn effectiveAllowInsecure(node: NormalizedNode, options: Options) bool {
    return options.sub_ai_force or (node.allow_insecure orelse false);
}

fn isVmessPlainUri(node: NormalizedNode) bool {
    const raw = node.raw_uri orelse return false;
    const body = requireBody(raw, "vmess") catch return false;
    return std.mem.indexOfScalar(u8, body, '@') != null or std.mem.indexOfScalar(u8, body, '?') != null;
}

fn rawUriQueryValueAlloc(allocator: std.mem.Allocator, node: NormalizedNode, key: []const u8) !?[]u8 {
    const raw = node.raw_uri orelse return null;
    const scheme = detectScheme(raw) orelse return null;
    const body = try requireBody(raw, scheme);
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    return queryValueAlloc(allocator, query_main.query, key);
}

fn makeGroupHashAlloc(allocator: std.mem.Allocator, node: NormalizedNode, options: Options) !?[]u8 {
    const source_tag = options.source_tag orelse return null;
    var normalized: ?[]u8 = null;
    if (std.mem.eql(u8, node.scheme, "ss")) {
        normalized = try extractNormalizedGroupFromSsRawAlloc(allocator, node);
    } else if (std.mem.eql(u8, node.scheme, "ssr")) {
        normalized = try extractNormalizedGroupFromSsrRawAlloc(allocator, node);
    }
    if (normalized == null and options.group != null) {
        normalized = try normalizeOptionalGroupAlloc(allocator, options.group.?, false);
    }
    const group_text = normalized orelse return null;
    defer allocator.free(group_text);
    return try std.fmt.allocPrint(allocator, "{s}_{s}", .{ group_text, source_tag });
}

fn extractNormalizedGroupFromSsRawAlloc(allocator: std.mem.Allocator, node: NormalizedNode) !?[]u8 {
    const raw = node.raw_uri orelse return null;
    const body = try requireBody(raw, "ss");
    const without_frag = splitFragment(body).before;
    const query = splitSsQuery(without_frag).query;
    const raw_group = try queryValueAlloc(allocator, query, "group") orelse return null;
    defer allocator.free(raw_group);
    return try normalizeOptionalGroupAlloc(allocator, raw_group, true);
}

fn extractNormalizedGroupFromSsrRawAlloc(allocator: std.mem.Allocator, node: NormalizedNode) !?[]u8 {
    const raw = node.raw_uri orelse return null;
    const body = try requireBody(raw, "ssr");
    const decoded = try decodeBase64SmartAlloc(allocator, body);
    defer allocator.free(decoded);
    const slash = std.mem.indexOf(u8, decoded, "/?") orelse return null;
    const query = decoded[slash + 2 ..];
    const raw_group = try decodeOptionalB64QueryValue(allocator, query, "group") orelse return null;
    defer allocator.free(raw_group);
    return try normalizeOptionalGroupAlloc(allocator, raw_group, false);
}

fn normalizeOptionalGroupAlloc(allocator: std.mem.Allocator, value: []const u8, decode_b64: bool) !?[]u8 {
    var raw_value: []const u8 = value;
    var decoded: ?[]u8 = null;
    defer if (decoded) |buf| allocator.free(buf);

    if (decode_b64) {
        decoded = decodeBase64SmartAlloc(allocator, value) catch null;
        if (decoded == null) return null;
        raw_value = decoded.?;
    }

    const trimmed = std.mem.trim(u8, raw_value, " \t\r\n");
    if (trimmed.len == 0 or std.mem.eql(u8, trimmed, "null") or std.mem.eql(u8, trimmed, "_")) return null;
    if (std.mem.lastIndexOfScalar(u8, trimmed, '_')) |idx| {
        if (idx > 0) {
            const prefix = trimmed[0..idx];
            if (prefix.len == 0 or std.mem.eql(u8, prefix, "null") or std.mem.eql(u8, prefix, "_")) return null;
            return try allocator.dupe(u8, prefix);
        }
    }
    return try allocator.dupe(u8, trimmed);
}

fn base64EncodeAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const size = std.base64.standard.Encoder.calcSize(input.len);
    const out = try allocator.alloc(u8, size);
    _ = std.base64.standard.Encoder.encode(out, input);
    return out;
}

fn hasToken(allocator: std.mem.Allocator, value: ?[]const u8, token: []const u8) !bool {
    const text = value orelse return false;
    const lowered = try asciiLowerAlloc(allocator, text);
    defer allocator.free(lowered);
    var parts = std.mem.splitScalar(u8, lowered, ',');
    while (parts.next()) |part_raw| {
        const part = std.mem.trim(u8, part_raw, " \t");
        if (std.mem.eql(u8, part, token)) return true;
    }
    return false;
}

fn buildTuicJsonBase64Alloc(allocator: std.mem.Allocator, node: NormalizedNode, options: Options) ![]u8 {
    var out = std.ArrayList(u8){};
    defer out.deinit(allocator);
    const writer = out.writer(allocator);

    const server_host = blk: {
        if ((try rawUriQueryValueAlloc(allocator, node, "sni"))) |sni_value| {
            defer allocator.free(sni_value);
            if (isIpLiteral(node.server)) break :blk sni_value;
        }
        break :blk node.server;
    };

    const ip_value = blk: {
        if ((try rawUriQueryValueAlloc(allocator, node, "sni"))) |_| {
            if (isIpLiteral(node.server)) break :blk node.server;
        }
        if (node.host) |host_value| {
            if (!std.mem.eql(u8, host_value, node.server)) break :blk host_value;
        }
        break :blk null;
    };

    try writer.writeAll("{\"relay\":{");
    var first = true;
    const server_text = try formatHostPortAlloc(allocator, server_host, node.port);
    defer allocator.free(server_text);
    try jsonFieldString(writer, &first, "server", server_text);
    try jsonFieldMaybeString(writer, &first, "uuid", node.uuid);
    try jsonFieldMaybeString(writer, &first, "password", node.password);
    try jsonFieldMaybeString(writer, &first, "ip", ip_value);
    if (node.alpn) |alpn_value| {
        const alpn_json = try splitCsvToJsonArrayAlloc(allocator, alpn_value);
        defer allocator.free(alpn_json);
        try jsonFieldSeparator(writer, &first);
        try writeJsonString(writer, "alpn");
        try writer.writeAll(":");
        try writer.writeAll(alpn_json);
    }
    try jsonFieldMaybeString(writer, &first, "congestion_control", node.congestion_control);
    if (effectiveAllowInsecure(node, options)) {
        try jsonFieldString(writer, &first, "skip_cert_verify", "true");
    }
    try writer.writeAll("}}");

    return try base64EncodeAlloc(allocator, out.items);
}

fn splitCsvToJsonArrayAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var out = std.ArrayList(u8){};
    defer out.deinit(allocator);
    const writer = out.writer(allocator);
    try writer.writeAll("[");
    var first = true;
    var parts = std.mem.splitScalar(u8, input, ',');
    while (parts.next()) |part_raw| {
        const part = std.mem.trim(u8, part_raw, " \t");
        if (part.len == 0) continue;
        if (first) {
            first = false;
        } else {
            try writer.writeAll(",");
        }
        try writeJsonString(writer, part);
    }
    try writer.writeAll("]");
    return try out.toOwnedSlice(allocator);
}

fn formatHostPortAlloc(allocator: std.mem.Allocator, host: []const u8, port: u16) ![]u8 {
    if (std.mem.indexOfScalar(u8, host, ':') != null and host[0] != '[') {
        return try std.fmt.allocPrint(allocator, "[{s}]:{d}", .{ host, port });
    }
    return try std.fmt.allocPrint(allocator, "{s}:{d}", .{ host, port });
}

fn isIpLiteral(host: []const u8) bool {
    return isIpv4Literal(host) or isIpv6Literal(host);
}

fn isIpv4Literal(host: []const u8) bool {
    var parts = std.mem.splitScalar(u8, host, '.');
    var count: usize = 0;
    while (parts.next()) |part| {
        count += 1;
        if (part.len == 0) return false;
        _ = std.fmt.parseInt(u8, part, 10) catch return false;
    }
    return count == 4;
}

fn isIpv6Literal(host: []const u8) bool {
    return std.mem.indexOfScalar(u8, host, ':') != null;
}

fn readInput(allocator: std.mem.Allocator, input_path: ?[]const u8) ![]u8 {
    if (input_path) |path| {
        return try std.fs.cwd().readFileAlloc(allocator, path, max_input_size);
    }
    return try std.fs.File.stdin().readToEndAlloc(allocator, max_input_size);
}

fn detectContentInfo(allocator: std.mem.Allocator, raw: []const u8) !ContentInfo {
    const trimmed = std.mem.trim(u8, raw, " \t\r\n");
    const normalized = trimBom(trimmed);
    if (normalized.len == 0) {
        return .{ .kind = .empty, .content = try allocator.dupe(u8, normalized) };
    }
    if (normalized.len >= 2 and normalized[0] == 0x1f and normalized[1] == 0x8b) {
        return .{ .kind = .gzip, .content = try allocator.dupe(u8, normalized) };
    }
    if (looksLikeHtml(normalized)) {
        return .{
            .kind = detectHtmlKind(normalized),
            .content = try allocator.dupe(u8, normalized),
        };
    }
    if (looksLikeClashYaml(normalized)) {
        return .{ .kind = .clash_yaml, .content = try allocator.dupe(u8, normalized) };
    }
    if (looksLikeSsepEnvelope(allocator, normalized)) {
        return .{ .kind = .ssep_envelope, .content = try allocator.dupe(u8, normalized) };
    }
    if (looksLikeUriLines(normalized)) {
        return .{ .kind = .uri_lines, .content = try allocator.dupe(u8, normalized) };
    }
    if (looksLikeJson(normalized)) {
        return .{
            .kind = if (looksLikeJsonError(allocator, normalized)) .json_error else .json,
            .content = try allocator.dupe(u8, normalized),
        };
    }
    if (looksLikeTextError(normalized)) {
        return .{ .kind = .text_error, .content = try allocator.dupe(u8, normalized) };
    }

    if (try maybeDecodeBase64Text(allocator, normalized)) |decoded| {
        const decoded_trimmed = trimBom(std.mem.trim(u8, decoded, " \t\r\n"));
        if (decoded_trimmed.len == 0) {
            allocator.free(decoded);
            return .{ .kind = .empty, .content = try allocator.dupe(u8, normalized) };
        }
        if (looksLikeUriLines(decoded)) {
            return .{ .kind = .base64_uri_lines, .content = decoded };
        }
        if (looksLikeClashYaml(decoded_trimmed)) {
            allocator.free(decoded);
            return .{ .kind = .clash_yaml, .content = try allocator.dupe(u8, normalized) };
        }
        if (looksLikeJson(decoded_trimmed)) {
            const kind: InputKind = if (looksLikeJsonError(allocator, decoded_trimmed)) .json_error else .json;
            allocator.free(decoded);
            return .{ .kind = kind, .content = try allocator.dupe(u8, normalized) };
        }
        if (looksLikeHtml(decoded_trimmed)) {
            const kind: InputKind = detectHtmlKind(decoded_trimmed);
            allocator.free(decoded);
            return .{ .kind = kind, .content = try allocator.dupe(u8, normalized) };
        }
        if (looksLikeTextError(decoded_trimmed)) {
            allocator.free(decoded);
            return .{ .kind = .text_error, .content = try allocator.dupe(u8, normalized) };
        }
        allocator.free(decoded);
    }

    return .{ .kind = .unknown, .content = try allocator.dupe(u8, normalized) };
}

fn parseSubscription(allocator: std.mem.Allocator, raw: []const u8, options: Options) !ParseResult {
    var result = ParseResult.init(allocator);

    const info = try detectContentInfo(allocator, raw);
    defer if (info.content.ptr != raw.ptr) allocator.free(info.content);
    result.kind = info.kind;

    switch (info.kind) {
        .uri_lines, .base64_uri_lines => {},
        else => return error.UnsupportedInputKind,
    }

    var lines = std.mem.tokenizeAny(u8, info.content, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0) continue;
        result.total_lines += 1;
        if (line[0] == '#') {
            result.ignored_lines += 1;
            continue;
        }

        const node = parseLine(allocator, line, options) catch |err| switch (err) {
            error.UnsupportedScheme => {
                result.ignored_lines += 1;
                continue;
            },
            else => {
                result.invalid_lines += 1;
                continue;
            },
        };

        try result.nodes.append(allocator, node);
        result.valid_lines += 1;
    }

    return result;
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const scheme = detectScheme(line) orelse return error.UnsupportedScheme;
    if (std.mem.eql(u8, scheme, "ss")) return parseSs(allocator, line, options);
    if (std.mem.eql(u8, scheme, "ssr")) return parseSsr(allocator, line, options);
    if (std.mem.eql(u8, scheme, "vmess")) {
        const body = try requireBody(line, "vmess");
        const query_main = splitQuery(body);
        if (query_main.query.len > 0 and looksLikeBase64(query_main.before)) {
            if (try maybeDecodeBase64Lossy(allocator, query_main.before)) |decoded| {
                defer allocator.free(decoded);
                if (std.mem.indexOfScalar(u8, decoded, '@') != null) {
                    return parseVmessUriEncoded(allocator, line, options);
                }
            }
        }
        if (std.mem.indexOfScalar(u8, body, '@') != null or std.mem.indexOfScalar(u8, body, '?') != null) {
            return parseVlessLike(allocator, "vmess", line, options);
        }
        return parseVmess(allocator, line, options);
    }
    if (std.mem.eql(u8, scheme, "vless")) return parseVlessLike(allocator, "vless", line, options);
    if (std.mem.eql(u8, scheme, "trojan")) return parseTrojan(allocator, line, options);
    if (std.mem.eql(u8, scheme, "naive+https") or std.mem.eql(u8, scheme, "naive+quic")) return parseNaive(allocator, scheme, line, options);
    if (std.mem.eql(u8, scheme, "tuic")) return parseTuic(allocator, line, options);
    if (std.mem.eql(u8, scheme, "hy2") or std.mem.eql(u8, scheme, "hysteria2")) return parseHy2(allocator, scheme, line, options);
    return error.UnsupportedScheme;
}

fn parseSs(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    var body = try requireBody(line, "ss");
    const remark = try fragmentOrDefault(allocator, line, "");
    defer allocator.free(remark);

    var plugin_value: ?[]u8 = null;
    defer if (plugin_value) |v| allocator.free(v);

    body = splitFragment(body).before;
    const query_split = splitSsQuery(body);
    body = query_split.before;
    if (query_split.query.len > 0) {
        plugin_value = try queryValueAlloc(allocator, query_split.query, "plugin");
    }

    const decoded_candidate = extractSsUserinfoCandidate(body);
    const main_decoded = try maybeDecodeBase64Lossy(allocator, decoded_candidate);
    defer if (main_decoded) |buf| allocator.free(buf);

    var method: []const u8 = "";
    var password: []const u8 = "";
    var hostport: []const u8 = "";

    if (main_decoded) |decoded| {
        if (std.mem.indexOfScalar(u8, decoded, '@')) |_| {
            const at = std.mem.lastIndexOfScalar(u8, decoded, '@').?;
            const userinfo = decoded[0..at];
            hostport = decoded[at + 1 ..];
            const mp = std.mem.indexOfScalar(u8, userinfo, ':') orelse return error.InvalidUri;
            method = userinfo[0..mp];
            password = userinfo[mp + 1 ..];
        } else {
            const at = std.mem.lastIndexOfScalar(u8, body, '@') orelse return error.InvalidUri;
            const userinfo_decoded = decoded;
            const mp = std.mem.indexOfScalar(u8, userinfo_decoded, ':') orelse return error.InvalidUri;
            method = userinfo_decoded[0..mp];
            password = userinfo_decoded[mp + 1 ..];
            hostport = body[at + 1 ..];
        }
    } else {
        const at = std.mem.lastIndexOfScalar(u8, body, '@') orelse return error.InvalidUri;
        const userinfo = body[0..at];
        const mp = std.mem.indexOfScalar(u8, userinfo, ':') orelse return error.InvalidUri;
        method = userinfo[0..mp];
        password = userinfo[mp + 1 ..];
        hostport = body[at + 1 ..];
    }
    hostport = std.mem.trimRight(u8, hostport, "/");

    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);

    const final_name = if (remark.len > 0) remark else hp.host;
    const raw_group = try queryValueAlloc(allocator, query_split.query, "group");
    const group = if (raw_group) |v| try normalizeOptionalGroupAlloc(allocator, v, true) else null;
    defer if (raw_group) |v| allocator.free(v);
    defer if (group) |v| allocator.free(v);

    var node = try baseNode(allocator, "ss", final_name, hp.host, hp.port, options);
    node.method = try allocator.dupe(u8, method);
    node.password = try allocator.dupe(u8, password);
    if (group) |g| node.group = try allocator.dupe(u8, g);
    if (plugin_value) |plugin_raw| {
        node.protocol = try allocator.dupe(u8, "plugin");
        node.obfs = try allocator.dupe(u8, plugin_raw);
        if (std.mem.indexOf(u8, plugin_raw, "obfs=")) |_| {
            if (extractPluginField(allocator, plugin_raw, "obfs")) |v| node.obfs = v;
            if (extractPluginField(allocator, plugin_raw, "obfs-host")) |v| node.obfs_host = v;
        }
    }
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseSsr(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, "ssr");
    const decoded = try decodeBase64SmartAlloc(allocator, body);
    defer allocator.free(decoded);

    const slash = std.mem.indexOf(u8, decoded, "/?") orelse return error.InvalidUri;
    const head = decoded[0..slash];
    const query = decoded[slash + 2 ..];

    var fields = std.mem.splitScalar(u8, head, ':');
    const server = fields.next() orelse return error.InvalidUri;
    const port_text = fields.next() orelse return error.InvalidUri;
    const protocol = fields.next() orelse return error.InvalidUri;
    const method = fields.next() orelse return error.InvalidUri;
    const obfs = fields.next() orelse return error.InvalidUri;
    const password = fields.next() orelse return error.InvalidUri;
    const port = try parsePort(port_text);

    const remarks = try decodeOptionalB64QueryValue(allocator, query, "remarks");
    defer if (remarks) |v| allocator.free(v);
    const raw_group = try decodeOptionalB64QueryValue(allocator, query, "group");
    const group = if (raw_group) |v| try normalizeOptionalGroupAlloc(allocator, v, false) else null;
    defer if (raw_group) |v| allocator.free(v);
    defer if (group) |v| allocator.free(v);
    const obfsparam = try decodeOptionalB64QueryValue(allocator, query, "obfsparam");
    defer if (obfsparam) |v| allocator.free(v);
    const protoparam = try decodeOptionalB64QueryValue(allocator, query, "protoparam");
    defer if (protoparam) |v| allocator.free(v);

    const final_name = if (remarks) |v| v else server;
    var node = try baseNode(allocator, "ssr", final_name, server, port, options);
    if (group) |v| node.group = try allocator.dupe(u8, v);
    node.protocol = try allocator.dupe(u8, protocol);
    node.method = try allocator.dupe(u8, method);
    node.password = try allocator.dupe(u8, password);
    node.obfs = try allocator.dupe(u8, obfs);
    if (obfsparam) |v| node.obfs_host = try allocator.dupe(u8, v);
    if (protoparam) |v| node.protocol_param = try allocator.dupe(u8, v);
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseVmess(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, "vmess");
    const decoded = try decodeBase64SmartAlloc(allocator, body);
    defer allocator.free(decoded);

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, decoded, .{});
    defer parsed.deinit();
    const root = parsed.value;
    if (root != .object) return error.InvalidUri;

    const obj = root.object;
    const name = (try jsonObjectTextAlloc(allocator, obj, "ps")) orelse
        (try jsonObjectTextAlloc(allocator, obj, "remark")) orelse
        (try jsonObjectTextAlloc(allocator, obj, "add")) orelse return error.InvalidUri;
    defer allocator.free(name);
    const server = (try jsonObjectTextAlloc(allocator, obj, "add")) orelse return error.InvalidUri;
    defer allocator.free(server);
    const port_text = (try jsonObjectTextAlloc(allocator, obj, "port")) orelse return error.InvalidUri;
    defer allocator.free(port_text);
    const port = try parsePort(port_text);

    var node = try baseNode(allocator, "vmess", name, server, port, options);
    if (try jsonObjectTextAlloc(allocator, obj, "id")) |v| node.uuid = v;
    if (try jsonObjectTextAlloc(allocator, obj, "aid")) |v| node.protocol_param = v;
    if (try jsonObjectTextAlloc(allocator, obj, "scy")) |v| node.method = v;
    if (try jsonObjectTextAlloc(allocator, obj, "net")) |v| node.network = v;
    if (try jsonObjectTextAlloc(allocator, obj, "tls")) |v| {
        if (v.len > 0) node.security = v else allocator.free(v);
    }
    if (try jsonObjectTextAlloc(allocator, obj, "host")) |v| node.host = v;
    if (try jsonObjectTextAlloc(allocator, obj, "path")) |v| node.path = v;
    if (try jsonObjectTextAlloc(allocator, obj, "sni")) |v| node.sni = v;
    if (try jsonObjectTextAlloc(allocator, obj, "alpn")) |v| node.alpn = v;
    if (try jsonObjectTextAlloc(allocator, obj, "type")) |v| node.protocol = v;
    if (try jsonObjectTextAlloc(allocator, obj, "verify_cert")) |v| {
        node.allow_insecure = !stringEqualsIgnoreCase(v, "true");
        allocator.free(v);
    }
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseVmessUriEncoded(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, "vmess");
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const decoded = try decodeBase64SmartAlloc(allocator, query_main.before);
    defer allocator.free(decoded);
    const at = std.mem.lastIndexOfScalar(u8, decoded, '@') orelse return error.InvalidUri;
    const userinfo = decoded[0..at];
    const hostport = decoded[at + 1 ..];
    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);
    const name = if (try queryValueAlloc(allocator, query_main.query, "remark")) |v|
        v
    else if (parts.fragment.len > 0)
        try urlDecodeAlloc(allocator, parts.fragment)
    else
        try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    var uuid: []const u8 = userinfo;
    var method: ?[]u8 = null;
    if (std.mem.indexOfScalar(u8, userinfo, ':')) |colon| {
        const candidate_method = userinfo[0..colon];
        const candidate_uuid = userinfo[colon + 1 ..];
        if (candidate_uuid.len > 0) {
            uuid = candidate_uuid;
            method = try allocator.dupe(u8, candidate_method);
        }
    }

    var node = try baseNode(allocator, "vmess", name, hp.host, hp.port, options);
    node.uuid = try allocator.dupe(u8, uuid);
    if (method) |m| node.method = m;
    if (try queryValueAlloc(allocator, query_main.query, "network")) |v| node.network = v;
    if (try queryValueAlloc(allocator, query_main.query, "type")) |v| node.protocol = v;
    if (try queryValueAlloc(allocator, query_main.query, "wsPath")) |v| node.path = v;
    if (try queryValueAlloc(allocator, query_main.query, "path")) |v| {
        if (node.path == null) {
            node.path = v;
        } else {
            allocator.free(v);
        }
    }
    if (try queryValueAlloc(allocator, query_main.query, "host")) |v| node.host = v;
    if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
    if (try queryValueAlloc(allocator, query_main.query, "tls")) |v| {
        if (std.mem.eql(u8, v, "1") or stringEqualsIgnoreCase(v, "tls") or stringEqualsIgnoreCase(v, "true")) {
            allocator.free(v);
            node.security = try allocator.dupe(u8, "tls");
        } else {
            node.security = v;
        }
    }
    if (try queryValueAlloc(allocator, query_main.query, "aid")) |v| node.protocol_param = v;
    if (try queryBoolValue(query_main.query, "allowInsecure")) |v| node.allow_insecure = v;
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseVlessLike(allocator: std.mem.Allocator, scheme: []const u8, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, scheme);
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const authority = query_main.before;
    const at = std.mem.lastIndexOfScalar(u8, authority, '@') orelse return error.InvalidUri;
    const userinfo = authority[0..at];
    const hostport = authority[at + 1 ..];
    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);

    const name = if (parts.fragment.len > 0) try urlDecodeAlloc(allocator, parts.fragment) else try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    var node = try baseNode(allocator, scheme, name, hp.host, hp.port, options);
    node.uuid = try allocator.dupe(u8, userinfo);
    if (query_main.query.len > 0) {
        if (try queryValueAlloc(allocator, query_main.query, "type")) |v| node.network = v;
        if (try queryValueAlloc(allocator, query_main.query, "security")) |v| node.security = v;
        if (try queryValueAlloc(allocator, query_main.query, "host")) |v| node.host = v;
        if (try queryValueAlloc(allocator, query_main.query, "path")) |v| node.path = v;
        if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
        if (try queryValueAlloc(allocator, query_main.query, "flow")) |v| node.flow = v;
        if (try queryValueAlloc(allocator, query_main.query, "fp")) |v| node.fingerprint = v;
        if (try queryValueAlloc(allocator, query_main.query, "pbk")) |v| node.public_key = v;
        if (try queryValueAlloc(allocator, query_main.query, "sid")) |v| node.short_id = v;
        if (try queryValueAlloc(allocator, query_main.query, "spx")) |v| node.spider_x = v;
        if (try queryValueAlloc(allocator, query_main.query, "alpn")) |v| node.alpn = v;
        if (try queryValueAlloc(allocator, query_main.query, "headerType")) |v| node.protocol = v;
        if (try queryBoolValue(query_main.query, "allowInsecure")) |v| node.allow_insecure = v;
        if (try queryBoolValue(query_main.query, "insecure")) |v| node.allow_insecure = v;
    }
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseTrojan(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, "trojan");
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const authority = query_main.before;
    const at = std.mem.lastIndexOfScalar(u8, authority, '@') orelse return error.InvalidUri;
    const password = authority[0..at];
    const hostport = authority[at + 1 ..];
    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);
    const name = if (parts.fragment.len > 0) try urlDecodeAlloc(allocator, parts.fragment) else try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    var node = try baseNode(allocator, "trojan", name, hp.host, hp.port, options);
    node.password = try allocator.dupe(u8, password);
    if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
    if (try queryValueAlloc(allocator, query_main.query, "peer")) |v| {
        if (node.sni == null) {
            node.sni = v;
        } else {
            allocator.free(v);
        }
    }
    if (try queryValueAlloc(allocator, query_main.query, "type")) |v| node.network = v;
    if (try queryValueAlloc(allocator, query_main.query, "host")) |v| node.host = v;
    if (try queryValueAlloc(allocator, query_main.query, "path")) |v| node.path = v;
    if (try queryValueAlloc(allocator, query_main.query, "security")) |v| node.security = v;
    if (try queryBoolValue(query_main.query, "allowInsecure")) |v| node.allow_insecure = v;
    if (try queryBoolValue(query_main.query, "insecure")) |v| node.allow_insecure = v;
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseNaive(allocator: std.mem.Allocator, scheme: []const u8, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, scheme);
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const authority = std.mem.trimRight(u8, query_main.before, "/");
    const at = std.mem.lastIndexOfScalar(u8, authority, '@') orelse return error.InvalidUri;
    const auth = authority[0..at];
    const hostport = authority[at + 1 ..];
    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);

    const colon = std.mem.indexOfScalar(u8, auth, ':') orelse return error.InvalidUri;
    const username = auth[0..colon];
    const password = auth[colon + 1 ..];
    const name = if (parts.fragment.len > 0) try urlDecodeAlloc(allocator, parts.fragment) else try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    var node = try baseNode(allocator, scheme, name, hp.host, hp.port, options);
    node.username = try allocator.dupe(u8, username);
    node.password = try allocator.dupe(u8, password);
    node.protocol = try allocator.dupe(u8, scheme["naive+".len..]);
    if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
    if (try queryBoolValue(query_main.query, "insecure")) |v| node.allow_insecure = v;
    if (try queryValueAlloc(allocator, query_main.query, "extra-headers")) |v| node.protocol_param = v;
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseTuic(allocator: std.mem.Allocator, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, "tuic");
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const authority = std.mem.trimRight(u8, query_main.before, "/");
    const at = std.mem.lastIndexOfScalar(u8, authority, '@');

    var uuid: ?[]const u8 = null;
    var password: ?[]const u8 = null;
    var hostport = authority;

    if (at) |pos| {
        const auth = authority[0..pos];
        hostport = authority[pos + 1 ..];
        if (std.mem.indexOfScalar(u8, auth, ':')) |colon| {
            uuid = auth[0..colon];
            password = auth[colon + 1 ..];
        }
    }

    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);
    const name = if (parts.fragment.len > 0) try urlDecodeAlloc(allocator, parts.fragment) else try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    if (uuid == null) uuid = try queryValueBorrowed(allocator, query_main.query, "uuid");
    if (uuid == null) uuid = try queryValueBorrowed(allocator, query_main.query, "id");
    if (password == null) password = try queryValueBorrowed(allocator, query_main.query, "password");
    if (password == null) password = try queryValueBorrowed(allocator, query_main.query, "passwd");
    if (password == null) password = try queryValueBorrowed(allocator, query_main.query, "token");
    if (uuid == null or password == null) return error.InvalidUri;

    var node = try baseNode(allocator, "tuic", name, hp.host, hp.port, options);
    node.uuid = try allocator.dupe(u8, uuid.?);
    node.password = try allocator.dupe(u8, password.?);
    if (try queryValueAlloc(allocator, query_main.query, "alpn")) |v| node.alpn = v;
    if (try queryValueAlloc(allocator, query_main.query, "congestion_control")) |v| node.congestion_control = v;
    if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
    if (try queryValueAlloc(allocator, query_main.query, "ip")) |v| node.host = v;
    if (try queryBoolValue(query_main.query, "allow_insecure")) |v| node.allow_insecure = v;
    if (try queryBoolValue(query_main.query, "allowInsecure")) |v| node.allow_insecure = v;
    if (try queryBoolValue(query_main.query, "insecure")) |v| node.allow_insecure = v;
    if (try queryBoolValue(query_main.query, "skip_cert_verify")) |v| node.allow_insecure = v;
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn parseHy2(allocator: std.mem.Allocator, scheme: []const u8, line: []const u8, options: Options) !NormalizedNode {
    const body = try requireBody(line, scheme);
    const parts = splitFragment(body);
    const query_main = splitQuery(parts.before);
    const authority = std.mem.trimRight(u8, query_main.before, "/");
    const at = std.mem.lastIndexOfScalar(u8, authority, '@');

    var password: ?[]const u8 = null;
    var hostport = authority;
    if (at) |pos| {
        password = authority[0..pos];
        hostport = authority[pos + 1 ..];
    }
    const hp = try splitHostPortAlloc(allocator, hostport);
    defer hp.deinit(allocator);
    const name = if (parts.fragment.len > 0) try urlDecodeAlloc(allocator, parts.fragment) else try allocator.dupe(u8, hp.host);
    defer allocator.free(name);

    var node = try baseNode(allocator, scheme, name, hp.host, hp.port, options);
    node.password = if (password) |v| try allocator.dupe(u8, v) else null;
    if (try queryValueAlloc(allocator, query_main.query, "sni")) |v| node.sni = v;
    if (try queryValueAlloc(allocator, query_main.query, "obfs")) |v| node.obfs = v;
    if (try queryValueAlloc(allocator, query_main.query, "obfs-password")) |v| node.obfs_password = v;
    if (try queryValueAlloc(allocator, query_main.query, "pinSHA256")) |v| node.public_key = v;
    if (try queryValueAlloc(allocator, query_main.query, "pcs")) |v| {
        if (node.public_key == null) {
            node.public_key = v;
        } else {
            allocator.free(v);
        }
    }
    if (try queryBoolValue(query_main.query, "insecure")) |v| node.allow_insecure = v;
    if (try queryBoolValue(query_main.query, "allowInsecure")) |v| node.allow_insecure = v;
    if (options.include_raw) node.raw_uri = try allocator.dupe(u8, line);
    return node;
}

fn baseNode(allocator: std.mem.Allocator, scheme: []const u8, name: []const u8, server: []const u8, port: u16, options: Options) !NormalizedNode {
    return .{
        .scheme = try allocator.dupe(u8, scheme),
        .name = try allocator.dupe(u8, name),
        .server = try allocator.dupe(u8, server),
        .port = port,
        .group = if (options.group) |v| try allocator.dupe(u8, v) else null,
        .source_tag = if (options.source_tag) |v| try allocator.dupe(u8, v) else null,
    };
}

fn detectScheme(line: []const u8) ?[]const u8 {
    const marker = std.mem.indexOf(u8, line, "://") orelse return null;
    if (marker == 0) return null;
    const scheme = line[0..marker];
    return if (scheme.len > 0) scheme else null;
}

fn requireBody(line: []const u8, expected_scheme: []const u8) ![]const u8 {
    const prefix = try std.fmt.allocPrint(std.heap.page_allocator, "{s}://", .{expected_scheme});
    defer std.heap.page_allocator.free(prefix);
    if (!std.mem.startsWith(u8, line, prefix)) return error.InvalidUri;
    return line[prefix.len..];
}

fn splitFragment(input: []const u8) struct { before: []const u8, fragment: []const u8 } {
    if (std.mem.indexOfScalar(u8, input, '#')) |idx| {
        return .{ .before = input[0..idx], .fragment = input[idx + 1 ..] };
    }
    return .{ .before = input, .fragment = "" };
}

fn splitQuery(input: []const u8) struct { before: []const u8, query: []const u8 } {
    if (std.mem.indexOfScalar(u8, input, '?')) |idx| {
        return .{ .before = input[0..idx], .query = input[idx + 1 ..] };
    }
    return .{ .before = input, .query = "" };
}

fn splitSsQuery(input: []const u8) struct { before: []const u8, query: []const u8 } {
    if (std.mem.indexOfScalar(u8, input, '?')) |idx| {
        return .{ .before = input[0..idx], .query = input[idx + 1 ..] };
    }
    if (std.mem.indexOfScalar(u8, input, '&')) |idx| {
        return .{ .before = input[0..idx], .query = input[idx + 1 ..] };
    }
    return .{ .before = input, .query = "" };
}

const HostPort = struct {
    host: []u8,
    port: u16,

    fn deinit(self: HostPort, allocator: std.mem.Allocator) void {
        allocator.free(self.host);
    }
};

fn splitHostPortAlloc(allocator: std.mem.Allocator, hostport: []const u8) !HostPort {
    var host: []const u8 = hostport;
    var port_text: []const u8 = "";
    if (hostport.len == 0) return error.InvalidUri;

    if (hostport[0] == '[') {
        const end = std.mem.indexOfScalar(u8, hostport, ']') orelse return error.InvalidUri;
        host = hostport[1..end];
        if (end + 1 < hostport.len) {
            if (hostport[end + 1] != ':') return error.InvalidUri;
            port_text = hostport[end + 2 ..];
        }
    } else if (std.mem.lastIndexOfScalar(u8, hostport, ':')) |idx| {
        if (std.mem.indexOfScalar(u8, hostport, ':') == idx) {
            host = hostport[0..idx];
            port_text = hostport[idx + 1 ..];
        } else {
            host = hostport;
        }
    }

    const port = if (port_text.len > 0) try parsePort(port_text) else 443;
    return .{ .host = try allocator.dupe(u8, host), .port = port };
}

fn parsePort(text: []const u8) !u16 {
    return try std.fmt.parseInt(u16, text, 10);
}

fn fragmentOrDefault(allocator: std.mem.Allocator, line: []const u8, fallback: []const u8) ![]u8 {
    const parts = splitFragment(line);
    if (parts.fragment.len == 0) return allocator.dupe(u8, fallback);
    return try urlDecodeAlloc(allocator, parts.fragment);
}

fn extractSsUserinfoCandidate(body: []const u8) []const u8 {
    const at = std.mem.lastIndexOfScalar(u8, body, '@') orelse return body;
    return body[0..at];
}

fn writeJsonString(writer: anytype, value: []const u8) !void {
    try writer.print("{f}", .{std.json.fmt(value, .{})});
}

fn jsonObjectString(obj: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const value = obj.get(key) orelse return null;
    if (value != .string) return null;
    return value.string;
}

fn jsonObjectTextAlloc(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) !?[]u8 {
    const value = obj.get(key) orelse return null;
    return switch (value) {
        .string => try allocator.dupe(u8, value.string),
        .integer => try std.fmt.allocPrint(allocator, "{d}", .{value.integer}),
        .float => try std.fmt.allocPrint(allocator, "{d}", .{value.float}),
        .number_string => try allocator.dupe(u8, value.number_string),
        .bool => try allocator.dupe(u8, if (value.bool) "true" else "false"),
        else => null,
    };
}

fn trimBom(input: []const u8) []const u8 {
    if (input.len >= 3 and input[0] == 0xef and input[1] == 0xbb and input[2] == 0xbf) {
        return input[3..];
    }
    return input;
}

fn lowercaseHeadAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const head = input[0..@min(input.len, 4096)];
    const out = try allocator.dupe(u8, head);
    for (out) |*ch| {
        if (ch.* <= 0x7f) {
            ch.* = std.ascii.toLower(ch.*);
        }
    }
    return out;
}

fn looksLikeJson(input: []const u8) bool {
    return input.len > 1 and ((input[0] == '{' and input[input.len - 1] == '}') or (input[0] == '[' and input[input.len - 1] == ']'));
}

fn looksLikeHtml(input: []const u8) bool {
    const lower = lowercaseHeadAlloc(std.heap.page_allocator, input) catch return false;
    defer std.heap.page_allocator.free(lower);
    return std.mem.startsWith(u8, lower, "<!doctype html") or
        std.mem.startsWith(u8, lower, "<html") or
        std.mem.indexOf(u8, lower, "<html") != null;
}

fn looksLikeHtmlLoginPage(input: []const u8) bool {
    const lower = lowercaseHeadAlloc(std.heap.page_allocator, input) catch return false;
    defer std.heap.page_allocator.free(lower);
    return std.mem.indexOf(u8, lower, "cloudflare access") != null or
        std.mem.indexOf(u8, lower, "sign in") != null or
        std.mem.indexOf(u8, lower, "login") != null or
        std.mem.indexOf(u8, lower, "用户中心") != null or
        std.mem.indexOf(u8, lower, "登录") != null;
}

fn looksLikeHtmlRedirectPage(input: []const u8) bool {
    const lower = lowercaseHeadAlloc(std.heap.page_allocator, input) catch return false;
    defer std.heap.page_allocator.free(lower);
    return std.mem.indexOf(u8, lower, "window.location.replace(") != null or
        std.mem.indexOf(u8, lower, "window.location.href") != null or
        std.mem.indexOf(u8, lower, "window.location=") != null or
        std.mem.indexOf(u8, lower, "redirect_link") != null or
        std.mem.indexOf(u8, lower, "http-equiv=\"refresh\"") != null or
        std.mem.indexOf(u8, lower, "http-equiv='refresh'") != null or
        std.mem.indexOf(u8, lower, "/lander?sub=") != null or
        std.mem.indexOf(u8, lower, "fingerprint/iife.min.js") != null;
}

fn detectHtmlKind(input: []const u8) InputKind {
    if (looksLikeHtmlLoginPage(input)) return .html_login;
    if (looksLikeHtmlRedirectPage(input)) return .html_redirect;
    return .html_page;
}

fn extractHtmlRedirectTargetAlloc(allocator: std.mem.Allocator, input: []const u8) !?[]u8 {
    const head = input[0..@min(input.len, 8192)];
    if (try extractQuotedUrlAfterLiteralAlloc(allocator, head, "window.location.replace(")) |value| return value;
    if (try extractAssignedQuotedUrlAlloc(allocator, head, "window.location.href")) |value| return value;
    if (try extractAssignedQuotedUrlAlloc(allocator, head, "window.location")) |value| return value;
    if (try extractAssignedQuotedUrlAlloc(allocator, head, "redirect_link")) |value| return value;
    if (try extractMetaRefreshUrlAlloc(allocator, head)) |value| return value;
    return null;
}

fn extractQuotedUrlAfterLiteralAlloc(allocator: std.mem.Allocator, input: []const u8, literal: []const u8) !?[]u8 {
    const pos = std.mem.indexOf(u8, input, literal) orelse return null;
    var idx = pos + literal.len;
    while (idx < input.len and isInlineSpace(input[idx])) : (idx += 1) {}
    return extractQuotedUrlAtAlloc(allocator, input, idx);
}

fn extractAssignedQuotedUrlAlloc(allocator: std.mem.Allocator, input: []const u8, literal: []const u8) !?[]u8 {
    const pos = std.mem.indexOf(u8, input, literal) orelse return null;
    var idx = pos + literal.len;
    while (idx < input.len and isInlineSpace(input[idx])) : (idx += 1) {}
    if (idx >= input.len or input[idx] != '=') return null;
    idx += 1;
    while (idx < input.len and isInlineSpace(input[idx])) : (idx += 1) {}
    return extractQuotedUrlAtAlloc(allocator, input, idx);
}

fn extractQuotedUrlAtAlloc(allocator: std.mem.Allocator, input: []const u8, idx: usize) !?[]u8 {
    if (idx >= input.len) return null;
    const quote = input[idx];
    if (quote != '\'' and quote != '"') return null;
    const start = idx + 1;
    var end = start;
    while (end < input.len) : (end += 1) {
        if (input[end] == '\\' and end + 1 < input.len) {
            end += 1;
            continue;
        }
        if (input[end] == quote) break;
    }
    if (end >= input.len or end <= start) return null;
    return try sanitizeRedirectTargetAlloc(allocator, input[start..end]);
}

fn extractMetaRefreshUrlAlloc(allocator: std.mem.Allocator, input: []const u8) !?[]u8 {
    const lower = try lowercasePrefixAlloc(allocator, input, 8192);
    defer allocator.free(lower);
    const pos = std.mem.indexOf(u8, lower, "url=") orelse return null;
    var idx = pos + 4;
    while (idx < input.len and isInlineSpace(input[idx])) : (idx += 1) {}
    if (idx >= input.len) return null;
    if (input[idx] == '\'' or input[idx] == '"') {
        return extractQuotedUrlAtAlloc(allocator, input, idx);
    }
    var end = idx;
    while (end < input.len and !isMetaRefreshTerminator(input[end])) : (end += 1) {}
    if (end <= idx) return null;
    return try sanitizeRedirectTargetAlloc(allocator, input[idx..end]);
}

fn sanitizeRedirectTargetAlloc(allocator: std.mem.Allocator, raw: []const u8) ![]u8 {
    const trimmed = std.mem.trim(u8, raw, " \t\r\n");
    var out = try allocator.dupe(u8, trimmed);
    out = try replaceOwnedAlloc(allocator, out, "\\/", "/");
    out = try replaceOwnedAlloc(allocator, out, "\\u0026", "&");
    out = try replaceOwnedAlloc(allocator, out, "&amp;", "&");
    return out;
}

fn replaceOwnedAlloc(allocator: std.mem.Allocator, input: []u8, needle: []const u8, replacement: []const u8) ![]u8 {
    const replaced = try std.mem.replaceOwned(u8, allocator, input, needle, replacement);
    allocator.free(input);
    return replaced;
}

fn lowercasePrefixAlloc(allocator: std.mem.Allocator, input: []const u8, max_len: usize) ![]u8 {
    const head = input[0..@min(input.len, max_len)];
    const out = try allocator.dupe(u8, head);
    for (out) |*ch| {
        if (ch.* <= 0x7f) {
            ch.* = std.ascii.toLower(ch.*);
        }
    }
    return out;
}

fn isInlineSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn isMetaRefreshTerminator(ch: u8) bool {
    return isInlineSpace(ch) or ch == '"' or ch == '\'' or ch == '>' or ch == ';';
}

fn looksLikeClashYaml(input: []const u8) bool {
    const lower = lowercaseHeadAlloc(std.heap.page_allocator, input) catch return false;
    defer std.heap.page_allocator.free(lower);
    const has_proxies = std.mem.indexOf(u8, lower, "proxies:") != null or std.mem.indexOf(u8, lower, "\nproxies:") != null;
    if (!has_proxies) return false;
    return std.mem.indexOf(u8, lower, "proxy-groups:") != null or
        std.mem.indexOf(u8, lower, "\nproxy-groups:") != null or
        std.mem.indexOf(u8, lower, "rules:") != null or
        std.mem.indexOf(u8, lower, "\nrules:") != null or
        std.mem.indexOf(u8, lower, "rule:") != null or
        std.mem.indexOf(u8, lower, "\nrule:") != null or
        std.mem.indexOf(u8, lower, "type: vmess") != null or
        std.mem.indexOf(u8, lower, "type: trojan") != null or
        std.mem.indexOf(u8, lower, "type: ss") != null or
        std.mem.indexOf(u8, lower, "type: socks5") != null or
        std.mem.indexOf(u8, lower, "port:") != null or
        std.mem.indexOf(u8, lower, "socks-port:") != null or
        std.mem.indexOf(u8, lower, "redir-port:") != null or
        std.mem.indexOf(u8, lower, "external-controller:") != null;
}

fn looksLikeSsepEnvelope(allocator: std.mem.Allocator, input: []const u8) bool {
    if (!looksLikeJson(input)) return false;
    var parsed = std.json.parseFromSlice(std.json.Value, allocator, input, .{}) catch return false;
    defer parsed.deinit();
    if (parsed.value != .object) return false;
    const obj = parsed.value.object;
    return obj.contains("v") and obj.contains("alg") and (obj.contains("data") or obj.contains("payload")) and (obj.contains("req") or obj.contains("request"));
}

fn looksLikeJsonError(allocator: std.mem.Allocator, input: []const u8) bool {
    var parsed = std.json.parseFromSlice(std.json.Value, allocator, input, .{}) catch return false;
    defer parsed.deinit();
    if (parsed.value != .object) return false;
    const obj = parsed.value.object;
    if (obj.contains("error") or obj.contains("errors")) return true;
    if (obj.contains("msg") or obj.contains("message")) return true;
    if (obj.contains("status")) return true;
    if (obj.contains("code") and !obj.contains("proxies") and !obj.contains("outbounds")) return true;
    if (obj.get("success")) |value| {
        if (value == .bool and value.bool == false) return true;
    }
    return false;
}

fn looksLikeUriLines(input: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, input, "\r\n");
    var matched: usize = 0;
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        const scheme = detectScheme(line) orelse continue;
        if (isSupportedScheme(scheme)) matched += 1;
    }
    return matched > 0;
}

fn isSupportedScheme(scheme: []const u8) bool {
    return std.mem.eql(u8, scheme, "ss") or
        std.mem.eql(u8, scheme, "ssr") or
        std.mem.eql(u8, scheme, "vmess") or
        std.mem.eql(u8, scheme, "vless") or
        std.mem.eql(u8, scheme, "trojan") or
        std.mem.eql(u8, scheme, "naive+https") or
        std.mem.eql(u8, scheme, "naive+quic") or
        std.mem.eql(u8, scheme, "tuic") or
        std.mem.eql(u8, scheme, "hy2") or
        std.mem.eql(u8, scheme, "hysteria2");
}

fn looksLikeTextError(input: []const u8) bool {
    const lower = lowercaseHeadAlloc(std.heap.page_allocator, input) catch return false;
    defer std.heap.page_allocator.free(lower);
    return std.mem.indexOf(u8, lower, "error:") != null or
        std.mem.indexOf(u8, lower, "参数缺失") != null or
        std.mem.indexOf(u8, lower, "请重新获取订阅") != null or
        std.mem.indexOf(u8, lower, "nice try") != null or
        std.mem.indexOf(u8, lower, "can not find user") != null or
        std.mem.indexOf(u8, lower, "pass wrong") != null or
        std.mem.indexOf(u8, lower, "uncorrect token") != null or
        std.mem.indexOf(u8, lower, "incorrect token") != null or
        std.mem.indexOf(u8, lower, "invalid service") != null or
        std.mem.indexOf(u8, lower, "not active") != null or
        std.mem.indexOf(u8, lower, "link not found") != null or
        std.mem.indexOf(u8, lower, "obsolete") != null or
        std.mem.indexOf(u8, lower, "api url is obsolete") != null or
        std.mem.indexOf(u8, lower, "service is not under normal status") != null or
        std.mem.indexOf(u8, lower, "please submit ticket") != null or
        std.mem.indexOf(u8, lower, "产品状态异常") != null or
        std.mem.indexOf(u8, lower, "forbidden") != null or
        std.mem.indexOf(u8, lower, "access denied") != null or
        std.mem.indexOf(u8, lower, "denied") != null or
        std.mem.indexOf(u8, lower, "expired") != null;
}

fn maybeDecodeBase64Text(allocator: std.mem.Allocator, input: []const u8) !?[]u8 {
    if (!looksLikeBase64(input)) return null;
    return decodeBase64SmartAlloc(allocator, input) catch null;
}

fn maybeDecodeBase64Lossy(allocator: std.mem.Allocator, input: []const u8) !?[]u8 {
    if (!looksLikeBase64(input)) return null;
    return decodeBase64SmartAlloc(allocator, input) catch null;
}

fn looksLikeBase64(input: []const u8) bool {
    var useful: usize = 0;
    for (input) |ch| {
        if (ch == '\r' or ch == '\n' or ch == '\t' or ch == ' ') continue;
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or (ch >= '0' and ch <= '9') or ch == '+' or ch == '/' or ch == '=' or ch == '-' or ch == '_') {
            useful += 1;
            continue;
        }
        return false;
    }
    return useful > 0;
}

fn decodeBase64SmartAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const cleaned = try stripWhitespaceAlloc(allocator, input);
    defer allocator.free(cleaned);
    if (cleaned.len == 0) return error.InvalidBase64;

    if (std.mem.indexOfAny(u8, cleaned, "-_")) |_| {
        return decodeBase64Alloc(allocator, cleaned, true);
    }
    return decodeBase64Alloc(allocator, cleaned, false);
}

fn decodeBase64Alloc(allocator: std.mem.Allocator, input: []const u8, url_safe: bool) ![]u8 {
    const padded = try padBase64Alloc(allocator, input);
    defer allocator.free(padded);

    if (url_safe) {
        const converted = try allocator.dupe(u8, padded);
        defer allocator.free(converted);
        for (converted) |*ch| {
            if (ch.* == '-') ch.* = '+';
            if (ch.* == '_') ch.* = '/';
        }
        return decodeBase64StandardAlloc(allocator, converted);
    }
    return decodeBase64StandardAlloc(allocator, padded);
}

fn decodeBase64StandardAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const Decoder = std.base64.standard.Decoder;
    const size = try Decoder.calcSizeForSlice(input);
    const out = try allocator.alloc(u8, size);
    errdefer allocator.free(out);
    try Decoder.decode(out, input);
    return out;
}

fn padBase64Alloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const pad_len = (4 - (input.len % 4)) % 4;
    var out = try allocator.alloc(u8, input.len + pad_len);
    @memcpy(out[0..input.len], input);
    for (out[input.len..]) |*ch| ch.* = '=';
    return out;
}

fn stripWhitespaceAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var list = std.ArrayList(u8){};
    defer list.deinit(allocator);
    for (input) |ch| {
        if (ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n') continue;
        try list.append(allocator, ch);
    }
    return try list.toOwnedSlice(allocator);
}

fn urlDecodeAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var out = std.ArrayList(u8){};
    defer out.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '%' and i + 2 < input.len) {
            const hi = try hexNibble(input[i + 1]);
            const lo = try hexNibble(input[i + 2]);
            try out.append(allocator, (hi << 4) | lo);
            i += 3;
            continue;
        }
        try out.append(allocator, input[i]);
        i += 1;
    }
    return try out.toOwnedSlice(allocator);
}

fn hexNibble(ch: u8) !u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => error.InvalidPercentEncoding,
    };
}

fn queryValueAlloc(allocator: std.mem.Allocator, query: []const u8, key: []const u8) !?[]u8 {
    if (query.len == 0) return null;
    var parts = std.mem.splitScalar(u8, query, '&');
    while (parts.next()) |part| {
        if (part.len == 0) continue;
        const eq = std.mem.indexOfScalar(u8, part, '=') orelse {
            if (std.mem.eql(u8, part, key)) return try allocator.dupe(u8, "");
            continue;
        };
        if (!std.mem.eql(u8, part[0..eq], key)) continue;
        return try urlDecodeAlloc(allocator, part[eq + 1 ..]);
    }
    return null;
}

fn queryValueBorrowed(allocator: std.mem.Allocator, query: []const u8, key: []const u8) !?[]const u8 {
    if (try queryValueAlloc(allocator, query, key)) |value| return value;
    return null;
}

fn decodeOptionalB64QueryValue(allocator: std.mem.Allocator, query: []const u8, key: []const u8) !?[]u8 {
    const raw = try queryValueAlloc(allocator, query, key) orelse return null;
    defer allocator.free(raw);
    if (raw.len == 0) return null;
    return try decodeBase64SmartAlloc(allocator, raw);
}

fn queryBoolValue(query: []const u8, key: []const u8) !?bool {
    var buf_allocator = std.heap.page_allocator;
    const value = try queryValueAlloc(buf_allocator, query, key);
    defer if (value) |v| buf_allocator.free(v);
    if (value) |v| {
        const lowered = try asciiLowerAlloc(buf_allocator, v);
        defer buf_allocator.free(lowered);
        if (std.mem.eql(u8, lowered, "1") or std.mem.eql(u8, lowered, "true") or std.mem.eql(u8, lowered, "yes") or std.mem.eql(u8, lowered, "on")) return true;
        if (std.mem.eql(u8, lowered, "0") or std.mem.eql(u8, lowered, "false") or std.mem.eql(u8, lowered, "no") or std.mem.eql(u8, lowered, "off")) return false;
    }
    return null;
}

fn asciiLowerAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const out = try allocator.dupe(u8, input);
    for (out) |*ch| ch.* = std.ascii.toLower(ch.*);
    return out;
}

fn stringEqualsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |lhs, rhs| {
        if (std.ascii.toLower(lhs) != std.ascii.toLower(rhs)) return false;
    }
    return true;
}

fn extractPluginField(allocator: std.mem.Allocator, plugin: []const u8, key: []const u8) ?[]u8 {
    var parts = std.mem.splitScalar(u8, plugin, ';');
    _ = parts.next();
    while (parts.next()) |part| {
        const eq = std.mem.indexOfScalar(u8, part, '=') orelse continue;
        if (!std.mem.eql(u8, part[0..eq], key)) continue;
        return allocator.dupe(u8, part[eq + 1 ..]) catch null;
    }
    return null;
}

fn countUriSchemes(map: *std.StringHashMap(usize), content: []const u8) struct { total_lines: usize, scheme_total: usize } {
    var lines = std.mem.tokenizeAny(u8, content, "\r\n");
    var total: usize = 0;
    var scheme_total: usize = 0;
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        total += 1;
        const scheme = detectScheme(line) orelse continue;
        if (!isSupportedScheme(scheme)) continue;
        const entry = map.getOrPut(scheme) catch continue;
        if (!entry.found_existing) entry.value_ptr.* = 0;
        entry.value_ptr.* += 1;
        scheme_total += 1;
    }
    return .{ .total_lines = total, .scheme_total = scheme_total };
}

test "inspect base64 uri lines" {
    const allocator = std.testing.allocator;
    const src = "c3M6Ly9ZV1Z6TFRJMU5pMW5ZMjA2Y0dGemN6QkFaWGhoYlhCc1pTNWpiMjA2TkRReg09I05vZGU=\n";
    const info = try detectContentInfo(allocator, src);
    defer allocator.free(info.content);
    try std.testing.expectEqual(InputKind.base64_uri_lines, info.kind);
}

test "parse ss link" {
    const allocator = std.testing.allocator;
    const line = "ss://YWVzLTI1Ni1nY206cGFzczBAZXhhbXBsZS5jb206NDQz#Node";
    const node = try parseSs(allocator, line, .{ .command = .parse_uri_lines });
    try std.testing.expectEqualStrings("ss", node.scheme);
    try std.testing.expectEqualStrings("Node", node.name);
    try std.testing.expectEqualStrings("example.com", node.server);
    try std.testing.expectEqual(@as(u16, 443), node.port);
}

test "parse ss link with amp group" {
    const allocator = std.testing.allocator;
    const line = "ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTo3YTNhOGI5Mi1kNjY1LTQ3MmQtYWZjNy00Y2IyNzZhZTYxMjA@abb9f910fc9f4ababffb16db3cfd972e.ss03.net:22350&group=c3NMaW5rcw==#Expire%3A%202026-08-30";
    const node = parseSs(allocator, line, .{ .command = .parse_uri_lines }) catch |err| {
        std.debug.print("parse ss amp group err={s}\n", .{@errorName(err)});
        return err;
    };
    try std.testing.expectEqualStrings("ss", node.scheme);
    try std.testing.expectEqualStrings("Expire: 2026-08-30", node.name);
    try std.testing.expectEqualStrings("abb9f910fc9f4ababffb16db3cfd972e.ss03.net", node.server);
    try std.testing.expectEqual(@as(u16, 22350), node.port);
}

test "parse ss link with plugin query" {
    const allocator = std.testing.allocator;
    const line = "ss://YWVzLTEyOC1nY206N2EzYThiOTItZDY2NS00NzJkLWFmYzctNGNiMjc2YWU2MTIw@abb9f910fc9f4ababffb16db3cfd972e.ss03.net:22401/?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3Dltsbdy.gtimg.com&group=c3NMaW5rcw==#%F0%9F%87%AD%F0%9F%87%B0%20%E9%A6%99%E6%B8%AF%2001%20%5Bobfs%5D";
    const node = parseSs(allocator, line, .{ .command = .parse_uri_lines }) catch |err| {
        std.debug.print("parse ss plugin err={s}\n", .{@errorName(err)});
        return err;
    };
    try std.testing.expectEqualStrings("ss", node.scheme);
    try std.testing.expectEqualStrings("🇭🇰 香港 01 [obfs]", node.name);
    try std.testing.expectEqualStrings("abb9f910fc9f4ababffb16db3cfd972e.ss03.net", node.server);
    try std.testing.expectEqual(@as(u16, 22401), node.port);
}

test "parse vless link" {
    const allocator = std.testing.allocator;
    const line = "vless://11111111-1111-1111-1111-111111111111@example.com:443?type=ws&security=tls&host=cdn.example.com&path=%2Fws&sni=tls.example.com#VLESS";
    const node = try parseVlessLike(allocator, "vless", line, .{ .command = .parse_uri_lines });
    try std.testing.expectEqualStrings("vless", node.scheme);
    try std.testing.expectEqualStrings("VLESS", node.name);
    try std.testing.expectEqualStrings("example.com", node.server);
    try std.testing.expectEqual(@as(u16, 443), node.port);
}

test "parse vmess link" {
    const allocator = std.testing.allocator;
    const payload =
        "eyJ2IjoiMiIsInBzIjoiVk1FU1MiLCJhZGQiOiJleGFtcGxlLmNvbSIsInBvcnQiOiI0NDMiLCJpZCI6IjExMTExMTExLTExMTEtMTExMS0xMTExLTExMTExMTExMTExMSIsImFpZCI6IjAiLCJuZXQiOiJ3cyIsImhvc3QiOiJjZG4uZXhhbXBsZS5jb20iLCJwYXRoIjoiL3dzIiwidGxzIjoidGxzIn0=";
    const line = try std.fmt.allocPrint(allocator, "vmess://{s}", .{payload});
    defer allocator.free(line);
    const node = try parseVmess(allocator, line, .{ .command = .parse_uri_lines });
    try std.testing.expectEqualStrings("vmess", node.scheme);
    try std.testing.expectEqualStrings("VMESS", node.name);
    try std.testing.expectEqualStrings("example.com", node.server);
}

test "detect text error payloads" {
    try std.testing.expect(looksLikeTextError("pass wrong"));
    try std.testing.expect(looksLikeTextError("Unisset or Uncorrect Token"));
    try std.testing.expect(looksLikeTextError("INVALID SERVICE"));
    try std.testing.expect(looksLikeTextError("Not Active"));
    try std.testing.expect(looksLikeTextError("Link not found"));
    try std.testing.expect(looksLikeTextError("This API URL is obsolete and can no longer be used."));
    try std.testing.expect(looksLikeTextError("产品状态异常 !\n Your service is not under normal status, please submit ticket !"));
}

test "detect content info classifications" {
    const allocator = std.testing.allocator;
    {
        const info = try detectContentInfo(allocator, "pass wrong");
        defer allocator.free(info.content);
        try std.testing.expectEqual(InputKind.text_error, info.kind);
    }
    {
        const info = try detectContentInfo(allocator, "<!DOCTYPE html><html><title>Sign in ・ Cloudflare Access</title></html>");
        defer allocator.free(info.content);
        try std.testing.expectEqual(InputKind.html_login, info.kind);
    }
    {
        const info = try detectContentInfo(allocator, "<html><head><script>window.onload=function(){window.location.href=\"/lander?sub=1\"}</script></head></html>");
        defer allocator.free(info.content);
        try std.testing.expectEqual(InputKind.html_redirect, info.kind);
    }
    {
        const info = try detectContentInfo(allocator, "port: 7890\nsocks-port: 7891\nproxies:\n  - {name: test, type: vmess}");
        defer allocator.free(info.content);
        try std.testing.expectEqual(InputKind.clash_yaml, info.kind);
    }
}

test "detect clash style profile yaml" {
    const allocator = std.testing.allocator;
    const sample =
        "\xEF\xBB\xBFport: 7890\n" ++
        "socks-port: 7891\n" ++
        "redir-port: 7892\n" ++
        "allow-lan: false\n" ++
        "mode: rule\n" ++
        "log-level: info\n" ++
        "external-controller: '127.0.0.1:9090'\n" ++
        "secret: ''\n\n" ++
        "proxies:\n" ++
        "  - name: Shadowsocks\n" ++
        "    type: socks5\n" ++
        "    server: 127.0.0.1\n" ++
        "    port: 1080\n\n" ++
        "rule:\n" ++
        "  - 'MATCH,DIRECT'\n";
    try std.testing.expect(looksLikeClashYaml(trimBom(sample)));
    const info = try detectContentInfo(allocator, sample);
    defer allocator.free(info.content);
    try std.testing.expectEqual(InputKind.clash_yaml, info.kind);
}

test "extract html redirect target" {
    const allocator = std.testing.allocator;
    {
        const value = try extractHtmlRedirectTargetAlloc(allocator, "<html><script>window.location.replace('https://example.com/sub?token=1')</script></html>");
        defer if (value) |v| allocator.free(v);
        try std.testing.expectEqualStrings("https://example.com/sub?token=1", value.?);
    }
    {
        const value = try extractHtmlRedirectTargetAlloc(allocator, "<html><script>window.onload=function(){window.location.href=\"/lander?sub=3\"}</script></html>");
        defer if (value) |v| allocator.free(v);
        try std.testing.expectEqualStrings("/lander?sub=3", value.?);
    }
    {
        const value = try extractHtmlRedirectTargetAlloc(allocator, "<html><script>var redirect_link = 'https:\\/\\/bigairport.icu\\/api\\/v1\\/client\\/subscribe?token=1\\u0026js=2';</script></html>");
        defer if (value) |v| allocator.free(v);
        try std.testing.expectEqualStrings("https://bigairport.icu/api/v1/client/subscribe?token=1&js=2", value.?);
    }
}
