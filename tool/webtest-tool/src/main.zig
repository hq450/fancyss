const std = @import("std");
const build_options = @import("build_options");

const version = build_options.version;
const debug_log_path = "/tmp/webtest-tool.debug.log";

const ProbeError = error{
    UnsupportedScheme,
    MissingHost,
    InvalidProxy,
    InvalidPort,
    InvalidStatusLine,
    SocksVersion,
    SocksAuth,
    SocksConnect,
    HeaderTooLarge,
    UnexpectedEof,
    Timeout,
};

const ParsedUrl = struct {
    raw: []const u8,
    host: []const u8,
    port: u16,
    target: []const u8,
};

const ProxyEndpoint = struct {
    host: []const u8,
    port: u16,
};

const ProbeResult = struct {
    ok: bool,
    status_code: u16,
    elapsed_ms: u32,
    remote_addr: []const u8,
    err_text: []const u8,
};

const TargetConfig = struct {
    id: []u8,
    identity: []u8,
    group: []u8,
    test_port: u16,
    start_script: ?[]u8 = null,
    stop_script: ?[]u8 = null,
    wait_port: ?u16 = null,
    wait_timeout_ms: ?u32 = null,
};

const TargetResult = struct {
    id: []u8,
    identity: []u8,
    group: []u8,
    test_port: u16,
    state: []const u8,
    latency_ms: ?u32 = null,
    response_code: ?u16 = null,
    err_text: ?[]u8 = null,
    updated_at_ms: i64 = 0,
};

const GroupConfig = struct {
    name: []u8,
    concurrency: u16,
    start_index: usize,
    target_count: usize,
};

const WebtestConfig = struct {
    batch_id: []u8,
    url: []u8,
    timeout_ms: u32,
    warmup: u8,
    attempts: u8,
    concurrency: u16,
    output_json: []u8,
    output_stream: []u8,
    legacy_result_file: ?[]u8 = null,
    legacy_stream_file: ?[]u8 = null,
    legacy_emit_stop: bool = true,
    runtime_root: ?[]u8 = null,
    groups: []GroupConfig,
    targets: []TargetConfig,
};

const Phase = enum {
    idle,
    ready,
    running,
    stopping,
    done,
    failed,
};

const State = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    phase: Phase = .idle,
    stop_requested: bool = false,
    worker_active: bool = false,
    last_error: ?[]u8 = null,
    config: ?WebtestConfig = null,
    results: []TargetResult = &.{},

    fn clear(self: *State) void {
        if (self.config) |cfg| {
            self.allocator.free(cfg.batch_id);
            self.allocator.free(cfg.url);
            self.allocator.free(cfg.output_json);
            self.allocator.free(cfg.output_stream);
            if (cfg.legacy_result_file) |path| self.allocator.free(path);
            if (cfg.legacy_stream_file) |path| self.allocator.free(path);
            if (cfg.runtime_root) |path| self.allocator.free(path);
            for (cfg.groups) |g| {
                self.allocator.free(g.name);
            }
            if (cfg.groups.len != 0) self.allocator.free(cfg.groups);
            for (cfg.targets) |t| {
                self.allocator.free(t.id);
                self.allocator.free(t.identity);
                self.allocator.free(t.group);
                if (t.start_script) |path| self.allocator.free(path);
                if (t.stop_script) |path| self.allocator.free(path);
            }
            self.allocator.free(cfg.targets);
            self.config = null;
        }
        for (self.results) |r| {
            self.allocator.free(r.id);
            self.allocator.free(r.identity);
            self.allocator.free(r.group);
            if (r.err_text) |msg| self.allocator.free(msg);
        }
        if (self.results.len != 0) self.allocator.free(self.results);
        self.results = &.{};
        if (self.last_error) |msg| {
            self.allocator.free(msg);
            self.last_error = null;
        }
        self.phase = .idle;
        self.stop_requested = false;
        self.worker_active = false;
    }
};

fn printUsage() void {
    std.debug.print(
        \\webtest-tool {s}
        \\
        \\Usage:
        \\  webtest-tool webtestd [--socket-path <path>]
        \\  webtest-tool run --config <path>
        \\  webtest-tool --help
        \\  webtest-tool --version
        \\
    , .{version});
}

fn debugLog(comptime fmt: []const u8, args: anytype) void {
    var file = std.fs.cwd().createFile(debug_log_path, .{ .truncate = false }) catch return;
    defer file.close();
    file.seekFromEnd(0) catch return;
    var buf: [512]u8 = undefined;
    var writer = file.writer(&buf);
    writer.interface.print(fmt ++ "\n", args) catch return;
    writer.interface.flush() catch return;
}

fn parseHttpUrl(arena: std.mem.Allocator, raw_url: []const u8) !ParsedUrl {
    const uri = try std.Uri.parse(raw_url);
    if (!std.mem.eql(u8, uri.scheme, "http")) return ProbeError.UnsupportedScheme;
    const host = try uri.getHostAlloc(arena);
    if (host.len == 0) return ProbeError.MissingHost;

    var target: std.ArrayList(u8) = .empty;
    defer target.deinit(arena);

    const path_text = switch (uri.path) {
        .raw => |v| v,
        .percent_encoded => |v| v,
    };
    if (path_text.len == 0) {
        try target.append(arena, '/');
    } else {
        try target.appendSlice(arena, path_text);
    }
    if (uri.query) |query| {
        try target.append(arena, '?');
        switch (query) {
            .raw => |v| try target.appendSlice(arena, v),
            .percent_encoded => |v| try target.appendSlice(arena, v),
        }
    }

    return .{
        .raw = raw_url,
        .host = host,
        .port = uri.port orelse 80,
        .target = try arena.dupe(u8, target.items),
    };
}

fn parseProxyEndpoint(proxy_text: []const u8) !ProxyEndpoint {
    const prefix = "socks5://127.0.0.1:";
    if (!std.mem.startsWith(u8, proxy_text, prefix)) return ProbeError.InvalidProxy;
    return .{
        .host = "127.0.0.1",
        .port = try std.fmt.parseInt(u16, proxy_text[prefix.len..], 10),
    };
}

fn waitReadable(stream: std.net.Stream, timeout_ms: u32) !void {
    var pfd = [_]std.posix.pollfd{.{
        .fd = stream.handle,
        .events = std.posix.POLL.IN,
        .revents = 0,
    }};
    const rc = try std.posix.poll(&pfd, @intCast(timeout_ms));
    if (rc == 0) return ProbeError.Timeout;
}

fn writeAll(stream: std.net.Stream, bytes: []const u8) !void {
    var sent: usize = 0;
    while (sent < bytes.len) {
        const n = try stream.write(bytes[sent..]);
        if (n == 0) return error.WriteFailed;
        sent += n;
    }
}

fn readExactTimeout(stream: std.net.Stream, buf: []u8, timeout_ms: u32) !void {
    var offset: usize = 0;
    while (offset < buf.len) {
        try waitReadable(stream, timeout_ms);
        const n = try stream.read(buf[offset..]);
        if (n == 0) return ProbeError.UnexpectedEof;
        offset += n;
    }
}

fn openProxyStream(proxy: ProxyEndpoint) !std.net.Stream {
    const addr = try std.net.Address.parseIp4(proxy.host, proxy.port);
    return std.net.tcpConnectToAddress(addr);
}

fn openSocks5Stream(allocator: std.mem.Allocator, parsed: ParsedUrl, proxy_text: []const u8, timeout_ms: u32) !struct {
    stream: std.net.Stream,
    remote_addr: []const u8,
} {
    const proxy = try parseProxyEndpoint(proxy_text);
    var stream = try openProxyStream(proxy);
    errdefer stream.close();

    try writeAll(stream, &[_]u8{ 0x05, 0x01, 0x00 });
    var greeting: [2]u8 = undefined;
    try readExactTimeout(stream, &greeting, timeout_ms);
    if (greeting[0] != 0x05) return ProbeError.SocksVersion;
    if (greeting[1] != 0x00) return ProbeError.SocksAuth;

    if (parsed.host.len > 255) return ProbeError.InvalidProxy;
    var request: std.ArrayList(u8) = .empty;
    defer request.deinit(allocator);
    try request.appendSlice(allocator, &[_]u8{ 0x05, 0x01, 0x00, 0x03, @intCast(parsed.host.len) });
    try request.appendSlice(allocator, parsed.host);
    try request.append(allocator, @intCast((parsed.port >> 8) & 0xff));
    try request.append(allocator, @intCast(parsed.port & 0xff));
    try writeAll(stream, request.items);

    var header: [4]u8 = undefined;
    try readExactTimeout(stream, &header, timeout_ms);
    if (header[0] != 0x05) return ProbeError.SocksVersion;
    if (header[1] != 0x00) return ProbeError.SocksConnect;

    switch (header[3]) {
        0x01 => {
            var skip: [6]u8 = undefined;
            try readExactTimeout(stream, &skip, timeout_ms);
        },
        0x03 => {
            var size_buf: [1]u8 = undefined;
            try readExactTimeout(stream, &size_buf, timeout_ms);
            const host_len = size_buf[0];
            const skip = try allocator.alloc(u8, host_len + 2);
            defer allocator.free(skip);
            try readExactTimeout(stream, skip, timeout_ms);
        },
        0x04 => {
            var skip: [18]u8 = undefined;
            try readExactTimeout(stream, &skip, timeout_ms);
        },
        else => return ProbeError.SocksConnect,
    }

    return .{
        .stream = stream,
        .remote_addr = try std.fmt.allocPrint(allocator, "{s}:{d}", .{ proxy.host, proxy.port }),
    };
}

fn readHttpResponseHead(allocator: std.mem.Allocator, stream: std.net.Stream, timeout_ms: u32) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(allocator);
    var temp: [1024]u8 = undefined;
    while (buf.items.len < 16 * 1024) {
        try waitReadable(stream, timeout_ms);
        const n = try stream.read(&temp);
        if (n == 0) break;
        try buf.appendSlice(allocator, temp[0..n]);
        if (std.mem.indexOf(u8, buf.items, "\r\n\r\n") != null) break;
    }
    if (std.mem.indexOf(u8, buf.items, "\r\n\r\n") == null) return ProbeError.HeaderTooLarge;
    return try buf.toOwnedSlice(allocator);
}

fn parseStatusCode(head: []const u8) !u16 {
    const line_end = std.mem.indexOf(u8, head, "\r\n") orelse return ProbeError.InvalidStatusLine;
    const line = head[0..line_end];
    var iter = std.mem.splitScalar(u8, line, ' ');
    _ = iter.next() orelse return ProbeError.InvalidStatusLine;
    const code_text = iter.next() orelse return ProbeError.InvalidStatusLine;
    return try std.fmt.parseInt(u16, code_text, 10);
}

fn probePort(allocator: std.mem.Allocator, url: []const u8, test_port: u16, timeout_ms: u32, warmup: u8, attempts: u8) !ProbeResult {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try parseHttpUrl(arena, url);
    const effective_attempts: u8 = if (attempts == 0) 1 else attempts;
    const total_rounds: usize = @as(usize, warmup) + @as(usize, effective_attempts);
    var best_ms: ?u32 = null;
    var best_code: u16 = 0;
    var last_err: ?[]const u8 = null;

    var round: usize = 0;
    while (round < total_rounds) : (round += 1) {
        var timer = try std.time.Timer.start();
        const opened = openSocks5Stream(allocator, parsed, try std.fmt.allocPrint(arena, "socks5://127.0.0.1:{d}", .{test_port}), timeout_ms) catch |err| {
            last_err = @errorName(err);
            continue;
        };
        defer opened.stream.close();

        const req = try std.fmt.allocPrint(arena,
            "HEAD {s} HTTP/1.1\r\nHost: {s}\r\nUser-Agent: webtest-tool/{s}\r\nConnection: close\r\nAccept: */*\r\n\r\n",
            .{ parsed.target, parsed.host, version },
        );
        writeAll(opened.stream, req) catch |err| {
            last_err = @errorName(err);
            continue;
        };
        const head = readHttpResponseHead(arena, opened.stream, timeout_ms) catch |err| {
            last_err = @errorName(err);
            continue;
        };
        const code = parseStatusCode(head) catch |err| {
            last_err = @errorName(err);
            continue;
        };
        const elapsed_ms: u32 = @intCast(@min(timer.read() / std.time.ns_per_ms, std.math.maxInt(u32)));

        if (round < warmup) continue;
        if (code >= 200 and code < 400) {
            if (best_ms == null or elapsed_ms < best_ms.?) {
                best_ms = elapsed_ms;
                best_code = code;
            }
        } else {
            last_err = "bad-status";
        }
    }

    if (best_ms) |ms| {
        return .{
            .ok = true,
            .status_code = best_code,
            .elapsed_ms = ms,
            .remote_addr = try std.fmt.allocPrint(allocator, "127.0.0.1:{d}", .{test_port}),
            .err_text = try allocator.dupe(u8, "ok"),
        };
    }

    return .{
        .ok = false,
        .status_code = 0,
        .elapsed_ms = 0,
        .remote_addr = try std.fmt.allocPrint(allocator, "127.0.0.1:{d}", .{test_port}),
        .err_text = try allocator.dupe(u8, last_err orelse "failed"),
    };
}

fn parseU32(text: []const u8) !u32 {
    return try std.fmt.parseInt(u32, text, 10);
}

fn parseU8(text: []const u8) !u8 {
    return try std.fmt.parseInt(u8, text, 10);
}

fn parseOptionalString(allocator: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8) !?[]u8 {
    if (obj.get(key)) |value| {
        return switch (value) {
            .null => null,
            .string => |v| try allocator.dupe(u8, v),
            else => return error.InvalidConfig,
        };
    }
    return null;
}

fn parseOptionalU16(obj: std.json.ObjectMap, key: []const u8) !?u16 {
    if (obj.get(key)) |value| {
        return switch (value) {
            .null => null,
            .integer => |v| @as(u16, @intCast(v)),
            .number_string => |v| @as(u16, @intCast(try parseU32(v))),
            else => return error.InvalidConfig,
        };
    }
    return null;
}

fn parseOptionalU32(obj: std.json.ObjectMap, key: []const u8) !?u32 {
    if (obj.get(key)) |value| {
        return switch (value) {
            .null => null,
            .integer => |v| @as(u32, @intCast(v)),
            .number_string => |v| try parseU32(v),
            else => return error.InvalidConfig,
        };
    }
    return null;
}

fn parseBoolish(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |v| v,
        .integer => |v| v != 0,
        .number_string => |v| {
            if (std.mem.eql(u8, v, "0")) return false;
            if (std.mem.eql(u8, v, "1")) return true;
            return error.InvalidConfig;
        },
        .string => |v| {
            if (std.ascii.eqlIgnoreCase(v, "true")) return true;
            if (std.ascii.eqlIgnoreCase(v, "false")) return false;
            if (std.mem.eql(u8, v, "0")) return false;
            if (std.mem.eql(u8, v, "1")) return true;
            return error.InvalidConfig;
        },
        else => return error.InvalidConfig,
    };
}

fn nowMs() i64 {
    return std.time.milliTimestamp();
}

fn runShellScript(allocator: std.mem.Allocator, script_path: []const u8, runtime_root: ?[]const u8) bool {
    if (script_path.len == 0) return true;
    debugLog("runShellScript path={s} runtime_root={s}", .{ script_path, runtime_root orelse "" });
    const argv = [_][]const u8{ "/bin/sh", script_path };
    var child = std.process.Child.init(&argv, allocator);
    if (runtime_root) |root| {
        var env_map = std.process.EnvMap.init(allocator);
        defer env_map.deinit();
        env_map.put("WT_RUNTIME_ROOT", root) catch return false;
        child.env_map = &env_map;
        const term = child.spawnAndWait() catch |err| {
            debugLog("runShellScript spawn err={s}", .{@errorName(err)});
            return false;
        };
        debugLog("runShellScript done with env", .{});
        return switch (term) {
            .Exited => |code| code == 0,
            else => false,
        };
    }
    const term = child.spawnAndWait() catch |err| {
        debugLog("runShellScript spawn err={s}", .{@errorName(err)});
        return false;
    };
    debugLog("runShellScript done", .{});
    return switch (term) {
        .Exited => |code| code == 0,
        else => false,
    };
}

fn isLocalPortOpen(port: u16) bool {
    const addr = std.net.Address.parseIp4("127.0.0.1", port) catch return false;
    var stream = std.net.tcpConnectToAddress(addr) catch return false;
    stream.close();
    return true;
}

fn waitLocalPortOpen(port: u16, timeout_ms: u32) bool {
    const interval_ms: u32 = 100;
    var waited_ms: u32 = 0;
    while (true) {
        if (isLocalPortOpen(port)) return true;
        if (waited_ms >= timeout_ms) return false;
        std.Thread.sleep(@as(u64, interval_ms) * std.time.ns_per_ms);
        waited_ms = @min(timeout_ms, waited_ms + interval_ms);
    }
}

fn readFileAllocCompat(allocator: std.mem.Allocator, path: []const u8, max_bytes: usize) ![]u8 {
    var file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    var list: std.ArrayList(u8) = .empty;
    errdefer list.deinit(allocator);

    var buf: [4096]u8 = undefined;
    while (true) {
        const n = try file.read(&buf);
        if (n == 0) break;
        if (list.items.len + n > max_bytes) return error.FileTooBig;
        try list.appendSlice(allocator, buf[0..n]);
    }
    return try list.toOwnedSlice(allocator);
}

fn parseConfigFile(allocator: std.mem.Allocator, path: []const u8) !WebtestConfig {
    debugLog("parseConfigFile path={s}", .{path});
    const bytes = try readFileAllocCompat(allocator, path, 1024 * 1024);
    debugLog("parseConfigFile read bytes={d}", .{bytes.len});
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, bytes, .{});
    debugLog("parseConfigFile json parsed", .{});
    const root = parsed.value;
    if (root != .object) return error.InvalidConfig;
    const obj = root.object;

    const batch_id = switch (obj.get("batch_id") orelse return error.InvalidConfig) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    };
    const url = switch (obj.get("url") orelse return error.InvalidConfig) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    };
    const output_json = switch (obj.get("output_json") orelse return error.InvalidConfig) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    };
    const output_stream = switch (obj.get("output_stream") orelse return error.InvalidConfig) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    };
    const legacy_result_file = if (obj.get("legacy_result_file")) |value| switch (value) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    } else null;
    const legacy_stream_file = if (obj.get("legacy_stream_file")) |value| switch (value) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    } else null;
    const legacy_emit_stop = if (obj.get("legacy_emit_stop")) |value|
        try parseBoolish(value)
    else
        true;
    const runtime_root = if (obj.get("runtime_root")) |value| switch (value) {
        .null => null,
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    } else null;
    const timeout_ms = switch (obj.get("timeout_ms") orelse return error.InvalidConfig) {
        .integer => |v| @as(u32, @intCast(v)),
        .number_string => |v| try parseU32(v),
        else => return error.InvalidConfig,
    };
    const warmup = switch (obj.get("warmup") orelse return error.InvalidConfig) {
        .integer => |v| @as(u8, @intCast(v)),
        .number_string => |v| try parseU8(v),
        else => return error.InvalidConfig,
    };
    const attempts = switch (obj.get("attempts") orelse return error.InvalidConfig) {
        .integer => |v| @as(u8, @intCast(v)),
        .number_string => |v| try parseU8(v),
        else => return error.InvalidConfig,
    };
    const concurrency = switch (obj.get("concurrency") orelse return error.InvalidConfig) {
        .integer => |v| @as(u16, @intCast(v)),
        .number_string => |v| @as(u16, @intCast(try parseU32(v))),
        else => return error.InvalidConfig,
    };

    const ParsedPlan = try parseTargetsPlan(allocator, obj, concurrency);

    return .{
        .batch_id = batch_id,
        .url = url,
        .timeout_ms = timeout_ms,
        .warmup = warmup,
        .attempts = attempts,
        .concurrency = concurrency,
        .output_json = output_json,
        .output_stream = output_stream,
        .legacy_result_file = legacy_result_file,
        .legacy_stream_file = legacy_stream_file,
        .legacy_emit_stop = legacy_emit_stop,
        .runtime_root = runtime_root,
        .groups = ParsedPlan.groups,
        .targets = ParsedPlan.targets,
    };
}

const ParsedTargetsPlan = struct {
    groups: []GroupConfig,
    targets: []TargetConfig,
};

fn parseTargetConfig(allocator: std.mem.Allocator, item: std.json.Value, group_name: []const u8) !TargetConfig {
    if (item != .object) return error.InvalidConfig;
    const tobj = item.object;
    const identity = if (tobj.get("identity")) |value| switch (value) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    } else switch (tobj.get("id") orelse return error.InvalidConfig) {
        .string => |v| try allocator.dupe(u8, v),
        else => return error.InvalidConfig,
    };
    return .{
        .id = switch (tobj.get("id") orelse return error.InvalidConfig) {
            .string => |v| try allocator.dupe(u8, v),
            else => return error.InvalidConfig,
        },
        .identity = identity,
        .group = try allocator.dupe(u8, group_name),
        .test_port = switch (tobj.get("test_port") orelse return error.InvalidConfig) {
            .integer => |v| @as(u16, @intCast(v)),
            .number_string => |v| @as(u16, @intCast(try parseU32(v))),
            else => return error.InvalidConfig,
        },
        .start_script = try parseOptionalString(allocator, tobj, "start_script"),
        .stop_script = try parseOptionalString(allocator, tobj, "stop_script"),
        .wait_port = try parseOptionalU16(tobj, "wait_port"),
        .wait_timeout_ms = try parseOptionalU32(tobj, "wait_timeout_ms"),
    };
}

fn parseTargetsPlan(allocator: std.mem.Allocator, obj: std.json.ObjectMap, default_concurrency: u16) !ParsedTargetsPlan {
    if (obj.get("groups")) |groups_val| {
        if (groups_val != .array) return error.InvalidConfig;
        if (groups_val.array.items.len == 0) return error.InvalidConfig;
        var total_targets: usize = 0;
        for (groups_val.array.items) |group_item| {
            if (group_item != .object) return error.InvalidConfig;
            const gobj = group_item.object;
            const targets_val = gobj.get("targets") orelse return error.InvalidConfig;
            if (targets_val != .array) return error.InvalidConfig;
            total_targets += targets_val.array.items.len;
        }

        const groups = try allocator.alloc(GroupConfig, groups_val.array.items.len);
        const targets = try allocator.alloc(TargetConfig, total_targets);
        var target_index: usize = 0;
        for (groups_val.array.items, 0..) |group_item, group_idx| {
            const gobj = group_item.object;
            const raw_name = switch (gobj.get("name") orelse return error.InvalidConfig) {
                .string => |v| v,
                else => return error.InvalidConfig,
            };
            const group_concurrency = (try parseOptionalU16(gobj, "concurrency")) orelse default_concurrency;
            const targets_val = gobj.get("targets") orelse return error.InvalidConfig;
            groups[group_idx] = .{
                .name = try allocator.dupe(u8, raw_name),
                .concurrency = if (group_concurrency == 0) 1 else group_concurrency,
                .start_index = target_index,
                .target_count = targets_val.array.items.len,
            };
            for (targets_val.array.items) |target_item| {
                targets[target_index] = try parseTargetConfig(allocator, target_item, raw_name);
                target_index += 1;
            }
        }
        return .{ .groups = groups, .targets = targets };
    }

    const targets_val = obj.get("targets") orelse return error.InvalidConfig;
    if (targets_val != .array) return error.InvalidConfig;
    const groups = try allocator.alloc(GroupConfig, 1);
    groups[0] = .{
        .name = try allocator.dupe(u8, "default"),
        .concurrency = if (default_concurrency == 0) 1 else default_concurrency,
        .start_index = 0,
        .target_count = targets_val.array.items.len,
    };
    const targets = try allocator.alloc(TargetConfig, targets_val.array.items.len);
    for (targets_val.array.items, 0..) |item, idx| {
        targets[idx] = try parseTargetConfig(allocator, item, "default");
    }
    return .{ .groups = groups, .targets = targets };
}

fn appendJsonlLine(path: []const u8, line: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{ .truncate = false });
    defer file.close();
    try file.seekFromEnd(0);
    try file.writeAll(line);
    try file.writeAll("\n");
}

fn writeTextFile(path: []const u8, bytes: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(bytes);
}

fn writeSnapshot(state: *State) !void {
    debugLog("writeSnapshot enter", .{});
    state.mutex.lock();
    defer state.mutex.unlock();
    const cfg = state.config orelse return;

    var arena_state = std.heap.ArenaAllocator.init(state.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const Snapshot = struct {
        batch_id: []const u8,
        url: []const u8,
        phase: []const u8,
        updated_at_ms: i64,
        concurrency: u16,
        timeout_ms: u32,
        warmup: u8,
        attempts: u8,
        groups: []const GroupConfig,
        results: []const TargetResult,
    };

    var writer: std.Io.Writer.Allocating = .init(arena);
    defer writer.deinit();
    try std.json.Stringify.value(Snapshot{
        .batch_id = cfg.batch_id,
        .url = cfg.url,
        .phase = @tagName(state.phase),
        .updated_at_ms = nowMs(),
        .concurrency = cfg.concurrency,
        .timeout_ms = cfg.timeout_ms,
        .warmup = cfg.warmup,
        .attempts = cfg.attempts,
        .groups = cfg.groups,
        .results = state.results,
    }, .{ .whitespace = .indent_2 }, &writer.writer);
    try writer.writer.writeByte('\n');
    try writeTextFile(cfg.output_json, writer.written());
    debugLog("writeSnapshot ok", .{});
}

fn appendEvent(state: *State, line: []const u8) void {
    state.mutex.lock();
    defer state.mutex.unlock();
    const cfg = state.config orelse return;
    appendJsonlLine(cfg.output_stream, line) catch {};
}

fn appendLegacyLine(state: *State, line: []const u8) void {
    state.mutex.lock();
    defer state.mutex.unlock();
    const cfg = state.config orelse return;
    if (cfg.legacy_result_file) |path| appendJsonlLine(path, line) catch {};
    if (cfg.legacy_stream_file) |path| appendJsonlLine(path, line) catch {};
}

fn emitTestingState(state: *State, result: *TargetResult) void {
    var arena_state = std.heap.ArenaAllocator.init(state.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var event_writer: std.Io.Writer.Allocating = .init(arena);
    defer event_writer.deinit();
    std.json.Stringify.value(.{
        .type = "state",
        .group = result.group,
        .id = result.id,
        .identity = result.identity,
        .test_port = result.test_port,
        .state = result.state,
        .updated_at_ms = result.updated_at_ms,
    }, .{}, &event_writer.writer) catch {};
    appendEvent(state, event_writer.written());

    const line = std.fmt.allocPrint(arena, "{s}>testing...", .{result.id}) catch "";
    if (line.len != 0) appendLegacyLine(state, line);
}

fn emitFinalResult(state: *State, result: *TargetResult) void {
    var arena_state = std.heap.ArenaAllocator.init(state.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var event_writer: std.Io.Writer.Allocating = .init(arena);
    defer event_writer.deinit();
    std.json.Stringify.value(.{
        .type = "result",
        .group = result.group,
        .id = result.id,
        .identity = result.identity,
        .test_port = result.test_port,
        .state = result.state,
        .latency_ms = result.latency_ms,
        .response_code = result.response_code,
        .updated_at_ms = result.updated_at_ms,
    }, .{}, &event_writer.writer) catch {};
    appendEvent(state, event_writer.written());

    if (std.mem.eql(u8, result.state, "ok") and result.latency_ms != null) {
        const line = std.fmt.allocPrint(arena, "{s}>{d}", .{ result.id, result.latency_ms.? }) catch "";
        if (line.len != 0) appendLegacyLine(state, line);
    } else if (std.mem.eql(u8, result.state, "timeout")) {
        const line = std.fmt.allocPrint(arena, "{s}>timeout", .{result.id}) catch "";
        if (line.len != 0) appendLegacyLine(state, line);
    } else if (std.mem.eql(u8, result.state, "stopped")) {
        const line = std.fmt.allocPrint(arena, "{s}>stopped", .{result.id}) catch "";
        if (line.len != 0) appendLegacyLine(state, line);
    } else {
        const line = std.fmt.allocPrint(arena, "{s}>failed", .{result.id}) catch "";
        if (line.len != 0) appendLegacyLine(state, line);
    }
}

fn processTarget(state: *State, idx: usize) void {
    state.mutex.lock();
    const cfg = state.config orelse {
        state.mutex.unlock();
        return;
    };
    const target = cfg.targets[idx];
    const stop_now = state.stop_requested;
    var result = &state.results[idx];
    if (stop_now) {
        result.state = "stopped";
        result.updated_at_ms = nowMs();
        state.mutex.unlock();
        emitFinalResult(state, result);
        writeSnapshot(state) catch {};
        return;
    }
    state.mutex.unlock();

    if (target.start_script) |start_script| {
        debugLog("target {s} start hook begin wait_port={d}", .{ result.id, target.wait_port orelse 0 });
        if (!runShellScript(state.allocator, start_script, cfg.runtime_root)) {
            state.mutex.lock();
            result = &state.results[idx];
            result.state = "failed";
            result.updated_at_ms = nowMs();
            result.latency_ms = null;
            result.response_code = null;
            if (result.err_text) |msg| state.allocator.free(msg);
            result.err_text = state.allocator.dupe(u8, "HookStartFailed") catch null;
            state.mutex.unlock();
            emitFinalResult(state, result);
            writeSnapshot(state) catch {};
            return;
        }
        if (target.wait_port) |wait_port| {
            const wait_timeout_ms = target.wait_timeout_ms orelse 5000;
            debugLog("target {s} waiting port {d} timeout={d}", .{ result.id, wait_port, wait_timeout_ms });
            if (!waitLocalPortOpen(wait_port, wait_timeout_ms)) {
                debugLog("target {s} wait port timeout", .{result.id});
                if (target.stop_script) |stop_script| {
                    _ = runShellScript(state.allocator, stop_script, cfg.runtime_root);
                }
                state.mutex.lock();
                result = &state.results[idx];
                result.state = "failed";
                result.updated_at_ms = nowMs();
                result.latency_ms = null;
                result.response_code = null;
                if (result.err_text) |msg| state.allocator.free(msg);
                result.err_text = state.allocator.dupe(u8, "HookWaitTimeout") catch null;
                state.mutex.unlock();
                emitFinalResult(state, result);
                writeSnapshot(state) catch {};
                return;
            }
            debugLog("target {s} wait port ready", .{result.id});
        }
    }

    state.mutex.lock();
    result = &state.results[idx];
    result.state = "testing";
    result.updated_at_ms = nowMs();
    state.mutex.unlock();
    emitTestingState(state, result);
    writeSnapshot(state) catch {};
    debugLog("probe start port={d}", .{cfg.targets[idx].test_port});

    var arena_state = std.heap.ArenaAllocator.init(state.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const probe = probePort(arena, cfg.url, cfg.targets[idx].test_port, cfg.timeout_ms, cfg.warmup, cfg.attempts) catch |err| blk: {
        state.mutex.lock();
        result = &state.results[idx];
        result.state = if (err == ProbeError.Timeout) "timeout" else "failed";
        result.updated_at_ms = nowMs();
        result.latency_ms = null;
        result.response_code = null;
        if (result.err_text) |msg| state.allocator.free(msg);
        result.err_text = state.allocator.dupe(u8, @errorName(err)) catch null;
        state.mutex.unlock();
        debugLog("probe fail {s}", .{@errorName(err)});
        break :blk null;
    };

    if (probe) |ok_probe| {
        state.mutex.lock();
        result = &state.results[idx];
        if (ok_probe.ok) {
            result.state = "ok";
            result.latency_ms = ok_probe.elapsed_ms;
            result.response_code = ok_probe.status_code;
        } else {
            result.state = if (std.mem.eql(u8, ok_probe.err_text, "Timeout")) "timeout" else "failed";
            result.latency_ms = null;
            result.response_code = null;
        }
        if (result.err_text) |msg| state.allocator.free(msg);
        result.err_text = state.allocator.dupe(u8, ok_probe.err_text) catch null;
        result.updated_at_ms = nowMs();
        state.mutex.unlock();
        debugLog("probe done state={s}", .{result.state});
    }

    if (target.stop_script) |stop_script| {
        _ = runShellScript(state.allocator, stop_script, cfg.runtime_root);
    }

    emitFinalResult(state, &state.results[idx]);
    writeSnapshot(state) catch {};
}

fn workerThread(state: *State, next_index: *std.atomic.Value(usize), start_index: usize, end_index: usize) void {
    while (true) {
        const offset = next_index.fetchAdd(1, .monotonic);
        const idx = start_index + offset;
        if (idx >= end_index) break;
        processTarget(state, idx);
    }
}

fn runGroupWorkers(state: *State, group: GroupConfig) void {
    if (group.target_count == 0) return;
    const start_index = group.start_index;
    const end_index = group.start_index + group.target_count;
    const configured_concurrency = if (group.concurrency == 0) 1 else group.concurrency;
    const worker_count: usize = @min(@as(usize, configured_concurrency), group.target_count);
    var next_index: std.atomic.Value(usize) = .init(0);
    var threads = state.allocator.alloc(std.Thread, worker_count) catch {
        state.mutex.lock();
        state.phase = .failed;
        state.worker_active = false;
        state.mutex.unlock();
        return;
    };
    defer state.allocator.free(threads);

    for (threads, 0..) |*thread, idx| {
        thread.* = std.Thread.spawn(.{}, workerThread, .{ state, &next_index, start_index, end_index }) catch {
            for (threads[0..idx]) |started| started.join();
            state.mutex.lock();
            state.phase = .failed;
            state.worker_active = false;
            state.mutex.unlock();
            return;
        };
    }

    for (threads) |thread| {
        thread.join();
    }
}

fn workerMain(state: *State) void {
    debugLog("worker start", .{});
    state.mutex.lock();
    const cfg = state.config orelse {
        state.worker_active = false;
        state.phase = .failed;
        state.mutex.unlock();
        return;
    };
    state.phase = .running;
    state.stop_requested = false;
    state.worker_active = true;
    state.mutex.unlock();

    writeSnapshot(state) catch {};

    for (cfg.groups) |group| {
        state.mutex.lock();
        const stop_now = state.stop_requested or state.phase == .failed;
        state.mutex.unlock();
        if (stop_now) break;
        debugLog("group start name={s} concurrency={d} targets={d}", .{ group.name, group.concurrency, group.target_count });
        runGroupWorkers(state, group);
        debugLog("group done name={s}", .{group.name});
    }

    state.mutex.lock();
    state.phase = if (state.stop_requested) .stopping else .done;
    state.worker_active = false;
    state.mutex.unlock();
    writeSnapshot(state) catch {};
    debugLog("worker done phase={s}", .{@tagName(state.phase)});
    if (cfg.legacy_emit_stop) {
        appendLegacyLine(state, "stop>stop");
    }

    var done_arena_state = std.heap.ArenaAllocator.init(state.allocator);
    defer done_arena_state.deinit();
    var event_writer: std.Io.Writer.Allocating = .init(done_arena_state.allocator());
    defer event_writer.deinit();
    std.json.Stringify.value(.{
        .type = "done",
        .phase = @tagName(state.phase),
        .updated_at_ms = nowMs(),
    }, .{}, &event_writer.writer) catch {};
    appendEvent(state, event_writer.written());
}

fn runBatchOnce(allocator: std.mem.Allocator, config_path: []const u8) !void {
    debugLog("runBatchOnce config={s}", .{config_path});
    var state = State{ .allocator = allocator };
    defer state.clear();

    state.config = try parseConfigFile(state.allocator, config_path);
    debugLog("parseConfig ok", .{});
    const cfg = state.config.?;
    state.results = try state.allocator.alloc(TargetResult, cfg.targets.len);
    for (cfg.targets, 0..) |t, idx| {
        state.results[idx] = .{
            .id = try state.allocator.dupe(u8, t.id),
            .identity = try state.allocator.dupe(u8, t.identity),
            .group = try state.allocator.dupe(u8, t.group),
            .test_port = t.test_port,
            .state = "waiting",
            .updated_at_ms = nowMs(),
        };
    }
    workerMain(&state);
}

fn handleCommand(allocator: std.mem.Allocator, state: *State, command: []const u8) ![]const u8 {
    debugLog("cmd={s}", .{command});
    var parts = std.mem.tokenizeScalar(u8, command, ' ');
    const verb = parts.next() orelse return try allocator.dupe(u8, "invalid\n");

    if (std.mem.eql(u8, verb, "ping")) {
        return try allocator.dupe(u8, "pong\n");
    }

    if (std.mem.eql(u8, verb, "status")) {
        state.mutex.lock();
        defer state.mutex.unlock();
        const cfg = state.config;
        return try std.fmt.allocPrint(allocator,
            "{{\"phase\":\"{s}\",\"active\":{s},\"stop_requested\":{s},\"batch_id\":\"{s}\",\"targets\":{d}}}\n",
            .{
                @tagName(state.phase),
                if (state.worker_active) "true" else "false",
                if (state.stop_requested) "true" else "false",
                if (cfg) |cfgv| cfgv.batch_id else "",
                if (cfg) |cfgv| cfgv.targets.len else 0,
            },
        );
    }

    if (std.mem.eql(u8, verb, "stop")) {
        state.mutex.lock();
        defer state.mutex.unlock();
        state.stop_requested = true;
        if (state.phase == .running) state.phase = .stopping;
        return try allocator.dupe(u8, "stopping\n");
    }

    if (std.mem.eql(u8, verb, "run")) {
        const config_path = parts.next() orelse return try allocator.dupe(u8, "invalid\n");
        state.mutex.lock();
        if (state.worker_active) {
            state.mutex.unlock();
            return try allocator.dupe(u8, "busy\n");
        }
        state.clear();
        state.config = parseConfigFile(state.allocator, config_path) catch |err| {
            state.phase = .failed;
            state.last_error = state.allocator.dupe(u8, @errorName(err)) catch null;
            state.mutex.unlock();
            return try std.fmt.allocPrint(allocator, "error:{s}\n", .{@errorName(err)});
        };
        const cfg = state.config.?;
        state.results = try state.allocator.alloc(TargetResult, cfg.targets.len);
        for (cfg.targets, 0..) |t, idx| {
            state.results[idx] = .{
                .id = try state.allocator.dupe(u8, t.id),
                .identity = try state.allocator.dupe(u8, t.identity),
                .group = try state.allocator.dupe(u8, t.group),
                .test_port = t.test_port,
                .state = "waiting",
                .updated_at_ms = nowMs(),
            };
        }
        state.phase = .ready;
        state.stop_requested = false;
        state.worker_active = true;
        state.mutex.unlock();

        const thread = try std.Thread.spawn(.{}, workerMain, .{state});
        thread.detach();
        return try allocator.dupe(u8, "started\n");
    }

    return try allocator.dupe(u8, "unknown-command\n");
}

fn runWebtestd(allocator: std.mem.Allocator, socket_path: []const u8) !void {
    debugLog("webtestd start socket={s}", .{socket_path});
    if (socket_path.len != 0) {
        std.fs.cwd().deleteFile(socket_path) catch {};
    }
    var addr = try std.net.Address.initUnix(socket_path);
    var server = try addr.listen(.{});
    defer {
        server.deinit();
        std.fs.cwd().deleteFile(socket_path) catch {};
    }

    var state = State{ .allocator = allocator };
    defer state.clear();

    while (true) {
        debugLog("accept wait", .{});
        var conn = server.accept() catch |err| {
            debugLog("accept err {s}", .{@errorName(err)});
            continue;
        };
        defer conn.stream.close();
        debugLog("accept ok", .{});

        var read_buf: [1024]u8 = undefined;
        const n = conn.stream.read(&read_buf) catch |err| {
            debugLog("read err {s}", .{@errorName(err)});
            continue;
        };
        if (n == 0) {
            debugLog("read eof", .{});
            continue;
        }
        debugLog("read n={d}", .{n});
        const command = std.mem.trim(u8, read_buf[0..n], " \r\n\t");

        var arena_state = std.heap.ArenaAllocator.init(allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const response = handleCommand(arena, &state, command) catch |err| {
            debugLog("handle err {s}", .{@errorName(err)});
            continue;
        };
        debugLog("write response", .{});
        conn.stream.writeAll(response) catch |err| {
            debugLog("write err {s}", .{@errorName(err)});
            continue;
        };
    }
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    if (argv.len <= 1 or std.mem.eql(u8, argv[1], "--help") or std.mem.eql(u8, argv[1], "-h")) {
        printUsage();
        return;
    }
    if (std.mem.eql(u8, argv[1], "--version")) {
        std.debug.print("{s}\n", .{version});
        return;
    }
    if (std.mem.eql(u8, argv[1], "run")) {
        if (argv.len != 4 or !std.mem.eql(u8, argv[2], "--config")) return error.InvalidArgument;
        try runBatchOnce(allocator, argv[3]);
        return;
    }
    if (!std.mem.eql(u8, argv[1], "webtestd")) return error.InvalidArgument;

    var socket_path: []const u8 = "/tmp/status-webtest.sock";
    var i: usize = 2;
    while (i < argv.len) : (i += 1) {
        if (std.mem.eql(u8, argv[i], "--socket-path")) {
            i += 1;
            if (i >= argv.len) return error.InvalidArgument;
            socket_path = argv[i];
        } else {
            return error.InvalidArgument;
        }
    }

    try runWebtestd(allocator, socket_path);
}
