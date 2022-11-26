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

    const db = try sqlite.SQLite3.open("blog.db");
    defer db.close() catch unreachable;

    // Create the posts table if it doesn't exist
    db.exec(SQL_CREATE_TABLE, null, null, null) catch |e| return printSqliteErrMsg(db, e);

    // Get commandline arguments
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len < 2) {
        std.log.warn(
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
            std.log.warn("Invalid post id\nUsage: {s} read [post-id]", .{args[0]});
            return error.NotAnInt;
        };
        readOpts.singlePost = GetPostBy{ .Id = postId };
    } else if (std.mem.eql(u8, args[1], CMD_CREATE_POST)) {
        if (args.len != 4) {
            std.log.warn("Error: wrong number of args\nUsage: {s} create <title> <content>\n", .{args[0]});
            return;
        }

        var stmt = (try db.prepare_v2(SQL_INSERT_POST, null)).?;
        try stmt.bindText(1, args[2], .static);
        try stmt.bindText(2, args[2], .static);

        std.debug.assert((try stmt.step()) == .Done);

        try stmt.finalize();

        readOpts.singlePost = GetPostBy{ .LastInserted = {} };
    } else if (std.mem.eql(u8, args[1], CMD_UPDATE_POST)) {
        if (args.len != 5) {
            std.log.warn("Not enough arguments\nUsage: {s} update <post-id> <title> <content>\n", .{args[0]});
            return error.NotEnoughArguments;
        }
        const id = std.fmt.parseInt(i64, args[2], 10) catch {
            std.log.warn("Invalid post id\nUsage: {s} update <post-id> <title> <content>\n", .{args[0]});
            return error.NotAnInt;
        };
        const title = args[3];
        const content = args[4];

        var stmt = (try db.prepare_v2(SQL_UPDATE_POST, null)).?;
        try stmt.bindText(1, title, .static);
        try stmt.bindText(2, content, .static);
        try stmt.bindInt64(3, id);

        std.debug.assert((try stmt.step()) == .Done);

        try stmt.finalize();

        readOpts.singlePost = GetPostBy{ .Id = id };
    } else if (std.mem.eql(u8, args[1], CMD_DELETE_POST)) {
        if (args.len != 3) {
            std.log.warn("Not enough arguments\nUsage: {s} delete <post-id>\n", .{args[0]});
            return error.WrongNumberOfArguments;
        }
        const id = std.fmt.parseInt(i64, args[2], 10) catch {
            std.log.warn("Invalid post id\nUsage: {s} delete <post-id>\n", .{args[0]});
            return error.NotAnInt;
        };

        var stmt = (try db.prepare_v2(SQL_DELETE_POST, null)).?;
        try stmt.bindInt64(3, id);

        std.debug.assert((try stmt.step()) == .Done);

        try stmt.finalize();
    }

    const stdout = &std.io.getStdOut().writer();

    try read(stdout, db, readOpts);
}

fn printSqliteErrMsg(db: *sqlite.SQLite3, e: sqlite.Error) !void {
    std.log.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
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

fn read(out: anytype, db: *sqlite.SQLite3, opts: ReadOptions) !void {
    if (opts.singlePost) |post| {
        const sql = switch (post) {
            .Id => SQL_GET_POST_BY_ID,
            .LastInserted => SQL_GET_LAST_INSERTED,
        };

        var stmt = (try db.prepare_v2(sql, null)).?;
        defer stmt.finalize() catch {};
        if (post == .LastInserted) {
            try stmt.bindInt64(1, post.Id);
        }

        switch (try stmt.step()) {
            .Ok, .Row => {},
            .Done => {
                std.log.warn("No post with id '{}'\n", .{post});
                return error.InvalidPostId;
            },
        }
        try displaySinglePost(out, stmt);
    } else {
        var stmt = (try db.prepare_v2(SQL_GET_POSTS, null)).?;
        defer stmt.finalize() catch {};

        try out.print("Posts:\n", .{});
        while ((try stmt.step()) == .Row) {
            const id = stmt.columnInt64(0);
            const title = stmt.columnText(1);
            const content = stmt.columnText(2);
            try out.print("\t{}\t{s}\t{s}\n", .{ id, title, content });
        }
    }
}

fn displaySinglePost(out: anytype, stmt: *sqlite.Stmt) !void {
    const id = stmt.columnInt64(0);
    const title = stmt.columnText(1);
    const content = stmt.columnText(2);
    try out.print(
        \\ Id: {}
        \\ Title: {s}
        \\
        \\ {s}
        \\
    , .{ id, title, content });
}
