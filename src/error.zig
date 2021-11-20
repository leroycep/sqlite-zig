const std = @import("std");
const panic = std.debug.panic;

const c = @import("c.zig");

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
        c.SQLITE_OK => .Ok,
        c.SQLITE_DONE => .Done,
        c.SQLITE_ROW => .Row,
        else => null,
    };
}

pub fn primaryErrorFromCode(rc: c_int) Primary!void {
    return switch (rc) {
        c.SQLITE_ABORT => error.Abort,
        c.SQLITE_AUTH => error.Auth,
        c.SQLITE_BUSY => error.Busy,
        c.SQLITE_CANTOPEN => error.CantOpen,
        c.SQLITE_CONSTRAINT => error.Constraint,
        c.SQLITE_CORRUPT => error.Corrupt,
        c.SQLITE_EMPTY => error.Empty,
        c.SQLITE_ERROR => error.Error,
        c.SQLITE_FORMAT => error.Format,
        c.SQLITE_FULL => error.Full,
        c.SQLITE_INTERNAL => error.Internal,
        c.SQLITE_INTERRUPT => error.Interrupt,
        c.SQLITE_IOERR => error.IoErr,
        c.SQLITE_LOCKED => error.Locked,
        c.SQLITE_MISMATCH => error.Mismatch,
        c.SQLITE_MISUSE => error.Misuse,
        c.SQLITE_NOLFS => error.NoLFS,
        c.SQLITE_NOMEM => error.NoMem,
        c.SQLITE_NOTADB => error.NotA_DB,
        c.SQLITE_NOTFOUND => error.NotFound,
        c.SQLITE_NOTICE => error.Notice,
        c.SQLITE_PERM => error.Perm,
        c.SQLITE_PROTOCOL => error.Protocol,
        c.SQLITE_RANGE => error.Range,
        c.SQLITE_READONLY => error.ReadOnly,
        c.SQLITE_SCHEMA => error.Schema,
        c.SQLITE_TOOBIG => error.TooBig,
        c.SQLITE_WARNING => error.Warning,
        else => {},
    };
}

pub fn extendedErrorFromCode(rc: c_int) Extended!void {
    return switch (rc) {
        c.SQLITE_ABORT_ROLLBACK => error.AbortRollback,
        c.SQLITE_BUSY_RECOVERY => error.BusyRecovery,
        c.SQLITE_BUSY_SNAPSHOT => error.BusySnapshot,
        c.SQLITE_CANTOPEN_CONVPATH => error.CantOpenConvPath,
        c.SQLITE_CANTOPEN_DIRTYWAL => error.CantOpenDirtyWAL,
        c.SQLITE_CANTOPEN_FULLPATH => error.CantOpenFullPath,
        c.SQLITE_CANTOPEN_ISDIR => error.CantOpenIsDir,
        c.SQLITE_CANTOPEN_NOTEMPDIR => error.CantOpenNoTempDir,
        c.SQLITE_CONSTRAINT_CHECK => error.ConstraintCheck,
        c.SQLITE_CONSTRAINT_COMMITHOOK => error.ConstraintCommitHook,
        c.SQLITE_CONSTRAINT_FOREIGNKEY => error.ConstraintForeignKey,
        c.SQLITE_CONSTRAINT_FUNCTION => error.ConstraintFunction,
        c.SQLITE_CONSTRAINT_NOTNULL => error.ConstraintNotNull,
        c.SQLITE_CONSTRAINT_PRIMARYKEY => error.ConstraintPrimaryKey,
        c.SQLITE_CONSTRAINT_ROWID => error.ConstraintRowId,
        c.SQLITE_CONSTRAINT_TRIGGER => error.ConstraintTrigger,
        c.SQLITE_CONSTRAINT_UNIQUE => error.ConstraintUnique,
        c.SQLITE_CONSTRAINT_VTAB => error.ConstraintVTab,
        c.SQLITE_CORRUPT_SEQUENCE => error.CorruptSequence,
        c.SQLITE_CORRUPT_VTAB => error.CorruptVTab,
        c.SQLITE_ERROR_MISSING_COLLSEQ => error.ErrorMissingCollSeq,
        c.SQLITE_ERROR_RETRY => error.ErrorRetry,
        c.SQLITE_ERROR_SNAPSHOT => error.ErrorSnapshot,
        c.SQLITE_IOERR_ACCESS => error.IoErrAccess,
        c.SQLITE_IOERR_BLOCKED => error.IoErrBlocked,
        c.SQLITE_IOERR_CHECKRESERVEDLOCK => error.IoErrCheckReservedLock,
        c.SQLITE_IOERR_CLOSE => error.IoErrClose,
        c.SQLITE_IOERR_CONVPATH => error.IoErrConvPath,
        c.SQLITE_IOERR_DELETE => error.IoErrDelete,
        c.SQLITE_IOERR_DELETE_NOENT => error.IoErrDeleteNoEnt,
        c.SQLITE_IOERR_DIR_CLOSE => error.IoErrDirClose,
        c.SQLITE_IOERR_DIR_FSYNC => error.IoErrDirFSync,
        c.SQLITE_IOERR_FSTAT => error.IoErrFStat,
        c.SQLITE_IOERR_FSYNC => error.IoErrFSync,
        c.SQLITE_IOERR_GETTEMPPATH => error.IoErrGetTempPath,
        c.SQLITE_IOERR_LOCK => error.IoErrLock,
        c.SQLITE_IOERR_MMAP => error.IoErrMMap,
        c.SQLITE_IOERR_NOMEM => error.IoErrNoMem,
        c.SQLITE_IOERR_RDLOCK => error.IoErrRDLock,
        c.SQLITE_IOERR_READ => error.IoErrRead,
        c.SQLITE_IOERR_SEEK => error.IoErrSeek,
        c.SQLITE_IOERR_SHMLOCK => error.IoErrShMLock,
        c.SQLITE_IOERR_SHMMAP => error.IoErrShMMap,
        c.SQLITE_IOERR_SHMOPEN => error.IoErrShMOpen,
        c.SQLITE_IOERR_SHMSIZE => error.IoErrShMSize,
        c.SQLITE_IOERR_SHORT_READ => error.IoErrShortRead,
        c.SQLITE_IOERR_TRUNCATE => error.IoErrTruncate,
        c.SQLITE_IOERR_UNLOCK => error.IoErrUnlock,
        c.SQLITE_IOERR_WRITE => error.IoErrWrite,
        c.SQLITE_LOCKED_SHAREDCACHE => error.LockedSharedCache,
        c.SQLITE_LOCKED_VTAB => error.LockedVTab,
        c.SQLITE_NOTICE_RECOVER_ROLLBACK => error.NoticeRecoverRollback,
        c.SQLITE_NOTICE_RECOVER_WAL => error.NoticeRecoverWAL,
        c.SQLITE_OK_LOAD_PERMANENTLY => error.OkLoadPermanently,
        c.SQLITE_READONLY_CANTINIT => error.ReadOnlyCantInit,
        c.SQLITE_READONLY_CANTLOCK => error.ReadOnlyCantLock,
        c.SQLITE_READONLY_DBMOVED => error.ReadOnlyDBMoved,
        c.SQLITE_READONLY_DIRECTORY => error.ReadOnlyDirectory,
        c.SQLITE_READONLY_RECOVERY => error.ReadOnlyRecovery,
        c.SQLITE_READONLY_ROLLBACK => error.ReadOnlyRollback,
        c.SQLITE_WARNING_AUTOINDEX => error.WarningAutoIndex,
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
    panic("unknown sqlite error code\n", .{});
}

pub fn assertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != c.SQLITE_OK) {
        panic("SQLite returned an error code", .{});
    }
}
