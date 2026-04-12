const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version_text = std.mem.trim(u8, @embedFile("VERSION"), " \r\n");

    const options = b.addOptions();
    options.addOption([]const u8, "version", version_text);

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .single_threaded = false,
        .strip = optimize != .Debug,
    });
    root_module.addOptions("build_options", options);

    const exe = b.addExecutable(.{
        .name = "webtest-tool",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    const ctl_module = b.createModule(.{
        .root_source_file = b.path("src/webtestctl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .single_threaded = true,
        .strip = optimize != .Debug,
    });
    ctl_module.addOptions("build_options", options);

    const ctl = b.addExecutable(.{
        .name = "webtestctl",
        .root_module = ctl_module,
    });
    b.installArtifact(ctl);
}
