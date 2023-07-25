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

    try stdout.print("Project {s} created successfully!\n", .{cpmk.project_name.*});
}

fn is_valid(language: *[]const u8) bool {
    return std.mem.eql(u8, language.*, "c") or std.mem.eql(u8, language.*, "cpp");
}

fn create_directories(cwd: std.fs.Dir, project_name: *[]const u8) !void {
    try cwd.makeDir(project_name.*);
    const src_dir = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/src", .{project_name.*});
    try cwd.makeDir(src_dir);
}

fn create_files(cwd: std.fs.Dir, cpmk: *Cpmk) !void {
    var src_file: []u8 = undefined;
    var src_content: []u8 = undefined;
    var cmake_c: []u8 = "";
    if (std.mem.eql(u8, cpmk.language.*, "c")) {
        src_file = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/src/main.c", .{cpmk.project_name.*});
        src_content = try std.fmt.allocPrint(std.heap.page_allocator,
            \\#include <stdio.h>
            \\
            \\int main(void) {{
            \\  printf("Hello, world!\n");
            \\
            \\  return 0;
            \\}}
        , .{});
        cmake_c = try std.fmt.allocPrint(std.heap.page_allocator,
            \\set(CMAKE_C_STANDARD 17)
            \\set(CMAKE_C_STANDARD_REQUIRED True)
            \\set(CMAKE_C_FLAGS "-Wall -Wextra -Werror")
            \\
            \\
        , .{});
    } else {
        src_file = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/src/main.cpp", .{cpmk.project_name.*});
        src_content = try std.fmt.allocPrint(std.heap.page_allocator,
            \\#include <iostream>
            \\
            \\int main() {{
            \\  std::cout << "Hello, world!\n";
            \\
            \\  return 0;
            \\}}
        , .{});
    }

    try cwd.writeFile(src_file, src_content);

    var cmake_file = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/CMakeLists.txt", .{cpmk.project_name.*});
    var cmake_content = try std.fmt.allocPrint(std.heap.page_allocator,
        \\cmake_minimum_required(VERSION 3.10.0)
        \\
        \\project({s} VERSION 0.1.0)
        \\
        \\{s}set(CMAKE_CXX_STANDARD 17)
        \\set(CMAKE_CXX_STANDARD_REQUIRED True)
        \\set(CMAKE_CXX_FLAGS "-Wall -Wextra -Werror")
        \\
        \\set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${{CMAKE_BINARY_DIR}}")
        \\
        \\add_subdirectory(src)
    , .{ cpmk.project_name.*, cmake_c });
    try cwd.writeFile(cmake_file, cmake_content);

    var cmake_src_file = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/src/CMakeLists.txt", .{cpmk.project_name.*});
    var cmake_src_content = try std.fmt.allocPrint(std.heap.page_allocator,
        \\cmake_minimum_required(VERSION 3.10.0)
        \\
        \\add_executable(
        \\  {s}
        \\  main.{s}
        \\)
    , .{ cpmk.project_name.*, cpmk.language.* });

    try cwd.writeFile(cmake_src_file, cmake_src_content);
}
