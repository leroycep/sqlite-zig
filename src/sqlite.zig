const std = @import("std");
const panic = @import("builtin").panic;
const Allocator = std.mem.Allocator;

usingnamespace @import("c.zig");

pub const SQLiteError = enum {};

pub const SQLite = struct {
    db: *sqlite3,

    pub fn open(filename: [:0]const u8) !@This() {
        var db: ?*sqlite3 = undefined;

        var rc = sqlite3_open(filename, &db);
        errdefer sqliteAssertOkay(sqlite3_close(db));

        if (rc != SQLITE_OK) {
            return error.OpenFailed;
        }

        var dbNonNull = db orelse return error.OpenFailed;

        return @This(){
            .db = dbNonNull,
        };
    }
};

fn sqliteAssertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        panic("SQLite returned an error code", null);
    }
}

test "open in memory sqlite db" {
    const db = SQLite.open(":memory:");
}
