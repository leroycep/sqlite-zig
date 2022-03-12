const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
pub const errors = @import("error.zig");
pub const Error = errors.Error;
pub const Success = errors.Success;
pub const checkSqliteErr = errors.checkSqliteErr;
const bind = @import("bind.zig");

const c = @import("c.zig");

/// Workaround Zig translate-c not being able to translate SQLITE_TRANSIENT into an actual value
const S: isize = -1;
const ZIG_SQLITE_TRANSIENT: fn (?*anyopaque) callconv(.C) void = @intToPtr(fn (?*anyopaque) callconv(.C) void, @bitCast(usize, S));

pub const Db = struct {
    db: *c.sqlite3,

    pub fn open(filename: [:0]const u8) Error!@This() {
        var db: ?*c.sqlite3 = undefined;

        var rc = c.sqlite3_open(filename, &db);
        errdefer errors.assertOkay(c.sqlite3_close(db));

        _ = try checkSqliteErr(rc);

        var dbNonNull = db orelse panic("No error, sqlite db should not be null", .{});

        return @This(){
            .db = dbNonNull,
        };
    }

    pub const OpenOptions = struct {
        mode: enum { readonly, readwrite, readwrite_create } = .readwrite_create,
        interpret_as_uri: bool = false,
        in_memory: bool = false,
        threading: ?enum { no_mutex, full_mutex } = null,
        cache: ?enum { shared, private } = null,
        vfs_module: ?[:0]const u8 = null,
    };

    pub fn openWithOptions(filename: [:0]const u8, options: OpenOptions) Error!@This() {
        var db: ?*c.sqlite3 = undefined;

        var option_flags: c_int = switch (options.mode) {
            .readonly => c.SQLITE_OPEN_READONLY,
            .readwrite => c.SQLITE_OPEN_READWRITE,
            .readwrite_create => c.SQLITE_OPEN_READWRITE | c.SQLITE_OPEN_CREATE,
        };
        if (options.interpret_as_uri) option_flags |= c.SQLITE_OPEN_URI;
        if (options.in_memory) option_flags |= c.SQLITE_OPEN_MEMORY;
        if (options.threading) |threading| {
            option_flags |= @as(c_int, switch (threading) {
                .no_mutex => c.SQLITE_OPEN_NOMUTEX,
                .full_mutex => c.SQLITE_OPEN_FULLMUTEX,
            });
        }
        if (options.cache) |cache| {
            option_flags |= @as(c_int, switch (cache) {
                .shared => c.SQLITE_OPEN_SHAREDCACHE,
                .private => c.SQLITE_OPEN_PRIVATECACHE,
            });
        }
        var rc = c.sqlite3_open_v2(filename, &db, option_flags, options.vfs_module orelse 0);
        errdefer errors.assertOkay(c.sqlite3_close(db));

        _ = try checkSqliteErr(rc);

        var dbNonNull = db orelse panic("No error, sqlite db should not be null", .{});

        return @This(){
            .db = dbNonNull,
        };
    }

    pub fn close(self: *const @This()) Error!void {
        _ = try checkSqliteErr(c.sqlite3_close(self.db));
    }

    pub fn errmsg(self: *const @This()) ?[*:0]const u8 {
        return c.sqlite3_errmsg(self.db);
    }

    pub fn prepare(self: *const @This(), sql: [:0]const u8, sqlTail: ?*[:0]const u8) Error!?Stmt {
        var stmt: ?*c.sqlite3_stmt = null;
        const sqlLen = @intCast(c_int, sql.len + 1);
        var tail: ?[*]u8 = undefined;

        var rc = c.sqlite3_prepare_v2(self.db, sql, sqlLen, &stmt, &tail);

        _ = try checkSqliteErr(rc);

        if (tail) |cTail| {
            if (sqlTail) |sqlTailNotNull| {
                const offset = @ptrToInt(cTail) - @ptrToInt(sql.ptr);
                sqlTailNotNull.* = sql[offset..];
            }
        }

        return Stmt{
            .stmt = stmt orelse return null,
        };
    }

    pub fn exec(self: *const @This(), sql: [:0]const u8) RowsIterator {
        return RowsIterator.init(self, sql);
    }

    pub fn execBind(self: *const @This(), comptime sql: [:0]const u8, args: anytype) !RowsIterator {
        var tail: [:0]const u8 = sql;
        var stmtOpt = try self.prepare(sql, &tail);
        if (stmtOpt) |stmt| {
            errdefer stmt.finalize() catch {};
            try bind.bind(&stmt, sql, args);
        }
        return RowsIterator{ .db = self, .remaingSql = tail, .stmt = stmtOpt };
    }
};

pub const Stmt = struct {
    stmt: *c.sqlite3_stmt,

    pub fn step(self: *const Stmt) Error!Success {
        return try checkSqliteErr(c.sqlite3_step(self.stmt));
    }

    pub fn columnCount(self: *const Stmt) c_int {
        return c.sqlite3_column_count(self.stmt);
    }

    pub fn columnType(self: *const Stmt, col: c_int) TypeTag {
        switch (c.sqlite3_column_type(self.stmt, col)) {
            c.SQLITE_INTEGER => return .Integer,
            c.SQLITE_FLOAT => return .Float,
            c.SQLITE_TEXT => return .Text,
            c.SQLITE_BLOB => return .Blob,
            c.SQLITE_NULL => return .Null,
            else => panic("Unexpected sqlite datatype", .{}),
        }
    }

    pub fn column(self: *const Stmt, col: c_int) Type {
        switch (self.columnType(col)) {
            .Integer => return Type{ .Integer = self.columnInt64(col) },
            .Float => return Type{ .Float = self.columnFloat(col) },
            .Text => return Type{ .Text = self.columnText(col) },
            .Blob => return Type{ .Blob = self.columnBlob(col) },
            .Null => return Type{ .Null = {} },
        }
    }

    pub fn columnInt(self: *const Stmt, col: c_int) i32 {
        return c.sqlite3_column_int(self.stmt, col);
    }

    pub fn columnInt64(self: *const Stmt, col: c_int) i64 {
        return c.sqlite3_column_int64(self.stmt, col);
    }

    pub fn columnFloat(self: *const Stmt, col: c_int) f64 {
        return c.sqlite3_column_double(self.stmt, col);
    }

    pub fn columnText(self: *const Stmt, col: c_int) []const u8 {
        const num_bytes = c.sqlite3_column_bytes(self.stmt, col);
        const bytes = c.sqlite3_column_text(self.stmt, col);
        return bytes[0..@intCast(usize, num_bytes)];
    }

    pub fn columnBlob(self: *const Stmt, col: c_int) []const u8 {
        const num_bytes = c.sqlite3_column_bytes(self.stmt, col);
        const bytes = @ptrCast([*]const u8, c.sqlite3_column_blob(self.stmt, col));
        return bytes[0..@intCast(usize, num_bytes)];
    }

    pub fn bindInt(self: *const Stmt, paramIdx: c_int, number: i32) Error!void {
        _ = try checkSqliteErr(c.sqlite3_bind_int(self.stmt, paramIdx, number));
    }

    pub fn bindInt64(self: *const Stmt, paramIdx: c_int, number: i64) Error!void {
        _ = try checkSqliteErr(c.sqlite3_bind_int64(self.stmt, paramIdx, number));
    }

    pub fn bindText(self: *const Stmt, paramIdx: c_int, text: []const u8) Error!void {
        _ = try checkSqliteErr(c.sqlite3_bind_text(self.stmt, paramIdx, text.ptr, @intCast(c_int, text.len), ZIG_SQLITE_TRANSIENT));
    }

    pub fn bindBlob(self: *const Stmt, paramIdx: c_int, bytes: []const u8) Error!void {
        _ = try checkSqliteErr(c.sqlite3_bind_blob(self.stmt, paramIdx, bytes.ptr, @intCast(c_int, bytes.len), ZIG_SQLITE_TRANSIENT));
    }

    pub fn finalize(self: *const Stmt) Error!void {
        _ = try checkSqliteErr(c.sqlite3_finalize(self.stmt));
    }
};

pub const TypeTag = enum {
    Integer,
    Float,
    Text,
    Blob,
    Null,
};

pub const Type = union(TypeTag) {
    Integer: i64,
    Float: f64,
    Text: []const u8,
    Blob: []const u8,
    Null: void,

    pub fn int(number: i64) @This() {
        return .{ .Integer = number };
    }

    pub fn text(str: []const u8) @This() {
        return .{ .Text = str };
    }

    pub fn eql(self: *const Type, other: *const Type) bool {
        if (@as(TypeTag, self.*) != @as(TypeTag, other.*)) {
            return false;
        }
        switch (self.*) {
            // Types must be same, and any null is the same as any other null
            .Null => return true,
            .Integer => return self.Integer == other.Integer,
            .Float => return self.Float == other.Float,
            .Text => return std.mem.eql(u8, self.Text, other.Text),
            .Blob => return std.mem.eql(u8, self.Blob, other.Blob),
        }
    }
};

pub const Row = struct {
    stmt: Stmt,

    pub fn columnCount(self: *const @This()) c_int {
        return self.stmt.columnCount();
    }

    pub fn column(self: *const @This(), col: c_int) Type {
        return self.stmt.column(col);
    }

    pub fn columnInt(self: *const @This(), col: c_int) i32 {
        return self.stmt.columnInt(col);
    }

    pub fn columnInt64(self: *const @This(), col: c_int) i64 {
        return self.stmt.columnInt64(col);
    }

    pub fn columnText(self: *const @This(), col: c_int) []const u8 {
        return self.stmt.columnText(col);
    }

    pub fn columnBlob(self: *const @This(), col: c_int) []const u8 {
        return self.stmt.columnBlob(col);
    }
};

pub const RowsIterator = struct {
    db: *const Db,
    remaingSql: [:0]const u8,
    stmt: ?Stmt = null,

    pub fn init(db: *const Db, sql: [:0]const u8) RowsIterator {
        var self: @This() = .{
            .db = db,
            .remaingSql = sql,
        };
        return self;
    }

    // An error will only be returned if the most recent evaluation failed
    pub fn finalize(this: *@This()) !void {
        try this.finalizeStmt();
    }

    pub const Item = union(enum) {
        Row: Row,
        Done: void,
    };

    pub fn next(self: *@This()) !?Item {
        if (self.stmt == null) {
            try self.prepareNextStmt();
        }
        if (self.stmt) |stmt| {
            const step_res = try stmt.step();
            switch (step_res) {
                .Row, .Ok => return Item{ .Row = Row{ .stmt = stmt } },
                .Done => {
                    try self.finalizeStmt();
                    return Item{ .Done = .{} };
                },
            }
        } else {
            return null;
        }
    }

    pub fn finish(self: *@This()) !void {
        while (try self.next()) |_| {}
    }

    fn finalizeStmt(self: *@This()) !void {
        if (self.stmt) |stmt| {
            try stmt.finalize();
            self.stmt = null;
        }
    }

    fn prepareNextStmt(self: *@This()) !void {
        if (self.stmt != null) {
            try self.finalizeStmt();
        }
        const curSql = self.remaingSql;
        self.stmt = try self.db.prepare(curSql, &self.remaingSql);
    }
};

test "open in memory sqlite db" {
    const db = try Db.open(":memory:");

    // Create the hello table
    const sqlCreateTable = "CREATE TABLE hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);";
    const create_stmt = (try db.prepare(sqlCreateTable, null)) orelse return error.NullCreateStmt;
    _ = try create_stmt.step();
    _ = try create_stmt.finalize();

    // Insert values and get results
    const sql =
        \\ INSERT INTO hello (name) VALUES ("world"), ("foo");
        \\ SELECT * FROM hello;
    ;
    var tailSql: [:0]const u8 = sql;

    while (true) {
        const curSql = tailSql;

        const cur_stmt = (try db.prepare(curSql, &tailSql)) orelse break;
        var row: usize = 0;
        while ((try cur_stmt.step()) != .Done) {
            var col: c_int = 0;
            while (col < cur_stmt.columnCount()) {
                const val = cur_stmt.column(col);
                switch (row) {
                    0 => switch (col) {
                        0 => std.testing.expectEqual(Type{ .Integer = 1 }, val),
                        1 => std.testing.expect(Type.text("world").eql(&val)),
                        else => panic("unexpected col in test", .{}),
                    },
                    1 => switch (col) {
                        0 => std.testing.expectEqual(Type{ .Integer = 2 }, val),
                        1 => std.testing.expect(Type.text("foo").eql(&val)),
                        else => panic("unexpected col in test", .{}),
                    },
                    else => panic("unexpected row in test", .{}),
                }
                col += 1;
            }
            row += 1;
        }
        try cur_stmt.finalize();
    }

    try db.close();
}

test "Empty SQL prepared" {
    const db = try Db.open(":memory:");
    const create_stmt = try db.prepare("", null);
    std.debug.assert(create_stmt == null);

    try db.close();
}

test "exec function" {
    const db = try Db.open(":memory:");

    // Create the hello table
    try db.exec("CREATE TABLE hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);").finish();
    // Insert values and get results
    try db.exec("INSERT INTO hello (name) VALUES (\"world\"), (\"foo\");").finish();

    const expected = [_][2]Type{
        .{ Type.int(1), Type.text("world") },
        .{ Type.int(2), Type.text("foo") },
    };

    var rows = db.exec("SELECT * FROM hello;");
    defer rows.finalize() catch {};

    var rowIdx: usize = 0;
    while (try rows.next()) |rows_item| {
        const row = switch (rows_item) {
            .Row => |r| r,
            .Done => continue,
        };
        const expectedRow = expected[rowIdx];

        var colIdx: usize = 0;
        while (colIdx < row.columnCount()) {
            const col = row.column(@intCast(c_int, colIdx));
            const expectedCol = expectedRow[colIdx];
            std.testing.expect(expectedCol.eql(&col));

            colIdx += 1;
        }

        rowIdx += 1;
    }

    try db.close();
}

test "exec multiple statement" {
    const db = try Db.open(":memory:");

    const expected = [_][2]Type{
        .{ Type.int(1), Type.text("world") },
        .{ Type.int(2), Type.text("foo") },
    };

    // Create the hello table, insert test values, and get results
    var rows = db.exec(
        \\ CREATE TABLE hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);
        \\ INSERT INTO hello (name) VALUES ("world"), ("foo");
        \\ SELECT * FROM hello;
    );
    defer rows.finalize() catch {};

    var rowIdx: usize = 0;
    while (try rows.next()) |rows_item| {
        const row = switch (rows_item) {
            .Row => |r| r,
            .Done => continue,
        };
        const expectedRow = expected[rowIdx];

        var colIdx: usize = 0;
        while (colIdx < row.columnCount()) {
            const col = row.column(@intCast(c_int, colIdx));
            const expectedCol = expectedRow[colIdx];
            std.testing.expect(expectedCol.eql(&col));

            colIdx += 1;
        }

        rowIdx += 1;
    }

    std.testing.expectEqual(@as(usize, 2), rowIdx);

    try db.close();
}

test "bind parameters" {
    const db = try Db.open(":memory:");
    try db.exec("CREATE TABLE hello (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);").finish();

    const NAME = "world!";
    const NAME2 = "foo";

    const insert = (try db.prepare("INSERT INTO hello (name) VALUES (?);", null)).?;
    try insert.bindText(1, NAME);
    _ = try insert.step();
    try insert.finalize();

    try (try db.execBind("INSERT INTO hello (name) VALUES (?);", .{NAME2})).finish();

    var rows = db.exec("SELECT name FROM hello;");
    defer rows.finalize() catch {};
    std.testing.expect((try rows.next()).?.Row.column(0).eql(&Type.text(NAME)));
    std.testing.expect((try rows.next()).?.Row.column(0).eql(&Type.text(NAME2)));
    std.testing.expect((try rows.next()).? == .Done);
    std.testing.expect((try rows.next()) == null);

    try db.close();
}
