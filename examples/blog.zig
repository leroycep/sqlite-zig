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
const SQL_GET_POST_BY_ID = "SELECT id, title, content FROM posts WHERE id = ?;";
const SQL_GET_LAST_INSERTED = "SELECT id, title, content FROM posts WHERE id = last_insert_rowid();";

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

    var readOpts = ReadOptions{};
    if (std.mem.eql(u8, args[1], CMD_READ_POSTS) and args.len == 3) {
        const postId = std.fmt.parseInt(i64, args[2], 10) catch {
            std.debug.warn("Invalid post id\nUsage: {} read [post-id]", .{args[0]});
            return error.NotAnInt;
        };
        readOpts.singlePost = GetPostBy{ .Id = postId };
    } else if (std.mem.eql(u8, args[1], CMD_CREATE_POST)) {
        if (args.len != 4) {
            std.debug.warn("Error: wrong number of args\nUsage: {} create <title> <content>\n", .{args[0]});
            return;
        }

        var exec = try db.execBind(SQL_INSERT_POST, .{ args[2], args[3] });
        try exec.finish();
        readOpts.singlePost = GetPostBy{ .LastInserted = {} };
    }

    var stdout = std.io.getStdOut().outStream().stream;

    try read(&stdout, &db, readOpts);
}

fn printSqliteErrMsg(db: *const sqlite.SQLite, e: sqlite.SQLiteError) !void {
    std.debug.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
    return e;
}

const GetPostByTag = enum {
    Id,
    LastInserted,
};
const GetPostBy = union(GetPostByTag) {
    Id: i64,
    LastInserted: void,
};

const ReadOptions = struct {
    singlePost: ?GetPostBy = null,
};

fn read(out: *std.io.OutStream(std.os.WriteError), db: *const sqlite.SQLite, opts: ReadOptions) !void {
    if (opts.singlePost) |post| {
        var rows: sqlite.SQLiteRowsIterator = undefined;
        switch (post) {
            .Id => |postId| rows = try db.execBind(SQL_GET_POST_BY_ID, .{postId}),
            .LastInserted => rows = db.exec(SQL_GET_LAST_INSERTED),
        }

        const row = rows.next() orelse {
            std.debug.warn("No post with id '{}'\n", .{post});
            return error.InvalidPostId;
        } catch unreachable;
        try displaySinglePost(out, &row);

        try rows.finish();
    } else {
        var rows = db.exec(SQL_GET_POSTS);

        std.debug.warn("Posts:\n", .{});
        while (rows.next()) |row_erropt| {
            const row = row_erropt catch |e| return printSqliteErrMsg(db, e);
            const id = row.columnInt64(0);
            const title = row.columnText(1);
            const content = row.columnText(2);
            std.debug.warn("\t{}\t{}\t{}\n", .{ id, title, content });
        }
    }
}

fn displaySinglePost(out: *std.io.OutStream(std.os.WriteError), row: *const sqlite.SQLiteRow) !void {
    const id = row.columnInt64(0);
    const title = row.columnText(1);
    const content = row.columnText(2);
    try out.print(
        \\ Id: {}
        \\ Title: {}
        \\
        \\ {}
        \\
    , .{ id, title, content });
}
