const std = @import("std");
const panic = @import("builtin").panic;
const Allocator = std.mem.Allocator;
pub const sqliteError = @import("error.zig");
pub const SQLiteError = sqliteError;
pub const checkSqliteErr = sqliteError.checkSqliteErr;

usingnamespace @import("c.zig");

pub const SQLite = struct {
    db: *sqlite3,

    pub fn open(filename: [:0]const u8) !@This() {
        var db: ?*sqlite3 = undefined;

        var rc = sqlite3_open(filename, &db);
        errdefer sqliteError.assertOkay(sqlite3_close(db));

        try checkSqliteErr(rc);

        var dbNonNull = db orelse panic("No error, sqlite db should not be null", null);

        return @This(){
            .db = dbNonNull,
        };
    }

    pub fn close(self: *const @This()) !void {
        try checkSqliteErr(sqlite3_close(self.db));
    }

    pub fn prepare(self: *const @This(), sql: [:0]const u8, sqlTail: ?*[:0]const u8) !?SQLiteStmt {
        var stmt: ?*sqlite3_stmt = undefined;
        const sqlLen = @intCast(c_int, sql.len);
        var tail: ?[*]u8 = undefined;

        var rc = sqlite3_prepare_v2(self.db, sql, sqlLen, &stmt, &tail);

        try checkSqliteErr(rc);

        if (tail) |cTail| {
            if (sqlTail) |sqlTailNotNull| {
                const offset = @ptrToInt(cTail) - @ptrToInt(sql.ptr);
                sqlTailNotNull.* = sql[offset..];
            }
        }

        return SQLiteStmt{
            .stmt = stmt orelse return null,
        };
    }
};

pub const SQLiteStmt = struct {
    stmt: *sqlite3_stmt,

    pub fn step(self: *const SQLiteStmt) !void {
        try checkSqliteErr(sqlite3_step(self.stmt));
    }

    pub fn finalize(self: *const SQLiteStmt) !void {
        try checkSqliteErr(sqlite3_finalize(self.stmt));
    }
};

test "open in memory sqlite db" {
    const db = try SQLite.open(":memory:");

    const sqlCreateTable = "CREATE TABLE IF NOT EXISTS hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);";
    const create_stmt = (try db.prepare(sqlCreateTable, null)) orelse return error.NullCreateStmt;
    try create_stmt.step();
    try create_stmt.finalize();

    const sql =
        \\ INSERT INTO hello (name) VALUES ("world"), ("foo");
        \\ SELECT * FROM hello;
    ;
    var tailSql: [:0]const u8 = sql;

    while (true) {
        const curSql = tailSql;

        const cur_stmt = (try db.prepare(curSql, &tailSql)) orelse break;
        try cur_stmt.finalize();
    }

    try db.close();
}

test "Empty SQL prepared" {
    const db = try SQLite.open(":memory:");
    const create_stmt = try db.prepare("", null);
    std.debug.assert(create_stmt == null);

    try db.close();
}
