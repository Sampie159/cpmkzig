const std = @import("std");
const clap = @import("clap");
const Cpmk = @import("cpmk.zig").Cpmk;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-l, --language <LANG>          "Language to use in the new project: c or cpp"
        \\-p, --project_name <PROJ_NAME> "Name of the new project"
        \\-h, --help                     "Prints help information"
    );

    const parsers = comptime .{
        .LANG = clap.parsers.string,
        .PROJ_NAME = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        std.debug.print(
            \\Usage: cpmk [OPTIONS]
            \\
            \\Options:
            \\  -l, --language <LANG>          Language to use in the new project: c or cpp
            \\  -p, --project_name <PROJ_NAME> Name of the new project
            \\  -h, --help                     Prints help information
            \\
        , .{});
        return;
    }

    var lang = res.args.language orelse {
        std.debug.print("Missing required argument: --language\n", .{});
        return;
    };

    var project_name = res.args.project_name orelse {
        std.debug.print("Missing required argument: --project_name\n", .{});
        return;
    };

    const cpmk = Cpmk.new(&lang, &project_name);
    try cpmk.setup_project();
}
