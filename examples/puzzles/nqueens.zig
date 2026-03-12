const std = @import("std");
const z3 = @import("z3_sys");
const Context = z3.Context;
const Config = z3.Config;

// TODO: actually write nqueens or some other minimal test
pub fn main() !void {
    // Print Z3 version
    const ver = Context.getVersion();
    std.debug.print("Z3 version: {}.{}.{}\n", .{ ver.major, ver.minor, ver.build });

    // Basic SAT example: find x, y : Int s.t. x + y = 10 && x > 3
    const cfg = Config.init();
    defer cfg.deinit();

    const ctx = Context.init(cfg);
    defer ctx.deinit();

    const solver = ctx.mkSolver();
    defer solver.deinit();

    const x = ctx.intConst("x");
    const y = ctx.intConst("y");
    const ten = ctx.mkInt(10);
    const three = ctx.mkInt(3);

    // x + y == 10
    solver.assert(x.add(y).eq(ten));
    // x > 3
    solver.assert(x.gt(three));

    const result = solver.check();
    std.debug.print("Check result: {s}\n", .{@tagName(result)});

    if (result == .sat) {
        if (solver.getModel()) |model| {
            defer model.deinit();
            std.debug.print("Model:\n{s}\n", .{model.toString() orelse "(null)"});
        }
    }
}
