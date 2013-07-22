//
//  HSQLDatabase.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/21/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession.h"
#import "HSQLDatabase.h"
#import "HSQLStatement.h"
#import "HSQLRow.h"
#import "HSQLValue.h"

@implementation HSQLDatabase

@dynamic absolutePath;
@dynamic readOnly;

- (id)initWithHandle:(sqlite3 *)handle session:(HSQLSession *)session name:(NSString *)name
{
    if ((self = [super init])) {
        _handle = handle;
        _session = session;
        _name = name;
    }
    return self;
}

- (void)detachFromSession
{
    NSString *query = [NSString stringWithFormat:@"DETACH \"%@\"", self.name];
    [self.session executeQuery:query error:nil];
    _session = nil;
}

- (NSString *)absolutePath
{
    const char *path = sqlite3_db_filename(_handle, [_name UTF8String]);
    return [NSString stringWithUTF8String:path];
}

- (BOOL)isReadOnly
{
    return 1 == sqlite3_db_readonly(_handle, [_name UTF8String]);
}

@end

@implementation HSQLSession (Database)

- (HSQLDatabase *)databaseNamed:(NSString *)name
{
    NSParameterAssert(name);
    return [[HSQLDatabase alloc] initWithHandle:_db session:self name:name];
}

- (HSQLDatabase *)mainDatabase
{
    return [self databaseNamed:@"main"];
}

- (HSQLDatabase *)tempDatabase
{
    return [self databaseNamed:@"temp"];
}

- (NSArray *)allDatabases
{
    HSQLStatement *st = [self statementWithQuery:@"PRAGMA database_list" error:nil];
    return [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        NSString *name = [row[1] stringValue];
        return [self databaseNamed:name];
    }];
}

- (void)attachDatabaseFileAtPath:(NSString *)path forName:(NSString *)name error:(NSError *__autoreleasing *)error
{
    HSQLStatement *st = [self statementWithQuery:@"ATTACH DATABASE ? AS ?" error:nil];
    st[1] = path;
    st[2] = name;
    [st executeWithBlock:NULL];
}

@end
