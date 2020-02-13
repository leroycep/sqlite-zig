const panic = @import("builtin").panic;

usingnamespace @import("c.zig");

pub const SQLiteResult = enum {
    Ok,
    Done,
    Row,
};

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

pub fn checkSqliteErr(rc: c_int) SQLiteError!SQLiteResult {
    switch (rc) {
        // Result codes
        SQLITE_OK => return SQLiteResult.Ok,
        SQLITE_DONE => return SQLiteResult.Done,
        SQLITE_ROW => return SQLiteResult.Row,

        // Error codes
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
