const std = @import("std");
const Builder = std.build.Builder;

const EXAMPLES = .{
    "simple-exec",
    "simple",
    "blog",
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{
        // To deal with the error message:
        //
        //     LLD Link... ld.lld: error: undefined symbol: fcntl64
        //
        // We are using musl by default; though specifying a version of glibc would also work.
        //
        // See https://github.com/ziglang/zig/issues/9485#issue-956197415
        .default_target = .{
            .abi = .musl,
        },
    });

    const mode = b.standardReleaseOptions();

    const tests = b.addTest("src/sqlite3.zig");
    tests.setBuildMode(mode);
    tests.setTarget(target);
    tests.addCSourceFile("src/sqlite3.c", &.{});
    tests.linkLibC();

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    const all_example_step = b.step("examples", "Build examples");
    inline for (EXAMPLES) |example_name| {
        const example = b.addExecutable(example_name, "examples" ++ std.fs.path.sep_str ++ example_name ++ ".zig");
        example.addPackagePath("sqlite", "src/sqlite3.zig");
        example.setBuildMode(mode);
        example.setTarget(target);
        example.addCSourceFile("src/sqlite3.c", &.{});
        example.linkLibC();

        var run = example.run();
        if (b.args) |args| run.addArgs(args);
        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&run.step);

        all_example_step.dependOn(&example.step);
    }
}
