const std = @import("std");
const Builder = std.build.Builder;

const EXAMPLES = .{
    "simple-exec",
    "simple",
    "blog",
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("sqlite3", .{
        .source_file = .{ .path = "src/sqlite3.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "sqlite3",
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFile(.{
        .file = .{ .path = "src/sqlite3.c" },
        .flags = &.{},
    });
    lib.linkLibC();
    b.installArtifact(lib);

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/sqlite3.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibrary(lib);

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
        example.addModule("sqlite", module);
        example.linkLibrary(lib);

        var run = b.addRunArtifact(example);
        if (b.args) |args| run.addArgs(args);
        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&run.step);

        all_example_step.dependOn(&example.step);
    }
}
