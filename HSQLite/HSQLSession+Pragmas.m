//
//  HSQLSession+Pragmas.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession+Pragmas.h"
#import "HSQLStatement.h"
#import "HSQLRow.h"
#import "HSQLValue.h"

@implementation HSQLSession (Pragmas)

- (int)intForPragmaQuery:(NSString *)query
{
    __block int result = -1;
    HSQLStatement *st = [self statementWithQuery:query error:NULL];
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        result = [row[0] intValue];
    }];
    return result;
}

- (void)setInt:(int)value forPragmaName:(NSString *)name
{
    NSString *query = [NSString stringWithFormat:@"PRAGMA %@=%d", name, value];
    [self executeQuery:query error:NULL];
}

@dynamic applicationID;

- (uint32_t)applicationID
{
    if (sqlite3_libversion_number() < 3007017) {
        NSLog(@"WARNING: PRAGMA application_id not supported by this version of sqlite");
        return 0;
    }
    return [self intForPragmaQuery:@"PRAGMA application_id"];
}

- (void)setApplicationID:(uint32_t)appID
{
    if (sqlite3_libversion_number() < 3007017) {
        NSLog(@"WARNING: PRAGMA application_id not supported by this version of sqlite");
        return;
    }
    [self willChangeValueForKey:@"applicationID"];
    [self setInt:appID forPragmaName:@"application_id"];
    [self didChangeValueForKey:@"applicationID"];
}

@dynamic autoVacuumMode;

- (HSQLAutoVacuumMode)autoVacuumMode
{
    return [self intForPragmaQuery:@"PRAGMA auto_vacuum"];
}

- (void)setAutoVacuumMode:(HSQLAutoVacuumMode)autoVacuumMode
{
    [self willChangeValueForKey:@"autoVacuumMode"];
    [self setInt:autoVacuumMode forPragmaName:@"auto_vacuum"];
    [self didChangeValueForKey:@"autoVaccumMode"];
}

@dynamic autoIndexingEnabled;

- (BOOL)autoIndexingEnabled
{
    return [self intForPragmaQuery:@"PRAGMA auto_index"];
}

- (void)setAutoIndexingEnabled:(BOOL)autoIndexingEnabled
{
    [self willChangeValueForKey:@"autoIndexingEnabled"];
    [self setInt:autoIndexingEnabled forPragmaName:@"auto_index"];
    [self didChangeValueForKey:@"autoIndexingEnabled"];
}

@dynamic encoding;

- (NSStringEncoding)encoding
{
    __block NSString *encoding = nil;
    HSQLStatement *st = [self statementWithQuery:@"PRAGMA encoding" error:NULL];
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        encoding = [row[0] stringValue];
    }];
    if (encoding == nil) return 0;
    NSDictionary *map = @{@"UTF-8": @(NSUTF8StringEncoding),
                          @"UTF-16": @(NSUTF16StringEncoding),
                          @"UTF-16le": @(NSUTF16LittleEndianStringEncoding),
                          @"UTF-16be": @(NSUTF16BigEndianStringEncoding)};
    return [[map objectForKey:encoding] unsignedIntegerValue];
}

- (void)setEncoding:(NSStringEncoding)encoding
{
    NSString *name = nil;
    switch (encoding) {
        case NSUTF8StringEncoding: name = @"UTF-8"; break;
        case NSUTF16StringEncoding: name = @"UTF-16"; break;
        case NSUTF16LittleEndianStringEncoding: name = @"UTF-16le"; break;
        case NSUTF16BigEndianStringEncoding: name = @"UTF-16be"; break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"encoding must be UTF-8 or UTF-16"];
            break;
    }
    NSString *query = [NSString stringWithFormat:@"PRAGMA encoding=\"%@\"", name];
    [self executeQuery:query error:NULL];
}

@dynamic foreignKeyConstraintsEnforced;

- (BOOL)foreignKeyConstraintsEnforced
{
    return [self intForPragmaQuery:@"PRAGMA foreign_keys"];
}

- (void)setForeignKeyConstraintsEnforced:(BOOL)foreignKeyConstraintsEnforced
{
    [self willChangeValueForKey:@"foreignKeyConstraintsEnforced"];
    [self setInt:foreignKeyConstraintsEnforced forPragmaName:@"foreign_keys"];
    [self didChangeValueForKey:@"foreignKeyConstraintsEnforced"];
}

@dynamic userVersion;

- (int)userVersion
{
    return [self intForPragmaQuery:@"PRAGMA user_version"];
}

- (void)setUserVersion:(int)userVersion
{
    [self willChangeValueForKey:@"userVersion"];
    [self setInt:userVersion forPragmaName:@"user_version"];
    [self didChangeValueForKey:@"userVersion"];
}

- (NSArray *)errorsFromQuery:(NSString *)query
{
    return [[self statementWithQuery:query error:nil] arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        NSString *message = [row[0] stringValue];
        if ([message isEqualToString:@"ok"]) return nil;
        return [NSError errorWithDomain:HSQLErrorDomain
                                   code:SQLITE_INTERNAL
                               userInfo:@{NSLocalizedDescriptionKey: message}];
    }];
}

- (NSArray *)errorsFromIntegrityCheckStoppingAfter:(int)count
{
    return [self errorsFromQuery:
            [NSString stringWithFormat:@"PRAGMA integrity_check(%d)", count]];
}

- (NSArray *)errorsFromIntegrityCheck
{
    return [self errorsFromQuery:@"PRAGMA integrity_check"];
}

- (NSArray *)errorsFromQuickCheckStoppingAfter:(int)count
{
    return [self errorsFromQuery:
            [NSString stringWithFormat:@"PRAGMA quick_check(%d)", count]];
}

- (NSArray *)errorsFromQuickCheck
{
    return [self errorsFromQuery:@"PRAGMA quick_check"];
}

@end
