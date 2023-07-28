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

    pub fn setup_project(self: Cpmk) !void {
        if (!self.is_valid()) {
            try stdout.print("Invalid language: {s}\n", .{self.language.*});
            try stdout.print("Valid languages: c, cpp\n", .{});

            return;
        }

        var cwd = std.fs.cwd();

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        try self.create_directories(cwd, allocator);
        try self.create_files(cwd, allocator);

        try stdout.print("Project {s} created successfully!\n", .{self.project_name.*});
    }

    fn is_valid(self: Cpmk) bool {
        return std.mem.eql(u8, self.language.*, "c") or std.mem.eql(u8, self.language.*, "cpp");
    }

    fn create_directories(self: Cpmk, cwd: std.fs.Dir, allocator: std.mem.Allocator) !void {
        try cwd.makeDir(self.project_name.*);
        const src_dir = try std.fmt.allocPrint(allocator, "{s}/src", .{self.project_name.*});
        try cwd.makeDir(src_dir);
    }

    fn create_files(self: Cpmk, cwd: std.fs.Dir, allocator: std.mem.Allocator) !void {
        var src_file: []u8 = undefined;
        var src_content: []u8 = undefined;
        var cmake_c: []u8 = "";
        if (std.mem.eql(u8, self.language.*, "c")) {
            src_file = try std.fmt.allocPrint(allocator, "{s}/src/main.c", .{self.project_name.*});
            src_content = try std.fmt.allocPrint(allocator,
                \\#include <stdio.h>
                \\
                \\int main(void) {{
                \\  printf("Hello, world!\n");
                \\
                \\  return 0;
                \\}}
            , .{});
            cmake_c = try std.fmt.allocPrint(allocator,
                \\set(CMAKE_C_STANDARD 17)
                \\set(CMAKE_C_STANDARD_REQUIRED True)
                \\set(CMAKE_C_FLAGS "-Wall -Wextra -Werror")
                \\
                \\
            , .{});
        } else {
            src_file = try std.fmt.allocPrint(allocator, "{s}/src/main.cpp", .{self.project_name.*});
            src_content = try std.fmt.allocPrint(allocator,
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

        var cmake_file = try std.fmt.allocPrint(allocator, "{s}/CMakeLists.txt", .{self.project_name.*});
        var cmake_content = try std.fmt.allocPrint(allocator,
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
        , .{ self.project_name.*, cmake_c });
        try cwd.writeFile(cmake_file, cmake_content);

        var cmake_src_file = try std.fmt.allocPrint(allocator, "{s}/src/CMakeLists.txt", .{self.project_name.*});
        var cmake_src_content = try std.fmt.allocPrint(allocator,
            \\cmake_minimum_required(VERSION 3.10.0)
            \\
            \\add_executable(
            \\  {s}
            \\  main.{s}
            \\)
        , .{ self.project_name.*, self.language.* });

        try cwd.writeFile(cmake_src_file, cmake_src_content);
    }
};
