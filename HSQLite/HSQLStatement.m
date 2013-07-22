//
//  HSQLStatement.m
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
#import "HSQLRow+Private.h"

@implementation HSQLStatement

- (instancetype)initWithSession:(HSQLSession *)session stmt:(sqlite3_stmt *)stmt
{
    if ((self = [super init])) {
        _session = session;
        _stmt = stmt;
    }
    return self;
}

- (void)close
{
    sqlite3_finalize(_stmt); // calling finalize on NULL is a no-op
    _stmt = NULL;
}

- (void)dealloc
{
    [self close];
}

- (NSString *)query
{
    const char *sql = sqlite3_sql(_stmt);
    return [NSString stringWithUTF8String:sql];
}

- (BOOL)isReadOnly
{
    return sqlite3_stmt_readonly(_stmt);
}

- (BOOL)isBusy
{
    return sqlite3_stmt_busy(_stmt);
}

- (int)numberOfParameters
{
    return sqlite3_bind_parameter_count(_stmt);
}

- (int)numberOfColumns
{
    return sqlite3_column_count(_stmt);
}

- (int)indexForColumnName:(NSString *)name
{
    if (_columnIndexesByName == nil) {
        NSUInteger count = [self numberOfColumns];
        NSMutableDictionary *columns = [NSMutableDictionary dictionaryWithCapacity:count];
        for (int i = 0; i < count; i++) {
            const char *s = sqlite3_column_name(_stmt, i);
            if (s) {
                NSString *name = [NSString stringWithUTF8String:s];
                [columns setObject:@(i) forKey:name];
            }
            // TODO: maybe also use sqlite3_column_{database,table,origin}_name?
        }
        _columnIndexesByName = [columns copy];
    }
    NSNumber *idx = _columnIndexesByName[name];
    if (idx == nil) {
        [NSException raise:NSInvalidArgumentException format:@"No such column named '%@'", name];
    }
    return [idx intValue];
}

- (void)setObject:(id)anObject atIndexedSubscript:(NSUInteger)idx
{
    int r = SQLITE_FAIL;

    if (anObject == nil) {
        r = sqlite3_bind_null(_stmt, idx);
    }
    else if ([anObject respondsToSelector:@selector(HSQLStatement_bindValueToStmt:column:)]) {
        r = [anObject HSQLStatement_bindValueToStmt:_stmt column:idx];
    }
    else {
        [NSException raise:NSInvalidArgumentException format:@"can't use object of class %@ as parameter", [anObject class]];
    }

    if (r == SQLITE_RANGE) {
        [NSException raise:NSRangeException format:@"parameter index %d out of range", idx];
    }
    if (r != SQLITE_OK) {
        [HSQLSession raiseExceptionOrGetError:nil forResultCode:r];
    }

    if (anObject == nil) {
        [_boundObjects removeObjectForKey:@(idx)];
    } else {
        if (_boundObjects == nil) {
            _boundObjects = [[NSMutableDictionary alloc] initWithCapacity:self.numberOfParameters];
        }
        [_boundObjects setObject:anObject forKey:@(idx)];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return [_boundObjects objectForKey:@(index)];
}

- (NSUInteger)indexForKey:(NSString *)key
{
    int idx = sqlite3_bind_parameter_index(_stmt, [key UTF8String]);
    if (idx == 0) {
        [NSException raise:NSInvalidArgumentException format:@"unknown parameter name '%@'", key];
    }
    return idx;
}

- (void)setObject:(id)anObject forKeyedSubscript:(NSString *)key
{
    [self setObject:anObject atIndexedSubscript:[self indexForKey:key]];
}

- (id)objectforKeyedSubscript:(NSString *)key
{
    return [self objectAtIndexedSubscript:[self indexForKey:key]];
}

- (void)executeWithBlock:(void(^)(HSQLRow *row, BOOL *stop))block
{
    int r;
    BOOL done = NO;
    HSQLRow *row = [[HSQLRow alloc] initWithStatement:self stmt:_stmt];
    while ( ! done) {
        r = sqlite3_step(_stmt);
        switch (r) {
            case SQLITE_ROW:
                if (block) block(row, &done);
                break;
            case SQLITE_DONE:
                done = YES;
                break;
            default:
                [HSQLSession raiseExceptionOrGetError:NULL forResultCode:r];
                break;
        }
    }
    sqlite3_reset(_stmt);
}

- (NSArray *)arrayByExecutingWithBlock:(id(^)(HSQLRow *row, BOOL *stop))block
{
    NSMutableArray *array = [NSMutableArray array];
    [self executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        id <NSObject> item = block(row, stop);
        if (item) {
            NSAssert(![item isKindOfClass:[HSQLRow class]], @"Can't persist HSQLRow outside of execution block.");
            NSAssert(![item conformsToProtocol:@protocol(HSQLValue)], @"Can't persist HSQLValue outside of execution block.");
            [array addObject:item];
        }
    }];
    return array;
}

- (void)clearBindings
{
    sqlite3_clear_bindings(_stmt);
    [_boundObjects removeAllObjects];
}

@end

@implementation NSNull (HSQLStatement)

- (int)HSQLStatement_bindValueToStmt:(sqlite3_stmt *)stmt column:(int)idx
{
    return sqlite3_bind_null(stmt, idx);
}

@end

@implementation NSString (HSQLStatement)

- (int)HSQLStatement_bindValueToStmt:(sqlite3_stmt *)stmt column:(int)idx
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return sqlite3_bind_text(stmt, idx, [data bytes], [data length], SQLITE_TRANSIENT);
}

@end

@implementation NSData (HSQLStatement)

- (int)HSQLStatement_bindValueToStmt:(sqlite3_stmt *)stmt column:(int)idx
{
    // We claim the data is static and then ensure that HSQLStatement
    // keeps the object around until the binding is cleared. This is more
    // memory efficient than copying.
    return sqlite3_bind_blob(stmt, idx, [self bytes], [self length], SQLITE_STATIC);
}

@end

@implementation NSNumber (HSQLStatement)

- (int)HSQLStatement_bindValueToStmt:(sqlite3_stmt *)stmt column:(int)idx
{
    const char *t = [self objCType];
    NSAssert(t != NULL, @"NSNumber must have an objcType encoding");
    switch (*t) {
        case 'f':
        case 'd':
            return sqlite3_bind_double(stmt, idx, [self doubleValue]);
        case 'q':
        case 'Q':
            return sqlite3_bind_int64(stmt, idx, [self longLongValue]);
        default:
            return sqlite3_bind_int(stmt, idx, [self intValue]);
    }
}

@end
