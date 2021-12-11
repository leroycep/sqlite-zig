const std = @import("std");
const panic = std.debug.panic;
const log = std.log.scoped(.sqlite3);

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

pub const SQLITE_OK = @as(c_int, 0);
pub const SQLITE_ROW = @as(c_int, 100);
pub const SQLITE_DONE = @as(c_int, 101);

pub fn successFromCode(rc: c_int) ?Success {
    return switch (rc) {
        SQLITE_OK => .Ok,
        SQLITE_DONE => .Done,
        SQLITE_ROW => .Row,
        else => null,
    };
}

pub const SQLITE_ERROR = @as(c_int, 1);
pub const SQLITE_INTERNAL = @as(c_int, 2);
pub const SQLITE_PERM = @as(c_int, 3);
pub const SQLITE_ABORT = @as(c_int, 4);
pub const SQLITE_BUSY = @as(c_int, 5);
pub const SQLITE_LOCKED = @as(c_int, 6);
pub const SQLITE_NOMEM = @as(c_int, 7);
pub const SQLITE_READONLY = @as(c_int, 8);
pub const SQLITE_INTERRUPT = @as(c_int, 9);
pub const SQLITE_IOERR = @as(c_int, 10);
pub const SQLITE_CORRUPT = @as(c_int, 11);
pub const SQLITE_NOTFOUND = @as(c_int, 12);
pub const SQLITE_FULL = @as(c_int, 13);
pub const SQLITE_CANTOPEN = @as(c_int, 14);
pub const SQLITE_PROTOCOL = @as(c_int, 15);
pub const SQLITE_EMPTY = @as(c_int, 16);
pub const SQLITE_SCHEMA = @as(c_int, 17);
pub const SQLITE_TOOBIG = @as(c_int, 18);
pub const SQLITE_CONSTRAINT = @as(c_int, 19);
pub const SQLITE_MISMATCH = @as(c_int, 20);
pub const SQLITE_MISUSE = @as(c_int, 21);
pub const SQLITE_NOLFS = @as(c_int, 22);
pub const SQLITE_AUTH = @as(c_int, 23);
pub const SQLITE_FORMAT = @as(c_int, 24);
pub const SQLITE_RANGE = @as(c_int, 25);
pub const SQLITE_NOTADB = @as(c_int, 26);
pub const SQLITE_NOTICE = @as(c_int, 27);
pub const SQLITE_WARNING = @as(c_int, 28);

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

pub const SQLITE_ERROR_MISSING_COLLSEQ = SQLITE_ERROR | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_ERROR_RETRY = SQLITE_ERROR | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_ERROR_SNAPSHOT = SQLITE_ERROR | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_IOERR_READ = SQLITE_IOERR | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_IOERR_SHORT_READ = SQLITE_IOERR | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_IOERR_WRITE = SQLITE_IOERR | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_IOERR_FSYNC = SQLITE_IOERR | (@as(c_int, 4) << @as(c_int, 8));
pub const SQLITE_IOERR_DIR_FSYNC = SQLITE_IOERR | (@as(c_int, 5) << @as(c_int, 8));
pub const SQLITE_IOERR_TRUNCATE = SQLITE_IOERR | (@as(c_int, 6) << @as(c_int, 8));
pub const SQLITE_IOERR_FSTAT = SQLITE_IOERR | (@as(c_int, 7) << @as(c_int, 8));
pub const SQLITE_IOERR_UNLOCK = SQLITE_IOERR | (@as(c_int, 8) << @as(c_int, 8));
pub const SQLITE_IOERR_RDLOCK = SQLITE_IOERR | (@as(c_int, 9) << @as(c_int, 8));
pub const SQLITE_IOERR_DELETE = SQLITE_IOERR | (@as(c_int, 10) << @as(c_int, 8));
pub const SQLITE_IOERR_BLOCKED = SQLITE_IOERR | (@as(c_int, 11) << @as(c_int, 8));
pub const SQLITE_IOERR_NOMEM = SQLITE_IOERR | (@as(c_int, 12) << @as(c_int, 8));
pub const SQLITE_IOERR_ACCESS = SQLITE_IOERR | (@as(c_int, 13) << @as(c_int, 8));
pub const SQLITE_IOERR_CHECKRESERVEDLOCK = SQLITE_IOERR | (@as(c_int, 14) << @as(c_int, 8));
pub const SQLITE_IOERR_LOCK = SQLITE_IOERR | (@as(c_int, 15) << @as(c_int, 8));
pub const SQLITE_IOERR_CLOSE = SQLITE_IOERR | (@as(c_int, 16) << @as(c_int, 8));
pub const SQLITE_IOERR_DIR_CLOSE = SQLITE_IOERR | (@as(c_int, 17) << @as(c_int, 8));
pub const SQLITE_IOERR_SHMOPEN = SQLITE_IOERR | (@as(c_int, 18) << @as(c_int, 8));
pub const SQLITE_IOERR_SHMSIZE = SQLITE_IOERR | (@as(c_int, 19) << @as(c_int, 8));
pub const SQLITE_IOERR_SHMLOCK = SQLITE_IOERR | (@as(c_int, 20) << @as(c_int, 8));
pub const SQLITE_IOERR_SHMMAP = SQLITE_IOERR | (@as(c_int, 21) << @as(c_int, 8));
pub const SQLITE_IOERR_SEEK = SQLITE_IOERR | (@as(c_int, 22) << @as(c_int, 8));
pub const SQLITE_IOERR_DELETE_NOENT = SQLITE_IOERR | (@as(c_int, 23) << @as(c_int, 8));
pub const SQLITE_IOERR_MMAP = SQLITE_IOERR | (@as(c_int, 24) << @as(c_int, 8));
pub const SQLITE_IOERR_GETTEMPPATH = SQLITE_IOERR | (@as(c_int, 25) << @as(c_int, 8));
pub const SQLITE_IOERR_CONVPATH = SQLITE_IOERR | (@as(c_int, 26) << @as(c_int, 8));
pub const SQLITE_IOERR_VNODE = SQLITE_IOERR | (@as(c_int, 27) << @as(c_int, 8));
pub const SQLITE_IOERR_AUTH = SQLITE_IOERR | (@as(c_int, 28) << @as(c_int, 8));
pub const SQLITE_IOERR_BEGIN_ATOMIC = SQLITE_IOERR | (@as(c_int, 29) << @as(c_int, 8));
pub const SQLITE_IOERR_COMMIT_ATOMIC = SQLITE_IOERR | (@as(c_int, 30) << @as(c_int, 8));
pub const SQLITE_IOERR_ROLLBACK_ATOMIC = SQLITE_IOERR | (@as(c_int, 31) << @as(c_int, 8));
pub const SQLITE_IOERR_DATA = SQLITE_IOERR | (@as(c_int, 32) << @as(c_int, 8));
pub const SQLITE_IOERR_CORRUPTFS = SQLITE_IOERR | (@as(c_int, 33) << @as(c_int, 8));
pub const SQLITE_LOCKED_SHAREDCACHE = SQLITE_LOCKED | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_LOCKED_VTAB = SQLITE_LOCKED | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_BUSY_RECOVERY = SQLITE_BUSY | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_BUSY_SNAPSHOT = SQLITE_BUSY | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_BUSY_TIMEOUT = SQLITE_BUSY | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_NOTEMPDIR = SQLITE_CANTOPEN | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_ISDIR = SQLITE_CANTOPEN | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_FULLPATH = SQLITE_CANTOPEN | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_CONVPATH = SQLITE_CANTOPEN | (@as(c_int, 4) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_DIRTYWAL = SQLITE_CANTOPEN | (@as(c_int, 5) << @as(c_int, 8));
pub const SQLITE_CANTOPEN_SYMLINK = SQLITE_CANTOPEN | (@as(c_int, 6) << @as(c_int, 8));
pub const SQLITE_CORRUPT_VTAB = SQLITE_CORRUPT | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_CORRUPT_SEQUENCE = SQLITE_CORRUPT | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_CORRUPT_INDEX = SQLITE_CORRUPT | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_READONLY_RECOVERY = SQLITE_READONLY | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_READONLY_CANTLOCK = SQLITE_READONLY | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_READONLY_ROLLBACK = SQLITE_READONLY | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_READONLY_DBMOVED = SQLITE_READONLY | (@as(c_int, 4) << @as(c_int, 8));
pub const SQLITE_READONLY_CANTINIT = SQLITE_READONLY | (@as(c_int, 5) << @as(c_int, 8));
pub const SQLITE_READONLY_DIRECTORY = SQLITE_READONLY | (@as(c_int, 6) << @as(c_int, 8));
pub const SQLITE_ABORT_ROLLBACK = SQLITE_ABORT | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_CHECK = SQLITE_CONSTRAINT | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_COMMITHOOK = SQLITE_CONSTRAINT | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_FOREIGNKEY = SQLITE_CONSTRAINT | (@as(c_int, 3) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_FUNCTION = SQLITE_CONSTRAINT | (@as(c_int, 4) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_NOTNULL = SQLITE_CONSTRAINT | (@as(c_int, 5) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_PRIMARYKEY = SQLITE_CONSTRAINT | (@as(c_int, 6) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_TRIGGER = SQLITE_CONSTRAINT | (@as(c_int, 7) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_UNIQUE = SQLITE_CONSTRAINT | (@as(c_int, 8) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_VTAB = SQLITE_CONSTRAINT | (@as(c_int, 9) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_ROWID = SQLITE_CONSTRAINT | (@as(c_int, 10) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_PINNED = SQLITE_CONSTRAINT | (@as(c_int, 11) << @as(c_int, 8));
pub const SQLITE_CONSTRAINT_DATATYPE = SQLITE_CONSTRAINT | (@as(c_int, 12) << @as(c_int, 8));
pub const SQLITE_NOTICE_RECOVER_WAL = SQLITE_NOTICE | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_NOTICE_RECOVER_ROLLBACK = SQLITE_NOTICE | (@as(c_int, 2) << @as(c_int, 8));
pub const SQLITE_WARNING_AUTOINDEX = SQLITE_WARNING | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_AUTH_USER = SQLITE_AUTH | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_OK_LOAD_PERMANENTLY = SQLITE_OK | (@as(c_int, 1) << @as(c_int, 8));
pub const SQLITE_OK_SYMLINK = SQLITE_OK | (@as(c_int, 2) << @as(c_int, 8));

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
    log.err("unknown sqlite error code: {}", .{rc});
    panic("unknown sqlite error code\n", .{});
}

pub fn assertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        panic("SQLite returned an error code", .{});
    }
}
