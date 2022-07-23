const std = @import("std");
const log = std.log.scoped(.sqlite3);

pub const SQLite3 = opaque {
    // open
    pub extern fn sqlite3_open([*:0]const u8, *?*SQLite3) c_int;
    pub extern fn sqlite3_open16([*]const anyopaque, *?*SQLite3) c_int;
    pub extern fn sqlite3_open_v2([*:0]const u8, *?*SQLite3, c_int, [*:0]const u8) c_int;

    pub fn open(filename: [*:0]const u8) !*SQLite3 {
        var db: ?*SQLite3 = null;
        errdefer {
            if (db) |db_not_null| {
                log.debug("Freeing sqlite3 on error", .{});
                db_not_null.close() catch unreachable;
            }
        }
        _ = try checkSqliteErr(sqlite3_open(filename, &db));
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
        _ = try checkSqliteErr(sqlite3_open(filename, &db));
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

        _ = try checkSqliteErr(sqlite3_open_v2(filename, &db, c_flags, zVfs));
        return db.?;
    }

    // close
    pub extern fn sqlite3_close(?*SQLite3) c_int;
    pub extern fn sqlite3_close_v2(?*SQLite3) c_int;
    pub fn close(this: *@This()) !void {
        _ = try checkSqliteErr(sqlite3_close(this));
    }

    pub fn close_v2(this: *@This()) !void {
        _ = try checkSqliteErr(sqlite3_close_v2(this));
    }

    // Error messages
    // TODO: Can the returned strings be null?
    pub extern fn sqlite3_errcode(*SQLite3) c_int;
    pub extern fn sqlite3_extended_errcode(*SQLite3) c_int;
    pub extern fn sqlite3_errmsg(*SQLite3) ?[*:0]const u8;
    pub extern fn sqlite3_errmsg16(*SQLite3) ?*const anyopaque;

    pub fn errmsg(this: *@This()) [:0]const u8 {
        return std.mem.span(sqlite3_errmsg(this) orelse return "");
    }

    // exec
    pub const ExecCallback = fn (userdata: ?*anyopaque, number_of_result_columns: c_int, columnsAsText: [*]?[*:0]u8, columnNames: [*]?[*:0]u8) callconv(.C) c_int;
    pub extern fn sqlite3_exec(*SQLite3, sql: [*:0]const u8, callback: ?ExecCallback, ?*anyopaque, pErrmsg: ?*[*:0]u8) c_int;

    pub fn exec(this: *@This(), sql: [*:0]const u8, callback: ?ExecCallback, userdata: ?*anyopaque, pErrmsg: ?*[*:0]u8) !void {
        _ = try checkSqliteErr(sqlite3_exec(this, sql, callback, userdata, pErrmsg));
    }

    // prepare
    pub extern fn sqlite3_prepare(*SQLite3, zSql: [*]const u8, maxLen: c_int, ppStmt: *?*Stmt, pzTail: ?*[*]const u8) c_int;
    pub extern fn sqlite3_prepare_v2(*SQLite3, zSql: [*]const u8, maxLen: c_int, ppStmt: *?*Stmt, pzTail: ?*[*]const u8) c_int;

    pub fn prepare_v2(this: *@This(), sql: []const u8, sqlTailOpt: ?*[]const u8) !?*Stmt {
        //var sql_tail_buf: [*:0]const u8 = undefined;
        var sql_tail_ptr: ?*[*]const u8 = if (sqlTailOpt) |sqlTail| &sqlTail.ptr else null;

        var pp_stmt: ?*Stmt = null;
        errdefer _ = Stmt.sqlite3_finalize(pp_stmt);
        _ = try checkSqliteErr(sqlite3_prepare_v2(this, sql.ptr, @intCast(c_int, sql.len), &pp_stmt, sql_tail_ptr));

        if (sqlTailOpt) |sqlTail| {
            const diff = @ptrToInt(sqlTail.ptr) -| @ptrToInt(sql.ptr);
            sqlTail.len = sql.len - diff;
        }

        return pp_stmt;
    }
};

pub const Stmt = opaque {
    pub extern fn sqlite3_reset(*Stmt) c_int;
    pub fn reset(this: *@This()) !void {
        _ = try checkSqliteErr(this.sqlite3_reset());
    }

    pub extern fn sqlite3_finalize(?*Stmt) c_int;
    pub fn finalize(this: *@This()) !void {
        _ = try checkSqliteErr(sqlite3_finalize(this));
    }

    pub extern fn sqlite3_step(*Stmt) c_int;
    pub fn step(this: *@This()) !Success {
        return try checkSqliteErr(sqlite3_step(this));
    }

    // column
    pub extern fn sqlite3_column_blob(*Stmt, iCol: c_int) ?*const anyopaque;
    pub extern fn sqlite3_column_double(*Stmt, iCol: c_int) f64;
    pub extern fn sqlite3_column_int(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_column_int64(*Stmt, iCol: c_int) i64;
    pub extern fn sqlite3_column_text(*Stmt, iCol: c_int) [*:0]const u8;
    pub extern fn sqlite3_column_text16(*Stmt, iCol: c_int) *const anyopaque;
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
    pub extern fn sqlite3_bind_blob(*Stmt, iCol: c_int, value: ?*const anyopaque, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_blob64(*Stmt, iCol: c_int, value: ?*const anyopaque, len: u64, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_double(*Stmt, iCol: c_int, value: f64) c_int;
    pub extern fn sqlite3_bind_int(*Stmt, iCol: c_int, value: c_int) c_int;
    pub extern fn sqlite3_bind_int64(*Stmt, iCol: c_int, value: i64) c_int;
    pub extern fn sqlite3_bind_null(*Stmt, iCol: c_int) c_int;
    pub extern fn sqlite3_bind_text(*Stmt, iCol: c_int, value: ?[*]const u8, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_text16(*Stmt, iCol: c_int, value: ?*const anyopaque, len: c_int, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_text64(*Stmt, iCol: c_int, value: ?[*]const u8, len: u64, ?DestructorFn, encoding: u8) c_int;
    // TODO: pub extern fn sqlite3_bind_value(*Stmt, iCol: c_int, value: *const Value) c_int;
    pub extern fn sqlite3_bind_pointer(*Stmt, iCol: c_int, value: *anyopaque, name: [*:0]const u8, ?DestructorFn) c_int;
    pub extern fn sqlite3_bind_zeroblob(*Stmt, iCol: c_int, len: c_int) c_int;
    pub extern fn sqlite3_bind_zeroblob64(*Stmt, iCol: c_int, len: u64) c_int;

    pub fn bindBlob(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType) !void {
        _ = try checkSqliteErr(sqlite3_bind_blob64(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| @intCast(u64, v.len) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindDouble(this: *@This(), iCol: c_int, value: f64) !void {
        _ = try checkSqliteErr(sqlite3_bind_double(this, iCol, value));
    }

    pub fn bindInt(this: *@This(), iCol: c_int, value: c_int) !void {
        _ = try checkSqliteErr(sqlite3_bind_int(this, iCol, value));
    }

    pub fn bindInt64(this: *@This(), iCol: c_int, value: i64) !void {
        _ = try checkSqliteErr(sqlite3_bind_int64(this, iCol, value));
    }

    pub fn bindNull(this: *@This(), iCol: c_int) !void {
        _ = try checkSqliteErr(sqlite3_bind_null(this, iCol));
    }

    pub fn bindText(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType) !void {
        if (value) |v| std.debug.assert(v.len <= std.math.maxInt(c_int));

        _ = try checkSqliteErr(sqlite3_bind_text(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| @intCast(c_int, v.len) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindText16(this: *@This(), iCol: c_int, value: ?[]const u16, destructorType: DestructorType) !void {
        _ = try checkSqliteErr(sqlite3_bind_text16(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| v.len * @sizeOf(u16) else 0,
            destructorType.getFnValue(),
        ));
    }

    pub fn bindText64(this: *@This(), iCol: c_int, value: ?[]const u8, destructorType: DestructorType, encoding: TextEncoding) !void {
        _ = try checkSqliteErr(sqlite3_bind_text64(
            this,
            iCol,
            if (value) |v| v.ptr else null,
            if (value) |v| v.len else 0,
            destructorType.getFnValue(),
            @enumToInt(encoding),
        ));
    }

    // TODO: pub fn bindValue()

    pub fn bindPointer(this: *@This(), iCol: c_int, value: ?*anyopaque, name: [*:0]const u8, destructorFn: ?DestructorFn) !void {
        _ = try checkSqliteErr(sqlite3_bind_pointer(
            this,
            iCol,
            value,
            name,
            destructorFn,
        ));
    }

    pub fn bindZeroBlob(this: *@This(), iCol: c_int, len: c_int) !void {
        _ = try checkSqliteErr(sqlite3_bind_zeroblob(this, iCol, len));
    }

    pub fn bindZeroblob64(this: *@This(), iCol: c_int, len: u64) !void {
        _ = try checkSqliteErr(sqlite3_bind_zeroblob64(this, iCol, len));
    }

    // Stmt introspection
    pub extern fn sqlite3_bind_parameter_index(*Stmt, name: [*:0]const u8) c_int;

    pub fn bindParameterIndex(this: *@This(), name: [:0]const u8) ?c_int {
        const ret = this.sqlite3_bind_parameter_index(name.ptr);
        if (ret == 0) return null;
        return ret;
    }
};

pub extern fn sqlite3_errstr(c_int) ?[*:0]const u8;
pub fn errstr(errcode: c_int) [:0]const u8 {
    return std.mem.span(sqlite3_errstr(errcode) orelse return "");
}

pub const SQLiteType = enum(c_int) {
    integer = 1,
    float = 2,
    text = 3,
    blob = 4,
    @"null" = 5,
};

pub const DestructorFn = fn (*anyopaque) callconv(.C) void;

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
pub extern fn sqlite3_malloc(len: c_int) ?*anyopaque;
pub extern fn sqlite3_malloc64(len: u64) ?*anyopaque;
pub extern fn sqlite3_realloc(ptr: ?*anyopaque, len: c_int) ?*anyopaque;
pub extern fn sqlite3_realloc64(ptr: ?*anyopaque, len: u64) ?*anyopaque;
pub extern fn sqlite3_free(ptr: ?*anyopaque) void;
pub extern fn sqlite3_msize(ptr: ?*anyopaque) u64;

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
    std.debug.assert((try checkSqliteErr(result)) == .Ok);
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
        logFn: fn (userdata: *anyopaque, errcode: c_int, msg: ?[*:0]const u8) callconv(.C) void,
        userdata: ?*anyopaque,
    },
    uri: bool,
    covering_index_scan: bool,
    sqllog: struct {
        logFn: fn (userdata: *anyopaque, db: *SQLite3, dbFilename: ?[*:0]const u8, sqllog: c_int) callconv(.C) void,
        userdata: ?*anyopaque,
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
    xMalloc: ?fn (c_int) callconv(.C) ?*anyopaque,
    xFree: ?fn (?*anyopaque) callconv(.C) void,
    xRealloc: ?fn (?*anyopaque, c_int) callconv(.C) ?*anyopaque,
    xSize: ?fn (?*anyopaque) callconv(.C) c_int,
    xRoundup: ?fn (c_int) callconv(.C) c_int,
    xInit: ?fn (?*anyopaque) callconv(.C) c_int,
    xShutdown: ?fn (?*anyopaque) callconv(.C) void,
    pAppData: ?*anyopaque,
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
        pBuf: ?*anyopaque,
        pExtra: ?*anyopaque,
    };

    pub const Methods2 = extern struct {
        iVersion: c_int,
        pArg: ?*anyopaque,
        xInit: ?fn (?*anyopaque) callconv(.C) c_int,
        xShutdown: ?fn (?*anyopaque) callconv(.C) void,
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
        pArg: ?*anyopaque,
        xInit: ?fn (?*anyopaque) callconv(.C) c_int,
        xShutdown: ?fn (?*anyopaque) callconv(.C) void,
        xCreate: ?fn (c_int, c_int) callconv(.C) ?*PCache,
        xCachesize: ?fn (?*PCache, c_int) callconv(.C) void,
        xPagecount: ?fn (?*PCache) callconv(.C) c_int,
        xFetch: ?fn (?*PCache, c_uint, c_int) callconv(.C) ?*anyopaque,
        xUnpin: ?fn (?*PCache, ?*anyopaque, c_int) callconv(.C) void,
        xRekey: ?fn (?*PCache, ?*anyopaque, c_uint, c_uint) callconv(.C) void,
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
    std.debug.panic("unknown sqlite error code\n", .{});
}

pub fn assertOkay(sqlite_rc: c_int) void {
    if (sqlite_rc != SQLITE_OK) {
        std.debug.panic("SQLite returned an error code", .{});
    }
}
