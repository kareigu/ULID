const std = @import("std");

const version = std.SemanticVersion{ .major = 0, .minor = 0, .patch = 1 };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared_lib = b.option(bool, "shared-lib", "Build as a shared library") orelse false;

    const name = "ulid";
    const root_source_file = b.path("src/root.zig");

    const lib = if (shared_lib)
        b.addSharedLibrary(.{
            .name = name,
            .root_source_file = root_source_file,
            .target = target,
            .optimize = optimize,
            .version = version,
        })
    else
        b.addStaticLibrary(.{
            .name = name,
            .root_source_file = root_source_file,
            .target = target,
            .optimize = optimize,
        });

    b.installArtifact(lib);
    const header_install = b.addInstallHeaderFile(b.path("include/ulid.h"), "ulid.h");
    b.getInstallStep().dependOn(&header_install.step);

    const unit_tests = b.addTest(.{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const c_test = b.addExecutable(.{
        .name = "test",
        .target = target,
        .optimize = optimize,
    });
    c_test.addIncludePath(b.path("include"));
    c_test.addCSourceFile(.{ .file = b.path("test/test.c"), .flags = &.{"-std=c99"} });
    c_test.linkLibrary(lib);
    c_test.linkSystemLibrary("c");

    const run_c_test = b.addRunArtifact(c_test);
    const c_test_step = b.step("c-test", "Run C library test application");
    c_test_step.dependOn(&run_c_test.step);
}
