const panic = @import("builtin").panic;
const std = @import("std");
const sqlite = @import("sqlite");

const SQL_CREATE_TABLE =
    \\ CREATE TABLE IF NOT EXISTS posts(
    \\   id INTEGER PRIMARY KEY AUTOINCREMENT,
    \\   title TEXT NOT NULL,
    \\   content TEXT NOT NULL
    \\ );
;

const SQL_GET_POSTS = "SELECT id, title, content FROM posts;";

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    const db = try sqlite.SQLite.open("blog.db");
    try initDB(&db);

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        return;
    }

    if (std.mem.eql(u8, args[1], "read")) {
        try readPosts(&db);
    }
    if (std.mem.eql(u8, args[1], "delete")) {
        std.debug.warn("delete\n", .{});
    }
}

fn initDB(db: *const sqlite.SQLite) !void {
    const create_stmt_opt = db.prepare(SQL_CREATE_TABLE, null) catch |e| {
        std.debug.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
        return e;
    };
    const create_stmt = create_stmt_opt orelse panic("Create table statment was null!", null);
    _ = try create_stmt.step();
    _ = try create_stmt.finalize();
}

fn readPosts(db: *const sqlite.SQLite) !void {
    const read_stmt_opt = db.prepare(SQL_GET_POSTS, null) catch |e| {
        std.debug.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
        return e;
    };
    const read_stmt = read_stmt_opt orelse panic("Read post statement was null!", null);

    std.debug.warn("Posts:\n", .{});
    while ((try read_stmt.step()) != .Done) {
        const id = read_stmt.columnInt64(0);
        const title = read_stmt.columnText(1);
        const content = read_stmt.columnText(2);
        std.debug.warn("\t{} {}: {}\n", .{ id, title, content });
    }

    _ = try read_stmt.finalize();
}
