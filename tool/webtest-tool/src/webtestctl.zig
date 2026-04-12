const std = @import("std");
const build_options = @import("build_options");

const version = build_options.version;

const Options = struct {
    socket_path: []const u8 = "/tmp/status-webtest.sock",
    command: []const u8,
};

fn printUsage() void {
    std.debug.print(
        \\webtestctl {s}
        \\
        \\Usage:
        \\  webtestctl [--socket-path <path>] ping
        \\  webtestctl [--socket-path <path>] status
        \\  webtestctl [--socket-path <path>] stop
        \\  webtestctl [--socket-path <path>] run --config <path>
        \\  webtestctl [--socket-path <path>] send <raw-command>
        \\  webtestctl --help
        \\  webtestctl --version
        \\
    , .{version});
}

fn mapCommand(allocator: std.mem.Allocator, cmd: []const u8, argv: []const [:0]u8, index: *usize) !?[]const u8 {
    if (std.mem.eql(u8, cmd, "ping")) return "ping";
    if (std.mem.eql(u8, cmd, "status")) return "status";
    if (std.mem.eql(u8, cmd, "stop")) return "stop";
    if (std.mem.eql(u8, cmd, "run")) {
        index.* += 1;
        if (index.* >= argv.len or !std.mem.eql(u8, argv[index.*], "--config")) return error.InvalidArgument;
        index.* += 1;
        if (index.* >= argv.len) return error.InvalidArgument;
        return try std.fmt.allocPrint(allocator, "run {s}", .{argv[index.*]});
    }
    return null;
}

fn parseOptions(allocator: std.mem.Allocator, argv: []const [:0]u8) !Options {
    var socket_path: []const u8 = "/tmp/status-webtest.sock";
    var i: usize = 0;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (std.mem.eql(u8, arg, "--socket-path")) {
            i += 1;
            if (i >= argv.len) return error.InvalidArgument;
            socket_path = argv[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "send")) {
            i += 1;
            if (i >= argv.len) return error.InvalidArgument;
            return .{
                .socket_path = socket_path,
                .command = try allocator.dupe(u8, argv[i]),
            };
        }
        if (try mapCommand(allocator, arg, argv, &i)) |mapped| {
            return .{
                .socket_path = socket_path,
                .command = mapped,
            };
        }
        return error.InvalidArgument;
    }
    return error.InvalidArgument;
}

fn writeAll(stream: std.net.Stream, bytes: []const u8) !void {
    var sent: usize = 0;
    while (sent < bytes.len) {
        const n = try stream.write(bytes[sent..]);
        if (n == 0) return error.WriteFailed;
        sent += n;
    }
}

fn readAndPrintAll(stream: std.net.Stream) !void {
    const stdout = std.fs.File.stdout();
    var buf: [4096]u8 = undefined;
    while (true) {
        const n = stream.read(&buf) catch |err| switch (err) {
            error.ConnectionResetByPeer => break,
            else => return err,
        };
        if (n == 0) break;
        try stdout.writeAll(buf[0..n]);
    }
}

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    const argv = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, argv);

    if (argv.len <= 1) {
        printUsage();
        return;
    }

    if (std.mem.eql(u8, argv[1], "--help") or std.mem.eql(u8, argv[1], "-h")) {
        printUsage();
        return;
    }
    if (std.mem.eql(u8, argv[1], "--version")) {
        try std.fs.File.stdout().writeAll(version ++ "\n");
        return;
    }

    const opts = parseOptions(gpa, argv[1..]) catch {
        printUsage();
        return error.InvalidArgument;
    };

    var attempt: usize = 0;
    while (attempt < 2) : (attempt += 1) {
        var stream = std.net.connectUnixSocket(opts.socket_path) catch |err| {
            if ((err == error.ConnectionRefused or err == error.FileNotFound) and attempt == 0) {
                std.Thread.sleep(200 * std.time.ns_per_ms);
                continue;
            }
            return err;
        };
        defer stream.close();

        writeAll(stream, opts.command) catch |err| {
            if (err == error.BrokenPipe and attempt == 0) {
                std.Thread.sleep(200 * std.time.ns_per_ms);
                continue;
            }
            return err;
        };
        writeAll(stream, "\n") catch |err| {
            if (err == error.BrokenPipe and attempt == 0) {
                std.Thread.sleep(200 * std.time.ns_per_ms);
                continue;
            }
            return err;
        };
        try readAndPrintAll(stream);
        return;
    }
}
