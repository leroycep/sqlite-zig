const std = @import("std");
pub const sqliteError = @import("error.zig");
pub const SQLiteError = sqliteError.SQLiteError;
pub const SQLiteResult = sqliteError.SQLiteResult;
pub const checkSqliteErr = sqliteError.checkSqliteErr;
pub const SQLiteStmt = @import("sqlite.zig").SQLiteStmt;

usingnamespace @import("c.zig");

pub fn bind(stmt: *const SQLiteStmt, comptime sql: [:0]const u8, args: var) SQLiteError!void {
    // TODO: Make this more robust. Make it clear that SQL is not actually being parsed
    comptime var nextArg = 0;
    inline for (sql) |c| {
        if (c == '?') {
            const arg = args[nextArg];
            comptime const argIdx = nextArg + 1;
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

pub fn bindType(stmt: *const SQLiteStmt, comptime paramIdx: comptime_int, value: var) SQLiteError!void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
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
        else => |typeInfo| @compileError("Binding type of " ++ @typeName(T) ++ " is not supported."),
    }
}
