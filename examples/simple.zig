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

    var stmt = (try db.prepare_v2("SELECT id, username FROM users;", null)).?;
    defer stmt.finalize() catch unreachable;

    const out = std.io.getStdOut().writer();
    try out.print(" {s}\t{s}\n", .{ "id", "username" });
    try out.print(" {s}\t{s}\n", .{ "--", "--------" });
    while (true) {
        switch (try stmt.step()) {
            .Done => break,
            .Row => {},
            .Ok => unreachable,
        }

        const id = stmt.columnInt(0);
        const username = stmt.columnText(1);

        try out.print(" {}\t{s}\n", .{ id, username });
    }
}
