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
        .name = "anytls-zig",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run anytls-zig");
    run_step.dependOn(&run_cmd.step);
}
