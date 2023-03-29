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

    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("sqlite3", .{
        .source_file = .{ .path = "src/sqlite3.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "sqlite3",
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFile("src/sqlite3.c", &.{});
    lib.linkLibC();
    lib.install();

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/sqlite3.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.addCSourceFile("src/sqlite3.c", &.{});
    tests.linkLibC();

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    const all_example_step = b.step("examples", "Build examples");
    inline for (EXAMPLES) |example_name| {
        const example = b.addExecutable(.{
            .name = example_name,
            .root_source_file = .{ .path = "examples" ++ std.fs.path.sep_str ++ example_name ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        example.addAnonymousModule("sqlite", .{
            .source_file = .{ .path = "src/sqlite3.zig" },
        });
        example.linkLibrary(lib);

        var run = example.run();
        if (b.args) |args| run.addArgs(args);
        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&run.step);

        all_example_step.dependOn(&example.step);
    }
}
