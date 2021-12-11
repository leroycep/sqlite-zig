const std = @import("std");
const Builder = std.build.Builder;

const EXAMPLES = .{
    "simple-exec",
    "simple",
    "blog",
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const tests = b.addTest("src/sqlite3.zig");
    tests.setBuildMode(mode);
    tests.addCSourceFile("dep/sqlite/sqlite3.c", &.{});
    tests.linkLibC();

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    const target = b.standardTargetOptions(.{});

    const all_example_step = b.step("examples", "Build examples");
    inline for (EXAMPLES) |example_name| {
        const example = b.addExecutable(example_name, "examples" ++ std.fs.path.sep_str ++ example_name ++ ".zig");
        example.addPackagePath("sqlite", "src/sqlite3.zig");
        example.setBuildMode(mode);
        example.setTarget(target);
        example.addCSourceFile("dep/sqlite/sqlite3.c", &.{});
        example.linkLibC();

        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&example.run().step);
        all_example_step.dependOn(&example.step);
    }
}
