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

    pub fn close(self: *const @This()) void {
        sqliteAssertOkay(sqlite3_close(self.db));
    }

    pub fn prepare(self: *const @This(), sql: [:0]const u8, sqlTail: ?*[:0]const u8) !?SQLiteStmt {
        var stmt: ?*sqlite3_stmt = undefined;
        const sqlLen = @intCast(c_int, sql.len);
        var tail: ?[*]u8 = undefined;

        var rc = sqlite3_prepare_v2(self.db, sql, sqlLen, &stmt, &tail);

        if (rc != SQLITE_OK) {
            return error.PrepareFailed;
        }

        return SQLiteStmt{
            .stmt = stmt orelse return null,
        };
    }
};

pub const SQLiteStmt = struct {
    stmt: *sqlite3_stmt,

    pub fn finalize(self: *const SQLiteStmt) void {
        sqliteAssertOkay(sqlite3_finalize(self.stmt));
    }
};

fn sqliteAssertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        panic("SQLite returned an error code", null);
    }
}

test "open in memory sqlite db" {
    const db = try SQLite.open(":memory:");
    defer db.close();

    const sqlCreateTable = "CREATE TABLE IF NOT EXISTS hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);";
    const sql =
        \\ INSERT INTO hello (name) VALUES ("world"), ("foo");
        \\ SELECT * FROM hello;
    ;

    const create_stmt = (try db.prepare(sqlCreateTable, null)) orelse return error.NullCreateStmt;
    defer create_stmt.finalize();
}
