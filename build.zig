const std = @import("std");

const EXAMPLES = .{
    "simple-exec",
    "simple",
    "blog",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const should_install_shell = b.option(bool, "shell", "Build and install the sqlite3 command line interface (default: false)") orelse false;

    const lib = b.addStaticLibrary(.{
        .name = "sqlite3",
        .target = target,
        .optimize = optimize,
    });
    lib.installHeader(b.path("src/sqlite3.h"), "sqlite3.h");
    lib.installHeader(b.path("src/sqlite3ext.h"), "sqlite3ext.h");
    lib.addCSourceFile(.{ .file = b.path("src/sqlite3.c") });
    lib.linkLibC();
    b.installArtifact(lib);

    const shell = b.addExecutable(.{
        .name = "sqlite3",
        .target = target,
        .optimize = optimize,
    });
    shell.addCSourceFile(.{ .file = b.path("src/shell.c") });
    shell.linkLibrary(lib);
    if (should_install_shell) {
        b.installArtifact(shell);
    }

    const module = b.addModule("sqlite3", .{
        .root_source_file = b.path("src/sqlite3.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.linkLibrary(lib);

    const test_exe = b.addTest(.{
        .root_source_file = b.path("src/sqlite3.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_exe.linkLibrary(lib);

    const test_run = b.addRunArtifact(test_exe);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&test_run.step);

    const all_example_step = b.step("examples", "Build examples");
    inline for (EXAMPLES) |example_name| {
        const example = b.addExecutable(.{
            .name = example_name,
            .root_source_file = b.path("examples" ++ std.fs.path.sep_str ++ example_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        example.root_module.addImport("sqlite", module);

        const install_example = b.addInstallArtifact(example, .{});

        var run = b.addRunArtifact(example);
        if (b.args) |args| run.addArgs(args);
        b.step("run-example-" ++ example_name, "Run the " ++ example_name ++ " example").dependOn(&run.step);

        all_example_step.dependOn(&install_example.step);
    }
}
