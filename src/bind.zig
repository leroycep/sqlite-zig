const std = @import("std");
const errors = @import("error.zig");
const Error = errors.Error;
const checkSqliteErr = errors.checkSqliteErr;
const Stmt = @import("sqlite.zig").Stmt;

usingnamespace @import("c.zig");

pub fn bind(stmt: *const Stmt, comptime sql: [:0]const u8, args: anytype) Error!void {
    // TODO: Make this more robust. Make it clear that SQL is not actually being parsed
    comptime var nextArg = 0;
    inline for (sql) |c| {
        if (c == '?') {
            const arg = args[nextArg];
            const argIdx = nextArg + 1;
            try bindType(stmt, argIdx, arg);
            nextArg += 1;
        }
    }
    comptime {
        if (nextArg != args.len) {
            @compileError("Unused arguments");
        }
    }
}

pub fn bindType(stmt: *const Stmt, comptime paramIdx: comptime_int, value: anytype) Error!void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        .Int => {
            try stmt.bindInt64(paramIdx, value);
        },
        .Pointer => |ptr_info| switch (ptr_info.size) {
            .One => switch (@typeInfo(ptr_info.child)) {
                .Array => |info| {
                    if (info.child == u8) {
                        return try stmt.bindText(paramIdx, value);
                    }
                    @compileError("Not yet implement");
                },
                else => @compileError("Not yet implement"),
            },
            .Slice => {
                if (ptr_info.child == u8) {
                    return try stmt.bindText(paramIdx, value);
                }
                @compileError("Not yet implemented");
            },
            else => @compileError("Not yet implemented"),
        },
        .Array => |arr| {
            if (arr.child == u8) {
                stmt.bindText(paramIdx, value);
            } else {
                @compileError("Arrays of type " ++ @typeName(arr.child) ++ " are not supported.");
            }
        },
        else => @compileError("Binding type of " ++ @typeName(T) ++ " is not supported."),
    }
}
