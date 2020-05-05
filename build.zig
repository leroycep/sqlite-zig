const std = @import("std");
const Builder = std.build.Builder;

const EXAMPLES = .{
    "simple",
    "blog",
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const tests = b.addTest("src/sqlite.zig");
    tests.setBuildMode(mode);
    tests.linkSystemLibrary("sqlite3");
    tests.linkSystemLibrary("c");

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    const all_example_step = b.step("examples", "Build examples");
    inline for (EXAMPLES) |example_name| {
        const example = b.addExecutable(example_name, "examples" ++ std.fs.path.sep_str ++ example_name ++ ".zig");
        example.addPackagePath("sqlite", "src/sqlite.zig");
        example.setBuildMode(mode);
        example.linkSystemLibrary("sqlite3");
        example.linkSystemLibrary("c");

        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&example.run().step);
        all_example_step.dependOn(&example.step);
    }
}
