const std = @import("std");
const sqlite = @import("sqlite");

pub fn main() !void {
    const db = try sqlite.SQLite3.open("simple.db");
    defer db.close() catch unreachable;

    std.debug.warn(" {s}\t{s}\n", .{ "id", "username" });
    std.debug.warn(" {s}\t{s}\n", .{ "--", "--------" });
    try db.exec(
        \\ DROP TABLE IF EXISTS users;
        \\ CREATE TABLE users(
        \\   id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\   username TEXT NOT NULL
        \\ );
        \\ INSERT INTO users(username)
        \\ VALUES
        \\   ("shallan"),
        \\   ("kaladin"),
        \\   ("adolin"),
        \\   ("dalinar")
        \\ ;
        \\ SELECT id, username FROM users;
    ,
        dataCallback,
        null,
        null,
    );
}

pub fn dataCallback(_: ?*c_void, number_of_result_columns: c_int, columnsAsText: [*]?[*:0]u8, _: [*]?[*:0]u8) callconv(.C) c_int {
    std.debug.assert(number_of_result_columns == 2);
    std.debug.warn(" {s}\t{s}\n", .{ columnsAsText[0], columnsAsText[1] });
    return 0;
}
