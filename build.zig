const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ncgames",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkSystemLibrary("menu");
    exe.linkSystemLibrary("ncursesw");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const tzfe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib2048.zig"),
        .target = target,
        .optimize = optimize,
    });

    const sudoku_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/sudoku.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_sudoku_unit_tests = b.addRunArtifact(sudoku_unit_tests);
    const run_tzfe_unit_tests = b.addRunArtifact(tzfe_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_tzfe_unit_tests.step);
    test_step.dependOn(&run_sudoku_unit_tests.step);
}
