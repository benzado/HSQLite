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
    if (anObject == nil || anObject == [NSNull null]) {
        r = sqlite3_bind_null(_stmt, idx);
    }
    else if ([anObject isKindOfClass:[NSString class]]) {
        NSData *data = [anObject dataUsingEncoding:NSUTF8StringEncoding];
        r = sqlite3_bind_text(_stmt, idx, [data bytes], [data length], SQLITE_TRANSIENT);
    }
    else if ([anObject isKindOfClass:[NSData class]]) {
        r = sqlite3_bind_blob(_stmt, idx, [anObject bytes], [anObject length], SQLITE_TRANSIENT);
    }
    else if ([anObject isKindOfClass:[NSNumber class]]) {
        const char *t = [anObject objCType];
        NSAssert(t != NULL, @"NSNumber must have an objcType encoding");
        switch (*t) {
            case 'f':
            case 'd':
                r = sqlite3_bind_double(_stmt, idx, [anObject doubleValue]);
                break;
            case 'q':
            case 'Q':
                r = sqlite3_bind_int64(_stmt, idx, [anObject longLongValue]);
            default:
                r = sqlite3_bind_int(_stmt, idx, [anObject intValue]);
                break;
        }
    }
    else {
        [NSException raise:NSInvalidArgumentException format:@"can't use object of class %@ as parameter", [anObject class]];
    }
    if (r == SQLITE_RANGE) {
        [NSException raise:NSRangeException format:@"parameter index %d out of range", idx];
    }
}

- (void)setObject:(id)anObject forKeyedSubscript:(NSString *)key
{
    int idx = sqlite3_bind_parameter_index(_stmt, [key UTF8String]);
    if (idx == 0) {
        [NSException raise:NSInvalidArgumentException format:@"unknown parameter name '%@'", key];
    }
    [self setObject:anObject atIndexedSubscript:idx];
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
        id item = block(row, stop);
        if (item) {
            [array addObject:item];
        }
    }];
    return array;
}

- (void)clearBindings
{
    sqlite3_clear_bindings(_stmt);
}

@end
