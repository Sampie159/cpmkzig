const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub const Cpmk = struct {
    language: *[]const u8,
    project_name: *[]const u8,

    pub fn new(language: *[]const u8, project_name: *[]const u8) Cpmk {
        return Cpmk{
            .language = language,
            .project_name = project_name,
        };
    }
};

pub fn setup_project(cpmk: *Cpmk) !void {
    if (!is_valid(cpmk.language)) {
        try stdout.print("Invalid language: {s}\n", .{cpmk.language.*});
        try stdout.print("Valid languages: c, cpp\n", .{});

        return;
    }

    var cwd = std.fs.cwd();

    try create_directories(cwd, cpmk.project_name);
    try create_files(cwd, cpmk);
}

fn is_valid(language: *[]const u8) bool {
    return std.mem.eql(u8, language.*, "c") or std.mem.eql(u8, language.*, "cpp");
}

fn create_directories(cwd: std.fs.Dir, project_name: *[]const u8) !void {
    try cwd.makeDir(project_name.*);
    const src_dir = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ project_name.*, "/src" });
    try cwd.makeDir(src_dir);
}

fn create_files(cwd: std.fs.Dir, cpmk: *Cpmk) !void {
    var src_file: []u8 = undefined;
    var src_content: []u8 = undefined;
    if (std.mem.eql(u8, cpmk.language.*, "c")) {
        src_file = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ cpmk.project_name.*, "/src/main.c" });
        src_content = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{
            \\#include <stdio.h>
            \\
            \\int main(void) {
            \\  printf("Hello, world!\n");
            \\
            \\  return 0;
            \\}
        });
    } else if (std.mem.eql(u8, cpmk.language.*, "cpp")) {
        src_file = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ cpmk.project_name.*, "/src/main.cpp" });
        src_content = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{
            \\#include <iostream>
            \\
            \\int main() {
            \\  std::cout << "Hello, world!\n";
            \\  
            \\  return 0;
            \\}
        });
    }

    try cwd.writeFile(src_file, src_content);

    var cmake_file = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ cpmk.project_name.*, "/CMakeLists.txt" });
    var cmake_content =
        \\cmake_minimum_required(VERSION 3.10.0)
        \\
        \\project({cpmk.project_name.*})
    ;
    try cwd.writeFile(cmake_file, cmake_content);
}
