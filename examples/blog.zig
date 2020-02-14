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

const SQL_INSERT_POST =
    \\ INSERT INTO
    \\   posts(title, content)
    \\ VALUES
    \\   (?, ?)
    \\ ;
;

const CMD_CREATE_POST = "create";
const CMD_READ_POSTS = "read";

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    const db = try sqlite.SQLite.open("blog.db");
    defer db.close() catch unreachable;

    // Create the posts table if it doesn't exist
    db.exec(SQL_CREATE_TABLE).finish() catch |e| return printSqliteErrMsg(&db, e);

    // Get commandline arguments
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len < 2) {
        std.debug.warn(
            \\ Incorrect usage.
            \\ Usage: {} <cmd>
            \\ Possible commands:
            \\   {}
            \\   {}
            \\
        , .{ args[0], CMD_CREATE_POST, CMD_READ_POSTS });
        return;
    }

    if (std.mem.eql(u8, args[1], CMD_READ_POSTS)) {
        var rows = db.exec(SQL_GET_POSTS);

        std.debug.warn("Posts:\n", .{});
        while (rows.next()) |row_erropt| {
            const row = row_erropt catch |e| return printSqliteErrMsg(&db, e);
            const id = row.columnInt64(0);
            const title = row.columnText(1);
            const content = row.columnText(2);
            std.debug.warn("\t{}\t{}\t{}\n", .{ id, title, content });
        }
    } else if (std.mem.eql(u8, args[1], CMD_CREATE_POST)) {
        if (args.len != 4) {
            std.debug.warn("Error: wrong number of args\nUsage: {} create <title> <content>\n", .{args[0]});
            return;
        }

        var exec = try db.execBind(SQL_INSERT_POST, .{ args[2], args[3] });
        try exec.finish();
    }
}

fn printSqliteErrMsg(db: *const sqlite.SQLite, e: sqlite.SQLiteError) !void {
    std.debug.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
    return e;
}
