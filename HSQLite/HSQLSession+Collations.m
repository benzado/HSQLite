//
//  HSQLSession+Collations.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession+Collations.h"
#import "HSQLSession+Private.h"
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
    HSQLSession *session = (__bridge HSQLSession *)ptr;
    [session collationNeededWithName:[NSString stringWithUTF8String:n]];
}

@implementation HSQLSession (Collations)

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
    HSQLStatement *st = [self statementWithQuery:@"PRAGMA collation_list" error:NULL];
    return [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        return [row[@"name"] stringValue];
    }];
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
