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

const SQL_UPDATE_POST =
    \\ UPDATE
    \\   posts
    \\ SET
    \\   title = ?,
    \\   content = ?
    \\ WHERE id = ?;
;

const SQL_DELETE_POST = "DELETE FROM posts WHERE id = ?;";

const CMD_CREATE_POST = "create";
const CMD_READ_POSTS = "read";
const CMD_UPDATE_POST = "update";
const CMD_DELETE_POST = "delete";

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    const db = try sqlite.Db.open("blog.db");
    defer db.close() catch unreachable;

    // Create the posts table if it doesn't exist
    db.exec(SQL_CREATE_TABLE).finish() catch |e| return printSqliteErrMsg(&db, e);

    // Get commandline arguments
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len < 2) {
        std.debug.warn(
            \\ Incorrect usage.
            \\ Usage: {s} <cmd>
            \\ Possible commands:
            \\   {s}
            \\   {s}
            \\   {s}
            \\   {s}
            \\
        , .{ args[0], CMD_CREATE_POST, CMD_READ_POSTS, CMD_UPDATE_POST, CMD_DELETE_POST });
        return;
    }

    var readOpts = ReadOptions{};
    if (std.mem.eql(u8, args[1], CMD_READ_POSTS) and args.len == 3) {
        const postId = std.fmt.parseInt(i64, args[2], 10) catch {
            std.debug.warn("Invalid post id\nUsage: {s} read [post-id]", .{args[0]});
            return error.NotAnInt;
        };
        readOpts.singlePost = GetPostBy{ .Id = postId };
    } else if (std.mem.eql(u8, args[1], CMD_CREATE_POST)) {
        if (args.len != 4) {
            std.debug.warn("Error: wrong number of args\nUsage: {s} create <title> <content>\n", .{args[0]});
            return;
        }

        var exec = try db.execBind(SQL_INSERT_POST, .{ args[2], args[3] });
        try exec.finish();
        readOpts.singlePost = GetPostBy{ .LastInserted = {} };
    } else if (std.mem.eql(u8, args[1], CMD_UPDATE_POST)) {
        if (args.len != 5) {
            std.debug.warn("Not enough arguments\nUsage: {s} update <post-id> <title> <content>\n", .{args[0]});
            return error.NotEnoughArguments;
        }
        const id = std.fmt.parseInt(i64, args[2], 10) catch {
            std.debug.warn("Invalid post id\nUsage: {s} update <post-id> <title> <content>\n", .{args[0]});
            return error.NotAnInt;
        };
        const title = args[3];
        const content = args[4];

        var exec = try db.execBind(SQL_UPDATE_POST, .{ title, content, id });
        try exec.finish();

        readOpts.singlePost = GetPostBy{ .Id = id };
    } else if (std.mem.eql(u8, args[1], CMD_DELETE_POST)) {
        if (args.len != 3) {
            std.debug.warn("Not enough arguments\nUsage: {s} delete <post-id>\n", .{args[0]});
            return error.WrongNumberOfArguments;
        }
        const id = std.fmt.parseInt(i64, args[2], 10) catch {
            std.debug.warn("Invalid post id\nUsage: {s} delete <post-id>\n", .{args[0]});
            return error.NotAnInt;
        };

        var exec = try db.execBind(SQL_DELETE_POST, .{id});
        try exec.finish();
    }

    const stdout = &std.io.getStdOut().writer();

    try read(stdout, &db, readOpts);
}

fn printSqliteErrMsg(db: *const sqlite.Db, e: sqlite.Error) !void {
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

fn read(out: anytype, db: *const sqlite.Db, opts: ReadOptions) !void {
    if (opts.singlePost) |post| {
        var rows: sqlite.RowsIterator = undefined;
        switch (post) {
            .Id => |postId| rows = try db.execBind(SQL_GET_POST_BY_ID, .{postId}),
            .LastInserted => rows = db.exec(SQL_GET_LAST_INSERTED),
        }
        defer rows.finalize() catch {};

        const item = (try rows.next()) orelse {
            std.debug.warn("No post with id '{}'\n", .{post});
            return error.InvalidPostId;
        };
        try displaySinglePost(out, &item.Row);

        try rows.finish();
    } else {
        var rows = db.exec(SQL_GET_POSTS);
        defer rows.finalize() catch {};

        try out.print("Posts:\n", .{});
        while (try rows.next()) |row_item| {
            const row = switch (row_item) {
                .Row => |r| r,
                .Done => continue,
            };
            const id = row.columnInt64(0);
            const title = row.columnText(1);
            const content = row.columnText(2);
            try out.print("\t{}\t{s}\t{s}\n", .{ id, title, content });
        }
    }
}

fn displaySinglePost(out: anytype, row: *const sqlite.Row) !void {
    const id = row.columnInt64(0);
    const title = row.columnText(1);
    const content = row.columnText(2);
    try out.print(
        \\ Id: {}
        \\ Title: {s}
        \\
        \\ {s}
        \\
    , .{ id, title, content });
}
