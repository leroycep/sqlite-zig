const std = @import("std");
const sqlite = @import("sqlite");

pub fn main() !void {
    const db = try sqlite.SQLite3.open("simple.db");
    defer db.close() catch unreachable;

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
    ,
        null,
        null,
        null,
    );

    var stmt = try db.prepare_v2("SELECT id, username FROM users;", null);
    defer stmt.finalize() catch unreachable;

    std.debug.warn(" {s}\t{s}\n", .{ "id", "username" });
    std.debug.warn(" {s}\t{s}\n", .{ "--", "--------" });
    while (true) {
        switch (try stmt.step()) {
            .Done => break,
            .Row => {},
            .Ok => unreachable,
        }

        const id = stmt.columnInt(0);
        const username = stmt.columnText(1);

        std.debug.warn(" {}\t{s}\n", .{ id, username });
    }
}
