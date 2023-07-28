const std = @import("std");
const cpmk = @import("cpmk.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var args = std.process.args();
    _ = args.next();
    var lang = args.next() orelse {
        try stdout.print("usage: cpmk <lang> <proj_name>\n", .{});
        return;
    };
    var proj_name = args.next() orelse {
        try stdout.print("usage: cpmk <lang> <proj_name>\n", .{});
        return;
    };

    var proj = cpmk.Cpmk.new(&lang, &proj_name);
    try proj.setup_project();
}
