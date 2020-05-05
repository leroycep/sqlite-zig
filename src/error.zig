const panic = @import("builtin").panic;
const std = @import("std");

usingnamespace @import("c.zig");

pub const Success = enum {
    Ok,
    Done,
    Row,
};

pub const Error = Primary || Extended;

pub const Primary = error{
    /// Generic  error
    Abort,
    Auth,
    Busy,
    CantOpen,
    Constraint,
    Corrupt,
    Empty,
    Error,
    Format,
    Full,
    Internal,
    Interrupt,
    IoErr,
    Locked,
    Mismatch,
    Misuse,
    NoLFS,
    NoMem,
    NotA_DB,
    NotFound,
    Notice,
    Perm,
    Protocol,
    Range,
    ReadOnly,
    Schema,
    TooBig,
    Warning,
};

pub const Extended = error{
    AbortRollback,
    BusyRecovery,
    BusySnapshot,
    CantOpenConvPath,
    CantOpenDirtyWAL, // Is not used by sqlite at this time
    CantOpenFullPath,
    CantOpenIsDir,
    CantOpenNoTempDir, // No longer used
    ConstraintCheck,
    ConstraintCommitHook,
    ConstraintForeignKey,
    ConstraintFunction,
    ConstraintNotNull,
    ConstraintPrimaryKey,
    ConstraintRowId,
    ConstraintTrigger,
    ConstraintUnique,
    ConstraintVTab, // Not used by sqlite core
    CorruptSequence,
    CorruptVTab,
    ErrorMissingCollSeq,
    ErrorRetry,
    ErrorSnapshot,
    IoErrAccess,
    IoErrBlocked,
    IoErrCheckReservedLock,
    IoErrClose,
    IoErrConvPath,
    IoErrDelete,
    IoErrDeleteNoEnt,
    IoErrDirClose,
    IoErrDirFSync,
    IoErrFStat,
    IoErrFSync,
    IoErrGetTempPath,
    IoErrLock,
    IoErrMMap,
    IoErrNoMem,
    IoErrRDLock,
    IoErrRead,
    IoErrSeek,
    IoErrShMLock,
    IoErrShMMap,
    IoErrShMOpen,
    IoErrShMSize,
    IoErrShortRead,
    IoErrTruncate,
    IoErrUnlock,
    IoErrWrite,
    LockedSharedCache,
    LockedVTab,
    NoticeRecoverRollback,
    NoticeRecoverWAL,
    OkLoadPermanently,
    ReadOnlyCantInit,
    ReadOnlyCantLock,
    ReadOnlyDBMoved,
    ReadOnlyDirectory,
    ReadOnlyRecovery,
    ReadOnlyRollback,
    WarningAutoIndex,
};

pub fn successFromCode(rc: c_int) ?Success {
    return switch (rc) {
        SQLITE_OK => .Ok,
        SQLITE_DONE => .Done,
        SQLITE_ROW => .Row,
        else => null,
    };
}

pub fn primaryErrorFromCode(rc: c_int) Primary!void {
    return switch (rc) {
        SQLITE_ABORT => error.Abort,
        SQLITE_AUTH => error.Auth,
        SQLITE_BUSY => error.Busy,
        SQLITE_CANTOPEN => error.CantOpen,
        SQLITE_CONSTRAINT => error.Constraint,
        SQLITE_CORRUPT => error.Corrupt,
        SQLITE_EMPTY => error.Empty,
        SQLITE_ERROR => error.Error,
        SQLITE_FORMAT => error.Format,
        SQLITE_FULL => error.Full,
        SQLITE_INTERNAL => error.Internal,
        SQLITE_INTERRUPT => error.Interrupt,
        SQLITE_IOERR => error.IoErr,
        SQLITE_LOCKED => error.Locked,
        SQLITE_MISMATCH => error.Mismatch,
        SQLITE_MISUSE => error.Misuse,
        SQLITE_NOLFS => error.NoLFS,
        SQLITE_NOMEM => error.NoMem,
        SQLITE_NOTADB => error.NotA_DB,
        SQLITE_NOTFOUND => error.NotFound,
        SQLITE_NOTICE => error.Notice,
        SQLITE_PERM => error.Perm,
        SQLITE_PROTOCOL => error.Protocol,
        SQLITE_RANGE => error.Range,
        SQLITE_READONLY => error.ReadOnly,
        SQLITE_SCHEMA => error.Schema,
        SQLITE_TOOBIG => error.TooBig,
        SQLITE_WARNING => error.Warning,
        else => {},
    };
}

pub fn extendedErrorFromCode(rc: c_int) Extended!void {
    return switch (rc) {
        SQLITE_ABORT_ROLLBACK => error.AbortRollback,
        SQLITE_BUSY_RECOVERY => error.BusyRecovery,
        SQLITE_BUSY_SNAPSHOT => error.BusySnapshot,
        SQLITE_CANTOPEN_CONVPATH => error.CantOpenConvPath,
        SQLITE_CANTOPEN_DIRTYWAL => error.CantOpenDirtyWAL,
        SQLITE_CANTOPEN_FULLPATH => error.CantOpenFullPath,
        SQLITE_CANTOPEN_ISDIR => error.CantOpenIsDir,
        SQLITE_CANTOPEN_NOTEMPDIR => error.CantOpenNoTempDir,
        SQLITE_CONSTRAINT_CHECK => error.ConstraintCheck,
        SQLITE_CONSTRAINT_COMMITHOOK => error.ConstraintCommitHook,
        SQLITE_CONSTRAINT_FOREIGNKEY => error.ConstraintForeignKey,
        SQLITE_CONSTRAINT_FUNCTION => error.ConstraintFunction,
        SQLITE_CONSTRAINT_NOTNULL => error.ConstraintNotNull,
        SQLITE_CONSTRAINT_PRIMARYKEY => error.ConstraintPrimaryKey,
        SQLITE_CONSTRAINT_ROWID => error.ConstraintRowId,
        SQLITE_CONSTRAINT_TRIGGER => error.ConstraintTrigger,
        SQLITE_CONSTRAINT_UNIQUE => error.ConstraintUnique,
        SQLITE_CONSTRAINT_VTAB => error.ConstraintVTab,
        SQLITE_CORRUPT_SEQUENCE => error.CorruptSequence,
        SQLITE_CORRUPT_VTAB => error.CorruptVTab,
        SQLITE_ERROR_MISSING_COLLSEQ => error.ErrorMissingCollSeq,
        SQLITE_ERROR_RETRY => error.ErrorRetry,
        SQLITE_ERROR_SNAPSHOT => error.ErrorSnapshot,
        SQLITE_IOERR_ACCESS => error.IoErrAccess,
        SQLITE_IOERR_BLOCKED => error.IoErrBlocked,
        SQLITE_IOERR_CHECKRESERVEDLOCK => error.IoErrCheckReservedLock,
        SQLITE_IOERR_CLOSE => error.IoErrClose,
        SQLITE_IOERR_CONVPATH => error.IoErrConvPath,
        SQLITE_IOERR_DELETE => error.IoErrDelete,
        SQLITE_IOERR_DELETE_NOENT => error.IoErrDeleteNoEnt,
        SQLITE_IOERR_DIR_CLOSE => error.IoErrDirClose,
        SQLITE_IOERR_DIR_FSYNC => error.IoErrDirFSync,
        SQLITE_IOERR_FSTAT => error.IoErrFStat,
        SQLITE_IOERR_FSYNC => error.IoErrFSync,
        SQLITE_IOERR_GETTEMPPATH => error.IoErrGetTempPath,
        SQLITE_IOERR_LOCK => error.IoErrLock,
        SQLITE_IOERR_MMAP => error.IoErrMMap,
        SQLITE_IOERR_NOMEM => error.IoErrNoMem,
        SQLITE_IOERR_RDLOCK => error.IoErrRDLock,
        SQLITE_IOERR_READ => error.IoErrRead,
        SQLITE_IOERR_SEEK => error.IoErrSeek,
        SQLITE_IOERR_SHMLOCK => error.IoErrShMLock,
        SQLITE_IOERR_SHMMAP => error.IoErrShMMap,
        SQLITE_IOERR_SHMOPEN => error.IoErrShMOpen,
        SQLITE_IOERR_SHMSIZE => error.IoErrShMSize,
        SQLITE_IOERR_SHORT_READ => error.IoErrShortRead,
        SQLITE_IOERR_TRUNCATE => error.IoErrTruncate,
        SQLITE_IOERR_UNLOCK => error.IoErrUnlock,
        SQLITE_IOERR_WRITE => error.IoErrWrite,
        SQLITE_LOCKED_SHAREDCACHE => error.LockedSharedCache,
        SQLITE_LOCKED_VTAB => error.LockedVTab,
        SQLITE_NOTICE_RECOVER_ROLLBACK => error.NoticeRecoverRollback,
        SQLITE_NOTICE_RECOVER_WAL => error.NoticeRecoverWAL,
        SQLITE_OK_LOAD_PERMANENTLY => error.OkLoadPermanently,
        SQLITE_READONLY_CANTINIT => error.ReadOnlyCantInit,
        SQLITE_READONLY_CANTLOCK => error.ReadOnlyCantLock,
        SQLITE_READONLY_DBMOVED => error.ReadOnlyDBMoved,
        SQLITE_READONLY_DIRECTORY => error.ReadOnlyDirectory,
        SQLITE_READONLY_RECOVERY => error.ReadOnlyRecovery,
        SQLITE_READONLY_ROLLBACK => error.ReadOnlyRollback,
        SQLITE_WARNING_AUTOINDEX => error.WarningAutoIndex,
        else => {},
    };
}

pub fn checkSqliteErr(rc: c_int) Error!Success {
    if (successFromCode(rc)) |success| {
        return success;
    }
    primaryErrorFromCode(rc) catch |primary_err| return primary_err;
    extendedErrorFromCode(rc) catch |extended_err| return extended_err;

    // If nothing above returns, there's an unknown return code
    std.debug.warn("unknown sqlite error code: {}\n", .{rc});
    panic("unknown sqlite error code\n", null);
}

pub fn assertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        panic("SQLite returned an error code", null);
    }
}
