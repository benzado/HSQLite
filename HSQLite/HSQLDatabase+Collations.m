//
//  HSQLDatabase+Collations.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLDatabase+Collations.h"
#import "HSQLDatabase+Private.h"
#import "HSQLValue.h"
#import "HSQLRow.h"
#import "HSQLStatement.h"

int HSQLCollationCompare(void *comparator, int alen, const void *abytes, int blen, const void *bbytes)
{
    NSString *a = [[NSString alloc] initWithBytesNoCopy:(void *)abytes length:alen encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSString *b = [[NSString alloc] initWithBytesNoCopy:(void *)bbytes length:blen encoding:NSUTF8StringEncoding freeWhenDone:NO];
    return ((__bridge NSComparator)comparator)(a, b);
}

void HSQLCollationDestroy(void *comparator)
{
    CFBridgingRelease(comparator);
}

void HSQLCollationNeeded(void *ptr, sqlite3 *db, int eTextRep, const char *n)
{
    HSQLDatabase *database = (__bridge HSQLDatabase *)ptr;
    [database collationNeededWithName:[NSString stringWithUTF8String:n]];
}

@implementation HSQLDatabase (Collations)

- (void)defineCollationNamed:(NSString *)name comparator:(NSComparator)comparator
{
    void *block = (void *)CFBridgingRetain([comparator copy]);
    int r;
    r = sqlite3_create_collation_v2(_db, [name UTF8String], SQLITE_UTF8, block, HSQLCollationCompare, HSQLCollationDestroy);
    if (r != SQLITE_OK) {
        [self raiseExceptionOrGetError:NULL];
    }
}

- (void)removeCollationNamed:(NSString *)name
{
    int r = sqlite3_create_collation_v2(_db, [name UTF8String], SQLITE_UTF8, NULL, NULL, NULL);
    if (r != SQLITE_OK) {
        [self raiseExceptionOrGetError:NULL];
    }
}

- (NSArray *)allCollationNames
{
    NSMutableArray *names = [NSMutableArray array];
    HSQLStatement *st = [self statementWithQuery:@"PRAGMA collation_list" error:NULL];
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        [names addObject:[row[@"name"] stringValue]];
    }];
    return names;
}

- (void)setUndefinedCollationHandler:(HSQLUndefinedCollationHandler)handler
{
    NSParameterAssert(handler);
    collationNeededHandler = [handler copy];
    int err = sqlite3_collation_needed(_db, (__bridge void *)(self), &HSQLCollationNeeded);
    if (err != SQLITE_OK) {
        [self raiseExceptionOrGetError:NULL];
    }
}

- (void)collationNeededWithName:(NSString *)name
{
    collationNeededHandler(self, name);
}

@end
