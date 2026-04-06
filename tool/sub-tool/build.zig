const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .single_threaded = true,
        .strip = optimize != .Debug,
    });

    const exe = b.addExecutable(.{
        .name = "sub-tool",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run sub-tool");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest(.{ .root_module = root_module });
    const test_step = b.step("test", "Run sub-tool tests");
    test_step.dependOn(&tests.step);
}
