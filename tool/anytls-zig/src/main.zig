const std = @import("std");
const build_options = @import("build_options");
const posix = std.posix;

const Allocator = std.mem.Allocator;
const Sha256 = std.crypto.hash.sha2.Sha256;
const Md5 = std.crypto.hash.Md5;
const TlsClient = std.crypto.tls.Client;

const version = build_options.version;
const client_name = "anytls-zig/" ++ version;

const CMD_WASTE: u8 = 0;
const CMD_SYN: u8 = 1;
const CMD_PSH: u8 = 2;
const CMD_FIN: u8 = 3;
const CMD_SETTINGS: u8 = 4;
const CMD_ALERT: u8 = 5;
const CMD_UPDATE_PADDING_SCHEME: u8 = 6;
const CMD_SYNACK: u8 = 7;
const CMD_HEART_REQUEST: u8 = 8;
const CMD_HEART_RESPONSE: u8 = 9;
const CMD_SERVER_SETTINGS: u8 = 10;

const HEADER_LEN: usize = 7;
const PADDING0_SIZE: usize = 30;
const PADDING1_SIZE: usize = 160;
const PADDING2_SIZE: usize = 450;
const DEFAULT_LISTEN = "127.0.0.1:18081";
const DEFAULT_PADDING_SCHEME =
    "stop=8\n" ++
    "0=30-30\n" ++
    "1=100-400\n" ++
    "2=400-500,c,500-1000,c,500-1000,c,500-1000,c,500-1000\n" ++
    "3=9-9,500-1000\n" ++
    "4=500-1000\n" ++
    "5=500-1000\n" ++
    "6=500-1000\n" ++
    "7=500-1000";

var insecure_sni_disabled = std.atomic.Value(bool).init(false);

const Config = struct {
    listen_host: []const u8 = "127.0.0.1",
    listen_port: u16 = 18081,
    server_host: []const u8 = "",
    server_port: u16 = 443,
    sni: []const u8 = "",
    password: []const u8 = "",
    insecure: bool = true,
};

const SocksTarget = struct {
    atyp: u8,
    addr: []u8,
    port: u16,
};

const Frame = struct {
    cmd: u8,
    sid: u32,
    data: []u8,
};

const TlsConn = struct {
    stream: std.net.Stream,
    stream_reader: std.net.Stream.Reader,
    stream_writer: std.net.Stream.Writer,
    tls: TlsClient,
    ca_bundle: ?std.crypto.Certificate.Bundle = null,
    write_mutex: std.Thread.Mutex = .{},

    fn connect(allocator: Allocator, server_host: []const u8, server_port: u16, sni: []const u8, insecure: bool) !*TlsConn {
        const tls_host = tlsHost(server_host, sni);
        if (insecure and insecure_sni_disabled.load(.acquire)) {
            return try connectWithTlsHost(allocator, server_host, server_port, "", insecure);
        }
        if (insecure and tls_host.len > 0) {
            return connectWithTlsHost(allocator, server_host, server_port, tls_host, insecure) catch |err| switch (err) {
                error.CertificateHostMismatch => {
                    std.log.warn("TLS certificate host mismatch for SNI {s}, retrying without SNI in insecure mode", .{tls_host});
                    insecure_sni_disabled.store(true, .release);
                    return try connectWithTlsHost(allocator, server_host, server_port, "", insecure);
                },
                else => return err,
            };
        }
        return try connectWithTlsHost(allocator, server_host, server_port, tls_host, insecure);
    }

    fn connectWithTlsHost(allocator: Allocator, server_host: []const u8, server_port: u16, tls_host: []const u8, insecure: bool) !*TlsConn {
        const self = try allocator.create(TlsConn);
        errdefer allocator.destroy(self);

        self.* = undefined;
        self.write_mutex = .{};
        self.ca_bundle = null;
        self.stream = try std.net.tcpConnectToHost(allocator, server_host, server_port);
        errdefer self.stream.close();

        const tls_read_buffer = try allocator.alloc(u8, TlsClient.min_buffer_len * 2);
        errdefer allocator.free(tls_read_buffer);
        const tls_write_buffer = try allocator.alloc(u8, TlsClient.min_buffer_len);
        errdefer allocator.free(tls_write_buffer);
        const socket_read_buffer = try allocator.alloc(u8, TlsClient.min_buffer_len);
        errdefer allocator.free(socket_read_buffer);
        const socket_write_buffer = try allocator.alloc(u8, TlsClient.min_buffer_len);
        errdefer allocator.free(socket_write_buffer);

        self.stream_reader = self.stream.reader(socket_read_buffer);
        self.stream_writer = self.stream.writer(tls_write_buffer);

        if (!insecure) {
            self.ca_bundle = .{};
            try self.ca_bundle.?.rescan(allocator);
        }
        errdefer if (self.ca_bundle) |*bundle| bundle.deinit(allocator);

        self.tls = try TlsClient.init(
            self.stream_reader.interface(),
            &self.stream_writer.interface,
            .{
                .host = if (tls_host.len > 0) .{ .explicit = tls_host } else .no_verification,
                .ca = if (insecure) .no_verification else .{ .bundle = self.ca_bundle.? },
                .read_buffer = tls_read_buffer,
                .write_buffer = socket_write_buffer,
                .allow_truncation_attacks = true,
            },
        );
        return self;
    }

    fn writeAll(self: *TlsConn, data: []const u8) !void {
        self.write_mutex.lock();
        defer self.write_mutex.unlock();
        try self.tls.writer.writeAll(data);
        try self.tls.writer.flush();
        try self.stream_writer.interface.flush();
    }

    fn readExact(self: *TlsConn, out: []u8) !void {
        try self.tls.reader.readSliceAll(out);
    }

    fn close(self: *TlsConn, allocator: Allocator) void {
        allocator.free(self.tls.reader.buffer);
        allocator.free(self.tls.writer.buffer);
        allocator.free(self.stream_reader.file_reader.interface.buffer);
        allocator.free(self.stream_writer.interface.buffer);
        if (self.ca_bundle) |*bundle| bundle.deinit(allocator);
        self.stream.close();
        allocator.destroy(self);
    }
};

fn printUsage() void {
    std.debug.print(
        \\anytls-zig {s}
        \\
        \\Usage:
        \\  anytls-zig -s anytls://password@host:port/?sni=name [-l 127.0.0.1:18081]
        \\  anytls-zig -server host:port -p password [-sni name] [-l 127.0.0.1:18081]
        \\
        \\Options:
        \\  -l, --listen ADDR       SOCKS5 listen address, default {s}
        \\  -s, --server-uri URI    AnyTLS URI
        \\  --server-uri-file PATH  Read AnyTLS URI from file
        \\  -server ADDR            AnyTLS server address
        \\  -p, --password VALUE    AnyTLS password
        \\  --password-file PATH    Read AnyTLS password from file
        \\  -sni VALUE              TLS SNI
        \\  --insecure              Disable CA verification, default
        \\  --verify                Enable system CA and host verification
        \\  --version, version      Show version
        \\  -h, --help              Show help
        \\
    , .{ version, DEFAULT_LISTEN });
}

fn dieUsage() noreturn {
    printUsage();
    std.process.exit(2);
}

fn dupComponent(allocator: Allocator, component: std.Uri.Component) ![]const u8 {
    return try allocator.dupe(u8, try component.toRawMaybeAlloc(allocator));
}

fn parseBool(value: []const u8) bool {
    return std.mem.eql(u8, value, "1") or
        std.ascii.eqlIgnoreCase(value, "true") or
        std.ascii.eqlIgnoreCase(value, "yes") or
        std.ascii.eqlIgnoreCase(value, "on");
}

fn queryValue(query: []const u8, key: []const u8) []const u8 {
    var it = std.mem.splitScalar(u8, query, '&');
    while (it.next()) |pair| {
        const eq = std.mem.indexOfScalar(u8, pair, '=') orelse continue;
        if (std.mem.eql(u8, pair[0..eq], key)) return pair[eq + 1 ..];
    }
    return "";
}

fn dupPercentDecoded(allocator: Allocator, value: []const u8) ![]const u8 {
    const buffer = try allocator.dupe(u8, value);
    return std.Uri.percentDecodeInPlace(buffer);
}

fn parseHostPort(allocator: Allocator, value: []const u8, default_port: u16) !struct { host: []const u8, port: u16 } {
    if (value.len == 0) return error.InvalidHostPort;
    if (value[0] == '[') {
        const end = std.mem.indexOfScalar(u8, value, ']') orelse return error.InvalidHostPort;
        const host = try allocator.dupe(u8, value[1..end]);
        var port = default_port;
        if (end + 1 < value.len) {
            if (value[end + 1] != ':') return error.InvalidHostPort;
            port = try std.fmt.parseInt(u16, value[end + 2 ..], 10);
        }
        return .{ .host = host, .port = port };
    }

    const colon = std.mem.lastIndexOfScalar(u8, value, ':');
    if (colon) |idx| {
        if (std.mem.indexOfScalar(u8, value[0..idx], ':') == null) {
            return .{
                .host = try allocator.dupe(u8, value[0..idx]),
                .port = try std.fmt.parseInt(u16, value[idx + 1 ..], 10),
            };
        }
    }
    return .{ .host = try allocator.dupe(u8, value), .port = default_port };
}

fn parseListen(allocator: Allocator, value: []const u8, cfg: *Config) !void {
    const parsed = try parseHostPort(allocator, value, cfg.listen_port);
    cfg.listen_host = parsed.host;
    cfg.listen_port = parsed.port;
}

fn parseServerAddr(allocator: Allocator, value: []const u8, cfg: *Config) !void {
    const parsed = try parseHostPort(allocator, value, 443);
    cfg.server_host = parsed.host;
    cfg.server_port = parsed.port;
}

fn parseServerUri(allocator: Allocator, value: []const u8, cfg: *Config) !void {
    if (!std.mem.startsWith(u8, value, "anytls://")) return error.InvalidScheme;
    const uri = try std.Uri.parse(value);
    if (!std.mem.eql(u8, uri.scheme, "anytls")) return error.InvalidScheme;
    cfg.server_host = try allocator.dupe(u8, try uri.getHostAlloc(allocator));
    cfg.server_port = uri.port orelse 443;
    if (uri.user) |user_component| cfg.password = try dupComponent(allocator, user_component);
    if (uri.password) |password_component| cfg.password = try dupComponent(allocator, password_component);
    if (uri.query) |query_component| {
        const query = try query_component.toRawMaybeAlloc(allocator);
        const sni = queryValue(query, "sni");
        if (sni.len > 0) cfg.sni = try dupPercentDecoded(allocator, sni);
        const insecure = queryValue(query, "insecure");
        if (insecure.len > 0) cfg.insecure = parseBool(insecure);
    }
}

fn readTextFileTrimmed(allocator: Allocator, path: []const u8) ![]const u8 {
    const max_bytes = 64 * 1024;
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const buffer = try allocator.alloc(u8, max_bytes);
    errdefer allocator.free(buffer);

    const size = try file.readAll(buffer);
    if (size == max_bytes) {
        var extra: [1]u8 = undefined;
        if (try file.read(&extra) != 0) return error.FileTooBig;
    }

    const trimmed = std.mem.trim(u8, buffer[0..size], " \t\r\n");
    const result = try allocator.dupe(u8, trimmed);
    allocator.free(buffer);
    return result;
}

fn parseArgs(allocator: Allocator) !Config {
    var cfg = Config{};
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--listen")) {
            parseListen(allocator, args.next() orelse dieUsage(), &cfg) catch dieUsage();
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--server-uri")) {
            try parseServerUri(allocator, args.next() orelse dieUsage(), &cfg);
        } else if (std.mem.eql(u8, arg, "--server-uri-file")) {
            try parseServerUri(allocator, try readTextFileTrimmed(allocator, args.next() orelse dieUsage()), &cfg);
        } else if (std.mem.eql(u8, arg, "-server") or std.mem.eql(u8, arg, "--server")) {
            try parseServerAddr(allocator, args.next() orelse dieUsage(), &cfg);
        } else if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--password")) {
            cfg.password = try allocator.dupe(u8, args.next() orelse dieUsage());
        } else if (std.mem.eql(u8, arg, "--password-file")) {
            cfg.password = try allocator.dupe(u8, try readTextFileTrimmed(allocator, args.next() orelse dieUsage()));
        } else if (std.mem.eql(u8, arg, "-sni") or std.mem.eql(u8, arg, "--sni")) {
            cfg.sni = try allocator.dupe(u8, args.next() orelse dieUsage());
        } else if (std.mem.eql(u8, arg, "--insecure")) {
            cfg.insecure = true;
        } else if (std.mem.eql(u8, arg, "--verify")) {
            cfg.insecure = false;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "version") or std.mem.eql(u8, arg, "-V")) {
            try std.fs.File.stdout().writeAll(version ++ "\n");
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printUsage();
            std.process.exit(0);
        } else {
            dieUsage();
        }
    }

    if (cfg.server_host.len == 0 or cfg.password.len == 0) dieUsage();
    return cfg;
}

fn tlsHost(server_host: []const u8, sni: []const u8) []const u8 {
    const host = if (sni.len > 0) sni else server_host;
    if (host.len == 0) return "";
    if (std.net.Address.parseIp(host, 0)) |_| {
        return "";
    } else |_| {}
    return host;
}

fn md5Hex(allocator: Allocator, input: []const u8) ![]u8 {
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(input, &digest, .{});
    const hex = std.fmt.bytesToHex(digest, .lower);
    return try allocator.dupe(u8, &hex);
}

fn appendFrame(allocator: Allocator, out: *std.ArrayList(u8), cmd: u8, sid: u32, data: []const u8) !void {
    if (data.len > std.math.maxInt(u16)) return error.FrameTooLarge;
    var header: [HEADER_LEN]u8 = undefined;
    header[0] = cmd;
    std.mem.writeInt(u32, header[1..5], sid, .big);
    std.mem.writeInt(u16, header[5..7], @intCast(data.len), .big);
    try out.appendSlice(allocator, &header);
    try out.appendSlice(allocator, data);
}

fn appendWasteFrame(allocator: Allocator, out: *std.ArrayList(u8), data_len: usize) !void {
    if (data_len > std.math.maxInt(u16)) return error.FrameTooLarge;
    const old_len = out.items.len;
    try out.resize(allocator, old_len + HEADER_LEN + data_len);
    const frame = out.items[old_len..];
    frame[0] = CMD_WASTE;
    std.mem.writeInt(u32, frame[1..5], 0, .big);
    std.mem.writeInt(u16, frame[5..7], @intCast(data_len), .big);
    @memset(frame[HEADER_LEN..], 0);
}

fn writeFirstPacket(allocator: Allocator, conn: *TlsConn, settings: []const u8, socks_addr: []const u8) !void {
    var packet = std.ArrayList(u8).empty;
    defer packet.deinit(allocator);
    try appendFrame(allocator, &packet, CMD_SETTINGS, 0, settings);
    try appendFrame(allocator, &packet, CMD_SYN, 1, "");
    try appendFrame(allocator, &packet, CMD_PSH, 1, socks_addr);
    if (packet.items.len < PADDING1_SIZE and PADDING1_SIZE - packet.items.len > HEADER_LEN) {
        try appendWasteFrame(allocator, &packet, PADDING1_SIZE - packet.items.len - HEADER_LEN);
    }
    try conn.writeAll(packet.items);
}

fn writeFrame(conn: *TlsConn, cmd: u8, sid: u32, data: []const u8) !void {
    if (data.len > std.math.maxInt(u16)) return error.FrameTooLarge;
    var header: [HEADER_LEN]u8 = undefined;
    header[0] = cmd;
    std.mem.writeInt(u32, header[1..5], sid, .big);
    std.mem.writeInt(u16, header[5..7], @intCast(data.len), .big);
    conn.write_mutex.lock();
    defer conn.write_mutex.unlock();
    try conn.tls.writer.writeAll(&header);
    if (data.len > 0) try conn.tls.writer.writeAll(data);
    try conn.tls.writer.flush();
    try conn.stream_writer.interface.flush();
}

fn writeDataFramePadded(allocator: Allocator, conn: *TlsConn, sid: u32, data: []const u8) !void {
    var packet = std.ArrayList(u8).empty;
    defer packet.deinit(allocator);
    try appendFrame(allocator, &packet, CMD_PSH, sid, data);
    if (packet.items.len < PADDING2_SIZE and PADDING2_SIZE - packet.items.len > HEADER_LEN) {
        try appendWasteFrame(allocator, &packet, PADDING2_SIZE - packet.items.len - HEADER_LEN);
    }
    try conn.writeAll(packet.items);
}

fn readFrame(allocator: Allocator, conn: *TlsConn) !Frame {
    var header: [HEADER_LEN]u8 = undefined;
    try conn.readExact(&header);
    const data_len = std.mem.readInt(u16, header[5..7], .big);
    const data = try allocator.alloc(u8, data_len);
    errdefer allocator.free(data);
    if (data_len > 0) try conn.readExact(data);
    return .{ .cmd = header[0], .sid = std.mem.readInt(u32, header[1..5], .big), .data = data };
}

fn writeAuth(conn: *TlsConn, password: []const u8) !void {
    var hash: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(password, &hash, .{});
    var auth: [34 + PADDING0_SIZE]u8 = undefined;
    @memcpy(auth[0..32], &hash);
    std.mem.writeInt(u16, auth[32..34], PADDING0_SIZE, .big);
    @memset(auth[34..], 0);
    try conn.writeAll(&auth);
}

fn makeSettings(allocator: Allocator) ![]u8 {
    const padding_md5 = try md5Hex(allocator, DEFAULT_PADDING_SCHEME);
    defer allocator.free(padding_md5);
    return try std.fmt.allocPrint(allocator, "v=2\nclient={s}\npadding-md5={s}", .{ client_name, padding_md5 });
}

fn serializeSocksAddr(allocator: Allocator, atyp: u8, addr: []const u8, port: u16) ![]u8 {
    var out = std.ArrayList(u8).empty;
    errdefer out.deinit(allocator);
    try out.append(allocator, atyp);
    switch (atyp) {
        1 => {
            if (addr.len != 4) return error.InvalidIpv4;
            try out.appendSlice(allocator, addr);
        },
        3 => {
            if (addr.len > 255) return error.DomainTooLong;
            try out.append(allocator, @intCast(addr.len));
            try out.appendSlice(allocator, addr);
        },
        4 => {
            if (addr.len != 16) return error.InvalidIpv6;
            try out.appendSlice(allocator, addr);
        },
        else => return error.UnsupportedAddressType,
    }
    var port_buf: [2]u8 = undefined;
    std.mem.writeInt(u16, &port_buf, port, .big);
    try out.appendSlice(allocator, &port_buf);
    return try out.toOwnedSlice(allocator);
}

fn recvAllFd(fd: posix.fd_t, buf: []u8) !void {
    var offset: usize = 0;
    while (offset < buf.len) {
        const n = try posix.recv(fd, buf[offset..], 0);
        if (n == 0) return error.EndOfStream;
        offset += n;
    }
}

fn sendAllFd(fd: posix.fd_t, data: []const u8) !void {
    var offset: usize = 0;
    while (offset < data.len) {
        const n = try posix.send(fd, data[offset..], 0);
        if (n == 0) return error.EndOfStream;
        offset += n;
    }
}

fn readSocksTarget(allocator: Allocator, stream: std.net.Stream) !SocksTarget {
    var head: [4]u8 = undefined;
    try recvAllFd(stream.handle, &head);
    if (head[0] != 5 or head[1] != 1) return error.InvalidSocksRequest;
    const atyp = head[3];
    const addr_len: usize = switch (atyp) {
        1 => 4,
        3 => blk: {
            var one: [1]u8 = undefined;
            try recvAllFd(stream.handle, &one);
            break :blk one[0];
        },
        4 => 16,
        else => return error.UnsupportedAddressType,
    };
    const addr = try allocator.alloc(u8, addr_len);
    errdefer allocator.free(addr);
    try recvAllFd(stream.handle, addr);
    var port_buf: [2]u8 = undefined;
    try recvAllFd(stream.handle, &port_buf);
    return .{ .atyp = atyp, .addr = addr, .port = std.mem.readInt(u16, &port_buf, .big) };
}

fn handleSocks(allocator: Allocator, client: std.net.Stream, cfg: Config) !void {
    defer client.close();
    var methods_head: [2]u8 = undefined;
    try recvAllFd(client.handle, &methods_head);
    if (methods_head[0] != 5) return error.InvalidSocksHandshake;
    var methods_buf: [255]u8 = undefined;
    const method_count = methods_head[1];
    try recvAllFd(client.handle, methods_buf[0..method_count]);
    try sendAllFd(client.handle, &.{ 5, 0 });

    const target = try readSocksTarget(allocator, client);
    defer allocator.free(target.addr);
    if (target.atyp == 3) {
        std.log.info("proxy target {s}:{}", .{ target.addr, target.port });
    } else {
        std.log.info("proxy target atyp={} port={}", .{ target.atyp, target.port });
    }

    const remote = try TlsConn.connect(allocator, cfg.server_host, cfg.server_port, cfg.sni, cfg.insecure);
    defer remote.close(allocator);
    try writeAuth(remote, cfg.password);
    const settings = try makeSettings(allocator);
    defer allocator.free(settings);
    const socks_addr = try serializeSocksAddr(allocator, target.atyp, target.addr, target.port);
    defer allocator.free(socks_addr);
    try writeFirstPacket(allocator, remote, settings, socks_addr);

    try sendAllFd(client.handle, &.{ 5, 0, 0, 1, 0, 0, 0, 0, 0, 0 });

    const client_thread = try std.Thread.spawn(.{}, relayClientToRemote, .{ allocator, client.handle, remote });

    remote_loop: while (true) {
        const frame = readFrame(allocator, remote) catch |err| switch (err) {
            error.EndOfStream => break :remote_loop,
            else => {
                std.log.err("read remote failed: {}", .{err});
                break :remote_loop;
            },
        };
        defer allocator.free(frame.data);
        switch (frame.cmd) {
            CMD_PSH => if (frame.sid == 1 and frame.data.len > 0) {
                sendAllFd(client.handle, frame.data) catch |err| {
                    std.log.err("send client failed: {}", .{err});
                    break :remote_loop;
                };
            },
            CMD_FIN => {
                posix.shutdown(client.handle, .send) catch {};
                break :remote_loop;
            },
            CMD_ALERT => {
                std.log.err("server alert: {s}", .{frame.data});
                posix.shutdown(client.handle, .send) catch {};
                break :remote_loop;
            },
            CMD_HEART_REQUEST => writeFrame(remote, CMD_HEART_RESPONSE, frame.sid, "") catch |err| {
                std.log.err("write heartbeat failed: {}", .{err});
                break :remote_loop;
            },
            CMD_SYNACK, CMD_SERVER_SETTINGS, CMD_WASTE, CMD_UPDATE_PADDING_SCHEME, CMD_HEART_RESPONSE => {},
            else => {},
        }
    }

    posix.shutdown(client.handle, .both) catch {};
    client_thread.join();
}

fn relayClientToRemote(allocator: Allocator, fd: posix.fd_t, remote: *TlsConn) void {
    var buf: [8192]u8 = undefined;
    while (true) {
        const n = posix.recv(fd, &buf, 0) catch break;
        if (n == 0) break;
        writeDataFramePadded(allocator, remote, 1, buf[0..n]) catch |err| {
            std.log.err("relay write failed: {}", .{err});
            break;
        };
    }
    writeFrame(remote, CMD_FIN, 1, "") catch {};
}

fn handleSocksThread(allocator: Allocator, client: std.net.Stream, cfg: Config) void {
    handleSocks(allocator, client, cfg) catch |err| {
        std.log.err("connection failed: {}", .{err});
    };
}

pub fn main() !void {
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_instance.deinit();
    const allocator = gpa_instance.allocator();
    const cfg = try parseArgs(allocator);

    const listen_addr = try std.net.Address.parseIp(cfg.listen_host, cfg.listen_port);
    var server = try listen_addr.listen(.{ .reuse_address = true });
    defer server.deinit();
    std.log.info("{s} listening {s}:{} => {s}:{} sni={s} insecure={}", .{ client_name, cfg.listen_host, cfg.listen_port, cfg.server_host, cfg.server_port, cfg.sni, cfg.insecure });

    while (true) {
        const conn = try server.accept();
        const thread = std.Thread.spawn(.{}, handleSocksThread, .{ allocator, conn.stream, cfg }) catch |err| {
            std.log.err("spawn connection thread failed: {}", .{err});
            conn.stream.close();
            continue;
        };
        thread.detach();
    }
}
