//
//  HSQLSession.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession.h"
#import "HSQLSession+Private.h"
#import "HSQLStatement.h"
#import "HSQLStatement+Private.h"
#import "HSQLRow.h"

NSString * const HSQLExceptionName = @"HSQLException";
NSString * const HSQLErrorDomain = @"HSQLError";

NSString * const HSQLUnderlyingExceptionKey = @"HSQLUnderlyingException";

int HSQLDatabaseBusyHandler(void *ptr, int lockAttempts)
{
    HSQLSession *db = (__bridge HSQLSession *)ptr;
    return [db busyForNumberOfLockAttempts:lockAttempts];
}

@implementation HSQLSession

+ (void)initialize
{
    if (sqlite3_threadsafe() == 0) {
        NSLog(@"WARNING: sqlite library compiled without mutex support.");
    }
}

+ (NSString *)stringForResultCode:(int)resultCode
{
    switch (resultCode & 0x00FF) {
        case SQLITE_OK: return @"OK";
        case SQLITE_ERROR: return @"SQL error or missing database";
        case SQLITE_INTERNAL: return @"Internal logic error in SQLite";
        case SQLITE_PERM: return @"Access permission denied";
        case SQLITE_ABORT: return @"Callback routine requested an abort";
        case SQLITE_BUSY: return @"The database file is locked";
        case SQLITE_LOCKED: return @"A table in the database is locked";
        case SQLITE_NOMEM: return @"A malloc() failed";
        case SQLITE_READONLY: return @"Attempt to write a readonly database";
        case SQLITE_INTERRUPT: return @"Operation terminated by sqlite3_interrupt()";
        case SQLITE_IOERR: return @"Some kind of disk I/O error occurred";
        case SQLITE_CORRUPT: return @"The database disk image is malformed";
        case SQLITE_NOTFOUND: return @"Unknown opcode in sqlite3_file_control()";
        case SQLITE_FULL: return @"Insertion failed because database is full";
        case SQLITE_CANTOPEN: return @"Unable to open the database file";
        case SQLITE_PROTOCOL: return @"Database lock protocol error";
        case SQLITE_EMPTY: return @"Database is empty";
        case SQLITE_SCHEMA: return @"The database schema changed";
        case SQLITE_TOOBIG: return @"String or BLOB exceeds size limit";
        case SQLITE_CONSTRAINT: return @"Abort due to constraint violation";
        case SQLITE_MISMATCH: return @"Data type mismatch";
        case SQLITE_MISUSE: return @"Library used incorrectly";
        case SQLITE_NOLFS: return @"Uses OS features not supported on host";
        case SQLITE_AUTH: return @"Authorization denied";
        case SQLITE_FORMAT: return @"Auxiliary database format error";
        case SQLITE_RANGE: return @"2nd parameter to sqlite3_bind out of range";
        case SQLITE_NOTADB: return @"File opened that is not a database file";
        case SQLITE_ROW: return @"sqlite3_step() has another row ready";
        case SQLITE_DONE: return @"sqlite3_step() has finished executing";
        default:
            return [NSString stringWithFormat:@"Unknown error code %d", resultCode];
    }
}

+ (BOOL)raiseExceptionOrGetError:(NSError **)error forResultCode:(int)resultCode
{
    if (resultCode == SQLITE_OK) return YES;
    NSString *msg = [self stringForResultCode:resultCode];
    if (error) {
        *error = [NSError errorWithDomain:HSQLErrorDomain code:resultCode userInfo:@{NSLocalizedDescriptionKey: msg}];
    } else {
        [NSException raise:HSQLExceptionName format:@"Error %d: %@", resultCode, msg];
    }
    return NO;
}

+ (instancetype)sessionWithFileAtPath:(NSString *)path
{
    HSQLSessionFlags flags = (HSQLSessionOpenCreate | HSQLSessionOpenReadWrite);
    return [[[self class] alloc] initWithPath:path flags:flags VFSName:nil];
}

+ (instancetype)sessionWithTemporaryFile
{
    HSQLSessionFlags flags = (HSQLSessionOpenCreate | HSQLSessionOpenReadWrite);
    return [[[self class] alloc] initWithPath:@"" flags:flags VFSName:nil];
}

+ (instancetype)sessionWithMemoryDatabase
{
    HSQLSessionFlags flags = (HSQLSessionOpenCreate | HSQLSessionOpenReadWrite);
    return [[[self class] alloc] initWithPath:@":memory:" flags:flags VFSName:nil];
}

+ (instancetype)sessionWithFileNamed:(NSString *)name
{
    // if "name.sqlite" exists in Documents directory, open it
    // else if "name.sqlite" exists in main bundle, copy then open
    // else if "name.sql" exists in main bundle, create and execute SQL
    return nil;
}

- (instancetype)initWithPath:(NSString *)path flags:(HSQLSessionFlags)flags VFSName:(NSString *)VFSName
{
    static const int REQUIRED_FLAGS = (HSQLSessionOpenReadOnly | HSQLSessionOpenReadWrite);

    NSParameterAssert(path);
    if ((flags & REQUIRED_FLAGS) == 0) {
        [NSException raise:NSInvalidArgumentException format:@"HSQLSession flags must include either HSQLSessionOpenReadOnly or HSQLSessionOpenReadWrite"];
    }
    NSParameterAssert(flags & REQUIRED_FLAGS);
    if ((self = [super init])) {
        int r = sqlite3_open_v2([path UTF8String], &_db, flags, [VFSName UTF8String]);
        if (_db == NULL) {
            NSString *message = [[self class] stringForResultCode:r];
            [NSException raise:HSQLExceptionName format:@"sqlite3_open_v2: %@", message];
        }
        if (r != SQLITE_OK) {
            NSLog(@"WARNING: sqlite3_open_v2: %s", sqlite3_errmsg(_db));
        }
    }
    return self;
}

- (void)raiseExceptionOrGetError:(NSError *__autoreleasing *)error
{
    if (error) {
        int code = sqlite3_errcode(_db);
        NSString *msg = [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
        *error = [NSError errorWithDomain:HSQLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}];
    } else {
        [NSException raise:HSQLExceptionName format:@"%s", sqlite3_errmsg(_db)];
    }
}

- (NSError *)latestError
{
    int code = sqlite3_errcode(_db);
    NSString *message = [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
    return [NSError errorWithDomain:HSQLErrorDomain code:code userInfo:
            @{NSLocalizedDescriptionKey: message}];
}

- (void)close
{
    // TODO: finalize open statements, e.g. sqlite3_next_stmt
    int r = sqlite3_close(_db); // If _db is NULL, close is a no-op
    if (r != SQLITE_OK) {
        // Might fail if open prepared statements or blob objects
        [self raiseExceptionOrGetError:NULL];
    } else {
        _db = NULL;
    }
}

- (void)dealloc
{
    [self close];
}

- (void)releaseMemory
{
    // TODO: automatically call on memory warning
    sqlite3_db_release_memory(_db);
}

- (sqlite_int64)lastInsertRowID
{
    return sqlite3_last_insert_rowid(_db);
}

- (int)numberOfRowsChangedByLastStatement
{
    return sqlite3_changes(_db);
}

- (int)totalNumberOfRowsChanged
{
    return sqlite3_total_changes(_db);
}

- (void)setBusyTimeout:(NSTimeInterval)timeout
{
    NSParameterAssert(timeout >= 0);
    int ms = 1000 * timeout;
    int err = sqlite3_busy_timeout(_db, ms);
    if (err == SQLITE_OK) {
        busyHandler = NULL;
    } else {
        [self raiseExceptionOrGetError:NULL];
    }
}

- (void)setBusyHandler:(HSQLBusyHandler)handler
{
    int err;
    if (handler) {
        err = sqlite3_busy_handler(_db, &HSQLDatabaseBusyHandler, (__bridge void *)(self));
    } else {
        err = sqlite3_busy_handler(_db, NULL, NULL);
    }
    if (err == SQLITE_OK) {
        busyHandler = [handler copy];
    } else {
        [self raiseExceptionOrGetError:NULL];
    }
}

- (int)busyForNumberOfLockAttempts:(int)attempts
{
    return busyHandler(self, attempts);
}

- (HSQLStatement *)statementWithQuery:(NSString *)sql error:(NSError **)pError
{
    NSAssert(_db, @"database is closed");
    if (sql == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Query string is nil"];
    }
    sqlite3_stmt *stmt = NULL;
    int r = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, NULL);
    if (r != SQLITE_OK) {
        [self raiseExceptionOrGetError:pError];
        return nil;
    }
    if (stmt) {
        if (pError) {
            *pError = nil;
        }
        return [[HSQLStatement alloc] initWithSession:self stmt:stmt];
    } else {
        NSString *msg = [NSString stringWithFormat:@"Cannot compile SQL: %@", sql];
        if (pError) {
            *pError = [NSError errorWithDomain:HSQLErrorDomain code:SQLITE_ERROR userInfo:@{NSLocalizedDescriptionKey: msg}];
        } else {
            [NSException raise:HSQLExceptionName format:@"%@", msg];
        }
        return nil;
    }
}

- (BOOL)executeQuery:(NSString *)sql error:(NSError *__autoreleasing *)pError
{
    NSAssert(_db, @"database is closed");
    if (sql == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Query string is nil"];
    }
    char *errmsg = NULL;
    int r = sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &errmsg);
    if (r) {
        NSString *msg;
        if (errmsg) {
            msg = [NSString stringWithUTF8String:errmsg];
        } else {
            msg = [[self class] stringForResultCode:r];
        }
        if (pError) {
            *pError = [NSError errorWithDomain:HSQLErrorDomain code:r userInfo:@{NSLocalizedDescriptionKey: msg}];
        } else {
            [NSException raise:HSQLExceptionName format:@"exec: %@", msg];
        }
    }
    return (r == SQLITE_OK);
}

- (void)executeBeginQuery:(NSString *)beginQuery block:(void(^)())block commitQuery:(NSString *)commitQuery rollbackQuery:(NSString *)rollbackQuery
{
    [self executeQuery:beginQuery error:nil];
    @try {
        block();
        [self executeQuery:commitQuery error:nil];
    }
    @catch (NSException *exception) {
        NSError *error;
        if ( ! [self executeQuery:rollbackQuery error:&error]) {
            exception = [NSException
                         exceptionWithName:HSQLExceptionName
                         reason:[error localizedDescription]
                         userInfo:@{HSQLUnderlyingExceptionKey: exception}];
        }
        [exception raise];
    }
}

- (void)transactionWithBlock:(void(^)())block
{
    [self executeBeginQuery:@"BEGIN TRANSACTION"
                      block:block
                commitQuery:@"COMMIT TRANSACTION"
              rollbackQuery:@"ROLLBACK TRANSACTION"];
}

- (void)savepointWithBlock:(void(^)())block
{
    NSString *name = [NSString stringWithFormat:@"\"HS%08x\"", rand()];
    [self executeBeginQuery:[@"SAVEPOINT " stringByAppendingString:name]
                      block:block
                commitQuery:[@"RELEASE " stringByAppendingString:name]
              rollbackQuery:[@"ROLLBACK TO " stringByAppendingString:name]];
}

@end
