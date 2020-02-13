const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const tests = b.addTest("src/sqlite.zig");
    tests.setBuildMode(mode);
    tests.linkSystemLibrary("sqlite3");
    tests.linkSystemLibrary("c");

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);
}
