const panic = @import("builtin").panic;

usingnamespace @import("c.zig");

pub const SQLiteError = error{
    /// Generic  error
    Error,
    Abort,
    Auth,
    Busy,
    CantOpen,
    Constraint,
    Corrupt,
};

pub fn checkSqliteErr(rc: c_int) SQLiteError!void {
    switch (rc) {
        SQLITE_OK, SQLITE_DONE => return,
        SQLITE_ERROR => return SQLiteError.Error,
        SQLITE_ABORT => return SQLiteError.Abort,
        SQLITE_AUTH => return SQLiteError.Auth,
        SQLITE_BUSY => return SQLiteError.Busy,
        SQLITE_CANTOPEN => return SQLiteError.CantOpen,
        SQLITE_CONSTRAINT => return SQLiteError.Constraint,
        SQLITE_CORRUPT => return SQLiteError.Corrupt,
        else => return SQLiteError.Error,
    }
}

pub fn assertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        panic("SQLite returned an error code", null);
    }
}
