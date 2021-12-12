const std = @import("std");
const err = @import("./error.zig");
const log = std.log.scoped(.sqlite3);

pub const Error = err.Error;

pub const SQLite3 = opaque {
    // open
    pub extern fn sqlite3_open([*:0]const u8, *?*SQLite3) c_int;
    pub extern fn sqlite3_open16([*]const c_void, *?*SQLite3) c_int;
    pub extern fn sqlite3_open_v2([*:0]const u8, *?*SQLite3, c_int, [*:0]const u8) c_int;

    pub fn open(filename: [*:0]const u8) !*SQLite3 {
        var db: ?*SQLite3 = null;
        errdefer {
            if (db) |db_not_null| {
                log.debug("Freeing sqlite3 on error", .{});
                db_not_null.close() catch unreachable;
            }
        }
        _ = try err.checkSqliteErr(sqlite3_open(filename, &db));
        return db.?;
    }

    pub fn open16(filename: [*:0]const u16) !*SQLite3 {
        var db: ?*SQLite3 = null;
        errdefer {
            if (db) |db_not_null| {
                log.debug("Freeing sqlite3 on error", .{});
                db_not_null.close() catch unreachable;
            }
        }
        _ = try err.checkSqliteErr(sqlite3_open(filename, &db));
        return db.?;
    }

    pub const OpenV2Flags = struct {
        readonly: bool = false,
        readwrite: bool = false,
        create: bool = false,
        uri: bool = false,
        memory: bool = false,
        nomutex: bool = false,
        fullmutex: bool = false,
        sharedcache: bool = false,
        privatecache: bool = false,
        exrescode: bool = false,
        nofollow: bool = false,
    };

    pub fn open_v2(filename: [*:0]const u8, flags: OpenV2Flags, zVfs: [*:0]const u8) !*SQLite3 {
        var db: ?*SQLite3 = null;
        errdefer {
            if (db) |db_not_null| {
                log.debug("Freeing SQLite3 on error", .{});
                db_not_null.close() catch unreachable;
            }
        }

        var c_flags: c_int = 0;
        if (flags.readonly) c_flags |= SQLITE_OPEN_READONLY;
        if (flags.readwrite) c_flags |= SQLITE_OPEN_READWRITE;
        if (flags.create) c_flags |= SQLITE_OPEN_CREATE;
        if (flags.uri) c_flags |= SQLITE_OPEN_URI;
        if (flags.memory) c_flags |= SQLITE_OPEN_MEMORY;
        if (flags.nomutex) c_flags |= SQLITE_OPEN_NOMUTEX;
        if (flags.fullmutex) c_flags |= SQLITE_OPEN_FULLMUTEX;
        if (flags.sharedcache) c_flags |= SQLITE_OPEN_SHAREDCACHE;
        if (flags.privatecache) c_flags |= SQLITE_OPEN_PRIVATECACHE;
        if (flags.exrescode) c_flags |= SQLITE_OPEN_EXRESCODE;
        if (flags.nofollow) c_flags |= SQLITE_OPEN_NOFOLLOW;

        _ = try err.checkSqliteErr(sqlite3_open_v2(filename, &db, c_flags, zVfs));
        return db.?;
    }

    // close
    pub extern fn sqlite3_close(?*SQLite3) c_int;
    pub extern fn sqlite3_close_v2(?*SQLite3) c_int;
    pub fn close(this: *@This()) !void {
        _ = try err.checkSqliteErr(sqlite3_close(this));
    }

    pub fn close_v2(this: *@This()) !void {
        _ = try err.checkSqliteErr(sqlite3_close_v2(this));
    }

    // Error messages
    // TODO: Can the returned strings be null?
    pub extern fn sqlite3_errcode(*SQLite3) c_int;
    pub extern fn sqlite3_extended_errcode(*SQLite3) c_int;
    pub extern fn sqlite3_errmsg(*SQLite3) ?[*:0]const u8;
    pub extern fn sqlite3_errmsg16(*SQLite3) ?*const c_void;

    pub fn errmsg(this: *@This()) [:0]const u8 {
        return std.mem.span(sqlite3_errmsg(this) orelse return "");
    }

    // exec
    pub const ExecCallback = fn (userdata: ?*c_void, number_of_result_columns: c_int, columnsAsText: [*]?[*:0]u8, columnNames: [*]?[*:0]u8) callconv(.C) c_int;
    pub extern fn sqlite3_exec(*SQLite3, sql: [*:0]const u8, callback: ?ExecCallback, ?*c_void, pErrmsg: ?*[*:0]u8) c_int;

    pub fn exec(this: *@This(), sql: [*:0]const u8, callback: ?ExecCallback, userdata: ?*c_void, pErrmsg: ?*[*:0]u8) !void {
        _ = try err.checkSqliteErr(sqlite3_exec(this, sql, callback, userdata, pErrmsg));
    }

    // prepare
    pub extern fn sqlite3_prepare(*SQLite3, zSql: [*]const u8, maxLen: c_int, ppStmt: *?*Stmt, pzTail: ?*[*]const u8) c_int;
    pub extern fn sqlite3_prepare_v2(*SQLite3, zSql: [*]const u8, maxLen: c_int, ppStmt: *?*Stmt, pzTail: ?*[*]const u8) c_int;

    pub fn prepare_v2(this: *@This(), sql: []const u8, sqlTailOpt: ?*[]const u8) !*Stmt {
        //var sql_tail_buf: [*:0]const u8 = undefined;
        var sql_tail_ptr: ?*[*]const u8 = if (sqlTailOpt) |sqlTail| &sqlTail.ptr else null;

        var pp_stmt: ?*Stmt = null;
        errdefer _ = Stmt.sqlite3_finalize(pp_stmt);
        _ = try err.checkSqliteErr(sqlite3_prepare_v2(this, sql.ptr, @intCast(c_int, sql.len), &pp_stmt, sql_tail_ptr));

        if (sqlTailOpt) |sqlTail| {
            const diff = @ptrToInt(sqlTail.ptr) -| @ptrToInt(sql.ptr);
            sqlTail.len = sql.len - diff;
        }

        return pp_stmt.?;
    }
};

pub const Stmt = opaque {
    // finalize
    pub extern fn sqlite3_finalize(?*Stmt) c_int;
    pub fn finalize(this: *@This()) !void {
        _ = try err.checkSqliteErr(sqlite3_finalize(this));
    }

    // step
    pub extern fn sqlite3_step(*Stmt) c_int;
    pub fn step(this: *@This()) !err.Success {
        return try err.checkSqliteErr(sqlite3_step(this));
    }

    // column
    pub extern fn sqlite3_column_blob(*Stmt, iCol: c_int) ?*const c_void;
    pub extern fn sqlite3_column_double(*Stmt, iCol: c_int) f64;
    pub extern fn sqlite3_column_int(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_column_int64(*Stmt, iCol: c_int) i64;
    pub extern fn sqlite3_column_text(*Stmt, iCol: c_int) [*:0]const u8;
    pub extern fn sqlite3_column_text16(*Stmt, iCol: c_int) *const c_void;
    //pub extern fn sqlite3_column_value(*Stmt, iCol: c_int) ?*Value;

    pub extern fn sqlite3_column_bytes(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_column_bytes16(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_column_type(*Stmt, iCol: c_int) c_int;

    pub fn columnBlob(this: *@This(), iCol: c_int) ?[]const u8 {
        const blob_ptr = sqlite3_column_blob(this, iCol) orelse return null;
        const blob_len = sqlite3_column_bytes(this, iCol);
        return @ptrCast([*]const u8, blob_ptr)[0..@intCast(usize, blob_len)];
    }

    pub fn columnInt(this: *@This(), iCol: c_int) c_int {
        return sqlite3_column_int(this, iCol);
    }

    pub fn columnInt64(this: *@This(), iCol: c_int) i64 {
        return sqlite3_column_int64(this, iCol);
    }

    pub fn columnText(this: *@This(), iCol: c_int) [:0]const u8 {
        const text_ptr = sqlite3_column_text(this, iCol);
        const text_len = sqlite3_column_bytes(this, iCol);
        return text_ptr[0..@intCast(usize, text_len) :0];
    }

    pub fn columnText16(this: *@This(), iCol: c_int) [:0]const u16 {
        const text_ptr = sqlite3_column_text(this, iCol);
        const text_len = sqlite3_column_bytes16(this, iCol) / @sizeOf(u16);
        return text_ptr[0..@intCast(usize, text_len) :0];
    }

    // TODO: Supprt columnValue as well (it has a bunch of caveats listed, focus on it later)
    pub const columnBytes = sqlite3_column_bytes;
    pub const columnBytes16 = sqlite3_column_bytes16;

    pub fn columnType(this: *@This(), iCol: c_int) SQLiteType {
        return @intToEnum(SQLiteType, sqlite3_column_type(this, iCol));
    }

    // bind
    pub extern fn sqlite3_bind_blob(*Stmt, iCol: c_int, value: ?*const c_void, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_blob64(*Stmt, iCol: c_int, value: ?*const c_void, len: u64, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_double(*Stmt, iCol: c_int, value: f64) c_int;
    pub extern fn sqlite3_bind_int(*Stmt, iCol: c_int, value: c_int) c_int;
    pub extern fn sqlite3_bind_int64(*Stmt, iCol: c_int, value: i64) c_int;
    pub extern fn sqlite3_bind_null(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_bind_text(*Stmt, iCol: c_int, value: ?[*]const u8, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_text16(*Stmt, iCol: c_int, value: ?*const c_void, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_text64(*Stmt, iCol: c_int, value: ?[*]const u8, len: u64, ?DestructorFn, encoding: u8) c_int;
    // TODO: pub extern fn sqlite3_bind_value(*Stmt, iCol: c_int, value: *const Value) c_int;
    pub extern fn sqlite3_bind_pointer(*Stmt, iCol: c_int, value: *c_void, name: [*:0]const u8, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_zeroblob(*Stmt, iCol: c_int, len: c_int) c_int;
    pub extern fn sqlite3_bind_zeroblob64(*Stmt, iCol: c_int, len: u64) c_int;

    pub fn bindBlob(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_blob64(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| @intCast(u64, v.len) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindDouble(this: *@This(), iCol: c_int, value: f64) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_double(this, iCol, value));
    }

    pub fn bindInt(this: *@This(), iCol: c_int, value: c_int) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_int(this, iCol, value));
    }

    pub fn bindInt64(this: *@This(), iCol: c_int, value: i64) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_int64(this, iCol, value));
    }

    pub fn bindNull(this: *@This(), iCol: c_int) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_null(this, iCol));
    }

    pub fn bindText(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType) !void {
        if (value) |v| std.debug.assert(v.len <= std.math.maxInt(c_int));

        _ = try err.checkSqliteErr(sqlite3_bind_text(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| @intCast(c_int, v.len) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindText16(this: *@This(), iCol: c_int, value: ?[]const u16, destructorType: DestructorType) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_text16(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| v.len * @sizeOf(u16) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindText64(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType, encoding: TextEncoding) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_text64(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| v.len else 0,
            destructorType.getFnValue(),
            @enumToInt(encoding),
        ));
    }

    // TODO: pub fn bindValue()

    pub fn bindPointer(this: *@This(), iCol: c_int, value: ?*c_void, name: [*:0]const u8, destructorFn: ?DestructorFn) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_pointer(
            this,
            iCol,
            value,
            name,
            destructorFn,
        ));
    }

    pub fn bindZeroBlob(this: *@This(), iCol: c_int, len: c_int) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_zeroblob(this, iCol, len));
    }

    pub fn bindZeroblob64(this: *@This(), iCol: c_int, len: u64) !void {
        _ = try err.checkSqliteErr(sqlite3_bind_zeroblob64(this, iCol, len));
    }
};

pub extern fn sqlite3_errstr(c_int) ?[*:0]const u8;
pub fn errstr(errcode: c_int) [:0]const u8 {
    return std.mem.span(sqlite3_errstr(errcode));
}

pub const SQLiteType = enum(c_int) {
    integer = 1,
    float = 2,
    text = 3,
    blob = 4,
    @"null" = 5,
};

pub const DestructorFn = fn (*c_void) callconv(.C) void;

pub const DestructorType = union(enum) {
    destructor: DestructorFn,
    static: void,
    transient: void,

    fn getFnValue(this: @This()) ?DestructorFn {
        return switch (this) {
            .destructor => |d| d,
            .static => @intToPtr(?DestructorFn, 0),
            .transient => @intToPtr(?DestructorFn, 0),
        };
    }
};

pub const TextEncoding = enum(u8) {
    utf8 = 1,
    utf16LE = 2,
    utf16BE = 3,
    utf16 = 4,
};

// TODO: Add Value opaque

// Memory allocation
pub extern fn sqlite3_malloc(len: c_int) ?*c_void;
pub extern fn sqlite3_malloc64(len: u64) ?*c_void;
pub extern fn sqlite3_realloc(ptr: ?*c_void, len: c_int) ?*c_void;
pub extern fn sqlite3_realloc64(ptr: ?*c_void, len: u64) ?*c_void;
pub extern fn sqlite3_free(ptr: ?*c_void) void;
pub extern fn sqlite3_msize(ptr: ?*c_void) u64;

pub const malloc = sqlite3_malloc;
pub const malloc64 = sqlite3_malloc64;
pub const realloc = sqlite3_realloc;
pub const realloc64 = sqlite3_realloc64;
pub const free = sqlite3_free;
pub const msize = sqlite3_msize;

// Config
pub extern fn sqlite3_config(c_int, ...) c_int;

pub fn config(params: ConfigParams) !void {
    const option = @enumToInt(params);
    const result = switch (params) {
        .singlethread,
        .multithread,
        .serialized,
        => sqlite3_config(option),

        .malloc,
        .getmalloc,
        => |p| sqlite3_config(option, p),

        .small_malloc,
        .memstatus,
        .uri,
        .covering_index_scan,
        => |p| sqlite3_config(option, @boolToInt(p)),

        .pagecache => |p| sqlite3_config(option, p.pMem, p.sz, p.n),
        .heap => |p| sqlite3_config(
            option,
            if (p.mem) |m| m.ptr else null,
            if (p.mem) |m| m.len else 0,
        ),

        .mutex,
        .getmutex,
        => |p| sqlite3_config(option, p),

        .lookaside => |p| sqlite3_config(option, p.defaultSlotSize, p.defaultSlotsPerConnection),

        .pcache2,
        .getpcache2,
        => |p| sqlite3_config(option, p),

        .log => |p| sqlite3_config(option, p.logFn, p.userdata),
        .sqllog => |p| sqlite3_config(option, p.logFn, p.userdata),
        .mmap_size => |p| sqlite3_config(option, p.defaultSizeLimit, p.maximumSizeLimit),
        .win32_heapsize => |p| sqlite3_config(option, p),
        .pcache_hdrsz => |p| sqlite3_config(option, p),
        .pmasz => |p| sqlite3_config(option, p),
        .stmtjrnl_spill => |p| sqlite3_config(option, p),
        .sorterref_size => |p| sqlite3_config(option, p),
        .memdb_maxsize => |p| sqlite3_config(option, p),
    };
    std.debug.assert((try err.checkSqliteErr(result)) == .Ok);
}

pub const ConfigParams = union(ConfigOption) {
    singlethread: void,
    multithread: void,
    serialized: void,
    malloc: *sqlite3_mem_methods,
    getmalloc: *sqlite3_mem_methods,
    small_malloc: bool,
    memstatus: bool,
    /// Define the memory pool that SQLite can use with the default database page cache implementation.
    pagecache: struct {
        /// Pointer to the start of the page cache
        pMem: *align(8) u8,
        /// The size of each cache line. This should be a size that is large enough to
        /// contain the largest database page plus some extra bytes for the page header.
        sz: c_int,
        /// The number of caches lines
        n: c_int,
    },
    heap: struct {
        /// Memory reserved for the heap
        mem: ?[]align(8) u8,
        /// The minimum allocation size. The minimum allocation size is capped at 2**12.
        /// Reasonable values for the minimum allocation size are 2**5 through 2**8.
        minimumAllocationSize: usize,
    },
    mutex: *Mutex.Methods,
    getmutex: *Mutex.Methods,
    lookaside: struct {
        defaultSlotSize: c_int,
        defaultSlotsPerConnection: c_int,
    },
    pcache2: *PCache.Methods2,
    getpcache2: *PCache.Methods2,
    log: struct {
        logFn: fn (userdata: *c_void, errcode: c_int, msg: ?[*:0]const u8) callconv(.C) void,
        userdata: ?*c_void,
    },
    uri: bool,
    covering_index_scan: bool,
    sqllog: struct {
        logFn: fn (userdata: *c_void, db: *SQLite3, dbFilename: ?[*:0]const u8, sqllog: c_int) callconv(.C) void,
        userdata: ?*c_void,
    },
    mmap_size: struct {
        defaultSizeLimit: i64,
        maximumSizeLimit: i64,
    },
    win32_heapsize: i32,
    pcache_hdrsz: *c_int,
    pmasz: c_uint,
    stmtjrnl_spill: c_int,
    sorterref_size: c_int,
    memdb_maxsize: i64,
};

pub const ConfigOption = enum(c_int) {
    singlethread = SQLITE_CONFIG_SINGLETHREAD,
    multithread = SQLITE_CONFIG_MULTITHREAD,
    serialized = SQLITE_CONFIG_SERIALIZED,
    malloc = SQLITE_CONFIG_MALLOC,
    getmalloc = SQLITE_CONFIG_GETMALLOC,
    pagecache = SQLITE_CONFIG_PAGECACHE,
    heap = SQLITE_CONFIG_HEAP,
    memstatus = SQLITE_CONFIG_MEMSTATUS,
    mutex = SQLITE_CONFIG_MUTEX,
    getmutex = SQLITE_CONFIG_GETMUTEX,
    lookaside = SQLITE_CONFIG_LOOKASIDE,
    log = SQLITE_CONFIG_LOG,
    uri = SQLITE_CONFIG_URI,
    pcache2 = SQLITE_CONFIG_PCACHE2,
    getpcache2 = SQLITE_CONFIG_GETPCACHE2,
    covering_index_scan = SQLITE_CONFIG_COVERING_INDEX_SCAN,
    sqllog = SQLITE_CONFIG_SQLLOG,
    mmap_size = SQLITE_CONFIG_MMAP_SIZE,
    win32_heapsize = SQLITE_CONFIG_WIN32_HEAPSIZE,
    pcache_hdrsz = SQLITE_CONFIG_PCACHE_HDRSZ,
    pmasz = SQLITE_CONFIG_PMASZ,
    stmtjrnl_spill = SQLITE_CONFIG_STMTJRNL_SPILL,
    small_malloc = SQLITE_CONFIG_SMALL_MALLOC,
    sorterref_size = SQLITE_CONFIG_SORTERREF_SIZE,
    memdb_maxsize = SQLITE_CONFIG_MEMDB_MAXSIZE,
};

pub const SQLITE_CONFIG_SINGLETHREAD = @as(c_int, 1);
pub const SQLITE_CONFIG_MULTITHREAD = @as(c_int, 2);
pub const SQLITE_CONFIG_SERIALIZED = @as(c_int, 3);
pub const SQLITE_CONFIG_MALLOC = @as(c_int, 4);
pub const SQLITE_CONFIG_GETMALLOC = @as(c_int, 5);
pub const SQLITE_CONFIG_SCRATCH = @as(c_int, 6);
pub const SQLITE_CONFIG_PAGECACHE = @as(c_int, 7);
pub const SQLITE_CONFIG_HEAP = @as(c_int, 8);
pub const SQLITE_CONFIG_MEMSTATUS = @as(c_int, 9);
pub const SQLITE_CONFIG_MUTEX = @as(c_int, 10);
pub const SQLITE_CONFIG_GETMUTEX = @as(c_int, 11);
pub const SQLITE_CONFIG_LOOKASIDE = @as(c_int, 13);
pub const SQLITE_CONFIG_PCACHE = @as(c_int, 14);
pub const SQLITE_CONFIG_GETPCACHE = @as(c_int, 15);
pub const SQLITE_CONFIG_LOG = @as(c_int, 16);
pub const SQLITE_CONFIG_URI = @as(c_int, 17);
pub const SQLITE_CONFIG_PCACHE2 = @as(c_int, 18);
pub const SQLITE_CONFIG_GETPCACHE2 = @as(c_int, 19);
pub const SQLITE_CONFIG_COVERING_INDEX_SCAN = @as(c_int, 20);
pub const SQLITE_CONFIG_SQLLOG = @as(c_int, 21);
pub const SQLITE_CONFIG_MMAP_SIZE = @as(c_int, 22);
pub const SQLITE_CONFIG_WIN32_HEAPSIZE = @as(c_int, 23);
pub const SQLITE_CONFIG_PCACHE_HDRSZ = @as(c_int, 24);
pub const SQLITE_CONFIG_PMASZ = @as(c_int, 25);
pub const SQLITE_CONFIG_STMTJRNL_SPILL = @as(c_int, 26);
pub const SQLITE_CONFIG_SMALL_MALLOC = @as(c_int, 27);
pub const SQLITE_CONFIG_SORTERREF_SIZE = @as(c_int, 28);
pub const SQLITE_CONFIG_MEMDB_MAXSIZE = @as(c_int, 29);

pub const sqlite3_mem_methods = extern struct {
    xMalloc: ?fn (c_int) callconv(.C) ?*c_void,
    xFree: ?fn (?*c_void) callconv(.C) void,
    xRealloc: ?fn (?*c_void, c_int) callconv(.C) ?*c_void,
    xSize: ?fn (?*c_void) callconv(.C) c_int,
    xRoundup: ?fn (c_int) callconv(.C) c_int,
    xInit: ?fn (?*c_void) callconv(.C) c_int,
    xShutdown: ?fn (?*c_void) callconv(.C) void,
    pAppData: ?*c_void,
};

// Mutex
pub const Mutex = opaque {
    pub const Methods = extern struct {
        xMutexInit: ?fn () callconv(.C) c_int,
        xMutexEnd: ?fn () callconv(.C) c_int,
        xMutexAlloc: ?fn (c_int) callconv(.C) ?*Mutex,
        xMutexFree: ?fn (?*Mutex) callconv(.C) void,
        xMutexEnter: ?fn (?*Mutex) callconv(.C) void,
        xMutexTry: ?fn (?*Mutex) callconv(.C) c_int,
        xMutexLeave: ?fn (?*Mutex) callconv(.C) void,
        xMutexHeld: ?fn (?*Mutex) callconv(.C) c_int,
        xMutexNotheld: ?fn (?*Mutex) callconv(.C) c_int,
    };
};

// PCache
pub const PCache = opaque {
    pub const Page = extern struct {
        pBuf: ?*c_void,
        pExtra: ?*c_void,
    };

    pub const Methods2 = extern struct {
        iVersion: c_int,
        pArg: ?*c_void,
        xInit: ?fn (?*c_void) callconv(.C) c_int,
        xShutdown: ?fn (?*c_void) callconv(.C) void,
        xCreate: ?fn (c_int, c_int, c_int) callconv(.C) ?*PCache,
        xCachesize: ?fn (?*PCache, c_int) callconv(.C) void,
        xPagecount: ?fn (?*PCache) callconv(.C) c_int,
        xFetch: ?fn (?*PCache, c_uint, c_int) callconv(.C) [*c]Page,
        xUnpin: ?fn (?*PCache, [*c]Page, c_int) callconv(.C) void,
        xRekey: ?fn (?*PCache, [*c]Page, c_uint, c_uint) callconv(.C) void,
        xTruncate: ?fn (?*PCache, c_uint) callconv(.C) void,
        xDestroy: ?fn (?*PCache) callconv(.C) void,
        xShrink: ?fn (?*PCache) callconv(.C) void,
    };

    pub const Methods = extern struct {
        pArg: ?*c_void,
        xInit: ?fn (?*c_void) callconv(.C) c_int,
        xShutdown: ?fn (?*c_void) callconv(.C) void,
        xCreate: ?fn (c_int, c_int) callconv(.C) ?*PCache,
        xCachesize: ?fn (?*PCache, c_int) callconv(.C) void,
        xPagecount: ?fn (?*PCache) callconv(.C) c_int,
        xFetch: ?fn (?*PCache, c_uint, c_int) callconv(.C) ?*c_void,
        xUnpin: ?fn (?*PCache, ?*c_void, c_int) callconv(.C) void,
        xRekey: ?fn (?*PCache, ?*c_void, c_uint, c_uint) callconv(.C) void,
        xTruncate: ?fn (?*PCache, c_uint) callconv(.C) void,
        xDestroy: ?fn (?*PCache) callconv(.C) void,
    };
};

// Constants
pub const SQLITE_OPEN_READONLY = @as(c_int, 0x00000001);
pub const SQLITE_OPEN_READWRITE = @as(c_int, 0x00000002);
pub const SQLITE_OPEN_CREATE = @as(c_int, 0x00000004);
pub const SQLITE_OPEN_DELETEONCLOSE = @as(c_int, 0x00000008);
pub const SQLITE_OPEN_EXCLUSIVE = @as(c_int, 0x00000010);
pub const SQLITE_OPEN_AUTOPROXY = @as(c_int, 0x00000020);
pub const SQLITE_OPEN_URI = @as(c_int, 0x00000040);
pub const SQLITE_OPEN_MEMORY = @as(c_int, 0x00000080);
pub const SQLITE_OPEN_MAIN_DB = @as(c_int, 0x00000100);
pub const SQLITE_OPEN_TEMP_DB = @as(c_int, 0x00000200);
pub const SQLITE_OPEN_TRANSIENT_DB = @as(c_int, 0x00000400);
pub const SQLITE_OPEN_MAIN_JOURNAL = @as(c_int, 0x00000800);
pub const SQLITE_OPEN_TEMP_JOURNAL = @as(c_int, 0x00001000);
pub const SQLITE_OPEN_SUBJOURNAL = @as(c_int, 0x00002000);
pub const SQLITE_OPEN_SUPER_JOURNAL = @as(c_int, 0x00004000);
pub const SQLITE_OPEN_NOMUTEX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00008000, .hexadecimal);
pub const SQLITE_OPEN_FULLMUTEX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00010000, .hexadecimal);
pub const SQLITE_OPEN_SHAREDCACHE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00020000, .hexadecimal);
pub const SQLITE_OPEN_PRIVATECACHE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00040000, .hexadecimal);
pub const SQLITE_OPEN_WAL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x00080000, .hexadecimal);
pub const SQLITE_OPEN_NOFOLLOW = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x01000000, .hexadecimal);
pub const SQLITE_OPEN_EXRESCODE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x02000000, .hexadecimal);
pub const SQLITE_OPEN_MASTER_JOURNAL = @as(c_int, 0x00004000);
