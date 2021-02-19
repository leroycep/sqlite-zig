const std = @import("std");
const sqlite = @import("sqlite");

pub fn main() !void {
    const db = try sqlite.SQLite.open("simple.db");
    defer db.close() catch unreachable;

    var rows = db.exec(
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
    );

    std.debug.warn(" {s}\t{s}\n", .{ "id", "username" });
    std.debug.warn(" {s}\t{s}\n", .{ "--", "--------" });
    while (rows.next()) |row_item| {
        const row = switch (row_item) {
            // Ignore when statements are completed
            .Done => continue,
            .Row => |r| r,
            .Error => |e| {
                std.debug.warn("sqlite3 errmsg: {s}\n", .{db.errmsg()});
                return e;
            },
        };

        const id = row.columnInt(0);
        const username = row.columnText(1);

        std.debug.warn(" {}\t{s}\n", .{ id, username });
    }
}
