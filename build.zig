const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Z3 Path Resolution
    const z3_include = b.option([]const u8, "z3-include", "Path to z3 headers") orelse
        std.process.getEnvVarOwned(b.allocator, "Z3_INCLUDE") catch "/usr/include";
    const z3_lib = b.option([]const u8, "z3-lib", "Path to z3 lib dir") orelse
        std.process.getEnvVarOwned(b.allocator, "Z3_LIB") catch "/usr/lib";

    // 2. Define your main library module
    const z3_sys_mod = b.addModule("z3-sys", .{
        .root_source_file = b.path("src/z3-sys.zig"),
    });

    // 3. Setup Example Iteration
    const examples_step = b.step("examples", "Build all examples");

    // --- Recursive Walker ---
    var iter_dir = try b.build_root.handle.openDir("examples", .{ .iterate = true });
    var walker = try iter_dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".zig")) continue;

        const file_path = entry.path;
        const exe_name = std.fs.path.stem(file_path);

        const exe = b.addExecutable(.{
            .name = exe_name,
            .use_llvm = true,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt("examples/{s}", .{file_path})),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Link Z3
        exe.addIncludePath(.{ .cwd_relative = z3_include });
        exe.addLibraryPath(.{ .cwd_relative = z3_lib });
        exe.linkSystemLibrary("z3");
        exe.linkLibC();
        exe.root_module.addImport("z3-sys", z3_sys_mod);

        // Build
        const install_exe = b.addInstallArtifact(exe, .{});
        examples_step.dependOn(&install_exe.step);

        // Run step
        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(b.fmt("run-{s}", .{exe_name}), b.fmt("Run {s}", .{file_path}));
        run_step.dependOn(&run_cmd.step);
    }
}
