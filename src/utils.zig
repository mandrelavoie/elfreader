const std = @import("std");
var stdout = std.io.getStdOut().writer();

pub fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch @panic("Cannot write to stdout.");
}

pub fn println(comptime format: []const u8, args: anytype) void {
    print(format ++ "\n", args);
}

pub fn print_bytes(bytes: []const u8) void {
    var first = true;
    for (bytes) |b| {
        if (first) {
            print("{x:0>2}", .{ b });
            first = false;
        } else {
            print(" {x:0>2}", .{ b });
        }
    }
    print("\n", .{});
}

pub fn transmute(comptime T: type, bytes: []const u8) !T {
    if (bytes.len < @sizeOf(T)) {
        return error.InvalidTransmute;
    }
    
    return @intToPtr(*align(1) T, @ptrToInt(bytes.ptr)).*;
}